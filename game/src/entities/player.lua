-- MODIFIED: Dash-only afterimages + auto-aim laser system.
Player = class('Player', Entity)
Player:include(Stateful)

Player.static.WIDTH = 14
Player.static.HEIGHT = 18
Player.static.DIP = 4
Player.static.NUM_TRAILS = 22
Player.static.DEATH_SOUND = love.audio.newSource('assets/sound/die.wav', 'static')
Player.static.DEATH_SOUND:setVolume(0.2)

function Player:initialize()
    Entity.initialize(self, 'player', 0, vector(0, 0))
    self.angle = 0
    self.target_angle = 0
    self.last_pos = self.pos:clone()
    self.last_angle = 0

    self.thrustCooldown = 0
    self.thrustCooldownMax = 0.5
    self.thrustActive = false
    self.thrustTimer = 0

    self.driftSpeed = 60
    self.driftTimer = 0
    self.velocity = vector(0, 0)

    self.wobbleAngle = 0
    self.wobbleTime = 0

    self.scrollSpeed = 100

    self.mouseTarget = nil
    self.mouseFollowSpeed = 10
    self.baseMouseFollowSpeed = 10
    self.maxSpeed = 320

    -- double laser powerup
    self.doubleLaser = false
    self.doubleLaserTimer = 0

    -- smooth dash system
    self.isDashing = false
    self.dashStart = vector(0, 0)
    self.dashTarget = vector(0, 0)
    self.dashTime = 0
    self.dashDuration = 0.22
    self.dashDir = vector(0, 0)
    self.dashParticles = {}
    self.dashCooldownTimer = 0
    self.dashCooldownMax = 0.6

    -- dash afterimages (stay in place, fade out)
    self.dashAfterimages = {}
    self.dashAfterimageTimer = 0

    -- auto-aim laser
    self.autoAimTarget = nil
    self.autoAimState = 'idle' -- idle, acquiring, locking, firing, cooldown
    self.autoAimTimer = 0
    self.autoAimAcquireTime = 0.5
    self.autoAimLockTime = 0.4
    self.autoAimCooldownMax = 0.6
    self.autoAimRange = 220
    self.autoAimCone = math.rad(55)

    -- manual fire
    self.manualFireCooldown = 0
    self.manualFireCooldownMax = 0.22

    local shapeVerts = {
        -Player.WIDTH * 0.5, Player.HEIGHT * 0.3,
        -Player.WIDTH * 0.2, -Player.HEIGHT * 0.2,
        0, -Player.HEIGHT * 0.5,
        Player.WIDTH * 0.2, -Player.HEIGHT * 0.2,
        Player.WIDTH * 0.5, Player.HEIGHT * 0.3,
        Player.WIDTH * 0.3, Player.HEIGHT * 0.5,
        0, Player.HEIGHT * 0.3,
        -Player.WIDTH * 0.3, Player.HEIGHT * 0.5
    }
    self.collision_shape = collision.newPolygonShape(unpack(shapeVerts))
    local x, y = self.collision_shape:center()
    self.collision_offset = vector(x, y)
end

