-- MODIFIED: Extends the original screen effect helper with hitstop, chromatic overlays, and slow motion.
ScreenEffects = class('ScreenEffects')

function ScreenEffects:initialize()
    self.shakeIntensity = 0
    self.shakeDuration = 0
    self.shakeTime = 0
    self.flashColor = nil
    self.flashDuration = 0
    self.flashTime = 0
    self.hitstopFrames = 0
    self.hitstopTotal = 0
    self.chromaticIntensity = 0
    self.chromaticDuration = 0
    self.chromaticTime = 0
    self.microJitterIntensity = 0
    self.slowMotionFactor = 1.0
    self.slowMotionDuration = 0
    self.slowMotionTime = 0
    self.blurIntensity = 0
    self.blurDuration = 0
    self.blurTime = 0
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

function ScreenEffects:hitstop(frames)
    self.hitstopFrames = frames
    self.hitstopTotal = frames
end

function ScreenEffects:isHitstop()
    return self.hitstopFrames > 0
end

function ScreenEffects:chromaticAberration(intensity, duration)
    self.chromaticIntensity = intensity
    self.chromaticDuration = duration
    self.chromaticTime = 0
end

function ScreenEffects:microJitter(intensity)
    self.microJitterIntensity = intensity
end

function ScreenEffects:slowMotion(factor, duration)
    self.slowMotionFactor = factor
    self.slowMotionDuration = duration
    self.slowMotionTime = 0
end

function ScreenEffects:blur(intensity, duration)
    self.blurIntensity = intensity
    self.blurDuration = duration
    self.blurTime = 0
end

function ScreenEffects:getTimeScale(dt)
    if self.hitstopFrames > 0 then
        return 0
    end
    if self.slowMotionTime < self.slowMotionDuration then
        local progress = self.slowMotionTime / self.slowMotionDuration
        local factor = lume.lerp(self.slowMotionFactor, 1.0, progress)
        return factor
    end
    return 1.0
end

function ScreenEffects:update(dt)
    if self.hitstopFrames > 0 then
        self.hitstopFrames = self.hitstopFrames - 1
    end

    if self.shakeTime < self.shakeDuration then
        self.shakeTime = self.shakeTime + dt
    end

    if self.flashTime < self.flashDuration then
        self.flashTime = self.flashTime + dt
    end

    if self.chromaticTime < self.chromaticDuration then
        self.chromaticTime = self.chromaticTime + dt
    end

    if self.slowMotionTime < self.slowMotionDuration then
        self.slowMotionTime = self.slowMotionTime + dt
    end

    if self.blurTime < self.blurDuration then
        self.blurTime = self.blurTime + dt
    end
end

function ScreenEffects:apply()
    local dx, dy = 0, 0

    if self.shakeTime < self.shakeDuration then
        local progress = self.shakeTime / self.shakeDuration
        local intensity = self.shakeIntensity * (1 - progress)
        dx = dx + (math.random() - 0.5) * intensity
        dy = dy + (math.random() - 0.5) * intensity
    end

    if self.microJitterIntensity > 0 then
        dx = dx + (math.random() - 0.5) * self.microJitterIntensity
        dy = dy + (math.random() - 0.5) * self.microJitterIntensity
    end

    if dx ~= 0 or dy ~= 0 then
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

    if self.chromaticTime < self.chromaticDuration then
        local progress = self.chromaticTime / self.chromaticDuration
        local intensity = self.chromaticIntensity * (1 - progress)

        love.graphics.setBlendMode('add')
        love.graphics.setColor(1, 0, 0, intensity * 0.15)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(0, 0, 1, intensity * 0.15)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setBlendMode('alpha')
    end

    if self.hitstopFrames > 0 then
        love.graphics.setColor(1, 1, 1, 0.08)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    if self.blurTime < self.blurDuration then
        local progress = self.blurTime / self.blurDuration
        local intensity = self.blurIntensity * (1 - progress)
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        love.graphics.setBlendMode('add')
        for i = 1, 16 do
            local angle = (i / 16) * math.pi * 2
            local dist = intensity * 6
            local dx = math.cos(angle) * dist
            local dy = math.sin(angle) * dist
            love.graphics.setColor(1, 1, 1, intensity * 0.012)
            love.graphics.rectangle('fill', dx, dy, w, h)
        end
        love.graphics.setBlendMode('alpha')
    end
end

return ScreenEffects
