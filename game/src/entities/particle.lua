-- MODIFIED: Existing particle helpers fixed so systems can own and update particles locally.
Particle = class('Particle', Entity)

function Particle:initialize(pos, velocity, color, size, life, decay)
    Entity.initialize(self, 'particle', -3, pos)
    self.velocity = velocity
    self.color = color
    self.size = size
    self.life = life
    self.maxLife = life
    self.decay = decay or 0.98
    self.glow = 0
end

function Particle:update(dt)
    self.pos = self.pos + self.velocity * dt
    self.velocity = self.velocity * self.decay
    self.life = self.life - dt
    self.glow = math.sin(self.life / self.maxLife * math.pi) * 0.5 + 0.5

    if self.life <= 0 then
        self:destroy()
    end
end

function Particle:draw()
    local alpha = math.max(0, self.life / self.maxLife)
    local r, g, b = self.color.r, self.color.g, self.color.b

    love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, alpha * 0.3)
    love.graphics.circle('fill', self.pos.x, self.pos.y, self.size * 2)

    love.graphics.setColor(r, g, b, alpha)
    love.graphics.circle('fill', self.pos.x, self.pos.y, self.size)
end

ParticleSystem = class('ParticleSystem', Entity)

function ParticleSystem:initialize()
    Entity.initialize(self, 'particles', -4, vector(0, 0))
    self.particles = {}
end

function ParticleSystem:emit(x, y, count, config)
    config = config or {}
    for i = 1, count do
        local angle = (config.angle or 0) + (config.spread or 0) * (math.random() - 0.5)
        local speed = (config.speed or 50) * (0.5 + math.random() * 0.5)
        local velocity = vector(math.cos(angle) * speed, math.sin(angle) * speed)

        local color = config.color or Color.CYAN
        local size = (config.size or 3) * (0.5 + math.random() * 0.5)
        local life = (config.life or 0.5) * (0.5 + math.random() * 0.5)

        local particle = Particle(
            vector(x, y),
            velocity,
            color:clone(),
            size,
            life,
            config.decay
        )
        particle:setGameState(self.gameState)
        table.insert(self.particles, particle)
    end
end

function ParticleSystem:draw()
    for _, particle in ipairs(self.particles) do
        particle:draw()
    end
end

function ParticleSystem:update(dt)
    local n = #self.particles
    local i = 1
    while i <= n do
        self.particles[i]:update(dt)
        if self.particles[i]:isDead() then
            self.particles[i] = self.particles[n]
            self.particles[n] = nil
            n = n - 1
        else
            i = i + 1
        end
    end
end

return ParticleSystem
