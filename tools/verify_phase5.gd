extends SceneTree
## Phase 5 regression: combat depth and traversal.
##   - every zombie variant reaches and hurts a stationary player, and every attack state / special is exercised
##   - every melee weapon's light combo, charged heavy and shove connect
##   - riot visor armour, perk dispensaries and the objective tracker behave
##   - the navigation mesh links every spawn to every zone, and the sealed stair flights stay unreachable
##   - the starting staircase can be walked up and down without getting stuck or going airborne
## Run on both renderers:  godot --path . --rendering-method <forward_plus|gl_compatibility> --script tools/verify_phase5.gd

var gm: GameManager
var p: PlayerBodycam
var seen_states := {}
var seen_special := {}

func _initialize() -> void:
	call_deferred("_run")

func _wait(n: int) -> void:
	for _i in range(n):
		await process_frame

func _phys(n: int) -> void:
	for _i in range(n):
		await physics_frame
		for z in gm.zombies_root.get_children():
			if z is ZombieAI:
				seen_states[ZombieAI.State.keys()[z.state]] = true
				if z._special != "":
					seen_special[z._special] = true

func _regroup(zs: Array[ZombieAI]) -> void:
	_place_player(Vector3(0.0, 0.05, 4.0), 0.0)
	for k in range(zs.size()):
		var z := zs[k]
		if is_instance_valid(z) and not z.dead:
			z.global_position = Vector3(-0.7 + k * 0.7, 0.05, 2.5)
			z.velocity = Vector3.ZERO
			z._knockback_vel = Vector3.ZERO
			z.health = 9999.0


func _place_player(pos: Vector3, yaw: float) -> void:
	p.global_position = pos
	p.velocity = Vector3.ZERO
	p.yaw = yaw
	p.pitch = 0.0
	p.rotation.y = yaw
	p.health = p.max_health
	p.dead = false

