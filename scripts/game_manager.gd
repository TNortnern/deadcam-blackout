extends Node3D
class_name GameManager

const MOON_BASE := 0.24
const MAX_ATTACKERS := 2
const QUALITY_NAMES := ["PERFORMANCE", "HIGH", "ULTRA"]
const UPSCALER_NAMES := ["AUTO", "METALFX TEMPORAL", "METALFX SPATIAL", "NATIVE 100%"]
const RES_SCALE_VALS := [-1.0, 0.70, 0.78, 0.85, 0.92, 1.00]
const RES_SCALE_NAMES := ["AUTO", "70%", "78%", "85%", "92%", "100%"]

var render_vp: SubViewport
var world: WorldBuilder
var vfx: VFXManager
var player: PlayerBodycam
var hud: BodycamHUD
var ambient_audio: AudioStreamPlayer
var zombies_root: Node3D

var game_active: bool = false
var deterministic_mode: bool = false
var quality_preset: int = 1
var upscaler_mode_idx: int = 0
var res_scale_idx: int = 0
var bench_mode: bool = false
var _warmup_done: bool = false
var _perf_accum: float = 0.0
var wave: int = 1
var points: int = 600
var kills: int = 0
var headshots: int = 0
var zombies_to_spawn: int = 0
var spawn_timer: float = 0.0
var wave_pause_timer: float = 0.0
var wave_intermission_dur: float = 7.0
var thunder_timer: float = 18.0
var lightning_flash: float = 0.0
var power_restored: bool = false

var _active_attackers: Array[ZombieAI] = []
var _recent_spawns: Array[int] = []
static var _spawn_cue_streams: Array[AudioStream] = []


func _ready() -> void:
	render_vp = SubViewport.new()
	render_vp.name = "WorldViewport"
	render_vp.own_world_3d = true
	render_vp.world_3d = World3D.new()
	render_vp.handle_input_locally = false
	render_vp.audio_listener_enable_3d = true
	var is_web_or_compat := OS.has_feature("web") or RenderingServer.get_current_rendering_method() == "gl_compatibility"
	if is_web_or_compat:
		# WebGL2/GLES3 uses non-reverse-Z depth; 16-bit shadow atlas causes diagonal self-shadow striping past 4.5m!
		render_vp.positional_shadow_atlas_16_bits = false
	render_vp.positional_shadow_atlas_size = 2048 if (is_web_or_compat or quality_preset < 2) else 4096
	render_vp.set_positional_shadow_atlas_quadrant_subdiv(0, Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1)
	render_vp.set_positional_shadow_atlas_quadrant_subdiv(1, Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_4)
	render_vp.set_positional_shadow_atlas_quadrant_subdiv(2, Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_16)
	render_vp.set_positional_shadow_atlas_quadrant_subdiv(3, Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_64)
	render_vp.msaa_3d = Viewport.MSAA_DISABLED
	render_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	render_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(render_vp)

	if OS.has_feature("web") and not deterministic_mode and not OS.get_cmdline_user_args().has("--bench"):
		render_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		hud = BodycamHUD.new()
		hud.name = "HUD"
		add_child(hud)
		hud.set_world_texture(render_vp.get_texture())
		hud.start_requested.connect(start_game)
		hud.start_daylight_requested.connect(start_game_daylight)
		hud.restart_requested.connect(restart_game)
		hud.graphics_action.connect(_on_hud_graphics_action)
		hud.settings_closed.connect(_on_settings_closed)
		if hud.loading_overlay:
			hud.loading_overlay.visible = true
			hud.set_loading_status("BODYCAM-04 // INITIALIZING WEBGL2 OPTICS...")
		call_deferred("_run_web_async_boot")
		return

	world = WorldBuilder.new()
	world.name = "World"
	render_vp.add_child(world)
	world.build_world()

	vfx = VFXManager.new()
	vfx.name = "VFXManager"
	render_vp.add_child(vfx)
	vfx.prewarm()

	zombies_root = Node3D.new()
	zombies_root.name = "Zombies"
	render_vp.add_child(zombies_root)
	ZombieAI.preload_baked_assets()

	player = PlayerBodycam.new()
	player.name = "Player"
	player.game_manager = self
	render_vp.add_child(player)
	player.global_position = Vector3(-1.2, 0.05, 3.6)
	player.yaw = -0.35
	player.input_enabled = false

	hud = BodycamHUD.new()
	hud.name = "HUD"
	add_child(hud)
	hud.set_world_texture(render_vp.get_texture())
	hud.start_requested.connect(start_game)
	hud.start_daylight_requested.connect(start_game_daylight)
	hud.restart_requested.connect(restart_game)
	hud.graphics_action.connect(_on_hud_graphics_action)
	hud.settings_closed.connect(_on_settings_closed)

	player.player_died.connect(_on_player_died)
	player.hit_confirmed.connect(_on_hit_confirmed)
	player.status_message.connect(func(msg): hud.show_toast(msg))

	for p in ["res://assets/audio/zombie_growl_a.wav", "res://assets/audio/zombie_growl_b.wav"]:
		if ResourceLoader.exists(p):
			_spawn_cue_streams.append(load(p))

	ambient_audio = AudioStreamPlayer.new()
	var amb := load("res://assets/audio/ambient_horror.wav")
	if amb:
		if amb is AudioStreamWAV:
			amb.loop_mode = AudioStreamWAV.LOOP_FORWARD
			var full_len := int(round(amb.get_length() * float(amb.mix_rate)))
			amb.loop_end = full_len if full_len > 44100 else int(44100 * 4.0)
		ambient_audio.stream = amb
		ambient_audio.volume_db = -14.0
		add_child(ambient_audio)
		ambient_audio.play()

	_apply_viewport_perf()
	get_viewport().size_changed.connect(_apply_viewport_perf)
	world.update_zone_culling(player.camera)

	if OS.get_cmdline_user_args().has("--bench"):
		bench_mode = true
		call_deferred("_run_cli_bench")
	elif not deterministic_mode:
		if hud.loading_overlay:
			hud.loading_overlay.visible = true
		call_deferred("_run_startup_warmup")
	elif not OS.has_feature("web"):
		call_deferred("_refresh_probes_all_zones")


