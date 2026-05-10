-- NEW: Magnet burst shockwave that pushes nearby hazards outward.
Shockwave = class('Shockwave', Entity)

function Shockwave:initialize(pos)
    Entity.initialize(self, 'effect', 0, pos)
    self.radius = 0
    self.maxRadius = 200
    self.speed = 500
    self.life = 0.5
    self.maxLife = self.life
    self.pushed = {}
end

function Shockwave:update(dt)
    Entity.update(self, dt)
    self.radius = self.radius + self.speed * dt
    self.life = self.life - dt

    for _, entity in ipairs(self.gameState:getEntitiesByTag('obstacle')) do
        if not self.pushed[entity.id] then
            local dist = (entity.pos - self.pos):len()
            if dist < self.radius + entity.radius and dist > self.radius - 30 then
                self.pushed[entity.id] = true
                local dir = (entity.pos - self.pos):normalized()
                if dir:len() == 0 then dir = vector(1, 0) end
                local pushSpeed = 200 * math.max(0, 1 - dist / self.maxRadius)
                entity.velocity = entity.velocity + dir * pushSpeed
            end
        end
    end

    for _, entity in ipairs(self.gameState:getEntitiesByTag('projectile')) do
        if not self.pushed[entity.id] then
            local dist = (entity.pos - self.pos):len()
            if dist < self.radius + 10 and dist > self.radius - 30 then
                self.pushed[entity.id] = true
                local dir = (entity.pos - self.pos):normalized()
                if dir:len() == 0 then dir = vector(1, 0) end
                local pushSpeed = 250 * math.max(0, 1 - dist / self.maxRadius)
                entity.velocity = entity.velocity + dir * pushSpeed
            end
        end
    end

    if self.life <= 0 then
        self:destroy()
    end
end

function Shockwave:draw()
    local progress = math.min(1, self.radius / self.maxRadius)
    local alpha = math.max(0, self.life / self.maxLife) * (1 - progress) * 0.7
    love.graphics.setColor(0.2, 0.9, 1.0, alpha)
    love.graphics.setLineWidth(4)
    love.graphics.circle('line', self.pos.x, self.pos.y, self.radius)

    love.graphics.setColor(0.4, 0.95, 1.0, alpha * 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.circle('line', self.pos.x, self.pos.y, self.radius * 0.85)

    love.graphics.setColor(0.6, 1.0, 1.0, alpha * 0.2)
    love.graphics.setLineWidth(8)
    love.graphics.circle('line', self.pos.x, self.pos.y, self.radius)
end

return Shockwave
