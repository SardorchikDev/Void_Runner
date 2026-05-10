-- NEW: Visual-only asteroid debris fragments spawned on impact.
Fragment = class('Fragment', Entity)

function Fragment:initialize(pos, velocity, size, color, rotation, rotSpeed)
    Entity.initialize(self, 'fragment', -1, pos)
    self.velocity = velocity
    self.size = size or lume.random(3, 8)
    self.baseColor = color or Color.DARK_GREY
    self.rotation = rotation or 0
    self.rotSpeed = rotSpeed or lume.random(-2, 2)
    self.life = lume.random(0.5, 1.5)
    self.maxLife = self.life

    local verts = {}
    local numVerts = math.random(3, 5)
    for i = 1, numVerts do
        local angle = (i - 1) * (math.pi * 2 / numVerts) + lume.random(-0.3, 0.3)
        local r = self.size * lume.random(0.6, 1.0)
        table.insert(verts, math.cos(angle) * r)
        table.insert(verts, math.sin(angle) * r)
    end
    self.vertices = verts
end

function Fragment:update(dt)
    Entity.update(self, dt)
    self.pos = self.pos + self.velocity * dt
    self.rotation = self.rotation + self.rotSpeed * dt
    self.velocity = self.velocity * 0.98
    self.life = self.life - dt
    if self.life <= 0 then
        self:destroy()
    end
end

function Fragment:draw()
    local alpha = math.max(0, self.life / self.maxLife)
    local r, g, b = self.baseColor.r, self.baseColor.g, self.baseColor.b

    love.graphics.push()
    love.graphics.translate(self.pos:unpack())
    love.graphics.rotate(self.rotation)

    love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, alpha * 0.5)
    love.graphics.polygon('fill', self.vertices)

    love.graphics.setColor(r * 0.6, g * 0.6, b * 0.6, alpha * 0.8)
    love.graphics.setLineWidth(1)
    love.graphics.polygon('line', self.vertices)

    love.graphics.pop()
end

return Fragment
