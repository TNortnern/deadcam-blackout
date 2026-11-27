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


class SniperScopeOverlay extends Control:
	var scope_alpha: float = 0.0
	var iris_scale: float = 1.0
	var sway_px: Vector2 = Vector2.ZERO

	func update_scope(alpha: float, iris: float, sway: Vector2) -> void:
		var clamped := clampf(alpha, 0.0, 1.0)
		var want_vis := clamped > 0.01
		if visible != want_vis:
			visible = want_vis
		if not want_vis:
			return
		scope_alpha = clamped
		iris_scale = clampf(iris, 0.65, 1.0)
		sway_px = sway
		queue_redraw()

	func _draw() -> void:
		if scope_alpha <= 0.01:
			return
		var sz := get_rect().size
		if sz.x < 10.0 or sz.y < 10.0:
			return
		var center := sz * 0.5 + sway_px
		var radius := minf(sz.x, sz.y) * 0.435 * iris_scale
		var a := scope_alpha
		var black := Color(0.008, 0.010, 0.012, a)

		# Opaque matte scope tube surround outside the lens circle
		draw_rect(Rect2(0.0, 0.0, sz.x, maxf(0.0, center.y - radius)), black, true)
		draw_rect(Rect2(0.0, center.y + radius, sz.x, maxf(0.0, sz.y - (center.y + radius))), black, true)
		draw_rect(Rect2(0.0, center.y - radius, maxf(0.0, center.x - radius), radius * 2.0), black, true)
		draw_rect(Rect2(center.x + radius, center.y - radius, maxf(0.0, sz.x - (center.x + radius)), radius * 2.0), black, true)
		# Thick circular ring mask filling the four corners cleanly
		var corner_r := radius * 1.48
		var ring_w := (corner_r - radius) * 2.0
		draw_arc(center, radius + ring_w * 0.5, 0.0, TAU, 96, black, ring_w, true)

		# Subtle optical glass rim + inner shadow vignette
		draw_arc(center, radius * 0.985, 0.0, TAU, 96, Color(0.0, 0.0, 0.0, 0.58 * a), radius * 0.055, true)
		draw_arc(center, radius * 1.002, 0.0, TAU, 96, Color(0.22, 0.25, 0.28, 0.45 * a), 2.2, true)

		# Crisp duplex mil-dot reticle
		var hair := Color(0.04, 0.05, 0.05, 0.92 * a)
		var post := Color(0.02, 0.02, 0.02, 0.98 * a)
		var post_start := radius * 0.48
		# Thin inner crosshairs
		draw_line(center + Vector2(-radius, 0.0), center + Vector2(radius, 0.0), hair, 1.3, true)
		draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, radius), hair, 1.3, true)
		# Heavy outer duplex posts
		draw_line(center + Vector2(-radius, 0.0), center + Vector2(-post_start, 0.0), post, 4.2, true)
		draw_line(center + Vector2(post_start, 0.0), center + Vector2(radius, 0.0), post, 4.2, true)
		draw_line(center + Vector2(0.0, post_start), center + Vector2(0.0, radius), post, 4.2, true)
		draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, -post_start * 1.15), post, 3.6, true)

		# Mil-dot rangefinder stadia ticks
		var step := radius * 0.085
		for k in range(1, 5):
			var off := step * float(k)
			var tick := 6.0 if (k % 2 == 0) else 3.8
			draw_line(center + Vector2(-off, -tick), center + Vector2(-off, tick), hair, 1.4, true)
			draw_line(center + Vector2(off, -tick), center + Vector2(off, tick), hair, 1.4, true)
			draw_line(center + Vector2(-tick, off), center + Vector2(tick, off), hair, 1.4, true)
			draw_line(center + Vector2(-tick, -off), center + Vector2(tick, -off), hair, 1.4, true)

		# Illuminated tactical red/amber center aiming dot
		draw_circle(center, 3.6, Color(1.0, 0.16, 0.08, 0.35 * a))
		draw_circle(center, 1.9, Color(1.0, 0.24, 0.12, 0.96 * a))


