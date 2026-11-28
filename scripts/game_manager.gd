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
	process_mode = Node.PROCESS_MODE_ALWAYS
	render_vp = SubViewport.new()
	render_vp.name = "WorldViewport"
	render_vp.process_mode = Node.PROCESS_MODE_PAUSABLE
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
		_connect_hud()
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
	_connect_hud()

	_post_player_setup()

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


func _is_any_overlay_open() -> bool:
	if hud == null:
		return false
	return (hud.settings_panel != null and hud.settings_panel.visible) or (hud.inventory_panel != null and hud.inventory_panel.visible) or (hud.dev_panel != null and hud.dev_panel.visible)


func _open_overlay(which: String) -> void:
	if hud == null:
		return
	if hud.settings_panel:
		hud.settings_panel.visible = (which == "settings")
	if hud.inventory_panel:
		hud.inventory_panel.visible = (which == "inventory")
	if hud.dev_panel:
		hud.dev_panel.visible = (which == "dev")
	if which == "settings":
		_sync_hud_graphics_state()
		_apply_options()
		hud.set_settings_context(game_active and player != null and not player.dead)
	elif which == "inventory" and player:
		hud.refresh_inventory(player)
	elif which == "dev" and player:
		hud.refresh_dev_menu(player)
	if game_active:
		get_tree().paused = true
	if player:
		player.input_enabled = false
		if player.has_method("cancel_bow_draw"):
			player.cancel_bow_draw(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _open_inventory() -> void:
	if not game_active or player == null or player.dead:
		return
	_open_overlay("inventory")


func _close_all_overlays() -> void:
	if hud:
		if hud.settings_panel:
			hud.settings_panel.visible = false
		if hud.inventory_panel:
			hud.inventory_panel.visible = false
		if hud.dev_panel:
			hud.dev_panel.visible = false
	get_tree().paused = false
	if game_active and player and not player.dead and (hud == null or not hud.title_panel.visible):
		player.input_enabled = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_settings_closed() -> void:
	_save_settings()
	_close_all_overlays()


func _on_inventory_action(action: String, arg: Variant) -> void:
	if player == null:
		return
	match action:
		"swap":
			var pair: Array = arg
			if pair.size() == 2:
				player.swap_firearm_slots(int(pair[0]), int(pair[1]))
		"equip_slot":
			player.equip_firearm_slot(int(arg))
		"equip_special":
			player.equip_special_slot()
		"drop_slot":
			player.drop_firearm_slot(int(arg))
		"select_melee":
			player.select_melee_weapon(str(arg))
		"select_grenade":
			player.select_grenade(str(arg))
	if hud:
		hud.refresh_inventory(player)


func _on_dev_action(action: String, arg: Variant) -> void:
	if player == null:
		return
	match action:
		"give_weapon":
			var wi := int(arg)
			var res := player.acquire_weapon(wi, true)
			if hud:
				hud.show_toast("DEV: SPAWNED [%s] %s" % [str(res.get("slot_key", "?")), PlayerBodycam.WEAPONS[wi]["name"]])
		"give_melee":
			var mid := str(arg)
			player.acquire_melee_weapon(mid)
			player.equip_melee_slot()
			if hud:
				hud.show_toast("DEV: EQUIPPED %s" % PlayerBodycam.MELEE_CATALOG[mid]["name"])
		"add_points":
			points += 5000
			if hud:
				hud.show_toast("DEV: +5000 PTS (TOTAL %d)" % points)
		"refill_all":
			player.dev_give_all_ammo_and_grenades()
			if hud:
				hud.show_toast("DEV: AMMO & GRENADES MAXED")
		"toggle_god":
			player.god_mode = not player.god_mode
			if player.god_mode:
				player.health = player.max_health
			if hud:
				hud.show_toast("DEV: GOD MODE %s" % ("ON" if player.god_mode else "OFF"))
		"upgrade_cur":
			if bool(PlayerBodycam.WEAPONS[player.current_weapon].get("is_melee", false)):
				if player.equipped_melee_id == "bat":
					player.acquire_melee_weapon("bat_spiked")
					if hud:
						hud.show_toast("DEV: UPGRADED TO SPIKED BASEBALL BAT")
			else:
				player.is_reloading = false
				player._burst_remaining = 0
				player._burst_timer = 0.0
				player.reload_pos_off = Vector3.ZERO
				player.reload_rot_off = Vector3.ZERO
				player.upgrade_weapon(player.current_weapon)
				player._reset_weapon_parts()
				if hud:
					hud.show_toast("DEV: UPGRADED %s TO MK-II" % PlayerBodycam.WEAPONS[player.current_weapon]["name"])
		"attach_optic":
			var cur_w := player.current_weapon
			var wd_o: Dictionary = PlayerBodycam.WEAPONS[cur_w]
			if not bool(wd_o.get("is_melee", false)) and not bool(wd_o.get("is_special", false)) and cur_w != 7 and not bool(wd_o.get("has_holo", false)):
				player.add_attachment(cur_w, "optic")
				if hud:
					hud.show_toast("DEV: INSTALLED RED-DOT OPTIC ON %s" % wd_o["name"])
			elif hud:
				hud.show_toast("DEV: %s DOES NOT ACCEPT AFTERMARKET RED-DOT" % wd_o["name"])
		"attach_suppressor":
			var cur_s := player.current_weapon
			var wd_s: Dictionary = PlayerBodycam.WEAPONS[cur_s]
			if not bool(wd_s.get("is_melee", false)) and not bool(wd_s.get("is_special", false)) and not bool(wd_s.get("is_crossbow", false)) and cur_s != 6:
				player.add_attachment(cur_s, "suppressor")
				if hud:
					hud.show_toast("DEV: INSTALLED SUPPRESSOR ON %s" % wd_s["name"])
			elif hud:
				hud.show_toast("DEV: %s CANNOT MOUNT SUPPRESSOR" % wd_s["name"])
		"kill_all":
			for z in zombies_root.get_children():
				if z is ZombieAI and not z.dead:
					(z as ZombieAI).apply_shot([{"zone": "HEAD", "pos": (z as Node3D).global_position + Vector3(0, 1.5, 0), "dir": Vector3.FORWARD, "dmg": 9999.0, "dist": 2.0}], 1)
			if hud:
				hud.show_toast("DEV: CLEARED ACTIVE ZOMBIES")
		"next_wave":
			zombies_to_spawn = 0
			wave_pause_timer = 0.0
			for z in zombies_root.get_children():
				z.queue_free()
			_active_attackers.clear()
			_start_wave(wave + 1)
			if hud:
				hud.show_toast("DEV: SKIPPED TO WAVE %02d" % wave)
		"spawn_zombie", "spawn_bruiser", "spawn_exploder", "spawn_crawler", "spawn_spitter", "spawn_screamer", "spawn_runner":
			var fwd_s := -player.global_transform.basis.z
			var req_d := 6.5 if action == "spawn_crawler" else 8.0
			var spos_s := player.global_position + fwd_s * req_d
			var sp_state := player.get_world_3d().direct_space_state
			if sp_state:
				var wq := PhysicsRayQueryParameters3D.create(player.global_position + Vector3(0, 1.1, 0), spos_s + Vector3(0, 1.1, 0), 1)
				var wh := sp_state.intersect_ray(wq)
				if not wh.is_empty():
					spos_s = (wh["position"] as Vector3) - fwd_s * 1.1
				var fq := PhysicsRayQueryParameters3D.create(Vector3(spos_s.x, player.global_position.y + 1.8, spos_s.z), Vector3(spos_s.x, player.global_position.y - 6.0, spos_s.z), 1)
				var fh := sp_state.intersect_ray(fq)
				spos_s.y = float(fh["position"].y) + 0.05 if not fh.is_empty() else player.global_position.y
			var sv := ZombieAI.Variant.TACTICAL_SOLDIER
			if action == "spawn_bruiser": sv = ZombieAI.Variant.BRUISER
			elif action == "spawn_exploder": sv = ZombieAI.Variant.EXPLODER
			elif action == "spawn_crawler": sv = ZombieAI.Variant.ASYLUM_PATIENT
			elif action == "spawn_spitter": sv = ZombieAI.Variant.SPITTER
			elif action == "spawn_screamer": sv = ZombieAI.Variant.SCREAMER
			elif action == "spawn_runner": sv = ZombieAI.Variant.RUNNER
			var zs := spawn_zombie_at(spos_s, sv, player.yaw + PI, action != "spawn_crawler")
			if action == "spawn_crawler":
				zs.crippled_side = -1
				zs._dismember_zone("LEG_L", spos_s + Vector3(0, 0.4, 0), -fwd_s)
				zs.enter_crawler()
			if hud:
				var lbl_map := {"spawn_zombie": "ZOMBIE", "spawn_bruiser": "RIOT BRUISER", "spawn_exploder": "BLOATER (HEADSHOT DEFUSES)", "spawn_crawler": "CRAWLER", "spawn_spitter": "SPITTER", "spawn_screamer": "SCREAMER", "spawn_runner": "RUNNER"}
				hud.show_toast("DEV: SPAWNED %s AHEAD" % lbl_map[action])
		"toggle_daylight":
			if world:
				world.set_daylight_mode(not world.daylight_mode)
		"unlock_world":
			if not power_restored:
				on_generator_activated()
			for inter: InteractableObject in world.interactables:
				if inter.kind == InteractableObject.Kind.GENERATOR or inter.kind == InteractableObject.Kind.BREACH_GATE:
					inter.activated = true
					if inter.kind == InteractableObject.Kind.GENERATOR and inter.glow_light:
						inter.glow_light.light_color = Color(0.35, 1.0, 0.45)
						inter.glow_light.light_energy = 1.8
					if inter.kind == InteractableObject.Kind.BREACH_GATE:
						inter.collision_layer = 0
						if inter.gate_visual and is_instance_valid(inter.gate_visual):
							inter.gate_visual.rotation.y = inter.gate_open_yaw
						on_breach_gate_opened(inter.gate_id)
			if hud:
				hud.show_toast("DEV: POWER RESTORED & ALL 3 WING GATES UNLOCKED")
	if hud:
		hud.refresh_dev_menu(player)


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
		if not is_instance_valid(a) or a.dead or (a.state != ZombieAI.State.WINDUP and a.state != ZombieAI.State.STRIKE and a.state != ZombieAI.State.RECOVER and a.state != ZombieAI.State.GRAB and a.state != ZombieAI.State.SPECIAL and a.state != ZombieAI.State.CHARGE and a.state != ZombieAI.State.LEAP):
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
	get_tree().paused = false
	game_active = true
	if world and world.daylight_mode:
		world.set_daylight_mode(false)
	if ambient_audio and not ambient_audio.playing:
		ambient_audio.play()
	hud.title_panel.visible = false
	hud.defeat_panel.visible = false
	if player.weapon_rig_holder:
		player.weapon_rig_holder.visible = true
	player.head.rotation.x = 0.0
	if hud.settings_panel: hud.settings_panel.visible = false
	if hud.inventory_panel: hud.inventory_panel.visible = false
	if hud.dev_panel: hud.dev_panel.visible = false
	player.input_enabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	run_time = 0.0
	points_earned = 0
	_start_wave(1)
	hud.show_toast("[I] LOADOUT    [G] GRENADE    [V] MELEE    [ESC] PAUSE", 6.0)


func start_game_daylight() -> void:
	get_tree().paused = false
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
	if player.weapon_rig_holder:
		player.weapon_rig_holder.visible = true
	player.head.rotation.x = 0.0
	if hud.settings_panel: hud.settings_panel.visible = false
	if hud.inventory_panel: hud.inventory_panel.visible = false
	if hud.dev_panel: hud.dev_panel.visible = false
	player.input_enabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	run_time = 0.0
	points_earned = 0
	_start_wave(1)
	hud.show_toast("WINTER DAYLIGHT — [F9] TOGGLES NIGHT", 5.0)


func restart_game() -> void:
	if zombies_root == null or player == null or world == null:
		return
	var keep_daylight := world.daylight_mode
	get_tree().paused = false
	_reset_run_state()
	if keep_daylight:
		start_game_daylight()
	else:
		start_game()


func _unhandled_input(event: InputEvent) -> void:
	if deterministic_mode:
		return
	if world == null or player == null or (hud != null and hud.loading_overlay != null and hud.loading_overlay.visible):
		return
	var any_overlay := _is_any_overlay_open()
	var inv_open := (hud != null and hud.inventory_panel != null and hud.inventory_panel.visible)
	var dev_open := (hud != null and hud.dev_panel != null and hud.dev_panel.visible)
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
		elif event.physical_keycode == KEY_I and game_active and player and not player.dead:
			if inv_open:
				_close_all_overlays()
			else:
				_open_overlay("inventory")
			return
		elif event.physical_keycode == KEY_QUOTELEFT and game_active and player and not player.dead:
			if dev_open:
				_close_all_overlays()
			else:
				_open_overlay("dev")
			return
		elif event.physical_keycode == KEY_ESCAPE:
			if any_overlay:
				_close_all_overlays()
				return
			elif hud and hud.settings_panel:
				_open_overlay("settings")
				return
	elif event is InputEventMouseButton and event.pressed and game_active and not player.dead:
		if any_overlay or (hud and hud.title_panel.visible):
			return
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if not any_overlay and not get_tree().paused and player and is_instance_valid(player):
		player._unhandled_input(event)


func _start_wave(w: int) -> void:
	wave = w
	if w == 1:
		zombies_to_spawn = 6
		spawn_timer = 2.4
	elif w == 2:
		zombies_to_spawn = 9
		spawn_timer = 1.4
	else:
		zombies_to_spawn = 7 + w * 2
		spawn_timer = 1.1
	wave_total = zombies_to_spawn
	_wave_kills = 0
	if hud and game_active and not deterministic_mode:
		var sub := "CLEAR THE ASYLUM"
		if w == 2:
			sub = "SPITTERS AND BLOATERS INBOUND"
		elif w == 3:
			sub = "RUNNERS. LISTEN FOR THE SCREAMER."
		elif w == 4:
			sub = "RIOT BRUISER ON THE FLOOR"
		elif w > 4:
			sub = "%d HOSTILES" % zombies_to_spawn
		hud.show_banner("WAVE %02d" % w, sub, Color(0.95, 0.30, 0.24), 3.4)
		hud.play_ui("wave_start")


func _pick_fair_spawn_point() -> Dictionary:
	var pts := world.spawn_points
	if pts.is_empty():
		return {"ok": false}
	var ppos := player.global_position
	var cam := player.camera
	var space := render_vp.world_3d.direct_space_state if render_vp else get_world_3d().direct_space_state
	var in_morgue := ppos.x < -18.4 and ppos.z > -56.6 and ppos.z < -40.4
	var min_d := 10.5 if (ppos.z > -27.0 or in_morgue) else 14.0
	var max_d := 46.0
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
	if game_active and wave > 3:
		z.max_health *= _wave_hp_scale()
		z.health = z.max_health
	if game_active and with_cue and hud and not _hint_shown.has(variant) and THREAT_HINTS.has(variant):
		_hint_shown[variant] = true
		hud.show_toast(str(THREAT_HINTS[variant]), 6.5)
	z.global_position = pos
	z.rotation.y = yaw_rad
	z.died.connect(_on_zombie_died)
	if with_cue:
		z.enter_spawn_cue(0.95)
	return z


func clear_zombies() -> void:
	_active_attackers.clear()
	if combat:
		combat.clear_all()
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
	if delta_pts > 0:
		points_earned += delta_pts
	elif delta_pts < 0 and hud and game_active:
		hud.push_points(delta_pts, "")
		hud.play_ui("ui_buy")


func on_generator_activated() -> void:
	if hud and game_active and not power_restored:
		hud.show_banner("POWER RESTORED", "ARMORY BENCH ONLINE", Color(0.56, 0.90, 0.62), 3.0)
		hud.push_points(200, "GENERATOR")
	power_restored = true
	world.set_asylum_power(true)
	for inter: InteractableObject in world.interactables:
		if is_instance_valid(inter) and inter.kind == InteractableObject.Kind.UPGRADE_BENCH:
			inter.activated = true
		elif is_instance_valid(inter) and inter.kind == InteractableObject.Kind.PERK:
			inter.set_powered(true)
	add_points(200)


func on_sawmill_gate_opened() -> void:
	on_breach_gate_opened("sawmill")


func on_breach_gate_opened(gate_id: String) -> void:
	if world == null:
		return
	if gate_id == "boiler":
		if world.boiler_gate_open:
			return
		world.boiler_gate_open = true
		for sp: Vector3 in world.boiler_spawn_points:
			if not (sp in world.spawn_points):
				world.spawn_points.append(sp)
	elif gate_id == "morgue":
		if world.morgue_gate_open:
			return
		world.morgue_gate_open = true
		for sp: Vector3 in world.morgue_spawn_points:
			if not (sp in world.spawn_points):
				world.spawn_points.append(sp)
	else:
		if world.sawmill_gate_open:
			return
		world.sawmill_gate_open = true
		for sp: Vector3 in world.sawmill_spawn_points:
			if not (sp in world.spawn_points):
				world.spawn_points.append(sp)


func _on_hit_confirmed(is_headshot: bool, killed: bool) -> void:
	hud.show_hit(is_headshot, killed)
	if not killed:
		add_points(10)


func _on_zombie_died(z: ZombieAI, was_headshot: bool) -> void:
	release_attack_token(z)
	kills += 1
	_wave_kills += 1
	if was_headshot:
		headshots += 1
	# Kill pay-out by enemy type, a precision bonus, and a short chain bonus for kills in quick succession
	var pts := z.kill_points + (50 if was_headshot else 0)
	add_points(pts)
	_kill_chain = (_kill_chain + 1) if _kill_chain_timer > 0.0 else 1
	_kill_chain_timer = 2.6
	if hud and game_active:
		var lbl := z.variant_label() if z.kill_points > 100 else ""
		if was_headshot:
			lbl = ("HEADSHOT  " + lbl).strip_edges()
		hud.push_points(pts, lbl)
		if _kill_chain >= 3:
			var bonus := 25 * (_kill_chain - 2)
			add_points(bonus)
			hud.push_points(bonus, "%d× CHAIN" % _kill_chain)
	if game_active and player and not player.dead:
		_maybe_spawn_drop(z)


func _on_player_died() -> void:
	game_active = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var new_best := wave > best_wave or (wave == best_wave and kills > best_kills)
	if new_best and not deterministic_mode:
		best_wave = wave
		best_kills = kills
		_save_settings()
	hud.show_defeat({
		"wave": wave, "kills": kills, "headshots": headshots,
		"hs_pct": int(round(100.0 * float(headshots) / float(maxi(kills, 1)))),
		"accuracy": int(round(100.0 * float(player.shots_hit) / float(maxi(player.shots_fired, 1)))),
		"earned": points_earned, "time": _format_time(run_time),
		"damage_taken": int(player.damage_taken_total), "killer": player.last_hit_by if player.last_hit_by != "" else "THE INFECTED",
		"new_best": new_best,
	})
	if player.sfx_heart and player.sfx_heart.playing:
		player.sfx_heart.stop()


func _process(delta: float) -> void:
	if world == null or player == null or hud == null:
		return
	if world and player and player.camera:
		world.update_zone_culling(player.camera)
	var living_z := get_living_zombies()
	var hud_ctx := {"wave_total": wave_total, "fisheye": 0.212 if deterministic_mode else get_fisheye_strength()}
	if game_active and not deterministic_mode:
		if wave_pause_timer > 0.0:
			hud_ctx["intermission"] = maxf(0.0, wave_intermission_dur - wave_pause_timer)
		var obj := get_objective()
		if not obj.is_empty():
			hud_ctx["objective"] = obj["text"]
			if obj.has("pos"):
				hud_ctx["objective_pos"] = obj["pos"]
	hud.update_hud(delta, player, wave, points, living_z + zombies_to_spawn, living_z, hud_ctx)
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
	if deterministic_mode or get_tree().paused:
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

	_update_low_health_audio()
	if hud.title_panel.visible and not deterministic_mode and not bench_mode:
		_title_t += delta
		player.rotation.y = -0.55 + sin(_title_t * 0.09) * 0.42
		player.head.rotation.x = 0.04 + sin(_title_t * 0.13) * 0.03
		if player.weapon_rig_holder and player.weapon_rig_holder.visible:
			player.weapon_rig_holder.visible = false
	if not game_active or player.dead:
		return
	run_time += delta
	if _kill_chain_timer > 0.0:
		_kill_chain_timer -= delta
	_update_drops(delta)

	var alive_cap := 4 if wave == 1 else (6 if wave == 2 else mini(11, 5 + wave))
	if zombies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0 and get_living_zombies() < alive_cap:
			var pick := _pick_fair_spawn_point()
			if pick["ok"]:
				zombies_to_spawn -= 1
				spawn_timer = 2.9 if wave == 1 else (2.3 if wave == 2 else maxf(0.85, 2.5 - wave * 0.16))
				var v := _pick_wave_variant()
				if wave == 4 and zombies_to_spawn == wave_total - 3 and _alive_of(ZombieAI.Variant.BRUISER) == 0:
					v = ZombieAI.Variant.BRUISER
				spawn_zombie_at(pick["pos"], v, float(pick.get("yaw", 0.0)), true)
			else:
				spawn_timer = 0.45
	elif get_living_zombies() == 0:
		if wave_pause_timer == 0.0:
			var g_pick: String = PlayerBodycam.GRENADE_ORDER[wave % PlayerBodycam.GRENADE_ORDER.size()]
			if player and player.has_method("add_grenade"):
				player.add_grenade(g_pick, 1)
			var clear_bonus := 100 + 50 * wave
			add_points(clear_bonus)
			hud.show_banner("WAVE %02d CLEARED" % wave, "+%d PTS   ·   +1 %s GRENADE   ·   RELOAD AND RESUPPLY" % [clear_bonus, PlayerBodycam.GRENADE_LABELS[g_pick]], Color(0.56, 0.90, 0.62), 4.0)
			hud.play_ui("wave_clear")
			wave_pause_timer = 0.0001
		wave_pause_timer += delta
		if wave_pause_timer >= wave_intermission_dur:
			wave_pause_timer = 0.0
			_start_wave(wave + 1)


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

	_post_player_setup()

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

	var warmup_weapons := [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 0]
	var step := 0
	var variant_count := ZombieAI.Variant.size()
	var total_steps := variant_count + warmup_weapons.size() + 4
	var _render_step := func(label: String) -> void:
		step += 1
		if hud:
			hud.set_loading_status("BODYCAM-04 // COMPILING SHADERS (%d/%d): %s" % [step, total_steps, label])
		render_vp.render_target_update_mode = SubViewport.UPDATE_ONCE

	# Steps 1-3: Each zombie variant directly in front of camera under flashlight + lobby omni
	var warm_z: Array[ZombieAI] = []
	for i in range(variant_count):
		var v := i as ZombieAI.Variant
		var z := spawn_zombie_at(Vector3(-1.2 + (i - 3) * 0.62, 0.05, 0.8 - absf(i - 3) * 0.18), v, PI, false)
		z.move_speed = 0.0
		z.deterministic_pose = true
		warm_z.append(z)
		_render_step.call("INFECTED %d/%d" % [i + 1, variant_count])
		await tree.process_frame

	# Steps 4-6: Weapons 0/1/2 with muzzle lights + muzzle flash rig visible (compiles dynamic-light + flash shaders!)
	player.muzzle_light.visible = true
	player.muzzle_light.light_energy = 1.5
	player.muzzle_vm_light.visible = true
	player.muzzle_vm_light.light_energy = 0.8
	player.muzzle_flash_rig.visible = true
	for wi_pos in range(warmup_weapons.size()):
		var w_idx: int = warmup_weapons[wi_pos]
		player._equip_weapon(w_idx, true)
		_render_step.call("WEAPON %d/%d" % [wi_pos + 1, warmup_weapons.size()])
		await tree.process_frame
	player.muzzle_light.visible = false
	player.muzzle_light.light_energy = 0.0
	player.muzzle_vm_light.visible = false
	player.muzzle_vm_light.light_energy = 0.0
	player.muzzle_flash_rig.visible = false

	# Step 7: In-frustum VFX + head dismemberment/ragdoll stump warmup
	if vfx:
		vfx.run_pipeline_warmup(player.camera.global_position, -player.camera.global_transform.basis.z)
	if combat:
		# Acid pool and glob materials compile here, behind the loading screen
		combat.spawn_acid_pool(Vector3(-1.2, 0.05, 1.6), 1.2, 1.0)
		combat.spawn_acid_glob(Vector3(-1.2, 1.4, 1.2), Vector3(-1.2, 0.05, 2.4))
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

	# Step 10: Cabin + Frozen Sawmill + Evidence Chest & Active Trap FX shader warmup!
	for inter: InteractableObject in world.interactables:
		if inter.kind == InteractableObject.Kind.TRAP and inter.trap_fx_node and is_instance_valid(inter.trap_fx_node):
			inter.trap_fx_node.visible = true
	player.global_position = Vector3(8.0, 0.5, -72.0)
	player.yaw = 0.0
	world.update_zone_culling(player.camera)
	_render_step.call("CABIN & SAWMILL")
	await tree.process_frame
	for inter: InteractableObject in world.interactables:
		if inter.kind == InteractableObject.Kind.TRAP and inter.trap_fx_node and is_instance_valid(inter.trap_fx_node):
			inter.trap_fx_node.visible = false

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
	for i in range(ZombieAI.Variant.size()):
		var v := i as ZombieAI.Variant
		var z := spawn_zombie_at(Vector3(-1.2 + (i - 3) * 0.62, 0.05, 0.2 - absf(i - 3) * 0.18), v, PI, false)
		z.move_speed = 0.0
		z.deterministic_pose = true
		warm_z.append(z)
	for w_idx in [1, 2, 0]:
		player._equip_weapon(w_idx, true)
		await tree.process_frame

	if vfx:
		vfx.run_pipeline_warmup(player.camera.global_position, -player.camera.global_transform.basis.z)
	if combat:
		# Acid pool and glob materials compile here, behind the loading screen
		combat.spawn_acid_pool(Vector3(-1.2, 0.05, 1.6), 1.2, 1.0)
		combat.spawn_acid_glob(Vector3(-1.2, 1.4, 1.2), Vector3(-1.2, 0.05, 2.4))
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


# ---------------------------------------------------------------------------------------------------------------------
# Run flow, scoring, objectives, drops and saved options
# ---------------------------------------------------------------------------------------------------------------------

const SETTINGS_PATH := "user://deadcam_settings.cfg"
const GRAIN_NAMES := ["OFF", "LOW", "FULL"]
const GRAIN_VALS := [0.0, 0.008, 0.016]
const DROP_LIFETIME := 45.0
const MAX_DROPS := 3

var combat: CombatDirector
var opt_sens: float = 1.0
var opt_ads_sens: float = 0.62
var opt_fov: float = 94.0
var opt_volume: int = 100
var opt_crosshair: bool = true
var opt_invert_y: bool = false
var opt_bodycam: int = 100
var opt_grain: int = 2
var best_wave: int = 0
var best_kills: int = 0
var run_time: float = 0.0
var points_earned: int = 0
var wave_total: int = 0
var _wave_kills: int = 0
var _drops: Array[Dictionary] = []
var _drop_scenes: Dictionary = {}
var _obj_cache: Dictionary = {}
var _heart_on: bool = false
var _kill_chain: int = 0
var _kill_chain_timer: float = 0.0
var _hint_shown: Dictionary = {}
var _title_t: float = 0.0

const THREAT_HINTS := {
	ZombieAI.Variant.RUNNER: "RUNNER — LEAPS FROM RANGE. SHOOT IT OUT OF THE AIR OR SIDESTEP.",
	ZombieAI.Variant.EXPLODER: "BLOATER — DETONATES ON CONTACT. A HEADSHOT DEFUSES IT; A BODY SHOT SETS IT OFF.",
	ZombieAI.Variant.SPITTER: "SPITTER — LOBS ACID FROM RANGE. KEEP MOVING AND CLOSE THE GAP.",
	ZombieAI.Variant.SCREAMER: "SCREAMER — ITS SHRIEK ENRAGES THE HORDE. KILL IT WHILE IT INHALES.",
	ZombieAI.Variant.BRUISER: "RIOT BRUISER — VISOR BLOCKS HEADSHOTS UNTIL IT BREAKS. DODGE THE CHARGE.",
	ZombieAI.Variant.TACTICAL_SOLDIER: "SOLDIER — BODY ARMOUR SOAKS CHEST HITS. AIM FOR THE HEAD OR LEGS.",
}


func _connect_hud() -> void:
	hud.start_requested.connect(start_game)
	hud.start_daylight_requested.connect(start_game_daylight)
	hud.restart_requested.connect(restart_game)
	hud.quit_to_title_requested.connect(quit_to_title)
	hud.graphics_action.connect(_on_hud_graphics_action)
	hud.option_action.connect(_on_option_action)
	hud.open_settings_requested.connect(func(): _open_overlay("settings"))
	hud.settings_closed.connect(_on_settings_closed)
	hud.open_inventory_requested.connect(_open_inventory)
	hud.inventory_action.connect(_on_inventory_action)
	hud.inventory_closed.connect(_close_all_overlays)
	hud.dev_action.connect(_on_dev_action)
	hud.dev_closed.connect(_close_all_overlays)


func _post_player_setup() -> void:
	player.player_died.connect(_on_player_died)
	player.hit_confirmed.connect(_on_hit_confirmed)
	player.status_message.connect(func(msg): hud.show_toast(msg))
	player.score_event.connect(_on_score_event)
	player.feed_message.connect(func(msg): hud.show_toast(msg))
	combat = CombatDirector.new()
	combat.name = "CombatDirector"
	render_vp.add_child(combat)
	combat.player = player
	ZombieAI.preload_kits()
	_load_settings()
	_apply_options()
	hud.set_best_record(best_wave, best_kills)


func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		return
	opt_sens = clampf(float(cf.get_value("game", "sens", opt_sens)), 0.3, 3.0)
	opt_ads_sens = clampf(float(cf.get_value("game", "ads_sens", opt_ads_sens)), 0.3, 1.0)
	opt_fov = clampf(float(cf.get_value("game", "fov", opt_fov)), 80.0, 110.0)
	opt_volume = clampi(int(cf.get_value("game", "volume", opt_volume)), 0, 100)
	opt_crosshair = bool(cf.get_value("game", "crosshair", opt_crosshair))
	opt_invert_y = bool(cf.get_value("game", "invert_y", opt_invert_y))
	opt_bodycam = clampi(int(cf.get_value("game", "bodycam", opt_bodycam)), 0, 100)
	opt_grain = clampi(int(cf.get_value("game", "grain", opt_grain)), 0, 2)
	best_wave = int(cf.get_value("record", "wave", 0))
	best_kills = int(cf.get_value("record", "kills", 0))


func _save_settings() -> void:
	if deterministic_mode or bench_mode:
		return
	var cf := ConfigFile.new()
	cf.set_value("game", "sens", opt_sens)
	cf.set_value("game", "ads_sens", opt_ads_sens)
	cf.set_value("game", "fov", opt_fov)
	cf.set_value("game", "volume", opt_volume)
	cf.set_value("game", "crosshair", opt_crosshair)
	cf.set_value("game", "invert_y", opt_invert_y)
	cf.set_value("game", "bodycam", opt_bodycam)
	cf.set_value("game", "grain", opt_grain)
	cf.set_value("record", "wave", best_wave)
	cf.set_value("record", "kills", best_kills)
	cf.save(SETTINGS_PATH)


func get_fisheye_strength() -> float:
	return 0.212 * float(opt_bodycam) / 100.0


func _apply_options() -> void:
	if player:
		player.mouse_sens = 0.0022 * opt_sens
		player.ads_sens_mult = opt_ads_sens
		player.base_fov = opt_fov
		player.invert_y = opt_invert_y
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, opt_volume <= 0)
		AudioServer.set_bus_volume_db(master, linear_to_db(maxf(float(opt_volume) / 100.0, 0.001)))
	if hud:
		hud.show_crosshair = opt_crosshair
		if hud.post_mat and not deterministic_mode:
			hud.post_mat.set_shader_parameter("grain_strength", float(GRAIN_VALS[opt_grain]))
			hud.post_mat.set_shader_parameter("ca_strength", 0.0068 * float(opt_bodycam) / 100.0)
		hud.update_option_labels({
			"sens": "%.1f×" % opt_sens,
			"ads_sens": "%d%%" % int(round(opt_ads_sens * 100.0)),
			"fov": "%d°" % int(opt_fov),
			"volume": ("%d%%" % opt_volume) if opt_volume > 0 else "MUTED",
			"crosshair": "ON" if opt_crosshair else "OFF",
			"invert_y": "ON" if opt_invert_y else "OFF",
			"bodycam": ("%d%%" % opt_bodycam) if opt_bodycam > 0 else "OFF",
			"grain": GRAIN_NAMES[opt_grain],
		})


