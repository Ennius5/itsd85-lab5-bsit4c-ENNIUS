class_name SpeedVignette
extends CanvasLayer
## A subtle glow at the screen edges while a ship is selected: green when it's safe, yellow at
## the speed where a bump starts to dent, red where a crash would cost 50 pay. Counts spin too.

const GREEN := Color(0.3, 1.0, 0.45)
const YELLOW := Color(1.0, 0.85, 0.2)
const RED := Color(1.0, 0.15, 0.1)
const RED_COST := 50  # pure red: a crash now would cost this much pay
const MIN_STRENGTH := 0.15
const MAX_STRENGTH := 0.45
const FADE_SECONDS := 0.2

var shown := false  # a ship is being tracked; the glow fades in or out to match

var _rect := ColorRect.new()
var _mat := ShaderMaterial.new()
var _fade := 0.0  # 0 = hidden, 1 = fully shown
var _strength := MIN_STRENGTH


func _init() -> void:
	layer = 1  # with the CCTV filter; the level puts it after the filter and before the HUD
	_mat.shader = load("res://scripts/fx/speed_vignette.gdshader")
	_rect.material = _mat
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.visible = false
	add_child(_rect)


## The glow's colour at a danger speed (px/s): green → yellow → red, red beyond.
static func color_for(speed: float) -> Color:
	var safe := ShiftLedger.SAFE_IMPACT_SPEED
	var red := ShiftLedger.impact_speed_for_cost(RED_COST)
	if speed <= safe:
		return GREEN.lerp(YELLOW, clampf(speed / safe, 0.0, 1.0))
	return YELLOW.lerp(RED, clampf((speed - safe) / (red - safe), 0.0, 1.0))


## How strong the glow is at a danger speed: faint at rest, never more than MAX_STRENGTH.
static func strength_for(speed: float) -> float:
	var red := ShiftLedger.impact_speed_for_cost(RED_COST)
	return lerpf(MIN_STRENGTH, MAX_STRENGTH, clampf(speed / red, 0.0, 1.0))


## Follows ship's danger speed; null or freed hides the glow.
func track(ship: Variant) -> void:  # untyped: a freed ship must not error
	shown = is_instance_valid(ship) and ship is Ship
	if not shown:
		return
	var speed: float = (ship as Ship).danger_speed()
	_mat.set_shader_parameter("tint", color_for(speed))
	_strength = strength_for(speed)


func _process(delta: float) -> void:
	_fade = move_toward(_fade, 1.0 if shown else 0.0, delta / FADE_SECONDS)
	_rect.visible = _fade > 0.0
	_mat.set_shader_parameter("strength", _strength * _fade)
