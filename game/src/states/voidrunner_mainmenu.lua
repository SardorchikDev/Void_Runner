-- NEW: Main menu with animated space background.
VoidRunnerMainMenu = class('VoidRunnerMainMenu', GameState)

function VoidRunnerMainMenu:initialize()
    GameState.initialize(self)
    self.time = 0

    self.buttons = {
        {text = "PLAY",     action = function() GameState.switchTo(VoidRunnerPlayState()) end},
        {text = "SETTINGS", action = function() GameState.switchTo(SettingsMenu()) end},
        {text = "HELP",     action = function() GameState.switchTo(HelpMenu()) end},
        {text = "EXIT",     action = function() love.event.quit() end}
    }
    self.selected = 1

    self:resize(love.graphics.getWidth(), love.graphics.getHeight())
    self:initBackground()
end

function VoidRunnerMainMenu:initBackground()

    -- parallax star layers
    self.starLayers = {}
    for layer = 1, 3 do
        local count = 80 + layer * 60
        local speed = 4 + layer * 6
        local stars = {}
        for i = 1, count do
            table.insert(stars, {
                x = math.random() * self.w,
                y = math.random() * self.h,
                size = (0.5 + math.random() * 1.5) * (layer * 0.6),
                brightness = 0.3 + math.random() * 0.7,
                twinkleSpeed = 1 + math.random() * 3,
                twinkleOffset = math.random() * math.pi * 2,
            })
        end
        table.insert(self.starLayers, {speed = speed, stars = stars})
    end

    -- nebula clouds (subtle colored blobs)
    self.nebulas = {}
    for i = 1, 5 do
        table.insert(self.nebulas, {
            x = math.random() * self.w,
            y = math.random() * self.h,
            rx = 150 + math.random() * 300,
            ry = 80 + math.random() * 200,
            angle = math.random() * math.pi * 2,
            r = 0.05 + math.random() * 0.1,
            g = 0.08 + math.random() * 0.15,
            b = 0.2 + math.random() * 0.3,
            driftX = (math.random() - 0.5) * 3,
            driftY = (math.random() - 0.5) * 2,
        })
    end

    -- shooting stars
    self.shootingStars = {}
    self.shootingStarTimer = 0

    -- dust particles
    self.dust = {}
    for i = 1, 40 do
        table.insert(self.dust, {
            x = math.random() * self.w,
            y = math.random() * self.h,
            size = 0.5 + math.random() * 1.5,
            speed = 5 + math.random() * 15,
            alpha = 0.1 + math.random() * 0.2,
        })
    end
end

function VoidRunnerMainMenu:resize(w, h)
    self.w = w
    self.h = h
    self.scale = math.min(w / 1280, h / 720)

    self.title_font = love.graphics.newFont("assets/roboto.ttf", math.floor(64 * self.scale))
    self.title_font:setFilter('linear', 'linear', 0)

    self.btn_font = love.graphics.newFont("assets/roboto.ttf", math.floor(28 * self.scale))
    self.btn_font:setFilter('linear', 'linear', 0)

    self.small_font = love.graphics.newFont("assets/roboto.ttf", math.floor(14 * self.scale))
    self.small_font:setFilter('linear', 'linear', 0)
end

function VoidRunnerMainMenu:update(dt)
    GameState.update(self, dt)
    self.time = self.time + dt

    -- scroll stars
    for _, layer in ipairs(self.starLayers) do
        for _, star in ipairs(layer.stars) do
            star.y = star.y + layer.speed * dt
            if star.y > self.h then
                star.y = -2
                star.x = math.random() * self.w
            end
        end
    end

    -- drift nebulas
    for _, n in ipairs(self.nebulas) do
        n.x = n.x + n.driftX * dt
        n.y = n.y + n.driftY * dt
        if n.x < -400 then n.x = self.w + 400 end
        if n.x > self.w + 400 then n.x = -400 end
        if n.y < -300 then n.y = self.h + 300 end
        if n.y > self.h + 300 then n.y = -300 end
    end

    -- shooting stars
    self.shootingStarTimer = self.shootingStarTimer - dt
    if self.shootingStarTimer <= 0 then
        self.shootingStarTimer = 1.5 + math.random() * 3
        table.insert(self.shootingStars, {
            x = math.random() * self.w,
            y = math.random() * self.h * 0.5,
            speed = 300 + math.random() * 200,
            angle = math.pi * 0.75 + (math.random() - 0.5) * 0.3,
            life = 0.5 + math.random() * 0.3,
            maxLife = 0.5 + math.random() * 0.3,
        })
    end
    for i = #self.shootingStars, 1, -1 do
        local s = self.shootingStars[i]
        s.life = s.life - dt
        s.x = s.x + math.cos(s.angle) * s.speed * dt
        s.y = s.y + math.sin(s.angle) * s.speed * dt
        if s.life <= 0 then
            table.remove(self.shootingStars, i)
        end
    end

    -- dust particles
    for _, p in ipairs(self.dust) do
        p.y = p.y + p.speed * dt
        if p.y > self.h then
            p.y = -2
            p.x = math.random() * self.w
        end
    end