function Player:update(dt)
    Entity.update(self, dt)

    local previousPos = self.pos:clone()

    self.wobbleTime = self.wobbleTime + dt
    self.wobbleAngle = math.sin(self.wobbleTime * 2.5) * 0.035

    -- dash cooldown
    if self.dashCooldownTimer > 0 then
        self.dashCooldownTimer = math.max(0, self.dashCooldownTimer - dt)
    end

    -- manual fire cooldown
    if self.manualFireCooldown > 0 then
        self.manualFireCooldown = math.max(0, self.manualFireCooldown - dt)
    end

    -- double laser timer
    if self.doubleLaser then
        self.doubleLaserTimer = self.doubleLaserTimer - dt
        if self.doubleLaserTimer <= 0 then
            self.doubleLaser = false
        end
    end

    -- scale mouse follow speed with depth
    if self.gameState and self.gameState.depth then
        self.mouseFollowSpeed = self.baseMouseFollowSpeed + self.gameState.depth * 0.003
    end

    -- smooth dash interpolation
    if self.isDashing then
        self.dashTime = self.dashTime + dt
        local t = math.min(1, self.dashTime / self.dashDuration)
        local ease = 1 - math.pow(1 - t, 3)
        self.pos = vector(
            lume.lerp(self.dashStart.x, self.dashTarget.x, ease),
            lume.lerp(self.dashStart.y, self.dashTarget.y, ease)
        )

        -- spawn dash particles
        if math.random() < 0.7 then
            table.insert(self.dashParticles, {
                pos = self.pos:clone() + vector(lume.random(-4, 4), lume.random(-4, 4)),
                vel = vector(lume.random(-30, 30), lume.random(-30, 30)),
                life = lume.random(0.1, 0.3),
                maxLife = 0.3,
                size = lume.random(1, 3),
                color = {0.3, 0.8, 1.0}
            })
        end

        -- spawn dash afterimages
        self.dashAfterimageTimer = self.dashAfterimageTimer - dt
        if self.dashAfterimageTimer <= 0 then
            self.dashAfterimageTimer = 0.03
            table.insert(self.dashAfterimages, {
                pos = self.pos:clone(),
                angle = self.angle,
                life = 0.28,
                maxLife = 0.28
            })
        end

        if t >= 1 then
            self.isDashing = false
            self.thrustActive = false
        end
    end

    -- update dash particles
    for i = #self.dashParticles, 1, -1 do
        local p = self.dashParticles[i]
        p.pos = p.pos + p.vel * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.dashParticles, i)
        end
    end

    -- update dash afterimages (fade out)
    for i = #self.dashAfterimages, 1, -1 do
        local im = self.dashAfterimages[i]
        im.life = im.life - dt
        if im.life <= 0 then
            table.remove(self.dashAfterimages, i)
        end
    end

    if self.mouseTarget and not self.isDashing then
        local target = self.mouseTarget:clone()
        if self.gameState and self.gameState.cam then
            local camL, camT = self.gameState.cam:worldCoords(0, 0)
            local camR, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
            local margin = 20
            target.x = lume.clamp(target.x, camL + margin, camR - margin)
        end
        local desired = vector(
            lume.lerp(self.pos.x, target.x, self.mouseFollowSpeed * dt),
            lume.lerp(self.pos.y, target.y, self.mouseFollowSpeed * dt)
        )
        local move = desired - self.pos
        local maxMove = self.maxSpeed * dt
        if move:len() > maxMove then
            move = move:normalized() * maxMove
            desired = self.pos + move
        end
        self.pos = desired
    end

    -- angle toward mouse (or dash direction)
    if self.isDashing then
        if self.dashDir:len() > 0 then
            self.target_angle = math.atan2(self.dashDir.y, self.dashDir.x) + math.pi / 2
        end
    elseif self.mouseTarget then
        local dx = self.mouseTarget.x - self.pos.x
        local dy = self.mouseTarget.y - self.pos.y
        if math.abs(dx) > 0.5 or math.abs(dy) > 0.5 then
            self.target_angle = math.atan2(dy, dx) + math.pi / 2
        end
    else
        local xvel = (self.pos.x - self.last_pos.x) / math.max(dt, 0.001)
        self.target_angle = xvel * 0.003
    end

    -- shortest-path angle lerp
    local angleDiff = self.target_angle - self.angle
    while angleDiff > math.pi do angleDiff = angleDiff - 2 * math.pi end
    while angleDiff < -math.pi do angleDiff = angleDiff + 2 * math.pi end
    local smoothAngle = self.angle + angleDiff * 4.0 * dt

    self.angle = smoothAngle

    -- auto-aim targeting state machine
    if not self.dead and self.gameState then
        self.autoAimTimer = self.autoAimTimer - dt

        if self.autoAimState == 'idle' or self.autoAimState == 'cooldown' then
            -- search for new target
            local forward = vector(math.sin(self.angle), -math.cos(self.angle))
            local bestDist = self.autoAimRange
            local bestTarget = nil

            local targetTags = {'obstacle', 'enemy'}
            for _, tag in ipairs(targetTags) do
                for _, ent in ipairs(self.gameState:getEntitiesByTag(tag)) do
                    if ent ~= self and not ent:isDead() then
                        local toTarget = ent.pos - self.pos
                        local dist = toTarget:len()
                        if dist < bestDist then
                            local dir = toTarget:normalized()
                            local dot = forward.x * dir.x + forward.y * dir.y
                            local angle = math.acos(math.max(-1, math.min(1, dot)))
                            if angle < self.autoAimCone then
                                bestDist = dist
                                bestTarget = ent
                            end
                        end
                    end
                end
            end

            if bestTarget then
                self.autoAimTarget = bestTarget
                self.autoAimState = 'acquiring'
                self.autoAimTimer = self.autoAimAcquireTime
            else
                self.autoAimTarget = nil
            end

        elseif self.autoAimState == 'acquiring' then
            if not self.autoAimTarget or self.autoAimTarget:isDead() then
                self.autoAimState = 'idle'
                self.autoAimTarget = nil
            elseif self.autoAimTimer <= 0 then
                self.autoAimState = 'locking'
                self.autoAimTimer = self.autoAimLockTime
            end

        elseif self.autoAimState == 'locking' then
            if not self.autoAimTarget or self.autoAimTarget:isDead() then
                self.autoAimState = 'idle'
                self.autoAimTarget = nil
            elseif self.autoAimTimer <= 0 then
                self.autoAimState = 'firing'
                self.autoAimTimer = 0.08
                -- fire laser
                if self.autoAimTarget then
                    local laser = Laser(self.pos:clone(), self.autoAimTarget)
                    self.gameState:addEntity(laser)
                    if self.gameState.screenEffects then
                        self.gameState.screenEffects:shake(2, 0.05)
                    end
                end
            end

        elseif self.autoAimState == 'firing' then
            if self.autoAimTimer <= 0 then
                self.autoAimState = 'cooldown'
                self.autoAimTimer = self.autoAimCooldownMax
                self.autoAimTarget = nil
            end

        elseif self.autoAimState == 'cooldown' then
            if self.autoAimTimer <= 0 then
                self.autoAimState = 'idle'
            end
        end
    end

    self.pos.y = self.pos.y + self.driftSpeed * dt

    if self.thrustActive and not self.isDashing then
        self.thrustTimer = self.thrustTimer - dt
        if self.thrustTimer <= 0 then
            self.thrustActive = false
        end
    end

    local INTERVALS = 5
    for i = 1, INTERVALS do
        local a = lume.lerp(self.last_angle, self.angle, i / INTERVALS)
        local pos = vector(
            lume.lerp(self.last_pos.x, self.pos.x, i / INTERVALS),
            lume.lerp(self.last_pos.y, self.pos.y, i / INTERVALS)
        )
        self.collision_shape:moveTo((pos + self.collision_offset):unpack())
        self.collision_shape:setRotation(a, pos:unpack())

        for _, obstacle in ipairs(self.gameState:getEntitiesByTag('obstacle')) do
            local collision, dx, dy = obstacle:collidesWith(self.collision_shape)
            if collision then
                self.pos = pos - vector(dx, dy)
                if obstacle.onDestroyed then
                    obstacle:onDestroyed(self.gameState)
                end
                obstacle:destroy()

                if self.gameState.shield and self.gameState.shield:isActive() then
                    self.gameState.shield:absorb()
                    self.gameState:onShieldHit()
                else
                    self:onDeath()
                end
                break
            end
        end

        if self.dead then break end

        for _, proj in ipairs(self.gameState:getEntitiesByTag('projectile')) do
            if proj:collidesWith(self.collision_shape) then
                if self.gameState.shield and self.gameState.shield:isActive() then
                    self.gameState.shield:absorb()
                    self.gameState:onShieldHit()
                    proj:destroy()
                else
                    self:onDeath()
                end
                break
            end
        end

        if self.dead then break end
    end

    if self.gameState and self.gameState.cam then
        local camL, camT = self.gameState.cam:worldCoords(0, 0)
        local camR, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
        local margin = 20
        self.pos.x = lume.clamp(self.pos.x, camL + margin, camR - margin)
    end

    if dt > 0 then
        self.velocity = (self.pos - previousPos) / dt
    else
        self.velocity = vector(0, 0)
    end

    self.last_pos = self.pos:clone()
    self.last_angle = self.angle