func get_renderer_label() -> String:
	var adapter := RenderingServer.get_video_adapter_name()
	if OS.has_feature("web") or RenderingServer.get_current_rendering_method() == "gl_compatibility":
		var compat_name := "WEBGL2" if OS.has_feature("web") else "COMPATIBILITY GL"
		return ("COMPATIBILITY  //  %s" % compat_name) if adapter.is_empty() else ("COMPATIBILITY  //  %s (%s)" % [compat_name, adapter])
	var os_name := OS.get_name()
	var backend := "METAL" if os_name == "macOS" else ("DIRECT3D 12" if os_name == "Windows" else "VULKAN")
	if adapter.is_empty():
		return "FORWARD+  //  NATIVE %s" % backend
	return "FORWARD+  //  NATIVE %s (%s)" % [backend, adapter]


func _sync_hud_graphics_state() -> void:
	if hud == null or world == null or render_vp == null:
		return
	var iw := int(round(render_vp.size.x * render_vp.scaling_3d_scale))
	var ih := int(round(render_vp.size.y * render_vp.scaling_3d_scale))
	var up_lbl: String = UPSCALER_NAMES[upscaler_mode_idx]
	var is_web_or_compat := OS.has_feature("web") or RenderingServer.get_current_rendering_method() == "gl_compatibility"
	if is_web_or_compat:
		var web_aa := ["AUTO (MSAA)", "MSAA 4X + FXAA", "MSAA 2X + FXAA", "FXAA ONLY"]
		up_lbl = web_aa[upscaler_mode_idx]
	elif OS.get_name() != "macOS":
		var win_upscalers := ["AUTO", "FSR 2.2", "FSR 1.0", "NATIVE 100%"]
		up_lbl = win_upscalers[upscaler_mode_idx]
	hud.update_settings_labels({
		"renderer": get_renderer_label(),
		"res_info": "3D %dx%d  ->  VP %dx%d  ->  OUT %dx%d" % [iw, ih, render_vp.size.x, render_vp.size.y, get_viewport().size.x, get_viewport().size.y],
		"preset": QUALITY_NAMES[quality_preset],
		"upscaler": up_lbl,
		"res_scale": RES_SCALE_NAMES[res_scale_idx],
		"ssr": world.user_ssr_enabled,
		"ssao": world.user_ssao_enabled,
		"vol_fog": world.user_vol_fog_enabled,
		"voxel_gi": world.user_voxel_gi_enabled,
		"pom": "HIGH" if world.user_pom_level >= 0.8 else ("LOW" if world.user_pom_level >= 0.3 else "OFF"),
		"telemetry": hud.perf_label.visible if hud.perf_label else false,
	})


func _on_hud_graphics_action(key: String) -> void:
	match key:
		"preset":
			quality_preset = (quality_preset + 1) % QUALITY_NAMES.size()
			upscaler_mode_idx = 0
			res_scale_idx = 0
			_apply_viewport_perf()
		"upscaler":
			upscaler_mode_idx = (upscaler_mode_idx + 1) % UPSCALER_NAMES.size()
			_apply_viewport_perf()
		"res_scale":
			res_scale_idx = (res_scale_idx + 1) % RES_SCALE_VALS.size()
			_apply_viewport_perf()
		"ssr":
			world.user_ssr_enabled = not world.user_ssr_enabled
			world.apply_graphics_toggles()
		"ssao":
			world.user_ssao_enabled = not world.user_ssao_enabled
			world.apply_graphics_toggles()
		"vol_fog":
			world.user_vol_fog_enabled = not world.user_vol_fog_enabled
			world.apply_graphics_toggles()
		"voxel_gi":
			world.user_voxel_gi_enabled = not world.user_voxel_gi_enabled
			world.apply_graphics_toggles()
		"pom":
			if world.user_pom_level >= 0.8:
				world.user_pom_level = 0.5
			elif world.user_pom_level >= 0.3:
				world.user_pom_level = 0.0
			else:
				world.user_pom_level = 1.0
			world.apply_graphics_toggles()
		"telemetry":
			if hud and hud.perf_label and render_vp:
				hud.perf_label.visible = not hud.perf_label.visible
				RenderingServer.viewport_set_measure_render_time(render_vp.get_viewport_rid(), hud.perf_label.visible)
	_sync_hud_graphics_state()


