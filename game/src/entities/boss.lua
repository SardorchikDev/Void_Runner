-- Boss entity with multi-phase attack patterns, spawns at zone transitions.
Boss = class('Boss', Entity)
Boss:include(Stateful)

Boss.static.WIDTH = 70
Boss.static.HEIGHT = 55
Boss.static.BASE_HEALTH = 30
Boss.static.BULLET_SPEED = 160

function Boss:initialize(zoneNum)
    Entity.initialize(self, 'boss', 0, vector(0, 0))
    self.zoneNum = zoneNum or 3
    self.maxHealth = Boss.BASE_HEALTH + (zoneNum - 2) * 15
    self.health = self.maxHealth
    self.displayHP = self.health
    self.radius = Boss.WIDTH
    self.fireTimer = 0
    self.phase = 1
    self.phaseTimer = 0
    self.orbitAngle = 0
    self.targetY = 0
    self.flashTimer = 0
    self.defeated = false
    self.deathTimer = 0
    self.shieldActive = false
    self.shieldTimer = 0
    self.warningShown = false
    self.spinAngle = 0
    self.burstCount = 0

    self.colors = {
        [3] = {r = 1.0, g = 0.3, b = 0.1},
        [4] = {r = 0.2, g = 1.0, b = 0.3},
        [5] = {r = 0.8, g = 0.2, b = 1.0},
    }
    local c = self.colors[zoneNum] or {r = 1.0, g = 0.3, b = 0.1}
    self.cr, self.cg, self.cb = c.r, c.g, c.b

    self:gotoState('Entering')
end

function Boss:takeDamage(amount)
    if self.defeated then return end
    if self.shieldActive then
        self.flashTimer = 0.1
        return
    end
    self.health = self.health - (amount or 1)
    self.flashTimer = 0.15
    if self.gameState then
        self.gameState.screenEffects:shake(4, 0.1)
    end

    local hpRatio = self.health / self.maxHealth
    if self.phase == 1 and hpRatio <= 0.6 then
        self.phase = 2
        self.phaseTimer = 0
        self.shieldActive = true
        self.shieldTimer = 2.0
        if self.gameState then
            self.gameState.screenEffects:flash(self.cr, self.cg, self.cb, 0.3, 0.3)
            if self.gameState.audioManager and self.gameState.audioManager.playBossPhaseShift then
                self.gameState.audioManager:playBossPhaseShift()
            end
        end
    elseif self.phase == 2 and hpRatio <= 0.25 then
        self.phase = 3
        self.phaseTimer = 0
        if self.gameState then
            self.gameState.screenEffects:flash(1, 0.2, 0.2, 0.4, 0.3)
            self.gameState.screenEffects:chromaticAberration(0.8, 2.0)
            if self.gameState.audioManager and self.gameState.audioManager.playBossPhaseShift then
                self.gameState.audioManager:playBossPhaseShift()
            end
        end
    end

    if self.health <= 0 then
        self.defeated = true
        self.deathTimer = 2.0
        if self.gameState then
            self.gameState:onBossDefeated(self.zoneNum)
        end
    end
end

function Boss:getPlayerPos()
    if not self.gameState then return vector(0, 0) end
    local player = self.gameState:getEntityByTag('player')
    if player then return player.pos:clone() end
    return vector(0, 0)
end

function Boss:fireBullet(angle, speed)
    if not self.gameState then return end
    speed = speed or Boss.BULLET_SPEED
    local vel = vector(math.cos(angle) * speed, math.sin(angle) * speed)
    self.gameState:addEntity(Projectile(self.pos:clone(), vel))
end

function Boss:fireAtPlayer(spread)
    spread = spread or 0
    local playerPos = self:getPlayerPos()
    local dir = playerPos - self.pos
    local angle = math.atan2(dir.y, dir.x)
    self:fireBullet(angle + spread)
end

function Boss:fireSpiral(count, offset)
    for i = 1, count do
        local angle = offset + (i / count) * math.pi * 2
        self:fireBullet(angle, Boss.BULLET_SPEED * 0.8)
    end
end

