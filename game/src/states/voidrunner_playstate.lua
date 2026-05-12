-- NEW: Infinite-scroll Void Runner play state replacing the original fixed PlayArea gameplay loop.
VoidRunnerPlayState = class('VoidRunnerPlayState', GameState)
VoidRunnerPlayState:include(Stateful)

VoidRunnerPlayState.static.NEWRECORD_SOUND = love.audio.newSource('assets/sound/newrecord.wav', 'static')
VoidRunnerPlayState.static.NEWRECORD_SOUND:setVolume(0.2)
VoidRunnerPlayState.static.VMARGIN = 20

function VoidRunnerPlayState:initialize()
    self.buttons = {}

    self.signin_button = MenuButton(MenuButton.CONTROLLER, 1.5, function()
        love.system.googlePlayConnect()
    end, false)

    self.leaderboard_button = MenuButton(MenuButton.LEADERBOARDS, 1.5, function()
        love.system.showLeaderboard(IDS.LEAD_SURVIVAL_TIME)
    end, false)

    self.achievements_button = MenuButton(MenuButton.ACHIEVEMENTS, 1.5, function()
        love.system.showAchievements()
    end, false)

    if ANDROID then
        table.insert(self.buttons, self.signin_button)
        table.insert(self.buttons, self.leaderboard_button)
        table.insert(self.buttons, self.achievements_button)
    end

    if IOS then
        table.insert(self.buttons, self.leaderboard_button)
        self.leaderboard_button.enabled = true
        table.insert(self.buttons, self.achievements_button)
        self.achievements_button.enabled = true
    end

    GameState.initialize(self)
    self:reset()
    self.cam:lookAt(0, 0)
    self:calculateScale()
    self:gotoState('Initial')

    self.screenEffects = ScreenEffects()
    self.audioManager = AudioManager()

    local saveFileInfo = love.filesystem.getInfo("bestscore")
    if saveFileInfo and saveFileInfo.type == "file" then
        local contents, size = love.filesystem.read("bestscore")
        self.bestscore = tonumber(contents)
    else
        self.bestscore = nil
    end

    self.white_fader = {time = 1.0, duration = 1.0}
    self.attempts = 0
    self.ignore_touch = {}
end

function VoidRunnerPlayState:flashWhite(duration)
    self.white_fader = {time = 0, duration = duration}
end

function VoidRunnerPlayState:isInState(stateName)
    local stack = self:getStateStackDebugInfo()
    return stack[1] == stateName
end

function VoidRunnerPlayState:reset()
    self.timer:clear()
    self.entities = {}
    self.cam:lookAt(0, 0)
    self.parallax = self:addEntity(ParallaxStars())
    self.player = self:addEntity(Player())
    self.player.pos = vector(0, 0)
    self.engineGlow = self:addEntity(EngineGlow(self.player))
    self.speedLines = self:addEntity(SpeedLines(self.parallax))

    self.depth = 0
    self.bestscore = self.bestscore or nil
    self.newrecord = false
    self.score = 0

    self.zoneManager = ZoneManager()
    self.currentZone = 1
    self.zoneColor = {r = 0, g = 0, b = 0}
    self.targetZoneColor = {r = 0, g = 0, b = 0}
    self.zoneTransitionTimer = 0

    self.scrollSpeed = 80

    self.asteroidSpawnTimer = 0
    self.scoutSpawnTimer = 0
    self.dreadnoughtSpawnTimer = 0
    self.powerupSpawnTimer = 0

    self.shield = nil
    self.timeWarpActive = false
    self.timeWarpTimer = 0
    self.timeWarpCharges = 0
    self.magnetBurstCooldown = 0
    self.magnetBurstBaseCooldown = 8.0

    self.multiplier = 1.0
    self.multiplierTimer = 0
    self.lastHitTime = 0
    self.killScore = 0

    self.minelayerSpawnTimer = 0
    self.swarmSpawnTimer = 0

    self.thrustCooldownDisplay = 0

    self.paused = false
    self.paused_time = 0
    self.paused_selected = 1

    self.dead_time = 0
    self.death_explosion = nil
    self.death_slowmo = false
    self.deathRevealTimer = 0
    self.deathRevealStarted = false

    self.nearMissChecks = {}
    self.ignore_touch = {}
    self.active_touches = {}
    self.recordBurstParticles = {}

    if self.screenEffects then
        self.screenEffects = ScreenEffects()
    end

    if CREATE_RECORDING then
        RECORDING = assert(io.open('recording.txt', "w"))
        local seed = os.time()
        math.randomseed(seed)
        RECORDING:write(seed .. "\n")
    end

    if PLAY_RECORDING then
        local rec = love.filesystem.lines('recording.txt')
        RECORDING = function()
            local val = rec()
            return tonumber(val)
        end
        local seed = RECORDING()
        CURRENT_CHECKPOINT = RECORDING()
        math.randomseed(seed)
    end
end

function VoidRunnerPlayState:calculateScale()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    self.scale = math.max(math.min(w / 900, h / 700), 1)
    self.cam:zoomTo(self.scale)

    self.time_font = love.graphics.newFont("assets/roboto.ttf", math.floor(20 * self.scale))
    self.time_font:setFilter('nearest', 'nearest', 0)
    self.best_font = love.graphics.newFont("assets/roboto.ttf", math.floor(20 * self.scale))
    self.best_font:setFilter('nearest', 'nearest', 0)
    self.new_record_font = love.graphics.newFont("assets/roboto.ttf", math.floor(20 * self.scale))
    self.new_record_font:setFilter('nearest', 'nearest', 0)
    self.instruction_font = love.graphics.newFont("assets/roboto.ttf", math.floor(15 * self.scale))
    self.instruction_font:setFilter('nearest', 'nearest', 0)
    self.zone_font = love.graphics.newFont("assets/roboto.ttf", math.floor(14 * self.scale))
    self.zone_font:setFilter('nearest', 'nearest', 0)
    self.mono_font = love.graphics.newFont("assets/roboto.ttf", math.floor(22 * self.scale))
    self.mono_font:setFilter('nearest', 'nearest', 0)
    self.mult_font = love.graphics.newFont("assets/roboto.ttf", math.floor(14 * self.scale))
    self.mult_font:setFilter('nearest', 'nearest', 0)

    local button_top = 0
    if IOS then
        local left, top, right, bottom = love.window.getSafeAreaInsets()
        button_top = top * love.window.getPixelScale()
    end

    for i, button in ipairs(self.buttons) do
        button.pos.x = love.graphics.getWidth()
        button.pos.y = button_top + 40 * self.scale * i
    end
end

function VoidRunnerPlayState:resize(w, h)
    self:calculateScale()
end

function VoidRunnerPlayState:startGame()
    self:reset()
    self:gotoState('Playing')
    self.audioManager:playDrone()
    self.audioManager:playMusic()
    self.attempts = self.attempts + 1
    love.mouse.setVisible(false)
    love.mouse.setGrabbed(true)
    self:hideButtons()
end

function VoidRunnerPlayState:hideButtons()
    for _, button in ipairs(self.buttons) do
        button.hidden = true
    end
