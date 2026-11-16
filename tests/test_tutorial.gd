extends TestCase

const TUTORIAL := "res://scenes/levels/Tutorial.tscn"
const TEST_SAVE := "user://test_tutorial_save.cfg"

var _real_save_path: String


func _make() -> TutorialLevel:
	_real_save_path = GameState.save_path
	GameState.save_path = TEST_SAVE
	GameState.reset_progress()
	GameState.tutorial_seen = false
	GameState.last_result = {}
	var level: TutorialLevel = load(TUTORIAL).instantiate()
	level.change_scene_on_end = false
	tree.root.add_child(level)
	await tree.process_frame
	return level


func _done(level: TutorialLevel) -> void:
	level.free()
	GameState.save_path = _real_save_path
	GameState.load_progress()


func _tick(level: TutorialLevel) -> void:
	level._check_step(0.0)


## Selects ship for valet 0, skipping the short guard after Done.
func _select(level: TutorialLevel, ship: Ship) -> void:
	level.valets[0].released_at_msec = -100000
	level.select_ship(ship)


func _park(level: TutorialLevel) -> void:
	var space: ParkingSpace = level.get_node("Spaces/H1")
	level.release_ship()
	level.drone.set_parked()
	level._on_ship_parked(level.drone, space)


func test_starts_at_step_one() -> void:
	var level := await _make()
	assert_eq(level.step, 1)
	assert_eq(level.get_node("Ships").get_child_count(), 1)
	assert_eq(level.drone.spec.display_name, "Manipulator Drone")
	assert_false(level.get_node("HUD/%Time").visible, "no shift clock")
	assert_false(level.get_node("HUD/%Pay").visible, "no pay line")
	assert_true(level.get_node_or_null("Darkness") == null, "the lot is lit")
	assert_true(GameState.tutorial_seen)
	assert_eq(level._pointer.target, level.drone)
	assert_eq((level.get_node("Spaces/H1") as ParkingSpace).space_class, ShipSpec.ShipClass.HEAVY)
	_done(level)


func test_select_release_select() -> void:
	var level := await _make()
	_select(level, level.drone)
	_tick(level)
	assert_eq(level.step, 2)
	assert_eq(level._pointer.target, level._controls.get_node("Buttons/Right/Done"))
	level.press_done()
	_tick(level)
	assert_eq(level.step, 3)
	_select(level, level.drone)
	_tick(level)
	assert_eq(level.step, 4)
	assert_eq(level._pointer.target, level._controls.get_node("Buttons/Left/Fwd"))
	_done(level)


func test_forward_then_park() -> void:
	var level := await _make()
	_select(level, level.drone)
	_tick(level)
	level.press_done()
	_tick(level)
	_select(level, level.drone)
	_tick(level)
	assert_eq(level.step, 4)
	var forward := Vector2.UP.rotated(level.drone.global_rotation)
	level.drone.global_position += forward * (TutorialLevel.FORWARD_DISTANCE + 10.0)
	_tick(level)
	assert_eq(level.step, 5)
	_park(level)
	_tick(level)
	assert_eq(level.step, 6)
	assert_eq(level._pointer.target, null, "step 6 is just reading")
	_done(level)


func test_return_and_exit() -> void:
	var level := await _make()
	_select(level, level.drone)
	_park(level)
	_tick(level)
	assert_eq(level.step, 6)
	level._update_customers(TutorialLevel.RETURN_DELAY + 0.1)
	_tick(level)
	assert_eq(level.step, 7)
	assert_true(level.customer_for(level.drone).requested)
	level._return(level.drone)
	_tick(level)
	assert_eq(level.step, 8)
	assert_true(level.spinner != null)
	assert_true(absf(level.spinner.angular_velocity) >= 3.9, "it arrives spinning fast")
	assert_true(level.customer_for(level.spinner).requested, "its owner wants it at the EXIT")
	level._check_step(TutorialLevel.ARRIVE_BEAT_SECONDS + 0.1)
	assert_eq(level.step, 9)
	assert_eq(level._pointer.target, level.spinner)
	_done(level)


func _to_step_nine(level: TutorialLevel) -> void:
	_select(level, level.drone)
	_park(level)
	_tick(level)
	level._update_customers(TutorialLevel.RETURN_DELAY + 0.1)
	_tick(level)
	level._return(level.drone)
	_tick(level)
	level._check_step(TutorialLevel.ARRIVE_BEAT_SECONDS + 0.1)


func test_spin_steps_and_complete() -> void:
	var level := await _make()
	_to_step_nine(level)
	var fired := [false]
	level.completed.connect(func() -> void: fired[0] = true)
	_select(level, level.spinner)
	_tick(level)
	assert_eq(level.step, 10)
	assert_eq(level._pointer.target, level._controls.get_node("Buttons/Right/StopSpin"))
	level.spinner.angular_velocity = 0.0
	_tick(level)
	assert_eq(level.step, 11)
	level._check_step(TutorialLevel.SPIN_EXPLAIN_SECONDS + 0.1)
	assert_eq(level.step, 12)
	level._return(level.spinner)
	_tick(level)
	assert_eq(level.step, 13)
	assert_true(fired[0], "completed emitted")
	_done(level)


func test_parking_early_skips_ahead() -> void:
	var level := await _make()
	_select(level, level.drone)
	_park(level)
	_tick(level)
	assert_eq(level.step, 6, "select then park straight away lands on the wait")
	_done(level)


func test_crashes_never_end_the_tutorial() -> void:
	var level := await _make()
	for i in 3:
		level._on_ship_dented(level.drone, 500)
	await tree.physics_frame
	assert_eq(level.ledger.outcome, ShiftLedger.Outcome.PLAYING)
	assert_eq(GameState.last_result, {})
	assert_eq(GameState.unlocked_level, 1)
	_done(level)


