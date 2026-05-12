SingularityMenu = class('SingularityMenu', GameState)

function SingularityMenu:initialize()
    GameState.initialize(self)
    self.time = 0

    self.w = love.graphics.getWidth()
    self.h = love.graphics.getHeight()
    self.scale = math.min(self.w / 1280, self.h / 720)

    self.title_font = love.graphics.newFont("assets/roboto.ttf", math.floor(80 * self.scale))
    self.title_font:setFilter('linear', 'linear', 0)
    self.sub_font = love.graphics.newFont("assets/roboto.ttf", math.floor(20 * self.scale))
    self.sub_font:setFilter('linear', 'linear', 0)
    self.btn_font = love.graphics.newFont("assets/roboto.ttf", math.floor(28 * self.scale))
    self.btn_font:setFilter('linear', 'linear', 0)
    self.help_font = love.graphics.newFont("assets/roboto.ttf", math.floor(16 * self.scale))
    self.help_font:setFilter('linear', 'linear', 0)

    self.buttons = {
        {text = "PLAY", action = function() GameState.switchTo(SingularityPlay()) end},
        {text = "HELP", action = function() self.showHelp = not self.showHelp end},
        {text = "EXIT", action = function() love.event.quit() end}
    }
    self.selected = 1
    self.showHelp = false

    -- background stars that get pulled toward center
    self.stars = {}
    for i = 1, 200 do
        local angle = math.random() * math.pi * 2
        local dist = 100 + math.random() * 800
        table.insert(self.stars, {
            angle = angle,
            dist = dist,
            baseDist = dist,
            size = 0.5 + math.random() * 2,
            speed = 0.3 + math.random() * 0.7,
            alpha = 0.15 + math.random() * 0.6
        })
    end

    -- event horizon rings
    self.rings = {}
    for i = 1, 5 do
        table.insert(self.rings, {
            radius = 30 + i * 25,
            phase = i * 0.5,
            alpha = 0.15 - i * 0.02
        })
    end

    love.mouse.setVisible(true)
    love.mouse.setGrabbed(false)
end

function SingularityMenu:enter()
    love.mouse.setVisible(true)
    love.mouse.setGrabbed(false)
end

function SingularityMenu:resize(w, h)
    self.w = w
    self.h = h
    self.scale = math.min(w / 1280, h / 720)
    self.title_font = love.graphics.newFont("assets/roboto.ttf", math.floor(80 * self.scale))
    self.sub_font = love.graphics.newFont("assets/roboto.ttf", math.floor(20 * self.scale))
    self.btn_font = love.graphics.newFont("assets/roboto.ttf", math.floor(28 * self.scale))
    self.help_font = love.graphics.newFont("assets/roboto.ttf", math.floor(16 * self.scale))
end

function SingularityMenu:update(dt)
    GameState.update(self, dt)
    self.time = self.time + dt

    local cx, cy = self.w / 2, self.h / 2
    for _, star in ipairs(self.stars) do
        star.dist = star.dist - star.speed * 40 * dt
        if star.dist < 5 then
            star.dist = star.baseDist
            star.angle = math.random() * math.pi * 2
        end
    end
end

