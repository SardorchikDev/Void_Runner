-- Large Zone 4+ enemy ship that fires red spread volleys.
EnemyDreadnought = class('EnemyDreadnought', Entity)
EnemyDreadnought:include(Stateful)

EnemyDreadnought.static.WIDTH = 40
EnemyDreadnought.static.HEIGHT = 35
EnemyDreadnought.static.FIRE_INTERVAL = 2.0
EnemyDreadnought.static.INTRO_TIME = 1.5
EnemyDreadnought.static.HOVER_Y_OFFSET = -80
EnemyDreadnought.static.BULLET_SPEED = 140
EnemyDreadnought.static.HEALTH = 5

function EnemyDreadnought:initialize(duration, side)
    Entity.initialize(self, 'enemy', 0, vector(0, 0))
    self.duration = duration or 12
    self.fireTimer = EnemyDreadnought.FIRE_INTERVAL * 0.5
    self.targetY = 0
    self.health = EnemyDreadnought.HEALTH
    self.radius = EnemyDreadnought.WIDTH
    self.entrySide = side or lume.randomchoice({'center', 'left', 'right'})
    self.smokeParticles = {}
    self:gotoState('Entering')
end

function EnemyDreadnought:takeDamage(amount)
    self.health = self.health - (amount or 1)
    if self.health <= 0 then
        if self.gameState then
            self.gameState:addEntity(Explosion(self.pos:clone(), 50, {
                core = {1.0, 0.8, 0.3}, mid = {1.0, 0.3, 0.1}, outer = {0.6, 0.1, 0.05}
            }))
            self.gameState:onEnemyKilled('dreadnought', self.pos:clone())
        end
        self:destroy()
    end
end

function EnemyDreadnought:update(dt)
    Entity.update(self, dt)

    -- damage smoke particles
    if self.health <= EnemyDreadnought.HEALTH / 2 then
        for i = 1, 2 do
            table.insert(self.smokeParticles, {
                x = lume.random(-EnemyDreadnought.WIDTH * 0.5, EnemyDreadnought.WIDTH * 0.5),
                y = lume.random(-EnemyDreadnought.HEIGHT * 0.3, EnemyDreadnought.HEIGHT * 0.3),
                size = lume.random(2, 4),
                life = lume.random(0.3, 0.6),
                maxLife = 0.6,
                vy = lume.random(-20, -40),
            })
        end
    end
    for i = #self.smokeParticles, 1, -1 do
        local p = self.smokeParticles[i]
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.smokeParticles, i)
        end
    end

    if self.time > self.duration then
        self:destroy()
    end
end

function EnemyDreadnought:getPlayerPos()
    local player = self.gameState:getEntityByTag('player')
    if player then
        local travelTime = (player.pos - self.pos):len() / EnemyDreadnought.BULLET_SPEED
        return player.pos:clone() + (player.velocity or vector(0, 0)) * math.min(0.9, travelTime)
    end
    return vector(0, 0)
end

function EnemyDreadnought:draw()
    local W = EnemyDreadnought.WIDTH
    local H = EnemyDreadnought.HEIGHT
    local t = self.time or 0

    love.graphics.push()
    love.graphics.translate(self.pos:unpack())

    -- central spine
    love.graphics.setColor(0.12, 0.06, 0.06, 0.8)
    love.graphics.polygon('fill', -W * 0.15, -H * 0.55, W * 0.15, -H * 0.55, W * 0.15, H * 0.55, -W * 0.15, H * 0.55)

    -- port/starboard weapon pods
    love.graphics.setColor(0.15, 0.08, 0.08, 0.7)
    love.graphics.polygon('fill', -W * 0.55, -H * 0.2, -W * 0.3, -H * 0.2, -W * 0.3, H * 0.4, -W * 0.55, H * 0.4)
    love.graphics.polygon('fill', W * 0.3, -H * 0.2, W * 0.55, -H * 0.2, W * 0.55, H * 0.4, W * 0.3, H * 0.4)

    -- bridge superstructure (trapezoid at top)
    love.graphics.setColor(0.18, 0.1, 0.1, 0.9)
    love.graphics.polygon('fill', -W * 0.1, -H * 0.55, W * 0.1, -H * 0.55, W * 0.2, -H * 0.35, -W * 0.2, -H * 0.35)

    -- hangar bay (dark rectangle at bottom)
    love.graphics.setColor(0.04, 0.02, 0.02, 0.8)
    love.graphics.polygon('fill', -W * 0.12, H * 0.35, W * 0.12, H * 0.35, W * 0.12, H * 0.55, -W * 0.12, H * 0.55)

    -- sensor array (3 circles at top of bridge)
    love.graphics.setColor(0.8, 0.3, 0.2, 0.6)
    love.graphics.circle('fill', -W * 0.08, -H * 0.5, 2)
    love.graphics.circle('fill', 0, -H * 0.55, 2.5)
    love.graphics.circle('fill', W * 0.08, -H * 0.5, 2)

    -- hull plating lines
    love.graphics.setColor(0.06, 0.03, 0.03, 0.5)
    love.graphics.setLineWidth(0.5)
    for i = 1, 7 do
        local y = -H * 0.4 + (i / 8) * H * 0.8
        love.graphics.line(-W * 0.5, y, W * 0.5, y)
    end

    -- edge outlines
    love.graphics.setColor(1.0, 0.2, 0.2, 0.9)
    love.graphics.setLineWidth(1)
    love.graphics.polygon('line', -W * 0.15, -H * 0.55, W * 0.15, -H * 0.55, W * 0.15, H * 0.55, -W * 0.15, H * 0.55)
    love.graphics.polygon('line', -W * 0.55, -H * 0.2, -W * 0.3, -H * 0.2, -W * 0.3, H * 0.4, -W * 0.55, H * 0.4)
    love.graphics.polygon('line', W * 0.3, -H * 0.2, W * 0.55, -H * 0.2, W * 0.55, H * 0.4, W * 0.3, H * 0.4)

    -- heat vents (pulsing orange circles)
    local ventPositions = {
        {x = -W * 0.42, y = H * 0.0, offset = 0},
        {x = -W * 0.42, y = H * 0.2, offset = 1.2},
        {x = W * 0.42, y = H * 0.0, offset = 2.4},
        {x = W * 0.42, y = H * 0.2, offset = 3.6},
        {x = -W * 0.42, y = -H * 0.1, offset = 4.8},
        {x = W * 0.42, y = -H * 0.1, offset = 0.6},
    }
    for _, v in ipairs(ventPositions) do
        local pulse = math.sin(t * 4 + v.offset) * 0.3 + 0.7
        love.graphics.setColor(1.0, 0.4, 0.1, 0.4 * pulse)
        love.graphics.circle('fill', v.x, v.y, 2.5 * pulse)
    end

    -- navigation lights (blinking red/green at wingtips)
    local redBlink = math.sin(t * (math.pi * 2 / 0.8)) > 0 and 0.8 or 0.1
    local greenBlink = math.sin(t * (math.pi * 2 / 1.1)) > 0 and 0.8 or 0.1
    love.graphics.setColor(1.0, 0.1, 0.1, redBlink)
    love.graphics.circle('fill', -W * 0.55, -H * 0.2, 2)
    love.graphics.setColor(0.1, 1.0, 0.2, greenBlink)
    love.graphics.circle('fill', W * 0.55, -H * 0.2, 2)

    -- cockpit
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle('fill', 0, -H * 0.45, 2)

    -- engines
    love.graphics.setBlendMode('add')
    love.graphics.setColor(1.0, 0.3, 0.1, 0.5)
    love.graphics.circle('fill', -W * 0.3, H * 0.45, 3)
    love.graphics.circle('fill', W * 0.3, H * 0.45, 3)
    love.graphics.circle('fill', 0, H * 0.55, 2.5)
    love.graphics.setBlendMode('alpha')

    -- damage smoke
    for _, p in ipairs(self.smokeParticles) do
        local a = math.max(0, p.life / p.maxLife) * 0.4
        love.graphics.setColor(0.3, 0.3, 0.3, a)
        love.graphics.circle('fill', p.x, p.y, p.size)
    end

    love.graphics.pop()
