-- NEW: Help / Codex menu documenting game features, turned the asteroid collision glitch into a feature.
HelpMenu = class('HelpMenu', GameState)

function HelpMenu:initialize()
    GameState.initialize(self)
    self.time = 0
    self.parallax = ParallaxStars()
    self.parallax:setGameState(self)
    self.parallax:start()

    self.page = 1
    self.pages = {"CONTROLS", "SHIP", "ASTEROIDS", "ENEMIES", "ZONES"}

    self:resize(love.graphics.getWidth(), love.graphics.getHeight())
end

function HelpMenu:resize(w, h)
    self.w = w
    self.h = h
    self.scale = math.min(w / 1280, h / 720)

    self.title_font = love.graphics.newFont("assets/roboto.ttf", math.floor(48 * self.scale))
    self.title_font:setFilter('linear', 'linear', 0)

    self.tab_font = love.graphics.newFont("assets/roboto.ttf", math.floor(18 * self.scale))
    self.tab_font:setFilter('linear', 'linear', 0)

    self.body_font = love.graphics.newFont("assets/roboto.ttf", math.floor(17 * self.scale))
    self.body_font:setFilter('linear', 'linear', 0)

    self.small_font = love.graphics.newFont("assets/roboto.ttf", math.floor(14 * self.scale))
    self.small_font:setFilter('linear', 'linear', 0)
end

function HelpMenu:update(dt)
    GameState.update(self, dt)
    self.time = self.time + dt
    self.parallax:update(dt)
end

