-- NEW: Procedural audio manager for Void Runner, extending the game with synthesized engine, drone, and impact sounds.
AudioManager = class('AudioManager')

local function generateSineWave(freq, duration, sampleRate, amplitudeFunc)
    sampleRate = sampleRate or 44100
    local samples = math.floor(duration * sampleRate)
    local data = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local amp = amplitudeFunc and amplitudeFunc(t, duration) or 1.0
        data:setSample(i, math.sin(t * freq * math.pi * 2) * amp * 0.5)
    end
    return love.audio.newSource(data, 'static')
end

local function generateNoise(duration, sampleRate, amplitudeFunc)
    sampleRate = sampleRate or 44100
    local samples = math.floor(duration * sampleRate)
    local data = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local amp = amplitudeFunc and amplitudeFunc(t, duration) or 1.0
        data:setSample(i, (math.random() * 2 - 1) * amp * 0.5)
    end
    return love.audio.newSource(data, 'static')
end

local function generateDrone(sampleRate)
    sampleRate = sampleRate or 44100
    local duration = 8.0
    local samples = math.floor(duration * sampleRate)
    local data = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local lfo1 = math.sin(t * 0.1 * math.pi * 2) * 0.5 + 0.5
        local lfo2 = math.sin(t * 0.23 * math.pi * 2) * 0.5 + 0.5
        local lfo3 = math.sin(t * 0.17 * math.pi * 2) * 0.5 + 0.5
        local s1 = math.sin(t * 55 * math.pi * 2) * lfo1
        local s2 = math.sin(t * 82.5 * math.pi * 2) * lfo2 * 0.5
        local s3 = math.sin(t * 110 * math.pi * 2) * lfo3 * 0.3
        data:setSample(i, (s1 + s2 + s3) * 0.15)
    end
    local src = love.audio.newSource(data, 'static')
    src:setLooping(true)
    src:setVolume(0.25)
    return src
end

local function generateZoneSequence(sampleRate)
    sampleRate = sampleRate or 44100
    local duration = 0.75
    local samples = math.floor(duration * sampleRate)
    local data = love.sound.newSoundData(samples, sampleRate, 16, 1)
    local freqs = {330, 440, 660}
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local section = math.min(#freqs, math.floor(t / (duration / #freqs)) + 1)
        local localT = (t - (section - 1) * (duration / #freqs)) / (duration / #freqs)
        local env = math.sin(math.min(1, localT) * math.pi)
        local tone = math.sin(t * freqs[section] * math.pi * 2)
        data:setSample(i, tone * env * 0.35)
    end
    local src = love.audio.newSource(data, 'static')
    src:setVolume(0.18)
    return src
end

function AudioManager:initialize()
    self.engineHum = generateSineWave(60, 2.0, 44100, function(t, d)
        return 1.0
    end)
    self.engineHum:setLooping(true)
    self.engineHum:setVolume(0.08)

    self.thrustBurst = generateNoise(0.15, 44100, function(t, d)
        local env = math.max(0, 1 - t / d)
        return env * env
    end)
    self.thrustBurst:setVolume(0.25)

    self.shieldClang = generateSineWave(200, 0.4, 44100, function(t, d)
        return math.max(0, math.exp(-t * 8))
    end)
    self.shieldClang:setVolume(0.3)

    local explosionSamples = math.floor(0.8 * 44100)
    local explosionData = love.sound.newSoundData(explosionSamples, 44100, 16, 1)
    for i = 0, explosionSamples - 1 do
        local t = i / 44100
        local noise = (math.random() * 2 - 1)
        local rumble = math.sin(t * 40 * math.pi * 2) * math.max(0, math.exp(-t * 3))
        local env = math.max(0, math.exp(-t * 4))
        explosionData:setSample(i, (noise * 0.3 + rumble * 0.7) * env * 0.5)
    end
    self.explosionSound = love.audio.newSource(explosionData, 'static')
    self.explosionSound:setVolume(0.4)

    self.zoneTone = generateZoneSequence(44100)

    self.nearMissWhoosh = generateNoise(0.25, 44100, function(t, d)
        local freqSweep = 1 - (t / d)
        local env = math.sin(t / d * math.pi) * 0.8 + 0.2
        return env * freqSweep
    end)
    self.nearMissWhoosh:setVolume(0.15)

    self.drone = generateDrone(44100)
end

function AudioManager:playEngineHum()
    if self.engineHum and not self.engineHum:isPlaying() then
        self.engineHum:play()
    end
end

function AudioManager:stopEngineHum()
    if self.engineHum and self.engineHum:isPlaying() then
        self.engineHum:stop()
    end
end

function AudioManager:setEnginePitch(depth)
    if not self.engineHum then return end
    local pitch = 1.0 + depth * 0.0002
    pitch = math.min(pitch, 2.5)
    self.engineHum:setPitch(pitch)
end

function AudioManager:playThrust()
    if not self.thrustBurst then return end
    self.thrustBurst:stop()
    self.thrustBurst:play()
end

function AudioManager:playShield()
    if not self.shieldClang then return end
    self.shieldClang:stop()
    self.shieldClang:play()
end

function AudioManager:playExplosion()
    if not self.explosionSound then return end
    self.explosionSound:stop()
    self.explosionSound:play()
end

function AudioManager:playZoneTone()
    if not self.zoneTone then return end
    self.zoneTone:stop()
    self.zoneTone:play()
end

function AudioManager:playNearMiss()
    if not self.nearMissWhoosh then return end
    self.nearMissWhoosh:stop()
    self.nearMissWhoosh:play()
end

function AudioManager:playDrone()
    if self.drone and not self.drone:isPlaying() then
        self.drone:play()
    end
end

function AudioManager:stopDrone()
    if self.drone and self.drone:isPlaying() then
        self.drone:stop()
    end
end

function AudioManager:stopAll()
    self:stopEngineHum()
    self:stopDrone()
end

return AudioManager
