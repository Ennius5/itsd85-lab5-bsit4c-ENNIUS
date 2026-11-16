extends TestCase


func test_points_at_a_button_centre() -> void:
	var controls: ShipControls = load("res://scenes/ui/ShipControls.tscn").instantiate()
	tree.root.add_child(controls)
	var fwd := controls.get_node("Buttons/Left/Fwd") as TouchScreenButton
	var pointer := TutorialPointer.new()
	tree.root.add_child(pointer)
	pointer.point_at(fwd)
	var expected := fwd.global_position + fwd.texture_normal.get_size() / 2
	assert_true(pointer.target_screen_position().distance_to(expected) < 1.0,
		"%s vs %s" % [pointer.target_screen_position(), expected])
	pointer.queue_free()
	controls.queue_free()


func test_points_at_a_world_node() -> void:
	var node := Node2D.new()
	node.position = Vector2(500, 300)
	tree.root.add_child(node)
	var pointer := TutorialPointer.new()
	tree.root.add_child(pointer)
	pointer.point_at(node)
	var expected := node.get_viewport().get_canvas_transform() * node.global_position
	assert_true(pointer.target_screen_position().distance_to(expected) < 1.0)
	pointer.queue_free()
	node.queue_free()


func test_clear_and_freed_target() -> void:
	var node := Node2D.new()
	tree.root.add_child(node)
	var pointer := TutorialPointer.new()
	tree.root.add_child(pointer)
	pointer.point_at(node)
	assert_eq(pointer.target, node)
	pointer.clear()
	assert_eq(pointer.target, null)
	pointer.point_at(node)
	node.free()
	pointer._process(0.016)
	assert_eq(pointer.target, null, "a freed target counts as cleared")
	pointer.queue_free()
