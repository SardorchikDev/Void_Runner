-- NEW: Player laser beam. Visual beam appears first, then asteroid shatters after a brief delay.
Laser = class('Laser', Entity)

function Laser:initialize(sourcePos, target, endPos)
    Entity.initialize(self, 'laser', 0, sourcePos:clone())
    self.target = target
    self.endPos = endPos
    self.hitPos = nil
    self.hitDone = false

    self.life = 0.22
    self.maxLife = 0.22
    self.hitDelay = 0.06

    -- capture hit position immediately so beam stays locked
    if target and not target:isDead() then
        self.hitPos = target.pos:clone()
    elseif endPos then
        self.hitPos = endPos:clone()
    end
end

function Laser:update(dt)
    Entity.update(self, dt)
    self.life = self.life - dt

    -- hit target after brief delay so you see the beam connect first
    if not self.hitDone and self.hitPos then
        if self.life <= (self.maxLife - self.hitDelay) then
            self.hitDone = true
            if self.target and not self.target:isDead() then
                if self.target.takeDamage then
                    self.target:takeDamage(1)
                else
                    if self.target.shatterIntoDust then
                        self.target:shatterIntoDust()
                    end
                    if self.target.onDestroyed then
                        self.target:onDestroyed(self.gameState)
                    end
                    self.target:destroy()
                end
                if self.gameState then
                    if self.gameState.screenEffects then
                        self.gameState.screenEffects:shake(3, 0.08)
                    end
                    if self.gameState.onLaserKill then
                        self.gameState:onLaserKill(self.target)
                    end
                end
            end
        end
    end

    if self.life <= 0 then
        self:destroy()
    end
end

function Laser:draw()
    if not self.hitPos then return end

    local alpha = math.max(0, self.life / self.maxLife)
    local sx, sy = self.pos.x, self.pos.y
    local tx, ty = self.hitPos.x, self.hitPos.y

    -- glow bloom (widest)
    love.graphics.setColor(0.15, 0.45, 1.0, alpha * 0.15)
    love.graphics.setLineWidth(10)
    love.graphics.line(sx, sy, tx, ty)

    -- glow beam
    love.graphics.setColor(0.25, 0.6, 1.0, alpha * 0.4)
    love.graphics.setLineWidth(5)
    love.graphics.line(sx, sy, tx, ty)

    -- core beam
    love.graphics.setColor(0.5, 0.9, 1.0, alpha * 0.95)
    love.graphics.setLineWidth(2)
    love.graphics.line(sx, sy, tx, ty)

    -- center white hot core
    love.graphics.setColor(1, 1, 1, alpha * 0.8)
    love.graphics.setLineWidth(1)
    love.graphics.line(sx, sy, tx, ty)

    -- impact flash builds right before shatter, then fades
    local flashAlpha = alpha
    if not self.hitDone then
        -- intensify flash just before hit
        flashAlpha = math.min(1, flashAlpha * 1.5)
    end

    love.graphics.setColor(0.6, 0.95, 1.0, flashAlpha * 0.7)
    love.graphics.circle('fill', tx, ty, 6 * flashAlpha)
    love.graphics.setColor(1, 1, 1, flashAlpha * 0.9)
    love.graphics.circle('fill', tx, ty, 2.5 * flashAlpha)
end

return Laser
