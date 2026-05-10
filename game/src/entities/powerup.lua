-- NEW: Collectible shield, time-warp, and magnet-burst powerups for Void Runner.
Powerup = class('Powerup', Entity)

Powerup.static.SHIELD = 1
Powerup.static.TIME_WARP = 2
Powerup.static.MAGNET_BURST = 3

Powerup.static.COLORS = {
    [Powerup.static.SHIELD] = Color.SHIELD_CYAN,
    [Powerup.static.TIME_WARP] = Color.WHITE,
    [Powerup.static.MAGNET_BURST] = Color.ORANGE
}

function Powerup:initialize(pos, ptype, velocity)
    Entity.initialize(self, 'powerup', 0, pos)
    self.ptype = ptype or Powerup.SHIELD
    self.velocity = velocity or vector(0, 100)
    self.life = 8
    self.maxLife = self.life
    self.bobOffset = lume.random(0, math.pi * 2)
    self.rotation = 0
    self.rotSpeed = lume.random(-1, 1)
    self.color = Powerup.COLORS[self.ptype]
end

function Powerup:update(dt)
    Entity.update(self, dt)
    self.pos = self.pos + self.velocity * dt
    self.rotation = self.rotation + self.rotSpeed * dt
    self.life = self.life - dt
    if self.life <= 0 then
        self:destroy()
    end
end

function Powerup:drawShape()
    if self.ptype == Powerup.SHIELD then
        local verts = {}
        for i = 0, 5 do
            local angle = self.rotation + (i * math.pi / 3)
            table.insert(verts, math.cos(angle) * 10)
            table.insert(verts, math.sin(angle) * 10)
        end
        love.graphics.polygon('fill', verts)
    elseif self.ptype == Powerup.TIME_WARP then
        love.graphics.push()
        love.graphics.rotate(self.rotation)
        love.graphics.polygon('fill', -8, 0, 0, -10, 8, 0, 0, 10)
        love.graphics.pop()
    else
        love.graphics.push()
        love.graphics.rotate(self.rotation)
        local verts = {}
        for i = 0, 4 do
            local angle = i * (math.pi * 2 / 5) - math.pi * 0.5
            local r = (i % 2 == 0) and 10 or 4
            table.insert(verts, math.cos(angle) * r)
            table.insert(verts, math.sin(angle) * r)
        end
        love.graphics.polygon('fill', verts)
        love.graphics.pop()
    end
end

function Powerup:draw()
    local alpha = math.min(1, self.life / 1.0)
    local bob = math.sin(self.time * 2 + self.bobOffset) * 3
    local r, g, b = self.color.r, self.color.g, self.color.b

    love.graphics.push()
    love.graphics.translate(self.pos.x, self.pos.y + bob)

    love.graphics.setColor(r * 0.2, g * 0.2, b * 0.2, alpha * 0.3)
    love.graphics.circle('fill', 0, 0, 16)

    love.graphics.setColor(r * 0.5, g * 0.5, b * 0.5, alpha * 0.4)
    love.graphics.circle('fill', 0, 0, 12)

    love.graphics.setColor(r, g, b, alpha * 0.9)
    self:drawShape()

    love.graphics.setColor(1, 1, 1, alpha * 0.5)
    love.graphics.circle('fill', 0, 0, 3)

    love.graphics.pop()
end

function Powerup:getTypeName()
    if self.ptype == Powerup.SHIELD then return "SHIELD" end
    if self.ptype == Powerup.TIME_WARP then return "TIME WARP" end
    return "MAGNET BURST"
end

return Powerup
