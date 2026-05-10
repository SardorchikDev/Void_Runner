ScreenEffects = class('ScreenEffects')

function ScreenEffects:initialize()
    self.shakeIntensity = 0
    self.shakeDuration = 0
    self.shakeTime = 0
    self.flashColor = nil
    self.flashDuration = 0
    self.flashTime = 0
end

function ScreenEffects:shake(intensity, duration)
    self.shakeIntensity = intensity
    self.shakeDuration = duration
    self.shakeTime = 0
end

function ScreenEffects:flash(r, g, b, a, duration)
    self.flashColor = {r = r, g = g, b = b, a = a or 1}
    self.flashDuration = duration
    self.flashTime = 0
end

function ScreenEffects:update(dt)
    if self.shakeTime < self.shakeDuration then
        self.shakeTime = self.shakeTime + dt
    end

    if self.flashTime < self.flashDuration then
        self.flashTime = self.flashTime + dt
    end
end

function ScreenEffects:apply()
    if self.shakeTime < self.shakeDuration then
        local progress = self.shakeTime / self.shakeDuration
        local intensity = self.shakeIntensity * (1 - progress)
        local dx = (math.random() - 0.5) * intensity
        local dy = (math.random() - 0.5) * intensity
        love.graphics.translate(dx, dy)
    end
end

function ScreenEffects:draw()
    if self.flashTime < self.flashDuration then
        local progress = self.flashTime / self.flashDuration
        local alpha = self.flashColor.a * (1 - progress)
        love.graphics.setColor(self.flashColor.r, self.flashColor.g, self.flashColor.b, alpha)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end

return ScreenEffects