# Tutorial level, pulsing ARRIVALS and speed vignette — design

Date: 2026-11-16 · Branch: `feature/tutorial`

## Why

Playtesters got stuck on the controls, and they skip the How to Play guide. A hands-on tutorial
teaches the controls by doing them, one step at a time, with no way to fail. Two small helpers
go with it in every level: ARRIVALS pulses when a ship is waiting, and a soft screen-edge glow
warns when the selected ship is moving or spinning fast enough to dent.

## Goals

- A Tutorial lot that walks a new player through 12 steps, each waiting until the step is done.
- What must be tapped (a ship, a button, a space, the EXIT) is highlighted, pulsing, with an arrow.
- It cannot be failed: no timer, no firing, no game over, no Result screen.
- On finishing: "Tutorial complete!" with **How to Play** and **Level Select** buttons.
- ARRIVALS pulses whenever a ship is waiting in it, in every level.
- A subtle vignette shows the selected ship's danger: green → yellow → red, in every level.

## Non-goals

- No score, stars or unlocks from the tutorial.
- No new controls, ship art or ship types.
- No tutorial in the online duel.

## Anti-goals

- The tutorial must not teach something that behaves differently in the real game: it runs on
  the real `Level.gd` rules (select, Done, orange space, retrieval, EXIT).
- The vignette must stay subtle: it must never hide ships, the HUD or the buttons.

## Approaches

1. **Tutorial scene with a script that extends `Level.gd` (picked).** Real selection, parking,
   retrieval and EXIT; a small step list drives signs and arrows; timer and firing turned off.
2. A separate tutorial scene written from scratch — full control, but it copies game logic that
   would drift from the real game. Dropped.
3. Tutorial checks inside `Level.gd` — no new script, but bloats a 1,000-line file and every level
   carries checks it doesn't need. Dropped.

The user picked 1. The vignette has one sensible build: a screen-space shader on its own
CanvasLayer, fed by the level.

## The tutorial

### Entry

- **Level Select** gets a **Tutorial** tile before Level 1, always open.
- **First time only:** the first tap on Offline in Mode Select goes straight into the tutorial
  (my call, because testers skip optional help). A saved `tutorial_seen` flag in `GameState`
  (`save.cfg`) is set as soon as the tutorial starts, so it is forced at most once, even if the
  player quits midway.
- The pause menu works as usual (Resume / Restart / How to Play / Quit to Level Select).

### The lot

- `scenes/levels/Tutorial.tscn`, script `scripts/TutorialLevel.gd` (`extends Level`).
- **Well lit:** no `Darkness` CanvasModulate (override `_add_darkness()` to do nothing). CCTV
  filter stays, as in every lot.
- Small, simple layout: ARRIVALS, then straight ahead one **Heavy** space (the most forgiving
  size), then the EXIT further along. Walls around the lot. No asteroids, radiation or black hole.
  Exact sizes and positions are the builder's call; the path from ARRIVALS forward to the space
  should be a straight line so "go forward" works.