function SingularityMenu:draw()
    local w, h = self.w, self.h
    local s = self.scale
    local cx, cy = w / 2, h / 2
    local pulse = math.sin(self.time * 1.5) * 0.15 + 0.85

    -- deep space background
    for y = 0, h, 4 do
        local t = y / h
        love.graphics.setColor(0.01 + t * 0.015, 0.005 + t * 0.01, 0.03 + t * 0.05, 1)
        love.graphics.rectangle('fill', 0, y, w, 4)
    end

    -- stars flowing toward center
    for _, star in ipairs(self.stars) do
        local sx = cx + math.cos(star.angle) * star.dist
        local sy = cy + math.sin(star.angle) * star.dist
        if sx > 0 and sx < w and sy > 0 and sy < h then
            local distFade = math.min(1, star.dist / 200)
            local a = star.alpha * distFade * pulse
            local closeness = 1 - math.min(1, star.dist / star.baseDist)
            local r = 0.5 + closeness * 0.3
            local g = 0.4 + closeness * 0.2
            local b = 1.0
            love.graphics.setColor(r, g, b, a)
            love.graphics.circle('fill', sx, sy, star.size * s * (1 + closeness * 0.5))
        end
    end

    -- central singularity glow
    for i = 6, 1, -1 do
        local r = (20 + i * 30) * s * pulse
        local a = 0.04 / i
        love.graphics.setColor(0.4, 0.2, 0.9, a)
        love.graphics.circle('fill', cx, cy - 40 * s, r)
    end

    -- event horizon rings
    for _, ring in ipairs(self.rings) do
        local r = ring.radius * s * (0.9 + 0.1 * math.sin(self.time * 2 + ring.phase))
        love.graphics.setColor(0.5, 0.3, 1.0, ring.alpha * pulse)
        love.graphics.setLineWidth(1.5 * s)
        love.graphics.circle('line', cx, cy - 40 * s, r)
    end

    -- core
    love.graphics.setColor(0.8, 0.7, 1.0, 0.9 * pulse)
    love.graphics.circle('fill', cx, cy - 40 * s, 4 * s)

    -- title glow layers
    love.graphics.setFont(self.title_font)
    for i = 3, 1, -1 do
        local offset = i * 2 * s
        local alpha = (1 - i / 4) * 0.08 * pulse
        love.graphics.setColor(0.5, 0.2, 1.0, alpha)
        love.graphics.printf("SINGULARITY", offset, cy - 140 * s, w, "center")
    end
    love.graphics.setColor(0.7, 0.5, 1.0, 1)
    love.graphics.printf("SINGULARITY", 0, cy - 140 * s, w, "center")

    -- subtitle
    love.graphics.setFont(self.sub_font)
    love.graphics.setColor(0.5, 0.35, 0.8, 0.6 + 0.3 * math.sin(self.time * 2))
    love.graphics.printf("BECOME THE VOID", 0, cy - 60 * s, w, "center")

    if self.showHelp then
        self:drawHelp()
        return
    end

    -- buttons
    local btnW = 240 * s
    local btnH = 50 * s
    local startY = cy + 40 * s

    love.graphics.setFont(self.btn_font)
    for i, btn in ipairs(self.buttons) do
        local bx = cx - btnW / 2
        local by = startY + (i - 1) * (btnH + 12 * s)
        local hover = i == self.selected

        if hover then
            love.graphics.setColor(0.4, 0.2, 0.8, 0.25)
            love.graphics.rectangle('fill', bx, by, btnW, btnH, 6 * s, 6 * s)
            love.graphics.setColor(0.6, 0.4, 1.0, 0.8)
            love.graphics.setLineWidth(2 * s)
            love.graphics.rectangle('line', bx, by, btnW, btnH, 6 * s, 6 * s)
            love.graphics.setColor(0.8, 0.7, 1.0, 1)
        else
            love.graphics.setColor(0.15, 0.1, 0.25, 0.5)
            love.graphics.rectangle('fill', bx, by, btnW, btnH, 6 * s, 6 * s)
            love.graphics.setColor(0.3, 0.2, 0.5, 0.4)
            love.graphics.setLineWidth(1.5 * s)
            love.graphics.rectangle('line', bx, by, btnW, btnH, 6 * s, 6 * s)
            love.graphics.setColor(0.5, 0.4, 0.7, 0.7)
        end
        love.graphics.printf(btn.text, bx, by + btnH / 2 - self.btn_font:getHeight() / 2, btnW, "center")
    end

    -- controls hint
    love.graphics.setFont(self.help_font)
    love.graphics.setColor(0.4, 0.3, 0.6, 0.35)
    love.graphics.printf("MOUSE TO MOVE  |  SPACE / LEFT CLICK TO PULL  |  ESC TO PAUSE", 0, h - 28 * s, w, "center")