var post_rect: TextureRect
var post_mat: ShaderMaterial
var rec_label: Label
var stats_label: Label
var prompt_label: Label
var toast_label: Label
var perf_label: Label
var loading_overlay: ColorRect
var _loading_label: Label
var hit_marker: TacticalHitmarker
var scope_overlay: SniperScopeOverlay
var title_panel: Control
var defeat_panel: Control
var defeat_info: Label
var settings_panel: Control
var _settings_hdr: Label
var _settings_inv_btn: Button
var _settings_rst_btn: Button
var _settings_renderer_lbl: Label
var _settings_res_lbl: Label
var _settings_btns: Dictionary = {}
var inventory_panel: Control
var _inv_body: VBoxContainer
var dev_panel: Control
var _dev_god_btn: Button

var toast_timer: float = 0.0
var hud_visible_minimal: bool = true
var _hud_text_accum: float = 0.25
var _last_ammo_sig: int = -1
var _last_hotbar_str: String = ""

signal start_requested
signal start_daylight_requested
signal restart_requested
signal graphics_action(key: String)
signal open_settings_requested
signal settings_closed
signal open_inventory_requested
signal inventory_action(action: String, arg: Variant)
signal inventory_closed
signal dev_action(action: String, arg: Variant)
signal dev_closed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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

	# Full-screen 4x telescopic sniper scope overlay (active strictly when ADS on M700 Hunting Rifle!)
	scope_overlay = SniperScopeOverlay.new()
	scope_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	scope_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scope_overlay.visible = false
	add_child(scope_overlay)

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
	if hit_marker:
		hit_marker.visible = false
	if scope_overlay:
		scope_overlay.update_scope(0.0, 1.0, Vector2.ZERO)
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
	lmsg.offset_left = -300
	lmsg.offset_top = -18
	lmsg.offset_right = 300
	lmsg.offset_bottom = 18
	lmsg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lmsg.add_theme_font_size_override("font_size", 16)
	lmsg.add_theme_color_override("font_color", Color(0.84, 0.88, 0.84, 0.88))
	_loading_label = lmsg
	loading_overlay.add_child(lmsg)
	add_child(loading_overlay)


func set_loading_status(msg: String) -> void:
	if _loading_label:
		_loading_label.text = msg


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
	sub.text = "ASYLUM  •  CATACOMB TUNNELS  •  WINTER COURTYARD  •  FROZEN SAWMILL\nWASD Move | LMB Fire / Bow | RMB Aim / Heavy Melee | V Quick Melee | G/Q Grenade | R Reload | E Interact\n1-3 Firearms | 4 Special | 5 Melee | I Inventory | ESC Pause | F Flashlight | F9 Day/Night"
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
	cfg_btn.pressed.connect(func(): emit_signal("open_settings_requested"))
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

	_settings_hdr = Label.new()
	_settings_hdr.text = "BODYCAM-04 // PAUSED & SETTINGS"
	_settings_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_hdr.add_theme_font_size_override("font_size", 18)
	_settings_hdr.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68))
	vb.add_child(_settings_hdr)

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
		b.custom_minimum_size = Vector2(460, 28)
		b.add_theme_font_size_override("font_size", 13)
		var captured_k: String = k
		b.pressed.connect(func(): emit_signal("graphics_action", captured_k))
		vb.add_child(b)
		_settings_btns[k] = b

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 10)
	var close_btn := Button.new()
	close_btn.text = "RESUME [ESC]"
	close_btn.custom_minimum_size = Vector2(150, 36)
	close_btn.pressed.connect(func(): emit_signal("settings_closed"))
	btn_row.add_child(close_btn)
	_settings_inv_btn = Button.new()
	_settings_inv_btn.text = "INVENTORY [I]"
	_settings_inv_btn.custom_minimum_size = Vector2(150, 36)
	_settings_inv_btn.pressed.connect(func(): emit_signal("open_inventory_requested"))
	btn_row.add_child(_settings_inv_btn)
	_settings_rst_btn = Button.new()
	_settings_rst_btn.text = "RESTART RUN"
	_settings_rst_btn.custom_minimum_size = Vector2(140, 36)
	_settings_rst_btn.pressed.connect(func(): emit_signal("restart_requested"))
	btn_row.add_child(_settings_rst_btn)
	vb.add_child(btn_row)

	card.add_child(vb)
	settings_panel.add_child(card)
	add_child(settings_panel)
	_build_inventory_overlay()
	_build_dev_overlay()


func set_settings_context(in_match: bool) -> void:
	if _settings_hdr:
		_settings_hdr.text = "BODYCAM-04 // PAUSED & SETTINGS" if in_match else "BODYCAM-04 // GRAPHICS SETTINGS"
	if _settings_inv_btn:
		_settings_inv_btn.visible = in_match
	if _settings_rst_btn:
		_settings_rst_btn.visible = in_match


