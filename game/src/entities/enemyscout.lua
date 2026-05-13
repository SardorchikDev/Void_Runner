-- Fast horizontal enemy ship that leads the player with single cyan shots.
EnemyScout = class('EnemyScout', Entity)
EnemyScout.static.HEALTH = 2
EnemyScout:include(Stateful)

EnemyScout.static.SIZE = 18
EnemyScout.static.SPEED = 120
EnemyScout.static.FIRE_INTERVAL = 0.6
EnemyScout.static.INTRO_TIME = 0.6

function EnemyScout:initialize(side, duration)
    Entity.initialize(self, 'enemy', 0, vector(0, 0))
    self.side = side
    self.duration = duration or 8
    self.fireTimer = 0
    self.direction = side == 'left' and 1 or -1
    self.targetY = nil
    self.health = EnemyScout.HEALTH
    self.radius = EnemyScout.SIZE
    self.hitFlash = 0
    self:gotoState('Entering')
end

function EnemyScout:takeDamage(amount)
    self.health = self.health - (amount or 1)
    self.hitFlash = 0.1
    if self.health <= 0 then
        if self.gameState then
            self.gameState:addEntity(Explosion(self.pos:clone(), 25, {
                core = {0.3, 1.0, 1.0}, mid = {0.1, 0.7, 0.9}, outer = {0.05, 0.3, 0.5}
            }))
            self.gameState:onEnemyKilled('scout', self.pos:clone())
        end
        self:destroy()
    end
end

function EnemyScout:update(dt)
    Entity.update(self, dt)
    if self.hitFlash > 0 then
        self.hitFlash = self.hitFlash - dt
    end
    if self.time > self.duration then
        self:destroy()
    end
end

function EnemyScout:getPlayerPos()
    local player = self.gameState:getEntityByTag('player')
    if player then
        local travelTime = (player.pos - self.pos):len() / 180
        return player.pos:clone() + (player.velocity or vector(0, 0)) * math.min(0.8, travelTime)
    end
    return vector(0, 0)
end

function EnemyScout:draw()
    local S = EnemyScout.SIZE
    love.graphics.push()
    love.graphics.translate(self.pos:unpack())
    love.graphics.rotate(self.direction > 0 and 0 or math.pi)

    -- fuselage (thin vertical rectangle)
    love.graphics.setColor(0.05, 0.25, 0.3, 0.8)
    love.graphics.polygon('fill', -3, -12, 3, -12, 3, 12, -3, 12)

    -- swept wings
    love.graphics.setColor(0.05, 0.2, 0.25, 0.7)
    love.graphics.polygon('fill', -3, -4, -18, 8, -6, 8)
    love.graphics.polygon('fill', 3, -4, 18, 8, 6, 8)

    -- tail fins
    love.graphics.setColor(0.08, 0.3, 0.35, 0.6)
    love.graphics.polygon('fill', -3, 8, -8, 14, -3, 12)
    love.graphics.polygon('fill', 3, 8, 8, 14, 3, 12)

    -- chromatic panel lines
    love.graphics.setColor(0.03, 0.15, 0.2, 0.4)
    love.graphics.setLineWidth(0.5)
    love.graphics.line(-2, -8, -2, 8)
    love.graphics.line(2, -8, 2, 8)
    love.graphics.line(-3, 0, 3, 0)

    -- edge outline
    love.graphics.setColor(0.2, 0.9, 1.0, 0.9)
    love.graphics.setLineWidth(1)
    love.graphics.polygon('line', -3, -12, 3, -12, 3, 12, -3, 12)
    love.graphics.polygon('line', -3, -4, -18, 8, -6, 8)
    love.graphics.polygon('line', 3, -4, 18, 8, 6, 8)

    -- cockpit teardrop
    love.graphics.setColor(0.4, 0.9, 1.0, 0.8)
    love.graphics.ellipse('fill', 0, -8, 2, 3)

    -- engine glow (pulsing)
    local pulse = 2 + math.sin((self.time or 0) * 8) * 1
    love.graphics.setBlendMode('add')
    love.graphics.setColor(0.2, 0.6, 1.0, 0.5)
    love.graphics.circle('fill', 0, 12, pulse)
    love.graphics.setBlendMode('alpha')

    -- hit flash (white outline)
    if self.hitFlash > 0 then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.circle('line', 0, 0, S * 0.8)
    end

    love.graphics.pop()
end

local Entering = EnemyScout:addState('Entering')
function Entering:update(dt)
    EnemyScout.update(self, dt)
    local t = self.time / EnemyScout.INTRO_TIME
    local camL, camT = self.gameState.cam:worldCoords(0, 0)
    local camR, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
    if not self.targetY then
        self.targetY = lume.random(camT + 35, camB - 35)
    end
    if self.direction > 0 then
        self.pos.x = lume.lerp(camL - 40, camL + 30, math.min(1, t))
    else
        self.pos.x = lume.lerp(camR + 40, camR - 30, math.min(1, t))
    end
    self.pos.y = self.targetY
    if self.time > EnemyScout.INTRO_TIME then
        self:gotoState('Traversing')
    end
end

local Traversing = EnemyScout:addState('Traversing')
function Traversing:update(dt)
    EnemyScout.update(self, dt)
    self.pos.x = self.pos.x + self.direction * EnemyScout.SPEED * dt

    local camL, camT = self.gameState.cam:worldCoords(0, 0)
    local camR, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())

    if self.pos.y < camT + 30 then self.pos.y = camT + 30 end
    if self.pos.y > camB - 30 then self.pos.y = camB - 30 end

    self.fireTimer = self.fireTimer + dt
    if self.fireTimer > EnemyScout.FIRE_INTERVAL then
        self.fireTimer = 0
        local playerPos = self:getPlayerPos()
        local dir = (playerPos - self.pos):normalized()
        if dir:len() == 0 then dir = vector(self.direction, 0) end
        local proj = Projectile(self.pos:clone(), dir * 180, Color.CYAN, 3.5)
        self.gameState:addEntity(proj)
    end

    if (self.direction > 0 and self.pos.x > camR + 50) or (self.direction < 0 and self.pos.x < camL - 50) then
        self:destroy()
    end
end

return EnemyScout