end

function VoidRunnerPlayState:showButtons()
    for _, button in ipairs(self.buttons) do
        button.hidden = false
    end
end

function VoidRunnerPlayState:updateButtons(dt)
    for _, button in ipairs(self.buttons) do
        button:update(dt)
    end
    if ANDROID then
        local connected = love.system.isGooglePlayConnected()
        self.signin_button.enabled = not connected
        self.leaderboard_button.enabled = connected
        self.achievements_button.enabled = connected
    end
end

function VoidRunnerPlayState:update(dt)
    local rawDt = dt

    if self.paused then
        self.paused_time = self.paused_time + rawDt
        if self.screenEffects then self.screenEffects:update(rawDt) end
        return
    end

    if self.screenEffects then
        local timeScale = self.screenEffects:getTimeScale(rawDt)
        self.screenEffects:update(rawDt)
        dt = rawDt * timeScale
    end

    if self.timeWarpActive then
        self.timeWarpTimer = self.timeWarpTimer - rawDt
        dt = dt * 0.4
        if self.timeWarpTimer <= 0 then
            self.timeWarpActive = false
            self.timeWarpTimer = 0
        end
    end

    if self.deathRevealStarted then
        self.deathRevealTimer = self.deathRevealTimer - rawDt
        if self.deathRevealTimer <= 0 and not self:isInState('Dead') then
            self.deathRevealStarted = false
            self.death_slowmo = false
            self:gotoState('Dead')
        end
    end

    GameState.update(self, dt)
    self:updateRecordBurst(rawDt)

    if self.player and not self.player:isDead() then
        self.depth = self.depth + self.scrollSpeed * dt
        self.score = self.score + self.scrollSpeed * dt * self.multiplier

        self.scrollSpeed = self.zoneManager:getScrollSpeed(self.depth)
        self.player.scrollSpeed = self.scrollSpeed
        self.player.driftSpeed = 70 + self.depth * 0.025 + self.scrollSpeed * 0.25
        if self.currentZone < 5 then
            self.player.driftSpeed = math.min(self.player.driftSpeed, 190)
        end

        self.zoneTransitionTimer = self.zoneTransitionTimer - dt
        if self.zoneTransitionTimer < 0 then self.zoneTransitionTimer = 0 end

        if self.currentZone >= 5 then
            self.targetZoneColor = self.zoneManager:getChaosColor(self.time)
        end

        local zoneColorSpeed = 0.5 * dt
        self.zoneColor.r = lume.lerp(self.zoneColor.r, self.targetZoneColor.r, zoneColorSpeed)
        self.zoneColor.g = lume.lerp(self.zoneColor.g, self.targetZoneColor.g, zoneColorSpeed)
        self.zoneColor.b = lume.lerp(self.zoneColor.b, self.targetZoneColor.b, zoneColorSpeed)

        if self.parallax then
            self.parallax:setZoneColor(self.zoneColor)
        end

        local newZone = self.zoneManager:getZone(self.depth)
        if newZone ~= self.currentZone then
            local transitioned, zoneName, zoneData = self.zoneManager:checkZoneTransition(self.currentZone, newZone)
            if transitioned then
                self.currentZone = newZone
                self.targetZoneColor = zoneData.color
                self.zoneTransitionTimer = 2.0
                self:addEntity(ZoneTransition(zoneName, zoneData.color))
                self.audioManager:playZoneTone()

                if ANDROID or IOS then
                    if newZone == 3 then love.system.unlockAchievement(IDS.ACH_REACH_THE_SHIPS) end
                    if newZone == 4 then love.system.unlockAchievement(IDS.ACH_REACH_THE_TUNNEL) end
                    if newZone == 5 then love.system.unlockAchievement(IDS.ACH_REACH_ENDLESS_MODE) end
                end
            end
        end

        self:spawnEntities(dt)
        self:updateMultiplier(rawDt)
        self:updateCamera()
        self:updatePowerups(rawDt)
        self:despawnEntities()
        self:checkNearMiss()
    end

    if self.newrecord == false and (self.bestscore == nil or self.depth > self.bestscore) then
        self.newrecord = true
        self.newrecord_visible = true

        if self.bestscore ~= nil then
            VoidRunnerPlayState.NEWRECORD_SOUND:play()

            if ANDROID or IOS then
                love.system.unlockAchievement(IDS.ACH_BEAT_YOUR_PERSONAL_BEST)
            end

            self:triggerRecordBurst()
        end
    end

    self.audioManager:setEnginePitch(self.depth)

    if CREATE_RECORDING then
        RECORDING:write(self.depth .. "\n")
        RECORDING:write(self.player.pos.x .. "\n")
        RECORDING:write(self.player.pos.y .. "\n")
    end

    if PLAY_RECORDING then
        if CURRENT_CHECKPOINT and self.depth >= CURRENT_CHECKPOINT - (1.0 / 60) then
            local x, y = RECORDING(), RECORDING()
            self.player.pos = vector(x, y)
            CURRENT_CHECKPOINT = RECORDING()
        end
    end

    self:updateButtons(rawDt)
    self.white_fader.time = self.white_fader.time + rawDt
end