function Boss:update(dt)
    Entity.update(self, dt)
    self.flashTimer = math.max(0, self.flashTimer - dt)
    self.phaseTimer = self.phaseTimer + dt
    self.spinAngle = self.spinAngle + dt * (1 + self.phase * 0.5)

    -- lerp displayHP toward real HP
    self.displayHP = lume.lerp(self.displayHP, self.health, math.min(1, dt / 0.3))

    if self.shieldActive then
        self.shieldTimer = self.shieldTimer - dt
        if self.shieldTimer <= 0 then
            self.shieldActive = false
        end
    end

    if self.defeated then
        self.deathTimer = self.deathTimer - dt
        if math.random() < 0.3 then
            if self.gameState then
                local offset = vector(lume.random(-40, 40), lume.random(-30, 30))
                self.gameState:addEntity(Explosion(self.pos + offset, 15, {
                    core = {1, 1, 0.8}, mid = {self.cr, self.cg, self.cb}, outer = {0.5, 0.1, 0.05}
                }))
            end
        end
        if self.deathTimer <= 0 then
            if self.gameState then
                self.gameState:addEntity(Explosion(self.pos:clone(), 80, {
                    core = {1, 1, 0.9}, mid = {self.cr, self.cg, self.cb}, outer = {0.3, 0.05, 0.02}
                }))
                self.gameState.screenEffects:shake(40, 0.6)
                self.gameState.screenEffects:flash(1, 1, 1, 0.5, 0.4)
                self.gameState.screenEffects:slowMotion(0.2, 0.5)
            end
            self:destroy()
        end
        return
    end
end