end

function VoidRunnerMainMenu:draw()
    local w, h = self.w, self.h
    local cx, cy = w / 2, h / 2
    local s = self.scale
    local pulse = math.sin(self.time * 3) * 0.12 + 0.88

    -- deep space base
    love.graphics.setColor(0.01, 0.015, 0.04, 1)
    love.graphics.rectangle('fill', 0, 0, w, h)

    -- subtle gradient overlay from bottom
    for i = 0, h, 2 do
        local t = i / h
        love.graphics.setColor(0.01, 0.02, 0.06, t * 0.3)
        love.graphics.rectangle('fill', 0, i, w, 2)
    end

    -- nebulas
    for _, n in ipairs(self.nebulas) do
        love.graphics.setColor(n.r, n.g, n.b, 0.15)
        love.graphics.ellipse('fill', n.x, n.y, n.rx, n.ry)
        love.graphics.setColor(n.r * 1.2, n.g * 1.2, n.b * 1.2, 0.08)
        love.graphics.ellipse('fill', n.x, n.y, n.rx * 0.6, n.ry * 0.6)
    end

    -- dust particles
    for _, p in ipairs(self.dust) do
        love.graphics.setColor(0.4, 0.5, 0.7, p.alpha)
        love.graphics.circle('fill', p.x, p.y, p.size)
    end

    -- shooting stars
    for _, ss in ipairs(self.shootingStars) do
        local alpha = math.max(0, ss.life / ss.maxLife)
        local tailLen = 40 * alpha
        local tx = ss.x - math.cos(ss.angle) * tailLen
        local ty = ss.y - math.sin(ss.angle) * tailLen
        love.graphics.setColor(0.6, 0.85, 1.0, alpha * 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.line(ss.x, ss.y, tx, ty)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.circle('fill', ss.x, ss.y, 2)
    end

    -- stars
    for _, layer in ipairs(self.starLayers) do
        for _, star in ipairs(layer.stars) do
            local twinkle = math.sin(self.time * star.twinkleSpeed + star.twinkleOffset) * 0.3 + 0.7
            local brightness = star.brightness * twinkle
            love.graphics.setColor(brightness, brightness, brightness * 1.1, brightness)
            love.graphics.circle('fill', star.x, star.y, star.size)
        end
    end

    -- vignette
    local vr = h * 0.7
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle('fill', cx, cy, vr)
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle('line', cx, cy, vr)

    -- dim overlay behind panel
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle('fill', 0, 0, w, h)

    -- center panel
    local panelW = 460 * s
    local panelH = 380 * s
    local px = cx - panelW / 2
    local py = cy - panelH / 2

    -- panel bg
    love.graphics.setColor(0.02, 0.03, 0.08, 0.85)
    love.graphics.rectangle('fill', px, py, panelW, panelH)
    -- panel border
    love.graphics.setColor(0.12, 0.35, 0.7, 0.4)
    love.graphics.setLineWidth(1.5 * s)
    love.graphics.rectangle('line', px, py, panelW, panelH)
    love.graphics.setColor(0.08, 0.2, 0.45, 0.12)
    love.graphics.rectangle('line', px + 2, py + 2, panelW - 4, panelH - 4)

    -- title glow (3-pass depth stack)
    love.graphics.setFont(self.title_font)
    love.graphics.setColor(0.05, 0.15, 0.4, 0.3 * pulse)
    love.graphics.printf("VOID RUNNER", 3 * s, py + 29 * s, w, "center")
    love.graphics.setColor(0.1, 0.3, 0.7, 0.5 * pulse)
    love.graphics.printf("VOID RUNNER", 1 * s, py + 27 * s, w, "center")
    love.graphics.setColor(0.45, 0.85, 1.0, 1.0 * pulse)
    love.graphics.printf("VOID RUNNER", 0, py + 26 * s, w, "center")

    -- pulsing ring behind subtitle
    local ringRadius = 40 + (math.sin(self.time * math.pi) * 10)
    love.graphics.setColor(0.2, 0.5, 1.0, 0.06)
    love.graphics.setLineWidth(1 * s)
    love.graphics.circle('line', cx, py + 100 * s, ringRadius * s)

    -- subtitle
    love.graphics.setFont(self.small_font)
    love.graphics.setColor(0.5, 0.7, 1.0, 0.55)
    love.graphics.printf("HOW DEEP CAN YOU GO?", 0, py + 94 * s, w, "center")

    -- buttons
    local btnW = 220 * s
    local btnH = 46 * s
    local btnGap = 14 * s
    local startY = py + 130 * s
    local bx = cx - btnW / 2

    for i, btn in ipairs(self.buttons) do
        local by = startY + (i - 1) * (btnH + btnGap)
        local sel = i == self.selected
        local r, g, b = 0.25, 0.65, 1.0

        love.graphics.setColor(0.04, 0.06, 0.14, 0.9)
        love.graphics.rectangle('fill', bx, by, btnW, btnH)
        love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, 0.5)
        love.graphics.setLineWidth(1.5 * s)
        love.graphics.rectangle('line', bx, by, btnW, btnH)

        if sel then
            love.graphics.setColor(r, g, b, pulse * 0.18)
            love.graphics.rectangle('fill', bx + 1, by + 1, btnW - 2, btnH - 2)
            love.graphics.setColor(r, g, b, 0.7)
            love.graphics.setLineWidth(2 * s)
            love.graphics.rectangle('line', bx - 1, by - 1, btnW + 2, btnH + 2)
            -- left accent bar
            love.graphics.setColor(r, g, b, 0.9)
            love.graphics.rectangle('fill', bx - 4 * s, by + 2, 2 * s, btnH - 4)
        end

        love.graphics.setFont(self.btn_font)
        love.graphics.setColor(r, g, b, sel and pulse or 0.75)
        love.graphics.printf(btn.text, bx, by + btnH / 2 - 12 * s, btnW, "center")
    end

    -- high score
    local saveFileInfo = love.filesystem.getInfo("bestscore")
    if saveFileInfo and saveFileInfo.type == "file" then
        local contents = love.filesystem.read("bestscore")
        local best = tonumber(contents)
        if best then
            love.graphics.setFont(self.small_font)
            love.graphics.setColor(1.0, 0.85, 0.2, 0.6)
            love.graphics.printf(string.format("BEST: %dm", math.floor(best)), 0, py + panelH - 42 * s, w, "center")
        end
    end

    -- controls hint
    love.graphics.setFont(self.small_font)
    love.graphics.setColor(0.3, 0.5, 0.7, 0.4)
    love.graphics.printf("ESC TO QUIT", 0, py + panelH - 22 * s, w, "center")