function VoidRunnerPlayState:spawnEntities(dt)
    local config = self.zoneManager:getSpawnConfig(self.currentZone)
    local camL, camT = self.cam:worldCoords(0, 0)
    local camR, camB = self.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
    local camW = camR - camL

    self.asteroidSpawnTimer = self.asteroidSpawnTimer + dt
    if self.asteroidSpawnTimer > config.asteroidSpawnRate / config.asteroidDensity then
        self.asteroidSpawnTimer = 0
        local numAsteroids = math.floor(config.asteroidDensity)
        if math.random() < (config.asteroidDensity - numAsteroids) then
            numAsteroids = numAsteroids + 1
        end
        for i = 1, numAsteroids do
            local x = lume.random(camL - 50, camR + 50)
            local y = camT - lume.random(50, 250)
            local speed = self.player.driftSpeed + config.asteroidSpeedMult * lume.random(35, 95)
            local vel = vector(lume.random(-10, 10), speed)
            local ast = Asteroid(vector(x, y), vel, self.currentZone)
            self:addEntity(ast)
            self:resolveAsteroidSpawnOverlap(ast)
        end

        if self.currentZone >= 2 and math.random() < 0.22 then
            local clusterMargin = math.min(60, camW * 0.25)
            local clusterX = lume.random(camL + clusterMargin, camR - clusterMargin)
            local clusterY = camT - lume.random(80, 180)
            local clusterCount = math.random(2, self.currentZone >= 5 and 5 or 4)
            for i = 1, clusterCount do
                local offset = vector(lume.random(-45, 45), lume.random(-30, 30))
                local vel = vector(lume.random(-25, 25), self.player.driftSpeed + config.asteroidSpeedMult * lume.random(55, 120))
                local ast = Asteroid(vector(clusterX, clusterY) + offset, vel, self.currentZone, lume.random(8, 22))
                self:addEntity(ast)
                self:resolveAsteroidSpawnOverlap(ast)
            end
        end
    end

    if config.enemyEnabled then
        self.scoutSpawnTimer = self.scoutSpawnTimer + dt
        if config.scoutSpawnRate > 0 and self.scoutSpawnTimer > config.scoutSpawnRate then
            self.scoutSpawnTimer = 0
            local side = math.random() < 0.5 and 'left' or 'right'
            self:addEntity(EnemyScout(side, config.scoutSpawnRate * 1.5))
        end

        self.dreadnoughtSpawnTimer = self.dreadnoughtSpawnTimer + dt
        if config.dreadnoughtSpawnRate > 0 and self.dreadnoughtSpawnTimer > config.dreadnoughtSpawnRate then
            self.dreadnoughtSpawnTimer = 0
            self:addEntity(EnemyDreadnought(config.dreadnoughtSpawnRate * 1.2))
        end
    end

    self.powerupSpawnTimer = self.powerupSpawnTimer + dt
    if self.powerupSpawnTimer > 3.0 then
        self.powerupSpawnTimer = 0
        if math.random() < config.powerupChance then
            local powerupMargin = math.min(30, camW * 0.2)
            local x = lume.random(camL + powerupMargin, camR - powerupMargin)
            local y = camT - lume.random(50, 200)
            local ptype = math.random(1, #Powerup.TYPES)
            self:addEntity(Powerup(vector(x, y), ptype))
        end
    end

    if config.enemyEnabled then
        self.minelayerSpawnTimer = self.minelayerSpawnTimer + dt
        local mlRate = self.currentZone >= 4 and 15 or 25
        if self.minelayerSpawnTimer > mlRate then
            self.minelayerSpawnTimer = 0
            local side = math.random() < 0.5 and 'left' or 'right'
            self:addEntity(EnemyMinelayer(side, 10))
        end

        self.swarmSpawnTimer = self.swarmSpawnTimer + dt
        local swarmRate = self.currentZone >= 5 and 12 or 20
        if self.currentZone >= 3 and self.swarmSpawnTimer > swarmRate then
            self.swarmSpawnTimer = 0
            local side = math.random() < 0.5 and 'left' or 'right'
            local count = math.random(3, 5)
            for i = 1, count do
                self:addEntity(EnemySwarm(side, i - 1, count))
            end
        end
    end
end

function VoidRunnerPlayState:updateMultiplier(dt)
    self.multiplierTimer = self.multiplierTimer + dt
    if self.multiplierTimer >= 8.0 then
        self.multiplierTimer = 0
        self.multiplier = self.multiplier + 0.1
    end
end

function VoidRunnerPlayState:boostMultiplier(amount)
    self.multiplier = self.multiplier + (amount or 0.25)
    self.multiplierTimer = 0
end

function VoidRunnerPlayState:resetMultiplier()
    self.multiplier = 1.0
    self.multiplierTimer = 0
end

function VoidRunnerPlayState:onPlayerDash()
    self:boostMultiplier(0.05)
end

function VoidRunnerPlayState:onEnemyKilled(enemyType)
    local scoreValues = {
        scout = 150,
        dreadnought = 500,
        minelayer = 250,
        swarm = 75,
    }
    local value = scoreValues[enemyType] or 100
    self.score = self.score + value * self.multiplier
    self.killScore = self.killScore + value
    self:boostMultiplier(0.15)
end

function VoidRunnerPlayState:onLaserKill(target)
    if target and target.tag == 'obstacle' then
        local value = 50 * self.multiplier
        self.score = self.score + value
        self.killScore = self.killScore + 50
        self:boostMultiplier(0.1)
    end
end

function VoidRunnerPlayState:triggerRecordBurst()
    local w = love.graphics.getWidth()
    local s = self.scale or 1
    local origin = vector(w / 2, 22 * s)
    self.recordBurstParticles = {}
    for i = 1, 28 do
        local angle = lume.random(-math.pi * 0.95, -math.pi * 0.05)
        local speed = lume.random(35, 125) * s
        table.insert(self.recordBurstParticles, {
            pos = origin:clone(),
            vel = vector(math.cos(angle) * speed, math.sin(angle) * speed),
            life = lume.random(0.45, 0.9),
            maxLife = 0.9,
            size = lume.random(1.5, 4.0) * s
        })
    end
end

function VoidRunnerPlayState:updateRecordBurst(dt)
    local n = #self.recordBurstParticles
    local i = 1
    while i <= n do
        local p = self.recordBurstParticles[i]
        p.pos = p.pos + p.vel * dt
        p.vel = p.vel * 0.94
        p.life = p.life - dt
        if p.life <= 0 then
            self.recordBurstParticles[i] = self.recordBurstParticles[n]
            self.recordBurstParticles[n] = nil
            n = n - 1
        else
            i = i + 1
        end
    end
end

function VoidRunnerPlayState:drawRecordBurst()
    for _, p in ipairs(self.recordBurstParticles) do
        local alpha = math.max(0, p.life / p.maxLife)
        love.graphics.setColor(1.0, 0.85, 0.1, alpha * 0.35)
        love.graphics.circle('fill', p.pos.x, p.pos.y, p.size * 2.5)
        love.graphics.setColor(1.0, 0.95, 0.45, alpha)
        love.graphics.circle('fill', p.pos.x, p.pos.y, p.size)
    end
end

function VoidRunnerPlayState:updateCamera()
    local cx = 0
    local cy = self.player.pos.y
    self.cam:lookAt(cx, cy)

    local jitterIntensity = 0.3 + (self.scrollSpeed / 500) * 0.2
    if self.currentZone >= 4 then
        jitterIntensity = jitterIntensity + 0.25
    end
    local jx = (math.random() - 0.5) * jitterIntensity
    local jy = (math.random() - 0.5) * jitterIntensity
    self.cam:move(jx, jy)
end

function VoidRunnerPlayState:updatePowerups(dt)
    if self.magnetBurstCooldown > 0 then
        self.magnetBurstCooldown = self.magnetBurstCooldown - dt
    end

    for _, pu in ipairs(self:getEntitiesByTag('powerup')) do
        local dist = (pu.pos - self.player.pos):len()
        if dist < 20 then
            self:collectPowerup(pu)
            pu:destroy()
        end
    end
end

function VoidRunnerPlayState:collectPowerup(pu)
    local typeName = pu.powerupType.name
    self.audioManager:playPickup()

    if typeName == 'shield' then
        if not self.shield then
            self.shield = Shield(self.player)
            self:addEntity(self.shield)
        else
            self.shield:activate()
        end
    elseif typeName == 'time_warp' then
        self.timeWarpCharges = math.min(3, self.timeWarpCharges + 1)
        self.screenEffects:flash(0.35, 0.75, 1.0, 0.18, 0.2)
    elseif typeName == 'magnet_burst' then
        if self.magnetBurstCooldown <= 0 then
            local cd = self.magnetBurstBaseCooldown - self.currentZone * 0.5
            self.magnetBurstCooldown = math.max(4, cd)
            self:addEntity(Shockwave(self.player.pos:clone()))
        end
    elseif typeName == 'score_bonus' then
        local bonus = 200 * self.multiplier * self.currentZone
        self.score = self.score + bonus
        self.screenEffects:flash(1.0, 0.85, 0.1, 0.15, 0.15)
    elseif typeName == 'speed_boost' then
        self.screenEffects:flash(0.1, 1.0, 0.4, 0.2, 0.2)
        self.screenEffects:blur(0.3, 0.2)
        if self.player then
            self.player.isDashing = false
            self.player.dashCooldownTimer = 0
        end
    elseif typeName == 'double_laser' then
        if self.player then
            self.player.doubleLaser = true
            self.player.doubleLaserTimer = 10.0
        end
        self.screenEffects:flash(0.8, 0.2, 1.0, 0.15, 0.15)
    end
end

function VoidRunnerPlayState:resolveAsteroidSpawnOverlap(ast)
    if not ast or not ast.collision_shape then return end
    local maxIterations = 8
    for _ = 1, maxIterations do
        local overlapped = false
        for _, other in ipairs(self:getEntitiesByTag('obstacle')) do
            if other ~= ast and other.collision_shape then
                local collides, dx, dy = ast.collision_shape:collidesWith(other.collision_shape)
                if collides then
                    ast.pos = ast.pos - vector(dx, dy)
                    ast.collision_shape:moveTo((ast.pos + ast.collision_offset):unpack())
                    overlapped = true
                end
            end
        end
        if not overlapped then break end
    end
end

function VoidRunnerPlayState:activateTimeWarp()
    if self.timeWarpActive or self.timeWarpCharges <= 0 then return end
    self.timeWarpCharges = self.timeWarpCharges - 1
    self.timeWarpActive = true
    self.timeWarpTimer = 4.0
    self.screenEffects:chromaticAberration(1.0, 4.0)
    self.screenEffects:blur(0.35, 3.5)
end

function VoidRunnerPlayState:despawnEntities()
    local camL, camT = self.cam:worldCoords(0, 0)
    local camR, camB = self.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())

    for _, entity in ipairs(self.entities) do
        if entity.tag == 'obstacle' or entity.tag == 'enemy' or entity.tag == 'projectile' or entity.tag == 'powerup' or entity.tag == 'warning' then
            if entity.pos.y > camB + 100 or entity.pos.y < camT - 500 or entity.pos.x < camL - 200 or entity.pos.x > camR + 200 then
                entity:destroy()
            end
        end
    end