func _on_settings_closed() -> void:
	if hud and hud.settings_panel:
		hud.settings_panel.visible = false
	if game_active and player and not player.dead and not hud.title_panel.visible:
		player.input_enabled = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _apply_viewport_perf() -> void:
	var win_vp := get_viewport()
	if win_vp == null or render_vp == null:
		return
	var win_size := Vector2(win_vp.size)
	render_vp.mesh_lod_threshold = 1.5
	render_vp.use_occlusion_culling = not OS.has_feature("web")
	var is_web_or_compat := OS.has_feature("web") or RenderingServer.get_current_rendering_method() == "gl_compatibility"
	if deterministic_mode:
		render_vp.positional_shadow_atlas_size = 2048 if is_web_or_compat else 4096
		render_vp.size = win_vp.size
		render_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		render_vp.scaling_3d_scale = 1.0
		render_vp.use_taa = false
		render_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		if world:
			world.set_quality_preset(2)
		_sync_hud_graphics_state()
		return

	render_vp.positional_shadow_atlas_size = 2048 if (is_web_or_compat or quality_preset < 2) else 4096
	if is_web_or_compat:
		var base_cap := 900.0 if quality_preset == 0 else (1200.0 if quality_preset == 1 else 1440.0)
		var manual_sc: float = 1.0 if RES_SCALE_VALS[res_scale_idx] < 0.0 else float(RES_SCALE_VALS[res_scale_idx])
		var web_ratio := clampf((base_cap * manual_sc) / maxf(win_size.y, 1.0), 0.1, 1.0)
		render_vp.size = Vector2i(maxi(320, int(round(win_size.x * web_ratio))), maxi(180, int(round(win_size.y * web_ratio))))
		render_vp.use_taa = false
		render_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		render_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		render_vp.scaling_3d_scale = 1.0 # Single-pass sampling via post_rect; avoids double-bilinear blur!
		if upscaler_mode_idx == 1 or (upscaler_mode_idx == 0 and quality_preset >= 2):
			render_vp.msaa_3d = Viewport.MSAA_4X
		elif upscaler_mode_idx == 2 or (upscaler_mode_idx == 0 and quality_preset == 1):
			render_vp.msaa_3d = Viewport.MSAA_2X
		else:
			render_vp.msaa_3d = Viewport.MSAA_DISABLED
		if world:
			world.set_quality_preset(quality_preset)
		_sync_hud_graphics_state()
		return

	var os_name := OS.get_name()
	var cap_h := (1080.0 if quality_preset == 0 else (1200.0 if quality_preset == 1 else 1600.0)) if os_name == "macOS" else (1080.0 if quality_preset == 0 else (1200.0 if quality_preset == 1 else 1440.0))
	var vp_ratio := clampf(cap_h / maxf(win_size.y, 1.0), 0.1, 1.0)
	render_vp.size = Vector2i(maxi(320, int(round(win_size.x * vp_ratio))), maxi(180, int(round(win_size.y * vp_ratio))))
	var h := float(render_vp.size.y)
	if os_name == "macOS":
		render_vp.use_taa = false
		var target_scale := 0.78 if quality_preset == 0 else (0.85 if quality_preset == 1 else 0.90)
		var target_mode := Viewport.SCALING_3D_MODE_METALFX_SPATIAL if quality_preset <= 1 else Viewport.SCALING_3D_MODE_METALFX_TEMPORAL
		if upscaler_mode_idx == 1:
			target_mode = Viewport.SCALING_3D_MODE_METALFX_TEMPORAL
		elif upscaler_mode_idx == 2:
			target_mode = Viewport.SCALING_3D_MODE_METALFX_SPATIAL
		elif upscaler_mode_idx == 3:
			target_mode = Viewport.SCALING_3D_MODE_BILINEAR
			target_scale = 1.0
		if RES_SCALE_VALS[res_scale_idx] > 0.0:
			target_scale = RES_SCALE_VALS[res_scale_idx]
		render_vp.scaling_3d_mode = target_mode
		render_vp.scaling_3d_scale = target_scale
		render_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA if (target_mode == Viewport.SCALING_3D_MODE_METALFX_SPATIAL and quality_preset >= 1) else Viewport.SCREEN_SPACE_AA_DISABLED
	else:
		render_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		if h >= 900.0 or upscaler_mode_idx > 0:
			if upscaler_mode_idx == 3:
				render_vp.use_taa = false
				render_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
				render_vp.scaling_3d_scale = 1.0
			elif upscaler_mode_idx == 2 or (upscaler_mode_idx == 0 and quality_preset == 0):
				render_vp.use_taa = true
				render_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
				render_vp.fsr_sharpness = 0.25
				render_vp.scaling_3d_scale = 0.78 if RES_SCALE_VALS[res_scale_idx] < 0.0 else RES_SCALE_VALS[res_scale_idx]
			else:
				render_vp.use_taa = false
				render_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
				render_vp.fsr_sharpness = 0.25
				var def_sc := 0.80 if quality_preset == 1 else 0.86
				render_vp.scaling_3d_scale = def_sc if RES_SCALE_VALS[res_scale_idx] < 0.0 else RES_SCALE_VALS[res_scale_idx]
		elif h > 640.0:
			render_vp.use_taa = (quality_preset == 0)
			render_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
			render_vp.fsr_sharpness = 0.25
			var def_sc2 := 0.78 if quality_preset == 0 else (0.82 if quality_preset == 1 else 0.90)
			render_vp.scaling_3d_scale = def_sc2 if RES_SCALE_VALS[res_scale_idx] < 0.0 else RES_SCALE_VALS[res_scale_idx]
		else:
			render_vp.use_taa = false
			render_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			render_vp.scaling_3d_scale = 1.0 if RES_SCALE_VALS[res_scale_idx] < 0.0 else RES_SCALE_VALS[res_scale_idx]
	if world:
		world.set_quality_preset(quality_preset)
	_sync_hud_graphics_state()


