class_name TutorialSign
extends Node2D
## A tutorial instruction painted in the lot: big white text on a dark panel, always level on
## screen and readable in any light.

const FONT_SIZE := 34
const WIDTH := 640.0  # text wraps at this width
const PADDING := Vector2(24, 16)
const BACKING := Color(0.02, 0.04, 0.08, 0.85)

var text := "":
	set(value):
		text = value
		visible = text != ""
		queue_redraw()


func _ready() -> void:
	material = Lighting.unlit()
	z_index = 20  # above ships and markings


func _process(_delta: float) -> void:
	queue_redraw()  # re-level as the camera turns


func _draw() -> void:
	if text == "":
		return
	var font := ThemeDB.fallback_font
	var size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, WIDTH, FONT_SIZE)
	var box := Rect2(-size / 2 - PADDING, size + PADDING * 2)
	draw_set_transform(Vector2.ZERO, Upright.angle(self))
	draw_rect(box, BACKING)
	draw_rect(box, HexStyle.CYAN, false, 3.0)
	draw_multiline_string(font, Vector2(-size.x / 2, -size.y / 2 + font.get_ascent(FONT_SIZE)), text,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, FONT_SIZE, -1, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0)