function Boss:drawHealthBar()
    if self.defeated then return end
    local w = love.graphics.getWidth()
    local s = self.gameState and self.gameState.scale or 1
    local barW = 200 * s
    local barH = 6 * s
    local barX = w / 2 - barW / 2
    local barY = 55 * s

    love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
    love.graphics.rectangle('fill', barX - 2, barY - 2, barW + 4, barH + 4)

    -- animated HP fill (lerps to real value)
    local hpRatio = math.max(0, self.displayHP / self.maxHealth)
    local r = lume.lerp(1.0, self.cr, hpRatio)
    local g = lume.lerp(0.1, self.cg, hpRatio)
    local b = lume.lerp(0.1, self.cb, hpRatio)
    love.graphics.setColor(r, g, b, 0.9)
    love.graphics.rectangle('fill', barX, barY, barW * hpRatio, barH)

    -- scanline effect when HP < 30%
    local realHPRatio = math.max(0, self.health / self.maxHealth)
    if realHPRatio < 0.3 then
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.setLineWidth(0.5)
        for y = barY, barY + barH, 3 do
            love.graphics.line(barX, y, barX + barW * hpRatio, y)
        end
    end

    love.graphics.setColor(0.5, 0.6, 0.7, 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle('line', barX, barY, barW, barH)

    -- zone-appropriate icon left of bar
    local iconX = barX - 16 * s
    local iconY = barY + barH / 2
    love.graphics.setColor(self.cr, self.cg, self.cb, 0.8)
    if self.zoneNum == 3 then
        -- sword icon
        love.graphics.setLineWidth(1.5)
        love.graphics.line(iconX, iconY - 6 * s, iconX, iconY + 6 * s)
        love.graphics.line(iconX - 3 * s, iconY - 2 * s, iconX + 3 * s, iconY - 2 * s)
    elseif self.zoneNum == 4 then
        -- lightning bolt
        love.graphics.polygon('fill', iconX - 2 * s, iconY - 6 * s, iconX + 1 * s, iconY - 1 * s, iconX - 1 * s, iconY - 1 * s, iconX + 2 * s, iconY + 6 * s, iconX - 1 * s, iconY + 1 * s, iconX + 1 * s, iconY + 1 * s)
    elseif self.zoneNum == 5 then
        -- eye shape
        love.graphics.ellipse('line', iconX, iconY, 5 * s, 3 * s)
        love.graphics.circle('fill', iconX, iconY, 1.5 * s)
    end

    local font = self.gameState and self.gameState.zone_font
    if font then
        love.graphics.setFont(font)
        love.graphics.setColor(self.cr, self.cg, self.cb, 0.8)
        local bossName = ({[3] = "WARDEN", [4] = "STORM KING", [5] = "VOID LORD"})[self.zoneNum] or "BOSS"
        love.graphics.printf(bossName, barX, barY - 14 * s, barW, "center")
    end
end

function Boss:draw()
    local flash = self.flashTimer > 0 and 1 or 0
    local r = self.cr + flash * 0.5
    local g = self.cg + flash * 0.5
    local b = self.cb + flash * 0.5

    love.graphics.push()
    love.graphics.translate(self.pos:unpack())

    if self.defeated then
        local shake = self.deathTimer * 3
        love.graphics.translate(lume.random(-shake, shake), lume.random(-shake, shake))
    end

    local hw = Boss.WIDTH * 0.5
    local hh = Boss.HEIGHT * 0.5

    if self.zoneNum == 3 then
        -- WARDEN: wide squat industrial hull
        love.graphics.setColor(r * 0.15, g * 0.15, b * 0.15, 0.3)
        love.graphics.circle('fill', 0, 0, Boss.WIDTH * 1.5)

        local wardenHull = {
            -hw * 1.2, -hh * 0.4,
            -hw * 0.8, -hh * 0.8,
            -hw * 0.3, -hh * 0.9,
            hw * 0.3, -hh * 0.9,
            hw * 0.8, -hh * 0.8,
            hw * 1.2, -hh * 0.4,
            hw * 1.1, hh * 0.5,
            hw * 0.5, hh * 0.8,
            -hw * 0.5, hh * 0.8,
            -hw * 1.1, hh * 0.5,
        }
        love.graphics.setColor(r * 0.5, g * 0.5, b * 0.5, 0.9)
        love.graphics.polygon('fill', wardenHull)
        love.graphics.setColor(r, g, b, 0.7)
        love.graphics.setLineWidth(1.5)
        love.graphics.polygon('line', wardenHull)

        -- riveted panel lines
        love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, 0.4)
        love.graphics.setLineWidth(0.5)
        love.graphics.line(-hw * 0.8, -hh * 0.3, hw * 0.8, -hh * 0.3)
        love.graphics.line(-hw * 0.9, hh * 0.1, hw * 0.9, hh * 0.1)
        love.graphics.line(-hw * 0.7, hh * 0.5, hw * 0.7, hh * 0.5)

        -- glowing reactor core
        local corePulse = math.sin(self.time * 5) * 0.2 + 0.8
        love.graphics.setBlendMode('add')
        love.graphics.setColor(1.0, 0.5, 0.1, 0.3 * corePulse)
        love.graphics.circle('fill', 0, 0, 12)
        love.graphics.setColor(1.0, 0.7, 0.3, 0.6 * corePulse)
        love.graphics.circle('fill', 0, 0, 6)
        love.graphics.setBlendMode('alpha')

        -- rotating outer ring of 8 bolts
        for i = 1, 8 do
            local a = self.spinAngle + (i - 1) * (math.pi * 2 / 8)
            local ox = math.cos(a) * hw * 0.75
            local oy = math.sin(a) * hh * 0.75
            love.graphics.setColor(r, g, b, 0.6)
            love.graphics.circle('fill', ox, oy, 3)
        end

    elseif self.zoneNum == 4 then
        -- STORM KING: elongated vertical diamond with fins
        love.graphics.setColor(r * 0.15, g * 0.15, b * 0.15, 0.3)
        love.graphics.circle('fill', 0, 0, Boss.WIDTH * 1.5)

        local diamondHull = {
            0, -hh * 1.4,
            hw * 0.5, -hh * 0.5,
            hw * 0.6, 0,
            hw * 0.5, hh * 0.5,
            0, hh * 1.4,
            -hw * 0.5, hh * 0.5,
            -hw * 0.6, 0,
            -hw * 0.5, -hh * 0.5,
        }
        love.graphics.setColor(r * 0.5, g * 0.5, b * 0.5, 0.9)
        love.graphics.polygon('fill', diamondHull)
        love.graphics.setColor(r, g, b, 0.7)
        love.graphics.setLineWidth(1.5)
        love.graphics.polygon('line', diamondHull)

        -- horizontal fins
        love.graphics.setColor(r * 0.4, g * 0.4, b * 0.4, 0.7)
        love.graphics.polygon('fill', -hw * 1.3, -hh * 0.1, -hw * 0.6, -hh * 0.15, -hw * 0.6, hh * 0.15, -hw * 1.3, hh * 0.1)
        love.graphics.polygon('fill', hw * 0.6, -hh * 0.15, hw * 1.3, -hh * 0.1, hw * 1.3, hh * 0.1, hw * 0.6, hh * 0.15)

        -- lightning arcs between fins (3 jagged lines)
        love.graphics.setBlendMode('add')
        for arc = 1, 3 do
            love.graphics.setColor(r, g, b, 0.6)
            love.graphics.setLineWidth(1.5)
            local startX = -hw * 1.2
            local endX = hw * 1.2
            local segments = 6
            local lastX, lastY = startX, lume.random(-3, 3)
            for seg = 1, segments do
                local nx = startX + (endX - startX) * (seg / segments)
                local ny = lume.random(-6, 6)
                love.graphics.line(lastX, lastY, nx, ny)
                lastX, lastY = nx, ny
            end
        end
        love.graphics.setBlendMode('alpha')

        -- core
        local corePulse = math.sin(self.time * 6) * 0.15 + 0.85
        love.graphics.setColor(r, g, b, corePulse)
        love.graphics.circle('fill', 0, 0, 8 * corePulse)
        love.graphics.setColor(1, 1, 1, corePulse * 0.6)
        love.graphics.circle('fill', 0, 0, 4)

    elseif self.zoneNum == 5 then
        -- VOID LORD: central core + 8 tentacles
        love.graphics.setColor(r * 0.15, g * 0.15, b * 0.15, 0.3)
        love.graphics.circle('fill', 0, 0, Boss.WIDTH * 1.8)

        -- concentric expanding void circles (purple additive)
        love.graphics.setBlendMode('add')
        for ring = 1, 4 do
            local ringR = 20 + ring * 15 + math.sin(self.time * 2 + ring) * 5
            love.graphics.setColor(r * 0.3, g * 0.1, b * 0.3, 0.08 / ring)
            love.graphics.circle('line', 0, 0, ringR)
        end
        love.graphics.setBlendMode('alpha')

        -- 8 tentacles (bezier-approximated curves)
        for i = 1, 8 do
            local baseAngle = self.spinAngle + (i - 1) * (math.pi * 2 / 8)
            love.graphics.setColor(r * 0.6, g * 0.3, b * 0.6, 0.7)
            love.graphics.setLineWidth(2)
            local tentLen = hw * 1.2
            local lastX, lastY = 0, 0
            for seg = 1, 4 do
                local t = seg / 4
                local wave = math.sin(self.time * 3 + i + seg * 0.8) * 8 * t
                local nx = math.cos(baseAngle) * tentLen * t + math.cos(baseAngle + math.pi / 2) * wave
                local ny = math.sin(baseAngle) * tentLen * t + math.sin(baseAngle + math.pi / 2) * wave
                love.graphics.line(lastX, lastY, nx, ny)
                lastX, lastY = nx, ny
            end
        end

        -- pulsing core
        local corePulse = math.sin(self.time * (math.pi * 2 / 0.4)) * 0.2 + 0.8
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.circle('fill', 0, 0, 10 * corePulse)
        love.graphics.setColor(1, 1, 1, 0.5 * corePulse)
        love.graphics.circle('fill', 0, 0, 5 * corePulse)

    else
        -- fallback generic
        love.graphics.setColor(r * 0.15, g * 0.15, b * 0.15, 0.3)
        love.graphics.circle('fill', 0, 0, Boss.WIDTH * 1.5)

        love.graphics.setColor(r * 0.6, g * 0.6, b * 0.6, 0.9)
        love.graphics.polygon('fill',
            0, -hh * 1.2,
            hw * 1.1, -hh * 0.3,
            hw * 0.9, hh * 0.6,
            hw * 0.3, hh,
            -hw * 0.3, hh,
            -hw * 0.9, hh * 0.6,
            -hw * 1.1, -hh * 0.3
        )
        love.graphics.setColor(r, g, b, 0.7)
        love.graphics.polygon('line',
            0, -hh * 0.8,
            hw * 0.7, -hh * 0.1,
            hw * 0.5, hh * 0.4,
            -hw * 0.5, hh * 0.4,
            -hw * 0.7, -hh * 0.1
        )
        local eyePulse = math.sin(self.time * 6) * 0.15 + 0.85
        love.graphics.setColor(r, g, b, eyePulse)
        love.graphics.circle('fill', 0, -hh * 0.1, 8 * eyePulse)
        love.graphics.setColor(1, 1, 1, eyePulse * 0.6)
        love.graphics.circle('fill', 0, -hh * 0.1, 4)
    end

    -- phase indicators (spinning orbs)
    for i = 1, self.phase do
        local a = self.spinAngle + (i - 1) * (math.pi * 2 / self.phase)
        local ox = math.cos(a) * (hw + 15)
        local oy = math.sin(a) * (hh + 10)
        love.graphics.setColor(r, g, b, 0.6)
        love.graphics.circle('fill', ox, oy, 4)
    end

    -- shield
    if self.shieldActive then
        local sa = math.sin(self.time * 8) * 0.2 + 0.5
        love.graphics.setColor(0.3, 0.8, 1.0, sa)
        love.graphics.setLineWidth(2)
        love.graphics.circle('line', 0, 0, Boss.WIDTH * 0.9)
        love.graphics.setColor(0.3, 0.8, 1.0, sa * 0.2)
        love.graphics.circle('fill', 0, 0, Boss.WIDTH * 0.9)
    end

    love.graphics.pop()
