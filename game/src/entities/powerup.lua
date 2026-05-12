-- Powerup collectible with 6 types and despawn warning visual.
Powerup = class('Powerup', Entity)

Powerup.static.TYPES = {
    {name = 'shield',       color = {0.2, 0.9, 1.0},   shape = 'hexagon'},
    {name = 'time_warp',    color = {1.0, 1.0, 1.0},   shape = 'diamond'},
    {name = 'magnet_burst', color = {1.0, 0.6, 0.1},   shape = 'star'},
    {name = 'score_bonus',  color = {1.0, 0.85, 0.1},  shape = 'coin'},
    {name = 'speed_boost',  color = {0.1, 1.0, 0.4},   shape = 'arrow'},
    {name = 'double_laser', color = {0.8, 0.2, 1.0},   shape = 'cross'},
}

function Powerup:initialize(pos, typeIndex, velocity)
    Entity.initialize(self, 'powerup', 0, pos)
    typeIndex = typeIndex or math.random(1, #Powerup.TYPES)
    self.powerupType = Powerup.TYPES[typeIndex]
    self.radius = 10
    self.velocity = velocity or vector(0, 100)
    self.life = 8
    self.maxLife = 8
    self.bobTime = 0
    self.rotation = 0
end

function Powerup:update(dt)
    Entity.update(self, dt)
    self.pos = self.pos + self.velocity * dt
    self.life = self.life - dt
    self.bobTime = self.bobTime + dt
    self.rotation = self.rotation + dt * 2

    if self.life <= 0 then
        self:destroy()
    end
end

function Powerup:draw()
    local remaining = math.max(0, self.life / self.maxLife)
    local alpha = remaining
    local bob = math.sin(self.bobTime * 3) * 4

    -- despawn warning: blink when <2 seconds left
    if self.life < 2 then
        local blinkRate = 8 + (2 - self.life) * 6
        alpha = alpha * (math.sin(self.time * blinkRate) > 0 and 1 or 0.2)
    end

    local r, g, b = self.powerupType.color[1], self.powerupType.color[2], self.powerupType.color[3]

    love.graphics.push()
    love.graphics.translate(self.pos.x, self.pos.y + bob)
    love.graphics.rotate(self.rotation)

    -- glow
    love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, alpha * 0.3)
    love.graphics.circle('fill', 0, 0, self.radius * 2)

    local shape = self.powerupType.shape
    if shape == 'hexagon' then
        local verts = {}
        for i = 0, 5 do
            local angle = i * math.pi / 3
            table.insert(verts, math.cos(angle) * self.radius)
            table.insert(verts, math.sin(angle) * self.radius)
        end
        love.graphics.setColor(r, g, b, alpha * 0.8)
        love.graphics.polygon('fill', verts)
        love.graphics.setColor(1, 1, 1, alpha * 0.5)
        love.graphics.polygon('line', verts)
    elseif shape == 'diamond' then
        love.graphics.setColor(r, g, b, alpha * 0.8)
        love.graphics.polygon('fill', 0, -self.radius, self.radius*0.7, 0, 0, self.radius, -self.radius*0.7, 0)
        love.graphics.setColor(1, 1, 1, alpha * 0.5)
        love.graphics.polygon('line', 0, -self.radius, self.radius*0.7, 0, 0, self.radius, -self.radius*0.7, 0)
    elseif shape == 'star' then
        local verts = {}
        for i = 0, 4 do
            local angle = i * math.pi * 2 / 5 - math.pi / 2
            table.insert(verts, math.cos(angle) * self.radius)
            table.insert(verts, math.sin(angle) * self.radius)
            angle = angle + math.pi / 5
            table.insert(verts, math.cos(angle) * self.radius * 0.45)
            table.insert(verts, math.sin(angle) * self.radius * 0.45)
        end
        love.graphics.setColor(r, g, b, alpha * 0.8)
        love.graphics.polygon('fill', verts)
        love.graphics.setColor(1, 1, 1, alpha * 0.5)
        love.graphics.polygon('line', verts)
    elseif shape == 'coin' then
        love.graphics.setColor(r, g, b, alpha * 0.8)
        love.graphics.circle('fill', 0, 0, self.radius)
        love.graphics.setColor(r * 0.7, g * 0.7, b * 0.7, alpha * 0.6)
        love.graphics.circle('line', 0, 0, self.radius * 0.7)
        love.graphics.setColor(1, 1, 1, alpha * 0.5)
        love.graphics.circle('line', 0, 0, self.radius)
    elseif shape == 'arrow' then
        love.graphics.setColor(r, g, b, alpha * 0.8)
        love.graphics.polygon('fill',
            0, -self.radius,
            self.radius * 0.6, 0,
            self.radius * 0.3, 0,
            self.radius * 0.3, self.radius,
            -self.radius * 0.3, self.radius,
            -self.radius * 0.3, 0,
            -self.radius * 0.6, 0)
        love.graphics.setColor(1, 1, 1, alpha * 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.polygon('line',
            0, -self.radius,
            self.radius * 0.6, 0,
            self.radius * 0.3, 0,
            self.radius * 0.3, self.radius,
            -self.radius * 0.3, self.radius,
            -self.radius * 0.3, 0,
            -self.radius * 0.6, 0)
    elseif shape == 'cross' then
        love.graphics.setColor(r, g, b, alpha * 0.8)
        local t = self.radius * 0.3
        love.graphics.rectangle('fill', -t, -self.radius, t * 2, self.radius * 2)
        love.graphics.rectangle('fill', -self.radius, -t, self.radius * 2, t * 2)
        love.graphics.setColor(1, 1, 1, alpha * 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle('line', -t, -self.radius, t * 2, self.radius * 2)
        love.graphics.rectangle('line', -self.radius, -t, self.radius * 2, t * 2)
    end

    love.graphics.pop()
end

return Powerup
