extends SceneTree

const OUT_DIR := "C:/Users/trayn/.t3/scratch/deadcam_cc0_cache/verify_phase4"

func _init() -> void:
	call_deferred("_run")

func _fail(msg: String) -> void:
	push_error("PHASE4_FAIL: " + msg)
	print("PHASE4_FAIL: ", msg)
	quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fail(msg)

func _snap(gm: GameManager, fname: String) -> void:
	await process_frame
	await process_frame
	var img := gm.render_vp.get_texture().get_image()
	if img:
		img.save_png(OUT_DIR + "/" + fname)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var is_compat := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	var scene := load("res://scenes/main.tscn")
	_assert(scene != null, "main.tscn load failed")
	var gm: GameManager = scene.instantiate()
	gm.deterministic_mode = true
	root.add_child(gm)
	current_scene = gm
	await process_frame
	await process_frame
	await process_frame

	var p: PlayerBodycam = gm.player
	var w: WorldBuilder = gm.world
	gm.hud.set_capture_mode(true)

	# Collect interactables by kind & name
	var gates := {}
	var wall_buys := {}
	var traps := {}
	var boxes := {}
	for inter: InteractableObject in w.interactables:
		if inter.kind == InteractableObject.Kind.BREACH_GATE:
			gates[inter.gate_id] = inter
		elif inter.kind == InteractableObject.Kind.WALL_BUY:
			wall_buys[inter.name] = inter
		elif inter.kind == InteractableObject.Kind.TRAP:
			traps[inter.name] = inter
		elif inter.kind == InteractableObject.Kind.MYSTERY_BOX:
			boxes[inter.name] = inter

	_assert(gates.has("boiler") and gates.has("morgue") and gates.has("sawmill"), "Missing breach gates: " + str(gates.keys()))
	_assert(wall_buys.size() >= 5, "Expected >= 5 Wall-Buy weapons, found %d" % wall_buys.size())
	_assert(traps.size() == 3, "Expected 3 activatable traps, found %d" % traps.size())
	_assert(boxes.size() >= 3, "Expected >= 3 Mystery Boxes, found %d" % boxes.size())
	print("PHASE4_WORLD_INVENTORY_OK gates=", gates.size(), " wall_buys=", wall_buys.size(), " traps=", traps.size(), " boxes=", boxes.size())

	# 1. Visual inspection captures of all 3 new wings + Wall-Buy + active traps on Forward+
	if not is_compat:
		# Lobby Wall-Buy M870
		p.set_deterministic_view(Vector3(-4.2, 0.05, -5.0), 0.0, 0.0, 0, false, true)
		w.update_zone_culling(p.camera)
		await _snap(gm, "01_lobby_wallbuy_m870.png")

		# Open Boiler Gate & activate Flame Jet Trap -> capture Boiler Wing!
		gm.points = 9999
		(gates["boiler"] as InteractableObject).interact(gm, p)
		(traps["BoilerFlameTrap"] as InteractableObject).interact(gm, p)
		p.set_deterministic_view(Vector3(11.6, 0.05, 3.25), -PI * 0.5, -0.05, 5, false, true)
		w.update_zone_culling(p.camera)
		await _snap(gm, "02_boiler_wing_flame_trap.png")

		# Open Quarantine Morgue Gate & activate Electric Fence -> capture Morgue + MysteryBoxMorgue!
		(gates["morgue"] as InteractableObject).interact(gm, p)
		(traps["MorgueElectricTrap"] as InteractableObject).interact(gm, p)
		var hm := maxf(w._snow_height_at(-19.0, -48.5), maxf(w._snow_height_at(-29.5, -48.5), maxf(w._snow_height_at(-38.0, -54.0), w._snow_height_at(-38.0, -42.0)))) + 0.34
		p.set_deterministic_view(Vector3(-19.2, hm + 0.08, -48.5), PI * 0.5, -0.04, 14, false, true)
		w.update_zone_culling(p.camera)
		await _snap(gm, "03_quarantine_morgue_electric.png")

		# Open Sawmill Gate & activate Spinning Sawblade Trap -> capture Extended North Logging Yard!
		(gates["sawmill"] as InteractableObject).interact(gm, p)
		(traps["SawmillBladeTrap"] as InteractableObject).interact(gm, p)
		var hy := w._snow_height_at(0.0, -91.0)
		p.set_deterministic_view(Vector3(2.8, hy + 0.05, -90.5), 0.28, -0.04, 13, false, true)
		w.update_zone_culling(p.camera)
		await _snap(gm, "04_logging_yard_sawblade.png")

		# Reset traps & gates cleanly before gameplay assertions
		gm.restart_game()
		await process_frame

	gm.deterministic_mode = false
	gm.start_game()
	p.deterministic_camera = false
	gm.points = 9999

	# 2. Verify all 3 Breach Gates unlock spawn pools & reset cleanly!
	var sp0 := w.spawn_points.size()
	(gates["boiler"] as InteractableObject).interact(gm, p)
	_assert(w.boiler_gate_open and w.spawn_points.size() == sp0 + w.boiler_spawn_points.size(), "Boiler gate failed to unlock spawns!")
	(gates["morgue"] as InteractableObject).interact(gm, p)
	_assert(w.morgue_gate_open and w.spawn_points.size() == sp0 + w.boiler_spawn_points.size() + w.morgue_spawn_points.size(), "Morgue gate failed to unlock spawns!")
	(gates["sawmill"] as InteractableObject).interact(gm, p)
	_assert(w.sawmill_gate_open and w.spawn_points.size() == sp0 + w.boiler_spawn_points.size() + w.morgue_spawn_points.size() + w.sawmill_spawn_points.size(), "Sawmill gate failed to unlock spawns!")
	print("BREACH_GATES_OK spawns=", w.spawn_points.size())

	# 3. Verify Wall-Buy purchase -> ammo refill flow!
	var wb_mp5 := wall_buys["WallBuy_MP5"] as InteractableObject
	var pts_before := gm.points
	var msg_buy := wb_mp5.interact(gm, p)
	_assert(p.unlocked_weapons[5] and p.current_weapon == 5 and gm.points == pts_before - 1000, "Wall-buy MP5 purchase failed: " + msg_buy)
	p.ammo_in_mag[5] = 2
	var pts_before_refill := gm.points
	var msg_refill := wb_mp5.interact(gm, p)
	_assert(p.ammo_in_mag[5] == p.get_weapon_mag_size(5) and gm.points == pts_before_refill - 250, "Wall-buy MP5 ammo refill failed: " + msg_refill)
	print("WALL_BUYS_OK")

	# 4. Verify all 3 Activatable Traps damage/kill zombies in kill-zone + transition to cooldown!
	var hm_floor := maxf(w._snow_height_at(-19.0, -48.5), maxf(w._snow_height_at(-29.5, -48.5), maxf(w._snow_height_at(-38.0, -54.0), w._snow_height_at(-38.0, -42.0)))) + 0.34
	for t_spec in [
		["BoilerFlameTrap", Vector3(14.0, 0.05, 3.25)],
		["MorgueElectricTrap", Vector3(-21.6, hm_floor + 0.08, -48.5)],
		["SawmillBladeTrap", Vector3(0.0, w._snow_height_at(0.0, -98.0) + 0.10, -98.0)],
	]:
		var tr := traps[t_spec[0]] as InteractableObject
		var z_t := gm.spawn_zombie_at(t_spec[1], ZombieAI.Variant.ASYLUM_PATIENT, 0.0, false)
		var hp0 := z_t.health
		var tmsg := tr.interact(gm, p)
		_assert(tr.trap_state == InteractableObject.TrapState.ACTIVE, "Trap did not activate: " + tmsg)
		for _tf in range(10):
			tr._update_trap(0.10)
		_assert(z_t.dead or z_t.health < hp0, "Trap %s did not harm zombie in kill zone!" % t_spec[0])
		z_t.queue_free()
		# Expire trap into cooldown
		tr._update_trap(tr.trap_duration + 0.5)
		_assert(tr.trap_state == InteractableObject.TrapState.COOLDOWN, "Trap %s did not enter COOLDOWN!" % t_spec[0])
	print("TRAPS_OK")

	# 5. Verify Cross-Wing Zombie Navigation + Morgue Ramp Walkability!
	p.global_position = Vector3(0.0, 0.05, 2.0)
	var z_boil := gm.spawn_zombie_at(Vector3(22.0, 0.05, 5.0), ZombieAI.Variant.ASYLUM_PATIENT, 0.0, false)
	z_boil._nav_ray_tick = 3
	var dir_b := z_boil._choose_nav_dir(p.global_position - z_boil.global_position)
	_assert(dir_b.x < -0.5, "Boiler zombie did not navigate west toward doorway! dir=" + str(dir_b))
	z_boil.queue_free()

	p.global_position = Vector3(-4.0, 0.05, -44.0)
	var z_mrg := gm.spawn_zombie_at(Vector3(-34.0, hm_floor + 0.08, -52.0), ZombieAI.Variant.ASYLUM_PATIENT, 0.0, false)
	z_mrg._nav_ray_tick = 3
	var dir_m := z_mrg._choose_nav_dir(p.global_position - z_mrg.global_position)
	_assert(dir_m.x > 0.5, "Morgue zombie did not navigate east toward doorway! dir=" + str(dir_m))
	z_mrg.queue_free()

	# Physically walk a zombie up the Morgue entry ramp from x=-12.8 to x<-18.5 without jumping!
	p.global_position = Vector3(-24.0, hm_floor + 0.08, -48.5)
	var z_ramp := gm.spawn_zombie_at(Vector3(-12.6, w._snow_height_at(-12.6, -48.5) + 0.12, -48.5), ZombieAI.Variant.ASYLUM_PATIENT, 0.0, false)
	z_ramp.velocity = Vector3(-3.8, 0.0, 0.0)
	for _rf in range(85):
		z_ramp.velocity.x = -3.8
		z_ramp.velocity.z = 0.0
		z_ramp.velocity.y = -2.0 if z_ramp.is_on_floor() else z_ramp.velocity.y - 18.0 * 0.03
		z_ramp.move_and_slide()
		await physics_frame
	_assert(z_ramp.global_position.x < -18.5 and z_ramp.global_position.y >= hm_floor - 0.15, "Zombie blocked by Morgue ramp curb! pos=" + str(z_ramp.global_position))
	z_ramp.queue_free()
	print("CROSS_WING_NAV_OK")

	# 6. Verify restart_game() resets all 3 gates, traps & spawns cleanly!
	gm.restart_game()
	_assert(not w.boiler_gate_open and not w.morgue_gate_open and not w.sawmill_gate_open and w.spawn_points.size() == sp0, "restart_game() did not reset gates & spawns!")
	for t_key in traps.keys():
		_assert((traps[t_key] as InteractableObject).trap_state == InteractableObject.TrapState.READY, "restart_game() did not reset trap %s!" % t_key)
	print("RESTART_CLEANUP_OK")

	print("PHASE4_VERIFY_PASS compat=", is_compat)
	gm.queue_free()
	await process_frame
	quit(0)
