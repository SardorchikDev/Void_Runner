-- NEW: Glowing enemy projectile entity used by scout and dreadnought ships.
Projectile = class('Projectile', Entity)

function Projectile:initialize(pos, velocity, color, size, life)
    Entity.initialize(self, 'projectile', 0, pos)
    self.velocity = velocity
    self.color = color or Color.CYAN
    self.size = size or 4
    self.life = life or 8
    self.maxLife = self.life
    self.glowPulse = 0
end

function Projectile:update(dt)
    Entity.update(self, dt)
    self.pos = self.pos + self.velocity * dt
    self.life = self.life - dt
    self.glowPulse = math.sin(self.time * 8) * 0.3 + 0.7

    if self.life <= 0 then
        self:destroy()
    end
end

function Projectile:draw()
    local alpha = math.min(1, self.life / 1.0) * math.max(0, math.min(1, self.life / self.maxLife))
    local r, g, b = self.color.r, self.color.g, self.color.b
    local tail = self.velocity:normalized() * -self.size * 5

    love.graphics.setColor(r * 0.35, g * 0.35, b * 0.35, alpha * 0.25)
    love.graphics.setLineWidth(self.size * 0.7)
    love.graphics.line(self.pos.x, self.pos.y, self.pos.x + tail.x, self.pos.y + tail.y)

    love.graphics.setColor(r * 0.2, g * 0.2, b * 0.2, alpha * 0.4)
    love.graphics.circle('fill', self.pos.x, self.pos.y, self.size * 3)

    love.graphics.setColor(r * 0.5, g * 0.5, b * 0.5, alpha * 0.6)
    love.graphics.circle('fill', self.pos.x, self.pos.y, self.size * 1.5)

    love.graphics.setColor(r, g, b, alpha * self.glowPulse)
    love.graphics.circle('fill', self.pos.x, self.pos.y, self.size)

    love.graphics.setColor(1, 1, 1, alpha * 0.8)
    love.graphics.circle('fill', self.pos.x, self.pos.y, self.size * 0.4)
end

function Projectile:collidesWith(player_shape)
    local cx, cy = player_shape:center()
    local dx = self.pos.x - cx
    local dy = self.pos.y - cy
    return (dx * dx + dy * dy) < (self.size + 8) * (self.size + 8)
end

return Projectile