end

function VoidRunnerPlayState:checkNearMiss()
    for _, ast in ipairs(self:getEntitiesByTag('obstacle')) do
        if not ast.warning and ast.time < 2.0 then
            local dist = (ast.pos - self.player.pos):len()
            local surfaceDist = dist - (ast.radius or 0)
            if surfaceDist > 0 and surfaceDist < 30 then
                if not self.nearMissChecks[ast.id] then
                    self.nearMissChecks[ast.id] = true
                    self.audioManager:playNearMiss()
                    self:boostMultiplier(0.2)
                    self.score = self.score + 25 * self.multiplier
                end
            end
        end
    end
end

function VoidRunnerPlayState:onShieldHit()
    self:resetMultiplier()
    self.screenEffects:hitstop(2)
    self.screenEffects:shake(10, 0.2)
    self.audioManager:playShield()
end

function VoidRunnerPlayState:onPlayerDeath()
    self:resetMultiplier()
    self.audioManager:stopEngineHum()
    self.audioManager:playExplosion()
    self:addEntity(Explosion(self.player.pos:clone(), 50))
    self.screenEffects:shake(30, 0.5)
    self.screenEffects:slowMotion(0.1, 0.5)
    self.death_slowmo = true
    self.deathRevealStarted = true
    self.deathRevealTimer = 0.5
end

function VoidRunnerPlayState:activateMagnetBurst()
    if self.magnetBurstCooldown <= 0 then
        local cd = self.magnetBurstBaseCooldown - self.currentZone * 0.5
        self.magnetBurstCooldown = math.max(4, cd)
        self:addEntity(Shockwave(self.player.pos:clone()))
    end
end

