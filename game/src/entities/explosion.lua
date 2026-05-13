-- Reusable particle burst for ship destruction and impact feedback.
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

    self.isLarge = count >= 50

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

        local isStreak = math.random() < 0.2

        table.insert(self.particles, {
            pos = vector(0, 0),
            velocity = vel,
            color = {r, g, b},
            size = size,
            life = life,
            maxLife = life,
            decay = lume.random(0.92, 0.98),
            isStreak = isStreak,
        })
    end

    self.maxLife = 1.2
    self.life = self.maxLife
    self.ringRadius = 0
    self.ringMax = 60
    self.ring2Radius = 0
    self.ring2Max = self.ringMax * 0.6
    self.ring2Duration = 0.3
end

function Explosion:update(dt)
    Entity.update(self, dt)
    self.life = self.life - dt
    self.ringRadius = self.ringRadius + self.ringMax / self.maxLife * dt

    -- secondary shockwave ring
    local elapsed = self.maxLife - self.life
    if elapsed < self.ring2Duration then
        self.ring2Radius = (elapsed / self.ring2Duration) * self.ring2Max
    end

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
    local elapsed = self.maxLife - self.life

    -- large explosion screen flash
    if self.isLarge and elapsed < 0.08 then
        love.graphics.setColor(1, 1, 1, 0.12)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    love.graphics.push()
    love.graphics.translate(self.pos:unpack())

    for _, p in ipairs(self.particles) do
        if p.life > 0 then
            local pa = math.max(0, p.life / p.maxLife) * alpha
            local r, g, b = p.color[1], p.color[2], p.color[3]

            if p.isStreak then
                -- streak variant: short line in velocity direction
                local vLen = p.velocity:len()
                if vLen > 0 then
                    local streakLen = vLen * 0.04
                    local dx = p.velocity.x / vLen * streakLen
                    local dy = p.velocity.y / vLen * streakLen
                    love.graphics.setColor(r, g, b, pa)
                    love.graphics.setLineWidth(math.max(1, p.size * 0.5))
                    love.graphics.line(p.pos.x, p.pos.y, p.pos.x - dx, p.pos.y - dy)
                end
            else
                love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, pa * 0.3)
                love.graphics.circle('fill', p.pos.x, p.pos.y, p.size * 2)

                love.graphics.setColor(r, g, b, pa)
                love.graphics.circle('fill', p.pos.x, p.pos.y, p.size)
            end
        end
    end

    -- primary shockwave ring
    local ringAlpha = alpha * 0.5 * (1 - self.ringRadius / self.ringMax)
    love.graphics.setColor(1, 0.8, 0.4, ringAlpha)
    love.graphics.setLineWidth(3)
    love.graphics.circle('line', 0, 0, self.ringRadius)

    love.graphics.setColor(1, 0.6, 0.2, ringAlpha * 0.5)
    love.graphics.setLineWidth(6)
    love.graphics.circle('line', 0, 0, self.ringRadius * 0.9)

    -- secondary shockwave ring
    if elapsed < self.ring2Duration then
        local r2Alpha = (1 - elapsed / self.ring2Duration) * 0.6
        love.graphics.setColor(1, 1, 1, r2Alpha)
        love.graphics.setLineWidth(8)
        love.graphics.circle('line', 0, 0, self.ring2Radius)
    end

    love.graphics.pop()
end

return Explosion
