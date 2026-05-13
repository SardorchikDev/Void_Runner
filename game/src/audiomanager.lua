-- Procedural audio manager with volume control, background music, and comprehensive SFX.
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

local function generatePickupSound(sampleRate)
    sampleRate = sampleRate or 44100
    local duration = 0.35
    local samples = math.floor(duration * sampleRate)
    local data = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local freq = 600 + (t / duration) * 800
        local env = math.max(0, 1 - (t / duration)) * math.sin(math.min(1, t / 0.02) * math.pi * 0.5)
        local tone = math.sin(t * freq * math.pi * 2)
        local harmonic = math.sin(t * freq * 1.5 * math.pi * 2) * 0.3
        data:setSample(i, (tone + harmonic) * env * 0.4)
    end
    local src = love.audio.newSource(data, 'static')
    src:setVolume(0.3)
    return src
end

local function generateDashSound(sampleRate)
    sampleRate = sampleRate or 44100
    local duration = 0.2
    local samples = math.floor(duration * sampleRate)
    local data = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local env = math.max(0, 1 - t / duration) * math.max(0, 1 - t / duration)
        local sweep = 200 + (1 - t / duration) * 400
        local noise = (math.random() * 2 - 1) * 0.4
        local tone = math.sin(t * sweep * math.pi * 2) * 0.6
        data:setSample(i, (noise + tone) * env * 0.45)
    end
    local src = love.audio.newSource(data, 'static')
    src:setVolume(0.25)
    return src
end

local function generateLaserSound(sampleRate)
    sampleRate = sampleRate or 44100
    local duration = 0.18
    local samples = math.floor(duration * sampleRate)
    local data = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local freq = 1200 - (t / duration) * 800
        local env = math.max(0, 1 - t / duration)
        local tone = math.sin(t * freq * math.pi * 2) * 0.5
        local buzz = math.sin(t * freq * 2 * math.pi * 2) * 0.25
        data:setSample(i, (tone + buzz) * env * 0.35)
    end
    local src = love.audio.newSource(data, 'static')
    src:setVolume(0.2)
    return src
end

local function generateMenuSelect(sampleRate)
    sampleRate = sampleRate or 44100
    local duration = 0.12
    local samples = math.floor(duration * sampleRate)
    local data = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local env = math.max(0, 1 - t / duration)
        data:setSample(i, math.sin(t * 800 * math.pi * 2) * env * 0.3)
    end
    local src = love.audio.newSource(data, 'static')
    src:setVolume(0.15)
    return src
end

local function generateZoneSwell(sampleRate)
    sampleRate = sampleRate or 44100
    local duration = 3.0
    local samples = math.floor(duration * sampleRate)
    local data = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local amp
        if t < 1.0 then
            amp = (t / 1.0) * 0.4
        elseif t < 2.0 then
            amp = 0.4
        else
            amp = 0.4 * math.max(0, 1 - (t - 2.0) / 1.0)
        end
        local s1 = math.sin(t * 55 * math.pi * 2)
        local s2 = math.sin(t * 110 * math.pi * 2) * 0.7
        local s3 = math.sin(t * 220 * math.pi * 2) * 0.4
        data:setSample(i, (s1 + s2 + s3) * amp * 0.2)
    end
    local src = love.audio.newSource(data, 'static')
    src:setVolume(0.2)
    return src
end

