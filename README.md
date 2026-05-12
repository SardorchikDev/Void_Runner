# SINGULARITY

**Become the Void.** A top-down arena survival game where you are a cosmic singularity — a black hole with the power to pull everything toward you.

Built with [LÖVE](https://love2d.org/) (Love2D) for game jam.

## The Concept

You control a **singularity** — a point of infinite gravity. Hold **SPACE** to activate your gravitational pull, dragging nearby enemies toward you. Enemies that **collide with each other** explode in satisfying **chain reactions**, racking up massive score multipliers. But be careful: if enemies touch you while your pull is **inactive**, you take damage.

Manage your **energy** (pull depletes it, resting recharges it), survive escalating **waves** of diverse enemies, and chase the high score.

## Features

- **Unique Core Mechanic** — Gravitational pull that turns enemies against each other
- **Chain Reaction System** — Enemies colliding create explosions that catch other enemies, with escalating multipliers
- **5 Enemy Types** — Drifters, Chasers, Orbiters, Tanks, and Splitters, each with distinct behavior and geometry
- **10+ Hand-Designed Waves** — Escalating difficulty with procedural scaling beyond wave 10
- **Visual Juice** — Screen shake, chromatic aberration, slow-motion, particle explosions, gravitational distortion, pull radius indicator
- **Procedural Audio** — Synthesized pull drone, absorption chimes, explosion bass, damage buzz, wave fanfares, ambient space drone
- **Persistent High Score** — Saved locally via LÖVE filesystem
- **Polished UI** — Atmospheric menu with flowing stars, in-game HUD (energy bar, health pips, multiplier, wave counter), cinematic game over screen
- **Pause Menu** — Resume, Restart, or Quit mid-game

## Requirements

- [LÖVE 11.3+](https://love2d.org/) (Love2D game framework)

## Running the Game

```bash
git clone https://github.com/SardorchikDev/Void_Runner.git
cd Void_Runner
love game/
```

## Controls

| Action | Input |
|--------|-------|
| Move | Mouse |
| Activate Pull | Space or Left Click (hold) |
| Pause | ESC |
| FPS Counter | F3 |

## How to Play

1. **Move** your mouse to glide your singularity through space
2. **Hold Space** (or left click) to activate your gravitational pull
3. Enemies within range are **dragged toward you**
4. Enemies that **collide** with each other are **destroyed** in chain reactions
5. Chain reactions give **score multipliers** — longer chains = bigger scores
6. Enemies that reach you **while pulling** are **absorbed** for points
7. Enemies that touch you **without pull** deal **damage**
8. **Energy** depletes while pulling — release to recharge
9. Survive the waves. Beat the high score.

## Enemy Types

| Enemy | Shape | Behavior | Points |
|-------|-------|----------|--------|
| **Drifter** | Cyan Circle | Drifts from edges | 10 |
| **Chaser** | Red Triangle | Pursues the player | 25 |
| **Orbiter** | Yellow Ring | Circles at a distance | 30 |
| **Splitter** | Green Square | Splits into 2 mini-drifters on death | 35 |
| **Tank** | Orange Hexagon | Slow, heavy, resists pull (3 HP) | 50 |

## Project Structure

```
Void_Runner/
├── game/
│   ├── main.lua                    # Entry point
│   ├── conf.lua                    # LÖVE configuration
│   ├── assets/                     # Fonts
│   ├── src/
│   │   ├── states/
│   │   │   ├── singularity_menu.lua    # Main menu
│   │   │   ├── singularity_play.lua    # Core gameplay
│   │   │   └── loadingscreen.lua       # Loading/splash screen
│   │   ├── gamestate.lua           # State machine
│   │   ├── entity.lua              # Entity base class
│   │   ├── screeneffect.lua        # Screen shake, flash, slow-mo
│   │   └── audiomanager.lua        # Procedural audio synthesis
│   └── external/                   # Third-party libraries (hump, HC, etc.)
├── build/                          # Build scripts
└── LICENSE
```

## License

MIT License — see [LICENSE](LICENSE) for details.
