---
name: testing-void-runner
description: End-to-end test the Void Runner LÖVE 2D game. Use when verifying gameplay features, UI, zone transitions, boss fights, combo system, or visual effects.
---

# Testing Void Runner

## Prerequisites
- LÖVE 11.5 must be installed (`love --version`)
- No audio hardware needed — audio features are visual-only testable (volume sliders, etc.)
- Game runs at `/home/ubuntu/repos/Void_Runner/` with `love game/`

## Launch & Setup
```bash
cd /home/ubuntu/repos/Void_Runner && love game/ &
sleep 3
wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
```

## Controls
- **Mouse**: Move ship (ship follows cursor smoothly)
- **SPACE**: Start game from menu / pre-game screen
- **Left Click**: Manual fire (targets closest entity in forward cone)
- **WASD**: Dash in direction
- **Right Click**: Time Warp
- **ESC**: Pause / return to menu
- **F3**: Toggle FPS counter

## Key Game Zones & Features
| Zone | Depth Range | Key Feature |
|------|-------------|-------------|
| 1 - Asteroid Field | 0-500m | Asteroids only, no enemies |
| 2 - Debris Zone | 500-1000m | More asteroids |
| 3 - Hostile Territory | 1000-2000m | Scout drones spawn, WARDEN boss at 1200m |
| 4 - Gravitational Storm | 2000-3500m | Dreadnoughts + scouts, STORM KING at 2500m |
| 5 - The Void | 3500m+ | All enemies, VOID LORD at 4000m |

## Testing Challenges & Workarounds

### Auto-Aim Targets Asteroids Over Enemies
The auto-aim laser (range: 220px, cone: 55°) targets the **closest** entity including asteroids. In zones with both asteroids and enemies, the laser almost always targets asteroids. This makes testing kill-dependent features (score popups, combo counter) very difficult.

**Workaround**: Temporarily modify `game/src/entities/zonemanager.lua` Zone 1 config:
```lua
-- Original Zone 1
asteroidSpawnRate = 1.5, asteroidDensity = 0.8, scoutSpawnRate = 0, enemyEnabled = false

-- Test config (remove asteroids, add scouts)
asteroidSpawnRate = 999, asteroidDensity = 0, scoutSpawnRate = 0.8, enemyEnabled = true, scrollSpeed = 30
```

Also temporarily widen auto-aim in `game/src/entities/player.lua`:
```lua
-- Original
self.autoAimAcquireTime = 0.5, self.autoAimLockTime = 0.4, self.autoAimCooldownMax = 0.6
self.autoAimRange = 220, self.autoAimCone = math.rad(55)

-- Test config (faster cycle, wider range/cone)
self.autoAimAcquireTime = 0.1, self.autoAimLockTime = 0.1, self.autoAimCooldownMax = 0.1
self.autoAimRange = 500, self.autoAimCone = math.rad(170)
```

**IMPORTANT**: Always revert these modifications after testing.

### Computer-Use Tool Delay
The computer-use tool has ~5s delay between actions. This is too slow for:
- Manual targeting of fast-moving enemies
- Precise dodge maneuvers
- Catching transient effects in screenshots (score popups last 1s)

**Workaround**: Use `xdotool key` for keyboard input instead of computer-use key events. Let auto-aim do the killing. Take rapid screenshots to catch transient effects.

### Help Menu Tab Navigation
Clicking on tab labels in the CODEX help menu may not work via computer-use. Use keyboard:
```bash
xdotool key Right  # Navigate to next tab
xdotool key Left   # Navigate to previous tab
```

## Two-Phase Test Strategy
For comprehensive testing, use a two-phase approach:
1. **Phase A (Temp Config)**: Test kill-dependent features (score popups, combo counter, death screen kills, player trail)
2. **Phase B (Original Config)**: Test zone transitions, boss spawning, main menu high score, help menu

## Key Files for Testing
- `game/src/entities/zonemanager.lua` — Zone configs, spawn rates, scroll speeds
- `game/src/entities/player.lua` — Auto-aim parameters, controls
- `game/src/states/voidrunner_playstate.lua` — Combo system, score popups, death screen
- `game/src/entities/boss.lua` — Boss entity, health bar, phases
- `game/src/states/voidrunner_mainmenu.lua` — High score display
- `game/src/states/helpmenu.lua` — CODEX/help pages
- `game/src/entities/backgrounds/zonetransition.lua` — Zone transition effects

## Devin Secrets Needed
None — the game runs fully locally with no external dependencies or API keys.