function VoidRunnerPlayState:keypressed(key, scancode, isrepeat)
    if key == 'f3' then
        DEBUG = not DEBUG
        return
    end

    if key == 'escape' then
        if self.paused then
            self.paused = false
            self.audioManager:playDrone()
            love.mouse.setVisible(false)
            love.mouse.setGrabbed(true)
        else
            self.paused = true
            self.paused_time = 0
            self.paused_selected = 1
            self.paused_buttons = {
                {text = "RESUME", action = function()
                    self.paused = false
                    self.audioManager:playDrone()
                    love.mouse.setVisible(false)
                    love.mouse.setGrabbed(true)
                end},
                {text = "RESTART", action = function()
                    self.paused = false
                    self:startGame()
                end},
                {text = "QUIT", action = function() GameState.switchTo(VoidRunnerMainMenu()) end}
            }
            self.audioManager:stopDrone()
            love.mouse.setVisible(true)
            love.mouse.setGrabbed(false)
        end
    end

    if self.paused then
        if key == 'up' or key == 'w' then
            self.paused_selected = math.max(1, self.paused_selected - 1)
        elseif key == 'down' or key == 's' then
            self.paused_selected = math.min(#self.paused_buttons, self.paused_selected + 1)
        elseif key == 'return' or key == 'space' then
            self.paused_buttons[self.paused_selected].action()
        end
        return
    end

    if not self.player or self.player:isDead() then return end

    if key == 'space' then
        self:activateTimeWarp()
    end
end

function VoidRunnerPlayState:gamepadpressed(joystick, button)
    if self.paused then
        if button == 'dpup' then
            self.paused_selected = math.max(1, self.paused_selected - 1)
        elseif button == 'dpdown' then
            self.paused_selected = math.min(#self.paused_buttons, self.paused_selected + 1)
        elseif button == 'a' or button == 'start' then
            if self.paused_buttons then
                self.paused_buttons[self.paused_selected].action()
            end
        end
        return
    end

    if button == 'start' then
        self:keypressed('escape')
        return
    end

    if not self.player or self.player:isDead() then return end

    if button == 'a' or button == 'x' then
        self.player:manualFire()
    elseif button == 'b' or button == 'y' then
        self:activateTimeWarp()
    elseif button == 'dpleft' then
        self.player:dash(-1, 0)
    elseif button == 'dpright' then
        self.player:dash(1, 0)
    elseif button == 'dpup' then
        self.player:dash(0, -1)
    elseif button == 'dpdown' then
        self.player:dash(0, 1)
    end
end

function VoidRunnerPlayState:draw()
    GameState.draw(self)
end

function VoidRunnerPlayState:drawBackground()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local zr = self.zoneColor.r or 0
    local zg = self.zoneColor.g or 0
    local zb = self.zoneColor.b or 0

    if not self.bgCanvas or self.bgCanvas:getWidth() ~= w or self.bgCanvas:getHeight() ~= h
       or self.bgLastZR ~= zr or self.bgLastZG ~= zg or self.bgLastZB ~= zb then
        self.bgCanvas = love.graphics.newCanvas(w, h)
        self.bgLastZR, self.bgLastZG, self.bgLastZB = zr, zg, zb
        love.graphics.setCanvas(self.bgCanvas)
        for y = 0, h, 4 do
            local t = y / h
            local r = 0.02 + t * 0.03 + zr * 0.5
            local g = 0.02 + t * 0.04 + zg * 0.5
            local b = 0.08 + t * 0.08 + zb * 0.5
            love.graphics.setColor(r, g, b, 1)
            love.graphics.rectangle('fill', 0, y, w, 4)
        end
        love.graphics.setCanvas()
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.bgCanvas, 0, 0)
end

function VoidRunnerPlayState:overlay()
    if self.screenEffects then
        self.screenEffects:draw()
    end

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local s = self.scale
    local cx = w / 2
    local flicker = math.sin(self.time * 12) * 0.04 + 0.96

    local function bracket(x, y, bw, bh, color, lw)
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
        love.graphics.setLineWidth((lw or 1) * s)
        local corner = 5 * s
        love.graphics.line(x, y + bh, x, y + bh - corner, x, y, x + corner, y)
        love.graphics.line(x + bw, y, x + bw - corner, y, x + bw, y, x + bw, y + corner)
        love.graphics.line(x + bw, y + bh, x + bw - corner, y + bh, x + bw, y + bh, x + bw, y + bh - corner)
        love.graphics.line(x, y + bh, x + corner, y + bh, x, y + bh, x, y + bh - corner)
    end

    -- safe area offset for mobile
    local safeTop, safeLeft = 0, 0
    if MOBILE and love.window.getSafeAreaInsets then
        local l, t = love.window.getSafeAreaInsets()
        local ps = love.window.getPixelScale and love.window.getPixelScale() or 1
        safeTop = t * ps
        safeLeft = l * ps
    end

    -- mobile touch zone indicators
    if MOBILE and self.player and not self.player:isDead() and not self.paused then
        love.graphics.setColor(0.2, 0.5, 1.0, 0.06)
        love.graphics.rectangle('line', safeLeft + 4, h * 0.6, w * 0.3, h * 0.35, 8, 8)
        love.graphics.rectangle('line', w - safeLeft - w * 0.3 - 4, h * 0.6, w * 0.3, h * 0.35, 8, 8)
        love.graphics.setFont(self.zone_font)
        love.graphics.setColor(0.3, 0.6, 1.0, 0.12)
        love.graphics.printf("DASH", safeLeft + 4, h * 0.75, w * 0.3, "center")
        love.graphics.printf("FIRE", w - safeLeft - w * 0.3 - 4, h * 0.75, w * 0.3, "center")
    end

    -- === TOP LEFT: ZONE INFO ===
    local zoneName = self.zoneManager:getZoneName(self.currentZone)
    local zoneStr = string.format("ZONE %d", self.currentZone)
    local tlX = (14 + safeLeft) * s
    local tlY = (10 * s) + safeTop
    bracket(tlX - 4 * s, tlY - 2 * s, 140 * s, 38 * s, {0.25, 0.6, 1.0, 0.35}, 1)
    love.graphics.setFont(self.zone_font)
    love.graphics.setColor(0.5, 0.75, 1.0, 0.5 * flicker)
    love.graphics.printf(zoneStr, tlX, tlY, 120 * s, "left")
    love.graphics.setColor(0.4, 0.65, 0.95, 0.7 * flicker)
    love.graphics.printf(zoneName, tlX, tlY + 16 * s, 200 * s, "left")

    -- === TOP CENTER: DEPTH ===
    local depthStr = string.format("%05dm", math.floor(self.depth))
    local tcW = 160 * s
    local tcH = 32 * s
    local tcX = cx - tcW / 2
    local tcY = (10 * s) + safeTop
    bracket(tcX, tcY, tcW, tcH, {0.3, 0.65, 1.0, 0.45}, 1.2)
    love.graphics.setFont(self.mono_font)
    love.graphics.setColor(0.9, 0.95, 1.0, 0.9 * flicker)
    love.graphics.printf(depthStr, tcX, tcY + tcH / 2 - 11 * s, tcW, "center")
    -- tiny label above
    love.graphics.setFont(self.zone_font)
    love.graphics.setColor(0.35, 0.6, 1.0, 0.4)
    love.graphics.printf("DEPTH", tcX, tcY - 12 * s, tcW, "center")

    -- === TOP RIGHT: WARP + SHIELD ===
    local trX = w - 14 * s
    if self.timeWarpCharges > 0 or self.timeWarpActive then
        love.graphics.setFont(self.zone_font)
        if self.timeWarpActive then
            love.graphics.setColor(0.3, 0.8, 1.0, 0.75)
            love.graphics.printf(string.format("WARP %.1f", self.timeWarpTimer), trX - 100 * s, 10 * s, 96 * s, "right")
        else
            love.graphics.setColor(0.4, 0.7, 1.0, 0.45)
            love.graphics.printf("WARP", trX - 60 * s, 10 * s, 56 * s, "right")
        end
    end
    -- shield hex
    if self.shield and self.shield:isActive() then
        love.graphics.setColor(0.15, 0.85, 1.0, 0.75 * flicker)
    elseif self.shield and self.shield:isRecharging() then
        love.graphics.setColor(0.35, 0.5, 0.6, 0.45 * flicker)
    else
        love.graphics.setColor(0.3, 0.35, 0.4, 0.35 * flicker)
    end
    local hs = 7 * s
    local hy = 30 * s
    local hv = {}
    for i = 0, 5 do
        local a = i * math.pi / 3
        table.insert(hv, trX - hs + math.cos(a) * hs)
        table.insert(hv, hy + math.sin(a) * hs)
    end
    love.graphics.setLineWidth(1.5 * s)
    love.graphics.polygon('line', hv)

    -- === MULTIPLIER (small, next to depth) ===
    if self.multiplier > 1.0 then
        love.graphics.setFont(self.mult_font)
        love.graphics.setColor(1, 0.8, 0.15, 0.85 * flicker)
        love.graphics.printf(string.format("x%.1f", self.multiplier), cx + tcW / 2 + 6 * s, tcY + tcH / 2 - 9 * s, 50 * s, "left")
    end

    self:drawRecordBurst()

    -- === CORNER RETICLES (subtle ship HUD feel) ===
    love.graphics.setColor(0.25, 0.6, 1.0, 0.12)
    love.graphics.setLineWidth(1 * s)
    local retSize = 18 * s
    local retOff = 6 * s
    -- top-left reticle
    love.graphics.line(retOff, retOff + retSize, retOff, retOff)
    love.graphics.line(retOff, retOff, retOff + retSize, retOff)
    -- top-right
    love.graphics.line(w - retOff, retOff + retSize, w - retOff, retOff)
    love.graphics.line(w - retOff, retOff, w - retOff - retSize, retOff)
    -- bottom-left
    love.graphics.line(retOff, h - retOff - retSize, retOff, h - retOff)
    love.graphics.line(retOff, h - retOff, retOff + retSize, h - retOff)
    -- bottom-right
    love.graphics.line(w - retOff, h - retOff - retSize, w - retOff, h - retOff)
    love.graphics.line(w - retOff, h - retOff, w - retOff - retSize, h - retOff)

    -- === CENTER CROSSHAIR (when alive) ===
    if self.player and not self.player:isDead() then
        love.graphics.setColor(0.25, 0.65, 1.0, 0.08)
        love.graphics.setLineWidth(0.5 * s)
        local cr = 12 * s
        love.graphics.line(cx - cr, h / 2, cx + cr, h / 2)
        love.graphics.line(cx, h / 2 - cr, cx, h / 2 + cr)
    end

    -- === TARGETING HUD (auto-aim lock-on sequence) ===
    if self.player and self.player.autoAimTarget and not self.player:isDead() then
        local target = self.player.autoAimTarget
        local sx, sy = self.player.pos.x, self.player.pos.y
        local tx, ty = target.pos.x, target.pos.y
        local screenTx, screenTy = self.cam:cameraCoords(tx, ty)
        local screenSx, screenSy = self.cam:cameraCoords(sx, sy)
        local state = self.player.autoAimState

        local tSize = 18 * s
        local corner = 5 * s
        local pulse = math.sin(self.time * 8) * 0.15 + 0.85

        -- colors based on state
        local r, g, b = 0.3, 0.8, 1.0
        local textLabel = "TARGETING"
        local alpha = 0.6 * pulse

        if state == 'acquiring' then
            r, g, b = 0.3, 0.8, 1.0
            textLabel = "TARGETING"
            alpha = 0.55 * pulse
        elseif state == 'locking' then
            -- red flicker
            local flicker = math.sin(self.time * 25) * 0.3 + 0.7
            r, g, b = 1.0, 0.15, 0.15
            textLabel = "LOCKING"
            alpha = 0.75 * flicker
        elseif state == 'firing' then
            r, g, b = 1.0, 0.3, 0.3
            textLabel = "FIRING"
            alpha = 0.9
        end

        -- targeting line
        love.graphics.setColor(r, g, b, alpha * 0.2)
        love.graphics.setLineWidth(0.5 * s)
        love.graphics.line(screenSx, screenSy, screenTx, screenTy)

        -- bracket reticle around target
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.setLineWidth(1.2 * s)
        -- top-left
        love.graphics.line(screenTx - tSize, screenTy - tSize + corner, screenTx - tSize, screenTy - tSize)
        love.graphics.line(screenTx - tSize, screenTy - tSize, screenTx - tSize + corner, screenTy - tSize)
        -- top-right
        love.graphics.line(screenTx + tSize - corner, screenTy - tSize, screenTx + tSize, screenTy - tSize)
        love.graphics.line(screenTx + tSize, screenTy - tSize, screenTx + tSize, screenTy - tSize + corner)
        -- bottom-left
        love.graphics.line(screenTx - tSize, screenTy + tSize - corner, screenTx - tSize, screenTy + tSize)
        love.graphics.line(screenTx - tSize, screenTy + tSize, screenTx - tSize + corner, screenTy + tSize)
        -- bottom-right
        love.graphics.line(screenTx + tSize - corner, screenTy + tSize, screenTx + tSize, screenTy + tSize)
        love.graphics.line(screenTx + tSize, screenTy + tSize, screenTx + tSize, screenTy + tSize - corner)

        -- center dot
        love.graphics.setColor(r, g, b, alpha * 0.8)
        love.graphics.circle('fill', screenTx, screenTy, 2 * s)

        -- state text
        love.graphics.setFont(self.zone_font)
        love.graphics.setColor(r, g, b, alpha * 0.7)
        love.graphics.printf(textLabel, screenTx - 30 * s, screenTy - tSize - 14 * s, 60 * s, "center")
    end

    -- === BOTTOM: DASH ARC ===
    if self.player and not self.player:isDead() then
        local dashProg = 0
        if self.player.dashCooldownMax and self.player.dashCooldownMax > 0 then
            dashProg = math.min(1, 1 - (self.player.dashCooldownTimer / self.player.dashCooldownMax))
        end
        local arcR = 16 * s
        local arcY = h - 8 * s
        local arcLW = 2.2 * s

        love.graphics.setColor(0.08, 0.14, 0.25, 0.5)
        love.graphics.setLineWidth(arcLW)
        love.graphics.arc('line', 'open', cx, arcY, arcR, math.pi, math.pi * 2)

        if dashProg > 0 then
            love.graphics.setColor(0.25, 0.75, 1.0, 0.8)
            love.graphics.setLineWidth(arcLW)
            love.graphics.arc('line', 'open', cx, arcY, arcR, math.pi, math.pi + dashProg * math.pi)
        end
    end

    for _, button in ipairs(self.buttons) do
        button:overlay(self.scale)
    end

    for _, entity in ipairs(self.entities) do
        if entity.tag == 'transition' then
            entity:drawOverlay(self.scale)
        end
    end

    if self.currentZone >= 4 and not self.paused then
        local stormAlpha = self.currentZone == 4 and 0.05 or 0.035
        love.graphics.setColor(0.25, 0.7, 0.35, stormAlpha * (0.6 + 0.4 * math.sin(self.time * 17)))
        love.graphics.rectangle('fill', 0, 0, w, h)
    end

    if self.paused then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle('fill', 0, 0, w, h)

        local panelW = 420 * s
        local panelH = 260 * s
        local px = cx - panelW / 2
        local py = h / 2 - 120 * s

        love.graphics.setColor(0.02, 0.03, 0.08, 0.8)
        love.graphics.rectangle('fill', px, py, panelW, panelH)
        love.graphics.setColor(0.12, 0.35, 0.7, 0.4)
        love.graphics.setLineWidth(1.5 * s)
        love.graphics.rectangle('line', px, py, panelW, panelH)
        love.graphics.setColor(0.08, 0.2, 0.45, 0.12)
        love.graphics.rectangle('line', px + 2, py + 2, panelW - 4, panelH - 4)

        local titlePulse = math.sin(self.paused_time * 3) * 0.1 + 0.9
        love.graphics.setColor(0.15, 0.45, 1.0, 0.2 * titlePulse)
        love.graphics.setFont(self.instruction_font)
        love.graphics.printf("PAUSED", 0, py + 22 * s, w, "center")
        love.graphics.setColor(0.35, 0.75, 1.0, 0.9 * titlePulse)
        love.graphics.printf("PAUSED", 0, py + 20 * s, w, "center")

        local btnW = 220 * s
        local btnH = 46 * s
        local btnGap = 14 * s
        local startY = py + 80 * s
        local bx = cx - btnW / 2

        for i, btn in ipairs(self.paused_buttons) do
            local by = startY + (i - 1) * (btnH + btnGap)
            local sel = i == self.paused_selected
            local r, g, b = 0.25, 0.65, 1.0
            local pulse = math.sin(self.paused_time * 3) * 0.12 + 0.88

            love.graphics.setColor(0.04, 0.06, 0.14, 0.9)
            love.graphics.rectangle('fill', bx, by, btnW, btnH)
            love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, 0.5)
            love.graphics.setLineWidth(1.5 * s)
            love.graphics.rectangle('line', bx, by, btnW, btnH)

            if sel then
                love.graphics.setColor(r, g, b, pulse * 0.18)
                love.graphics.rectangle('fill', bx + 1, by + 1, btnW - 2, btnH - 2)
                love.graphics.setColor(r, g, b, 0.7)
                love.graphics.setLineWidth(2 * s)
                love.graphics.rectangle('line', bx - 1, by - 1, btnW + 2, btnH + 2)
            end

            love.graphics.setFont(self.best_font)
            love.graphics.setColor(r, g, b, sel and pulse or 0.75)
            love.graphics.printf(btn.text, bx, by + btnH / 2 - 12 * s, btnW, "center")
        end

        love.graphics.setFont(self.instruction_font)
        love.graphics.setColor(0.3, 0.5, 0.7, 0.4)
        love.graphics.printf("ESC TO RESUME", 0, py + panelH - 24 * s, w, "center")
    end

    if self.white_fader.time < self.white_fader.duration then
        love.graphics.setColor(0, 0, 0, 1 * (1 - (self.white_fader.time / self.white_fader.duration)))
        love.graphics.rectangle('fill', 0, 0, w, h)
    end

    if DEBUG then
        love.graphics.setColor(0.5, 1.0, 0.5, 0.6)
        love.graphics.setFont(self.zone_font)
        love.graphics.printf(string.format("FPS: %d", love.timer.getFPS()), 4, h - 20 * s, 100, "left")
    end