end

local Entering = EnemyDreadnought:addState('Entering')
function Entering:update(dt)
    EnemyDreadnought.update(self, dt)
    local camL, camT = self.gameState.cam:worldCoords(0, 0)
    local camR, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
    local camCY = (camT + camB) / 2
    self.targetY = camCY + EnemyDreadnought.HOVER_Y_OFFSET

    local t = self.time / EnemyDreadnought.INTRO_TIME
    local targetX = (camL + camR) / 2
    if self.entrySide == 'left' then
        targetX = camL + (camR - camL) * 0.3
    elseif self.entrySide == 'right' then
        targetX = camL + (camR - camL) * 0.7
    end
    self.pos.x = targetX
    self.pos.y = lume.lerp(camT - 60, self.targetY, math.min(1, Timer.tween.out(Timer.tween.cubic)(t)))

    if self.time > EnemyDreadnought.INTRO_TIME then
        self:gotoState('Hovering')
    end
end

local Hovering = EnemyDreadnought:addState('Hovering')
function Hovering:update(dt)
    EnemyDreadnought.update(self, dt)
    local camL, camT = self.gameState.cam:worldCoords(0, 0)
    local camR, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
    local camCY = (camT + camB) / 2
    local targetX = (camL + camR) / 2
    if self.entrySide == 'left' then
        targetX = camL + (camR - camL) * 0.3
    elseif self.entrySide == 'right' then
        targetX = camL + (camR - camL) * 0.7
    end
    self.pos.x = targetX + math.sin(self.time * 0.8) * 30
    self.targetY = camCY + EnemyDreadnought.HOVER_Y_OFFSET
    self.pos.y = self.targetY + math.sin(self.time * 1.5) * 5

    self.fireTimer = self.fireTimer + dt
    if self.fireTimer > EnemyDreadnought.FIRE_INTERVAL then
        self.fireTimer = 0
        local playerPos = self:getPlayerPos()
        local baseDir = (playerPos - self.pos):normalized()
        if baseDir:len() == 0 then baseDir = vector(0, 1) end
        local atan2 = math.atan2 or math.atan
        local baseAngle = atan2(baseDir.y, baseDir.x)
        local angles = {-0.5, -0.25, 0, 0.25, 0.5}
        for _, a in ipairs(angles) do
            local angle = baseAngle + a
            local dir = vector(math.cos(angle), math.sin(angle))
            local proj = Projectile(self.pos:clone(), dir * EnemyDreadnought.BULLET_SPEED, Color.RED, 4.5)
            self.gameState:addEntity(proj)
        end
    end

    if self.time > self.duration - 1.0 then
        self:gotoState('Leaving')
    end
end

local Leaving = EnemyDreadnought:addState('Leaving')
function Leaving:update(dt)
    EnemyDreadnought.update(self, dt)
    local _, camT = self.gameState.cam:worldCoords(0, 0)
    local t = (self.time - (self.duration - 1.0)) / 1.0
    self.pos.y = lume.lerp(self.targetY, camT - 80, math.min(1, Timer.tween.cubic(t)))
    if t >= 1 then
        self:destroy()
    end
end

return EnemyDreadnought