func _make_card_style(border_col := Color(0.28, 0.34, 0.36, 0.92)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.045, 0.052, 0.062, 0.95)
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_content_margin_all(16)
	sb.set_corner_radius_all(4)
	return sb


func _build_inventory_overlay() -> void:
	inventory_panel = ColorRect.new()
	inventory_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	inventory_panel.color = Color(0.012, 0.016, 0.020, 0.80)
	inventory_panel.visible = false

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -330
	card.offset_top = -255
	card.offset_right = 330
	card.offset_bottom = 255
	card.add_theme_stylebox_override("panel", _make_card_style(Color(0.36, 0.48, 0.44, 0.94)))

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)

	var hdr := Label.new()
	hdr.text = "TACTICAL LOADOUT // INVENTORY [PAUSED]"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 18)
	hdr.add_theme_color_override("font_color", Color(0.95, 0.88, 0.64))
	outer.add_child(hdr)

	var sub := Label.new()
	sub.text = "Reorder firearm slots [1-3], swap active melee [V / 5], or select throwable [G / Q]."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.72, 0.78, 0.76))
	outer.add_child(sub)

	_inv_body = VBoxContainer.new()
	_inv_body.add_theme_constant_override("separation", 8)
	_inv_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(_inv_body)

	var close_b := Button.new()
	close_b.text = "RESUME [I / ESC]"
	close_b.custom_minimum_size = Vector2(220, 36)
	close_b.pressed.connect(func(): emit_signal("inventory_closed"))
	outer.add_child(close_b)

	card.add_child(outer)
	inventory_panel.add_child(card)
	add_child(inventory_panel)