end

function VoidRunnerPlayState:touchpressed(id, x, y, dx, dy, pressure)
    GameState.touchpressed(self, id, x, y, dx, dy, pressure)

    if self.paused then
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        local s = self.scale
        local btnW = 220 * s
        local btnH = 46 * s
        local btnGap = 14 * s
        local cx = w / 2
        local py = h / 2 - 120 * s
        local startY = py + 80 * s
        local bx = cx - btnW / 2
        for i, btn in ipairs(self.paused_buttons) do
            local by = startY + (i - 1) * (btnH + btnGap)
            if x > bx and x < bx + btnW and y > by and y < by + btnH then
                self.paused_selected = i
                btn.action()
                return
            end
        end
        return
    end

    for _, button in ipairs(self.buttons) do
        if button:containsPoint(x, y) then
            self.ignore_touch[id] = true
            button.action()
            break
        end
    end

    if y < VoidRunnerPlayState.VMARGIN or y > love.graphics.getHeight() - VoidRunnerPlayState.VMARGIN then
        self.ignore_touch[id] = true
    end

    if not self.ignore_touch[id] and self.player and not self.player:isDead() then
        local activeCount = 0
        for _ in pairs(self.active_touches) do activeCount = activeCount + 1 end
        if activeCount >= 1 and MOBILE then
            self:activateTimeWarp()
        else
            local wx, wy = self.cam:worldCoords(x, y)
            self.player.mouseTarget = vector(wx, wy)
        end
    end
    self.active_touches[id] = true
