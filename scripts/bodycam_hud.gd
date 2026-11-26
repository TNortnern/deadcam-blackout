extends CanvasLayer
class_name BodycamHUD


class TacticalHitmarker extends Control:
	var progress: float = 0.0
	var is_headshot: bool = false
	var killed: bool = false

	func trigger(headshot: bool, was_kill: bool) -> void:
		is_headshot = headshot
		killed = was_kill
		progress = 1.0
		visible = true
		queue_redraw()

	func _process(delta: float) -> void:
		if not visible:
			return
		progress -= delta / 0.18
		if progress <= 0.0:
			progress = 0.0
			visible = false
			return
		queue_redraw()

	func _draw() -> void:
		if progress <= 0.0:
			return
		var alpha := clampf(progress * 1.4, 0.0, 1.0)
		var pop := 1.0 + 0.38 * pow(progress, 2.0)
		var gap := 5.5 * pop
		var tick_len := (13.0 if (is_headshot or killed) else 10.5) * pop
		var main_col := Color(1.0, 0.18, 0.14, alpha) if (is_headshot or killed) else Color(0.96, 0.96, 0.94, alpha * 0.92)
		var shadow_col := Color(0.0, 0.0, 0.0, alpha * 0.72)
		var w := 2.0 if (is_headshot or killed) else 1.7
		for dir in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var dn := (dir as Vector2).normalized()
			var p0 := dn * gap
			var p1 := dn * (gap + tick_len)
			draw_line(p0, p1, shadow_col, w + 1.8, true)
			draw_line(p0, p1, main_col, w, true)
			if is_headshot and killed:
				var o0 := dn * (gap + tick_len + 3.5)
				var o1 := dn * (gap + tick_len + 7.5)
				draw_line(o0, o1, shadow_col, w + 1.4, true)
				draw_line(o0, o1, main_col, w * 0.9, true)


var post_rect: TextureRect
var post_mat: ShaderMaterial
var rec_label: Label
var stats_label: Label
var prompt_label: Label
var toast_label: Label
var perf_label: Label
var loading_overlay: ColorRect
var hit_marker: TacticalHitmarker
var title_panel: Control
var defeat_panel: Control
var defeat_info: Label
var settings_panel: Control
var _settings_renderer_lbl: Label
var _settings_res_lbl: Label
var _settings_btns: Dictionary = {}

var toast_timer: float = 0.0
var hud_visible_minimal: bool = true
var _hud_text_accum: float = 0.25
var _last_ammo_sig: int = -1

signal start_requested
signal start_daylight_requested
signal restart_requested
signal graphics_action(key: String)
signal settings_closed