end

function Player:onDeath()
    if self.dead then return end
    self.dead = true
    self.mouseTarget = nil
    self.isDashing = false
    self.autoAimTarget = nil
    Player.DEATH_SOUND:play()
    self.gameState:onPlayerDeath()
    self:gotoState('Dead')
end

-- dash in any direction
function Player:dash(dirX, dirY)
    if self.dead or self.isDashing then return end
    if self.dashCooldownTimer > 0 then return end

    local dir = vector(dirX, dirY)
    if dir:len() < 0.01 then return end
    dir = dir:normalized()

    self.dashCooldownTimer = self.dashCooldownMax
    self.thrustActive = true
    self.thrustTimer = self.dashDuration

    self.isDashing = true
    self.dashTime = 0
    self.dashStart = self.pos:clone()
    self.dashDir = dir
    self.dashAfterimageTimer = 0

    local dashDistance = 90
    self.dashTarget = self.pos + dir * dashDistance

    if self.gameState and self.gameState.screenEffects then
        self.gameState.screenEffects:shake(8, 0.15)
        self.gameState.screenEffects:blur(0.5, 0.3)
    end

    if self.gameState and self.gameState.audioManager then
        self.gameState.audioManager:playThrust()
        self.gameState.audioManager:playDash()
    end

    if self.gameState then
        self.gameState:onPlayerDash()
    end