func refresh_inventory(player: PlayerBodycam) -> void:
	if _inv_body == null or player == null:
		return
	for ch in _inv_body.get_children():
		ch.queue_free()

	var f_hdr := Label.new()
	f_hdr.text = "FIREARM SLOTS (CAP %d — PICKUP ORDER)" % PlayerBodycam.MAX_FIREARM_SLOTS
	f_hdr.add_theme_font_size_override("font_size", 13)
	f_hdr.add_theme_color_override("font_color", Color(0.66, 0.92, 0.76))
	_inv_body.add_child(f_hdr)

	for i in range(PlayerBodycam.MAX_FIREARM_SLOTS):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var slot_lbl := Label.new()
		slot_lbl.custom_minimum_size = Vector2(270, 28)
		slot_lbl.add_theme_font_size_override("font_size", 14)
		if i < player.firearm_slots.size():
			var wi := player.firearm_slots[i]
			var wname := str(PlayerBodycam.WEAPONS[wi]["name"])
			if player.is_weapon_upgraded(wi):
				wname += " MK-II"
			var held := " [EQUIPPED]" if wi == player.current_weapon else ""
			slot_lbl.text = "[%d] %s  (%d/%d)%s" % [i + 1, wname, player.ammo_in_mag[wi], player.ammo_reserve[wi], held]
			slot_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.72) if wi == player.current_weapon else Color(0.88, 0.90, 0.88))
			row.add_child(slot_lbl)

			var b_up := Button.new()
			b_up.text = "▲"
			b_up.disabled = (i == 0)
			var ci := i
			b_up.pressed.connect(func(): emit_signal("inventory_action", "swap", [ci, ci - 1]))
			row.add_child(b_up)

			var b_dn := Button.new()
			b_dn.text = "▼"
			b_dn.disabled = (i >= player.firearm_slots.size() - 1)
			b_dn.pressed.connect(func(): emit_signal("inventory_action", "swap", [ci, ci + 1]))
			row.add_child(b_dn)

			var b_eq := Button.new()
			b_eq.text = "EQUIP"
			b_eq.pressed.connect(func(): emit_signal("inventory_action", "equip_slot", ci))
			row.add_child(b_eq)

			var b_dr := Button.new()
			b_dr.text = "DROP"
			b_dr.disabled = (player.firearm_slots.size() <= 1)
			b_dr.pressed.connect(func(): emit_signal("inventory_action", "drop_slot", ci))
			row.add_child(b_dr)
		else:
			slot_lbl.text = "[%d] — EMPTY SLOT —" % (i + 1)
			slot_lbl.add_theme_color_override("font_color", Color(0.50, 0.54, 0.56))
			row.add_child(slot_lbl)
		_inv_body.add_child(row)

	# Special Slot [4]
	var sp_row := HBoxContainer.new()
	sp_row.add_theme_constant_override("separation", 6)
	var sp_lbl := Label.new()
	sp_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp_lbl.add_theme_font_size_override("font_size", 13)
	if player.special_slot >= 0:
		var sw := player.special_slot
		var mk2 := " MK-II" if player.is_weapon_upgraded(sw) else ""
		var active_s := " [EQUIPPED]" if player.current_weapon == sw else ""
		sp_lbl.text = "SPECIAL [4]: %s%s (%d/%d)%s" % [PlayerBodycam.WEAPONS[sw]["name"], mk2, player.ammo_in_mag[sw], player.ammo_reserve[sw], active_s]
		sp_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.36))
		sp_row.add_child(sp_lbl)
		var b_sp := Button.new()
		b_sp.text = "EQUIP"
		b_sp.pressed.connect(func(): emit_signal("inventory_action", "equip_special", 0))
		sp_row.add_child(b_sp)
	else:
		sp_lbl.text = "SPECIAL [4]: — EMPTY (COMPOUND BOW / SPECIAL) —"
		sp_lbl.add_theme_color_override("font_color", Color(0.56, 0.60, 0.62))
		sp_row.add_child(sp_lbl)
	_inv_body.add_child(sp_row)

	# Melee Weapon selector [V / 5]
	var m_hdr := Label.new()
	m_hdr.text = "MELEE WEAPON ([V] QUICK SLASH  •  [5] EQUIP FOR COMBOS + RMB HEAVY)"
	m_hdr.add_theme_font_size_override("font_size", 13)
	m_hdr.add_theme_color_override("font_color", Color(0.66, 0.92, 0.76))
	_inv_body.add_child(m_hdr)

	var m_row := HBoxContainer.new()
	m_row.add_theme_constant_override("separation", 6)
	for mid: String in player.owned_melee:
		var m_btn := Button.new()
		var m_nm := str(PlayerBodycam.MELEE_CATALOG[mid]["name"])
		m_btn.text = ("★ " + m_nm) if player.equipped_melee_id == mid else m_nm
		var cap_mid := mid
		m_btn.pressed.connect(func(): emit_signal("inventory_action", "select_melee", cap_mid))
		m_row.add_child(m_btn)
	var un_btn := Button.new()
	un_btn.text = "★ UNARMED (GUN BASH)" if player.equipped_melee_id == "" else "UNEQUIP (GUN BASH)"
	un_btn.pressed.connect(func(): emit_signal("inventory_action", "select_melee", ""))
	m_row.add_child(un_btn)
	_inv_body.add_child(m_row)

	# Throwables selector [G / Q]
	var g_hdr := Label.new()
	g_hdr.text = "THROWABLES ([G] THROW  •  [Q] CYCLE TYPE)"
	g_hdr.add_theme_font_size_override("font_size", 13)
	g_hdr.add_theme_color_override("font_color", Color(0.66, 0.92, 0.76))
	_inv_body.add_child(g_hdr)

	var g_row := HBoxContainer.new()
	g_row.add_theme_constant_override("separation", 8)
	for gt: String in PlayerBodycam.GRENADE_ORDER:
		var gb := Button.new()
		var cnt: int = int(player.grenade_counts.get(gt, 0))
		var lbl := "%s x%d" % [PlayerBodycam.GRENADE_LABELS[gt], cnt]
		gb.text = ("★ " + lbl) if player.equipped_grenade == gt else lbl
		gb.custom_minimum_size = Vector2(150, 32)
		var cap_gt := gt
		gb.pressed.connect(func(): emit_signal("inventory_action", "select_grenade", cap_gt))
		g_row.add_child(gb)
	_inv_body.add_child(g_row)


