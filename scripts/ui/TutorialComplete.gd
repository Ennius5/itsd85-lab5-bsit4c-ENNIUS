class_name TutorialComplete
extends CanvasLayer
## Shown when the tutorial's last step is done: "Tutorial complete!", How to Play (the guide as an
## overlay; its Back returns here) and Level Select.

signal level_select_pressed

const TITLE := "Tutorial complete!"
const GUIDE_LAYER_ABOVE := 10

var _guide_layer: CanvasLayer  # the How to Play overlay while it's open


func _init() -> void:
	layer = 15  # over the lot, HUD and driving pad; under the pause menu


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var title := Label.new()
	title.name = "Title"
	title.text = TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", HexStyle.CYAN)
	box.add_child(title)
	_own(title)
	_add_button(box, "HowToPlay", "How to Play").pressed.connect(open_guide)
	_add_button(box, "LevelSelect", "Level Select").pressed.connect(func() -> void: level_select_pressed.emit())
	Sound.wire_clicks(self)


func _add_button(box: BoxContainer, node_name: String, text: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.custom_minimum_size = Vector2(420, 90)
	b.add_theme_font_size_override("font_size", 34)
	box.add_child(b)
	_own(b)
	return b


func _own(node: Node) -> void:
	node.owner = self
	node.unique_name_in_owner = true


func open_guide() -> void:
	if is_guide_open():
		return
	_guide_layer = CanvasLayer.new()
	_guide_layer.name = "GuideLayer"
	_guide_layer.layer = layer + GUIDE_LAYER_ABOVE
	add_child(_guide_layer)
	var guide := Guide.new()
	guide.name = "Guide"
	guide.as_overlay = true
	guide.closed.connect(close_guide)
	_guide_layer.add_child(guide)


## Closes the guide if it is open; true if it was.
func close_guide() -> bool:
	if not is_guide_open():
		return false
	_guide_layer.queue_free()
	_guide_layer = null
	return true


func is_guide_open() -> bool:
	return _guide_layer != null