func _on_option_action(key: String, dir: int) -> void:
	match key:
		"sens": opt_sens = clampf(snappedf(opt_sens + 0.1 * dir, 0.1), 0.3, 3.0)
		"ads_sens": opt_ads_sens = clampf(snappedf(opt_ads_sens + 0.05 * dir, 0.01), 0.3, 1.0)
		"fov": opt_fov = clampf(opt_fov + 2.0 * dir, 80.0, 110.0)
		"volume": opt_volume = clampi(opt_volume + 10 * dir, 0, 100)
		"crosshair": opt_crosshair = not opt_crosshair
		"invert_y": opt_invert_y = not opt_invert_y
		"bodycam": opt_bodycam = clampi(opt_bodycam + 20 * dir, 0, 100)
		"grain": opt_grain = posmod(opt_grain + dir, GRAIN_NAMES.size())
	_apply_options()
	_save_settings()


func quit_to_title() -> void:
	if zombies_root == null or player == null or world == null:
		return
	get_tree().paused = false
	game_active = false
	_reset_run_state()
	hud.defeat_panel.visible = false
	if hud.settings_panel: hud.settings_panel.visible = false
	if hud.inventory_panel: hud.inventory_panel.visible = false
	if hud.dev_panel: hud.dev_panel.visible = false
	hud.title_panel.visible = true
	hud.set_best_record(best_wave, best_kills)
	player.input_enabled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _reset_run_state() -> void:
	_hint_shown.clear()
	for c in zombies_root.get_children():
		c.queue_free()
	_active_attackers.clear()
	_recent_spawns.clear()
	_clear_drops()
	if combat:
		combat.clear_all()
	wave_pause_timer = 0.0
	zombies_to_spawn = 0
	player.heal_full(true)
	player.global_position = Vector3(-1.2, 0.05, 3.6)
	player.yaw = -0.35
	player.pitch = 0.0
	points = 600
	kills = 0
	headshots = 0
	run_time = 0.0
	points_earned = 0
	_kill_chain = 0
	_obj_cache.clear()
	power_restored = false
	world.set_asylum_power(false)
	if world.sawmill_gate_open:
		world.sawmill_gate_open = false
		for sp: Vector3 in world.sawmill_spawn_points:
			world.spawn_points.erase(sp)
	if world.boiler_gate_open:
		world.boiler_gate_open = false
		for sp: Vector3 in world.boiler_spawn_points:
			world.spawn_points.erase(sp)
	if world.morgue_gate_open:
		world.morgue_gate_open = false
		for sp: Vector3 in world.morgue_spawn_points:
			world.spawn_points.erase(sp)
	for inter: InteractableObject in world.interactables:
		if is_instance_valid(inter) and inter.has_method("reset_state"):
			inter.reset_state()