end

-- old thrust kept for compatibility but redirects to dash
function Player:thrust(dx, dy)
    self:dash(dx, dy)
end

function Player:moveHorizontal(dx)
    self.pos.x = self.pos.x + dx
    self.pos.x = lume.clamp(self.pos.x, -300, 300)
end

function Player:drawBody()
    local r, g, b = 0.3, 0.8, 1.0
    local timeWarpGlow = self.gameState and self.gameState.timeWarpActive
    if timeWarpGlow then
        r, g, b = 0.9, 0.95, 1.0
    end

    local isDashing = self.isDashing
    local dashAlpha = 1.0
    if isDashing then
        dashAlpha = 0.85
        r, g, b = 0.5, 0.9, 1.0
    end

    love.graphics.push()
    love.graphics.translate(self.pos:unpack())
    love.graphics.rotate(self.angle)

    love.graphics.setLineStyle('smooth')

    -- engine glow / aura
    if isDashing then
        love.graphics.setColor(0.3, 0.8, 1.0, 0.15)
        love.graphics.circle('fill', 0, 0, Player.HEIGHT * 1.5)
        love.graphics.setColor(0.4, 0.9, 1.0, 0.25)
        love.graphics.circle('fill', 0, 0, Player.HEIGHT * 1.1)
    end

    if timeWarpGlow then
        love.graphics.setColor(0.7, 0.9, 1.0, 0.22)
        love.graphics.circle('fill', 0, 0, Player.HEIGHT * 1.15)
    end

    -- engine exhaust flare
    local enginePulse = math.sin(self.wobbleTime * 8) * 0.15 + 0.85
    love.graphics.setColor(r * 0.4, g * 0.6, b * 0.9, 0.4 * enginePulse * dashAlpha)
    love.graphics.circle('fill', 0, Player.HEIGHT * 0.45, 4 * enginePulse)
    love.graphics.setColor(r * 0.6, g * 0.8, b, 0.6 * enginePulse * dashAlpha)
    love.graphics.circle('fill', 0, Player.HEIGHT * 0.45, 2.5 * enginePulse)

    -- ship shadow layer
    love.graphics.setColor(r * 0.15, g * 0.15, b * 0.15, 0.5 * dashAlpha)
    love.graphics.polygon('fill',
        -Player.WIDTH * 0.7, Player.HEIGHT * 0.35,
        -Player.WIDTH * 0.25, -Player.HEIGHT * 0.25,
        0, -Player.HEIGHT * 0.7,
        Player.WIDTH * 0.25, -Player.HEIGHT * 0.25,
        Player.WIDTH * 0.7, Player.HEIGHT * 0.35,
        Player.WIDTH * 0.35, Player.HEIGHT * 0.55,
        0, Player.HEIGHT * 0.35,
        -Player.WIDTH * 0.35, Player.HEIGHT * 0.55)

    -- mid glow line
    love.graphics.setColor(r * 0.3, g * 0.5, b * 0.7, 0.4 * dashAlpha)
    love.graphics.setLineWidth(3)
    love.graphics.polygon('line',
        -Player.WIDTH * 0.55, Player.HEIGHT * 0.25,
        -Player.WIDTH * 0.2, -Player.HEIGHT * 0.15,
        0, -Player.HEIGHT * 0.55,
        Player.WIDTH * 0.2, -Player.HEIGHT * 0.15,
        Player.WIDTH * 0.55, Player.HEIGHT * 0.25,
        Player.WIDTH * 0.25, Player.HEIGHT * 0.45,
        0, Player.HEIGHT * 0.25,
        -Player.WIDTH * 0.25, Player.HEIGHT * 0.45)

    -- body fill
    love.graphics.setColor(r * 0.2, g * 0.4, b * 0.6, 0.6 * dashAlpha)
    love.graphics.polygon('fill',
        -Player.WIDTH * 0.4, Player.HEIGHT * 0.18,
        -Player.WIDTH * 0.15, -Player.HEIGHT * 0.1,
        0, -Player.HEIGHT * 0.4,
        Player.WIDTH * 0.15, -Player.HEIGHT * 0.1,
        Player.WIDTH * 0.4, Player.HEIGHT * 0.18,
        Player.WIDTH * 0.15, Player.HEIGHT * 0.32,
        0, Player.HEIGHT * 0.18,
        -Player.WIDTH * 0.15, Player.HEIGHT * 0.32)

    -- highlight outline
    love.graphics.setColor(r, g, b, 0.9 * dashAlpha)
    love.graphics.setLineWidth(1.5)
    love.graphics.polygon('line',
        -Player.WIDTH * 0.3, Player.HEIGHT * 0.12,
        -Player.WIDTH * 0.1, -Player.HEIGHT * 0.05,
        0, -Player.HEIGHT * 0.3,
        Player.WIDTH * 0.1, -Player.HEIGHT * 0.05,
        Player.WIDTH * 0.3, Player.HEIGHT * 0.12,
        Player.WIDTH * 0.1, Player.HEIGHT * 0.22,
        0, Player.HEIGHT * 0.12,
        -Player.WIDTH * 0.1, Player.HEIGHT * 0.22)

    -- cockpit / core light
    love.graphics.setColor(1, 1, 1, 0.8 * dashAlpha)
    love.graphics.circle('fill', 0, -Player.HEIGHT * 0.15, 2)

    -- dash energy ring
    if isDashing then
        local ringT = self.dashTime / self.dashDuration
        local ringAlpha = (1 - ringT) * 0.5
        love.graphics.setColor(r, g, b, ringAlpha)
        love.graphics.setLineWidth(2)
        love.graphics.circle('line', 0, 0, Player.HEIGHT * (0.8 + ringT * 0.5))
    end

    love.graphics.pop()