func _run() -> void:
	gm = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	gm.deterministic_mode = true
	root.add_child(gm)
	current_scene = gm
	await _wait(10)
	p = gm.player
	gm.deterministic_mode = false
	gm.start_game()
	gm.zombies_to_spawn = 0
	gm.wave_intermission_dur = 99999.0
	await _wait(4)
	p.god_mode = false
	var fails: Array[String] = []

	# --- 1. every variant alone against a stationary player for 9 s ---
	for v in ZombieAI.Variant.values():
		gm.clear_zombies()
		await _phys(2)
		_place_player(Vector3(0.0, 0.05, 4.0), 0.0)
		p.grab_immunity = 0.0
		var z := gm.spawn_zombie_at(Vector3(0.5, 0.05, -7.0), v, 0.0, false)
		var hp0 := p.health
		var min_hp := hp0
		var max_dist := 0.0
		for _k in range(9):
			await _phys(60)
			min_hp = minf(min_hp, p.health)
			if is_instance_valid(z):
				max_dist = maxf(max_dist, z.global_position.distance_to(p.global_position))
			p.health = maxf(p.health, 60.0)
			if p.grabbed_by != null:
				for _s in range(5):
					p.struggle_against_grab()
		var alive := is_instance_valid(z) and not z.dead
		print("VARIANT ", ZombieAI.Variant.keys()[v], " kit_parts=", (z._kit_parts.size() if is_instance_valid(z) else -1), " player_min_hp=", snappedf(min_hp, 0.1), " alive=", alive, " end_dist=", snappedf(z.global_position.distance_to(p.global_position), 0.1) if is_instance_valid(z) else -1.0)
		if min_hp >= hp0 and v != ZombieAI.Variant.SCREAMER:
			fails.append("%s never damaged the player" % ZombieAI.Variant.keys()[v])
	# dedicated runner leap check from inside its trigger band
	gm.clear_zombies()
	await _phys(2)
	_place_player(Vector3(0.0, 0.05, 4.0), 0.0)
	var rz := gm.spawn_zombie_at(Vector3(0.0, 0.05, -1.0), ZombieAI.Variant.RUNNER, 0.0, false)
	rz._special_cd = 0.0
	await _phys(150)
	# dedicated bruiser slam check: in reach, charge on cooldown, slam ready
	gm.clear_zombies()
	await _phys(2)
	_place_player(Vector3(0.0, 0.05, 4.0), 0.0)
	var bz := gm.spawn_zombie_at(Vector3(0.0, 0.05, 2.2), ZombieAI.Variant.BRUISER, 0.0, false)
	bz._special_cd = 999.0
	for _k in range(20):
		bz._slam_cd = 0.0
		p.health = p.max_health
		await _phys(30)
		if seen_special.has("slam"):
			break
	print("STATES_SEEN ", seen_states.keys())
	print("SPECIALS_SEEN ", seen_special.keys())
	for need in ["WINDUP", "STRIKE", "RECOVER", "SPECIAL", "CHARGE", "LEAP", "GRAB"]:
		if not seen_states.has(need):
			fails.append("state never entered: " + need)
	for need in ["spit", "scream", "slam", "charge", "leap"]:
		if not seen_special.has(need):
			fails.append("special never used: " + need)

	# --- 2. every melee weapon: light combo, charged heavy, shove ---
	p.god_mode = true
	for mid in ["knife", "fire_axe", "machete", "bat", "bat_spiked", "crowbar"]:
		gm.clear_zombies()
		await _phys(2)
		_place_player(Vector3(0.0, 0.05, 4.0), 0.0)
		p.acquire_melee_weapon(mid)
		p.equip_melee_slot()
		var zs: Array[ZombieAI] = []
		for k in range(3):
			var z := gm.spawn_zombie_at(Vector3(-0.7 + k * 0.7, 0.05, 2.5), ZombieAI.Variant.ASYLUM_PATIENT, 0.0, false)
			z.move_speed = 0.0
			z.attack_cd = 999.0
			z.max_health = 9999.0
			z.health = 9999.0
			zs.append(z)
		await _phys(4)
		var hits_light := 0
		for _sw in range(3):
			_regroup(zs)
			await _phys(2)
			p.trigger_melee(false)
			await _phys(int(p._melee_dur * 60.0) + 14)
			hits_light += p._melee_swing_hits.size()
		# Fresh standing targets for the heavy as well
		gm.clear_zombies()
		await _phys(3)
		_place_player(Vector3(0.0, 0.05, 4.0), 0.0)
		zs.clear()
		for k in range(3):
			var zh := gm.spawn_zombie_at(Vector3(-0.7 + k * 0.7, 0.05, 2.5), ZombieAI.Variant.ASYLUM_PATIENT, 0.0, false)
			zh.move_speed = 0.0
			zh.attack_cd = 999.0
			zh.max_health = 9999.0
			zh.health = 9999.0
			zs.append(zh)
		await _phys(8)
		var hp_before := 0.0
		for z in zs:
			hp_before += z.health
		p._melee_charge = 1.0
		p.trigger_melee(true)
		var move := p._melee_move
		await _phys(int(p._melee_dur * 60.0) + 16)
		var hits_heavy := p._melee_swing_hits.size()
		var hp_after := 0.0
		var downed := 0
		var crawlers := 0
		for z in zs:
			if is_instance_valid(z):
				hp_after += z.health
				if z.state == ZombieAI.State.KNOCKDOWN:
					downed += 1
				if z.is_crawler:
					crawlers += 1
		# Fresh standing targets for the shove: the heavy may have left the first group flat, legless or dead
		gm.clear_zombies()
		await _phys(3)
		_place_player(Vector3(0.0, 0.05, 4.0), 0.0)
		for k in range(3):
			var zf := gm.spawn_zombie_at(Vector3(-0.7 + k * 0.7, 0.05, 2.5), ZombieAI.Variant.ASYLUM_PATIENT, 0.0, false)
			zf.move_speed = 0.0
			zf.attack_cd = 999.0
		await _phys(8)
		p._shove_cd = 0.0
		p.trigger_shove()
		await _phys(24)
		var shoved := p._melee_swing_hits.size()
		print("MELEE ", mid, " light_hits(3 swings)=", hits_light, " heavy_move=", move, " heavy_hits=", hits_heavy, " heavy_dmg=", snappedf(hp_before - hp_after, 1.0), " knockdowns=", downed, " crawlers=", crawlers, " shove_hits=", shoved)
		if hits_light < 3:
			fails.append("%s light combo connected only %d times" % [mid, hits_light])
		if hits_heavy < 1:
			fails.append("%s heavy missed" % mid)
		if shoved < 1:
			fails.append("%s shove missed" % mid)

	# --- 3. bruiser armour: visor soaks headshots then breaks ---
	gm.clear_zombies()
	await _phys(2)
	var br := gm.spawn_zombie_at(Vector3(0.0, 0.05, -2.0), ZombieAI.Variant.BRUISER, 0.0, false)
	br.move_speed = 0.0
	await _phys(3)
	var h0 := br.health
	var res1 := br.apply_shot([{"zone": "HEAD", "pos": br.face_focus_position(), "dir": Vector3.FORWARD, "dmg": 38.0, "dist": 5.0}], 0)
	print("BRUISER helmet_hp0=", 150.0, " after_one_headshot hp_loss=", snappedf(h0 - br.health, 0.1), " headshot_flag=", res1["headshot"], " armor_block=", res1.get("armor_block"), " helmet_left=", br._helmet_hp)
	if br._kit_parts.size() > 0 and bool(res1["headshot"]):
		fails.append("bruiser visor did not block the first headshot")

	# --- 4. economy and progression plumbing ---
	gm.points = 5000
	gm.on_generator_activated()
	var perk_ok := 0
	for inter: InteractableObject in gm.world.interactables:
		if inter.kind == InteractableObject.Kind.PERK:
			var msg := inter.interact(gm, p)
			if inter.activated:
				perk_ok += 1
			print("PERK ", inter.perk_id, " -> ", msg)
	print("PERKS tags=", p.get_perk_tags(), " max_hp=", p.max_health, " points_left=", gm.points)
	if perk_ok != 3:
		fails.append("expected 3 perks purchasable, got %d" % perk_ok)
	print("OBJECTIVE ", gm.get_objective())

	# --- 5. navigation: every spawn reaches every zone; sealed flights are not reachable ---
	gm.clear_zombies()
	await _phys(4)
	var w: WorldBuilder = gm.world
	if not ZombieAI.nav_enabled:
		fails.append("navigation mesh not loaded")
	else:
		var map := ZombieAI.nav_map
		var spawns: Array[Vector3] = []
		spawns.append_array(w.spawn_points)
		for extra in [w.sawmill_spawn_points, w.boiler_spawn_points, w.morgue_spawn_points]:
			for sp: Vector3 in extra:
				if not spawns.has(sp):
					spawns.append(sp)
		var targets := {
			"lobby": Vector3(-1.2, 0.05, 3.6), "stair landing": Vector3(-8.6, 3.6, -2.0), "tunnel": Vector3(0.0, 0.05, -18.0),
			"courtyard": Vector3(0.0, 0.2, -40.0), "boiler wing": Vector3(18.0, 0.05, 3.0), "morgue": Vector3(-30.0, 1.3, -48.0),
			"sawmill yard": Vector3(0.0, 0.6, -85.0), "sawmill shed": Vector3(17.0, 0.6, -82.0),
		}
		for tn in targets.keys():
			var tp: Vector3 = targets[tn]
			var unreachable := 0
			for sp in spawns:
				var path := NavigationServer3D.map_get_path(map, sp, tp, true)
				var ok := path.size() >= 2
				if ok:
					var last := path[path.size() - 1]
					ok = Vector2(last.x - tp.x, last.z - tp.z).length() < 2.2 and absf(last.y - tp.y) < 1.6 and Vector2(path[0].x - sp.x, path[0].z - sp.z).length() < 2.0
				if not ok:
					unreachable += 1
			print("NAV ", tn, " unreachable_spawns=", unreachable, "/", spawns.size())
			if unreachable > 0:
				fails.append("nav: %d spawns cannot reach %s" % [unreachable, tn])
		for dead_end: Vector3 in [Vector3(-5.24, 6.66, 2.2), Vector3(-4.3, 6.58, -2.6)]:
			var dp := NavigationServer3D.map_get_path(map, Vector3(-1.2, 0.05, 3.6), dead_end, true)
			if dp.size() >= 2 and dp[dp.size() - 1].distance_to(dead_end) < 1.5:
				fails.append("nav: sealed stair flight is reachable at %s" % str(dead_end))

	# --- 6. the starting staircase: up, down, and the sealed flights ---
	p.god_mode = true
	var up := await _walk_line(Vector3(-7.98, 0.0, 5.6), 0.0, 3.6)
	print("STAIR up end=", (up["end"] as Vector3).snapped(Vector3.ONE * 0.01), " air=", up["air"], " max_stall=", up["stall"])
	if absf((up["end"] as Vector3).y - 3.58) > 0.08 or int(up["air"]) > 2:
		fails.append("stairs: could not walk cleanly up the first flight")
	var down := await _walk_line(Vector3(-7.98, 3.58, -1.3), PI, 3.4)
	print("STAIR down end=", (down["end"] as Vector3).snapped(Vector3.ONE * 0.01), " air=", down["air"])
	if (down["end"] as Vector3).y > 0.06 or int(down["air"]) > 3:
		fails.append("stairs: descent left the ground (%d airborne frames)" % int(down["air"]))
	for blocked in [[Vector3(-5.27, 3.58, -2.5), PI, "south flight"], [Vector3(-8.9, 3.58, -2.6), -PI * 0.5, "return flight"]]:
		var bl := await _walk_line(blocked[0], float(blocked[1]), 3.0)
		print("STAIR sealed ", blocked[2], " end=", (bl["end"] as Vector3).snapped(Vector3.ONE * 0.01))
		if (bl["end"] as Vector3).y > 4.2:
			fails.append("stairs: the sealed %s can still be climbed" % str(blocked[2]))

	for f in fails:
		print("PHASE5_FAIL: ", f)
	if fails.is_empty():
		print("PHASE5_VERIFY_PASS compat=", RenderingServer.get_current_rendering_method() == "gl_compatibility")
	quit(0 if fails.is_empty() else 1)


func _walk_line(start: Vector3, yaw: float, secs: float) -> Dictionary:
	p.global_position = start
	p.velocity = Vector3.ZERO
	p.yaw = yaw
	p.pitch = 0.0
	p.rotation.y = yaw
	for _i in range(12):
		await physics_frame
	Input.action_press("move_forward")
	var air := 0
	var stall := 0
	var cur_stall := 0
	var last := p.global_position
	for _f in range(int(secs * 60.0)):
		await physics_frame
		if not p.is_on_floor():
			air += 1
		if p.global_position.distance_to(last) < 0.004:
			cur_stall += 1
			stall = maxi(stall, cur_stall)
		else:
			cur_stall = 0
		last = p.global_position
	Input.action_release("move_forward")
	await physics_frame
	return {"end": p.global_position, "air": air, "stall": stall}
