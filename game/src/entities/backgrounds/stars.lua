Stars = class('Stars', Entity)
Stars.static.COUNT = 150
Stars.static.NEBULA_COUNT = 8
Stars.static.LAYER_SPEEDS = {0.3, 0.6, 1.0, 1.5}

function Stars:initialize()
    Entity.initialize(self, 'background', -5, vector(0, 0))
    self.starlayers = {}
    self.nebulas = {}

    for i=1, #Stars.LAYER_SPEEDS do table.insert(self.starlayers, {}) end
end

function Stars:start()
    self.left, self.top = self.gameState.cam:worldCoords(0, 0)
    self.right, self.bottom = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
    local worldW = self.right - self.left
    local worldH = self.bottom - self.top

    for i=1, Stars.COUNT do
        local layer = lume.randomchoice(self.starlayers)
        local x = lume.random(self.left - worldW * 0.2, self.right + worldW * 0.2)
        local y = lume.random(self.top - worldH * 0.2, self.bottom + worldH * 0.2)
        table.insert(layer, {
            pos = vector(x, y),
            size = lume.random(1, 4),
            brightness = lume.random(0.3, 1),
            twinkleSpeed = lume.random(2, 8),
            twinkleOffset = lume.random(0, math.pi * 2),
            colorType = lume.randomchoice({'white', 'blue', 'orange'})
        })
    end

    for i=1, Stars.NEBULA_COUNT do
        table.insert(self.nebulas, {
            pos = vector(
                lume.random(self.left - worldW * 0.3, self.right + worldW * 0.3),
                lume.random(self.top - worldH * 0.3, self.bottom + worldH * 0.3)
            ),
            size = lume.random(80, 200),
            rotation = lume.random(0, math.pi * 2),
            rotationSpeed = lume.random(-0.1, 0.1),
            color = lume.randomchoice({
                {0.1, 0.2, 0.4, 0.15},
                {0.2, 0.1, 0.3, 0.12},
                {0.15, 0.05, 0.2, 0.1}
            })
        })
    end

    self.time = 0
end

function Stars:draw()
    for _, nebula in ipairs(self.nebulas) do
        love.graphics.setColor(nebula.color[1], nebula.color[2], nebula.color[3], nebula.color[4])
        love.graphics.push()
        love.graphics.translate(nebula.pos:unpack())
        love.graphics.rotate(nebula.rotation)
        for i = 3, 1, -1 do
            love.graphics.circle('fill', 0, 0, nebula.size * i / 3)
        end
        love.graphics.pop()
    end

    for i, layer in ipairs(self.starlayers) do
        local speed = Stars.LAYER_SPEEDS[i]
        for j, star in ipairs(layer) do
            local twinkle = math.sin(self.time * star.twinkleSpeed + star.twinkleOffset) * 0.3 + 0.7
            local alpha = star.brightness * twinkle * speed * 0.4

            if star.colorType == 'blue' then
                love.graphics.setColor(0.4, 0.6, 1.0, alpha)
            elseif star.colorType == 'orange' then
                love.graphics.setColor(1.0, 0.7, 0.4, alpha)
            else
                love.graphics.setColor(0.9, 0.9, 1.0, alpha)
            end

            love.graphics.setLineStyle('smooth')
            love.graphics.setLineWidth(1)

            if star.size > 2.5 then
                local glowSize = star.size * (1 + twinkle * 0.5)
                love.graphics.circle('fill', star.pos.x, star.pos.y, glowSize * 2)
            end
            love.graphics.circle('fill', star.pos.x, star.pos.y, star.size)
        end
    end
end

function Stars:update(dt)
    self.time = self.time + dt

    for _, nebula in ipairs(self.nebulas) do
        nebula.rotation = nebula.rotation + nebula.rotationSpeed * dt
    end

    for i, layer in ipairs(self.starlayers) do
        local speed = Stars.LAYER_SPEEDS[i]
        for j, star in ipairs(layer) do
            star.pos.y = star.pos.y + 40 * dt * speed
            if star.pos.y > self.bottom + 10 then
                star.pos.y = self.top - 10
                star.pos.x = lume.random(self.left, self.right)
            end
        end
    end
end

return Stars