end

function Player:draw()
    Entity.draw(self)

    -- dash afterimages (stay in place, fade out)
    for _, im in ipairs(self.dashAfterimages) do
        local alpha = math.max(0, im.life / im.maxLife) * 0.35
        love.graphics.push()
        love.graphics.translate(im.pos:unpack())
        love.graphics.rotate(im.angle)

        -- ghost silhouette
        love.graphics.setColor(0.3, 0.75, 1.0, alpha * 0.2)
        love.graphics.polygon('fill',
            -Player.WIDTH * 0.4, Player.HEIGHT * 0.18,
            -Player.WIDTH * 0.15, -Player.HEIGHT * 0.1,
            0, -Player.HEIGHT * 0.4,
            Player.WIDTH * 0.15, -Player.HEIGHT * 0.1,
            Player.WIDTH * 0.4, Player.HEIGHT * 0.18,
            Player.WIDTH * 0.15, Player.HEIGHT * 0.32,
            0, Player.HEIGHT * 0.18,
            -Player.WIDTH * 0.15, Player.HEIGHT * 0.32)

        love.graphics.setColor(0.4, 0.85, 1.0, alpha * 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.polygon('line',
            -Player.WIDTH * 0.3, Player.HEIGHT * 0.12,
            -Player.WIDTH * 0.1, -Player.HEIGHT * 0.05,
            0, -Player.HEIGHT * 0.3,
            Player.WIDTH * 0.1, -Player.HEIGHT * 0.05,
            Player.WIDTH * 0.3, Player.HEIGHT * 0.12,
            Player.WIDTH * 0.1, Player.HEIGHT * 0.22,
            0, Player.HEIGHT * 0.12,
            -Player.WIDTH * 0.1, Player.HEIGHT * 0.22)

        love.graphics.pop()
    end

    -- dash particles
    for _, p in ipairs(self.dashParticles) do
        local alpha = math.max(0, p.life / p.maxLife)
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.6)
        love.graphics.circle('fill', p.pos.x, p.pos.y, p.size)
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.2)
        love.graphics.circle('fill', p.pos.x, p.pos.y, p.size * 2.5)
    end

    self:drawBody()
end

function Player:move(dx, dy)
    self.pos = self.pos + vector(dx, dy)
    if self.gameState and self.gameState.arena then
        self.pos.x = lume.clamp(self.pos.x, -PlayArea.SIZE / 2 + Player.WIDTH / 2, PlayArea.SIZE / 2 - Player.WIDTH / 2)
        self.pos.y = lume.clamp(self.pos.y, -PlayArea.SIZE / 2 + Player.HEIGHT / 2, PlayArea.SIZE / 2 - Player.HEIGHT / 2)
    end
