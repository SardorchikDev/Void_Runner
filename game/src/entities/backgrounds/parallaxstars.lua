-- NEW: Realistic deep-space parallax background with spectral star colors, Milky Way dust, and shooting stars.
ParallaxStars = class('ParallaxStars', Entity)
ParallaxStars.static.COUNT = 280
ParallaxStars.static.NEBULA_COUNT = 8
ParallaxStars.static.LAYER_SPEEDS = {0.15, 0.35, 0.6, 1.0}

-- Realistic star spectral colors (O B A F G K M)
ParallaxStars.static.STAR_COLORS = {
    {0.55, 0.65, 1.0},   -- O-type (blue-white)
    {0.6,  0.7,  1.0},   -- B-type (blue-white)
    {0.75, 0.85, 1.0},   -- A-type (white)
    {1.0,  1.0,  1.0},   -- F-type (white-yellow)
    {1.0,  0.95, 0.75},  -- G-type (yellow, like our Sun)
    {1.0,  0.75, 0.45},  -- K-type (orange)
    {1.0,  0.5,  0.35},  -- M-type (red)
}

function ParallaxStars:initialize()
    Entity.initialize(self, 'background', -5, vector(0, 0))
    self.starlayers = {}
    self.nebulas = {}
    self.galaxies = {}
    self.milkyWayBands = {}
    self.shootingStars = {}

    for i = 1, #ParallaxStars.LAYER_SPEEDS do table.insert(self.starlayers, {}) end
end