func _build_dev_overlay() -> void:
	dev_panel = ColorRect.new()
	dev_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	dev_panel.color = Color(0.015, 0.012, 0.022, 0.80)
	dev_panel.visible = false

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -360
	card.offset_top = -270
	card.offset_right = 360
	card.offset_bottom = 270
	card.add_theme_stylebox_override("panel", _make_card_style(Color(0.86, 0.56, 0.22, 0.94)))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)

	var hdr := Label.new()
	hdr.text = "DEV DEBUG SPAWN MENU [`]  //  GAME PAUSED"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 18)
	hdr.add_theme_color_override("font_color", Color(1.0, 0.76, 0.34))
	vb.add_child(hdr)

	var whdr := Label.new()
	whdr.text = "SPAWN / GIVE ANY WEAPON (AUTO-EQUIPS INTO LOADOUT):"
	whdr.add_theme_font_size_override("font_size", 12)
	whdr.add_theme_color_override("font_color", Color(0.82, 0.88, 0.90))
	vb.add_child(whdr)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for wi in range(PlayerBodycam.WEAPONS.size()):
		if wi == 3:
			continue
		var wb := Button.new()
		wb.text = str(PlayerBodycam.WEAPONS[wi]["name"])
		wb.custom_minimum_size = Vector2(215, 28)
		wb.add_theme_font_size_override("font_size", 12)
		var cap_wi := wi
		wb.pressed.connect(func(): emit_signal("dev_action", "give_weapon", cap_wi))
		grid.add_child(wb)
	vb.add_child(grid)

	var mhdr := Label.new()
	mhdr.text = "GIVE MELEE WEAPON:"
	mhdr.add_theme_font_size_override("font_size", 12)
	mhdr.add_theme_color_override("font_color", Color(0.82, 0.88, 0.90))
	vb.add_child(mhdr)

	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 8)
	for mid in ["knife", "fire_axe", "machete"]:
		var mb := Button.new()
		mb.text = str(PlayerBodycam.MELEE_CATALOG[mid]["name"])
		mb.custom_minimum_size = Vector2(215, 28)
		var cap_m: String = mid
		mb.pressed.connect(func(): emit_signal("dev_action", "give_melee", cap_m))
		mrow.add_child(mb)
	vb.add_child(mrow)

	var chdr := Label.new()
	chdr.text = "DEBUG CONTROLS:"
	chdr.add_theme_font_size_override("font_size", 12)
	chdr.add_theme_color_override("font_color", Color(0.82, 0.88, 0.90))
	vb.add_child(chdr)

	var cgrid := GridContainer.new()
	cgrid.columns = 3
	cgrid.add_theme_constant_override("h_separation", 6)
	cgrid.add_theme_constant_override("v_separation", 6)
	var dbg_specs := [
		["+5000 POINTS", "add_points"],
		["MAX AMMO + GRENADES", "refill_all"],
		["GOD MODE: OFF", "toggle_god"],
		["UPGRADE HELD MK-II", "upgrade_cur"],
		["KILL ALL ZOMBIES", "kill_all"],
		["SKIP TO NEXT WAVE", "next_wave"],
		["SPAWN ZOMBIE NEAR", "spawn_zombie"],
		["TOGGLE DAYLIGHT [F9]", "toggle_daylight"],
		["POWER ON + OPEN GATE", "unlock_world"],
	]
	for sp in dbg_specs:
		var db := Button.new()
		db.text = sp[0]
		db.custom_minimum_size = Vector2(215, 30)
		db.add_theme_font_size_override("font_size", 12)
		var cap_a: String = sp[1]
		db.pressed.connect(func(): emit_signal("dev_action", cap_a, null))
		if cap_a == "toggle_god":
			_dev_god_btn = db
		cgrid.add_child(db)
	vb.add_child(cgrid)

	var close_d := Button.new()
	close_d.text = "CLOSE DEV MENU [` / ESC]"
	close_d.custom_minimum_size = Vector2(240, 34)
	close_d.pressed.connect(func(): emit_signal("dev_closed"))
	vb.add_child(close_d)

	card.add_child(vb)
	dev_panel.add_child(card)
	add_child(dev_panel)


func refresh_dev_menu(player: PlayerBodycam) -> void:
	if _dev_god_btn and player:
		_dev_god_btn.text = "GOD MODE: ON" if player.god_mode else "GOD MODE: OFF"


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
	if inventory_panel:
		inventory_panel.visible = false
	if dev_panel:
		dev_panel.visible = false
	if loading_overlay:
		loading_overlay.visible = false
	if perf_label:
		perf_label.visible = false
	stats_label.visible = not clean
	rec_label.visible = not clean
	prompt_label.visible = not clean
	toast_label.visible = not clean
	if hit_marker:
		hit_marker.visible = false
	if scope_overlay:
		scope_overlay.update_scope(0.0, 1.0, Vector2.ZERO)
	post_mat.set_shader_parameter("fixed_time", 42.0 if clean else -1.0)
	post_mat.set_shader_parameter("glitch_amount", 0.0)
	post_mat.set_shader_parameter("yaw_vel", 0.0)
	post_mat.set_shader_parameter("hit_ca_boost", 0.0)