func request_attack_token(z: ZombieAI) -> bool:
	var i := _active_attackers.size() - 1
	while i >= 0:
		var a: ZombieAI = _active_attackers[i]
		if not is_instance_valid(a) or a.dead or (a.state != ZombieAI.State.WINDUP and a.state != ZombieAI.State.STRIKE and a.state != ZombieAI.State.RECOVER):
			_active_attackers.remove_at(i)
		i -= 1
	if z in _active_attackers:
		return true
	if _active_attackers.size() < MAX_ATTACKERS:
		_active_attackers.append(z)
		return true
	return false


func release_attack_token(z: ZombieAI) -> void:
	_active_attackers.erase(z)


func start_game() -> void:
	game_active = true
	if world and world.daylight_mode:
		world.set_daylight_mode(false)
	if ambient_audio and not ambient_audio.playing:
		ambient_audio.play()
	hud.title_panel.visible = false
	hud.defeat_panel.visible = false
	player.input_enabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_start_wave(1)
	hud.show_toast("WAVE 01 — SURVIVE THE BLACKOUT")


func start_game_daylight() -> void:
	game_active = true
	if world:
		world.set_daylight_mode(true)
	if player:
		player.global_position = Vector3(0.0, 0.05, -36.5)
		player.yaw = 0.0
		player.pitch = 0.0
		player.rotation.y = 0.0
		player.head.rotation = Vector3.ZERO
		if player.flashlight_on:
			player.toggle_flashlight()
		if world:
			world.update_zone_culling(player.camera)
	if ambient_audio and not ambient_audio.playing:
		ambient_audio.play()
	hud.title_panel.visible = false
	hud.defeat_panel.visible = false
	player.input_enabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_start_wave(1)
	hud.show_toast("WINTER DAYLIGHT — OUTDOOR SHOWCASE [F9 TOGGLE]")


func restart_game() -> void:
	for c in zombies_root.get_children():
		c.queue_free()
	_active_attackers.clear()
	_recent_spawns.clear()
	wave_pause_timer = 0.0
	player.heal_full(true)
	player.global_position = Vector3(-1.2, 0.05, 3.6)
	player.yaw = -0.35
	player.pitch = 0.0
	points = 600
	kills = 0
	headshots = 0
	power_restored = false
	world.set_asylum_power(false)
	if world.sawmill_gate_open:
		world.sawmill_gate_open = false
		for sp: Vector3 in world.sawmill_spawn_points:
			world.spawn_points.erase(sp)
	for inter: InteractableObject in world.interactables:
		if is_instance_valid(inter) and inter.has_method("reset_state"):
			inter.reset_state()
	start_game()


func _unhandled_input(event: InputEvent) -> void:
	if deterministic_mode:
		return
	var settings_open := (hud != null and hud.settings_panel != null and hud.settings_panel.visible)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F3 and hud and hud.perf_label and render_vp:
			hud.perf_label.visible = not hud.perf_label.visible
			RenderingServer.viewport_set_measure_render_time(render_vp.get_viewport_rid(), hud.perf_label.visible)
			_sync_hud_graphics_state()
		elif event.physical_keycode == KEY_F8:
			quality_preset = (quality_preset + 1) % QUALITY_NAMES.size()
			upscaler_mode_idx = 0
			res_scale_idx = 0
			_apply_viewport_perf()
			if hud:
				hud.show_toast("GRAPHICS PRESET: %s" % QUALITY_NAMES[quality_preset])
		elif event.physical_keycode == KEY_F9 and world:
			world.set_daylight_mode(not world.daylight_mode)
			if hud:
				hud.show_toast("LIGHTING: %s [F9]" % ("WINTER DAYLIGHT" if world.daylight_mode else "BLACKOUT NIGHT"))
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		if settings_open:
			_on_settings_closed()
			return
		elif hud and hud.settings_panel:
			_sync_hud_graphics_state()
			hud.settings_panel.visible = true
			if player:
				player.input_enabled = false
				if player.has_method("cancel_bow_draw"):
					player.cancel_bow_draw(true)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			return
	elif event is InputEventMouseButton and event.pressed and game_active and not player.dead:
		if settings_open or (hud and hud.title_panel.visible):
			return
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if not settings_open and player and is_instance_valid(player):
		player._unhandled_input(event)


func _start_wave(w: int) -> void:
	wave = w
	if w == 1:
		zombies_to_spawn = 6
		spawn_timer = 1.6
	elif w == 2:
		zombies_to_spawn = 9
		spawn_timer = 1.4
	else:
		zombies_to_spawn = 7 + w * 2
		spawn_timer = 1.1