function ParallaxStars:start()
    self.left, self.top = self.gameState.cam:worldCoords(0, 0)
    self.right, self.bottom = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
    local worldW = self.right - self.left
    local worldH = self.bottom - self.top

    -- distribute stars across layers with realistic weights
    local spectralWeights = {1, 3, 8, 12, 15, 10, 5} -- more common: F, G, K
    for i = 1, ParallaxStars.COUNT do
        local layerIdx = math.random(1, #self.starlayers)
        local layer = self.starlayers[layerIdx]
        local x = lume.random(self.left - worldW * 0.3, self.right + worldW * 0.3)
        local y = lume.random(self.top - worldH * 0.3, self.bottom + worldH * 0.3)

        -- pick spectral type by weight
        local specRoll = math.random(1, 54)
        local specIdx = 1
        local accum = 0
        for w = 1, #spectralWeights do
            accum = accum + spectralWeights[w]
            if specRoll <= accum then
                specIdx = w
                break
            end
        end

        local sizeRoll = math.random()
        local size = 1
        if sizeRoll > 0.985 then size = 4      -- rare giant
        elseif sizeRoll > 0.92 then size = 3   -- bright star
        elseif sizeRoll > 0.7 then size = 2    -- average
        end

        table.insert(layer, {
            pos = vector(x, y),
            size = size,
            brightness = lume.random(0.35, 1.0),
            twinkleSpeed = lume.random(1.5, 6),
            twinkleOffset = lume.random(0, math.pi * 2),
            color = ParallaxStars.static.STAR_COLORS[specIdx],
            isGiant = size >= 3
        })
    end

    -- nebulas with realistic space colors
    for i = 1, ParallaxStars.NEBULA_COUNT do
        table.insert(self.nebulas, {
            pos = vector(
                lume.random(self.left - worldW * 0.4, self.right + worldW * 0.4),
                lume.random(self.top - worldH * 0.4, self.bottom + worldH * 0.4)
            ),
            size = lume.random(100, 280),
            rotation = lume.random(0, math.pi * 2),
            rotationSpeed = lume.random(-0.08, 0.08),
            color = lume.randomchoice({
                {0.08, 0.15, 0.35, 0.12}, -- blue reflection nebula
                {0.25, 0.08, 0.15, 0.10}, -- red emission nebula
                {0.15, 0.05, 0.25, 0.09}, -- purple planetary
                {0.08, 0.25, 0.15, 0.08}, -- greenish (OIII)
                {0.2,  0.12, 0.08, 0.09}, -- warm brown dust
            })
        })
    end

    -- distant galaxies / galaxy clusters
    for i = 1, 6 do
        table.insert(self.galaxies, {
            pos = vector(
                lume.random(self.left - worldW * 0.6, self.right + worldW * 0.6),
                lume.random(self.top - worldH * 0.6, self.bottom + worldH * 0.6)
            ),
            width = lume.random(120, 350),
            height = lume.random(30, 90),
            rotation = lume.random(0, math.pi * 2),
            color = lume.randomchoice({
                {0.15, 0.08, 0.25, 0.035},
                {0.08, 0.04, 0.18, 0.04},
                {0.12, 0.08, 0.2, 0.03},
            })
        })
    end

    -- Milky Way dust bands
    for i = 1, 5 do
        table.insert(self.milkyWayBands, {
            pos = vector(
                lume.random(self.left - worldW * 0.3, self.right + worldW * 0.3),
                lume.random(self.top - worldH * 0.5, self.bottom + worldH * 0.5)
            ),
            width = lume.random(300, 700),
            height = lume.random(20, 60),
            rotation = lume.random(-0.3, 0.3),
            color = {0.12, 0.1, 0.15, 0.06},
            driftSpeed = lume.random(0.5, 1.2)
        })
    end

    self.time = 0
    self.zoneColor = {r = 0, g = 0, b = 0}
    self.shootingStarTimer = lume.random(2, 6)
end

function ParallaxStars:setZoneColor(zc)
    self.zoneColor = zc or {r = 0, g = 0, b = 0}
end

function ParallaxStars:draw()
    local zr = self.zoneColor.r or 0
    local zg = self.zoneColor.g or 0
    local zb = self.zoneColor.b or 0

    -- galaxies (farthest back)
    for _, galaxy in ipairs(self.galaxies) do
        love.graphics.setColor(
            math.min(1, galaxy.color[1] + zr * 0.3),
            math.min(1, galaxy.color[2] + zg * 0.3),
            math.min(1, galaxy.color[3] + zb * 0.3),
            galaxy.color[4]
        )
        love.graphics.push()
        love.graphics.translate(galaxy.pos:unpack())
        love.graphics.rotate(galaxy.rotation)
        for i = 3, 1, -1 do
            love.graphics.ellipse('fill', 0, 0, galaxy.width * i / 3, galaxy.height * i / 3)
        end
        love.graphics.pop()
    end

    -- Milky Way dust bands
    for _, band in ipairs(self.milkyWayBands) do
        love.graphics.setColor(
            math.min(1, band.color[1] + zr * 0.2),
            math.min(1, band.color[2] + zg * 0.2),
            math.min(1, band.color[3] + zb * 0.2),
            band.color[4]
        )
        love.graphics.push()
        love.graphics.translate(band.pos:unpack())
        love.graphics.rotate(band.rotation)
        love.graphics.ellipse('fill', 0, 0, band.width, band.height)
        love.graphics.pop()
    end

    -- nebulas
    for _, nebula in ipairs(self.nebulas) do
        love.graphics.setColor(
            math.min(1, nebula.color[1] + zr * 0.3),
            math.min(1, nebula.color[2] + zg * 0.3),
            math.min(1, nebula.color[3] + zb * 0.3),
            nebula.color[4]
        )
        love.graphics.push()
        love.graphics.translate(nebula.pos:unpack())
        love.graphics.rotate(nebula.rotation)
        for i = 3, 1, -1 do
            love.graphics.circle('fill', 0, 0, nebula.size * i / 3)
        end
        love.graphics.pop()
    end

    -- stars
    for i, layer in ipairs(self.starlayers) do
        local speed = ParallaxStars.LAYER_SPEEDS[i]
        for j, star in ipairs(layer) do
            local twinkle = math.sin(self.time * star.twinkleSpeed + star.twinkleOffset) * 0.3 + 0.7
            local alpha = star.brightness * twinkle * speed * 0.5

            local sr = math.min(1, star.color[1] + zr * 0.3)
            local sg = math.min(1, star.color[2] + zg * 0.3)
            local sb = math.min(1, star.color[3] + zb * 0.3)

            -- bloom glow for giant stars
            if star.isGiant then
                local glowAlpha = alpha * 0.15
                love.graphics.setColor(sr, sg, sb, glowAlpha)
                love.graphics.circle('fill', star.pos.x, star.pos.y, star.size * 5)
                love.graphics.setColor(sr, sg, sb, glowAlpha * 1.5)
                love.graphics.circle('fill', star.pos.x, star.pos.y, star.size * 2.5)
            end

            love.graphics.setColor(sr, sg, sb, alpha)
            love.graphics.circle('fill', star.pos.x, star.pos.y, star.size)

            -- cross flare for very bright stars
            if star.isGiant and star.brightness > 0.8 then
                love.graphics.setColor(sr, sg, sb, alpha * 0.3)
                love.graphics.setLineWidth(0.5)
                local flareLen = star.size * 6
                love.graphics.line(star.pos.x - flareLen, star.pos.y, star.pos.x + flareLen, star.pos.y)
                love.graphics.line(star.pos.x, star.pos.y - flareLen, star.pos.x, star.pos.y + flareLen)
            end
        end
    end

    -- shooting stars
    for _, ss in ipairs(self.shootingStars) do
        local alpha = math.max(0, ss.life / ss.maxLife)
        love.graphics.setLineWidth(1.5)
        -- head
        love.graphics.setColor(1, 1, 1.0, alpha)
        love.graphics.circle('fill', ss.pos.x, ss.pos.y, 1.5)
        -- tail fade
        for t = 1, 8 do
            local trailAlpha = alpha * (1 - t / 8) * 0.4
            local tx = ss.pos.x - ss.vel.x * t * 0.015
            local ty = ss.pos.y - ss.vel.y * t * 0.015
            love.graphics.setColor(0.7, 0.85, 1.0, trailAlpha)
            love.graphics.circle('fill', tx, ty, 1.2 - t * 0.1)
        end
    end
end

function ParallaxStars:update(dt)
    self.time = self.time + dt

    if self.gameState and self.gameState.cam then
        self.left, self.top = self.gameState.cam:worldCoords(0, 0)
        self.right, self.bottom = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
    end

    local baseSpeed = (self.gameState and self.gameState.scrollSpeed) and (self.gameState.scrollSpeed * 0.35) or 40
    if self.gameState and self.gameState.timeWarpActive then
        baseSpeed = baseSpeed * 0.25
    end

    -- shooting stars
    self.shootingStarTimer = self.shootingStarTimer - dt
    if self.shootingStarTimer <= 0 then
        self.shootingStarTimer = lume.random(3, 8)
        if math.random() < 0.6 then
            local angle = lume.random(math.pi * 0.1, math.pi * 0.4)
            local speed = lume.random(400, 700)
            table.insert(self.shootingStars, {
                pos = vector(
                    lume.random(self.left, self.right),
                    self.top - lume.random(20, 80)
                ),
                vel = vector(math.cos(angle) * speed, math.sin(angle) * speed),
                life = lume.random(0.4, 0.9),
                maxLife = 0.9
            })
        end
    end

    for i = #self.shootingStars, 1, -1 do
        local ss = self.shootingStars[i]
        ss.pos = ss.pos + ss.vel * dt
        ss.life = ss.life - dt
        if ss.life <= 0 or ss.pos.y > self.bottom + 100 then
            table.remove(self.shootingStars, i)
        end
    end

    for _, galaxy in ipairs(self.galaxies) do
        galaxy.pos.y = galaxy.pos.y + baseSpeed * dt * 0.08
        if galaxy.pos.y < self.top - galaxy.height then
            galaxy.pos.y = self.bottom + lume.random(40, 180)
            galaxy.pos.x = lume.random(self.left, self.right)
        elseif galaxy.pos.y > self.bottom + galaxy.height then
            galaxy.pos.y = self.top - lume.random(40, 180)
            galaxy.pos.x = lume.random(self.left, self.right)
        end
    end

    for _, band in ipairs(self.milkyWayBands) do
        band.pos.y = band.pos.y + baseSpeed * dt * band.driftSpeed * 0.05
        if band.pos.y < self.top - 200 then
            band.pos.y = self.bottom + lume.random(40, 200)
            band.pos.x = lume.random(self.left, self.right)
        elseif band.pos.y > self.bottom + 200 then
            band.pos.y = self.top - lume.random(40, 200)
            band.pos.x = lume.random(self.left, self.right)
        end
    end

    for _, nebula in ipairs(self.nebulas) do
        nebula.rotation = nebula.rotation + nebula.rotationSpeed * dt
        nebula.pos.y = nebula.pos.y + baseSpeed * dt * 0.18
        if nebula.pos.y < self.top - nebula.size then
            nebula.pos.y = self.bottom + lume.random(30, 140)
            nebula.pos.x = lume.random(self.left, self.right)
        elseif nebula.pos.y > self.bottom + nebula.size then
            nebula.pos.y = self.top - lume.random(30, 140)
            nebula.pos.x = lume.random(self.left, self.right)
        end
    end

    for i, layer in ipairs(self.starlayers) do
        local speed = ParallaxStars.LAYER_SPEEDS[i]
        for j, star in ipairs(layer) do
            star.pos.y = star.pos.y + baseSpeed * dt * speed
            if star.pos.y < self.top - 10 then
                star.pos.y = self.bottom + 10
                star.pos.x = lume.random(self.left, self.right)
            elseif star.pos.y > self.bottom + 10 then
                star.pos.y = self.top - 10
                star.pos.x = lume.random(self.left, self.right)
            end
        end
    end
end

return ParallaxStars
