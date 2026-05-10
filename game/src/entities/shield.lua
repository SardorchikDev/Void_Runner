-- NEW: Hexagonal one-hit energy shield with automatic recharge.
Shield = class('Shield', Entity)

function Shield:initialize(player)
    Entity.initialize(self, 'shield', 0, player.pos:clone())
    self.player = player
    self.active = true
    self.rechargeTime = 0
    self.rechargeDuration = 3.0
    self.hexRotation = 0
    self.flashTime = 0
end

function Shield:activate()
    self.active = true
    self.rechargeTime = 0
end

function Shield:absorb()
    if not self.active then return false end
    self.active = false
    self.rechargeTime = self.rechargeDuration
    self.flashTime = 0.15
    return true
end

function Shield:isActive()
    return self.active
end

function Shield:isRecharging()
    return not self.active and self.rechargeTime > 0
end

function Shield:canActivate()
    return not self.active and self.rechargeTime <= 0
end

function Shield:update(dt)
    Entity.update(self, dt)
    if self.player then
        self.pos = self.player.pos:clone()
    end
    self.hexRotation = self.hexRotation + dt * 1.2
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    if self.rechargeTime > 0 then
        self.rechargeTime = self.rechargeTime - dt
        if self.rechargeTime <= 0 then
            self.rechargeTime = 0
            self.active = true
            self.flashTime = 0.12
        end
    end
end

function Shield:drawHexagon(cx, cy, radius, rotation)
    local verts = {}
    for i = 0, 5 do
        local angle = rotation + (i * math.pi / 3)
        table.insert(verts, cx + math.cos(angle) * radius)
        table.insert(verts, cy + math.sin(angle) * radius)
    end
    love.graphics.polygon('line', verts)
end

function Shield:draw()
    if not self.player then return end

    local cx, cy = self.pos.x, self.pos.y
    local baseRadius = 22
    local pulse = math.sin(self.time * 3) * 2

    if self.active then
        if self.flashTime > 0 then
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.setLineWidth(4)
            self:drawHexagon(cx, cy, baseRadius + 8 + pulse, self.hexRotation)
        end

        love.graphics.setColor(0.1, 0.8, 1.0, 0.25 + pulse * 0.02)
        love.graphics.setLineWidth(6)
        self:drawHexagon(cx, cy, baseRadius + 6, self.hexRotation)

        love.graphics.setColor(0.1, 0.8, 1.0, 0.4 + pulse * 0.03)
        love.graphics.setLineWidth(3)
        self:drawHexagon(cx, cy, baseRadius + pulse, self.hexRotation)

        love.graphics.setColor(0.2, 0.9, 1.0, 0.6)
        love.graphics.setLineWidth(1.5)
        self:drawHexagon(cx, cy, baseRadius - 3 + pulse * 0.5, self.hexRotation)
    elseif self.rechargeTime > 0 then
        local progress = 1 - (self.rechargeTime / self.rechargeDuration)
        love.graphics.setColor(0.3, 0.3, 0.35, 0.3)
        love.graphics.setLineWidth(3)
        love.graphics.arc('line', 'open', cx + 28, cy, 6, -math.pi * 0.5, -math.pi * 0.5 + progress * math.pi * 2)

        love.graphics.setColor(0.5, 0.5, 0.6, 0.5)
        love.graphics.setLineWidth(1.5)
        love.graphics.arc('line', 'open', cx + 28, cy, 6, -math.pi * 0.5, -math.pi * 0.5 + progress * math.pi * 2)
    end
end

return Shield
