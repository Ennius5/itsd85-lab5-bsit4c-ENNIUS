class_name TutorialLevel
extends Level
## A lit practice lot that teaches the controls one step at a time. It runs the real Level rules
## (select, Done, orange space, retrieval, EXIT) but has no clock, can't fire the player and only
## brings ships in when a step calls for them. Each step shows a sign, the HUD goal line and a
## pulsing pointer at whatever must be tapped; it ends as soon as its condition holds, so doing
## things early just skips ahead.

signal completed

const STEP_TEXT: Array[String] = [
	"Tap the ship in ARRIVALS",
	"Tap Done to let go of the ship",
	"Tap the ship again to drive it",
	"Hold Fwd to go forward",
	"Stop in the space: hold Stop, then tap Done when it turns orange",
	"Bumping slowly is free. Hit something fast and you pay for the dent.\nThe screen edge turns yellow, then red, when you're going too fast.\nThe owner is coming back for their ship…",
	"Its owner wants it back. Drive it to the EXIT",
	"A new ship is arriving – and it's spinning!",
	"Tap the spinning ship",
	"Hold Stop Spin until it stops",
	"Rot L / Rot R turn the ship. It keeps turning until you hold Stop Spin.\nStop works the same way: hold it to stop sliding.",
	"Now drive it to the EXIT",
]
const LAST_STEP := 12
const FORWARD_DISTANCE := 150.0  # px along the nose for "go forward"
const RETURN_DELAY := 8.0  # seconds from parking until the owner wants the ship back
const SPIN_SPEED := 4.0  # rad/s the second ship arrives spinning at
const STOPPED_SPIN := 0.05  # rad/s that counts as stopped
const SPIN_EXPLAIN_SECONDS := 5.0  # step 11 moves on after this even without trying the turn buttons
const ARRIVE_BEAT_SECONDS := 2.0  # a moment to watch the spinning ship arrive
const MOVING_SPEED := 20.0  # px/s: above this, step 5 points at Stop
const BUTTON_SWAP_SECONDS := 1.0  # step 11's pointer alternates Rot L / Rot R this often

var step := 0  # 1..LAST_STEP; LAST_STEP + 1 = complete
var drone: Ship  # the Manipulator Drone, steps 1–7
var spinner: Ship  # the spinning ship, steps 8–12

var _pointer := TutorialPointer.new()
var _sign := TutorialSign.new()
var _step_time := 0.0  # seconds in the current step
var _forward_from := Vector2.ZERO  # step 4: where the drone was
var _forward_dir := Vector2.UP
var _complete: TutorialComplete  # the end panel, once every step is done


func _ready() -> void:
	GameState.tutorial_seen = true
	GameState.save_progress()
	_hud.hints_enabled = false
	show_return_countdowns = false
	super._ready()
	_hud.show_shift_lines(false)
	drone = _ships.get_child(0)
	customer_for(drone).wants_retrieval = true
	_pointer.name = "TutorialPointer"
	add_child(_pointer)
	_sign.name = "TutorialSign"
	_ships.add_sibling(_sign)
	completed.connect(_show_complete)
	_enter_step(1)


func _add_darkness() -> void:
	pass  # the tutorial lot is well lit


## Never ends: no clock, and dents can't get the player fired.
func new_ledger() -> ShiftLedger:
	return ShiftLedger.duel(INF)


func _update_arrivals(_delta: float, _in_the_way: Array[Node]) -> void:
	pass  # ships arrive only when a step brings them


func retrieval_delay() -> float:
	return RETURN_DELAY


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_check_step(delta)


func _process(delta: float) -> void:
	super._process(delta)
	_update_pointer()
	_update_sign()


