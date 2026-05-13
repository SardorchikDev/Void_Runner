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
        end
    elseif self.phase == 2 and hpRatio <= 0.25 then
        self.phase = 3
        self.phaseTimer = 0
        if self.gameState then
            self.gameState.screenEffects:flash(1, 0.2, 0.2, 0.4, 0.3)
            self.gameState.screenEffects:chromaticAberration(0.8, 2.0)
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

    local hpRatio = math.max(0, self.health / self.maxHealth)
    local r = lume.lerp(1.0, self.cr, hpRatio)
    local g = lume.lerp(0.1, self.cg, hpRatio)
    local b = lume.lerp(0.1, self.cb, hpRatio)
    love.graphics.setColor(r, g, b, 0.9)
    love.graphics.rectangle('fill', barX, barY, barW * hpRatio, barH)

    love.graphics.setColor(0.5, 0.6, 0.7, 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle('line', barX, barY, barW, barH)

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

    -- glow
    love.graphics.setColor(r * 0.15, g * 0.15, b * 0.15, 0.3)
    love.graphics.circle('fill', 0, 0, Boss.WIDTH * 1.5)

    -- main body: angular hull
    love.graphics.setColor(r * 0.6, g * 0.6, b * 0.6, 0.9)
    local hw = Boss.WIDTH * 0.5
    local hh = Boss.HEIGHT * 0.5
    love.graphics.polygon('fill',
        0, -hh * 1.2,
        hw * 1.1, -hh * 0.3,
        hw * 0.9, hh * 0.6,
        hw * 0.3, hh,
        -hw * 0.3, hh,
        -hw * 0.9, hh * 0.6,
        -hw * 1.1, -hh * 0.3
    )

    -- inner detail
    love.graphics.setColor(r, g, b, 0.7)
    love.graphics.polygon('line',
        0, -hh * 0.8,
        hw * 0.7, -hh * 0.1,
        hw * 0.5, hh * 0.4,
        -hw * 0.5, hh * 0.4,
        -hw * 0.7, -hh * 0.1
    )

    -- eye/core
    local eyePulse = math.sin(self.time * 6) * 0.15 + 0.85
    love.graphics.setColor(r, g, b, eyePulse)
    love.graphics.circle('fill', 0, -hh * 0.1, 8 * eyePulse)
    love.graphics.setColor(1, 1, 1, eyePulse * 0.6)
    love.graphics.circle('fill', 0, -hh * 0.1, 4)

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
            -- aimed shots
            self:fireAtPlayer(0)
            self:fireAtPlayer(0.15)
            self:fireAtPlayer(-0.15)
            self.fireTimer = 1.8 - self.zoneNum * 0.15
        elseif self.phase == 2 then
            -- spiral + aimed
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
            -- rapid spiral + aimed barrage
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
