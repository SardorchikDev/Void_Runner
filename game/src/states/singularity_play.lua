SingularityPlay = class('SingularityPlay', GameState)

-- ─── CONSTANTS ──────────────────────────────────────────
local PLAYER_FOLLOW_SPEED  = 8
local PLAYER_RADIUS        = 6
local PULL_RADIUS          = 380
local PULL_FORCE           = 320
local ENERGY_MAX           = 100
local ENERGY_DRAIN         = 20
local ENERGY_REGEN         = 14
local ABSORB_RADIUS        = 22
local DAMAGE_RADIUS        = 16
local HIT_INVULN           = 1.8
local MAX_HEALTH           = 5
local CHAIN_RADIUS         = 100
local CHAIN_MULT_BONUS     = 0.5
local MULT_DECAY_RATE      = 0.12
local ENEMY_COLLISION_DIST = 14
local WAVE_PAUSE           = 3.0

local HIGH_SCORE_FILE      = "singularity_highscore"

local ENEMY_TYPES = {
    drifter  = {radius = 7,  speed = {35, 55},   pullResist = 1.0, points = 10,  hp = 1, color = {0.3, 0.85, 1.0},   shape = 'circle'},
    chaser   = {radius = 9,  speed = {55, 80},   pullResist = 1.4, points = 25,  hp = 1, color = {1.0, 0.25, 0.3},   shape = 'triangle'},
    orbiter  = {radius = 8,  speed = {40, 60},   pullResist = 1.1, points = 30,  hp = 1, color = {1.0, 0.85, 0.15},  shape = 'ring'},
    tank     = {radius = 14, speed = {18, 28},   pullResist = 3.0, points = 50,  hp = 3, color = {1.0, 0.5, 0.1},    shape = 'hexagon'},
    splitter = {radius = 10, speed = {35, 50},   pullResist = 1.5, points = 35,  hp = 1, color = {0.2, 1.0, 0.4},    shape = 'square'},
}

-- ─── WAVE DEFINITIONS ───────────────────────────────────
local function getWaveEnemies(wave)
    if wave == 1 then return {drifter = 5}
    elseif wave == 2 then return {drifter = 8}
    elseif wave == 3 then return {drifter = 6, chaser = 2}
    elseif wave == 4 then return {drifter = 5, chaser = 4}
    elseif wave == 5 then return {drifter = 4, chaser = 3, orbiter = 2}
    elseif wave == 6 then return {drifter = 6, chaser = 5, orbiter = 3}
    elseif wave == 7 then return {drifter = 4, chaser = 4, orbiter = 3, tank = 1}
    elseif wave == 8 then return {drifter = 5, chaser = 5, orbiter = 3, tank = 2}
    elseif wave == 9 then return {drifter = 3, chaser = 5, orbiter = 4, tank = 2, splitter = 2}
    else
        local base = 4 + wave
        return {
            drifter  = math.floor(base * 0.3),
            chaser   = math.floor(base * 0.25),
            orbiter  = math.floor(base * 0.2),
            tank     = math.floor(base * 0.1) + 1,
            splitter = math.floor(base * 0.15)
        }
    end
end

-- ─── INITIALIZATION ─────────────────────────────────────
function SingularityPlay:initialize()
    GameState.initialize(self)
    self.screenEffects = ScreenEffects()

    self.w = love.graphics.getWidth()
    self.h = love.graphics.getHeight()
    self.scale = math.min(self.w / 1280, self.h / 720)

    self.hud_font = love.graphics.newFont("assets/roboto.ttf", math.floor(24 * self.scale))
    self.big_font = love.graphics.newFont("assets/roboto.ttf", math.floor(56 * self.scale))
    self.med_font = love.graphics.newFont("assets/roboto.ttf", math.floor(32 * self.scale))
    self.small_font = love.graphics.newFont("assets/roboto.ttf", math.floor(16 * self.scale))
    self.score_font = love.graphics.newFont("assets/roboto.ttf", math.floor(36 * self.scale))
    self.huge_font = love.graphics.newFont("assets/roboto.ttf", math.floor(72 * self.scale))

    self.audioManager = AudioManager()
    self:initAudio()
    self:startGame()
end