local function generateComboAchieved(sampleRate)
    sampleRate = sampleRate or 44100
    local duration = 0.25
    local samples = math.floor(duration * sampleRate)
    local data = love.sound.newSoundData(samples, sampleRate, 16, 1)
    local notes = {440, 554, 659, 880}
    local noteLen = 0.06
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local noteIndex = math.min(#notes, math.floor(t / noteLen) + 1)
        local localT = t - (noteIndex - 1) * noteLen
        local env = math.max(0, 1 - localT / noteLen)
        local tone = math.sin(t * notes[noteIndex] * math.pi * 2)
        data:setSample(i, tone * env * 0.35)
    end
    local src = love.audio.newSource(data, 'static')
    src:setVolume(0.2)
    return src
end

local function generateBossPhaseShift(sampleRate)
    sampleRate = sampleRate or 44100
    local duration = 1.2
    local samples = math.floor(duration * sampleRate)
    local data = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local env
        if t < 0.05 then
            env = t / 0.05
        else
            env = math.max(0, 1 - (t - 0.05) / (duration - 0.05))
        end
        local noise = (math.random() * 2 - 1) * 0.3
        local rumble = math.sin(t * 40 * math.pi * 2) * 0.5
        local sweepFreq = 200 + (t / duration) * 600
        local sawPhase = (t * sweepFreq) % 1.0
        local saw = (sawPhase * 2 - 1) * 0.4
        data:setSample(i, (noise + rumble + saw) * env * 0.3)
    end
    local src = love.audio.newSource(data, 'static')
    src:setVolume(0.25)
    return src
end

function AudioManager:initialize()
    -- Volume settings (0.0 to 1.0)
    self.masterVolume = 1.0
    self.musicVolume = 0.5
    self.sfxVolume = 0.8

    -- Load settings from file
    self:loadSettings()

    -- Background music
    local musicInfo = love.filesystem.getInfo("assets/sound/music.mp3")
    if musicInfo then
        self.music = love.audio.newSource('assets/sound/music.mp3', 'stream')
        self.music:setLooping(true)
        self.music:setVolume(self.musicVolume * self.masterVolume * 0.3)
    end

    -- Engine sounds
    self.engineHum = generateSineWave(60, 2.0, 44100, function(t, d) return 1.0 end)
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

    -- New sounds
    self.pickupSound = generatePickupSound(44100)
    self.dashSound = generateDashSound(44100)
    self.laserSound = generateLaserSound(44100)
    self.menuSelect = generateMenuSelect(44100)

    -- New upgrade 15 sounds
    self.zoneSwell = generateZoneSwell(44100)
    self.comboAchieved = generateComboAchieved(44100)
    self.bossPhaseShift = generateBossPhaseShift(44100)

    -- Track all sources for volume updates
    self.allSfx = {
        self.engineHum, self.thrustBurst, self.shieldClang,
        self.explosionSound, self.zoneTone, self.nearMissWhoosh,
        self.drone, self.pickupSound, self.dashSound,
        self.laserSound, self.menuSelect,
        self.zoneSwell, self.comboAchieved, self.bossPhaseShift
    }
    self.baseVolumes = {}
    for _, src in ipairs(self.allSfx) do
        self.baseVolumes[src] = src:getVolume()
    end

    self:applyVolumes()
end

function AudioManager:loadSettings()
    local info = love.filesystem.getInfo("settings")
    if info and info.type == "file" then
        local contents = love.filesystem.read("settings")
        if contents then
            for line in contents:gmatch("[^\n]+") do
                local key, val = line:match("^(%w+)=(.+)$")
                if key and val then
                    val = tonumber(val)
                    if val then
                        if key == "masterVolume" then self.masterVolume = val
                        elseif key == "musicVolume" then self.musicVolume = val
                        elseif key == "sfxVolume" then self.sfxVolume = val
                        end
                    end
                end
            end
        end
    end
end

function AudioManager:saveSettings()
    local data = string.format("masterVolume=%.2f\nmusicVolume=%.2f\nsfxVolume=%.2f\n",
        self.masterVolume, self.musicVolume, self.sfxVolume)
    love.filesystem.write("settings", data)
end

function AudioManager:applyVolumes()
    local master = self.masterVolume
    if self.music then
        self.music:setVolume(self.musicVolume * master * 0.3)
    end
    for _, src in ipairs(self.allSfx) do
        local base = self.baseVolumes[src] or 0.2
        src:setVolume(base * self.sfxVolume * master)
    end
end

function AudioManager:setMasterVolume(v)
    self.masterVolume = math.max(0, math.min(1, v))
    self:applyVolumes()
    self:saveSettings()
end

function AudioManager:setMusicVolume(v)
    self.musicVolume = math.max(0, math.min(1, v))
    self:applyVolumes()
    self:saveSettings()
end

function AudioManager:setSfxVolume(v)
    self.sfxVolume = math.max(0, math.min(1, v))
    self:applyVolumes()
    self:saveSettings()
end

function AudioManager:playMusic()
    if self.music and not self.music:isPlaying() then
        self.music:play()
    end
end

function AudioManager:stopMusic()
    if self.music and self.music:isPlaying() then
        self.music:stop()
    end
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

function AudioManager:playPickup()
    if not self.pickupSound then return end
    self.pickupSound:stop()
    self.pickupSound:play()
end

function AudioManager:playDash()
    if not self.dashSound then return end
    self.dashSound:stop()
    self.dashSound:play()
end

function AudioManager:playLaser()
    if not self.laserSound then return end
    self.laserSound:stop()
    self.laserSound:play()
end

function AudioManager:playMenuSelect()
    if not self.menuSelect then return end
    self.menuSelect:stop()
    self.menuSelect:play()
end

function AudioManager:playZoneSwell()
    if not self.zoneSwell then return end
    self.zoneSwell:stop()
    self.zoneSwell:play()
end

function AudioManager:playComboAchieved()
    if not self.comboAchieved then return end
    self.comboAchieved:stop()
    self.comboAchieved:play()
end

function AudioManager:playBossPhaseShift()
    if not self.bossPhaseShift then return end
    self.bossPhaseShift:stop()
    self.bossPhaseShift:play()
end

function AudioManager:stopAll()
    self:stopEngineHum()
    self:stopDrone()
    self:stopMusic()
    if self.explosionSound then self.explosionSound:stop() end
    if self.zoneTone then self.zoneTone:stop() end
    if self.nearMissWhoosh then self.nearMissWhoosh:stop() end
end

return AudioManager
