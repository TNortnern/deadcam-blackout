extends SceneTree

const OUT_DIR := "C:/Users/trayn/.t3/scratch/deadcam_cc0_cache/verify_phase1"

func _init() -> void:
	call_deferred("_run")

func _fail(msg: String) -> void:
	push_error("PHASE1_FAIL: " + msg)
	print("PHASE1_FAIL: ", msg)
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

func _render_studio_glb(glb_path: String, out_name: String) -> void:
	var svp := SubViewport.new()
	svp.size = Vector2i(640, 360)
	svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svp.own_world_3d = true
	svp.msaa_3d = Viewport.MSAA_4X
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.17, 0.19)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.90, 0.92, 0.96)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	svp.add_child(we)
	var key_l := DirectionalLight3D.new()
	key_l.light_energy = 2.5
	key_l.rotation_degrees = Vector3(-34, 42, 0)
	svp.add_child(key_l)
	var fill_l := DirectionalLight3D.new()
	fill_l.light_energy = 1.2
	fill_l.rotation_degrees = Vector3(-18, -130, 0)
	svp.add_child(fill_l)
	var cam := Camera3D.new()
	cam.fov = 34.0
	svp.add_child(cam)
	root.add_child(svp)
	var pk: PackedScene = load(glb_path)
	_assert(pk != null, "GLB failed to load: " + glb_path)
	var inst := pk.instantiate()
	svp.add_child(inst)
	await process_frame
	var aabb := AABB()
	var first := true
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null: continue
		var b := m.global_transform * m.get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
	var center := aabb.get_center()
	var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var dist := maxf(0.16, max_dim * 1.65)
	cam.position = center + Vector3(dist * 0.92, dist * 0.28, dist * 0.36)
	cam.look_at(center, Vector3.UP)
	await process_frame
	await process_frame
	var simg := svp.get_texture().get_image()
	if simg:
		simg.save_png(OUT_DIR + "/" + out_name)
	svp.queue_free()
	await process_frame

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

	# 1. Verify leveled MP5A3 unsuppressed visual + photoreal grenade GLBs on Forward+
	_assert(str(PlayerBodycam.WEAPONS[5]["name"]) == "MP5A3 9MM", "WEAPONS[5] name must be MP5A3 9MM")
	_assert(not bool(PlayerBodycam.WEAPONS[5].get("has_holo", false)), "MP5A3 should have clean iron sights")
	_assert(str(PlayerBodycam.WEAPONS[5]["audio_b"]).ends_with("gun_pistol_b.wav"), "MP5A3 audio_b must be unsuppressed")
	if not is_compat:
		p.set_deterministic_view(Vector3(-1.2, 0.05, 3.6), -0.35, 0.0, 5, false, true)
		p.vm_rim.light_energy = 1.85
		await _snap(gm, "mp5a3_leveled_hip.png")
		p.set_deterministic_view(Vector3(-1.2, 0.05, 3.6), -0.35, 0.0, 5, true, true)
		await _snap(gm, "mp5a3_leveled_ads.png")
		await _render_studio_glb("res://assets/models/weapon_mp5.glb", "mp5a3_leveled_studio.png")
		await _render_studio_glb("res://assets/models/weapon_grenade_frag.glb", "grenade_frag_studio.png")
		await _render_studio_glb("res://assets/models/weapon_grenade_molotov.glb", "grenade_molotov_studio.png")
		await _render_studio_glb("res://assets/models/weapon_grenade_shock.glb", "grenade_shock_studio.png")

	# 2. Verify REAL PAUSE (get_tree().paused = true freezes zombies!) + Title Settings context!
	gm.deterministic_mode = false
	gm._open_overlay("settings")
	_assert(not gm.hud._settings_inv_btn.visible and not gm.hud._settings_rst_btn.visible, "Title settings should hide Inventory & Restart buttons")
	gm._close_all_overlays()
	gm.start_game()
	p.deterministic_camera = false
	var z_pause := gm.spawn_zombie_at(Vector3(-1.2, 0.05, -5.0), ZombieAI.Variant.ASYLUM_PATIENT, 0.0, true)
	await physics_frame
	await physics_frame
	gm._open_overlay("settings")
	_assert(paused == true and gm.hud._settings_inv_btn.visible, "In-match pause must pause tree & show Inventory button")
	var z_pos_before := z_pause.global_position
	for _f in range(10):
		await physics_frame
	_assert(z_pause.global_position.distance_to(z_pos_before) < 0.001, "Zombie moved while game was paused!")
	gm._close_all_overlays()
	_assert(paused == false, "Closing overlays must unpause game!")
	z_pause.queue_free()
	print("REAL_PAUSE_OK")

	# 3. Verify Dynamic Loadout Cap + Mystery Box Timeout Non-Overwrite + Lobby Ammo Crate!
	gm.restart_game()
	_assert(p.firearm_slots == [0], "Fresh run should start with G17 in slot 0")
	p.acquire_weapon(5, true)
	p.acquire_weapon(8, true)
	_assert(p.firearm_slots == [0, 5, 8], "Loadout should be [0, 5, 8]")
	# Verify Mystery Box timeout does NOT overwrite a capped 3-firearm loadout!
	var mbox: InteractableObject = null
	var acrate: InteractableObject = null
	for inter: InteractableObject in w.interactables:
		if inter.name == "MysteryBox": mbox = inter
		elif inter.kind == InteractableObject.Kind.AMMO_CRATE: acrate = inter
	_assert(mbox != null and acrate != null, "Missing MysteryBox or Lobby AmmoCrate!")
	mbox.box_state = InteractableObject.BoxState.READY_CLAIM
	mbox._rolled_weapon_idx = 10
	mbox._rolled_owner_player = p
	mbox._box_timer = 0.01
	mbox._update_mystery_box(0.05)
	_assert(p.firearm_slots == [0, 5, 8] and p.current_weapon == 8, "Mystery Box timeout MUST NOT overwrite capped loadout!")
	# Verify Lobby AmmoCrate refills ammo for 250 PTS
	gm.points = 1000
	p.ammo_in_mag[8] = 2
	p.ammo_reserve[8] = 5
	var amsg := acrate.interact(gm, p)
	_assert(p.ammo_in_mag[8] == p.get_weapon_mag_size(8) and gm.points == 750, "Lobby AmmoCrate refill failed: " + amsg)
	# Verify cap replacement + Bow Special slot + Inventory swap/drop
	p.equip_firearm_slot(1)
	var rep := p.acquire_weapon(10, true)
	_assert(int(rep.get("replaced", -1)) == 5 and p.firearm_slots == [0, 10, 8], "Cap replace failed")
	p.acquire_weapon(4, false)
	_assert(p.special_slot == 4 and p.firearm_slots == [0, 10, 8], "Bow special slot failed")
	gm._open_overlay("inventory")
	gm._on_inventory_action("swap", [0, 1])
	_assert(p.firearm_slots == [10, 0, 8], "Inventory swap failed")
	gm._on_inventory_action("equip_special", 0)
	_assert(p.current_weapon == 4, "Inventory equip_special failed")
	gm._on_inventory_action("drop_slot", 2)
	_assert(p.firearm_slots == [10, 0], "Drop slot failed")
	gm._close_all_overlays()
	print("LOADOUT_AND_INVENTORY_OK")

	# 4. Verify Dev Menu (`) + Quick Melee Lockouts (no reload mid-quick-melee!)
	gm._open_overlay("dev")
	gm._on_dev_action("add_points", null)
	gm._on_dev_action("toggle_god", null)
	var hp0 := p.health
	p.take_damage(80.0)
	_assert(p.health == hp0, "God mode failed")
	gm._on_dev_action("give_weapon", 7)
	gm._on_dev_action("refill_all", null)
	gm._on_dev_action("toggle_god", null)
	gm._close_all_overlays()
	p.select_melee_weapon("knife")
	p.equip_firearm_slot(p.firearm_slots.find(7))
	p.ammo_in_mag[7] = 1
	_assert(p.trigger_melee(false), "Quick melee trigger failed")
	_assert(p._quick_melee_active and not p.start_reload(), "Reload MUST be blocked during quick-melee!")
	for _t in range(30):
		await physics_frame
	_assert(not p._quick_melee_active and p._weapon_rigs[7].visible, "Quick melee failed to restore Springfield")
	print("DEV_AND_MELEE_LOCKOUT_OK")

	# 5. Verify Throwables: Frag + Molotov Burn Kill Points & Light Cleanup + Shock!
	var pts_before := gm.points
	var z_burn := gm.spawn_zombie_at(Vector3(1.5, 0.05, 0.5), ZombieAI.Variant.ASYLUM_PATIENT, 0.0, false)
	z_burn.health = 10.0
	p._grenade_cd = 0.0
	p.select_grenade("molotov")
	_assert(p.throw_grenade(), "Molotov throw failed")
	(p._grenades[0]["node"] as Node3D).global_position = z_burn.global_position + Vector3(0.0, 0.2, 0.0)
	p._grenades[0]["age"] = 99.0
	p._update_grenades(0.016)
	p._update_hazards(0.35)
	_assert(z_burn.burn_timer > 0.0, "Molotov did not ignite zombie!")
	z_burn._tick_status_effects(0.40)
	_assert(z_burn.dead, "Burn tick did not kill 10-HP zombie")
	_assert(gm.points > pts_before, "Burn kill MUST award points! before=%d after=%d" % [pts_before, gm.points])
	if z_burn._status_light and is_instance_valid(z_burn._status_light):
		_assert(not z_burn._status_light.visible, "Dead zombie _status_light leaked visible!")

	var z_shock := gm.spawn_zombie_at(Vector3(-2.5, 0.05, 0.5), ZombieAI.Variant.TACTICAL_SOLDIER, 0.0, false)
	p._grenade_cd = 0.0
	p.select_grenade("shock")
	_assert(p.throw_grenade(), "Shock throw failed")
	(p._grenades[0]["node"] as Node3D).global_position = z_shock.global_position + Vector3(0.0, 0.2, 0.0)
	p._grenades[0]["age"] = 99.0
	p._update_grenades(0.016)
	p._update_hazards(0.35)
	_assert(z_shock.shock_timer > 0.0, "Shock pool did not stun zombie")
	print("THROWABLES_AND_STATUS_OK")

	gm.restart_game()
	_assert(p._grenades.is_empty() and p._hazards.is_empty(), "Restart did not clear grenades/hazards")
	print("PHASE1_VERIFY_PASS compat=", is_compat)
	gm.queue_free()
	await process_frame
	quit(0)