func _on_score_event(kind: String, amount: int) -> void:
	add_points(amount)
	if hud:
		hud.push_points(amount, kind)


func _alive_of(v: ZombieAI.Variant) -> int:
	var n := 0
	for c in zombies_root.get_children():
		if c is ZombieAI and not c.dead and c.variant == v:
			n += 1
	return n


func _pick_wave_variant() -> ZombieAI.Variant:
	# Weighted roster per wave, with caps on the specials so a wave never becomes three screamers and two bruisers
	var w := wave
	var table: Array = []
	if w <= 1:
		table = [[ZombieAI.Variant.ASYLUM_PATIENT, 100]]
	elif w == 2:
		table = [[ZombieAI.Variant.ASYLUM_PATIENT, 55], [ZombieAI.Variant.TACTICAL_SOLDIER, 25], [ZombieAI.Variant.EXPLODER, 10], [ZombieAI.Variant.SPITTER, 10]]
	elif w == 3:
		table = [[ZombieAI.Variant.ASYLUM_PATIENT, 32], [ZombieAI.Variant.TACTICAL_SOLDIER, 22], [ZombieAI.Variant.RUNNER, 18], [ZombieAI.Variant.EXPLODER, 10], [ZombieAI.Variant.SPITTER, 10], [ZombieAI.Variant.SCREAMER, 8]]
	else:
		table = [[ZombieAI.Variant.ASYLUM_PATIENT, 24], [ZombieAI.Variant.TACTICAL_SOLDIER, 20], [ZombieAI.Variant.RUNNER, 20], [ZombieAI.Variant.EXPLODER, 10], [ZombieAI.Variant.SPITTER, 11], [ZombieAI.Variant.SCREAMER, 6], [ZombieAI.Variant.BRUISER, 9]]
	var caps := {
		ZombieAI.Variant.BRUISER: 1 + (1 if w >= 7 else 0),
		ZombieAI.Variant.SCREAMER: 1,
		ZombieAI.Variant.SPITTER: 2 + (1 if w >= 6 else 0),
		ZombieAI.Variant.EXPLODER: 2,
	}
	var total := 0
	var usable: Array = []
	for row in table:
		var v: ZombieAI.Variant = row[0]
		if caps.has(v) and _alive_of(v) >= int(caps[v]):
			continue
		usable.append(row)
		total += int(row[1])
	if usable.is_empty() or total <= 0:
		return ZombieAI.Variant.ASYLUM_PATIENT
	var roll := randi() % total
	for row in usable:
		roll -= int(row[1])
		if roll < 0:
			return row[0]
	return ZombieAI.Variant.ASYLUM_PATIENT