- Ships: step 1's ship is the **Manipulator Drone**. Step 8's spinning ship is a light ship
  (builder's pick, not the Manipulator Drone, so the player sees a second ship). Both are
  customers who want their ship back, so the real retrieval → EXIT flow handles them.
- **No timer, no firing:** the shift clock and the "fired" outcome are switched off; the HUD hides
  the time and pay lines (or shows nothing for them). Dents still cost pay and still play the
  sound, so step 6 can point at what just happened, but pay can't drop the player out.
- No automatic arrivals: ships appear only when a step spawns them.

### Steps

Each step shows a sign — world text near the thing it is about, readable level on screen (like
existing labels, unlit) — plus an arrow and pulse on whatever must be tapped. A step ends when its
condition is met; the next sign then appears. A short "Nice!" style beat between steps is the
builder's call.

| # | Sign (wording is the builder's draft, keep it short) | Highlight + arrow | Done when |
|---|------|------|------|
| 1 | "Tap the ship in ARRIVALS" | the Manipulator Drone (ARRIVALS pulses too) | that ship is selected |
| 2 | "Tap Done to let go of the ship" | Done button | ship released |
| 3 | "Tap the ship again to drive it" | the ship | ship selected |
| 4 | "Hold Fwd to go forward" | Fwd button | ship has moved forward a set distance (builder picks, ~150 px) |
| 5 | "Stop in the space: hold Stop, then tap Done when it turns orange" | the Heavy space, then Stop, then Done (arrow moves: space → Stop while moving → Done once orange) | ship parked |
| 6 | Crash explainer: "Bumping slowly is free. Hit something fast and you pay for the dent. The edge of the screen turns yellow, then red, when you're going too fast." Then "The owner is coming back for their ship…" | none (no tap) | the customer asks for the ship back; delay ~8 s, at least long enough to read |
| 7 | "Its owner wants it back. Drive it to the EXIT" | the ship (until selected), then the EXIT | ship handed back at the EXIT |
| 8 | (a new ship arrives spinning fast) "This ship is spinning!" | ARRIVALS pulses | ship has arrived |
| 9 | "Tap the spinning ship" | the ship | selected |
| 10 | "Hold Stop Spin until it stops" | Stop Spin button | spin is nearly zero (below a small threshold) |
| 11 | Spin explainer: "Rot L / Rot R turn the ship. It keeps spinning until you hold Stop Spin. Stop moves the same way: hold Stop to stop sliding." | Rot L and Rot R | the player has tried turning (pressed either rotate button), or a few seconds passed |
| 12 | "Now drive it to the EXIT" | the EXIT | ship handed back at the EXIT |

The spinning ship's customer wants it back from the start (glowing outline as usual), so step 12 is
the normal EXIT hand-back without parking first. The spinning ship spawns with a fast angular
velocity (builder picks; clearly fast, e.g. ~4 rad/s).

If the player does things out of order (e.g. drives off during step 1), nothing breaks: the step
just waits for its condition. If a step's condition is already true when it starts, it completes
at once.

### Highlight and arrow

- One reusable overlay (`scripts/ui/TutorialPointer.gd` or similar) that can point at either a
  world node (ship, space, EXIT, ARRIVALS) or a UI button (`ShipControls` children).
- Pulse: the target's outline/ring brightens and dims (~1 s cycle). For buttons, the hex face
  pulses (reuse the HexFace magenta/cyan styling, or a pulsing ring around it).
- Arrow: a bold arrow that bobs toward the target, kept on screen; drawn unlit so it reads in any
  light.

### Complete

After step 12: a centred "Tutorial complete!" panel (neon style) with **How to Play** (opens the
guide as an overlay, like the pause menu does; its Back returns to this panel) and
**Level Select**. The back gesture also goes to Level Select.

## Pulsing ARRIVALS (every level)

`ArrivalBay` pulses while a ship waiting to be picked up is inside it — not driven yet since it
arrived. The dashed outline and label brighten and dim (~1 s cycle); still when empty.

## Speed vignette (every level, incl. the duel)

- Shown only while this device's valet has a ship selected; fades out when released.
- Danger speed = the fastest point on the hull: `|linear velocity| + |angular velocity| ×
  (distance from the centre of mass to the farthest hull point)`. So spinning counts too.
  (My call: it is the speed the hull would hit something at.)
- Colour ramp, smooth:
  - 0 px/s → green
  - 120 px/s (`ShiftLedger.SAFE_IMPACT_SPEED`, where a bump starts to dent) → yellow
  - 300 px/s (where `ShiftLedger.dent_cost` reaches 50 pay) → pure red; stays red above
  - Derive both thresholds from `ShiftLedger` so they follow if dent costs change.
- Subtle: a soft glow at the screen edges only, low opacity (builder picks; roughly 0.15 at rest
  rising to ~0.45 at red). Never covers the centre.
- Layering: above the lot (and the CCTV filter), below the HUD, the driving pad and menus.

## Tests (test-first, as always)

- Tutorial steps advance on their conditions and in order; out-of-order actions don't break it.
- Tutorial never ends the shift by time or pay; completing step 12 shows the complete panel and no
  Result screen; nothing is unlocked.
- `tutorial_seen` saves and loads; first Offline tap routes to the tutorial only once.
- Level Select shows the Tutorial tile.
- ARRIVALS pulses only with a waiting ship.
- Vignette: hidden with no ship; colour at 0 / 120 / 300+ px/s is green / yellow / red; spin alone
  raises it.

## Left to the builder

Exact lot layout, sign wording polish, arrow look, pulse timing, the step-4 distance, the step-6
delay, the spinning ship's pick and spin rate, vignette opacities. Update `docs/GDD.md` and the
guide if it mentions the vignette.
