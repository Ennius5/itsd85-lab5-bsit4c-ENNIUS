class_name TutorialPointer
extends CanvasLayer
## Shows what to tap in the tutorial: a pulsing ring around the target and a bold arrow bobbing
## toward it. The target is a world node (ship, space, EXIT, ARRIVALS) or a driving-pad button.

const COLOR := HexStyle.MAGENTA
const PULSE_SECONDS := 1.0
const BOB_PIXELS := 14.0
const ARROW_LENGTH := 70.0
const ARROW_GAP := 18.0  # between the ring and the arrow's tip
const TOP_ZONE := 0.25  # targets in the top quarter of the screen get the arrow from below

var target: CanvasItem  # null when there is nothing to tap

var _radius := 80.0
var _clock := 0.0
var _canvas := Node2D.new()


func _init() -> void:
	layer = 3  # above the driving pad, below the pause menu
	_canvas.name = "Canvas"
	_canvas.draw.connect(_draw_pointer)
	add_child(_canvas)


## Rings and points at target (a world Node2D or a TouchScreenButton) with a ring of radius px.
func point_at(new_target: CanvasItem, radius: float = 80.0) -> void:
	target = new_target
	_radius = radius
	_canvas.queue_redraw()


func clear() -> void:
	target = null
	_canvas.queue_redraw()


## Where the target is on screen: a button's centre, or a world node's position through the camera.
func target_screen_position() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.ZERO
	if target is TouchScreenButton:
		var button := target as TouchScreenButton
		return button.get_global_transform_with_canvas() * (button.texture_normal.get_size() / 2)
	return target.get_global_transform_with_canvas().origin


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		target = null  # freed targets compare equal to null but still hold the reference
	_clock = fmod(_clock + delta, PULSE_SECONDS)
	_canvas.queue_redraw()


func _draw_pointer() -> void:
	if not is_instance_valid(target):
		return
	var at := target_screen_position()
	var pulse := 0.5 - 0.5 * cos(TAU * _clock / PULSE_SECONDS)
	var ring := _radius * lerpf(0.95, 1.1, pulse)
	_canvas.draw_arc(at, ring, 0.0, TAU, 48, Color(COLOR, lerpf(0.5, 1.0, pulse)), lerpf(4.0, 7.0, pulse), true)
	var screen := _canvas.get_viewport_rect().size
	var from_below := at.y < screen.y * TOP_ZONE
	var dir := Vector2.UP if from_below else Vector2.DOWN  # the way the arrow points
	var tip := at - dir * (ring + ARROW_GAP + BOB_PIXELS * pulse)
	var tail := tip - dir * ARROW_LENGTH
	var side := dir.orthogonal() * 22.0
	var outline := Color(0, 0, 0, 0.8)
	_canvas.draw_line(tail, tip - dir * 20.0, outline, 16.0)
	_canvas.draw_line(tail, tip - dir * 20.0, COLOR, 10.0)
	var head := PackedVector2Array([tip, tip - dir * 34.0 + side, tip - dir * 34.0 - side])
	_canvas.draw_colored_polygon(head, COLOR)
	_canvas.draw_polyline(PackedVector2Array([head[0], head[1], head[2], head[0]]), outline, 3.0)