func _wave_hp_scale() -> float:
	return clampf(1.0 + 0.07 * float(maxi(0, wave - 3)), 1.0, 2.2)


func spawn_reinforcements(_caller: ZombieAI, count: int) -> void:
	# A scream calls a few extra bodies out of the dark. They do not count against the wave total.
	if not game_active or player == null or player.dead:
		return
	var cap := (4 if wave == 1 else (6 if wave == 2 else mini(11, 5 + wave))) + 2
	for _i in range(count):
		if get_living_zombies() >= cap:
			return
		var pick := _pick_fair_spawn_point()
		if not pick.get("ok", false):
			return
		var v := ZombieAI.Variant.RUNNER if randf() < 0.4 else ZombieAI.Variant.ASYLUM_PATIENT
		var z := spawn_zombie_at(pick["pos"], v, float(pick.get("yaw", 0.0)), true)
		z.enrage(8.0)
	if hud:
		hud.show_toast("THE SCREAM IS DRAWING MORE OF THEM")


func _find_interactable(kind: int, gate_id := "") -> InteractableObject:
	var key := "%d:%s" % [kind, gate_id]
	if _obj_cache.has(key) and is_instance_valid(_obj_cache[key]):
		return _obj_cache[key]
	for inter: InteractableObject in world.interactables:
		if is_instance_valid(inter) and inter.kind == kind and (gate_id == "" or inter.gate_id == gate_id):
			_obj_cache[key] = inter
			return inter
	return null


