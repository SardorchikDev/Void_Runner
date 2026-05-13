-- Cinematic zone transition with scanline sweep, title flash, and color grade.
ZoneTransition = class('ZoneTransition', Entity)
ZoneTransition.static.FONT_CACHE = {}
ZoneTransition.static.SUB_FONT_CACHE = {}

function ZoneTransition:initialize(zoneName, zoneColor, zoneNum)
    Entity.initialize(self, 'transition', 1, vector(0, 0))
    self.zoneName = zoneName or "UNKNOWN"
    self.targetColor = zoneColor or {r = 0, g = 0, b = 0}
    self.zoneNum = zoneNum or 1
    self.life = 3.0
    self.maxLife = self.life
    self.textAlpha = 0
    self.textFadeIn = 0.3
    self.textFadeOut = 0.5
    self.textDuration = 1.8
    self.scanlineY = -0.1
    self.particles = {}

    for i = 1, 20 do
        table.insert(self.particles, {
            x = math.random(),
            y = math.random(),
            speed = lume.random(0.1, 0.4),
            size = lume.random(1, 3),
            alpha = lume.random(0.2, 0.6),
        })
    end
end

function ZoneTransition:update(dt)
    Entity.update(self, dt)
    self.life = self.life - dt
    self.scanlineY = self.scanlineY + dt * 0.6

    for _, p in ipairs(self.particles) do
        p.y = p.y - p.speed * dt
        if p.y < -0.1 then
            p.y = 1.1
            p.x = math.random()
        end
    end

    if self.life <= 0 then
        self:destroy()
    end
end

function ZoneTransition:draw()
end

function ZoneTransition:drawOverlay(scale)
    local progress = 1 - (self.life / self.maxLife)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local s = scale or 1
    local r, g, b = self.targetColor.r, self.targetColor.g, self.targetColor.b

    -- color grade overlay
    local alpha = math.sin(progress * math.pi) * 0.18
    love.graphics.setColor(r, g, b, alpha)
    love.graphics.rectangle('fill', 0, 0, w, h)

    -- scanline sweep
    if self.scanlineY >= 0 and self.scanlineY <= 1.2 then
        local sy = self.scanlineY * h
        local scanAlpha = math.sin(progress * math.pi) * 0.4
        love.graphics.setColor(r * 0.5 + 0.5, g * 0.5 + 0.5, b * 0.5 + 0.5, scanAlpha)
        love.graphics.setLineWidth(2 * s)
        love.graphics.line(0, sy, w, sy)
        love.graphics.setColor(1, 1, 1, scanAlpha * 0.3)
        love.graphics.rectangle('fill', 0, sy - 20 * s, w, 40 * s)
    end

    -- transition particles
    for _, p in ipairs(self.particles) do
        local pa = p.alpha * math.sin(progress * math.pi)
        love.graphics.setColor(r * 0.5 + 0.5, g * 0.5 + 0.5, b * 0.5 + 0.5, pa)
        love.graphics.circle('fill', p.x * w, p.y * h, p.size * s)
    end

    -- text
    local textProgress = (self.maxLife - self.life)
    local textAlpha = 0
    if textProgress < self.textFadeIn then
        textAlpha = textProgress / self.textFadeIn
    elseif textProgress < self.textFadeIn + self.textDuration then
        textAlpha = 1
    else
        textAlpha = math.max(0, 1 - (textProgress - self.textFadeIn - self.textDuration) / self.textFadeOut)
    end

    -- zone title with glow
    local fontSize = math.floor(42 * s)
    if not ZoneTransition.FONT_CACHE[fontSize] then
        ZoneTransition.FONT_CACHE[fontSize] = love.graphics.newFont("assets/roboto.ttf", fontSize)
        ZoneTransition.FONT_CACHE[fontSize]:setFilter('linear', 'linear')
    end
    local font = ZoneTransition.FONT_CACHE[fontSize]

    local subFontSize = math.floor(16 * s)
    if not ZoneTransition.SUB_FONT_CACHE[subFontSize] then
        ZoneTransition.SUB_FONT_CACHE[subFontSize] = love.graphics.newFont("assets/roboto.ttf", subFontSize)
        ZoneTransition.SUB_FONT_CACHE[subFontSize]:setFilter('linear', 'linear')
    end
    local subFont = ZoneTransition.SUB_FONT_CACHE[subFontSize]

    -- glow behind text
    love.graphics.setColor(r, g, b, textAlpha * 0.2)
    love.graphics.setFont(font)
    for dx = -2, 2 do
        for dy = -2, 2 do
            love.graphics.printf(self.zoneName, dx * s, h / 2 - 25 * s + dy * s, w, "center")
        end
    end

    -- main title
    love.graphics.setColor(1, 1, 1, textAlpha)
    love.graphics.printf(self.zoneName, 0, h / 2 - 25 * s, w, "center")

    -- decorative lines
    local lineW = 120 * s
    local lineY = h / 2 + 18 * s
    love.graphics.setColor(r * 0.5 + 0.5, g * 0.5 + 0.5, b * 0.5 + 0.5, textAlpha * 0.5)
    love.graphics.setLineWidth(1 * s)
    love.graphics.line(w / 2 - lineW, lineY, w / 2 - 10 * s, lineY)
    love.graphics.line(w / 2 + 10 * s, lineY, w / 2 + lineW, lineY)

    -- zone number subtitle
    love.graphics.setFont(subFont)
    love.graphics.setColor(r * 0.5 + 0.5, g * 0.5 + 0.5, b * 0.5 + 0.5, textAlpha * 0.7)
    love.graphics.printf(string.format("ZONE %d", self.zoneNum), 0, h / 2 + 25 * s, w, "center")
end

return ZoneTransition
