# Individual Contribution Log – Parkin' Space

**ITSD 85 Lab 5 · Mobile Game with Level Progression and Offline/Online Multiplayer**
**Student:** Ethan Campomanes · **Section:** BSIT 4C · **Team:** solo
**Repository:** https://github.com/Ennius5/parkin-space

This was a one-person project, so every item below is my own work. That covers game design, programming, ship art, level layout, testing, the phone builds, playtesting and the paper. About 150 commits were made between 2026-10-31 and 2026-11-16. I used Claude (Anthropic) through Claude Code as a programming assistant for implementation, automated tests and documentation drafts. Commits it helped write carry a `Co-Authored-By: Claude` line. I made the design decisions, drew the ship art, tuned the game feel on my phone, and reviewed and approved every change.

## What I built, with commits

| Area | What it is | Key commits |
|---|---|---|
| Project setup and core rules | Godot project, test runner, saved level progress (`GameState`), ship specs, parking rules, pay/dent/star ledger | [cd8b7e1](https://github.com/Ennius5/parkin-space/commit/cd8b7e1), [1b80c96](https://github.com/Ennius5/parkin-space/commit/1b80c96), [79d2f06](https://github.com/Ennius5/parkin-space/commit/79d2f06), [691f4da](https://github.com/Ennius5/parkin-space/commit/691f4da) |
| Core gameplay and Level 1 | Physics ship, parking space, level controller, HUD, touch controls, title/mode/level-select/result screens, Stop and Stop Spin brakes | [d52f79c](https://github.com/Ennius5/parkin-space/commit/d52f79c), [54c21c3](https://github.com/Ennius5/parkin-space/commit/54c21c3), [f6cff9d](https://github.com/Ennius5/parkin-space/commit/f6cff9d), [6ecee47](https://github.com/Ennius5/parkin-space/commit/6ecee47) |
| Android build | Export preset, texture formats, first phone playtest notes | [fba9bcf](https://github.com/Ennius5/parkin-space/commit/fba9bcf) |
| Thruster ships | Ships as masses pushed by thrusters painted on their hulls | [9acd7bf](https://github.com/Ennius5/parkin-space/commit/9acd7bf) (merge) |
| Ship art pipeline | 10 hand-drawn ships, marker images and the build tool | [9d8bf38](https://github.com/Ennius5/parkin-space/commit/9d8bf38) (merge), [b0d7dc2](https://github.com/Ennius5/parkin-space/commit/b0d7dc2), [43735b1](https://github.com/Ennius5/parkin-space/commit/43735b1) |
| Levels 2–5 | Tip tiers, retrievals and EXIT (L2); wrecks, asteroids and radiation (L3); black hole (L4); gold rush hour with special requests (L5) | [94d831d](https://github.com/Ennius5/parkin-space/commit/94d831d), [647f5d0](https://github.com/Ennius5/parkin-space/commit/647f5d0), [301f1e1](https://github.com/Ennius5/parkin-space/commit/301f1e1) (merge) |
| Look and sound | Dark lots with floodlights, CCTV filter, neon hex buttons, sound effects, music, pause menu, credits | [4acdff1](https://github.com/Ennius5/parkin-space/commit/4acdff1) (merge) |
| Online mode | LAN 1-vs-1 duel: the host decides everything, the guest mirrors it, disconnect handling | [7d6a9a1](https://github.com/Ennius5/parkin-space/commit/7d6a9a1) (merge) |
| How to Play guide and app icon | 9-page illustrated guide, Manipulator Drone app icon | [b225936](https://github.com/Ennius5/parkin-space/commit/b225936) (merge) |
| Playtest fixes, kit and paper outline | Wall warning, return countdowns, tap tip, separate music and sound toggles, hex title screen, playtest kit | [c770323](https://github.com/Ennius5/parkin-space/commit/c770323) (merge) |
| Tutorial and speed glow | 12-step guided tutorial, pulsing ARRIVALS, speed-warning edge glow | [b698f7b](https://github.com/Ennius5/parkin-space/commit/b698f7b) (merge) |
| Documentation and paper | GDD, credits, README, playtest kit, action plan, phone test matrix, IEEE paper | `docs/` folder |

## Testing
495 automated tests in 37 test files run headless before every merge. Every build was installed and played on a Huawei LYA-L29 (Android 10).
