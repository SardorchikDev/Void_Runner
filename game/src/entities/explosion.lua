-- NEW: Reusable particle burst for ship destruction and impact feedback.
Explosion = class('Explosion', Entity)

function Explosion:initialize(pos, count, colorRange)
    Entity.initialize(self, 'explosion', 0, pos)
    self.particles = {}
    count = count or 40
    colorRange = colorRange or {
        core = {1.0, 1.0, 0.8},
        mid = {1.0, 0.5, 0.1},
        outer = {0.8, 0.1, 0.05}
    }

    for i = 1, count do
        local angle = lume.random(0, math.pi * 2)
        local speed = lume.random(40, 200)
        local vel = vector(math.cos(angle) * speed, math.sin(angle) * speed)
        local life = lume.random(0.3, 1.0)
        local size = lume.random(2, 7)

        local t = math.random()
        local r, g, b
        if t < 0.3 then
            r, g, b = colorRange.core[1], colorRange.core[2], colorRange.core[3]
        elseif t < 0.7 then
            r, g, b = colorRange.mid[1], colorRange.mid[2], colorRange.mid[3]
        else
            r, g, b = colorRange.outer[1], colorRange.outer[2], colorRange.outer[3]
        end

        table.insert(self.particles, {
            pos = vector(0, 0),
            velocity = vel,
            color = {r, g, b},
            size = size,
            life = life,
            maxLife = life,
            decay = lume.random(0.92, 0.98)
        })
    end

    self.maxLife = 1.2
    self.life = self.maxLife
    self.ringRadius = 0
    self.ringMax = 60
end

function Explosion:update(dt)
    Entity.update(self, dt)
    self.life = self.life - dt
    self.ringRadius = self.ringRadius + self.ringMax / self.maxLife * dt

    for _, p in ipairs(self.particles) do
        if p.life > 0 then
            p.pos = p.pos + p.velocity * dt
            p.velocity = p.velocity * p.decay
            p.life = p.life - dt
        end
    end

    if self.life <= 0 then
        self:destroy()
    end
end

function Explosion:draw()
    local alpha = math.max(0, self.life / self.maxLife)

    love.graphics.push()
    love.graphics.translate(self.pos:unpack())

    for _, p in ipairs(self.particles) do
        if p.life > 0 then
            local pa = math.max(0, p.life / p.maxLife) * alpha
            local r, g, b = p.color[1], p.color[2], p.color[3]

            love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, pa * 0.3)
            love.graphics.circle('fill', p.pos.x, p.pos.y, p.size * 2)

            love.graphics.setColor(r, g, b, pa)
            love.graphics.circle('fill', p.pos.x, p.pos.y, p.size)
        end
    end

    local ringAlpha = alpha * 0.5 * (1 - self.ringRadius / self.ringMax)
    love.graphics.setColor(1, 0.8, 0.4, ringAlpha)
    love.graphics.setLineWidth(3)
    love.graphics.circle('line', 0, 0, self.ringRadius)

    love.graphics.setColor(1, 0.6, 0.2, ringAlpha * 0.5)
    love.graphics.setLineWidth(6)
    love.graphics.circle('line', 0, 0, self.ringRadius * 0.9)

    love.graphics.pop()
end

return Explosion