func get_objective() -> Dictionary:
	# The next sensible thing to do, with a world position for the compass marker
	if not game_active or world == null or player == null:
		return {}
	if not power_restored:
		var gen := _find_interactable(InteractableObject.Kind.GENERATOR)
		if gen:
			return {"text": "RESTORE POWER — START THE GENERATOR", "pos": gen.global_position}
	var any_gate := world.boiler_gate_open or world.morgue_gate_open or world.sawmill_gate_open
	var any_up := false
	for u in player.upgraded_weapons:
		if u:
			any_up = true
			break
	if not world.sawmill_gate_open and (any_gate or points >= 750):
		var sg := _find_interactable(InteractableObject.Kind.BREACH_GATE, "sawmill")
		if sg:
			return {"text": "BREACH THE SAWMILL GATE — ARMORY BENCH BEYOND  (%d PTS)" % sg.cost, "pos": sg.global_position}
	if not any_gate:
		var bg := _find_interactable(InteractableObject.Kind.BREACH_GATE, "boiler")
		if bg:
			return {"text": "EARN %d PTS AND BREACH A WING GATE" % bg.cost, "pos": bg.global_position}
	if world.sawmill_gate_open and not any_up:
		var bench := _find_interactable(InteractableObject.Kind.UPGRADE_BENCH)
		if bench:
			return {"text": "UPGRADE A WEAPON AT THE ARMORY BENCH  (%d PTS)" % bench.cost, "pos": bench.global_position}
	return {"text": "HOLD OUT — SURVIVE THE WAVE"}


