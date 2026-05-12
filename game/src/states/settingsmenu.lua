-- Settings menu for volume control, fullscreen toggle, and resolution.
SettingsMenu = class('SettingsMenu', GameState)

function SettingsMenu:initialize()
    GameState.initialize(self)
    self.time = 0
    self.w = love.graphics.getWidth()
    self.h = love.graphics.getHeight()
    self.scale = math.min(self.w / 1280, self.h / 720)

    self.title_font = love.graphics.newFont("assets/roboto.ttf", math.floor(42 * self.scale))
    self.title_font:setFilter('linear', 'linear', 0)
    self.label_font = love.graphics.newFont("assets/roboto.ttf", math.floor(20 * self.scale))
    self.label_font:setFilter('linear', 'linear', 0)
    self.value_font = love.graphics.newFont("assets/roboto.ttf", math.floor(18 * self.scale))
    self.value_font:setFilter('linear', 'linear', 0)

    self.audioManager = AudioManager()

    self.items = {
        {label = "MASTER VOLUME", type = "slider", get = function() return self.audioManager.masterVolume end,
         set = function(v) self.audioManager:setMasterVolume(v) end},
        {label = "MUSIC VOLUME", type = "slider", get = function() return self.audioManager.musicVolume end,
         set = function(v) self.audioManager:setMusicVolume(v) end},
        {label = "SFX VOLUME", type = "slider", get = function() return self.audioManager.sfxVolume end,
         set = function(v) self.audioManager:setSfxVolume(v) end},
        {label = "FULLSCREEN", type = "toggle", get = function() return love.window.getFullscreen() end,
         set = function()
            local fs = love.window.getFullscreen()
            love.window.setFullscreen(not fs)
            self:onResize()
         end},
        {label = "BACK", type = "button", action = function()
            GameState.switchTo(VoidRunnerMainMenu())
        end},
    }
    self.selected = 1
    self.dragging = false

    self.particles = {}
    for i = 1, 30 do
        table.insert(self.particles, {
            x = math.random() * self.w,
            y = math.random() * self.h,
            size = math.random(1, 2),
            speed = 5 + math.random() * 15,
            alpha = 0.1 + math.random() * 0.3,
        })
    end
end

function SettingsMenu:onResize()
    self.w = love.graphics.getWidth()
    self.h = love.graphics.getHeight()
    self.scale = math.min(self.w / 1280, self.h / 720)
    self.title_font = love.graphics.newFont("assets/roboto.ttf", math.floor(42 * self.scale))
    self.title_font:setFilter('linear', 'linear', 0)
    self.label_font = love.graphics.newFont("assets/roboto.ttf", math.floor(20 * self.scale))
    self.label_font:setFilter('linear', 'linear', 0)
    self.value_font = love.graphics.newFont("assets/roboto.ttf", math.floor(18 * self.scale))
    self.value_font:setFilter('linear', 'linear', 0)
end

function SettingsMenu:resize(w, h)
    self:onResize()
end

function SettingsMenu:update(dt)
    GameState.update(self, dt)
    self.time = self.time + dt
    for _, p in ipairs(self.particles) do
        p.y = p.y + p.speed * dt * self.scale
        if p.y > self.h then
            p.y = -5
            p.x = math.random() * self.w
        end
    end
end

