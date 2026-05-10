-- NEW: Large Zone 4+ enemy ship that fires red spread volleys.
EnemyDreadnought = class('EnemyDreadnought', Entity)
EnemyDreadnought:include(Stateful)

EnemyDreadnought.static.WIDTH = 40
EnemyDreadnought.static.HEIGHT = 35
EnemyDreadnought.static.FIRE_INTERVAL = 2.0
EnemyDreadnought.static.INTRO_TIME = 1.5
EnemyDreadnought.static.HOVER_Y_OFFSET = -80
EnemyDreadnought.static.BULLET_SPEED = 140

function EnemyDreadnought:initialize(duration)
    Entity.initialize(self, 'enemy', 0, vector(0, 0))
    self.duration = duration or 12
    self.fireTimer = EnemyDreadnought.FIRE_INTERVAL * 0.5
    self.targetY = 0
    self:gotoState('Entering')
end

function EnemyDreadnought:update(dt)
    Entity.update(self, dt)
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
    local r, g, b = 1.0, 0.2, 0.2
    love.graphics.push()
    love.graphics.translate(self.pos:unpack())

    love.graphics.setColor(r * 0.15, g * 0.15, b * 0.15, 0.4)
    love.graphics.polygon('fill',
        -EnemyDreadnought.WIDTH * 0.8, -EnemyDreadnought.HEIGHT * 0.5,
        EnemyDreadnought.WIDTH * 0.8, -EnemyDreadnought.HEIGHT * 0.5,
        EnemyDreadnought.WIDTH * 0.5, EnemyDreadnought.HEIGHT * 0.5,
        0, EnemyDreadnought.HEIGHT * 0.7,
        -EnemyDreadnought.WIDTH * 0.5, EnemyDreadnought.HEIGHT * 0.5)

    love.graphics.setColor(r * 0.4, g * 0.4, b * 0.4, 0.6)
    love.graphics.polygon('fill',
        -EnemyDreadnought.WIDTH * 0.65, -EnemyDreadnought.HEIGHT * 0.4,
        EnemyDreadnought.WIDTH * 0.65, -EnemyDreadnought.HEIGHT * 0.4,
        EnemyDreadnought.WIDTH * 0.4, EnemyDreadnought.HEIGHT * 0.4,
        0, EnemyDreadnought.HEIGHT * 0.55,
        -EnemyDreadnought.WIDTH * 0.4, EnemyDreadnought.HEIGHT * 0.4)

    love.graphics.setColor(r, g, b, 0.9)
    love.graphics.polygon('line',
        -EnemyDreadnought.WIDTH * 0.5, -EnemyDreadnought.HEIGHT * 0.3,
        EnemyDreadnought.WIDTH * 0.5, -EnemyDreadnought.HEIGHT * 0.3,
        EnemyDreadnought.WIDTH * 0.3, EnemyDreadnought.HEIGHT * 0.3,
        0, EnemyDreadnought.HEIGHT * 0.4,
        -EnemyDreadnought.WIDTH * 0.3, EnemyDreadnought.HEIGHT * 0.3)

    love.graphics.setColor(1.0, 0.3, 0.1, 0.6)
    love.graphics.circle('fill', -EnemyDreadnought.WIDTH * 0.3, EnemyDreadnought.HEIGHT * 0.45, 4)
    love.graphics.circle('fill', EnemyDreadnought.WIDTH * 0.3, EnemyDreadnought.HEIGHT * 0.45, 4)
    love.graphics.circle('fill', 0, EnemyDreadnought.HEIGHT * 0.55, 3)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle('fill', 0, -EnemyDreadnought.HEIGHT * 0.1, 2)

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
    self.pos.x = (camL + camR) / 2
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
    self.pos.x = (camL + camR) / 2
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