func _pick_fair_spawn_point() -> Dictionary:
	var pts := world.spawn_points
	if pts.is_empty():
		return {"ok": false}
	var ppos := player.global_position
	var cam := player.camera
	var space := render_vp.world_3d.direct_space_state if render_vp else get_world_3d().direct_space_state
	var min_d := 10.5 if ppos.z > -27.0 else 14.0
	var max_d := 36.0
	var cands: Array[Dictionary] = []

	for idx in range(pts.size()):
		var sp: Vector3 = pts[idx]
		var d := ppos.distance_to(sp)
		if d < min_d or d > max_d:
			continue
		var occupied := false
		for z in zombies_root.get_children():
			if z is ZombieAI and not z.dead and z.global_position.distance_to(sp) < 2.2:
				occupied = true
				break
		if occupied:
			continue

		var visible_in_los := false
		if cam and cam.is_position_in_frustum(sp + Vector3(0, 1.25, 0)):
			if space:
				var q := PhysicsRayQueryParameters3D.create(cam.global_position, sp + Vector3(0, 1.25, 0), 1)
				if not space.intersect_ray(q):
					visible_in_los = true
			else:
				visible_in_los = true

		# Prefer out-of-FOV / occluded, 13-25m distance, and not recently used!
		var score := 100.0
		if visible_in_los:
			score -= 90.0
		if d >= 13.0 and d <= 25.0:
			score += 25.0
		else:
			score -= absf(d - 19.0) * 1.4
		if idx in _recent_spawns:
			score -= 35.0
		score += randf_range(-6.0, 6.0)
		cands.append({"idx": idx, "pos": sp, "score": score, "visible": visible_in_los})

	if cands.is_empty():
		return {"ok": false}
	# Strictly prefer occluded/out-of-FOV spawns so zombies never pop in on screen!
	var hidden_cands: Array[Dictionary] = []
	for c: Dictionary in cands:
		if not bool(c["visible"]):
			hidden_cands.append(c)
	var use_cands: Array[Dictionary] = hidden_cands if not hidden_cands.is_empty() else cands
	use_cands.sort_custom(func(a, b): return a["score"] > b["score"])
	var pick_pool := mini(3, use_cands.size())
	var chosen: Dictionary = use_cands[randi() % pick_pool]
	_recent_spawns.append(int(chosen["idx"]))
	if _recent_spawns.size() > 3:
		_recent_spawns.pop_front()
	var sp_pos: Vector3 = chosen["pos"]
	var face_yaw := atan2(ppos.x - sp_pos.x, ppos.z - sp_pos.z)
	return {"ok": true, "pos": sp_pos, "yaw": face_yaw}


func relocate_stuck_zombie(z: ZombieAI) -> void:
	if z == null or not is_instance_valid(z) or z.dead or player == null:
		return
	var pick := _pick_fair_spawn_point()
	if pick.get("ok", false):
		z.global_position = pick["pos"]
		z.rotation.y = float(pick.get("yaw", 0.0))
		z.velocity = Vector3.ZERO


func spawn_zombie_at(pos: Vector3, variant: ZombieAI.Variant, yaw_rad := 0.0, with_cue := false) -> ZombieAI:
	var z := ZombieAI.new()
	z.variant = variant
	z.target = player
	zombies_root.add_child(z)
	z.global_position = pos
	z.rotation.y = yaw_rad
	z.died.connect(_on_zombie_died)
	if with_cue:
		z.enter_spawn_cue(0.95)
	return z


func clear_zombies() -> void:
	_active_attackers.clear()
	for c in zombies_root.get_children():
		c.queue_free()


func get_living_zombies() -> int:
	var n := 0
	for c in zombies_root.get_children():
		if c is ZombieAI and not c.dead:
			n += 1
	return n


func add_points(delta_pts: int) -> void:
	points = max(0, points + delta_pts)


func on_generator_activated() -> void:
	power_restored = true
	world.set_asylum_power(true)
	for inter: InteractableObject in world.interactables:
		if is_instance_valid(inter) and inter.kind == InteractableObject.Kind.UPGRADE_BENCH:
			inter.activated = true
	add_points(200)


func on_sawmill_gate_opened() -> void:
	if world == null or world.sawmill_gate_open:
		return
	world.sawmill_gate_open = true
	for sp: Vector3 in world.sawmill_spawn_points:
		if not (sp in world.spawn_points):
			world.spawn_points.append(sp)


func _on_hit_confirmed(is_headshot: bool, killed: bool) -> void:
	hud.show_hit(is_headshot, killed)
	if killed:
		add_points(150 if is_headshot else 100)


func _on_zombie_died(z: ZombieAI, was_headshot: bool) -> void:
	release_attack_token(z)
	kills += 1
	if was_headshot:
		headshots += 1


func _on_player_died() -> void:
	game_active = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hud.defeat_info.text = "SURVIVED WAVE %d  •  KILLS: %d  •  HEADSHOTS: %d" % [wave, kills, headshots]
	hud.defeat_panel.visible = true