function SingularityPlay:initAudio()
    local sr = 44100

    -- pull drone
    local dur = 4.0
    local samples = math.floor(dur * sr)
    local data = love.sound.newSoundData(samples, sr, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sr
        local lfo = math.sin(t * 0.3 * math.pi * 2) * 0.5 + 0.5
        local s1 = math.sin(t * 65 * math.pi * 2) * lfo
        local s2 = math.sin(t * 97.5 * math.pi * 2) * (1 - lfo) * 0.5
        local s3 = math.sin(t * 130 * math.pi * 2) * 0.2
        data:setSample(i, (s1 + s2 + s3) * 0.12)
    end
    self.pullDrone = love.audio.newSource(data, 'static')
    self.pullDrone:setLooping(true)
    self.pullDrone:setVolume(0)

    -- absorb sound
    dur = 0.25
    samples = math.floor(dur * sr)
    data = love.sound.newSoundData(samples, sr, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sr
        local freq = 500 + (t / dur) * 1200
        local env = math.max(0, 1 - t / dur)
        data:setSample(i, math.sin(t * freq * math.pi * 2) * env * 0.3)
    end
    self.absorbSound = love.audio.newSource(data, 'static')
    self.absorbSound:setVolume(0.25)

    -- explosion sound
    dur = 0.4
    samples = math.floor(dur * sr)
    data = love.sound.newSoundData(samples, sr, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sr
        local env = math.max(0, 1 - t / dur) * math.max(0, 1 - t / dur)
        local noise = (math.random() * 2 - 1)
        local bass = math.sin(t * 80 * math.pi * 2) * 0.6
        data:setSample(i, (noise * 0.4 + bass) * env * 0.35)
    end
    self.explosionSound = love.audio.newSource(data, 'static')
    self.explosionSound:setVolume(0.3)

    -- damage sound
    dur = 0.3
    samples = math.floor(dur * sr)
    data = love.sound.newSoundData(samples, sr, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sr
        local env = math.max(0, 1 - t / dur)
        local buzz = math.sin(t * 150 * math.pi * 2) * math.sin(t * 30 * math.pi * 2)
        data:setSample(i, buzz * env * 0.4)
    end
    self.damageSound = love.audio.newSource(data, 'static')
    self.damageSound:setVolume(0.3)

    -- wave sound
    dur = 0.6
    samples = math.floor(dur * sr)
    data = love.sound.newSoundData(samples, sr, 16, 1)
    local freqs = {220, 330, 440}
    for i = 0, samples - 1 do
        local t = i / sr
        local section = math.min(#freqs, math.floor(t / (dur / #freqs)) + 1)
        local localT = (t - (section - 1) * (dur / #freqs)) / (dur / #freqs)
        local env = math.sin(math.min(1, localT) * math.pi)
        local tone = math.sin(t * freqs[section] * math.pi * 2)
        data:setSample(i, tone * env * 0.3)
    end
    self.waveSound = love.audio.newSource(data, 'static')
    self.waveSound:setVolume(0.2)

    -- background music drone
    dur = 12.0
    samples = math.floor(dur * sr)
    data = love.sound.newSoundData(samples, sr, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sr
        local lfo1 = math.sin(t * 0.07 * math.pi * 2) * 0.5 + 0.5
        local lfo2 = math.sin(t * 0.13 * math.pi * 2) * 0.5 + 0.5
        local s1 = math.sin(t * 40 * math.pi * 2) * lfo1 * 0.3
        local s2 = math.sin(t * 60 * math.pi * 2) * lfo2 * 0.2
        local s3 = math.sin(t * 80 * math.pi * 2) * (1 - lfo1) * 0.15
        local pad = math.sin(t * 120 * math.pi * 2) * math.sin(t * 0.5 * math.pi * 2) * 0.08
        data:setSample(i, (s1 + s2 + s3 + pad) * 0.5)
    end
    self.bgMusic = love.audio.newSource(data, 'static')
    self.bgMusic:setLooping(true)
    self.bgMusic:setVolume(0.15)
    self.bgMusic:play()
end

function SingularityPlay:startGame()
    self.time = 0

    -- player state
    self.px = self.w / 2
    self.py = self.h / 2
    self.ptx = self.px
    self.pty = self.py
    self.energy = ENERGY_MAX
    self.health = MAX_HEALTH
    self.pullActive = false
    self.invulnTimer = 0
    self.playerAlive = true

    -- game state
    self.score = 0
    self.multiplier = 1.0
    self.multTimer = 0
    self.currentChain = 0
    self.bestChain = 0
    self.wave = 0
    self.waveTimer = 0
    self.waveAnnounceTimer = 0
    self.waveAnnounceText = ""
    self.wavePaused = true
    self.waveSpawnQueue = {}
    self.spawnTimer = 0
    self.gameOver = false
    self.gameOverTimer = 0
    self.paused = false
    self.pauseSelected = 1

    -- entities
    self.enemies = {}
    self.particles = {}
    self.popups = {}
    self.pullLines = {}
    self.shockwaves = {}

    -- background
    self.bgStars = {}
    for i = 1, 150 do
        table.insert(self.bgStars, {
            x = math.random() * self.w,
            y = math.random() * self.h,
            size = 0.5 + math.random() * 1.5,
            baseAlpha = 0.1 + math.random() * 0.4,
            blink = math.random() * math.pi * 2
        })
    end

    self.bgNebulae = {}
    for i = 1, 6 do
        table.insert(self.bgNebulae, {
            x = math.random() * self.w,
            y = math.random() * self.h,
            radius = 80 + math.random() * 200,
            r = math.random() * 0.15,
            g = math.random() * 0.05,
            b = 0.1 + math.random() * 0.15,
            alpha = 0.03 + math.random() * 0.04
        })
    end

    -- high score
    self.highScore = self:loadHighScore()

    -- pull radius visual state
    self.pullRadiusAlpha = 0

    -- start first wave
    self.wavePaused = true
    self.waveTimer = 1.5

    self.pullDrone:stop()

    love.mouse.setVisible(false)
    love.mouse.setGrabbed(true)
end

function SingularityPlay:loadHighScore()
    local ok, data = pcall(love.filesystem.read, HIGH_SCORE_FILE)
    if ok and data then
        return tonumber(data) or 0
    end
    return 0
end

function SingularityPlay:saveHighScore()
    if self.score > self.highScore then
        self.highScore = self.score
        pcall(love.filesystem.write, HIGH_SCORE_FILE, tostring(math.floor(self.score)))
    end
end

function SingularityPlay:enter()
    love.mouse.setVisible(false)
    love.mouse.setGrabbed(true)
end

function SingularityPlay:resize(w, h)
    self.w = w
    self.h = h
    self.scale = math.min(w / 1280, h / 720)
end

-- ─── UPDATE ─────────────────────────────────────────────
function SingularityPlay:update(dt)
    if dt > 1/30 then dt = 1/30 end
    self.time = self.time + dt

    self.screenEffects:update(dt)
    local timeScale = self.screenEffects:getTimeScale(dt)
    if timeScale == 0 then return end
    dt = dt * timeScale

    if self.gameOver then
        self.gameOverTimer = self.gameOverTimer + dt
        return
    end

    if self.paused then return end

    self:updatePlayer(dt)
    self:updateEnemies(dt)
    self:updateWaves(dt)
    self:updateCollisions(dt)
    self:updateParticles(dt)
    self:updatePopups(dt)
    self:updateShockwaves(dt)
    self:updatePullLines(dt)
    self:updateBackground(dt)
    self:updateMultiplier(dt)
    self:updateAudio(dt)

    -- pull radius visual fade
    if self.pullActive and self.energy > 0 then
        self.pullRadiusAlpha = math.min(0.15, self.pullRadiusAlpha + dt * 0.8)
    else
        self.pullRadiusAlpha = math.max(0, self.pullRadiusAlpha - dt * 1.2)
    end
end

function SingularityPlay:updatePlayer(dt)
    if not self.playerAlive then return end

    -- smooth follow mouse
    local mx, my = love.mouse.getPosition()
    self.ptx = mx
    self.pty = my
    self.px = self.px + (self.ptx - self.px) * PLAYER_FOLLOW_SPEED * dt
    self.py = self.py + (self.pty - self.py) * PLAYER_FOLLOW_SPEED * dt

    -- clamp to screen
    self.px = math.max(20, math.min(self.w - 20, self.px))
    self.py = math.max(20, math.min(self.h - 20, self.py))

    -- pull state
    self.pullActive = love.keyboard.isDown('space') or love.mouse.isDown(1)

    -- energy management
    if self.pullActive and self.energy > 0 then
        self.energy = math.max(0, self.energy - ENERGY_DRAIN * dt)
        if self.energy <= 0 then
            self.pullActive = false
        end
    else
        self.pullActive = false
        self.energy = math.min(ENERGY_MAX, self.energy + ENERGY_REGEN * dt)
    end

    -- invulnerability
    if self.invulnTimer > 0 then
        self.invulnTimer = self.invulnTimer - dt
    end
end

function SingularityPlay:updateEnemies(dt)
    local toRemove = {}
    for i, e in ipairs(self.enemies) do
        e.time = e.time + dt

        -- base movement
        local etype = ENEMY_TYPES[e.type]

        if e.type == 'chaser' then
            -- chase player
            local dx = self.px - e.x
            local dy = self.py - e.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 1 then
                e.vx = (dx / dist) * e.speed
                e.vy = (dy / dist) * e.speed
            end
        elseif e.type == 'orbiter' then
            -- orbit player
            local dx = self.px - e.x
            local dy = self.py - e.y
            local dist = math.sqrt(dx * dx + dy * dy)
            local targetDist = 200 * self.scale
            if dist > 1 then
                local nx, ny = dx / dist, dy / dist
                -- tangential + radial
                local tangX, tangY = -ny, nx
                local radial = (dist - targetDist) * 0.5
                e.vx = tangX * e.speed + nx * radial
                e.vy = tangY * e.speed + ny * radial
            end
        end

        -- gravitational pull effect
        if self.pullActive and self.energy > 0 then
            local dx = self.px - e.x
            local dy = self.py - e.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < PULL_RADIUS * self.scale and dist > 1 then
                local force = PULL_FORCE / (dist * etype.pullResist) * self.scale
                e.vx = e.vx + (dx / dist) * force * dt
                e.vy = e.vy + (dy / dist) * force * dt
            end
        end

        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt

        -- check absorption or damage
        local dx = self.px - e.x
        local dy = self.py - e.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < ABSORB_RADIUS * self.scale and self.pullActive then
            -- absorbed!
            local points = math.floor(etype.points * self.multiplier)
            self.score = self.score + points
            self:spawnAbsorbParticles(e.x, e.y, etype.color)
            self:addPopup(e.x, e.y - 20, "+" .. points, etype.color)
            self.absorbSound:stop()
            self.absorbSound:play()
            self.energy = math.min(ENERGY_MAX, self.energy + 3)
            table.insert(toRemove, i)
        elseif dist < DAMAGE_RADIUS * self.scale and not self.pullActive and self.invulnTimer <= 0 then
            -- damage!
            self:takeDamage()
            table.insert(toRemove, i)
        end

        -- off-screen removal (with generous margin for orbiters)
        local margin = 200
        if e.x < -margin or e.x > self.w + margin or e.y < -margin or e.y > self.h + margin then
            if e.type ~= 'orbiter' then
                table.insert(toRemove, i)
            end
        end
    end

    -- remove in reverse order
    table.sort(toRemove, function(a, b) return a > b end)
    for _, i in ipairs(toRemove) do
        table.remove(self.enemies, i)
    end
end

function SingularityPlay:updateCollisions(dt)
    if not self.pullActive then return end

    local toExplode = {}
    for i = 1, #self.enemies do
        for j = i + 1, #self.enemies do
            local a = self.enemies[i]
            local b = self.enemies[j]
            if a and b and not a.exploding and not b.exploding then
                local dx = a.x - b.x
                local dy = a.y - b.y
                local dist = math.sqrt(dx * dx + dy * dy)
                local ra = ENEMY_TYPES[a.type].radius * self.scale
                local rb = ENEMY_TYPES[b.type].radius * self.scale
                if dist < (ra + rb) then
                    a.exploding = true
                    b.exploding = true
                    table.insert(toExplode, {a, b})
                end
            end
        end
    end

    for _, pair in ipairs(toExplode) do
        self:chainExplosion(pair[1])
        self:chainExplosion(pair[2])
    end
end

function SingularityPlay:chainExplosion(enemy)
    local etype = ENEMY_TYPES[enemy.type]
    self.currentChain = self.currentChain + 1
    self.bestChain = math.max(self.bestChain, self.currentChain)
    self.multiplier = self.multiplier + CHAIN_MULT_BONUS
    self.multTimer = 0

    local points = math.floor(etype.points * self.multiplier)
    self.score = self.score + points
    self:addPopup(enemy.x, enemy.y - 20, "+" .. points, {1, 0.8, 0.2})

    -- spawn chain explosion particles
    self:spawnExplosion(enemy.x, enemy.y, etype.color)

    -- shockwave
    table.insert(self.shockwaves, {
        x = enemy.x, y = enemy.y,
        radius = 0, maxRadius = CHAIN_RADIUS * self.scale,
        life = 0, maxLife = 0.4,
        color = etype.color
    })

    -- screen effects scale with chain
    local shakeAmount = math.min(12, 3 + self.currentChain * 1.5) * self.scale
    self.screenEffects:shake(shakeAmount, 0.2)
    if self.currentChain >= 3 then
        self.screenEffects:chromaticAberration(0.3 + self.currentChain * 0.1, 0.3)
    end
    if self.currentChain >= 2 then
        self:addPopup(enemy.x, enemy.y - 45, "x" .. string.format("%.1f", self.multiplier) .. " CHAIN!", {1, 0.6, 0.1})
    end

    self.explosionSound:stop()
    self.explosionSound:play()

    -- mark for removal
    enemy.dead = true

    -- check for chain propagation
    for _, other in ipairs(self.enemies) do
        if not other.dead and not other.exploding then
            local dx = enemy.x - other.x
            local dy = enemy.y - other.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < CHAIN_RADIUS * self.scale then
                other.exploding = true
                -- defer to avoid modifying list during iteration
                Timer.after(0.05 + math.random() * 0.1, function()
                    if not other.dead then
                        self:chainExplosion(other)
                    end
                end)
            end
        end
    end

    -- splitter: spawn mini enemies
    if enemy.type == 'splitter' and not enemy.isMini then
        for k = 1, 2 do
            local angle = math.random() * math.pi * 2
            local mini = self:createEnemy('drifter', enemy.x + math.cos(angle) * 20, enemy.y + math.sin(angle) * 20)
            mini.isMini = true
            table.insert(self.enemies, mini)
        end
    end

    -- remove dead enemies
    self.enemies = lume.reject(self.enemies, function(e) return e.dead end)
end

function SingularityPlay:updateShockwaves(dt)
    for i = #self.shockwaves, 1, -1 do
        local sw = self.shockwaves[i]
        sw.life = sw.life + dt
        sw.radius = (sw.life / sw.maxLife) * sw.maxRadius
        if sw.life >= sw.maxLife then
            table.remove(self.shockwaves, i)
        end
    end
end

function SingularityPlay:updateWaves(dt)
    -- check if current wave is cleared
    if not self.wavePaused and #self.enemies == 0 and #self.waveSpawnQueue == 0 then
        self.wavePaused = true
        self.waveTimer = WAVE_PAUSE
        self.currentChain = 0
    end

    if self.wavePaused then
        self.waveTimer = self.waveTimer - dt
        if self.waveTimer <= 0 then
            self.wavePaused = false
            self.wave = self.wave + 1
            self.waveAnnounceText = "WAVE " .. self.wave
            self.waveAnnounceTimer = 2.5
            self.waveSound:stop()
            self.waveSound:play()
            self:populateWave()
        end
    else
        -- spawn from queue
        if #self.waveSpawnQueue > 0 then
            self.spawnTimer = self.spawnTimer + dt
            local interval = math.max(0.3, 1.0 - self.wave * 0.05)
            if self.spawnTimer >= interval then
                self.spawnTimer = 0
                local enemyType = table.remove(self.waveSpawnQueue, 1)
                local e = self:spawnEnemyFromEdge(enemyType)
                table.insert(self.enemies, e)
            end
        end
    end

    if self.waveAnnounceTimer > 0 then
        self.waveAnnounceTimer = self.waveAnnounceTimer - dt
    end
end

function SingularityPlay:populateWave()
    local enemies = getWaveEnemies(self.wave)
    self.waveSpawnQueue = {}
    for etype, count in pairs(enemies) do
        for i = 1, count do
            table.insert(self.waveSpawnQueue, etype)
        end
    end
    -- shuffle
    for i = #self.waveSpawnQueue, 2, -1 do
        local j = math.random(i)
        self.waveSpawnQueue[i], self.waveSpawnQueue[j] = self.waveSpawnQueue[j], self.waveSpawnQueue[i]
    end
end

function SingularityPlay:createEnemy(etype, x, y)
    local def = ENEMY_TYPES[etype]
    local speed = def.speed[1] + math.random() * (def.speed[2] - def.speed[1])
    speed = speed * self.scale

    local vx, vy = 0, 0
    if etype == 'drifter' or etype == 'tank' or etype == 'splitter' then
        -- move toward center area
        local angle = math.atan2(self.h / 2 - y, self.w / 2 - x) + (math.random() - 0.5) * 1.0
        vx = math.cos(angle) * speed
        vy = math.sin(angle) * speed
    elseif etype == 'chaser' then
        local angle = math.atan2(self.py - y, self.px - x)
        vx = math.cos(angle) * speed
        vy = math.sin(angle) * speed
    elseif etype == 'orbiter' then
        vx = 0
        vy = 0
    end

    return {
        x = x, y = y, vx = vx, vy = vy,
        type = etype, speed = speed,
        hp = def.hp, time = 0,
        exploding = false, dead = false, isMini = false
    }
end

function SingularityPlay:spawnEnemyFromEdge(etype)
    local side = math.random(4)
    local x, y
    local margin = 40
    if side == 1 then     x = -margin;              y = math.random() * self.h
    elseif side == 2 then x = self.w + margin;       y = math.random() * self.h
    elseif side == 3 then x = math.random() * self.w; y = -margin
    else                  x = math.random() * self.w; y = self.h + margin
    end
    return self:createEnemy(etype, x, y)
end

function SingularityPlay:takeDamage()
    if self.invulnTimer > 0 then return end
    self.health = self.health - 1
    self.invulnTimer = HIT_INVULN
    self.screenEffects:shake(15 * self.scale, 0.4)
    self.screenEffects:flash(1, 0.2, 0.2, 0.4, 0.3)
    self.screenEffects:chromaticAberration(0.6, 0.5)
    self.damageSound:stop()
    self.damageSound:play()

    if self.health <= 0 then
        self.playerAlive = false
        self.gameOver = true
        self.gameOverTimer = 0
        self:saveHighScore()
        self.pullDrone:stop()
        self:spawnExplosion(self.px, self.py, {0.6, 0.4, 1.0})
        self:spawnExplosion(self.px, self.py, {1.0, 1.0, 1.0})
        self.screenEffects:shake(25 * self.scale, 0.8)
        self.screenEffects:flash(1, 1, 1, 0.6, 0.5)
        self.screenEffects:slowMotion(0.2, 1.5)
        love.mouse.setVisible(true)
        love.mouse.setGrabbed(false)
    end
end

-- ─── PARTICLES ──────────────────────────────────────────
function SingularityPlay:spawnAbsorbParticles(x, y, color)
    for i = 1, 12 do
        local angle = math.random() * math.pi * 2
        local speed = (40 + math.random() * 80) * self.scale
        table.insert(self.particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.3 + math.random() * 0.3,
            maxLife = 0.3 + math.random() * 0.3,
            size = (2 + math.random() * 3) * self.scale,
            r = color[1], g = color[2], b = color[3]
        })
    end
end

function SingularityPlay:spawnExplosion(x, y, color)
    for i = 1, 24 do
        local angle = math.random() * math.pi * 2
        local speed = (60 + math.random() * 150) * self.scale
        table.insert(self.particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.4 + math.random() * 0.5,
            maxLife = 0.4 + math.random() * 0.5,
            size = (2 + math.random() * 4) * self.scale,
            r = color[1], g = color[2], b = color[3]
        })
    end
end

function SingularityPlay:updateParticles(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vx = p.vx * 0.96
        p.vy = p.vy * 0.96
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function SingularityPlay:addPopup(x, y, text, color)
    table.insert(self.popups, {
        x = x, y = y, text = text,
        life = 1.2, maxLife = 1.2,
        r = color[1], g = color[2], b = color[3]
    })
end

function SingularityPlay:updatePopups(dt)
    for i = #self.popups, 1, -1 do
        local p = self.popups[i]
        p.y = p.y - 40 * dt * self.scale
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.popups, i)
        end
    end
end

function SingularityPlay:updatePullLines(dt)
    if self.pullActive and self.energy > 0 then
        if math.random() < 0.4 then
            local angle = math.random() * math.pi * 2
            local dist = (PULL_RADIUS * 0.8 + math.random() * PULL_RADIUS * 0.4) * self.scale
            table.insert(self.pullLines, {
                x = self.px + math.cos(angle) * dist,
                y = self.py + math.sin(angle) * dist,
                angle = angle,
                dist = dist,
                life = 0.4 + math.random() * 0.3,
                maxLife = 0.4 + math.random() * 0.3
            })
        end
    end
    for i = #self.pullLines, 1, -1 do
        local pl = self.pullLines[i]
        pl.life = pl.life - dt
        pl.dist = pl.dist - 200 * dt * self.scale
        pl.x = self.px + math.cos(pl.angle) * pl.dist
        pl.y = self.py + math.sin(pl.angle) * pl.dist
        if pl.life <= 0 or pl.dist < 10 then
            table.remove(self.pullLines, i)
        end
    end
end

function SingularityPlay:updateBackground(dt)
    for _, star in ipairs(self.bgStars) do
        star.blink = star.blink + dt * (1 + math.random() * 0.5)
        if self.pullActive and self.energy > 0 then
            local dx = self.px - star.x
            local dy = self.py - star.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 5 then
                star.x = star.x + (dx / dist) * 30 * dt * self.scale
                star.y = star.y + (dy / dist) * 30 * dt * self.scale
            end
        end
        -- wrap around
        if star.x < -10 then star.x = self.w + 10 end
        if star.x > self.w + 10 then star.x = -10 end
        if star.y < -10 then star.y = self.h + 10 end
        if star.y > self.h + 10 then star.y = -10 end
    end
end

function SingularityPlay:updateMultiplier(dt)
    if self.multiplier > 1.0 then
        self.multTimer = self.multTimer + dt
        if self.multTimer > 3.0 then
            self.multiplier = math.max(1.0, self.multiplier - MULT_DECAY_RATE * dt)
        end
    end
end

function SingularityPlay:updateAudio(dt)
    if self.pullActive and self.energy > 0 then
        local vol = math.min(0.2, self.pullDrone:getVolume() + dt * 0.5)
        self.pullDrone:setVolume(vol)
        if not self.pullDrone:isPlaying() then self.pullDrone:play() end
    else
        local vol = math.max(0, self.pullDrone:getVolume() - dt * 0.8)
        self.pullDrone:setVolume(vol)
        if vol <= 0 then self.pullDrone:stop() end
    end
end

-- ─── DRAW ───────────────────────────────────────────────
function SingularityPlay:draw()
    local w, h = self.w, self.h
    local s = self.scale

    -- background
    self:drawBackground()

    -- apply screen effects
    love.graphics.push()
    self.screenEffects:apply()

    -- pull radius indicator
    if self.pullRadiusAlpha > 0.001 then
        local pr = PULL_RADIUS * s
        love.graphics.setColor(0.4, 0.2, 0.8, self.pullRadiusAlpha * 0.3)
        love.graphics.setLineWidth(1.5 * s)
        love.graphics.circle('line', self.px, self.py, pr)
        -- inner gradient
        for i = 1, 4 do
            local r = pr * (1 - i * 0.15)
            love.graphics.setColor(0.5, 0.3, 1.0, self.pullRadiusAlpha * 0.02 * i)
            love.graphics.circle('fill', self.px, self.py, r)
        end
    end

    -- pull lines
    self:drawPullLines()

    -- shockwaves
    self:drawShockwaves()

    -- enemies
    self:drawEnemies()

    -- particles
    self:drawParticles()

    -- player
    if self.playerAlive then
        self:drawPlayer()
    end

    love.graphics.pop()

    -- screen effect overlays
    self.screenEffects:draw()

    -- HUD (not affected by shake)
    self:drawHUD()

    -- popups
    self:drawPopups()

    -- wave announcement
    if self.waveAnnounceTimer > 0 then
        self:drawWaveAnnounce()
    end

    -- pause overlay
    if self.paused then
        self:drawPause()
    end

    -- game over overlay
    if self.gameOver then
        self:drawGameOver()
    end
end

function SingularityPlay:drawBackground()
    local w, h = self.w, self.h
    -- deep space gradient
    for y = 0, h, 4 do
        local t = y / h
        love.graphics.setColor(0.008 + t * 0.012, 0.005 + t * 0.008, 0.025 + t * 0.04, 1)
        love.graphics.rectangle('fill', 0, y, w, 4)
    end

    -- nebulae
    for _, n in ipairs(self.bgNebulae) do
        love.graphics.setColor(n.r, n.g, n.b, n.alpha)
        love.graphics.circle('fill', n.x, n.y, n.radius)
    end

    -- stars
    for _, star in ipairs(self.bgStars) do
        local a = star.baseAlpha * (0.6 + 0.4 * math.sin(star.blink))
        love.graphics.setColor(0.7, 0.75, 1.0, a)
        love.graphics.circle('fill', star.x, star.y, star.size * self.scale)
    end
end

function SingularityPlay:drawPlayer()
    local s = self.scale
    local px, py = self.px, self.py
    local pulse = math.sin(self.time * 3) * 0.15 + 0.85

    -- invulnerability blink
    if self.invulnTimer > 0 and math.sin(self.time * 20) > 0 then
        return
    end

    -- gravitational distortion rings
    local ringCount = self.pullActive and 6 or 4
    for i = ringCount, 1, -1 do
        local r = (15 + i * 12) * s * pulse
        local a = 0.08 / i
        if self.pullActive and self.energy > 0 then
            r = r * (0.7 + 0.3 * math.sin(self.time * 5 + i))
            a = a * 1.5
            love.graphics.setColor(0.6, 0.3, 1.0, a)
        else
            love.graphics.setColor(0.3, 0.2, 0.6, a)
        end
        love.graphics.circle('fill', px, py, r)
    end

    -- event horizon ring
    love.graphics.setLineWidth(2 * s)
    if self.pullActive and self.energy > 0 then
        love.graphics.setColor(0.7, 0.4, 1.0, 0.6 * pulse)
        love.graphics.circle('line', px, py, 12 * s)
        -- inner glow
        love.graphics.setColor(0.8, 0.6, 1.0, 0.4)
        love.graphics.circle('fill', px, py, 8 * s)
    else
        love.graphics.setColor(0.4, 0.25, 0.7, 0.5 * pulse)
        love.graphics.circle('line', px, py, 10 * s)
    end

    -- core
    love.graphics.setColor(1, 0.95, 1, 0.95 * pulse)
    love.graphics.circle('fill', px, py, 3 * s)

    -- energy ring around player
    self:drawEnergyRing()
end

function SingularityPlay:drawEnergyRing()
    local s = self.scale
    local px, py = self.px, self.py
    local pct = self.energy / ENERGY_MAX
    local ringRadius = 22 * s
    local segments = 48
    local anglePerSegment = (math.pi * 2) / segments
    local filled = math.floor(pct * segments)

    love.graphics.setLineWidth(2 * s)
    for i = 0, segments - 1 do
        local startAngle = -math.pi / 2 + i * anglePerSegment
        local endAngle = startAngle + anglePerSegment * 0.8
        local x1 = px + math.cos(startAngle) * ringRadius
        local y1 = py + math.sin(startAngle) * ringRadius
        local x2 = px + math.cos(endAngle) * ringRadius
        local y2 = py + math.sin(endAngle) * ringRadius

        if i < filled then
            local t = i / segments
            love.graphics.setColor(0.3 + t * 0.4, 0.2 + (1 - t) * 0.6, 1.0, 0.6)
        else
            love.graphics.setColor(0.15, 0.1, 0.3, 0.2)
        end
        love.graphics.line(x1, y1, x2, y2)
    end
end

function SingularityPlay:drawPullLines()
    for _, pl in ipairs(self.pullLines) do
        local a = (pl.life / pl.maxLife) * 0.3
        love.graphics.setColor(0.5, 0.3, 1.0, a)
        love.graphics.setLineWidth(1 * self.scale)
        local endX = self.px + math.cos(pl.angle) * (pl.dist - 15 * self.scale)
        local endY = self.py + math.sin(pl.angle) * (pl.dist - 15 * self.scale)
        love.graphics.line(pl.x, pl.y, endX, endY)
    end
end

function SingularityPlay:drawShockwaves()
    for _, sw in ipairs(self.shockwaves) do
        local progress = sw.life / sw.maxLife
        local a = (1 - progress) * 0.5
        love.graphics.setColor(sw.color[1], sw.color[2], sw.color[3], a)
        love.graphics.setLineWidth(3 * self.scale * (1 - progress))
        love.graphics.circle('line', sw.x, sw.y, sw.radius)
    end
end

function SingularityPlay:drawEnemies()
    local s = self.scale
    for _, e in ipairs(self.enemies) do
        local etype = ENEMY_TYPES[e.type]
        local r, g, b = etype.color[1], etype.color[2], etype.color[3]
        local radius = etype.radius * s

        -- glow when being pulled
        if self.pullActive and self.energy > 0 then
            local dx = self.px - e.x
            local dy = self.py - e.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < PULL_RADIUS * s then
                local intensity = 1 - dist / (PULL_RADIUS * s)
                love.graphics.setColor(r, g, b, intensity * 0.15)
                love.graphics.circle('fill', e.x, e.y, radius * 2.5)
            end
        end

        -- draw shape
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.setLineWidth(2 * s)

        if etype.shape == 'circle' then
            love.graphics.circle('line', e.x, e.y, radius)
            love.graphics.setColor(r, g, b, 0.15)
            love.graphics.circle('fill', e.x, e.y, radius)
        elseif etype.shape == 'triangle' then
            local verts = {}
            for i = 0, 2 do
                local angle = -math.pi / 2 + i * (math.pi * 2 / 3) + e.time * 1.5
                table.insert(verts, e.x + math.cos(angle) * radius)
                table.insert(verts, e.y + math.sin(angle) * radius)
            end
            love.graphics.polygon('line', verts)
            love.graphics.setColor(r, g, b, 0.15)
            love.graphics.polygon('fill', verts)
        elseif etype.shape == 'ring' then
            love.graphics.circle('line', e.x, e.y, radius)
            love.graphics.circle('line', e.x, e.y, radius * 0.5)
        elseif etype.shape == 'hexagon' then
            local verts = {}
            for i = 0, 5 do
                local angle = i * (math.pi / 3) + e.time * 0.5
                table.insert(verts, e.x + math.cos(angle) * radius)
                table.insert(verts, e.y + math.sin(angle) * radius)
            end
            love.graphics.polygon('line', verts)
            love.graphics.setColor(r, g, b, 0.15)
            love.graphics.polygon('fill', verts)
            -- hp indicator for tanks
            if e.hp and e.hp > 1 then
                love.graphics.setColor(r, g, b, 0.5)
                love.graphics.circle('fill', e.x, e.y, 2 * s * e.hp)
            end
        elseif etype.shape == 'square' then
            love.graphics.push()
            love.graphics.translate(e.x, e.y)
            love.graphics.rotate(e.time * 2)
            love.graphics.rectangle('line', -radius, -radius, radius * 2, radius * 2)
            love.graphics.setColor(r, g, b, 0.15)
            love.graphics.rectangle('fill', -radius, -radius, radius * 2, radius * 2)
            love.graphics.pop()
        end

        -- core dot
        love.graphics.setColor(r, g, b, 0.7)
        love.graphics.circle('fill', e.x, e.y, 2 * s)
    end
end

function SingularityPlay:drawParticles()
    for _, p in ipairs(self.particles) do
        local a = (p.life / p.maxLife)
        love.graphics.setColor(p.r, p.g, p.b, a * 0.8)
        love.graphics.circle('fill', p.x, p.y, p.size * (p.life / p.maxLife))
    end
end

function SingularityPlay:drawPopups()
    love.graphics.setFont(self.small_font)
    for _, p in ipairs(self.popups) do
        local a = math.min(1, p.life / (p.maxLife * 0.3))
        love.graphics.setColor(p.r, p.g, p.b, a * 0.9)
        love.graphics.printf(p.text, p.x - 50 * self.scale, p.y, 100 * self.scale, "center")
    end
end

function SingularityPlay:drawHUD()
    local w, h = self.w, self.h
    local s = self.scale

    -- score (top center)
    love.graphics.setFont(self.score_font)
    love.graphics.setColor(0.8, 0.7, 1.0, 0.9)
    love.graphics.printf(tostring(math.floor(self.score)), 0, 15 * s, w, "center")

    -- wave (top left)
    love.graphics.setFont(self.hud_font)
    love.graphics.setColor(0.5, 0.4, 0.8, 0.7)
    love.graphics.printf("WAVE " .. self.wave, 15 * s, 15 * s, 200 * s, "left")

    -- multiplier (below score)
    if self.multiplier > 1.0 then
        love.graphics.setFont(self.hud_font)
        local multAlpha = 0.7 + 0.3 * math.sin(self.time * 4)
        love.graphics.setColor(1, 0.7, 0.2, multAlpha)
        love.graphics.printf(string.format("x%.1f", self.multiplier), 0, 50 * s, w, "center")
    end

    -- health pips (top right)
    for i = 1, MAX_HEALTH do
        local hx = w - 20 * s - (MAX_HEALTH - i) * 22 * s
        local hy = 22 * s
        if i <= self.health then
            love.graphics.setColor(0.6, 0.3, 1.0, 0.8)
            love.graphics.circle('fill', hx, hy, 7 * s)
            love.graphics.setColor(0.8, 0.6, 1.0, 0.9)
            love.graphics.circle('line', hx, hy, 7 * s)
        else
            love.graphics.setColor(0.2, 0.15, 0.3, 0.4)
            love.graphics.circle('line', hx, hy, 7 * s)
        end
    end

    -- energy bar (bottom left)
    local barW = 180 * s
    local barH = 10 * s
    local barX = 15 * s
    local barY = h - 35 * s
    local pct = self.energy / ENERGY_MAX

    love.graphics.setFont(self.small_font)
    love.graphics.setColor(0.4, 0.3, 0.6, 0.5)
    love.graphics.printf("ENERGY", barX, barY - 16 * s, barW, "left")

    love.graphics.setColor(0.08, 0.05, 0.15, 0.7)
    love.graphics.rectangle('fill', barX, barY, barW, barH, 3 * s, 3 * s)

    if pct > 0 then
        local r, g, b = 0.4, 0.3, 1.0
        if pct < 0.25 then r, g, b = 1.0, 0.3, 0.3 end
        love.graphics.setColor(r, g, b, 0.7)
        love.graphics.rectangle('fill', barX, barY, barW * pct, barH, 3 * s, 3 * s)
        -- glow tip
        love.graphics.setColor(r, g, b, 0.3)
        love.graphics.circle('fill', barX + barW * pct, barY + barH / 2, 4 * s)
    end

    love.graphics.setColor(0.3, 0.2, 0.5, 0.4)
    love.graphics.setLineWidth(1 * s)
    love.graphics.rectangle('line', barX, barY, barW, barH, 3 * s, 3 * s)

    -- high score (top center, small)
    if self.highScore > 0 then
        love.graphics.setFont(self.small_font)
        love.graphics.setColor(0.4, 0.35, 0.6, 0.4)
        love.graphics.printf("HI " .. math.floor(self.highScore), 0, 5 * s, w, "center")
    end

    -- enemies remaining
    if not self.wavePaused and #self.enemies > 0 then
        love.graphics.setFont(self.small_font)
        love.graphics.setColor(0.5, 0.4, 0.7, 0.5)
        love.graphics.printf(#self.enemies + #self.waveSpawnQueue .. " remaining", 0, h - 25 * s, w, "center")
    end

    -- FPS counter
    if DEBUG then
        love.graphics.setFont(self.small_font)
        love.graphics.setColor(0.5, 1.0, 0.5, 0.6)
        love.graphics.printf(string.format("FPS: %d", love.timer.getFPS()), 4, h - 50 * s, 100, "left")
    end
end

function SingularityPlay:drawWaveAnnounce()
    local s = self.scale
    local a = math.min(1, self.waveAnnounceTimer / 0.5)
    local rise = (1 - self.waveAnnounceTimer / 2.5) * 30 * s

    -- glow
    love.graphics.setFont(self.big_font)
    for i = 3, 1, -1 do
        love.graphics.setColor(0.5, 0.3, 1.0, a * 0.05 * i)
        love.graphics.printf(self.waveAnnounceText, i * 2, self.h / 2 - 40 * s - rise, self.w, "center")
    end
    love.graphics.setColor(0.7, 0.5, 1.0, a)
    love.graphics.printf(self.waveAnnounceText, 0, self.h / 2 - 40 * s - rise, self.w, "center")
end

function SingularityPlay:drawPause()
    local w, h = self.w, self.h
    local s = self.scale

    -- dim overlay
    love.graphics.setColor(0.02, 0.01, 0.05, 0.75)
    love.graphics.rectangle('fill', 0, 0, w, h)

    -- pause box
    local boxW = 300 * s
    local boxH = 280 * s
    local bx = w / 2 - boxW / 2
    local by = h / 2 - boxH / 2
    love.graphics.setColor(0.05, 0.03, 0.1, 0.9)
    love.graphics.rectangle('fill', bx, by, boxW, boxH, 8 * s, 8 * s)
    love.graphics.setColor(0.4, 0.25, 0.7, 0.5)
    love.graphics.setLineWidth(2 * s)
    love.graphics.rectangle('line', bx, by, boxW, boxH, 8 * s, 8 * s)

    love.graphics.setFont(self.hud_font)
    love.graphics.setColor(0.6, 0.4, 1.0, 0.8)
    love.graphics.printf("PAUSED", bx, by + 20 * s, boxW, "center")

    local buttons = {"RESUME", "RESTART", "QUIT"}
    local btnW = 220 * s
    local btnH = 45 * s
    love.graphics.setFont(self.med_font)
    for i, text in ipairs(buttons) do
        local btnX = w / 2 - btnW / 2
        local btnY = by + 70 * s + (i - 1) * (btnH + 10 * s)
        local hover = i == self.pauseSelected

        if hover then
            love.graphics.setColor(0.4, 0.2, 0.8, 0.3)
            love.graphics.rectangle('fill', btnX, btnY, btnW, btnH, 5 * s, 5 * s)
            love.graphics.setColor(0.6, 0.4, 1.0, 0.8)
            love.graphics.setLineWidth(2 * s)
            love.graphics.rectangle('line', btnX, btnY, btnW, btnH, 5 * s, 5 * s)
            love.graphics.setColor(0.8, 0.7, 1.0, 1)
        else
            love.graphics.setColor(0.1, 0.06, 0.2, 0.5)
            love.graphics.rectangle('fill', btnX, btnY, btnW, btnH, 5 * s, 5 * s)
            love.graphics.setColor(0.3, 0.2, 0.5, 0.4)
            love.graphics.setLineWidth(1 * s)
            love.graphics.rectangle('line', btnX, btnY, btnW, btnH, 5 * s, 5 * s)
            love.graphics.setColor(0.5, 0.4, 0.7, 0.7)
        end
        love.graphics.printf(text, btnX, btnY + btnH / 2 - self.med_font:getHeight() / 2, btnW, "center")
    end

    love.graphics.setFont(self.small_font)
    love.graphics.setColor(0.4, 0.3, 0.6, 0.4)
    love.graphics.printf("ESC TO RESUME", bx, by + boxH - 30 * s, boxW, "center")
end

function SingularityPlay:drawGameOver()
    local w, h = self.w, self.h
    local s = self.scale
    local fadeIn = math.min(1, self.gameOverTimer / 1.0)

    -- dim overlay
    love.graphics.setColor(0.02, 0.01, 0.04, 0.8 * fadeIn)
    love.graphics.rectangle('fill', 0, 0, w, h)

    if fadeIn < 0.3 then return end

    local cy = h / 2

    -- title
    love.graphics.setFont(self.huge_font)
    love.graphics.setColor(0.7, 0.3, 0.3, fadeIn)
    love.graphics.printf("COLLAPSED", 0, cy - 120 * s, w, "center")

    -- stats
    love.graphics.setFont(self.med_font)
    love.graphics.setColor(0.7, 0.6, 0.9, fadeIn * 0.9)
    love.graphics.printf(string.format("SCORE: %d", math.floor(self.score)), 0, cy - 30 * s, w, "center")

    love.graphics.setFont(self.hud_font)
    love.graphics.setColor(0.5, 0.4, 0.8, fadeIn * 0.7)
    love.graphics.printf(string.format("WAVE: %d", self.wave), 0, cy + 10 * s, w, "center")
    love.graphics.printf(string.format("BEST CHAIN: %d", self.bestChain), 0, cy + 40 * s, w, "center")

    -- new high score?
    if self.score >= self.highScore and self.score > 0 then
        love.graphics.setFont(self.hud_font)
        local hiAlpha = 0.7 + 0.3 * math.sin(self.time * 3)
        love.graphics.setColor(1, 0.85, 0.2, fadeIn * hiAlpha)
        love.graphics.printf("NEW HIGH SCORE!", 0, cy + 65 * s, w, "center")
    elseif self.highScore > 0 then
        love.graphics.setFont(self.small_font)
        love.graphics.setColor(0.4, 0.35, 0.6, fadeIn * 0.5)
        love.graphics.printf(string.format("HIGH SCORE: %d", math.floor(self.highScore)), 0, cy + 70 * s, w, "center")
    end

    if self.gameOverTimer > 1.5 then
        local btnAlpha = math.min(1, (self.gameOverTimer - 1.5) / 0.5)
        love.graphics.setFont(self.med_font)
        love.graphics.setColor(0.6, 0.4, 1.0, btnAlpha * 0.8)
        love.graphics.printf("CLICK TO RETRY", 0, cy + 100 * s, w, "center")

        love.graphics.setFont(self.small_font)
        love.graphics.setColor(0.4, 0.3, 0.6, btnAlpha * 0.5)
        love.graphics.printf("ESC FOR MENU", 0, cy + 135 * s, w, "center")
    end
end

-- ─── INPUT ──────────────────────────────────────────────
function SingularityPlay:keypressed(key)
    if key == 'f3' then
        DEBUG = not DEBUG
        return
    end

    if self.gameOver then
        if key == 'escape' then
            self.bgMusic:stop()
            self.pullDrone:stop()
            GameState.switchTo(SingularityMenu())
        elseif key == 'return' or key == 'space' then
            if self.gameOverTimer > 1.5 then
                self:startGame()
            end
        end
        return
    end

    if key == 'escape' then
        self.paused = not self.paused
        if self.paused then
            self.pauseSelected = 1
            love.mouse.setVisible(true)
            love.mouse.setGrabbed(false)
        else
            love.mouse.setVisible(false)
            love.mouse.setGrabbed(true)
        end
        return
    end

    if self.paused then
        if key == 'up' or key == 'w' then
            self.pauseSelected = math.max(1, self.pauseSelected - 1)
        elseif key == 'down' or key == 's' then
            self.pauseSelected = math.min(3, self.pauseSelected + 1)
        elseif key == 'return' or key == 'space' then
            self:executePauseAction()
        end
    end
end

function SingularityPlay:executePauseAction()
    if self.pauseSelected == 1 then
        -- resume
        self.paused = false
        love.mouse.setVisible(false)
        love.mouse.setGrabbed(true)
    elseif self.pauseSelected == 2 then
        -- restart
        self.paused = false
        self:startGame()
    elseif self.pauseSelected == 3 then
        -- quit
        self.bgMusic:stop()
        self.pullDrone:stop()
        GameState.switchTo(SingularityMenu())
    end
end

function SingularityPlay:mousepressed(x, y, button)
    if self.gameOver and self.gameOverTimer > 1.5 then
        if button == 1 then
            self:startGame()
        end
        return
    end

    if self.paused and button == 1 then
        local s = self.scale
        local w, h = self.w, self.h
        local boxW = 300 * s
        local boxH = 280 * s
        local bx = w / 2 - boxW / 2
        local by = h / 2 - boxH / 2
        local btnW = 220 * s
        local btnH = 45 * s

        for i = 1, 3 do
            local btnX = w / 2 - btnW / 2
            local btnY = by + 70 * s + (i - 1) * (btnH + 10 * s)
            if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
                self.pauseSelected = i
                self:executePauseAction()
                return
            end
        end
    end
end

return SingularityPlay
