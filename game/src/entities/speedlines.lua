-- NEW: Hyperspace streaks that appear after the player reaches deeper zones.
SpeedLines = class('SpeedLines', Entity)

function SpeedLines:initialize(starsEntity)
    Entity.initialize(self, 'effect', -4, vector(0, 0))
    self.stars = starsEntity
end

function SpeedLines:update(dt)
    Entity.update(self, dt)
end

function SpeedLines:draw()
    if not self.stars then return end
    local scrollSpeed = self.gameState.scrollSpeed or 0
    if (self.gameState.depth or 0) < 1000 then return end

    local intensity = math.min(1, math.max(0, (scrollSpeed - 140) / 360)) * 0.12
    local length = scrollSpeed * 0.06
    if self.gameState.timeWarpActive then
        intensity = intensity * 0.3
        length = length * 0.3
    end

    for i, layer in ipairs(self.stars.starlayers) do
        if i >= 3 then
            for _, star in ipairs(layer) do
                if star.size > 2 then
                    local alpha = star.brightness * intensity * (star.size / 4)
                    love.graphics.setColor(0.6, 0.7, 1.0, alpha)
                    love.graphics.setLineWidth(math.max(1, star.size * 0.5))
                    love.graphics.line(star.pos.x, star.pos.y, star.pos.x, star.pos.y - length)
                end
            end
        end
    end
end

return SpeedLines