func _ready() -> void:
	layer = 10
	# Full-screen bodycam fisheye / CMOS post-processing TextureRect (zero-copy from SubViewport!)
	post_rect = TextureRect.new()
	post_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	post_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	post_rect.stretch_mode = TextureRect.STRETCH_SCALE
	post_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_mat = ShaderMaterial.new()
	post_mat.shader = load("res://shaders/bodycam_post.gdshader")
	post_rect.material = post_mat
	add_child(post_rect)

	# Authentic subtle AXON-style Bodycam overlay (top-right corner, very understated)
	rec_label = Label.new()
	rec_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rec_label.offset_left = -310
	rec_label.offset_top = 18
	rec_label.offset_right = -24
	rec_label.offset_bottom = 66
	rec_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rec_label.add_theme_font_size_override("font_size", 14)
	rec_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.92, 0.72))
	rec_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	rec_label.add_theme_constant_override("shadow_offset_x", 1)
	rec_label.add_theme_constant_override("shadow_offset_y", 1)
	rec_label.text = "REC ●  2026-11-24 23:41:08\nBODYCAM-04 // UNIT-K9"
	add_child(rec_label)

	# Minimal bottom-right tactical ammo & wave counter
	stats_label = Label.new()
	stats_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	stats_label.offset_left = -340
	stats_label.offset_top = -78
	stats_label.offset_right = -28
	stats_label.offset_bottom = -20
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_label.add_theme_font_size_override("font_size", 15)
	stats_label.add_theme_color_override("font_color", Color(0.88, 0.90, 0.86, 0.78))
	stats_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	stats_label.add_theme_constant_override("shadow_offset_x", 1)
	stats_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(stats_label)

	# Center interaction prompt
	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER)
	prompt_label.offset_left = -220
	prompt_label.offset_top = 60
	prompt_label.offset_right = 220
	prompt_label.offset_bottom = 96
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82, 0.92))
	prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(prompt_label)

	# Brief status toast (top-center)
	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_left = -260
	toast_label.offset_top = 34
	toast_label.offset_right = 260
	toast_label.offset_bottom = 72
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 17)
	toast_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.62, 0.95))
	add_child(toast_label)

	# Razor-sharp custom-drawn tactical crosshair hitmarker
	hit_marker = TacticalHitmarker.new()
	hit_marker.set_anchors_preset(Control.PRESET_CENTER)
	hit_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_marker.visible = false
	add_child(hit_marker)

	# Top-left live telemetry (toggle with F3)
	perf_label = Label.new()
	perf_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	perf_label.offset_left = 20
	perf_label.offset_top = 18
	perf_label.offset_right = 560
	perf_label.offset_bottom = 86
	perf_label.add_theme_font_size_override("font_size", 13)
	perf_label.add_theme_color_override("font_color", Color(0.72, 0.96, 0.72, 0.90))
	perf_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	perf_label.add_theme_constant_override("shadow_offset_x", 1)
	perf_label.add_theme_constant_override("shadow_offset_y", 1)
	perf_label.visible = false
	add_child(perf_label)

	_build_title_overlay()
	_build_defeat_overlay()
	_build_settings_overlay()

	# Opaque warmup shield (hides shader/PSO warmup tour on startup so ZERO hitch appears after Deploy!)
	loading_overlay = ColorRect.new()
	loading_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_overlay.color = Color(0.014, 0.016, 0.020, 1.0)
	loading_overlay.visible = false
	var lmsg := Label.new()
	lmsg.text = "BODYCAM-04 // INITIALIZING OPTICS & LIGHTING..."
	lmsg.set_anchors_preset(Control.PRESET_CENTER)
	lmsg.offset_left = -260
	lmsg.offset_top = -18
	lmsg.offset_right = 260
	lmsg.offset_bottom = 18
	lmsg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lmsg.add_theme_font_size_override("font_size", 16)
	lmsg.add_theme_color_override("font_color", Color(0.84, 0.88, 0.84, 0.88))
	loading_overlay.add_child(lmsg)
	add_child(loading_overlay)


func _build_title_overlay() -> void:
	title_panel = ColorRect.new()
	title_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_panel.color = Color(0.02, 0.022, 0.026, 0.58)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.offset_left = -280
	vb.offset_top = -120
	vb.offset_right = 280
	vb.offset_bottom = 130
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)

	var t := Label.new()
	t.text = "[ DEADCAM: BLACKOUT ]"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 36)
	t.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86))
	vb.add_child(t)

	var sub := Label.new()
	sub.text = "ASYLUM  •  CATACOMB TUNNELS  •  WINTER COURTYARD\nWASD Move | LMB Fire | RMB Aim | V Quick Melee | R Reload | F Flashlight | E Interact | 1-4 Weapons | F9 Day/Night | F8 Quality"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.75, 0.78, 0.76))
	vb.add_child(sub)

	var btn := Button.new()
	btn.text = "DEPLOY: BLACKOUT NIGHT (ASYLUM)"
	btn.custom_minimum_size = Vector2(300, 44)
	btn.pressed.connect(func(): emit_signal("start_requested"))
	vb.add_child(btn)

	var day_btn := Button.new()
	day_btn.text = "DEPLOY: WINTER DAYLIGHT (OUTDOOR SHOWCASE)"
	day_btn.custom_minimum_size = Vector2(300, 42)
	day_btn.pressed.connect(func(): emit_signal("start_daylight_requested"))
	vb.add_child(day_btn)

	var cfg_btn := Button.new()
	cfg_btn.text = "GRAPHICS SETTINGS [ESC]"
	cfg_btn.custom_minimum_size = Vector2(300, 36)
	cfg_btn.pressed.connect(func():
		if settings_panel:
			settings_panel.visible = true
	)
	vb.add_child(cfg_btn)

	title_panel.add_child(vb)
	add_child(title_panel)