func test_no_arrivals_on_a_timer() -> void:
	var level := await _make()
	for i in 30:
		level._update_arrivals(1.0, [] as Array[Node])
	level._physics_process(30.0)
	assert_eq(level.get_node("Ships").get_child_count(), 1)
	assert_eq(level.ledger.outcome, ShiftLedger.Outcome.PLAYING, "no shift clock runs out")
	_done(level)


func test_sign_gives_way_to_the_goal_line_while_driving() -> void:
	var level := await _make()
	level._update_sign()
	assert_true(level._sign.visible, "lot view: the sign shows")
	_select(level, level.drone)
	_tick(level)
	_select(level, level.drone)
	level.press_done()
	_tick(level)
	_select(level, level.drone)
	_tick(level)
	level._check_step(0.0)
	assert_eq(level.step, 4)
	level._update_sign()
	assert_false(level._sign.visible, "driving: the sign would sit under the buttons")
	assert_eq(level._hud.get_node("%Goal").text, TutorialLevel.STEP_TEXT[3])
	_done(level)


func test_long_steps_keep_their_full_text_while_driving() -> void:
	var level := await _make()
	level.step = 11
	level._update_sign()
	assert_true(level._sign.text.contains("Stop works the same way"))
	_done(level)


func test_arrivals_marking_is_visible() -> void:
	var level := await _make()
	var after_bay := false
	for node in level.get_children():
		if node == level._bay:
			after_bay = true
		elif after_bay and node is Polygon2D:
			assert_true(false, "%s draws over ARRIVALS" % node.name)
	_done(level)


func _finish(level: TutorialLevel) -> void:
	_to_step_nine(level)
	_select(level, level.spinner)
	_tick(level)
	level.spinner.angular_velocity = 0.0
	_tick(level)
	level._check_step(TutorialLevel.SPIN_EXPLAIN_SECONDS + 0.1)
	level._return(level.spinner)
	_tick(level)


func test_complete_panel_appears() -> void:
	var level := await _make()
	_finish(level)
	assert_eq(level.step, 13)
	var panel := level.get_node_or_null("TutorialComplete") as TutorialComplete
	assert_true(panel != null, "the complete panel shows")
	if panel:
		assert_true(panel.get_node("%HowToPlay") is Button)
		assert_true(panel.get_node("%LevelSelect") is Button)
		assert_true((panel.get_node("%Title") as Label).text == "Tutorial complete!")
	assert_eq(GameState.last_result, {}, "no Result screen")
	assert_eq(GameState.unlocked_level, 1, "nothing unlocked")
	assert_eq(level._pointer.target, null)
	_done(level)


func test_complete_guide_opens_and_closes() -> void:
	var level := await _make()
	_finish(level)
	var panel := level.get_node("TutorialComplete") as TutorialComplete
	(panel.get_node("%HowToPlay") as Button).pressed.emit()
	assert_true(panel.is_guide_open())
	panel.close_guide()
	assert_false(panel.is_guide_open())
	assert_true(is_instance_valid(panel) and panel.is_inside_tree(), "back to the panel")
	_done(level)


func test_complete_level_select() -> void:
	var level := await _make()
	_finish(level)
	var panel := level.get_node("TutorialComplete") as TutorialComplete
	(panel.get_node("%LevelSelect") as Button).pressed.emit()
	assert_eq(level.last_pause_action, "level_select")
	_done(level)


func test_back_gesture_after_complete() -> void:
	var level := await _make()
	_finish(level)
	var panel := level.get_node("TutorialComplete") as TutorialComplete
	panel.open_guide()
	level.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_false(panel.is_guide_open(), "back closes the guide first")
	assert_eq(level.last_pause_action, "")
	level.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(level.last_pause_action, "level_select")
	assert_false(level._pause_menu.is_open(), "it doesn't pause a finished tutorial")
	_done(level)


func test_back_gesture_mid_tutorial_pauses_once() -> void:
	var level := await _make()
	level.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(level._pause_menu.is_open(), "back pauses as in any level")
	level.close_pause()
	_done(level)


func _to_step(level: TutorialLevel, n: int) -> void:
	_select(level, level.drone)
	_tick(level)
	level.press_done()
	_tick(level)
	_select(level, level.drone)
	_tick(level)
	if n >= 5:
		level.drone.global_position += Vector2.UP.rotated(level.drone.global_rotation) * 200.0
		level.drone.linear_velocity = Vector2.UP.rotated(level.drone.global_rotation) * 200.0
		level._check_step(1.0)


func test_letting_go_in_step_five_points_back_at_the_ship() -> void:
	var level := await _make()
	_to_step(level, 5)
	assert_eq(level.step, 5)
	level.release_ship()
	level._update_pointer()
	level._update_sign()
	assert_eq(level._pointer.target, level.drone)
	assert_eq(level._sign.text, TutorialLevel.RETAKE_TEXT)
	_done(level)


func test_letting_go_in_step_four_points_back_at_the_ship() -> void:
	var level := await _make()
	_to_step(level, 4)
	assert_eq(level.step, 4)
	level.release_ship()
	level._update_pointer()
	assert_eq(level._pointer.target, level.drone)
	_done(level)


func test_forward_counts_along_the_current_nose() -> void:
	var level := await _make()
	_to_step(level, 4)
	level.drone.global_rotation += PI  # it ended up facing back the way it came
	level.drone.linear_velocity = Vector2.UP.rotated(level.drone.global_rotation) * 100.0
	level._check_step(TutorialLevel.FORWARD_DISTANCE / 100.0 + 0.1)
	assert_eq(level.step, 5, "forward means wherever the nose points now")
	_done(level)
