-- Replaces rectangular block hazards with rotating convex asteroid polygons.
Asteroid = class('Asteroid', Entity)

function Asteroid:initialize(pos, velocity, zone, radiusOverride)
    Entity.initialize(self, 'obstacle', -1, pos)

    self.radius = radiusOverride or lume.random(8, 40)
    self.velocity = velocity or vector(0, 0)
    self.zone = zone or 1
    self.rotation = lume.random(0, math.pi * 2)
    self.rotSpeed = lume.random(-0.5, 0.5)
    self.life = 0

    local function makeVertices(jitter)
        local numVerts = math.random(5, 8)
        local verts = {}
        local angleOffset = lume.random(0, math.pi * 2)
        for i = 1, numVerts do
            local angle = angleOffset + (i - 1) * (math.pi * 2 / numVerts) + lume.random(-jitter, jitter)
            local r = self.radius * lume.random(0.9, 1.0)
            table.insert(verts, math.cos(angle) * r)
            table.insert(verts, math.sin(angle) * r)
        end
        return verts
    end

    self.vertices = makeVertices(0.1)

    local craters = {}
    local numCraters = math.random(1, 4)
    for i = 1, numCraters do
        local angle = lume.random(0, math.pi * 2)
        local dist = lume.random(0, self.radius * 0.5)
        table.insert(craters, {
            x = math.cos(angle) * dist,
            y = math.sin(angle) * dist,
            r = lume.random(1, self.radius * 0.25)
        })
    end
    self.craters = craters

    if self.zone == 4 or self.zone >= 5 then
        self.tint = {0.2, 0.3, 0.15}
        self.edgeTint = {0.3, 0.5, 0.2}
    elseif self.zone == 3 then
        self.tint = {0.25, 0.15, 0.15}
        self.edgeTint = {0.4, 0.2, 0.2}
    elseif self.zone == 2 then
        self.tint = {0.2, 0.15, 0.25}
        self.edgeTint = {0.3, 0.2, 0.4}
    else
        if math.random() < 0.15 then
            self.tint = {0.15, 0.2, 0.25}
            self.edgeTint = {0.25, 0.35, 0.45}
        else
            self.tint = {0.2, 0.2, 0.22}
            self.edgeTint = {0.3, 0.3, 0.32}
        end
    end

    -- rim glow color based on zone
    if self.zone >= 4 then
        self.rimColor = {0.2, 0.8, 0.3}
    elseif self.zone == 3 then
        self.rimColor = {0.8, 0.4, 0.15}
    else
        self.rimColor = {0.4, 0.5, 0.7}
    end

    local cx, cy = 0, 0
    for i = 1, #self.vertices, 2 do
        cx = cx + self.vertices[i]
        cy = cy + self.vertices[i + 1]
    end
    cx = cx / (#self.vertices / 2)
    cy = cy / (#self.vertices / 2)

    local shapeVerts = {}
    for i = 1, #self.vertices, 2 do
        table.insert(shapeVerts, self.vertices[i] - cx)
        table.insert(shapeVerts, self.vertices[i + 1] - cy)
    end

    local ok, shape = pcall(function()
        return collision.newPolygonShape(unpack(shapeVerts))
    end)
    if not ok then
        self.vertices = makeVertices(0)
        shapeVerts = {}
        cx, cy = 0, 0
        for i = 1, #self.vertices, 2 do
            cx = cx + self.vertices[i]
            cy = cy + self.vertices[i + 1]
        end
        cx = cx / (#self.vertices / 2)
        cy = cy / (#self.vertices / 2)
        for i = 1, #self.vertices, 2 do
            table.insert(shapeVerts, self.vertices[i] - cx)
            table.insert(shapeVerts, self.vertices[i + 1] - cy)
        end
        shape = collision.newPolygonShape(unpack(shapeVerts))
    end
    self.collision_shape = shape
    self.collision_offset = vector(cx, cy)

    self.warning = nil
end

function Asteroid:update(dt)
    Entity.update(self, dt)
    self.pos = self.pos + self.velocity * dt
    self.rotation = self.rotation + self.rotSpeed * dt
    self.life = self.life + dt

    self.collision_shape:moveTo((self.pos + self.collision_offset):unpack())
    self.collision_shape:setRotation(self.rotation)

    -- asteroid-asteroid collision: both shatter on impact
    for _, other in ipairs(self.gameState:getEntitiesByTag('obstacle')) do
        if other ~= self and other.collision_shape and not other.dead and not self.dead then
            local collides, dx, dy = self.collision_shape:collidesWith(other.collision_shape)
            if collides then
                self:shatterIntoDust()
                other:shatterIntoDust()
                self:destroy()
                other:destroy()
                break
            end
        end
    end

    if self.gameState and self.gameState.cam then
        local camL, camT = self.gameState.cam:worldCoords(0, 0)
        local camR, camB = self.gameState.cam:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())

        local player = self.gameState.player
        local relativeVy = self.velocity.y - (player and player.driftSpeed or 0)
        if not self.warning and self.pos.y < camT and relativeVy > 0 then
            local dist = camT - self.pos.y
            local time = dist / relativeVy
            if time > 0 and time <= 0.5 then
                self.warning = WarningIndicator(self.pos:clone(), 'top', time)
                self.gameState:addEntity(self.warning)
            end
        end

        if self.warning and self.pos.y >= camT then
            self.warning:destroy()
            self.warning = nil
        end
    end

    if self.life > 30 then
        self:destroy()
    end
end

function Asteroid:draw()
    local r, g, b = self.tint[1], self.tint[2], self.tint[3]
    local er, eg, eb = self.edgeTint[1], self.edgeTint[2], self.edgeTint[3]
    local rr, rg, rb = self.rimColor[1], self.rimColor[2], self.rimColor[3]

    love.graphics.push()
    love.graphics.translate(self.pos:unpack())
    love.graphics.rotate(self.rotation)

    -- surface normal lighting: per-face color variation
    local lightDirX, lightDirY = 0.3, -0.7
    local lightLen = math.sqrt(lightDirX * lightDirX + lightDirY * lightDirY)
    lightDirX, lightDirY = lightDirX / lightLen, lightDirY / lightLen

    local verts = self.vertices
    local numPts = #verts / 2
    -- draw per-face triangles with lighting
    for i = 1, numPts do
        local x1 = verts[(i - 1) * 2 + 1]
        local y1 = verts[(i - 1) * 2 + 2]
        local ni = (i % numPts)
        local x2 = verts[ni * 2 + 1]
        local y2 = verts[ni * 2 + 2]

        -- edge normal (pointing outward)
        local edgeX = x2 - x1
        local edgeY = y2 - y1
        local nx = edgeY
        local ny = -edgeX
        local nLen = math.sqrt(nx * nx + ny * ny)
        if nLen > 0 then
            nx, ny = nx / nLen, ny / nLen
        end

        local dot = nx * lightDirX + ny * lightDirY
        local lightMod = dot * 0.25

        local fr = math.max(0, math.min(1, r * 0.5 + lightMod))
        local fg = math.max(0, math.min(1, g * 0.5 + lightMod))
        local fb = math.max(0, math.min(1, b * 0.5 + lightMod))

        love.graphics.setColor(fr, fg, fb, 0.7)
        love.graphics.polygon('fill', 0, 0, x1, y1, x2, y2)
    end

    -- base edge outline
    love.graphics.setColor(r * 0.8, g * 0.8, b * 0.8, 0.9)
    love.graphics.setLineWidth(1.5)
    love.graphics.polygon('line', verts)

    -- rim glow (2-pass additive)
    love.graphics.setBlendMode('add')
    love.graphics.setColor(rr, rg, rb, 0.04)
    love.graphics.setLineWidth(6)
    love.graphics.polygon('line', verts)
    love.graphics.setColor(rr, rg, rb, 0.08)
    love.graphics.setLineWidth(3)
    love.graphics.polygon('line', verts)

    -- dust halo for large asteroids
    if self.radius > 25 then
        love.graphics.setColor(rr * 0.5, rg * 0.5, rb * 0.5, 0.04)
        love.graphics.circle('fill', 0, 0, self.radius * 1.6)
    end
    love.graphics.setBlendMode('alpha')

    -- craters with depth
    for _, crater in ipairs(self.craters) do
        love.graphics.setColor(r * 0.2, g * 0.2, b * 0.2, 0.8)
        love.graphics.circle('fill', crater.x, crater.y, crater.r)
        -- bright rim arc (top half)
        love.graphics.setColor(r * 1.5, g * 1.5, b * 1.5, 0.4)
        love.graphics.arc('line', 'open', crater.x, crater.y, crater.r, -math.pi, 0)
    end

    love.graphics.pop()
end

function Asteroid:collidesWith(player_shape)
    return self.collision_shape:collidesWith(player_shape)
end

function Asteroid:shatterIntoDust()
    if not self.gameState then return end
    -- impact flash (3 fast particles)
    for i = 1, 3 do
        local angle = lume.random(0, math.pi * 2)
        local speed = lume.random(200, 400)
        local vel = vector(math.cos(angle) * speed, math.sin(angle) * speed)
        local flash = Fragment(
            self.pos:clone(),
            vel,
            lume.random(2, 4),
            Color(1, 0.9, 0.7),
            0, 0
        )
        flash.life = 0.1
        flash.maxLife = 0.1
        self.gameState:addEntity(flash)
    end
    -- tiny rocky fragments
    local count = math.random(4, 7)
    for i = 1, count do
        local angle = lume.random(0, math.pi * 2)
        local speed = lume.random(30, 90)
        local vel = vector(math.cos(angle) * speed, math.sin(angle) * speed)
        local frag = Fragment(
            self.pos:clone(),
            vel,
            self.radius * 0.25,
            Color(self.tint[1], self.tint[2], self.tint[3]),
            self.rotation,
            lume.random(-5, 5)
        )
        frag.life = lume.random(0.2, 0.5)
        frag.maxLife = frag.life
        self.gameState:addEntity(frag)
    end
    -- fine dust cloud
    local dustCount = math.random(18, 28)
    for i = 1, dustCount do
        local angle = lume.random(0, math.pi * 2)
        local speed = lume.random(10, 50)
        local vel = vector(math.cos(angle) * speed, math.sin(angle) * speed)
        local dust = Fragment(
            self.pos:clone() + vector(lume.random(-self.radius * 0.3, self.radius * 0.3), lume.random(-self.radius * 0.3, self.radius * 0.3)),
            vel,
            lume.random(1.5, 3.5),
            Color(self.tint[1] * 0.6, self.tint[2] * 0.6, self.tint[3] * 0.6),
            0,
            0
        )
        dust.life = lume.random(0.3, 0.7)
        dust.maxLife = dust.life
        self.gameState:addEntity(dust)
    end
end

function Asteroid:onDestroyed(playState)
    local count = math.random(2, 3)
    for i = 1, count do
        local angle = lume.random(0, math.pi * 2)
        local speed = lume.random(20, 80)
        local vel = vector(math.cos(angle) * speed, math.sin(angle) * speed)
        local frag = Fragment(self.pos:clone(), vel, self.radius * 0.4, Color(self.tint[1], self.tint[2], self.tint[3]), self.rotation, lume.random(-3, 3))
        playState:addEntity(frag)
    end
end

return Asteroid
