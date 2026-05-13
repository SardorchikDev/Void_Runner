-- Glowing enemy projectile entity used by scout and dreadnought ships.
Projectile = class('Projectile', Entity)

function Projectile:initialize(pos, velocity, color, size, life)
    Entity.initialize(self, 'projectile', 0, pos)
    self.velocity = velocity
    self.color = color or Color.CYAN
    self.size = size or 4
    self.life = life or 8
    self.maxLife = self.life
    self.glowPulse = 0
    self.velAngle = math.atan2(velocity.y, velocity.x)
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
    local sz = self.size
    local angle = self.velAngle

    love.graphics.push()
    love.graphics.translate(self.pos.x, self.pos.y)
    love.graphics.rotate(angle)

    -- outer glow (additive, 2x size)
    love.graphics.setBlendMode('add')
    love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, alpha * 0.08)
    love.graphics.ellipse('fill', 0, 0, sz * 10, sz * 2.4)
    love.graphics.setBlendMode('alpha')

    -- trailing ellipses (5 trailing, decreasing size and alpha)
    for i = 1, 5 do
        local t = i / 5
        local trailAlpha = alpha * (0.4 - t * 0.4)
        local trailSize = sz * (1.0 - t * 0.6)
        love.graphics.setColor(r * 0.5, g * 0.5, b * 0.5, trailAlpha)
        love.graphics.ellipse('fill', -3 * i * sz * 0.3, 0, trailSize * 2, trailSize * 0.8)
    end

    -- main body (elongated ellipse)
    love.graphics.setColor(r * 0.5, g * 0.5, b * 0.5, alpha * 0.6)
    love.graphics.ellipse('fill', 0, 0, sz * 5, sz * 1.2)

    -- bright core
    love.graphics.setColor(r, g, b, alpha * self.glowPulse)
    love.graphics.ellipse('fill', 0, 0, sz * 3, sz * 0.8)

    -- front tip (bright white)
    love.graphics.setColor(1, 1, 1, alpha * 0.8)
    love.graphics.circle('fill', sz * 3, 0, 2)

    love.graphics.pop()
end

function Projectile:collidesWith(player_shape)
    local cx, cy = player_shape:center()
    local dx = self.pos.x - cx
    local dy = self.pos.y - cy
    return (dx * dx + dy * dy) < (self.size + 8) * (self.size + 8)
end

return Projectile