## In the lot view the step's sign shows in the lot and the goal line gives its first line. While
## driving, the camera follows the ship and the sign would sit under the buttons, so it hides and
## the goal line carries the whole step.
func _update_sign() -> void:
	if step < 1 or step > LAST_STEP:
		return
	var text := STEP_TEXT[step - 1]
	_sign.text = text
	var driving := valets[0].ship != null
	_sign.visible = not driving
	_hud.set_goal(text if driving else text.get_slice("
", 0))


## Ends the tutorial: lets go of any ship and shows the complete panel instead of the lot's controls.
func _show_complete() -> void:
	release_ship()
	_pointer.clear()
	_sign.text = ""
	_controls.set_driving(false)
	_hud.hide()
	_complete = TutorialComplete.new()
	_complete.name = "TutorialComplete"
	_complete.level_select_pressed.connect(_to_level_select)
	add_child(_complete)


func _to_level_select() -> void:
	last_pause_action = "level_select"
	if change_scene_on_end:
		get_tree().change_scene_to_file(LEVEL_SELECT)


## Back gesture: once complete it closes the guide, then leaves for Level Select; before that it
## pauses as in any level.
func _on_back_gesture() -> void:
	if _complete == null:
		super._on_back_gesture()
	elif not _complete.close_guide():
		_to_level_select()


## Advances through every step whose condition already holds.
func _check_step(delta: float) -> void:
	_step_time += delta
	while step <= LAST_STEP and _step_done():
		_enter_step(step + 1)
	_update_pointer()


func _enter_step(n: int) -> void:
	step = n
	_step_time = 0.0
	if n > LAST_STEP:
		_sign.text = ""
		_hud.set_goal("Tutorial complete!")
		_pointer.clear()
		completed.emit()
		return
	_sign.text = STEP_TEXT[n - 1]
	_hud.set_goal(STEP_TEXT[n - 1].get_slice("\n", 0))
	var spot := get_node_or_null("SignSpots/S%d" % n) as Node2D
	if spot:
		_sign.global_position = spot.global_position
	match n:
		4:
			_forward_from = drone.global_position
			_forward_dir = Vector2.UP.rotated(drone.global_rotation)
		8:
			_bring_spinner()


## The second customer: arrives spinning fast, and their owner wants it at the EXIT straight away.
func _bring_spinner() -> void:
	spinner = spawn_next_customer()
	if spinner == null:
		return
	spinner.angular_velocity = SPIN_SPEED
	_request(spinner)


func _driving(ship: Ship) -> bool:
	return is_instance_valid(ship) and valets[0].ship == ship


func _gone(ship: Ship) -> bool:
	return not is_instance_valid(ship) or not customers.has(ship)


func _step_done() -> bool:
	match step:
		1:
			return _driving(drone) or drone.is_parked
		2:
			return valets[0].ship == null or drone.is_parked
		3:
			return _driving(drone) or drone.is_parked
		4:
			return drone.is_parked or \
					(drone.global_position - _forward_from).dot(_forward_dir) >= FORWARD_DISTANCE
		5:
			return drone.is_parked or customer_for(drone).requested
		6:
			return customer_for(drone).requested
		7:
			return _gone(drone)
		8:
			return _step_time >= ARRIVE_BEAT_SECONDS
		9:
			return _driving(spinner) or _gone(spinner)
		10:
			return _gone(spinner) or absf(spinner.angular_velocity) < STOPPED_SPIN
		11:
			return _step_time >= SPIN_EXPLAIN_SECONDS or _gone(spinner) \
					or Input.is_action_pressed("rotate_left") or Input.is_action_pressed("rotate_right")
		12:
			return _gone(spinner)
	return false


func _button(path: String) -> TouchScreenButton:
	return _controls.get_node("Buttons/" + path) as TouchScreenButton


## Points at what to tap now; within a step it follows what the player has done so far.
func _update_pointer() -> void:
	var target: CanvasItem = null
	var radius := 80.0
	match step:
		1, 3:
			target = drone
		2:
			target = _button("Right/Done")
		4:
			target = _button("Left/Fwd")
		5:
			var space := get_node("Spaces/H1") as ParkingSpace
			if space.ready_for == drone:
				target = _button("Right/Done")
			elif drone.linear_velocity.length() > MOVING_SPEED and space.touches(drone):
				target = _button("Left/Stop")
			else:
				target = space
				radius = 130.0
		7:
			target = drone if not _driving(drone) else _exit
			radius = 80.0 if target == drone else 140.0
		8:
			target = _bay
			radius = 140.0
		9:
			target = spinner
		10:
			target = _button("Right/StopSpin") if _driving(spinner) else spinner
		11:
			var left := fmod(_step_time, 2.0 * BUTTON_SWAP_SECONDS) < BUTTON_SWAP_SECONDS
			target = _button("Right/RotL" if left else "Right/RotR")
		12:
			target = spinner if not _driving(spinner) else _exit
			radius = 80.0 if target == spinner else 140.0
	if not is_instance_valid(target):
		_pointer.clear()
	elif target != _pointer.target:
		_pointer.point_at(target, radius)