function HelpMenu:draw()
    self.cam:attach()
    self.parallax:draw()
    self.cam:detach()

    local w, h = self.w, self.h
    local cx, cy = w / 2, h / 2
    local s = self.scale
    local pulse = math.sin(self.time * 2.5) * 0.08 + 0.92

    -- panel bg
    local panelW = 760 * s
    local panelH = 520 * s
    local px = cx - panelW / 2
    local py = cy - panelH / 2 - 10 * s

    love.graphics.setColor(0.02, 0.03, 0.08, 0.82)
    love.graphics.rectangle('fill', px, py, panelW, panelH)
    love.graphics.setColor(0.12, 0.35, 0.7, 0.4)
    love.graphics.setLineWidth(1.5 * s)
    love.graphics.rectangle('line', px, py, panelW, panelH)
    love.graphics.setColor(0.08, 0.2, 0.45, 0.15)
    love.graphics.rectangle('line', px + 2, py + 2, panelW - 4, panelH - 4)

    -- title
    love.graphics.setColor(0.35, 0.75, 1.0, 0.9)
    love.graphics.setFont(self.title_font)
    love.graphics.printf("CODEX", 0, py + 18 * s, w, "center")

    -- tabs
    local tabCount = #self.pages
    local tabW = panelW / tabCount
    local tabH = 36 * s
    local tabY = py + 72 * s

    for i, tabName in ipairs(self.pages) do
        local tx = px + (i - 1) * tabW
        local sel = i == self.page

        if sel then
            love.graphics.setColor(0.08, 0.2, 0.5, 0.7)
            love.graphics.rectangle('fill', tx, tabY, tabW, tabH)
            love.graphics.setColor(0.35, 0.7, 1.0, 0.8)
            love.graphics.setLineWidth(2 * s)
            love.graphics.rectangle('line', tx, tabY, tabW, tabH)
        else
            love.graphics.setColor(0.04, 0.06, 0.14, 0.6)
            love.graphics.rectangle('fill', tx, tabY, tabW, tabH)
            love.graphics.setColor(0.15, 0.35, 0.6, 0.35)
            love.graphics.setLineWidth(1 * s)
            love.graphics.rectangle('line', tx, tabY, tabW, tabH)
        end

        love.graphics.setFont(self.tab_font)
        love.graphics.setColor(0.3, 0.75, 1.0, sel and 1 or 0.55)
        love.graphics.printf(tabName, tx, tabY + tabH / 2 - 10 * s, tabW, "center")
    end

    -- content area
    local contentY = tabY + tabH + 14 * s
    local contentH = panelH - (tabY - py) - tabH - 60 * s
    local margin = 28 * s

    love.graphics.setFont(self.body_font)
    love.graphics.setColor(0.7, 0.85, 1.0, 0.85)

    local function drawLine(text, yOff)
        love.graphics.printf(text, px + margin, contentY + yOff, panelW - margin * 2, "left")
    end

    local function drawHeader(text, yOff)
        love.graphics.setColor(0.35, 0.75, 1.0, 0.95)
        love.graphics.printf(text, px + margin, contentY + yOff, panelW - margin * 2, "left")
        love.graphics.setColor(0.7, 0.85, 1.0, 0.85)
    end

    if self.page == 1 then
        drawHeader("CONTROLS", 0)
        drawLine("", 22 * s)
        drawLine("MOUSE MOVE     -  Your ship follows the cursor smoothly.", 42 * s)
        drawLine("RIGHT CLICK    -  Activate Time Warp (slows time briefly).", 68 * s)
        drawLine("ESC            -  Pause / Resume the run.", 94 * s)
        drawLine("", 120 * s)
        drawLine("KEYBOARD (fallback):", 142 * s)
        drawLine("WASD / ARROWS  -  Thrust in that direction.", 166 * s)
        drawLine("SPACE          -  Activate Time Warp.", 192 * s)
        drawLine("ENTER          -  Start game from menus.", 218 * s)

    elseif self.page == 2 then
        drawHeader("SHIP: VOID RUNNER", 0)
        drawLine("", 22 * s)
        drawLine("A nimble scout vessel retrofitted for deep-void exploration.", 42 * s)
        drawLine("Its engines leave a multi-layered ion trail as it carves", 66 * s)
        drawLine("through asteroid fields.", 90 * s)
        drawLine("", 116 * s)
        drawLine("ABILITIES:", 138 * s)
        drawLine("- Cursor Tracking: The ship rotates to face your mouse.", 162 * s)
        drawLine("- Speed Cap: Max velocity limited for controlled evasion.", 186 * s)
        drawLine("- Time Warp: Briefly slow down everything around you.", 210 * s)
        drawLine("- Afterimages: Ghost trails echo your last 22 positions.", 234 * s)

    elseif self.page == 3 then
        drawHeader("ASTEROIDS", 0)
        drawLine("", 22 * s)
        drawLine("Solid Mass Physics (FEATURE):", 42 * s)
        drawLine("Asteroids now collide and push each other apart instead of", 66 * s)
        drawLine("phasing through. They form dynamic clusters and collision", 90 * s)
        drawLine("chains that change the flow of every run.", 114 * s)
        drawLine("", 140 * s)
        drawLine("- Rotate and tumble as they fall.", 162 * s)
        drawLine("- Cratered polygons with zone-based coloring.", 186 * s)
        drawLine("- Clusters spawn linked together in debris fields.", 210 * s)
        drawLine("- Warning indicators appear when one is about to enter view.", 234 * s)

    elseif self.page == 4 then
        drawHeader("ENEMIES", 0)
        drawLine("", 22 * s)
        drawLine("SCOUT DRONE:", 42 * s)
        drawLine("Fast, fragile drone that sweeps in from the sides.", 66 * s)
        drawLine("Dodges slightly toward your position.", 90 * s)
        drawLine("", 116 * s)
        drawLine("DREADNOUGHT:", 138 * s)
        drawLine("Heavy armored cruiser that spawns at the top.", 162 * s)
        drawLine("Fires targeted projectiles. Destroy it before it locks on.", 186 * s)
        drawLine("", 212 * s)
        drawLine("PROJECTILES:", 234 * s)
        drawLine("Red energy bolts. One hit = ship destroyed (unless shielded).", 258 * s)

    elseif self.page == 5 then
        drawHeader("ZONES", 0)
        drawLine("", 22 * s)
        drawLine("ZONE 1  -  ASTEROID FIELD", 42 * s)
        drawLine("Calm entry. Sparse rocks. Learn the drift.", 66 * s)
        drawLine("", 90 * s)
        drawLine("ZONE 2  -  DEBRIS ZONE", 110 * s)
        drawLine("Denser clusters. Slightly faster rocks. First real test.", 134 * s)
        drawLine("", 158 * s)
        drawLine("ZONE 3  -  HOSTILE TERRITORY", 178 * s)
        drawLine("Enemies appear. Scout drones begin sweeping the lanes.", 202 * s)
        drawLine("", 226 * s)
        drawLine("ZONE 4  -  GRAVITATIONAL STORM", 246 * s)
        drawLine("Chaos color shifts. Dreadnoughts spawn. Storm overlay.", 270 * s)
        drawLine("", 294 * s)
        drawLine("ZONE 5  -  THE VOID", 314 * s)
        drawLine("Everything is faster, denser, deadlier. No escape.", 338 * s)
    end

    -- back button
    local backW = 160 * s
    local backH = 40 * s
    local backX = cx - backW / 2
    local backY = py + panelH - backH - 16 * s

    love.graphics.setColor(0.04, 0.06, 0.14, 0.9)
    love.graphics.rectangle('fill', backX, backY, backW, backH)
    love.graphics.setColor(0.15, 0.35, 0.7, 0.5)
    love.graphics.setLineWidth(1.5 * s)
    love.graphics.rectangle('line', backX, backY, backW, backH)

    if self.backHovered then
        love.graphics.setColor(0.2, 0.5, 1.0, 0.18)
        love.graphics.rectangle('fill', backX + 1, backY + 1, backW - 2, backH - 2)
        love.graphics.setColor(0.35, 0.65, 1.0, 0.6)
        love.graphics.setLineWidth(2 * s)
        love.graphics.rectangle('line', backX - 1, backY - 1, backW + 2, backH + 2)
    end

    love.graphics.setFont(self.tab_font)
    love.graphics.setColor(0.3, 0.75, 1.0, self.backHovered and pulse or 0.75)
    love.graphics.printf("BACK", backX, backY + backH / 2 - 10 * s, backW, "center")