func _clear_drops() -> void:
	for d in _drops:
		if is_instance_valid(d.get("node")):
			(d["node"] as Node).queue_free()
	_drops.clear()


func _maybe_spawn_drop(z: ZombieAI) -> void:
	if _drops.size() >= MAX_DROPS or world == null or not game_active:
		return
	var roll := randf()
	var kind := ""
	# Low on health or ammo makes the matching drop more likely, so a bad stretch can turn around
	var hp_need := 1.0 - player.health / maxf(player.max_health, 1.0)
	var cw := player.current_weapon
	var ammo_need := 0.0
	if not bool(PlayerBodycam.WEAPONS[cw].get("is_melee", false)):
		ammo_need = 1.0 - clampf(float(player.ammo_reserve[cw]) / maxf(float(PlayerBodycam.WEAPONS[cw]["reserve_max"]), 1.0), 0.0, 1.0)
	var p_med := 0.03 + 0.07 * hp_need
	var p_ammo := 0.05 + 0.09 * ammo_need
	if z.variant == ZombieAI.Variant.BRUISER:
		p_ammo = 1.0
	if roll < p_med:
		kind = "medkit"
	elif roll < p_med + p_ammo:
		kind = "ammo"
	if kind == "":
		return
	var glb_key := "medical_box" if kind == "medkit" else "ammo_box"
	if not world.glbs.has(glb_key) or world.glbs[glb_key] == null:
		return
	var pos := z.global_position
	var space := render_vp.world_3d.direct_space_state
	if space:
		var q := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 1.2, 0), pos + Vector3(0, -4.0, 0), 1)
		var res := space.intersect_ray(q)
		if res.is_empty():
			return
		pos = res["position"]
	var node := Node3D.new()
	var inst: Node3D = world.glbs[glb_key].instantiate()
	inst.scale = Vector3.ONE * (0.75 if kind == "medkit" else 0.9)
	inst.rotation.y = randf() * TAU
	for sb in inst.find_children("*", "CollisionObject3D", true, false):
		(sb as CollisionObject3D).collision_layer = 0
		(sb as CollisionObject3D).collision_mask = 0
	node.add_child(inst)
	var light: OmniLight3D = null
	if not OS.has_feature("web"):
		light = OmniLight3D.new()
		light.light_color = Color(0.45, 1.0, 0.55) if kind == "medkit" else Color(1.0, 0.82, 0.42)
		light.light_energy = 0.9
		light.omni_range = 2.4
		light.shadow_enabled = false
		light.light_volumetric_fog_energy = 0.0
		light.light_bake_mode = Light3D.BAKE_DISABLED
		light.position = Vector3(0.0, 0.55, 0.0)
		node.add_child(light)
	zombies_root.get_parent().add_child(node)
	node.global_position = pos
	_drops.append({"node": node, "kind": kind, "age": 0.0, "light": light})