function SettingsMenu:draw()
    local w, h = self.w, self.h
    local s = self.scale
    local cx = w / 2

    -- bg gradient
    for y = 0, h, 4 do
        local t = y / h
        love.graphics.setColor(0.01 + t * 0.02, 0.01 + t * 0.03, 0.04 + t * 0.06, 1)
        love.graphics.rectangle('fill', 0, y, w, 4)
    end

    for _, p in ipairs(self.particles) do
        love.graphics.setColor(0.5, 0.75, 1.0, p.alpha)
        love.graphics.circle('fill', p.x, p.y, p.size * s)
    end

    -- title
    love.graphics.setColor(0.35, 0.7, 1.0, 1)
    love.graphics.setFont(self.title_font)
    love.graphics.printf("SETTINGS", 0, 40 * s, w, "center")

    -- items
    local startY = 130 * s
    local itemH = 60 * s
    local barW = 240 * s
    local barH = 10 * s

    for i, item in ipairs(self.items) do
        local y = startY + (i - 1) * itemH
        local sel = (i == self.selected)

        local labelColor = sel and {0.35, 0.8, 1.0, 1} or {0.5, 0.6, 0.7, 0.8}
        love.graphics.setColor(unpack(labelColor))
        love.graphics.setFont(self.label_font)

        if item.type == "slider" then
            love.graphics.printf(item.label, cx - barW - 80 * s, y + 2, barW + 60 * s, "right")

            local val = item.get()
            local barX = cx + 20 * s
            local barY = y + 8

            love.graphics.setColor(0.1, 0.15, 0.25, 0.8)
            love.graphics.rectangle('fill', barX, barY, barW, barH, 4, 4)

            love.graphics.setColor(0.25, 0.6, 1.0, sel and 0.9 or 0.5)
            love.graphics.rectangle('fill', barX, barY, barW * val, barH, 4, 4)

            if sel then
                love.graphics.setColor(0.4, 0.8, 1.0, 0.8)
                love.graphics.circle('fill', barX + barW * val, barY + barH / 2, 8 * s)
            end

            love.graphics.setColor(0.7, 0.8, 0.9, 0.6)
            love.graphics.setFont(self.value_font)
            love.graphics.printf(string.format("%d%%", math.floor(val * 100)), barX + barW + 10 * s, y + 2, 60 * s, "left")

        elseif item.type == "toggle" then
            love.graphics.printf(item.label, cx - barW - 80 * s, y + 2, barW + 60 * s, "right")

            local on = item.get()
            local toggleX = cx + 20 * s
            love.graphics.setColor(on and {0.25, 0.8, 0.4} or {0.4, 0.2, 0.2})
            love.graphics.rectangle('fill', toggleX, y + 5, 50 * s, barH + 4, 6, 6)
            love.graphics.setColor(1, 1, 1, 0.9)
            local knobX = on and (toggleX + 36 * s) or (toggleX + 4 * s)
            love.graphics.circle('fill', knobX, y + 5 + (barH + 4) / 2, 7 * s)

        elseif item.type == "button" then
            love.graphics.printf(item.label, 0, y + 2, w, "center")

            if sel then
                local pulse = math.sin(self.time * 3) * 0.15 + 0.85
                love.graphics.setColor(0.25, 0.65, 1.0, pulse * 0.3)
                love.graphics.rectangle('fill', cx - 80 * s, y - 4, 160 * s, 32 * s, 4, 4)
            end
        end

        if sel and item.type ~= "button" then
            love.graphics.setColor(0.25, 0.6, 1.0, 0.15)
            love.graphics.rectangle('fill', cx - barW - 90 * s, y - 6, barW * 2 + 200 * s, itemH - 6, 4, 4)
        end
    end

    love.graphics.setColor(0.3, 0.5, 0.7, 0.4)
    love.graphics.setFont(self.value_font)
    love.graphics.printf("ESC TO GO BACK", 0, h - 30 * s, w, "center")
end

function SettingsMenu:keypressed(key)
    if key == 'escape' then
        GameState.switchTo(VoidRunnerMainMenu())
        return
    end

    if key == 'up' or key == 'w' then
        self.selected = math.max(1, self.selected - 1)
    elseif key == 'down' or key == 's' then
        self.selected = math.min(#self.items, self.selected + 1)
    end

    local item = self.items[self.selected]
    if item.type == "slider" then
        if key == 'left' or key == 'a' then
            item.set(math.max(0, item.get() - 0.1))
        elseif key == 'right' or key == 'd' then
            item.set(math.min(1, item.get() + 0.1))
        end
    elseif item.type == "toggle" then
        if key == 'return' or key == 'space' or key == 'left' or key == 'right' then
            item.set()
        end
    elseif item.type == "button" then
        if key == 'return' or key == 'space' then
            item.action()
        end
    end
end

function SettingsMenu:mousepressed(x, y, button)
    if button ~= 1 then return end
    local s = self.scale
    local startY = 130 * s
    local itemH = 60 * s
    local barW = 240 * s
    local cx = self.w / 2

    for i, item in ipairs(self.items) do
        local iy = startY + (i - 1) * itemH
        if y >= iy - 6 and y <= iy + itemH - 6 then
            self.selected = i
            if item.type == "slider" then
                local barX = cx + 20 * s
                if x >= barX and x <= barX + barW then
                    local val = (x - barX) / barW
                    item.set(math.max(0, math.min(1, val)))
                    self.dragging = i
                end
            elseif item.type == "toggle" then
                item.set()
            elseif item.type == "button" then
                item.action()
            end
            break
        end
    end
end

function SettingsMenu:mousemoved(x, y)
    if self.dragging then
        local s = self.scale
        local barW = 240 * s
        local barX = self.w / 2 + 20 * s
        local val = (x - barX) / barW
        self.items[self.dragging].set(math.max(0, math.min(1, val)))
    end
end

function SettingsMenu:mousereleased()
    self.dragging = false
end

function SettingsMenu:gamepadpressed(joystick, button)
    if button == 'dpup' then
        self.selected = math.max(1, self.selected - 1)
    elseif button == 'dpdown' then
        self.selected = math.min(#self.items, self.selected + 1)
    elseif button == 'a' then
        local item = self.items[self.selected]
        if item.type == "toggle" then item.set()
        elseif item.type == "button" then item.action()
        end
    elseif button == 'dpleft' then
        local item = self.items[self.selected]
        if item.type == "slider" then
            item.set(math.max(0, item.get() - 0.1))
        end
    elseif button == 'dpright' then
        local item = self.items[self.selected]
        if item.type == "slider" then
            item.set(math.min(1, item.get() + 0.1))
        end
    elseif button == 'b' or button == 'back' then
        GameState.switchTo(VoidRunnerMainMenu())
    end
end

return SettingsMenu
