-- Stationary mine dropped by mine-layer enemies.
Mine = class('Mine', Entity)

Mine.static.RADIUS = 8
Mine.static.ARM_TIME = 0.5
Mine.static.LIFE = 12

function Mine:initialize(pos)
    Entity.initialize(self, 'obstacle', 0, pos)
    self.radius = Mine.RADIUS
    self.life = Mine.LIFE
    self.armTimer = Mine.ARM_TIME
    self.armed = false
    self.velocity = vector(0, 0)
    self.pulse = 0
end

function Mine:update(dt)
    Entity.update(self, dt)
    self.pos = self.pos + self.velocity * dt
    self.life = self.life - dt
    self.pulse = math.sin(self.time * 6) * 0.4 + 0.6

    if not self.armed then
        self.armTimer = self.armTimer - dt
        if self.armTimer <= 0 then
            self.armed = true
        end
    end

    if self.life <= 0 then
        self:destroy()
    end
end

function Mine:draw()
    local alpha = math.min(1, self.life / 2)
    local r, g, b = 1.0, 0.3, 0.1

    if not self.armed then
        r, g, b = 0.5, 0.5, 0.5
    end

    love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, alpha * 0.5)
    love.graphics.circle('fill', self.pos.x, self.pos.y, self.radius * 1.5)

    love.graphics.setColor(r, g, b, alpha * self.pulse)
    love.graphics.circle('fill', self.pos.x, self.pos.y, self.radius)

    love.graphics.setColor(1, 1, 1, alpha * 0.6)
    love.graphics.circle('fill', self.pos.x, self.pos.y, self.radius * 0.3)

    -- spikes
    if self.armed then
        love.graphics.setColor(r, g, b, alpha * 0.8)
        for i = 0, 5 do
            local angle = i * math.pi / 3 + self.time * 0.5
            local sx = self.pos.x + math.cos(angle) * self.radius * 1.3
            local sy = self.pos.y + math.sin(angle) * self.radius * 1.3
            love.graphics.circle('fill', sx, sy, 2)
        end
    end
end

function Mine:shatterIntoDust()
    if not self.gameState then return end
    for i = 1, 6 do
        local angle = lume.random(0, math.pi * 2)
        local speed = lume.random(30, 80)
        local vel = vector(math.cos(angle) * speed, math.sin(angle) * speed)
        local frag = Fragment(self.pos:clone(), vel, lume.random(2, 4), {r=1, g=0.3, b=0.1})
        self.gameState:addEntity(frag)
    end
end

return Mine