func _build_settings_overlay() -> void:
	settings_panel = ColorRect.new()
	settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_panel.color = Color(0.015, 0.018, 0.022, 0.78)
	settings_panel.visible = false

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -280
	card.offset_top = -230
	card.offset_right = 280
	card.offset_bottom = 230
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.055, 0.065, 0.94)
	sb.border_color = Color(0.28, 0.32, 0.34, 0.90)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(18)
	sb.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)

	var hdr := Label.new()
	hdr.text = "BODYCAM-04 // GRAPHICS SETTINGS"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 18)
	hdr.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68))
	vb.add_child(hdr)

	_settings_renderer_lbl = Label.new()
	_settings_renderer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_renderer_lbl.add_theme_font_size_override("font_size", 13)
	_settings_renderer_lbl.add_theme_color_override("font_color", Color(0.68, 0.94, 0.74))
	vb.add_child(_settings_renderer_lbl)

	_settings_res_lbl = Label.new()
	_settings_res_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_res_lbl.add_theme_font_size_override("font_size", 12)
	_settings_res_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.82))
	vb.add_child(_settings_res_lbl)

	var opt_keys := [
		"preset", "upscaler", "res_scale", "ssr", "ssao", "vol_fog", "voxel_gi", "pom", "telemetry"
	]
	for k in opt_keys:
		var b := Button.new()
		b.custom_minimum_size = Vector2(460, 30)
		b.add_theme_font_size_override("font_size", 14)
		var captured_k: String = k
		b.pressed.connect(func(): emit_signal("graphics_action", captured_k))
		vb.add_child(b)
		_settings_btns[k] = b

	var close_btn := Button.new()
	close_btn.text = "RESUME [ESC]"
	close_btn.custom_minimum_size = Vector2(240, 36)
	close_btn.pressed.connect(func(): emit_signal("settings_closed"))
	vb.add_child(close_btn)

	card.add_child(vb)
	settings_panel.add_child(card)
	add_child(settings_panel)


func update_settings_labels(state: Dictionary) -> void:
	if _settings_renderer_lbl:
		_settings_renderer_lbl.text = str(state.get("renderer", "FORWARD+"))
	if _settings_res_lbl:
		_settings_res_lbl.text = str(state.get("res_info", ""))
	if _settings_btns.has("preset"):
		(_settings_btns["preset"] as Button).text = "QUALITY PRESET [F8]:  %s" % str(state.get("preset", "HIGH"))
	if _settings_btns.has("upscaler"):
		(_settings_btns["upscaler"] as Button).text = "UPSCALER MODE:  %s" % str(state.get("upscaler", "AUTO"))
	if _settings_btns.has("res_scale"):
		(_settings_btns["res_scale"] as Button).text = "3D RESOLUTION SCALE:  %s" % str(state.get("res_scale", "AUTO"))
	if _settings_btns.has("ssr"):
		(_settings_btns["ssr"] as Button).text = "SCREEN-SPACE REFLECTIONS (SSR):  %s" % ("ON" if state.get("ssr", true) else "OFF")
	if _settings_btns.has("ssao"):
		(_settings_btns["ssao"] as Button).text = "AMBIENT OCCLUSION (SSAO):  %s" % ("ON" if state.get("ssao", true) else "OFF")
	if _settings_btns.has("vol_fog"):
		(_settings_btns["vol_fog"] as Button).text = "VOLUMETRIC FOG:  %s" % ("ON" if state.get("vol_fog", true) else "OFF")
	if _settings_btns.has("voxel_gi"):
		(_settings_btns["voxel_gi"] as Button).text = "VOXEL GI INDIRECT BOUNCE:  %s" % ("ON" if state.get("voxel_gi", true) else "OFF")
	if _settings_btns.has("pom"):
		(_settings_btns["pom"] as Button).text = "PARALLAX BRICK & GROUND (POM):  %s" % str(state.get("pom", "HIGH"))
	if _settings_btns.has("telemetry"):
		(_settings_btns["telemetry"] as Button).text = "PERF TELEMETRY HUD [F3]:  %s" % ("ON" if state.get("telemetry", false) else "OFF")