func _process(delta: float) -> void:
	if world == null or player == null or hud == null:
		return
	if world and player and player.camera:
		world.update_zone_culling(player.camera)
	var living_z := get_living_zombies()
	hud.update_hud(delta, player, wave, points, living_z + zombies_to_spawn, living_z)
	if hud.perf_label and hud.perf_label.visible and render_vp:
		_perf_accum += delta
		if _perf_accum >= 0.25:
			_perf_accum = 0.0
			var r_rid := render_vp.get_viewport_rid()
			var gpu_ms := RenderingServer.viewport_get_measured_render_time_gpu(r_rid)
			var cpu_ms := RenderingServer.viewport_get_measured_render_time_cpu(r_rid)
			var iw := int(round(render_vp.size.x * render_vp.scaling_3d_scale))
			var ih := int(round(render_vp.size.y * render_vp.scaling_3d_scale))
			hud.perf_label.text = "%d FPS | GPU %.1fms | CPU %.1fms\n3D %dx%d -> VP %dx%d | %s [F8]" % [
				Engine.get_frames_per_second(), gpu_ms, cpu_ms, iw, ih, render_vp.size.x, render_vp.size.y, QUALITY_NAMES[quality_preset]
			]
	if deterministic_mode:
		return

	# Outdoor-gated moon & distant lightning (STRICTLY skipped during live daylight_mode so sun_energy=2.45 is never overwritten!)
	if not world.daylight_mode:
		if lightning_flash > 0.0:
			lightning_flash = maxf(0.0, lightning_flash - delta * 4.5)
		else:
			thunder_timer -= delta
			if thunder_timer <= 0.0:
				thunder_timer = randf_range(16.0, 32.0)
				lightning_flash = 1.0
		var outdoor_weight := smoothstep(-25.0, -30.5, player.global_position.z)
		var moon_vis := outdoor_weight > 0.001
		if world.moon_light.visible != moon_vis:
			world.moon_light.visible = moon_vis
		var want_moon_e := MOON_BASE * outdoor_weight
		if moon_vis and absf(world.moon_light.light_energy - want_moon_e) > 0.001:
			world.moon_light.light_energy = want_moon_e
		if world.lightning_light:
			var l_vis := moon_vis and lightning_flash > 0.01
			if world.lightning_light.visible != l_vis:
				world.lightning_light.visible = l_vis
			if l_vis:
				world.lightning_light.light_energy = lightning_flash * 2.8 * outdoor_weight
	elif world.lightning_light and world.lightning_light.visible:
		world.lightning_light.visible = false
		world.lightning_light.light_energy = 0.0

	if not game_active or player.dead:
		return

	var alive_cap := 4 if wave == 1 else (6 if wave == 2 else mini(11, 5 + wave))
	if zombies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0 and get_living_zombies() < alive_cap:
			var pick := _pick_fair_spawn_point()
			if pick["ok"]:
				zombies_to_spawn -= 1
				spawn_timer = 2.9 if wave == 1 else (2.3 if wave == 2 else maxf(0.85, 2.5 - wave * 0.16))
				var v := ZombieAI.Variant.ASYLUM_PATIENT
				if wave == 2:
					v = ZombieAI.Variant.TACTICAL_SOLDIER if randf() < 0.25 else ZombieAI.Variant.ASYLUM_PATIENT
				elif wave >= 3:
					var r := randf()
					v = ZombieAI.Variant.TACTICAL_SOLDIER if r < 0.38 else (ZombieAI.Variant.RUNNER if r < 0.68 else ZombieAI.Variant.ASYLUM_PATIENT)
				spawn_zombie_at(pick["pos"], v, float(pick.get("yaw", 0.0)), true)
			else:
				spawn_timer = 0.45
	elif get_living_zombies() == 0:
		if wave_pause_timer == 0.0:
			hud.show_toast("WAVE %02d CLEARED — RELOAD & REGROUP" % wave)
		wave_pause_timer += delta
		if wave_pause_timer >= wave_intermission_dur:
			wave_pause_timer = 0.0
			_start_wave(wave + 1)
			hud.show_toast("WAVE %02d INCOMING" % wave)


func _run_web_async_boot() -> void:
	var tree := get_tree()
	await tree.process_frame

	world = WorldBuilder.new()
	world.name = "World"
	render_vp.add_child(world)
	await world.build_world_web_async(hud)

	hud.set_loading_status("BODYCAM-04 // ALLOCATING VFX POOLS...")
	vfx = VFXManager.new()
	vfx.name = "VFXManager"
	render_vp.add_child(vfx)
	vfx.prewarm()
	await tree.process_frame

	zombies_root = Node3D.new()
	zombies_root.name = "Zombies"
	render_vp.add_child(zombies_root)
	ZombieAI._ensure_audio_loaded()
	var z_idx := 0
	for v in ZombieAI.BAKED_PATHS.keys():
		z_idx += 1
		hud.set_loading_status("BODYCAM-04 // LOADING INFECTED MODELS (%d/%d)..." % [z_idx, ZombieAI.BAKED_PATHS.size()])
		var bp: String = ZombieAI.BAKED_PATHS[v]
		if not ZombieAI._baked_scene_cache.has(v) and ResourceLoader.exists(bp):
			ZombieAI._baked_scene_cache[v] = load(bp)
		await tree.process_frame

	player = PlayerBodycam.new()
	player.name = "Player"
	player.game_manager = self
	player.skip_initial_weapon_prebuild = true
	render_vp.add_child(player)
	await player.prebuild_weapon_rigs_web_async(hud)
	player.global_position = Vector3(-1.2, 0.05, 3.6)
	player.yaw = -0.35
	player.input_enabled = false

	player.player_died.connect(_on_player_died)
	player.hit_confirmed.connect(_on_hit_confirmed)
	player.status_message.connect(func(msg): hud.show_toast(msg))

	for p in ["res://assets/audio/zombie_growl_a.wav", "res://assets/audio/zombie_growl_b.wav"]:
		if ResourceLoader.exists(p):
			_spawn_cue_streams.append(load(p))

	ambient_audio = AudioStreamPlayer.new()
	var amb := load("res://assets/audio/ambient_horror.wav")
	if amb:
		if amb is AudioStreamWAV:
			amb.loop_mode = AudioStreamWAV.LOOP_FORWARD
			var full_len := int(round(amb.get_length() * float(amb.mix_rate)))
			amb.loop_end = full_len if full_len > 44100 else int(44100 * 4.0)
		ambient_audio.stream = amb
		ambient_audio.volume_db = -14.0
		add_child(ambient_audio)
		ambient_audio.play()

	_apply_viewport_perf()
	get_viewport().size_changed.connect(_apply_viewport_perf)
	world.update_zone_culling(player.camera)
	await _run_web_shader_warmup()


