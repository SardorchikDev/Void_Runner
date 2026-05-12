-- Swarm enemy: small fast ships that attack in coordinated groups.
EnemySwarm = class('EnemySwarm', Entity)
EnemySwarm:include(Stateful)

EnemySwarm.static.SIZE = 10
EnemySwarm.static.SPEED = 100
EnemySwarm.static.HEALTH = 1
EnemySwarm.static.FIRE_INTERVAL = 1.2

function EnemySwarm:initialize(side, index, total)
    Entity.initialize(self, 'enemy', 0, vector(0, 0))
    self.side = side or 'left'
    self.index = index or 0
    self.total = total or 4
    self.direction = self.side == 'left' and 1 or -1
    self.health = EnemySwarm.HEALTH
    self.radius = EnemySwarm.SIZE
    self.fireTimer = lume.random(0, EnemySwarm.FIRE_INTERVAL)
    self.duration = 8
    self.waveOffset = (index or 0) * math.pi * 2 / (total or 4)
    self:gotoState('Active')
end

function EnemySwarm:takeDamage(amount)
    self.health = self.health - (amount or 1)
    if self.health <= 0 then
        if self.gameState then
            self.gameState:addEntity(Explosion(self.pos:clone(), 12, {
                core = {0.5, 1.0, 0.3}, mid = {0.3, 0.8, 0.1}, outer = {0.1, 0.4, 0.05}
            }))
            self.gameState:onEnemyKilled('swarm')
        end
        self:destroy()
    end
end

function EnemySwarm:update(dt)
    Entity.update(self, dt)
    if self.time > self.duration then
        self:destroy()
    end
end

function EnemySwarm:draw()
    local r, g, b = 0.3, 1.0, 0.3
    love.graphics.push()
    love.graphics.translate(self.pos:unpack())

    love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, 0.6)
    love.graphics.polygon('fill',
        0, -EnemySwarm.SIZE,
        EnemySwarm.SIZE * 0.7, EnemySwarm.SIZE * 0.5,
        -EnemySwarm.SIZE * 0.7, EnemySwarm.SIZE * 0.5)

    love.graphics.setColor(r, g, b, 0.9)
    love.graphics.setLineWidth(1)
    love.graphics.polygon('line',
        0, -EnemySwarm.SIZE,
        EnemySwarm.SIZE * 0.7, EnemySwarm.SIZE * 0.5,
        -EnemySwarm.SIZE * 0.7, EnemySwarm.SIZE * 0.5)

    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.circle('fill', 0, -EnemySwarm.SIZE * 0.2, 1.5)

    love.graphics.pop()
end

local Active = EnemySwarm:addState('Active')
function Active:enteredState()
    if not self.gameState then return end
    local camL, camT = self.gameState.cam:worldCoords(0, 0)
    local camR, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
    if self.side == 'left' then
        self.pos.x = camL - 30 - self.index * 20
    else
        self.pos.x = camR + 30 + self.index * 20
    end
    self.pos.y = (camT + camB) / 2 - 40 + self.index * 25
end

function Active:update(dt)
    EnemySwarm.update(self, dt)
    self.pos.x = self.pos.x + self.direction * EnemySwarm.SPEED * dt
    self.pos.y = self.pos.y + math.sin(self.time * 3 + self.waveOffset) * 30 * dt

    self.fireTimer = self.fireTimer + dt
    if self.fireTimer >= EnemySwarm.FIRE_INTERVAL then
        self.fireTimer = 0
        if self.gameState then
            local player = self.gameState:getEntityByTag('player')
            if player and not player:isDead() then
                local dir = (player.pos - self.pos):normalized()
                if dir:len() == 0 then dir = vector(0, 1) end
                local proj = Projectile(self.pos:clone(), dir * 160, Color.GREEN, 3, 5)
                self.gameState:addEntity(proj)
            end
        end
    end
end

return EnemySwarm