end

local Dead = Player:addState('Dead')

function Dead:move(dx, dy) end

function Dead:enteredState()
    self.outline_time = 0
    if self.gameState.screenEffects then
        self.gameState.screenEffects:shake(30, 0.5)
        self.gameState.screenEffects:flash(1, 0.1, 0.1, 0.5, 0.3)
    end
end

function Dead:draw()
    Entity.draw(self)
    self:drawBody()

    love.graphics.setLineStyle('smooth')
    local pulse = 1 + self.outline_time * 0.5

    love.graphics.push()
    love.graphics.translate(self.pos:unpack())
    love.graphics.rotate(self.angle)
    love.graphics.scale(pulse, 1.1 - self.outline_time * 0.1)

    love.graphics.setColor(1, 0.2, 0.2, (2.0 - self.outline_time) * 0.5)
    love.graphics.setLineWidth(4)
    love.graphics.polygon('line',
        -Player.WIDTH * 0.3, Player.HEIGHT * 0.12,
        -Player.WIDTH * 0.1, -Player.HEIGHT * 0.05,
        0, -Player.HEIGHT * 0.3,
        Player.WIDTH * 0.1, -Player.HEIGHT * 0.05,
        Player.WIDTH * 0.3, Player.HEIGHT * 0.12,
        Player.WIDTH * 0.3, Player.HEIGHT * 0.22,
        0, Player.HEIGHT * 0.12,
        -Player.WIDTH * 0.1, Player.HEIGHT * 0.22)

    love.graphics.setColor(1, 0.3, 0.3, (2.0 - self.outline_time) * 0.3)
    love.graphics.setLineWidth(8)
    love.graphics.polygon('line',
        -Player.WIDTH * 0.3, Player.HEIGHT * 0.12,
        -Player.WIDTH * 0.1, -Player.HEIGHT * 0.05,
        0, -Player.HEIGHT * 0.3,
        Player.WIDTH * 0.1, -Player.HEIGHT * 0.05,
        Player.WIDTH * 0.3, Player.HEIGHT * 0.12,
        Player.WIDTH * 0.1, Player.HEIGHT * 0.22,
        0, Player.HEIGHT * 0.12,
        -Player.WIDTH * 0.1, Player.HEIGHT * 0.22)

    love.graphics.pop()
end

function Dead:update(dt)
    Entity.update(self, dt)
    self.outline_time = self.outline_time + dt * 2
    if self.outline_time > 2.0 then self.outline_time = 0 end
end

function Player:manualFire()
    if self.manualFireCooldown > 0 then return end
    if not self.gameState then return end
    if self.dead then return end

    self.manualFireCooldown = self.manualFireCooldownMax

    local target = nil
    if self.autoAimTarget and not self.autoAimTarget:isDead() then
        target = self.autoAimTarget
    else
        -- scan forward for nearest obstacle/enemy in narrow cone
        local forward = vector(math.sin(self.angle), -math.cos(self.angle))
        local bestDist = self.autoAimRange
        local scanTags = {'obstacle', 'enemy'}
        for _, tag in ipairs(scanTags) do
            for _, ent in ipairs(self.gameState:getEntitiesByTag(tag)) do
                if ent ~= self and not ent:isDead() then
                    local toTarget = ent.pos - self.pos
                    local dist = toTarget:len()
                    if dist < bestDist then
                        local dir = toTarget:normalized()
                        local dot = forward.x * dir.x + forward.y * dir.y
                        if dot > math.cos(math.rad(12)) then
                            bestDist = dist
                            target = ent
                        end
                    end
                end
            end
        end
    end

    local endPos = nil
    if not target then
        local forward = vector(math.sin(self.angle), -math.cos(self.angle))
        endPos = self.pos + forward * self.autoAimRange
    end

    local laser = Laser(self.pos:clone(), target, endPos)
    self.gameState:addEntity(laser)

    if self.doubleLaser then
        local offset = vector(8, 0)
        local laser2 = Laser(self.pos:clone() + offset, target, endPos and (endPos + offset) or nil)
        self.gameState:addEntity(laser2)
    end

    if self.gameState.screenEffects then
        self.gameState.screenEffects:shake(2, 0.05)
    end

    if self.gameState.audioManager then
        self.gameState.audioManager:playLaser()
    end
end

return Player
