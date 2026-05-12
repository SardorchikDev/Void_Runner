# Void Runner

A fast-paced infinite-scroll space survival game built with [LÖVE](https://love2d.org/) (Love2D). Pilot your ship through increasingly dangerous zones — dodge asteroids, fight enemy ships, collect powerups, and see how deep you can go.

## Features

- **5 Distinct Zones** — Asteroid Field → Debris Zone → Hostile Territory → Gravitational Storm → The Void
- **Mouse + Keyboard Controls** — Smooth mouse-follow movement, WASD dashes, auto-aim laser, manual fire
- **Gamepad Support** — Full controller support with analog stick movement and button mappings
- **Powerup System** — Shields, Time Warp, Magnet Burst, Score Bonus, Speed Boost, and Double Laser
- **Enemy Ships** — Scouts, Dreadnoughts, Mine-layers, and Swarms with unique attack patterns
- **Procedural Audio** — Synthesized engine hum, drones, explosions, and ambient sounds
- **Background Music** — Atmospheric soundtrack during gameplay
- **Score System** — Depth-based scoring with skill multiplier (near-misses, kills, dashes)
- **Settings Menu** — Volume control, fullscreen toggle, resolution options
- **Cross-Platform** — Desktop (Windows, macOS, Linux) and Mobile (Android, iOS)

## Requirements

- [LÖVE 11.3+](https://love2d.org/) (Love2D game framework)

## Running the Game

```bash
# Clone the repo
git clone https://github.com/SardorchikDev/Void_Runner.git
cd Void_Runner

# Run with LÖVE
love game/
```

## Controls

### Desktop (Keyboard + Mouse)
| Action | Input |
|--------|-------|
| Move ship | Mouse movement |
| Dash | WASD or Arrow keys |
| Manual fire | Left click |
| Time Warp | Right click or Space |
| Pause | ESC |

### Desktop (Gamepad)
| Action | Input |
|--------|-------|
| Move ship | Left stick |
| Dash | D-pad or Right stick flick |
| Manual fire | A / X button |
| Time Warp | B / Y button |
| Pause | Start |

### Mobile (Touch)
| Action | Input |
|--------|-------|
| Move ship | Touch and drag |
| Time Warp | Two-finger tap |

## Building

### Create .love file
```bash
bash scripts/build-love.sh
```

### Create Windows executable
```bash
bash build/build-windows.sh
```

## Project Structure

```
Void_Runner/
├── game/                   # Game source code
│   ├── main.lua           # Entry point
│   ├── conf.lua           # LÖVE configuration
│   ├── assets/            # Graphics, sounds, fonts
│   ├── src/               # Game source
│   │   ├── entities/      # Game objects (player, enemies, etc.)
│   │   ├── states/        # Game states (menu, play, help)
│   │   ├── phases/        # Legacy play phases
│   │   └── ...
│   └── external/          # Third-party libraries
├── scripts/               # Build scripts
├── build/                 # Windows build tooling
└── media/                 # Logos and marketing assets
```

## License

MIT License — see [LICENSE](LICENSE) for details.
