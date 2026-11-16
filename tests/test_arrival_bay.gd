extends TestCase

const SHIP_SCENE := preload("res://scenes/actors/Ship.tscn")


func _ship(pos: Vector2) -> Ship:
	var ship: Ship = SHIP_SCENE.instantiate()
	ship.spec = ship_spec("light_scout")
	ship.position = pos
	ship.freeze = true
	tree.root.add_child(ship)
	return ship


func test_touches_any_part_of_a_ship() -> void:
	var bay := ArrivalBay.new()
	bay.position = Vector2(300, 300)
	tree.root.add_child(bay)
	var ship := _ship(Vector2(300, 300))
	assert_true(bay.touches(ship))
	ship.position = Vector2(300, 300 + ArrivalBay.SIZE.y / 2 + 20)  # centre outside, nose still inside
	assert_true(bay.touches(ship))
	ship.position = Vector2(300, 700)
	assert_false(bay.touches(ship))
	ship.queue_free()
	bay.queue_free()


func test_bay_fits_the_biggest_space() -> void:
	var heavy: Vector2 = ParkingRules.SPACE_SIZES[ShipSpec.ShipClass.HEAVY]
	assert_true(ArrivalBay.SIZE.x >= heavy.x and ArrivalBay.SIZE.y >= heavy.y)


func test_asteroid_in_the_bay_blocks_it() -> void:
	var bay := ArrivalBay.new()
	bay.position = Vector2(300, 300)
	tree.root.add_child(bay)
	var img := Image.create(100, 60, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var rock := Asteroid.new()
	rock.texture = ImageTexture.create_from_image(img)
	rock.drift_speed = 0.0
	rock.freeze = true
	rock.position = Vector2(300, 300)
	tree.root.add_child(rock)
	var bodies: Array[Node] = [rock]
	assert_false(bay.is_clear(bodies))
	rock.position = Vector2(300, 700)
	assert_true(bay.is_clear(bodies))
	rock.queue_free()
	bay.queue_free()


func _rock(pos: Vector2, velocity: Vector2) -> Asteroid:
	var img := Image.create(100, 60, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var rock := Asteroid.new()
	rock.texture = ImageTexture.create_from_image(img)
	rock.drift_speed = 0.0
	rock.position = pos
	tree.root.add_child(rock)
	rock.linear_velocity = velocity
	rock.angular_velocity = 0.0
	return rock


func test_asteroids_bounce_off_the_bay() -> void:
	var bay := ArrivalBay.new()
	bay.position = Vector2(300, 300)
	tree.root.add_child(bay)
	var rock := _rock(Vector2(300, 520), Vector2(0, -80))
	var bodies: Array[Node] = [rock]
	var entered := false
	for i in 180:
		await tree.physics_frame
		entered = entered or not bay.is_clear(bodies)
	assert_false(entered, "the rock never got into the bay")
	assert_true(rock.linear_velocity.y > 0.0, "it bounced away: %s" % rock.linear_velocity)
	rock.queue_free()
	bay.queue_free()


func test_ships_drive_through_the_bay_wall() -> void:
	var bay := ArrivalBay.new()
	bay.position = Vector2(300, 300)
	tree.root.add_child(bay)
	var ship: Ship = SHIP_SCENE.instantiate()
	ship.spec = ship_spec("light_scout")
	ship.position = Vector2(300, 520)
	tree.root.add_child(ship)
	ship.linear_velocity = Vector2(0, -100)
	for i in 150:
		await tree.physics_frame
	assert_true(ship.global_position.y < 300.0, "ship at %s" % ship.global_position)
	ship.queue_free()
	bay.queue_free()


func test_bay_still_when_empty() -> void:
	var bay := ArrivalBay.new()
	tree.root.add_child(bay)
	bay.waiting = false
	await tree.process_frame
	await tree.process_frame
	assert_eq(bay.pulse(), 0.0)
	bay.queue_free()


func test_bay_pulse_moves_while_waiting() -> void:
	var bay := ArrivalBay.new()
	tree.root.add_child(bay)
	bay.waiting = true
	var seen := {}
	for i in 30:
		bay._process(1.0 / 30.0)
		seen[snappedf(bay.pulse(), 0.1)] = true
	assert_true(seen.size() >= 4, "the pulse rises and falls")
	for v: float in seen:
		assert_true(v >= 0.0 and v <= 1.0)
	bay.queue_free()


func test_bay_pulses_with_a_waiting_ship() -> void:
	var real_save := GameState.save_path
	GameState.save_path = "user://test_arrival_bay_save.cfg"
	var level: Level = load("res://scenes/levels/Level01.tscn").instantiate()
	level.change_scene_on_end = false
	tree.root.add_child(level)
	await tree.process_frame
	await tree.process_frame
	assert_true(level._bay.waiting, "the first customer waits in ARRIVALS")
	level.select_ship(level.get_node("Ships").get_child(0))
	await tree.process_frame
	assert_false(level._bay.waiting, "picked up: no longer waiting")
	level.free()
	GameState.save_path = real_save


func test_duel_bays_pulse() -> void:
	var real_save := GameState.save_path
	GameState.save_path = "user://test_arrival_bay_save.cfg"
	var level: DuelLevel = load("res://scenes/levels/Duel.tscn").instantiate()
	level.change_scene_on_end = false
	level.session = NetSession.new()
	tree.root.add_child(level)
	await tree.process_frame
	level._physics_process(DuelLevel.COUNTDOWN + 0.01)
	await tree.process_frame
	var bays := level.arrival_bays()
	assert_eq(bays.size(), 2)
	for bay in bays:
		assert_true(bay.waiting, "%s has a waiting ship" % bay.name)
	var session := level.session
	level.free()
	session.free()
	GameState.save_path = real_save