end

function VoidRunnerMainMenu:mousemoved(x, y)
    local s = self.scale
    local cx = self.w / 2
    local panelH = 380 * s
    local py = self.h / 2 - panelH / 2
    local btnW = 220 * s
    local btnH = 46 * s
    local btnGap = 14 * s
    local startY = py + 130 * s
    local bx = cx - btnW / 2

    self.selected = nil
    for i, btn in ipairs(self.buttons) do
        local by = startY + (i - 1) * (btnH + btnGap)
        if x >= bx and x <= bx + btnW and y >= by and y <= by + btnH then
            self.selected = i
            break
        end
    end
end

function VoidRunnerMainMenu:mousepressed(x, y, button)
    if button ~= 1 then return end
    self:mousemoved(x, y)
    if self.selected then
        self.buttons[self.selected].action()
    end
end

function VoidRunnerMainMenu:touchpressed(id, x, y)
    self:mousepressed(x, y, 1)
end

function VoidRunnerMainMenu:keypressed(key)
    if key == 'return' or key == 'space' then
        if self.selected then
            self.buttons[self.selected].action()
        end
    elseif key == 'up' or key == 'w' then
        self.selected = (self.selected or 1) - 1
        if self.selected < 1 then self.selected = #self.buttons end
    elseif key == 'down' or key == 's' then
        self.selected = (self.selected or 1) + 1
        if self.selected > #self.buttons then self.selected = 1 end
    elseif key == 'escape' then
        love.event.quit()
    elseif key == 'f3' then
        DEBUG = not DEBUG
    end
end

function VoidRunnerMainMenu:gamepadpressed(joystick, button)
    if button == 'a' or button == 'start' then
        if self.selected then
            self.buttons[self.selected].action()
        end
    elseif button == 'dpup' then
        self.selected = (self.selected or 1) - 1
        if self.selected < 1 then self.selected = #self.buttons end
    elseif button == 'dpdown' then
        self.selected = (self.selected or 1) + 1
        if self.selected > #self.buttons then self.selected = 1 end
    end
end

return VoidRunnerMainMenu