end

function VoidRunnerPlayState:touchreleased(id, x, y, dx, dy, pressure)
    self.ignore_touch[id] = false
    self.active_touches[id] = nil
end

function VoidRunnerPlayState:mousepressed(x, y, button, istouch)
    if istouch then return end
    if button == 2 then
        self:activateTimeWarp()
    elseif button == 1 then
        -- manual laser fire when playing and not paused
        if not self.paused and self.player and not self.player:isDead() then
            self.player:manualFire()
        end
        -- route left click through to touchpressed so pause menu clicks & mouse targeting work
        GameState.mousepressed(self, x, y, button, istouch)
    end
end

local Initial = VoidRunnerPlayState:addState('Initial')

function Initial:enteredState()
    if PLAY_RECORDING then
        Timer.after(1, function() self:startGame() end)
    end
end

function Initial:overlay()
    VoidRunnerPlayState.overlay(self)

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local s = self.scale

    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle('fill', 0, 0, w, h)

    local prompt = "TOUCH TO START"
    if not MOBILE then prompt = "SPACE TO START" end
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(self.instruction_font)
    love.graphics.printf(prompt, 0, h / 2 + 25 * s, w, "center")

    if not MOBILE then
        love.graphics.setColor(0.3, 0.7, 1.0, 0.45)
        love.graphics.printf("WASD TO DASH  |  MOUSE TO MOVE  |  RIGHT CLICK WARP", 0, h / 2 + 48 * s, w, "center")
    end

    love.graphics.setColor(0.3, 0.7, 1.0, 0.6)
    love.graphics.circle('fill', w / 2, h / 2 + 80 * s, s * 10 * (1 + 0.2 * (math.sin(self.time))^2), 32)

    if self.bestscore ~= nil then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.setFont(self.best_font)
        love.graphics.printf(string.format("BEST: %05dm", math.floor(self.bestscore)), 0, h / 2 - 60 * s, w, "center")
    end
end

function Initial:update(dt)
    GameState.update(self, dt)
    self:updateButtons(dt)
end

function Initial:touchpressed(id, x, y, dx, dy, pressure)
    VoidRunnerPlayState.touchpressed(self, id, x, y, dx, dy, pressure)
    if self.ignore_touch[id] then return end
    self:startGame()
end

function Initial:touchmoved(id, x, y, dx, dy, pressure)
end

function Initial:mousepressed(x, y, button, istouch)
    if istouch or button ~= 1 then return end
    self:startGame()
end

function Initial:keypressed(key, scancode, isrepeat)
    if key == 'escape' then
        GameState.switchTo(VoidRunnerMainMenu())
        return
    end
    if key == "space" or key == "return" then
        self:startGame()
    end
end

function Initial:gamepadpressed(joystick, button)
    if button == 'a' or button == 'start' then
        self:startGame()
    elseif button == 'b' or button == 'back' then
        GameState.switchTo(VoidRunnerMainMenu())
    end
end

local Playing = VoidRunnerPlayState:addState('Playing')

function Playing:enteredState()
    self.audioManager:playEngineHum()
end

function Playing:update(dt)
    if not self.paused and self.player and not self.player:isDead() then
        if not MOBILE then
            local mx, my = love.mouse.getPosition()
            local wx, wy = self.cam:worldCoords(mx, my)
            self.player.mouseTarget = vector(wx, wy)
        end

        -- gamepad analog stick movement
        local joysticks = love.joystick.getJoysticks()
        if #joysticks > 0 then
            local js = joysticks[1]
            if js:isGamepad() then
                local lx = js:getGamepadAxis('leftx')
                local ly = js:getGamepadAxis('lefty')
                local deadzone = 0.2
                if math.abs(lx) > deadzone or math.abs(ly) > deadzone then
                    local wx2, wy2 = self.cam:worldCoords(
                        love.graphics.getWidth() / 2 + lx * love.graphics.getWidth() * 0.4,
                        love.graphics.getHeight() / 2 + ly * love.graphics.getHeight() * 0.4
                    )
                    self.player.mouseTarget = vector(wx2, wy2)
                end

                -- right stick flick for dash
                local rx = js:getGamepadAxis('rightx')
                local ry = js:getGamepadAxis('righty')
                if math.abs(rx) > 0.7 or math.abs(ry) > 0.7 then
                    local dx = math.abs(rx) > 0.7 and (rx > 0 and 1 or -1) or 0
                    local dy = math.abs(ry) > 0.7 and (ry > 0 and 1 or -1) or 0
                    self.player:dash(dx, dy)
                end
            end
        end
    end

    VoidRunnerPlayState.update(self, dt)
