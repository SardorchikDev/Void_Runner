-- NEW: Center-screen zone title flash and temporary color-grade overlay.
ZoneTransition = class('ZoneTransition', Entity)
ZoneTransition.static.FONT_CACHE = {}

function ZoneTransition:initialize(zoneName, zoneColor)
    Entity.initialize(self, 'transition', 1, vector(0, 0))
    self.zoneName = zoneName or "UNKNOWN"
    self.targetColor = zoneColor or {r = 0, g = 0, b = 0}
    self.life = 2.5
    self.maxLife = self.life
    self.textAlpha = 0
    self.textFadeIn = 0.4
    self.textFadeOut = 0.4
    self.textDuration = 1.5
end

function ZoneTransition:update(dt)
    Entity.update(self, dt)
    self.life = self.life - dt
    if self.life <= 0 then
        self:destroy()
    end
end

function ZoneTransition:draw()
end

function ZoneTransition:drawOverlay(scale)
    local progress = 1 - (self.life / self.maxLife)
    local alpha = math.sin(progress * math.pi) * 0.15

    love.graphics.setColor(self.targetColor.r, self.targetColor.g, self.targetColor.b, alpha)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    local textProgress = (self.maxLife - self.life)
    local textAlpha = 0
    if textProgress < self.textFadeIn then
        textAlpha = textProgress / self.textFadeIn
    elseif textProgress < self.textFadeIn + self.textDuration then
        textAlpha = 1
    else
        textAlpha = math.max(0, 1 - (textProgress - self.textFadeIn - self.textDuration) / self.textFadeOut)
    end

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local s = scale or 1

    love.graphics.setColor(1, 1, 1, textAlpha)
    local fontSize = math.floor(42 * s)
    if not ZoneTransition.FONT_CACHE[fontSize] then
        ZoneTransition.FONT_CACHE[fontSize] = love.graphics.newFont("assets/roboto.ttf", fontSize)
        ZoneTransition.FONT_CACHE[fontSize]:setFilter('linear', 'linear')
    end
    local font = ZoneTransition.FONT_CACHE[fontSize]
    love.graphics.setFont(font)
    love.graphics.printf(self.zoneName, 0, h / 2 - 25 * s, w, "center")
end

return ZoneTransition