end

function SingularityMenu:drawHelp()
    local w, h = self.w, self.h
    local s = self.scale
    local cx = w / 2

    -- help overlay
    love.graphics.setColor(0.02, 0.01, 0.05, 0.92)
    love.graphics.rectangle('fill', 0, 0, w, h)

    love.graphics.setFont(self.btn_font)
    love.graphics.setColor(0.7, 0.5, 1.0, 1)
    love.graphics.printf("HOW TO PLAY", 0, 60 * s, w, "center")

    love.graphics.setFont(self.help_font)
    local lines = {
        "",
        "You are a SINGULARITY — a cosmic black hole.",
        "",
        "MOVE your mouse to glide through space.",
        "",
        "Hold SPACE or LEFT CLICK to activate your GRAVITATIONAL PULL.",
        "Everything nearby is drawn toward you.",
        "",
        "Enemies that COLLIDE with each other are destroyed in CHAIN REACTIONS.",
        "Chain reactions give you massive score multipliers!",
        "",
        "Enemies that reach you WHILE PULLING are ABSORBED for points.",
        "But if they touch you WITHOUT pull active, you take DAMAGE.",
        "",
        "ENERGY depletes while pulling and recharges when idle.",
        "Manage your energy wisely!",
        "",
        "Survive the waves. Chase the high score.",
        "",
        "CONTROLS:",
        "  Mouse ........... Move",
        "  Space / LMB ..... Activate Pull",
        "  Escape .......... Pause",
        "  F3 .............. FPS Counter",
        "",
        "Press ESC or click to return."
    }

    local y = 100 * s
    for _, line in ipairs(lines) do
        if line:find("CONTROLS:") or line:find("SINGULARITY") or line:find("GRAVITATIONAL") or line:find("CHAIN REACTIONS") or line:find("ABSORBED") or line:find("DAMAGE") then
            love.graphics.setColor(0.7, 0.5, 1.0, 0.9)
        else
            love.graphics.setColor(0.6, 0.55, 0.8, 0.75)
        end
        love.graphics.printf(line, 80 * s, y, w - 160 * s, "left")
        y = y + 20 * s
    end
end

function SingularityMenu:keypressed(key)
    if self.showHelp then
        self.showHelp = false
        return
    end

    if key == 'up' or key == 'w' then
        self.selected = math.max(1, self.selected - 1)
    elseif key == 'down' or key == 's' then
        self.selected = math.min(#self.buttons, self.selected + 1)
    elseif key == 'return' or key == 'space' then
        self.buttons[self.selected].action()
    elseif key == 'escape' then
        love.event.quit()
    end
end

function SingularityMenu:mousepressed(x, y, button)
    if self.showHelp then
        self.showHelp = false
        return
    end

    if button == 1 then
        local s = self.scale
        local cx = self.w / 2
        local btnW = 240 * s
        local btnH = 50 * s
        local startY = self.h / 2 + 40 * s

        for i, btn in ipairs(self.buttons) do
            local bx = cx - btnW / 2
            local by = startY + (i - 1) * (btnH + 12 * s)
            if x >= bx and x <= bx + btnW and y >= by and y <= by + btnH then
                btn.action()
                return
            end
        end
    end
end

function SingularityMenu:mousemoved(x, y)
    local s = self.scale
    local cx = self.w / 2
    local btnW = 240 * s
    local btnH = 50 * s
    local startY = self.h / 2 + 40 * s

    for i, btn in ipairs(self.buttons) do
        local bx = cx - btnW / 2
        local by = startY + (i - 1) * (btnH + 12 * s)
        if x >= bx and x <= bx + btnW and y >= by and y <= by + btnH then
            self.selected = i
            return
        end
    end
end

return SingularityMenu
