-- NEW: Fast horizontal enemy ship that leads the player with single cyan shots.
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
    self:gotoState('Entering')
end

function EnemyScout:takeDamage(amount)
    self.health = self.health - (amount or 1)
    if self.health <= 0 then
        if self.gameState then
            self.gameState:addEntity(Explosion(self.pos:clone(), 25, {
                core = {0.3, 1.0, 1.0}, mid = {0.1, 0.7, 0.9}, outer = {0.05, 0.3, 0.5}
            }))
            self.gameState:onEnemyKilled('scout')
        end
        self:destroy()
    end
end

function EnemyScout:update(dt)
    Entity.update(self, dt)
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
    local r, g, b = 0.2, 0.9, 1.0
    love.graphics.push()
    love.graphics.translate(self.pos:unpack())
    love.graphics.rotate(self.direction > 0 and 0 or math.pi)

    love.graphics.setColor(r * 0.15, g * 0.15, b * 0.15, 0.4)
    love.graphics.polygon('fill', -EnemyScout.SIZE, -EnemyScout.SIZE * 0.4,
        EnemyScout.SIZE * 0.5, 0, -EnemyScout.SIZE, EnemyScout.SIZE * 0.4)

    love.graphics.setColor(r * 0.4, g * 0.4, b * 0.4, 0.6)
    love.graphics.polygon('fill', -EnemyScout.SIZE * 0.85, -EnemyScout.SIZE * 0.3,
        EnemyScout.SIZE * 0.4, 0, -EnemyScout.SIZE * 0.85, EnemyScout.SIZE * 0.3)

    love.graphics.setColor(r, g, b, 0.9)
    love.graphics.polygon('fill', -EnemyScout.SIZE * 0.7, -EnemyScout.SIZE * 0.2,
        EnemyScout.SIZE * 0.3, 0, -EnemyScout.SIZE * 0.7, EnemyScout.SIZE * 0.2)

    love.graphics.setColor(0.2, 0.9, 1.0, 0.6)
    love.graphics.circle('fill', -EnemyScout.SIZE * 0.8, 0, 3)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle('fill', 0, 0, 1.5)

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