end

function Playing:keypressed(key, scancode, isrepeat)
    VoidRunnerPlayState.keypressed(self, key, scancode, isrepeat)

    if self.paused then return end
    if not self.player or self.player:isDead() then return end

    if key == 'left' or key == 'a' then
        self.player:dash(-1, 0)
    elseif key == 'right' or key == 'd' then
        self.player:dash(1, 0)
    elseif key == 'up' or key == 'w' then
        self.player:dash(0, -1)
    elseif key == 'down' or key == 's' then
        self.player:dash(0, 1)
    elseif key == 'space' then
        self.player:manualFire()
    end
end

local Dead = VoidRunnerPlayState:addState('Dead')

function Dead:enteredState()
    self.dead_time = 0

    if ANDROID or IOS then
        love.system.unlockAchievement(IDS.ACH_PLAY_A_GAME)
        love.system.submitScore(IDS.LEAD_SURVIVAL_TIME, math.floor(self.depth))
    end

    self.audioManager:stopAll()

    if self.newrecord then
        love.filesystem.write("bestscore", tostring(self.depth))
        self.bestscore = self.depth
    end

    if PLAY_RECORDING then
        Timer.after(3, function() love.event.quit(0) end)
    end

    love.mouse.setVisible(true)
    love.mouse.setGrabbed(false)
    self:showButtons()
end

function Dead:update(dt)
    GameState.update(self, dt)
    self.time = self.time + dt
    self.dead_time = self.dead_time + dt
    self.newrecord_visible = (self.time % 1) < 0.5
    self.white_fader.time = self.white_fader.time + dt
    self:updateButtons(dt)
end

function Dead:overlay()
    VoidRunnerPlayState.overlay(self)

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local s = self.scale
    local cx, cy = w / 2, h / 2

    local fadeAlpha = math.min(0.55, self.dead_time / 0.3 * 0.55)
    local uiAlpha = math.min(1, math.max(0, (self.dead_time - 0.25) / 0.75))
    love.graphics.setColor(0, 0, 0, fadeAlpha)
    love.graphics.rectangle('fill', 0, 0, w, h)

    local bestR, bestG, bestB = 0.2, 0.35, 0.5
    if self.newrecord then bestR, bestG, bestB = 1.0, 0.75, 0.1 end
    love.graphics.setColor(bestR, bestG, bestB, 0.85 * uiAlpha)
    love.graphics.setFont(self.best_font)
    love.graphics.printf(string.format("BEST: %05dm", math.floor(self.bestscore or self.depth)), 0, cy - 70 * s, w, "center")

    love.graphics.setFont(self.instruction_font)
    love.graphics.setColor(1, 0.2, 0.3, 0.9 * uiAlpha)
    love.graphics.printf("SHIP DESTROYED", 0, cy - 45 * s, w, "center")

    love.graphics.setColor(1, 1, 1, 0.9 * uiAlpha)
    love.graphics.setFont(self.time_font)
    love.graphics.printf(string.format("DEPTH: %05dm", math.floor(self.depth)), 0, cy - 18 * s, w, "center")

    love.graphics.setColor(0.8, 0.9, 1.0, 0.8 * uiAlpha)
    love.graphics.setFont(self.zone_font)
    love.graphics.printf(string.format("SCORE: %d", math.floor(self.score)), 0, cy + 2 * s, w, "center")

    local zoneName = self.zoneManager:getZoneName(self.currentZone)
    love.graphics.setColor(0.5, 0.7, 1.0, 0.7 * uiAlpha)
    love.graphics.setFont(self.zone_font)
    love.graphics.printf(string.format("ZONE %d / %s", self.currentZone, zoneName), 0, cy + 20 * s, w, "center")

    local flavor = self.zoneManager:getFlavorText(self.currentZone)
    love.graphics.setColor(0.7, 0.7, 0.8, 0.6 * uiAlpha)
    love.graphics.setFont(self.instruction_font)
    love.graphics.printf(flavor, 0, cy + 40 * s, w, "center")

    local pulse = math.sin(self.dead_time * 3) * 0.12 + 0.88
    local btnW = 260 * s
    local btnH = 50 * s
    local bx = cx - btnW / 2
    local by = cy + 70 * s

    love.graphics.setColor(0.05, 0.05, 0.12, 0.9 * uiAlpha)
    love.graphics.rectangle('fill', bx, by, btnW, btnH)
    love.graphics.setColor(0.15, 0.5, 0.8, 0.6 * uiAlpha)
    love.graphics.setLineWidth(2 * s)
    love.graphics.rectangle('line', bx, by, btnW, btnH)

    love.graphics.setColor(0.3, 0.7, 1.0, pulse * uiAlpha)
    love.graphics.setFont(self.best_font)
    local retryPrompt = MOBILE and "TAP TO RETRY" or "CLICK TO RETRY"
    love.graphics.printf(retryPrompt, bx, by + btnH / 2 - 14 * s, btnW, "center")

    if self.newrecord and self.newrecord_visible then
        love.graphics.setColor(1, 0.85, 0.1, 0.9 * uiAlpha)
        love.graphics.setFont(self.new_record_font)
        love.graphics.printf("NEW RECORD", 0, cy - 90 * s, w, "center")
    end

    love.graphics.setFont(self.instruction_font)
    love.graphics.setColor(0.3, 0.5, 0.7, 0.4 * uiAlpha)
    love.graphics.printf("ESC FOR MENU", 0, h - 15 * s, w, "center")
end

function Dead:mousepressed(x, y, button, istouch)
    if istouch or button ~= 1 then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local s = self.scale
    local cx, cy = w / 2, h / 2
    local btnW = 260 * s
    local btnH = 50 * s
    local bx = cx - btnW / 2
    local by = cy + 70 * s
    if x >= bx and x <= bx + btnW and y >= by and y <= by + btnH then
        self:startGame()
    end
end

function Dead:touchpressed(id, x, y, dx, dy, pressure)
    VoidRunnerPlayState.touchpressed(self, id, x, y, dx, dy, pressure)
    if self.ignore_touch[id] then return end
    self:startGame()
end

function Dead:keypressed(key, scancode, isrepeat)
    if key == 'escape' then
        GameState.switchTo(VoidRunnerMainMenu())
        return
    end
    if key == "space" or key == "return" then
        self:startGame()
    end
end

function Dead:gamepadpressed(joystick, button)
    if button == 'a' or button == 'start' then
        self:startGame()
    elseif button == 'b' or button == 'back' then
        GameState.switchTo(VoidRunnerMainMenu())
    end
end

return VoidRunnerPlayState
