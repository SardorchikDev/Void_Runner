-- NEW: Engine exhaust particle layer for the Void Runner ship.
EngineGlow = class('EngineGlow', Entity)

function EngineGlow:initialize(player)
    Entity.initialize(self, 'effect', -1, player.pos:clone())
    self.player = player
    self.particles = {}
    self.time = 0
end

function EngineGlow:update(dt)
    Entity.update(self, dt)
    if self.player and not self.player:isDead() then
        self.pos = self.player.pos:clone()

        local safeDt = math.max(dt, 0.001)
        local speed = math.abs(self.player.pos.x - (self.player.last_pos and self.player.last_pos.x or self.player.pos.x)) / safeDt
        speed = speed + (self.player.scrollSpeed or 100)

        local emission = 2
        if self.player.thrustActive then emission = 6 end
        if self.gameState and self.gameState.timeWarpActive then
            emission = math.max(1, math.floor(emission * 0.4))
        end

        for i = 1, emission do
            local colorT = math.min(1, (speed - 100) / 300)
            local r = lume.lerp(0.6, 1.0, colorT)
            local g = lume.lerp(0.8, 0.4, colorT)
            local b = lume.lerp(1.0, 0.1, colorT)

            table.insert(self.particles, {
                pos = vector(
                    lume.random(-4, 4),
                    lume.random(6, 12)
                ),
                velocity = vector(lume.random(-20, 20), lume.random(45, 120)),
                color = {r, g, b},
                size = lume.random(1, 3.5),
                life = lume.random(0.08, 0.25),
                maxLife = 0.25,
                decay = lume.random(0.88, 0.95)
            })
        end
    end

    local n = #self.particles
    local i = 1
    while i <= n do
        local p = self.particles[i]
        p.pos = p.pos + p.velocity * dt
        p.velocity = p.velocity * p.decay
        p.life = p.life - dt
        if p.life <= 0 then
            self.particles[i] = self.particles[n]
            self.particles[n] = nil
            n = n - 1
        else
            i = i + 1
        end
    end
end

function EngineGlow:draw()
    if not self.player then return end
    love.graphics.push()
    love.graphics.translate(self.pos:unpack())
    love.graphics.rotate(self.player.angle)

    for _, p in ipairs(self.particles) do
        local alpha = math.max(0, p.life / p.maxLife)
        local r, g, b = p.color[1], p.color[2], p.color[3]

        love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, alpha * 0.2)
        love.graphics.circle('fill', p.pos.x, p.pos.y, p.size * 2.5)

        love.graphics.setColor(r, g, b, alpha * 0.6)
        love.graphics.circle('fill', p.pos.x, p.pos.y, p.size)
    end

    love.graphics.pop()
end

return EngineGlow
