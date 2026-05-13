-- Hyperspace streaks that appear after the player reaches deeper zones.
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
    local depth = self.gameState.depth or 0
    if depth < 400 then return end

    local intensity = math.min(1, math.max(0, (scrollSpeed - 140) / 360)) * 0.12
    local length = scrollSpeed * 0.06
    if self.gameState.timeWarpActive then
        intensity = intensity * 0.3
        length = length * 0.3
    end

    -- primary pass (blue-white)
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

    -- secondary pass (purple chromatic, wider, 30% density)
    for i, layer in ipairs(self.stars.starlayers) do
        if i >= 3 then
            for j, star in ipairs(layer) do
                if star.size > 2 and (j % 3 == 0) then
                    local alpha = star.brightness * intensity * (star.size / 4) * 0.07
                    love.graphics.setColor(0.8, 0.6, 1.0, alpha)
                    love.graphics.setLineWidth(2.5)
                    love.graphics.line(star.pos.x, star.pos.y, star.pos.x, star.pos.y - length * 0.8)
                end
            end
        end
    end

    -- radial warp at depth >= 2000
    if depth >= 2000 then
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
        local centerX = w / 2
        local centerY = h / 2
        local warpLen = scrollSpeed * 0.08
        local warpAlpha = intensity * 0.04
        love.graphics.setBlendMode('add')
        love.graphics.setLineWidth(1)
        for i = 1, 16 do
            local angle = (i / 16) * math.pi * 2
            local sx = centerX + math.cos(angle) * 40
            local sy = centerY + math.sin(angle) * 40
            local ex = sx + math.cos(angle) * warpLen
            local ey = sy + math.sin(angle) * warpLen
            love.graphics.setColor(0.7, 0.7, 1.0, warpAlpha)
            love.graphics.line(sx, sy, ex, ey)
        end
        love.graphics.setBlendMode('alpha')
    end
end

return SpeedLines
