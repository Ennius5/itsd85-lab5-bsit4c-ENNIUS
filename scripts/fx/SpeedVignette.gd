class_name SpeedVignette
extends CanvasLayer
## A subtle glow at the screen edges while a ship is selected: green when it's safe, yellow at
## the speed where a bump starts to dent, red at RED_SPEED. Counts spin too.

const GREEN := Color(0.3, 1.0, 0.45)
const YELLOW := Color(1.0, 0.85, 0.2)
const RED := Color(1.0, 0.15, 0.1)
const RED_SPEED := 600.0  # px/s: pure red (the user's call from playtesting)
const GLOW_START := 1.0 - 0.3 / 1.7  # the glow fills only the outer part from centre to edge: 1.7x thinner than 30%
const MIN_STRENGTH := 0.15
const MAX_STRENGTH := 0.45
const FADE_SECONDS := 0.2

var shown := false  # a ship is being tracked; the glow fades in or out to match

var _rect := ColorRect.new()
var _mat := ShaderMaterial.new()
var _fade := 0.0  # 0 = hidden, 1 = fully shown
var _strength := MIN_STRENGTH
var _last_ship: Object  # the ship tracked last frame, to measure how far it moved
var _last_position := Vector2.ZERO
var _last_rotation := 0.0
var _measured := 0.0


func _init() -> void:
	layer = 1  # with the CCTV filter; the level puts it after the filter and before the HUD
	_mat.shader = load("res://scripts/fx/speed_vignette.gdshader")
	_rect.material = _mat
	_mat.set_shader_parameter("inner", GLOW_START)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.visible = false
	add_child(_rect)


## The glow's colour at a danger speed (px/s): green → yellow → red, red beyond.
static func color_for(speed: float) -> Color:
	var safe := ShiftLedger.SAFE_IMPACT_SPEED
	var red := RED_SPEED
	if speed <= safe:
		return GREEN.lerp(YELLOW, clampf(speed / safe, 0.0, 1.0))
	return YELLOW.lerp(RED, clampf((speed - safe) / (red - safe), 0.0, 1.0))


## How strong the glow is at a danger speed: faint at rest, never more than MAX_STRENGTH.
static func strength_for(speed: float) -> float:
	var red := RED_SPEED
	return lerpf(MIN_STRENGTH, MAX_STRENGTH, clampf(speed / red, 0.0, 1.0))


## Follows ship's danger speed; null or freed hides the glow. delta (seconds since the last call)
## lets it also measure how far the ship moved, for ships whose velocity isn't simulated here
## (a duel guest's mirrored ships are frozen and moved by snapshots).
func track(ship: Variant, delta: float = 0.0) -> void:  # untyped: a freed ship must not error
	shown = is_instance_valid(ship) and ship is Ship
	if not shown:
		_last_ship = null
		_measured = 0.0
		return
	var s := ship as Ship
	_measure(s, delta)
	var speed: float = maxf(s.danger_speed(), _measured)
	_mat.set_shader_parameter("tint", color_for(speed))
	_strength = strength_for(speed)


## The hull's fastest point's speed worked out from how far the ship moved since the last call.
func measured_speed() -> float:
	return _measured


func _measure(ship: Ship, delta: float) -> void:
	if ship == _last_ship and delta > 0.0:
		var moved := ship.global_position.distance_to(_last_position)
		var turned := absf(angle_difference(_last_rotation, ship.global_rotation))
		_measured = (moved + turned * ship.hull_reach()) / delta
	elif ship != _last_ship:
		_measured = 0.0
	_last_ship = ship
	_last_position = ship.global_position
	_last_rotation = ship.global_rotation


func _process(delta: float) -> void:
	_fade = move_toward(_fade, 1.0 if shown else 0.0, delta / FADE_SECONDS)
	_rect.visible = _fade > 0.0
	_mat.set_shader_parameter("strength", _strength * _fade)