end

function HelpMenu:mousemoved(x, y)
    local s = self.scale
    local w, h = self.w, self.h
    local cx = w / 2
    local panelW = 760 * s
    local panelH = 520 * s
    local px = cx - panelW / 2
    local py = h / 2 - panelH / 2 - 10 * s

    local tabCount = #self.pages
    local tabW = panelW / tabCount
    local tabH = 36 * s
    local tabY = py + 72 * s

    self.backHovered = false
    for i = 1, tabCount do
        local tx = px + (i - 1) * tabW
        if x >= tx and x <= tx + tabW and y >= tabY and y <= tabY + tabH then
            -- tab hover doesn't switch page, only click
        end
    end

    local backW = 160 * s
    local backH = 40 * s
    local backX = cx - backW / 2
    local backY = py + panelH - backH - 16 * s
    if x >= backX and x <= backX + backW and y >= backY and y <= backY + backH then
        self.backHovered = true
    end
end

function HelpMenu:mousepressed(x, y, button)
    if button ~= 1 then return end
    local s = self.scale
    local w, h = self.w, self.h
    local cx = w / 2
    local panelW = 760 * s
    local panelH = 520 * s
    local px = cx - panelW / 2
    local py = h / 2 - panelH / 2 - 10 * s

    -- tabs
    local tabCount = #self.pages
    local tabW = panelW / tabCount
    local tabH = 36 * s
    local tabY = py + 72 * s
    for i = 1, tabCount do
        local tx = px + (i - 1) * tabW
        if x >= tx and x <= tx + tabW and y >= tabY and y <= tabY + tabH then
            self.page = i
            return
        end
    end

    -- back
    local backW = 160 * s
    local backH = 40 * s
    local backX = cx - backW / 2
    local backY = py + panelH - backH - 16 * s
    if x >= backX and x <= backX + backW and y >= backY and y <= backY + backH then
        GameState.switchTo(VoidRunnerMainMenu())
    end
end

function HelpMenu:touchpressed(id, x, y)
    self:mousepressed(x, y, 1)
end

function HelpMenu:keypressed(key)
    if key == 'escape' then
        GameState.switchTo(VoidRunnerMainMenu())
    elseif key == 'left' or key == 'a' then
        self.page = math.max(1, self.page - 1)
    elseif key == 'right' or key == 'd' then
        self.page = math.min(#self.pages, self.page + 1)
    elseif key == 'return' or key == 'space' then
        if self.backHovered then
            GameState.switchTo(VoidRunnerMainMenu())
        end
    elseif key == 'up' or key == 'w' then
        self.backHovered = true
    elseif key == 'down' or key == 's' then
        self.backHovered = false
    end
end

function HelpMenu:gamepadpressed(joystick, button)
    if button == 'b' or button == 'back' then
        GameState.switchTo(VoidRunnerMainMenu())
    elseif button == 'dpleft' or button == 'leftshoulder' then
        self.page = math.max(1, self.page - 1)
    elseif button == 'dpright' or button == 'rightshoulder' then
        self.page = math.min(#self.pages, self.page + 1)
    elseif button == 'a' then
        if self.backHovered then
            GameState.switchTo(VoidRunnerMainMenu())
        end
    end
end

return HelpMenu