func show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_timer = 3.2


func show_hit(is_headshot: bool, killed: bool = false) -> void:
	hit_marker.trigger(is_headshot, killed)


func update_hud(delta: float, player: PlayerBodycam, wave: int, points: int, zombies_left: int, active_zombies: int = -1) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_label.text = ""

	var low_hp: float = clamp((45.0 - player.health) / 45.0, 0.0, 1.0) * 0.65
	var is_paused_now := get_tree().paused
	post_mat.set_shader_parameter("damage_vignette", clamp(max(low_hp, player.damage_flash), 0.0, 1.0))
	post_mat.set_shader_parameter("glitch_amount", 0.0 if is_paused_now else (0.75 if player.dead else player.hit_glitch))
	post_mat.set_shader_parameter("yaw_vel", player.yaw_vel)
	post_mat.set_shader_parameter("hit_ca_boost", player.hit_ca_boost)
	post_mat.set_shader_parameter("hit_dir_screen", player.hit_dir_screen)
	if scope_overlay:
		var sa: float = player.sniper_scope_alpha if not player.dead else 0.0
		var ir: float = player.sniper_iris_scale if not player.dead else 1.0
		# Reticle center tracks exact camera aim (breathing sway is already applied to head/camera rotation, so reticle & shot ray agree 100%!)
		scope_overlay.update_scope(sa, ir, Vector2.ZERO)
		post_mat.set_shader_parameter("fisheye_strength", lerpf(0.212, 0.035, sa))

	if not rec_label.visible:
		return

	# Update interaction focus prompt EVERY frame (never throttled by 0.20s stats cache!)
	var obj := player.get_looked_interactable()
	prompt_label.text = obj.get_prompt(points, player) if obj else ""

	var mag: int = player.ammo_in_mag[player.current_weapon]
	var res: int = player.ammo_reserve[player.current_weapon]
	var hotbar: String = player.get_hotbar_summary() if player.has_method("get_hotbar_summary") else ""
	var act_sig := active_zombies if active_zombies >= 0 else zombies_left
	var sig := player.current_weapon * 1000000 + mag * 10000 + res * 100 + int(player.health) + (1 if player.is_reloading else 0) + zombies_left * 7 + act_sig * 17 + wave * 13 + points
	_hud_text_accum += delta
	if sig == _last_ammo_sig and hotbar == _last_hotbar_str and _hud_text_accum < 0.20:
		return
	_last_ammo_sig = sig
	_last_hotbar_str = hotbar
	_hud_text_accum = 0.0

	var sec: int = int(Time.get_ticks_msec() / 1000.0)
	var blink := "●" if (sec % 2 == 0) else " "
	var mins: int = int(sec / 60.0)
	var fps := Engine.get_frames_per_second()
	var god_tag := "  [GOD]" if player.god_mode else ""
	rec_label.text = "REC %s  2026-11-24 23:%02d:%02d  •  %d FPS%s\nBODYCAM-04 // WAVE %02d  [I] INV  [ESC] PAUSE" % [blink, (41 + mins) % 60, sec % 60, fps, god_tag, wave]

	var wname: String = player.get_current_weapon_name() if player.has_method("get_current_weapon_name") else PlayerBodycam.WEAPONS[player.current_weapon]["name"]
	var wkey: String = player.get_slot_key_for_weapon(player.current_weapon) if player.has_method("get_slot_key_for_weapon") else str(PlayerBodycam.WEAPONS[player.current_weapon].get("key", str(player.current_weapon + 1)))
	var is_melee: bool = bool(PlayerBodycam.WEAPONS[player.current_weapon].get("is_melee", false))
	var reload_tag := " [RELOADING]" if player.is_reloading else ""
	var ammo_str := "MELEE" if is_melee else ("%02d / %03d" % [mag, res])
	var hostile_str := ("HOSTILES %d (%d ACTIVE)" % [zombies_left, active_zombies]) if (active_zombies >= 0 and active_zombies < zombies_left) else ("HOSTILES %d" % zombies_left)
	stats_label.text = "[%s] %s%s  %s  •  HP %d%%  •  PTS %d  •  %s\n%s" % [
		wkey, wname, reload_tag, ammo_str, int(player.health), points, hostile_str, hotbar
	]