func _run_web_shader_warmup() -> void:
	if _warmup_done:
		return
	_warmup_done = true
	var tree := get_tree()
	var saved_lock := world.debug_lock_env
	world.debug_lock_env = true

	var step := 0
	var total_steps := 10
	var _render_step := func(label: String) -> void:
		step += 1
		if hud:
			hud.set_loading_status("BODYCAM-04 // COMPILING SHADERS (%d/%d): %s" % [step, total_steps, label])
		render_vp.render_target_update_mode = SubViewport.UPDATE_ONCE

	# Steps 1-3: Each zombie variant directly in front of camera under flashlight + lobby omni
	var warm_z: Array[ZombieAI] = []
	for i in range(3):
		var v := i as ZombieAI.Variant
		var z := spawn_zombie_at(Vector3(-1.2 + (i - 1) * 0.85, 0.05, 0.8), v, PI, false)
		z.move_speed = 0.0
		warm_z.append(z)
		_render_step.call("INFECTED %d/3" % (i + 1))
		await tree.process_frame

	# Steps 4-6: Weapons 0/1/2 with muzzle lights + muzzle flash rig visible (compiles dynamic-light + flash shaders!)
	player.muzzle_light.visible = true
	player.muzzle_light.light_energy = 1.5
	player.muzzle_vm_light.visible = true
	player.muzzle_vm_light.light_energy = 0.8
	player.muzzle_flash_rig.visible = true
	for w_idx in [1, 2, 4, 5, 6, 7, 8, 9, 10, 0]:
		player._equip_weapon(w_idx, true)
		_render_step.call("WEAPON %d/10" % (w_idx + 1))
		await tree.process_frame
	player.muzzle_light.visible = false
	player.muzzle_light.light_energy = 0.0
	player.muzzle_vm_light.visible = false
	player.muzzle_vm_light.light_energy = 0.0
	player.muzzle_flash_rig.visible = false

	# Step 7: In-frustum VFX + head dismemberment/ragdoll stump warmup
	if vfx:
		vfx.run_pipeline_warmup(player.camera.global_position, -player.camera.global_transform.basis.z)
	if not warm_z.is_empty() and is_instance_valid(warm_z[2]):
		warm_z[2].apply_shot([{"zone": "HEAD", "pos": warm_z[2].face_focus_position(), "dir": Vector3.FORWARD, "dmg": 400.0, "dist": 3.0}], 2)
	_render_step.call("COMBAT VFX")
	await tree.process_frame

	# Step 8: Catacomb Tunnel
	player.global_position = Vector3(0.0, 0.05, -16.0)
	player.yaw = 0.0
	world.update_zone_culling(player.camera)
	_render_step.call("CATACOMB TUNNEL")
	await tree.process_frame

	# Step 9: Courtyard with BOTH moon_light and lightning_light active (prevents t=18s thunder hitch!)
	player.global_position = Vector3(0.0, 0.05, -40.0)
	world.update_zone_culling(player.camera)
	if world.moon_light:
		world.moon_light.visible = true
		world.moon_light.light_energy = MOON_BASE
	if world.lightning_light:
		world.lightning_light.visible = true
		world.lightning_light.light_energy = 0.05
	_render_step.call("WINTER COURTYARD")
	await tree.process_frame

	# Step 10: Cabin + Frozen Sawmill + Evidence Chest & Upgrade Bench shader warmup!
	player.global_position = Vector3(8.0, 0.5, -72.0)
	player.yaw = 0.0
	world.update_zone_culling(player.camera)
	_render_step.call("CABIN & SAWMILL")
	await tree.process_frame

	# Restore clean initial lobby state
	clear_zombies()
	if vfx:
		vfx.clear_warmup_effects()
	if world.moon_light:
		world.moon_light.visible = false
		world.moon_light.light_energy = 0.0
	if world.lightning_light:
		world.lightning_light.visible = false
		world.lightning_light.light_energy = 0.0
	points = 600
	kills = 0
	headshots = 0
	player.global_position = Vector3(-1.2, 0.05, 3.6)
	player.yaw = -0.35
	player.pitch = 0.0
	player._equip_weapon(0)
	world.debug_lock_env = saved_lock
	world.update_zone_culling(player.camera)
	render_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await tree.process_frame
	if hud and hud.loading_overlay:
		hud.loading_overlay.visible = false