func _update_drops(delta: float) -> void:
	var i := _drops.size() - 1
	while i >= 0:
		var d: Dictionary = _drops[i]
		var node := d["node"] as Node3D
		d["age"] = float(d["age"]) + delta
		var gone := not is_instance_valid(node) or float(d["age"]) > DROP_LIFETIME
		if not gone:
			var l := d.get("light") as OmniLight3D
			if l and is_instance_valid(l):
				var left := DROP_LIFETIME - float(d["age"])
				var blink := 1.0 if left > 8.0 else (0.35 + 0.65 * absf(sin(float(d["age"]) * 6.0)))
				l.light_energy = (0.8 + 0.25 * sin(float(d["age"]) * 3.0)) * blink
			var to := node.global_position - player.global_position
			if Vector2(to.x, to.z).length() < 1.25 and absf(to.y) < 1.6 and not player.dead:
				if _collect_drop(str(d["kind"])):
					gone = true
		if gone:
			if is_instance_valid(node):
				node.queue_free()
			_drops.remove_at(i)
		i -= 1


func _collect_drop(kind: String) -> bool:
	if kind == "medkit":
		if player.health >= player.max_health - 1.0:
			return false
		player.health = minf(player.max_health, player.health + 50.0)
		hud.show_toast("FIELD DRESSING APPLIED  +50 HP")
		hud.play_ui("ui_buy", 1.1)
		return true
	var gave := false
	var slots: Array[int] = []
	for idx: int in player.firearm_slots:
		slots.append(idx)
	if player.special_slot >= 0 and not player.is_no_refill_weapon(player.special_slot):
		slots.append(player.special_slot)
	for idx: int in slots:
		var cap := int(PlayerBodycam.WEAPONS[idx]["reserve_max"])
		if player.ammo_reserve[idx] < cap:
			player.ammo_reserve[idx] = mini(cap, player.ammo_reserve[idx] + maxi(2, player.get_weapon_mag_size(idx) * 2))
			gave = true
	if not gave:
		return false
	hud.show_toast("AMMUNITION RECOVERED")
	hud.play_ui("ui_buy", 0.92)
	return true


func _update_low_health_audio() -> void:
	if player == null or player.sfx_heart == null or player.sfx_heart.stream == null:
		return
	var frac := player.health / maxf(player.max_health, 1.0)
	var want := game_active and not player.dead and frac < 0.42
	if want:
		if not player.sfx_heart.playing:
			player.sfx_heart.play()
		player.sfx_heart.volume_db = lerpf(-4.0, -16.0, clampf(frac / 0.42, 0.0, 1.0))
		player.sfx_heart.pitch_scale = lerpf(1.22, 0.92, clampf(frac / 0.42, 0.0, 1.0))
	elif player.sfx_heart.playing:
		player.sfx_heart.stop()


func _format_time(t: float) -> String:
	var s := int(t)
	return "%d:%02d" % [int(s / 60.0), s % 60]
