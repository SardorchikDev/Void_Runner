-- Engine exhaust particle layer for the Void Runner ship.
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

        local emission = 4
        if self.player.thrustActive then emission = 10 end
        if self.gameState and self.gameState.timeWarpActive then
            emission = math.max(1, math.floor(emission * 0.4))
        end

        for i = 1, emission do
            local colorT = math.min(1, (speed - 100) / 300)
            local r, g, b
            if speed > 200 then
                local heatT = math.min(1, (speed - 200) / 200)
                r = lume.lerp(0.6, 1.0, colorT)
                g = lume.lerp(0.8, 0.4, colorT)
                b = lume.lerp(1.0, 0.1, colorT)
                r = lume.lerp(r, 1.0, heatT)
                g = lume.lerp(g, 0.4, heatT)
                b = lume.lerp(b, 0.1, heatT)
            else
                r = lume.lerp(0.6, 1.0, colorT)
                g = lume.lerp(0.8, 0.4, colorT)
                b = lume.lerp(1.0, 0.1, colorT)
            end

            table.insert(self.particles, {
                pos = vector(
                    lume.random(-4, 4),
                    lume.random(6, 12)
                ),
                velocity = vector(lume.random(-20, 20), lume.random(45, 120)),
                color = {r, g, b},
                size = lume.random(1.5, 5),
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
    local W = Player.WIDTH
    local H = Player.HEIGHT

    love.graphics.push()
    love.graphics.translate(self.pos:unpack())
    love.graphics.rotate(self.player.angle)

    -- persistent engine core bloom (3 concentric circles per engine, additive)
    love.graphics.setBlendMode('add')
    local engines = {
        {x = -W * 0.45, y = H * 0.55},
        {x = W * 0.45,  y = H * 0.55},
        {x = 0,          y = H * 0.45},
    }
    for _, eng in ipairs(engines) do
        love.graphics.setColor(0.2, 0.5, 1.0, 0.06)
        love.graphics.circle('fill', eng.x, eng.y, 12)
        love.graphics.setColor(0.4, 0.75, 1.0, 0.15)
        love.graphics.circle('fill', eng.x, eng.y, 7)
        love.graphics.setColor(0.8, 0.95, 1.0, 0.5)
        love.graphics.circle('fill', eng.x, eng.y, 3)
    end
    love.graphics.setBlendMode('alpha')

    -- particles
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