func _run_startup_warmup() -> void:
	if _warmup_done:
		return
	_warmup_done = true
	if deterministic_mode or bench_mode or hud == null or not hud.title_panel.visible:
		if not deterministic_mode and not bench_mode:
			await _refresh_probes_all_zones()
		if hud and hud.loading_overlay:
			hud.loading_overlay.visible = false
		return

	if OS.has_feature("web"):
		await get_tree().process_frame
		await get_tree().process_frame
		if hud.loading_overlay:
			hud.loading_overlay.visible = false
		return

	if hud.loading_overlay:
		hud.loading_overlay.visible = true
	var tree := get_tree()
	await tree.process_frame

	# Bake VoxelGIs if pre-baked assets/baked/gi_*.res did not exist
	var needs_gi_bake := false
	for gi in world.voxel_gis:
		if gi.data == null:
			needs_gi_bake = true
			break
	if needs_gi_bake:
		world.bake_voxel_gis(false)
		await tree.process_frame

	# Capture ReflectionProbes while all zones and courtyard foliage are visible
	world.set_all_zones_visible_for_bake(true)
	world.refresh_reflection_probes()
	await tree.process_frame
	await tree.process_frame

	# Exercise all 3 zombie variants, VFX decals/particles/blood pools, weapons, and all 4 zones!
	var saved_lock := world.debug_lock_env
	world.debug_lock_env = true
	var warm_z: Array[ZombieAI] = []
	for i in range(3):
		var v := i as ZombieAI.Variant
		var z := spawn_zombie_at(Vector3(-1.8 + i * 1.4, 0.05, 0.2), v, PI, false)
		z.move_speed = 0.0
		warm_z.append(z)
	for w_idx in [1, 2, 0]:
		player._equip_weapon(w_idx, true)
		await tree.process_frame

	if vfx:
		vfx.run_pipeline_warmup(player.camera.global_position, -player.camera.global_transform.basis.z)
	await tree.process_frame
	if not warm_z.is_empty() and is_instance_valid(warm_z[2]):
		warm_z[2].apply_shot([{"zone": "HEAD", "pos": warm_z[2].face_focus_position(), "dir": Vector3.FORWARD, "dmg": 400.0, "dist": 3.0}], 2)
	for cam_z in [-16.0, -40.0, -54.0, 3.6]:
		player.global_position = Vector3(-1.2, 0.05, cam_z)
		world.update_zone_culling(player.camera)
		await tree.process_frame

	clear_zombies()
	if vfx:
		vfx.clear_warmup_effects()
	points = 600
	kills = 0
	headshots = 0
	player.global_position = Vector3(-1.2, 0.05, 3.6)
	player.yaw = -0.35
	player.pitch = 0.0
	player._equip_weapon(0)
	world.debug_lock_env = saved_lock
	world.set_all_zones_visible_for_bake(false)
	world.update_zone_culling(player.camera)
	await tree.process_frame
	if hud.loading_overlay:
		hud.loading_overlay.visible = false


func _refresh_probes_all_zones() -> void:
	if world == null or OS.has_feature("web"):
		return
	var tree := get_tree()
	world.set_all_zones_visible_for_bake(true)
	world.refresh_reflection_probes()
	await tree.process_frame
	await tree.process_frame
	world.set_all_zones_visible_for_bake(false)
	if player and player.camera:
		world.update_zone_culling(player.camera)


func _run_cli_bench() -> void:
	await _refresh_probes_all_zones()
	var tree := get_tree()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	hud.set_capture_mode(true)
	if hud.loading_overlay:
		hud.loading_overlay.visible = false
	var r_rid := render_vp.get_viewport_rid()
	var w_rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(r_rid, true)
	RenderingServer.viewport_set_measure_render_time(w_rid, true)
	print("BENCH PRESET:", QUALITY_NAMES[quality_preset], " VP_SIZE:", render_vp.size, " SCALE_MODE:", render_vp.scaling_3d_mode, " SCALE:", render_vp.scaling_3d_scale, " TAA:", render_vp.use_taa)

	var views := [
		{"name": "lobby_0z", "pos": Vector3(-0.35, 0.05, 1.35), "yaw": -0.95, "pitch": -0.05, "zombies": 0},
		{"name": "lobby_6z", "pos": Vector3(-0.35, 0.05, 1.35), "yaw": -0.95, "pitch": -0.05, "zombies": 6},
		{"name": "tunnel", "pos": Vector3(0.0, 0.05, -13.0), "yaw": 0.0, "pitch": -0.04, "zombies": 0},
		{"name": "courtyard", "pos": Vector3(0.0, 0.05, -35.0), "yaw": 0.0, "pitch": -0.04, "zombies": 0},
	]
	for vw in views:
		clear_zombies()
		player.set_deterministic_view(vw["pos"], vw["yaw"], vw["pitch"], 1, false, true, 0.0)
		world.update_zone_culling(player.camera)
		for k in range(int(vw["zombies"])):
			var zv := ZombieAI.Variant.TACTICAL_SOLDIER if k % 2 == 0 else ZombieAI.Variant.RUNNER
			var z := spawn_zombie_at(Vector3(-2.5 + k * 1.1, 0.05, -2.5), zv, 0.0)
			z.move_speed = 0.0
		for _w in range(10):
			await tree.process_frame
		var t0 := Time.get_ticks_usec()
		var gpu3d := 0.0
		var gpuwin := 0.0
		for _f in range(30):
			await tree.process_frame
			gpu3d += RenderingServer.viewport_get_measured_render_time_gpu(r_rid)
			gpuwin += RenderingServer.viewport_get_measured_render_time_gpu(w_rid)
		var ms := (Time.get_ticks_usec() - t0) / 1000.0 / 30.0
		print("BENCH %-12s | %6.2f ms (%5.1f FPS) | 3D_GPU %.2f ms | WIN_GPU %.2f ms" % [vw["name"], ms, 1000.0 / maxf(ms, 0.001), gpu3d / 30.0, gpuwin / 30.0])
	tree.quit(0)
