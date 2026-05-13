-- Mine-layer enemy that drops stationary mines in the player's path.
EnemyMinelayer = class('EnemyMinelayer', Entity)
EnemyMinelayer:include(Stateful)

EnemyMinelayer.static.SIZE = 22
EnemyMinelayer.static.SPEED = 60
EnemyMinelayer.static.HEALTH = 3
EnemyMinelayer.static.MINE_INTERVAL = 1.8

function EnemyMinelayer:initialize(side, duration)
    Entity.initialize(self, 'enemy', 0, vector(0, 0))
    self.side = side or 'left'
    self.duration = duration or 10
    self.direction = self.side == 'left' and 1 or -1
    self.mineTimer = EnemyMinelayer.MINE_INTERVAL * 0.5
    self.health = EnemyMinelayer.HEALTH
    self.radius = EnemyMinelayer.SIZE
    self:gotoState('Active')
end

function EnemyMinelayer:takeDamage(amount)
    self.health = self.health - (amount or 1)
    if self.health <= 0 then
        if self.gameState then
            self.gameState:addEntity(Explosion(self.pos:clone(), 30, {
                core = {1.0, 0.8, 0.2}, mid = {0.8, 0.5, 0.1}, outer = {0.5, 0.2, 0.05}
            }))
            self.gameState:onEnemyKilled('minelayer', self.pos:clone())
        end
        self:destroy()
    end
end

function EnemyMinelayer:update(dt)
    Entity.update(self, dt)
    if self.time > self.duration then
        self:destroy()
    end
end

function EnemyMinelayer:draw()
    local r, g, b = 0.9, 0.7, 0.1
    love.graphics.push()
    love.graphics.translate(self.pos:unpack())

    love.graphics.setColor(r * 0.2, g * 0.2, b * 0.2, 0.6)
    love.graphics.rectangle('fill', -EnemyMinelayer.SIZE * 0.7, -EnemyMinelayer.SIZE * 0.4,
        EnemyMinelayer.SIZE * 1.4, EnemyMinelayer.SIZE * 0.8)

    love.graphics.setColor(r * 0.5, g * 0.5, b * 0.5, 0.8)
    love.graphics.rectangle('fill', -EnemyMinelayer.SIZE * 0.5, -EnemyMinelayer.SIZE * 0.3,
        EnemyMinelayer.SIZE * 1.0, EnemyMinelayer.SIZE * 0.6)

    love.graphics.setColor(r, g, b, 0.9)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle('line', -EnemyMinelayer.SIZE * 0.5, -EnemyMinelayer.SIZE * 0.3,
        EnemyMinelayer.SIZE * 1.0, EnemyMinelayer.SIZE * 0.6)

    -- mine bay indicator
    local pulse = math.sin(self.time * 4) * 0.3 + 0.7
    love.graphics.setColor(1.0, 0.4, 0.1, pulse)
    love.graphics.circle('fill', 0, EnemyMinelayer.SIZE * 0.2, 3)

    love.graphics.pop()
end

local Active = EnemyMinelayer:addState('Active')
function Active:enteredState()
    if not self.gameState then return end
    local camL, camT = self.gameState.cam:worldCoords(0, 0)
    local camR, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
    if self.side == 'left' then
        self.pos.x = camL - EnemyMinelayer.SIZE
    else
        self.pos.x = camR + EnemyMinelayer.SIZE
    end
    self.pos.y = (camT + camB) / 2 + lume.random(-50, -20)
end

function Active:update(dt)
    EnemyMinelayer.update(self, dt)
    self.pos.x = self.pos.x + self.direction * EnemyMinelayer.SPEED * dt

    self.mineTimer = self.mineTimer + dt
    if self.mineTimer >= EnemyMinelayer.MINE_INTERVAL then
        self.mineTimer = 0
        self:dropMine()
    end
end

function Active:dropMine()
    if not self.gameState then return end
    local mine = Mine(self.pos:clone() + vector(0, EnemyMinelayer.SIZE * 0.5))
    self.gameState:addEntity(mine)
end

return EnemyMinelayer
