extends TestCase

const LEVEL01 := preload("res://scenes/levels/Level01.tscn")
const SHIP_SCENE := preload("res://scenes/actors/Ship.tscn")


func _ship() -> Ship:
	var ship: Ship = SHIP_SCENE.instantiate()
	ship.spec = ship_spec("ManipulatorDrone")
	ship.position = Vector2(400, 400)
	tree.root.add_child(ship)
	return ship


func test_red_speed_comes_from_the_ledger() -> void:
	assert_almost(ShiftLedger.impact_speed_for_cost(50), 300.0, 0.01)
	assert_eq(ShiftLedger.dent_cost(ShiftLedger.impact_speed_for_cost(50)), 50)


func test_colour_ramp() -> void:
	assert_eq(SpeedVignette.color_for(0.0), SpeedVignette.GREEN)
	assert_eq(SpeedVignette.color_for(ShiftLedger.SAFE_IMPACT_SPEED), SpeedVignette.YELLOW)
	assert_true(SpeedVignette.color_for(300.0).is_equal_approx(SpeedVignette.RED))
	assert_true(SpeedVignette.color_for(900.0).is_equal_approx(SpeedVignette.RED))
	var mid := SpeedVignette.color_for(60.0)
	assert_true(mid != SpeedVignette.GREEN and mid != SpeedVignette.YELLOW, "it blends")


func test_strength_stays_subtle_and_rises() -> void:
	assert_true(SpeedVignette.strength_for(0.0) < SpeedVignette.strength_for(300.0))
	assert_true(SpeedVignette.strength_for(900.0) <= 0.5)
	assert_true(SpeedVignette.strength_for(0.0) > 0.0, "a faint green glow even at rest")


func test_spin_alone_raises_danger_speed() -> void:
	var ship := _ship()
	ship.linear_velocity = Vector2.ZERO
	ship.angular_velocity = 3.0
	var pivot := ship.to_global(ship.center_of_mass)
	var reach := 0.0
	for p in ship.hull_points():
		reach = maxf(reach, pivot.distance_to(p))
	assert_true(reach > 0.0)
	assert_almost(ship.danger_speed(), 3.0 * reach, 0.5)
	ship.angular_velocity = 0.0
	ship.linear_velocity = Vector2(50, 0)
	assert_almost(ship.danger_speed(), 50.0, 0.01)
	ship.queue_free()


func test_vignette_hidden_without_a_ship() -> void:
	var v := SpeedVignette.new()
	tree.root.add_child(v)
	v.track(null)
	assert_false(v.shown)
	v.queue_free()


func test_vignette_hides_when_ship_freed() -> void:
	var v := SpeedVignette.new()
	tree.root.add_child(v)
	var ship := _ship()
	v.track(ship)
	assert_true(v.shown)
	ship.free()
	v.track(ship)
	assert_false(v.shown)
	v.queue_free()


func test_level_shows_vignette_only_while_driving() -> void:
	var level: Level = LEVEL01.instantiate()
	level.change_scene_on_end = false
	tree.root.add_child(level)
	await tree.process_frame
	assert_true(level._vignette != null)
	assert_false(level._vignette.shown)
	var ship: Ship = level.get_node("Ships").get_child(0)
	level.select_ship(ship)
	await tree.process_frame
	assert_true(level._vignette.shown)
	level.release_ship()
	await tree.process_frame
	assert_false(level._vignette.shown)
	level.queue_free()


func test_frozen_mirror_ship_still_reads_its_speed() -> void:
	# a duel guest's ships are frozen mirrors moved by snapshots: velocity stays 0
	var v := SpeedVignette.new()
	tree.root.add_child(v)
	var ship := _ship()
	ship.freeze = true
	v.track(ship, 1.0 / 30.0)
	ship.global_position += Vector2(10, 0)  # 300 px/s
	v.track(ship, 1.0 / 30.0)
	assert_true(v.measured_speed() >= 290.0, "got %s" % v.measured_speed())
	ship.queue_free()
	v.queue_free()
