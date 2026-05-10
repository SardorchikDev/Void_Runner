-- NEW: Depth-zone progression, spawn tuning, speed scaling, and death flavor text for Void Runner.
ZoneManager = class('ZoneManager')

ZoneManager.static.ZONES = {
    {
        name = "ASTEROID FIELD",
        startDepth = 0,
        endDepth = 500,
        color = {r = 0, g = 0, b = 0},
        asteroidSpawnRate = 1.5,
        asteroidSpeedMult = 1.0,
        scoutSpawnRate = 0,
        dreadnoughtSpawnRate = 0,
        powerupChance = 0.18,
        scrollSpeed = 80,
        asteroidDensity = 0.8,
        enemyEnabled = false
    },
    {
        name = "DEBRIS ZONE",
        startDepth = 500,
        endDepth = 1000,
        color = {r = 0.1, g = 0, b = 0.15},
        asteroidSpawnRate = 1.2,
        asteroidSpeedMult = 1.1,
        scoutSpawnRate = 0,
        dreadnoughtSpawnRate = 0,
        powerupChance = 0.22,
        scrollSpeed = 110,
        asteroidDensity = 1.1,
        enemyEnabled = false
    },
    {
        name = "HOSTILE TERRITORY",
        startDepth = 1000,
        endDepth = 2000,
        color = {r = 0.2, g = 0, b = 0},
        asteroidSpawnRate = 0.95,
        asteroidSpeedMult = 1.3,
        scoutSpawnRate = 4.0,
        dreadnoughtSpawnRate = 0,
        powerupChance = 0.26,
        scrollSpeed = 150,
        asteroidDensity = 1.3,
        enemyEnabled = true
    },
    {
        name = "GRAVITATIONAL STORM",
        startDepth = 2000,
        endDepth = 3500,
        color = {r = 0, g = 0.15, b = 0},
        asteroidSpawnRate = 0.75,
        asteroidSpeedMult = 1.6,
        scoutSpawnRate = 2.5,
        dreadnoughtSpawnRate = 7.0,
        powerupChance = 0.30,
        scrollSpeed = 200,
        asteroidDensity = 1.5,
        enemyEnabled = true
    },
    {
        name = "THE VOID",
        startDepth = 3500,
        endDepth = math.huge,
        color = {r = 0.05, g = 0.05, b = 0.05},
        asteroidSpawnRate = 0.55,
        asteroidSpeedMult = 2.0,
        scoutSpawnRate = 1.5,
        dreadnoughtSpawnRate = 4.0,
        powerupChance = 0.35,
        scrollSpeed = 260,
        asteroidDensity = 1.8,
        enemyEnabled = true
    }
}

function ZoneManager:initialize()
    self.currentZone = 1
    self.zoneTime = 0
end

function ZoneManager:getZone(depth)
    for i, zone in ipairs(ZoneManager.ZONES) do
        if depth < zone.endDepth then
            return i
        end
    end
    return #ZoneManager.ZONES
end

function ZoneManager:getZoneData(zoneNum)
    return ZoneManager.ZONES[zoneNum] or ZoneManager.ZONES[#ZoneManager.ZONES]
end

function ZoneManager:getZoneName(zoneNum)
    local data = self:getZoneData(zoneNum)
    return data.name
end

function ZoneManager:getZoneColor(zoneNum)
    local data = self:getZoneData(zoneNum)
    return data.color
end

function ZoneManager:getChaosColor(time)
    local colors = {
        ZoneManager.ZONES[2].color,
        ZoneManager.ZONES[3].color,
        ZoneManager.ZONES[4].color,
        {r = 0.05, g = 0.05, b = 0.12}
    }
    local index = math.floor((time or 0) * 5) % #colors + 1
    return colors[index]
end

function ZoneManager:getSpawnConfig(zoneNum)
    return self:getZoneData(zoneNum)
end

function ZoneManager:getScrollSpeed(depth)
    local zone = self:getZone(depth)
    local data = self:getZoneData(zone)
    if zone == #ZoneManager.ZONES then
        return data.scrollSpeed + math.max(0, depth - data.startDepth) * 0.06
    end
    local progress = (depth - data.startDepth) / math.max(1, data.endDepth - data.startDepth)
    progress = math.min(1, progress)
    local nextData = ZoneManager.ZONES[zone + 1]
    if nextData then
        return lume.lerp(data.scrollSpeed, nextData.scrollSpeed, progress * 0.3)
    end
    return data.scrollSpeed
end

function ZoneManager:checkZoneTransition(oldZone, newZone)
    if oldZone ~= newZone then
        return true, self:getZoneName(newZone), self:getZoneData(newZone)
    end
    return false, nil, nil
end

function ZoneManager:getFlavorText(zoneNum)
    local texts = {
        "You barely left the hangar.",
        "The asteroids were not impressed.",
        "They saw you coming.",
        "The storm consumed you.",
        "You stared into the void. It stared back."
    }
    return texts[zoneNum] or texts[#texts]
end

return ZoneManager
