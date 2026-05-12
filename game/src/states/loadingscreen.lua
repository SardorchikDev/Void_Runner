-- NEW: Loading screen that preps assets and transitions to main menu.
LoadingScreen = class('LoadingScreen', GameState)

function LoadingScreen:initialize()
    GameState.initialize(self)
    self.time = 0
    self.progress = 0
    self.done = false

    self.w = love.graphics.getWidth()
    self.h = love.graphics.getHeight()
    self.scale = math.min(self.w / 1280, self.h / 720)

    self.title_font = love.graphics.newFont("assets/roboto.ttf", math.floor(72 * self.scale))
    self.title_font:setFilter('linear', 'linear', 0)

    self.sub_font = love.graphics.newFont("assets/roboto.ttf", math.floor(18 * self.scale))
    self.sub_font:setFilter('linear', 'linear', 0)

    self.particles = {}
    for i = 1, 40 do
        table.insert(self.particles, {
            x = math.random() * self.w,
            y = math.random() * self.h,
            size = math.random(1, 3),
            speed = 8 + math.random() * 20,
            alpha = 0.1 + math.random() * 0.4,
            blink = math.random() * math.pi * 2
        })
    end

    -- fake loading stages
    self.stages = {
        "Collapsing spacetime...",
        "Forming event horizon...",
        "Calibrating singularity...",
        "Bending light...",
        "Ready"
    }
    self.currentStage = 1
end

function LoadingScreen:resize(w, h)
    self.w = w
    self.h = h
    self.scale = math.min(w / 1280, h / 720)

    self.title_font = love.graphics.newFont("assets/roboto.ttf", math.floor(72 * self.scale))
    self.title_font:setFilter('linear', 'linear', 0)

    self.sub_font = love.graphics.newFont("assets/roboto.ttf", math.floor(18 * self.scale))
    self.sub_font:setFilter('linear', 'linear', 0)
end

function LoadingScreen:update(dt)
    GameState.update(self, dt)
    self.time = self.time + dt

    for _, p in ipairs(self.particles) do
        p.y = p.y + p.speed * dt * self.scale
        if p.y > self.h then
            p.y = -10
            p.x = math.random() * self.w
        end
        p.blink = p.blink + dt * 2
    end

    if self.done then return end

    -- smooth progress
    local target = math.min(1, self.time / 2.5)
    self.progress = lume.lerp(self.progress, target, 5 * dt)

    -- stage updates
    if self.progress > 0.2 then self.currentStage = 2 end
    if self.progress > 0.45 then self.currentStage = 3 end
    if self.progress > 0.7 then self.currentStage = 4 end
    if self.progress > 0.92 then self.currentStage = 5 end

    if self.progress >= 0.99 and not self.done then
        self.done = true
        Timer.after(0.3, function()
            GameState.switchTo(SingularityMenu())
        end)
    end
end

function LoadingScreen:draw()
    local w, h = self.w, self.h
    local s = self.scale
    local cx, cy = w / 2, h / 2
    local pulse = math.sin(self.time * 2.5) * 0.08 + 0.92

    -- bg
    for y = 0, h, 4 do
        local t = y / h
        love.graphics.setColor(0.01 + t * 0.02, 0.01 + t * 0.03, 0.04 + t * 0.06, 1)
        love.graphics.rectangle('fill', 0, y, w, 4)
    end

    -- particles
    for _, p in ipairs(self.particles) do
        local a = p.alpha * (0.7 + 0.3 * math.sin(p.blink)) * pulse
        love.graphics.setColor(0.5, 0.75, 1.0, a)
        love.graphics.circle('fill', p.x, p.y, p.size * s)
    end

    -- title
    for i = 3, 1, -1 do
        local offset = i * 3 * s
        local alpha = (1 - i / 4) * 0.12 * pulse
        love.graphics.setColor(0.15, 0.45, 1.0, alpha)
        love.graphics.setFont(self.title_font)
        love.graphics.printf("SINGULARITY", offset, cy - 80 * s - offset * 0.2, w, "center")
    end
    love.graphics.setColor(0.35, 0.7, 1.0, 1)
    love.graphics.setFont(self.title_font)
    love.graphics.printf("SINGULARITY", 0, cy - 80 * s, w, "center")

    -- progress bar bg
    local barW = 320 * s
    local barH = 8 * s
    local barX = cx - barW / 2
    local barY = cy + 20 * s

    love.graphics.setColor(0.06, 0.08, 0.16, 0.9)
    love.graphics.rectangle('fill', barX, barY, barW, barH, 4 * s, 4 * s)

    love.graphics.setColor(0.15, 0.35, 0.7, 0.5)
    love.graphics.setLineWidth(1.5 * s)
    love.graphics.rectangle('line', barX, barY, barW, barH, 4 * s, 4 * s)

    -- progress fill
    local fillW = barW * self.progress
    if fillW > 0 then
        love.graphics.setColor(0.25, 0.6, 1.0, 0.85)
        love.graphics.rectangle('fill', barX, barY, fillW, barH, 4 * s, 4 * s)

        -- glow tip
        love.graphics.setColor(0.4, 0.8, 1.0, 0.4)
        love.graphics.circle('fill', barX + fillW, barY + barH / 2, 6 * s)
    end

    -- percentage
    love.graphics.setFont(self.sub_font)
    love.graphics.setColor(0.5, 0.75, 1.0, 0.7)
    love.graphics.printf(string.format("%d%%", math.floor(self.progress * 100)), 0, barY + 18 * s, w, "center")

    -- stage text
    local stageText = self.stages[self.currentStage] or ""
    local stageAlpha = 0.5 + 0.5 * math.sin(self.time * 4)
    love.graphics.setColor(0.4, 0.65, 1.0, stageAlpha)
    love.graphics.printf(stageText, 0, barY + 38 * s, w, "center")

    -- controls hint
    love.graphics.setColor(0.3, 0.5, 0.7, 0.35)
    love.graphics.printf("MOUSE TO MOVE  |  HOLD SPACE TO PULL  |  BECOME THE VOID", 0, h - 22 * s, w, "center")
end

function LoadingScreen:keypressed(key)
    if key == 'return' or key == 'space' or key == 'escape' then
        self.progress = 1
        self.done = true
        Timer.after(0.1, function()
            GameState.switchTo(SingularityMenu())
        end)
    end
end

function LoadingScreen:mousepressed(x, y, button)
    self.progress = 1
    self.done = true
    Timer.after(0.1, function()
        GameState.switchTo(SingularityMenu())
    end)
end

function LoadingScreen:touchpressed(id, x, y)
    self:mousepressed(x, y, 1)
end

return LoadingScreen
