# Tutorial, Pulsing ARRIVALS and Speed Vignette Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A 12-step, unfailable, well-lit Tutorial lot that teaches the controls, plus a pulsing ARRIVALS bay and a green→yellow→red speed vignette in every level.

**Architecture:** `TutorialLevel.gd extends Level` reuses the real select/Done/park/retrieval/EXIT rules; a step counter checked every physics frame moves a world sign, the HUD goal line and a screen-space `TutorialPointer`. `SpeedVignette` is a CanvasLayer shader fed by `Level._process`. `ArrivalBay` gets a `waiting` flag that the level sets.

**Tech Stack:** Godot 4.7.2, typed GDScript, the project's own `TestCase` runner.

**Spec:** `docs/superpowers/specs/2026-11-16-tutorial-and-speed-vignette-design.md`

## Global Constraints

- Test suite: `bash .superpowers/sdd/2026-11-01-ship-art-pipeline/t.sh`; pass = `ALL TESTS PASSED` (read the log's `tests,` line; an exit-time "resources still in use" line is harmless).
- Typed GDScript, Godot 4 APIs only (see `godot-conventions` skill). One `##` doc line per new function, matching the codebase style.
- Never revert, stash or check out files you didn't change: unexpected modified files are the user's editor work.
- Tests that touch saves use `GameState.save_path = "user://test_<name>_save.cfg"` and restore it (see `tests/test_level.gd:_setup_state`).
- Tutorial steps' first ship: **Manipulator Drone** (`res://resources/ships/ManipulatorDrone.tres`). Spinning ship: **Recreational Drone** (`RecreationalDrone.tres`), spawned with `angular_velocity = 4.0`.
- Tutorial space: one **Heavy** space (`space_class = 2`). Lot well lit: no `Darkness` CanvasModulate.
- Vignette thresholds: green at 0, yellow at `ShiftLedger.SAFE_IMPACT_SPEED` (120 px/s), pure red at the speed where `ShiftLedger.dent_cost` = 50 (300 px/s), red above. Derived from `ShiftLedger`, never hard-coded.
- Vignette layering: above the CCTV filter, below HUD (layer 1, after CCTV in tree order), ShipControls (layer 2) and the pause menu (layer 20).
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Work stays on `feature/tutorial`; no merge/push without the user saying so.

## Review Focus

1. **Player does steps out of order** (drives off during step 1, parks straight away in step 3/4, releases the spinner before it stops): the tutorial must not stall forever or skip into a broken state → Task 5 test `test_parking_early_skips_ahead`.
2. **Restart from the pause menu mid-tutorial** reloads at step 1 with one Manipulator Drone, and doesn't force the tutorial again from Mode Select → Task 3 `test_tutorial_seen_set_on_start` + Task 5 `test_starts_at_step_one`.
3. **Dents in the tutorial never end it** (no Result scene, no unlock, `end_level` never runs) even when pay would go negative → Task 5 `test_crashes_never_end_the_tutorial`.
4. **Vignette with the ship deselected or freed mid-frame** (ship returned at the EXIT while driven): it hides, and nothing errors on a freed ship → Task 1 `test_vignette_hides_when_ship_freed`.
5. **Duel bays pulse too** — the duel has two bays (`ArrivalBay`, `ArrivalBayR`); both must pulse when a waiting ship sits in them → Task 2 `test_duel_bays_pulse`.

---

### Task 1: Speed vignette (every level)

**Files:**
- Create: `scripts/fx/SpeedVignette.gd`, `scripts/fx/speed_vignette.gdshader`
- Modify: `scripts/core/ShiftLedger.gd` (add a static), `scripts/actors/Ship.gd` (add `danger_speed()`), `scripts/Level.gd` (`_ready`, `_process`)
- Test: `tests/test_speed_vignette.gd`

**Interfaces:**
- Produces: `static func ShiftLedger.impact_speed_for_cost(cost: int) -> float` (inverse of `dent_cost`; 50 → 300.0).
- Produces: `func Ship.danger_speed() -> float` = `linear_velocity.length() + absf(angular_velocity) * r`, where `r` = max distance from `to_global(center_of_mass)` to any `hull_points()` point.
- Produces: `class_name SpeedVignette extends CanvasLayer` with `static func color_for(speed: float) -> Color`, `static func strength_for(speed: float) -> float`, `func track(ship: Ship) -> void` (null or freed → hidden), `var shown: bool` (read-only intent).
- Produces: `Level._vignette: SpeedVignette`, added in `_ready()` right after `_add_cctv()` and moved to tree index 1 (just after the CCTV filter).

- [ ] **Step 1: Write failing tests** in `tests/test_speed_vignette.gd`:

```gdscript
func test_red_speed_comes_from_the_ledger() -> void:
	assert_almost(ShiftLedger.impact_speed_for_cost(50), 300.0, 0.01)
	assert_eq(ShiftLedger.dent_cost(ShiftLedger.impact_speed_for_cost(50)), 50)

func test_colour_ramp() -> void:
	assert_eq(SpeedVignette.color_for(0.0), SpeedVignette.GREEN)
	assert_eq(SpeedVignette.color_for(ShiftLedger.SAFE_IMPACT_SPEED), SpeedVignette.YELLOW)
	assert_eq(SpeedVignette.color_for(300.0), SpeedVignette.RED)
	assert_eq(SpeedVignette.color_for(900.0), SpeedVignette.RED)
	var mid := SpeedVignette.color_for(60.0)
	assert_true(mid != SpeedVignette.GREEN and mid != SpeedVignette.YELLOW)  # it blends

func test_strength_stays_subtle_and_rises() -> void:
	assert_true(SpeedVignette.strength_for(0.0) < SpeedVignette.strength_for(300.0))
	assert_true(SpeedVignette.strength_for(900.0) <= 0.5)

func test_spin_alone_raises_danger_speed() -> void:
	# a frozen ship in the tree with angular_velocity = 3, linear 0 → danger_speed() > 0
	# and == 3 * r (r from hull_points), within 0.5

func test_vignette_hidden_without_a_ship() -> void:
	# SpeedVignette in tree, track(null) → shown == false, visible == false

func test_vignette_hides_when_ship_freed() -> void:
	# track(ship) → shown; ship.free(); track(ship) → no error, shown == false

func test_level_shows_vignette_only_while_driving() -> void:
	# Level01: after select_ship → level._vignette.shown; after release_ship + one frame → not shown
```

- [ ] **Step 2: Run tests** — expect FAIL (SpeedVignette not defined).
- [ ] **Step 3: Implement.** `GREEN = Color(0.3, 1.0, 0.45)`, `YELLOW = Color(1.0, 0.85, 0.2)`, `RED = Color(1.0, 0.15, 0.1)`; `color_for` lerps green→yellow over 0..SAFE, yellow→red over SAFE..`impact_speed_for_cost(50)`. `strength_for` ramps ~0.15 → 0.45 over 0..red speed. Shader: a full-rect `ColorRect` (`mouse_filter = IGNORE`) whose alpha is 0 in the centre and rises only near the edges (e.g. `smoothstep` on distance from the UV centre), uniforms `tint` and `strength`; fade in/out ~0.2 s when `shown` changes. `Level._process` calls `_vignette.track(valets[0].ship if not valets.is_empty() else null)` next to the `_lot_edge.track` call. Use `is_instance_valid`.
- [ ] **Step 4: Run tests** — expect all pass.
- [ ] **Step 5: Commit** `feat: speed vignette from green to red as the selected ship gets dangerous`.

### Task 2: Pulsing ARRIVALS

**Files:**
- Modify: `scripts/actors/ArrivalBay.gd`, `scripts/Level.gd`, `scripts/DuelLevel.gd` (if its bays aren't covered by the Level helper)
- Test: `tests/test_arrival_bay.gd` (extend)

**Interfaces:**
- Produces: `ArrivalBay.waiting: bool`; `func ArrivalBay.pulse() -> float` (0.0 when not waiting; oscillates 0..1 at ~1 s period when waiting, driven by an internal clock in `_process`). `_draw` brightens outline/label alpha and the fill by `pulse()`.
- Produces: `func Level.has_waiting_ship(bay: ArrivalBay) -> bool` — true when some ship in `_ships` with `not is_parked and not driven_since_free` touches the bay. `_physics_process` sets `waiting` on every bay the level owns (`_bay`, and in the duel each of `_arrivals.bays`).

- [ ] **Step 1: Failing tests:** `test_bay_still_when_empty` (`waiting = false` → `pulse() == 0.0` after a few frames), `test_bay_pulses_with_a_waiting_ship` (Level01 at start: `level._bay.waiting == true`; after `select_ship` + one physics frame → false), `test_duel_bays_pulse` (DuelLevel offline-constructible the way `tests/test_duel.gd` builds it: a spawned ship in each bay → both `waiting`).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** as in Interfaces.
- [ ] **Step 4: Run** — PASS, including existing arrival-bay and duel tests.
- [ ] **Step 5: Commit** `feat: ARRIVALS pulses while a ship waits in it`.

### Task 3: Tutorial entry (save flag, Mode Select, Level Select)

**Files:**
- Modify: `autoload/GameState.gd`, `scripts/ui/ModeSelect.gd`, `scripts/ui/LevelSelect.gd`, `tests/test_ui_flow.gd` (existing offline-routing test sets `tutorial_seen = true` first)
- Test: `tests/test_game_state.gd`, `tests/test_ui_flow.gd` (extend)

**Interfaces:**
- Produces: `GameState.TUTORIAL_SCENE := "res://scenes/levels/Tutorial.tscn"`, `GameState.tutorial_seen: bool` saved as `progress/tutorial_seen`, loaded with a bool type check, default `false`. `reset_progress()` leaves it alone.
- Produces: `ModeSelect._on_offline_pressed` → `_go(GameState.TUTORIAL_SCENE)` when `not tutorial_seen`, else `LEVEL_SELECT`.
- Produces: Level Select grid's first child is a Button named `Tutorial`, text `"Tutorial\nLearn the controls"`, always enabled, opening `TUTORIAL_SCENE`. (Task 5 sets `tutorial_seen` on tutorial start.)

- [ ] **Step 1: Failing tests:** `test_tutorial_seen_saves_and_loads`, `test_first_offline_goes_to_tutorial` (`last_target == GameState.TUTORIAL_SCENE`), `test_offline_after_tutorial_goes_to_level_select`, `test_level_select_has_tutorial_tile` (first grid child named `Tutorial`, not disabled).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: tutorial entry from Level Select and first Offline tap`.

### Task 4: TutorialPointer (pulse + arrow)

**Files:**
- Create: `scripts/ui/TutorialPointer.gd`
- Test: `tests/test_tutorial_pointer.gd`

**Interfaces:**
- Produces: `class_name TutorialPointer extends CanvasLayer` (layer 3: above the driving pad, below pause) with
  - `func point_at(target: CanvasItem, radius: float = 80.0) -> void` — a world `Node2D` or a `TouchScreenButton` on `ShipControls`.
  - `func clear() -> void`
  - `func target_screen_position() -> Vector2` — world nodes: `get_viewport().get_canvas_transform() * target.global_position`; a `TouchScreenButton`: its global position + half its `texture_normal` size (the face size from `HexFace`).
  - `var target: CanvasItem` (null when cleared; treat a freed target as cleared).
- Draws (unlit, in screen space): a ring of `radius` around the target whose alpha/width pulses at ~1 s, and a thick arrow that bobs toward the target from whichever side keeps it on screen (from above by default; from below if the target is in the top 25% of the screen). Colour `HexStyle.MAGENTA`.

- [ ] **Step 1: Failing tests:** `test_points_at_a_button_centre` (a ShipControls instance's `Buttons/Left/Fwd` → screen pos equals button global pos + 60,60 within 1 px), `test_points_at_a_world_node` (Node2D at (500,300) with an identity canvas transform → (500,300)), `test_clear_and_freed_target` (`clear()` → `target == null`; freeing the target then `_process` → no error, cleared).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: TutorialPointer pulses and points at what to tap`.

### Task 5: Tutorial lot and its 12 steps

**Files:**
- Create: `scenes/levels/Tutorial.tscn`, `scripts/TutorialLevel.gd`, `scripts/ui/TutorialSign.gd`
- Modify: `scripts/ui/HUD.gd` (`hints_enabled`, `show_shift_lines`)
- Test: `tests/test_tutorial.gd`

**Interfaces:**
- Consumes: `TutorialPointer` (Task 4), `GameState.tutorial_seen` (Task 3), Level internals (`valets`, `customers`, `customer_for`, `_request`, `_exit`, `_hud`, `_controls`, `_bay`, `_ships`, `spawn_next_customer`).
- Produces `HUD`: `var hints_enabled := true` (`show_hint` does nothing when false); `func show_shift_lines(on: bool) -> void` hides/shows `%Time`, `%Pay`, `%Customers`.
- Produces `TutorialSign extends Node2D`: `var text: String` (setter redraws); draws large text (size ~34, white on a dark rounded backing) level on screen via `Upright.angle(self)`, `material = Lighting.unlit()`, `z_index` above ships.
- Produces `TutorialLevel extends Level` (`class_name TutorialLevel`):
  - `const STEP_TEXT: Array[String]` — 12 sign lines, index 0 = step 1, copied from the spec's table.
  - `var step: int` (1..12; 13 = complete), `var drone: Ship`, `var spinner: Ship`, `signal completed`.
  - `const FORWARD_DISTANCE := 150.0`, `const RETURN_DELAY := 8.0`, `const SPIN_SPEED := 4.0`, `const STOPPED_SPIN := 0.05`, `const SPIN_EXPLAIN_SECONDS := 5.0`, `const ARRIVE_BEAT_SECONDS := 2.0`.
  - Overrides: `_ready()` (sets `GameState.tutorial_seen = true` + save, `_hud.hints_enabled = false`, `show_return_countdowns = false`, then `super._ready()`, then `_hud.show_shift_lines(false)`, marks the drone's customer `wants_retrieval = true`, enters step 1); `_add_darkness()` → no-op; `new_ledger()` → `ShiftLedger.duel(INF)` (never ends; dents still charged and sounded); `_update_arrivals()` → no-op (ships only come from steps); `retrieval_delay()` → `RETURN_DELAY`; `_update_orphans()` untouched (orphan_count 0).
  - `func _physics_process(delta)` → `super(delta)` then `_check_step(delta)`, which **loops**: while the current step's condition holds, advance (so out-of-order play skips ahead in one frame).
  - `func _enter_step(n: int) -> void` — sets `_sign.text`, moves `_sign` to `SignSpots/S<n>` if present (else keeps its place), `_hud.set_goal(STEP_TEXT[n-1])`, and retargets the pointer.
  - Pointer each frame (`_update_pointer()`), because it depends on state: 1/3 → drone; 2 → `Done`; 4 → `Fwd`; 5 → the Heavy space, then `Stop` while drone speed > 20 px/s, then `Done` once the space's `ready_for == drone`; 6 → none; 7 → drone until driven, then `Exit`; 8 → `_bay`; 9 → spinner; 10 → `StopSpin` (spinner if not driven); 11 → `RotL` (alternating with `RotR` each second); 12 → spinner until driven, then `Exit`. Buttons via `_controls.get_node("Buttons/Left/Fwd")` etc. (`Buttons/Right/Done`, `Buttons/Left/Stop`, `Buttons/Right/StopSpin`, `Buttons/Right/RotL`, `Buttons/Right/RotR`).
  - Conditions (“done when”): 1 `valets[0].ship == drone`; 2 `valets[0].ship == null` or `drone.is_parked`; 3 `drone.is_driven` or `drone.is_parked`; 4 forward distance ≥ `FORWARD_DISTANCE` along the drone's forward (−Y) at step-4 start, or `drone.is_parked`; 5 `drone.is_parked`; 6 `customer_for(drone).requested`; 7 drone handed back (`not is_instance_valid(drone) or not customers.has(drone)`); 8 entering spawns the spinner (`spawn_next_customer()`, `angular_velocity = SPIN_SPEED`, then `_request(spinner)` so it glows and goes to the EXIT unparked); done after `ARRIVE_BEAT_SECONDS`; 9 `valets[0].ship == spinner`; 10 `absf(spinner.angular_velocity) < STOPPED_SPIN`; 11 `Input.is_action_pressed("rotate_left"/"rotate_right")` or `SPIN_EXPLAIN_SECONDS` elapsed; 12 spinner handed back → step 13 → `completed.emit()`.
- Scene `Tutorial.tscn`: built like `Level01.tscn` (Floor, Walls, Spaces, Ships, Entrance, Exit (ExitPad), LotCamera, HUD, Controls, ShipPicker), `script = TutorialLevel.gd`, `level_number = 0`, `customer_queue = [ManipulatorDrone, RecreationalDrone]`, `random_customers = 0`, `goal_text = ""`. Lot roughly 1600×900: Entrance facing up at the bottom, one Heavy space `H1` straight ahead of it (~350 px nose-ward), the Exit further ahead past the space with a clear lane beside the space. Bright floodlights optional (no darkness means everything is lit). `SignSpots/S1..S12` Marker2D near the relevant spot (beside ARRIVALS for 1–3, beside the lane for 4, beside H1 for 5–6, near Exit for 7 and 12, by ARRIVALS for 8–11).

- [ ] **Step 1: Failing tests** in `tests/test_tutorial.gd` (instantiate `Tutorial.tscn` with `change_scene_on_end = false`, test save path; drive state directly like `test_level.gd` does):
  - `test_starts_at_step_one` — `step == 1`, exactly one ship, it is the Manipulator Drone, `_hud` time/pay labels hidden, no `Darkness` node, `GameState.tutorial_seen`.
  - `test_select_release_select` — `select_ship(drone)` → step 2; wait > `Level.RESELECT_DELAY_MS`… `release_ship()` → 3; `select_ship(drone)` → 4.
  - `test_forward_then_park` — at step 4 move `drone.global_position` 160 px along its forward + physics frame → 5; `drone.set_parked()` + `_on_ship_parked(drone, H1)` → 6.
  - `test_return_and_exit` — at step 6, simulate `RETURN_DELAY + 0.1` s of `_update_customers` → step 7 and the drone is requested; place drone at `Exit` → step 8 then (after `ARRIVE_BEAT_SECONDS`) step 9 with a spinner whose `absf(angular_velocity) >= 3.9`, glowing/requested.
  - `test_spin_steps_and_complete` — select spinner → 10; set `angular_velocity = 0` → 11; after `SPIN_EXPLAIN_SECONDS` → 12; spinner at Exit → step 13 and `completed` emitted.
  - `test_parking_early_skips_ahead` — at step 1, select and park the drone directly in H1 → step lands on 6 in one frame.
  - `test_crashes_never_end_the_tutorial` — `_on_ship_dented(drone, 500)` ×3 → `ledger.outcome == PLAYING`, `GameState.last_result` still `{}`, `unlocked_level` unchanged.
  - `test_no_arrivals_on_a_timer` — simulate 30 s of physics at step 1 → still one ship.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** HUD additions, TutorialSign, TutorialLevel, the scene.
- [ ] **Step 4: Run** — PASS (whole suite).
- [ ] **Step 5: Screenshot** — `--write-movie` a few frames of the tutorial at step 1 (sign, pointer on the drone, pulsing ARRIVALS) and with a driven ship (vignette); read the PNGs; fix anything unreadable.
- [ ] **Step 6: Commit** `feat: step-by-step tutorial lot`.

### Task 6: Tutorial complete panel

**Files:**
- Create: `scripts/ui/TutorialComplete.gd`
- Modify: `scripts/TutorialLevel.gd` (show it on `completed`; back gesture while shown → Level Select)
- Test: `tests/test_tutorial.gd` (extend)

**Interfaces:**
- Produces `class_name TutorialComplete extends CanvasLayer` (layer 15): centred neon panel, title `"Tutorial complete!"`, buttons named `HowToPlay` ("How to Play") and `LevelSelect` ("Level Select"), `signal level_select_pressed`, `func open_guide() -> void` / `func is_guide_open() -> bool` opening `Guide` with `as_overlay = true` on a child CanvasLayer (copy PauseMenu's pattern at `scripts/ui/PauseMenu.gd:172-196`); the guide's `closed` returns to the panel. `Sound.wire_clicks(self)`.
- `TutorialLevel`: on `completed` → `release_ship()`, hide controls/pointer/sign, add `TutorialComplete`; `level_select_pressed` → `change_scene_to_file(LEVEL_SELECT)` when `change_scene_on_end`, else record `last_pause_action = "level_select"`. Back gesture while the panel shows: close the guide if open, else go to Level Select (override `_notification`, call `super` otherwise).

- [ ] **Step 1: Failing tests:** `test_complete_panel_appears` (force step 12 done → a `TutorialComplete` child with both buttons; no `Result` change, `GameState.last_result == {}`), `test_complete_guide_opens_and_closes` (press HowToPlay → `is_guide_open()`; guide `closed` → false, panel still there), `test_complete_level_select` (press LevelSelect → `last_pause_action == "level_select"`).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: tutorial complete panel with How to Play and Level Select`.

### Task 7: Docs, phone build, review

**Files:** `docs/GDD.md`, `scripts/ui/Guide.gd` (one line about the edge glow on the controls/crash page, if the page has room), `README.md` if it lists levels.

- [ ] **Step 1:** Update GDD (Tutorial section, pulsing ARRIVALS, speed vignette with the 120/300 thresholds) and the guide line; add/adjust the guide test if it counts lines.
- [ ] **Step 2:** Full suite → `ALL TESTS PASSED`.
- [ ] **Step 3:** Export check (`--export-pack "Android"` + `tools/check_export_pack.gd`), then `--export-debug "Android" export/parkin-space.apk`, install on the phone (adb nodaemon server, user taps Allow, `install -r`, launch).
- [ ] **Step 4:** Commit `docs: tutorial, pulsing ARRIVALS and speed vignette in the GDD and guide`.
- [ ] **Step 5:** One fresh opus reviewer over the whole branch against the spec; fix confirmed findings test-first; re-run the suite.