end

-- === STATES ===

local Entering = Boss:addState('Entering')

function Entering:enteredState()
    local camL, camT
    if self.gameState then
        camL, camT = self.gameState.cam:worldCoords(0, 0)
        local _, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
        self.targetY = camT + (camB - camT) * 0.2
    else
        self.targetY = -200
    end
    self.pos = vector(0, self.targetY - 300)
end

function Entering:update(dt)
    Boss.update(self, dt)
    self.pos.y = lume.lerp(self.pos.y, self.targetY, 1.5 * dt)
    if math.abs(self.pos.y - self.targetY) < 5 then
        self:gotoState('Fighting')
    end
end

local Fighting = Boss:addState('Fighting')

function Fighting:enteredState()
    self.fireTimer = 1.5
    self.burstCount = 0
end

function Fighting:update(dt)
    Boss.update(self, dt)
    if self.defeated then return end

    self.fireTimer = self.fireTimer - dt

    -- stay relative to camera
    if self.gameState then
        local _, camT = self.gameState.cam:worldCoords(0, 0)
        local _, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
        self.targetY = camT + (camB - camT) * 0.18
        self.pos.y = lume.lerp(self.pos.y, self.targetY, 2.0 * dt)
    end

    -- orbit movement
    self.orbitAngle = self.orbitAngle + dt * (0.8 + self.phase * 0.3)
    local orbitRadius = 100 + self.phase * 20
    self.pos.x = math.sin(self.orbitAngle) * orbitRadius

    if self.fireTimer <= 0 then
        if self.phase == 1 then
            self:fireAtPlayer(0)
            self:fireAtPlayer(0.15)
            self:fireAtPlayer(-0.15)
            self.fireTimer = 1.8 - self.zoneNum * 0.15
        elseif self.phase == 2 then
            self.burstCount = self.burstCount + 1
            if self.burstCount % 3 == 0 then
                self:fireSpiral(8, self.spinAngle)
            else
                self:fireAtPlayer(0)
                self:fireAtPlayer(0.25)
                self:fireAtPlayer(-0.25)
                self:fireAtPlayer(0.5)
                self:fireAtPlayer(-0.5)
            end
            self.fireTimer = 1.2 - self.zoneNum * 0.1
        elseif self.phase == 3 then
            self:fireSpiral(12, self.spinAngle)
            self:fireAtPlayer(0)
            self:fireAtPlayer(0.1)
            self:fireAtPlayer(-0.1)
            self.fireTimer = 0.8 - self.zoneNum * 0.05
        end

        if self.gameState then
            self.gameState.audioManager:playLaser()
        end
    end
end

return Boss