func _build_defeat_overlay() -> void:
	defeat_panel = ColorRect.new()
	defeat_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	defeat_panel.color = Color(0.02, 0.01, 0.01, 0.78)
	defeat_panel.visible = false

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.offset_left = -260
	vb.offset_top = -95
	vb.offset_right = 260
	vb.offset_bottom = 110
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)

	var h := Label.new()
	h.text = "CAM DISCONNECTED"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 34)
	h.add_theme_color_override("font_color", Color(0.92, 0.24, 0.20))
	vb.add_child(h)

	defeat_info = Label.new()
	defeat_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	defeat_info.add_theme_font_size_override("font_size", 16)
	defeat_info.add_theme_color_override("font_color", Color(0.84, 0.84, 0.84))
	vb.add_child(defeat_info)

	var btn := Button.new()
	btn.text = "RECONNECT [RESTART]"
	btn.custom_minimum_size = Vector2(220, 44)
	btn.pressed.connect(func(): emit_signal("restart_requested"))
	vb.add_child(btn)

	defeat_panel.add_child(vb)
	add_child(defeat_panel)


func set_world_texture(tex: Texture2D) -> void:
	if post_rect:
		post_rect.texture = tex


func set_capture_mode(clean: bool) -> void:
	title_panel.visible = false
	defeat_panel.visible = false
	if settings_panel:
		settings_panel.visible = false
	if loading_overlay:
		loading_overlay.visible = false
	if perf_label:
		perf_label.visible = false
	stats_label.visible = not clean
	rec_label.visible = not clean
	prompt_label.visible = not clean
	toast_label.visible = not clean
	hit_marker.visible = false
	post_mat.set_shader_parameter("fixed_time", 42.0 if clean else -1.0)
	post_mat.set_shader_parameter("glitch_amount", 0.0)
	post_mat.set_shader_parameter("yaw_vel", 0.0)
	post_mat.set_shader_parameter("hit_ca_boost", 0.0)


func show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_timer = 3.2


func show_hit(is_headshot: bool, killed: bool = false) -> void:
	hit_marker.trigger(is_headshot, killed)


func update_hud(delta: float, player: PlayerBodycam, wave: int, points: int, zombies_left: int) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_label.text = ""

	var low_hp: float = clamp((45.0 - player.health) / 45.0, 0.0, 1.0) * 0.65
	post_mat.set_shader_parameter("damage_vignette", clamp(max(low_hp, player.damage_flash), 0.0, 1.0))
	post_mat.set_shader_parameter("glitch_amount", 0.75 if player.dead else player.hit_glitch)
	post_mat.set_shader_parameter("yaw_vel", player.yaw_vel)
	post_mat.set_shader_parameter("hit_ca_boost", player.hit_ca_boost)
	post_mat.set_shader_parameter("hit_dir_screen", player.hit_dir_screen)

	if not rec_label.visible:
		return
	var mag: int = player.ammo_in_mag[player.current_weapon]
	var res: int = player.ammo_reserve[player.current_weapon]
	var sig := player.current_weapon * 1000000 + mag * 10000 + res * 100 + int(player.health) + (1 if player.is_reloading else 0) + zombies_left * 7 + wave * 13 + points
	_hud_text_accum += delta
	if sig == _last_ammo_sig and _hud_text_accum < 0.20:
		return
	_last_ammo_sig = sig
	_hud_text_accum = 0.0

	var sec: int = int(Time.get_ticks_msec() / 1000.0)
	var blink := "●" if (sec % 2 == 0) else " "
	var mins: int = int(sec / 60.0)
	var fps := Engine.get_frames_per_second()
	rec_label.text = "REC %s  2026-11-24 23:%02d:%02d  •  %d FPS\nBODYCAM-04 // WAVE %02d" % [blink, (41 + mins) % 60, sec % 60, fps, wave]

	var wname: String = player.get_current_weapon_name() if player.has_method("get_current_weapon_name") else PlayerBodycam.WEAPONS[player.current_weapon]["name"]
	var is_melee: bool = bool(PlayerBodycam.WEAPONS[player.current_weapon].get("is_melee", false))
	var reload_tag := " [RELOADING]" if player.is_reloading else ""
	var ammo_str := "MELEE" if is_melee else ("%02d / %03d" % [mag, res])
	stats_label.text = "%s%s  %s\nHP %d%%  •  PTS %d  •  HOSTILES %d" % [
		wname, reload_tag, ammo_str, int(player.health), points, zombies_left
	]

	var obj := player.get_looked_interactable()
	prompt_label.text = obj.get_prompt(points) if obj else ""
