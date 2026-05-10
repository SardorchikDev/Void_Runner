-- NEW: Red edge warning arrow for hazards entering the visible playfield.
WarningIndicator = class('WarningIndicator', Entity)

function WarningIndicator:initialize(targetPos, edge, life)
    Entity.initialize(self, 'warning', 1, targetPos)
    self.edge = edge or 'top'
    self.life = life or 0.5
    self.maxLife = self.life
    self.pulse = 0
end

function WarningIndicator:update(dt)
    Entity.update(self, dt)
    self.life = self.life - dt
    self.pulse = math.sin(self.time * 10) * 0.3 + 0.7
    if self.life <= 0 then
        self:destroy()
    end
end

function WarningIndicator:draw()
    local alpha = math.min(1, self.life / self.maxLife) * 0.9 * self.pulse
    love.graphics.setColor(1, 0.1, 0.1, alpha)

    local camL, camT = self.gameState.cam:worldCoords(0, 0)
    local camR, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())

    local x, y, angle = self.pos.x, self.pos.y, 0

    if self.edge == 'left' then
        x = camL + 12
        y = self.pos.y
        angle = math.pi * 0.5
    elseif self.edge == 'right' then
        x = camR - 12
        y = self.pos.y
        angle = -math.pi * 0.5
    elseif self.edge == 'top' then
        x = lume.clamp(self.pos.x, camL + 12, camR - 12)
        y = camT + 12
        angle = math.pi
    else
        x = lume.clamp(self.pos.x, camL + 12, camR - 12)
        y = camB - 12
        angle = 0
    end

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)
    love.graphics.polygon('fill', -6, -4, 6, 0, -6, 4)
    love.graphics.pop()
end

return WarningIndicator
