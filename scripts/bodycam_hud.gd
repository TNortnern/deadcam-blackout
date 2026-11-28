extends CanvasLayer
class_name BodycamHUD
## Bodycam post-process pass plus every piece of interface: in-run HUD (custom drawn, redrawn only when its data changes),
## reticle layer, banners, and the title / pause / loadout / debrief screens.

const COL_TEXT := Color(0.90, 0.92, 0.88)
const COL_DIM := Color(0.62, 0.66, 0.64)
const COL_AMBER := Color(0.96, 0.76, 0.34)
const COL_RED := Color(0.95, 0.27, 0.21)
const COL_GREEN := Color(0.56, 0.90, 0.62)
const COL_PANEL := Color(0.035, 0.042, 0.050, 0.94)
const COL_LINE := Color(0.30, 0.35, 0.37, 0.90)
const MARGIN := 30.0

const TIPS := [
	"Headshots stagger. Leg shots cripple and turn walkers into crawlers.",
	"Hold RMB with a melee weapon to charge its heavy attack. Release to swing.",
	"[V] with a melee weapon in hand shoves the pack back and buys you room.",
	"A Screamer rallies every infected in earshot. Drop it before it finishes inhaling.",
	"Spitters keep their distance. Their acid slows you, so break line of sight or close in.",
	"The Riot Bruiser's visor stops bullets until it shatters. Sidestep its charge and it stuns itself on the wall.",
	"Health regenerates after five seconds without taking a hit.",
	"Restore power at the generator to bring the armory bench online.",
	"Rifle rounds pass through the first body and hit the one behind it.",
	"Grabbed? Mash [V] or [LMB] to tear free before the next bite.",
]


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
		progress -= delta / (0.26 if killed else 0.18)
		if progress <= 0.0:
			progress = 0.0
			visible = false
			return
		queue_redraw()

	func _draw() -> void:
		if progress <= 0.0:
			return
		var alpha := clampf(progress * 1.4, 0.0, 1.0)
		var pop := 1.0 + (0.55 if killed else 0.38) * pow(progress, 2.0)
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
		draw_rect(Rect2(0.0, 0.0, sz.x, maxf(0.0, center.y - radius)), black, true)
		draw_rect(Rect2(0.0, center.y + radius, sz.x, maxf(0.0, sz.y - (center.y + radius))), black, true)
		draw_rect(Rect2(0.0, center.y - radius, maxf(0.0, center.x - radius), radius * 2.0), black, true)
		draw_rect(Rect2(center.x + radius, center.y - radius, maxf(0.0, sz.x - (center.x + radius)), radius * 2.0), black, true)
		var corner_r := radius * 1.48
		var ring_w := (corner_r - radius) * 2.0
		draw_arc(center, radius + ring_w * 0.5, 0.0, TAU, 96, black, ring_w, true)
		draw_arc(center, radius * 0.985, 0.0, TAU, 96, Color(0.0, 0.0, 0.0, 0.58 * a), radius * 0.055, true)
		draw_arc(center, radius * 1.002, 0.0, TAU, 96, Color(0.22, 0.25, 0.28, 0.45 * a), 2.2, true)
		var hair := Color(0.04, 0.05, 0.05, 0.92 * a)
		var post := Color(0.02, 0.02, 0.02, 0.98 * a)
		var post_start := radius * 0.48
		draw_line(center + Vector2(-radius, 0.0), center + Vector2(radius, 0.0), hair, 1.3, true)
		draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, radius), hair, 1.3, true)
		draw_line(center + Vector2(-radius, 0.0), center + Vector2(-post_start, 0.0), post, 4.2, true)
		draw_line(center + Vector2(post_start, 0.0), center + Vector2(radius, 0.0), post, 4.2, true)
		draw_line(center + Vector2(0.0, post_start), center + Vector2(0.0, radius), post, 4.2, true)
		draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, -post_start * 1.15), post, 3.6, true)
		var step := radius * 0.085
		for k in range(1, 5):
			var off := step * float(k)
			var tick := 6.0 if (k % 2 == 0) else 3.8
			draw_line(center + Vector2(-off, -tick), center + Vector2(-off, tick), hair, 1.4, true)
			draw_line(center + Vector2(off, -tick), center + Vector2(off, tick), hair, 1.4, true)
			draw_line(center + Vector2(-tick, off), center + Vector2(tick, off), hair, 1.4, true)
			draw_line(center + Vector2(-tick, -off), center + Vector2(tick, -off), hair, 1.4, true)
		draw_circle(center, 3.6, Color(1.0, 0.16, 0.08, 0.35 * a))
		draw_circle(center, 1.9, Color(1.0, 0.24, 0.12, 0.96 * a))


class DrawLayer extends Control:
	## Thin canvas that forwards its draw to the HUD so all layout code lives in one place.
	var hud: BodycamHUD
	var kind: int = 0

	func _draw() -> void:
		if hud == null:
			return
		match kind:
			0: hud._draw_panels(self)
			1: hud._draw_reticle(self)
			2: hud._draw_banners(self)


var post_rect: TextureRect
var post_mat: ShaderMaterial
var rec_label: Label
var stats_label: Label # kept as an accessible plain-text mirror of the drawn HUD
var prompt_label: Label
var toast_label: Label
var perf_label: Label
var loading_overlay: ColorRect
var _loading_label: Label
var _loading_tip: Label
var _loading_bar: ColorRect
var _loading_bar_bg: ColorRect
var hit_marker: TacticalHitmarker
var scope_overlay: SniperScopeOverlay
var title_panel: Control
var defeat_panel: Control
var defeat_info: Label
var _defeat_grid: GridContainer
var _defeat_tag: Label
var settings_panel: Control
var _settings_hdr: Label
var _settings_inv_btn: Button
var _settings_rst_btn: Button
var _settings_title_btn: Button
var _settings_renderer_lbl: Label
var _settings_res_lbl: Label
var _settings_btns: Dictionary = {}
var _settings_tabs: Dictionary = {} # name -> Control
var _settings_tab_btns: Dictionary = {}
var _option_value_lbls: Dictionary = {}
var inventory_panel: Control
var _inv_body: VBoxContainer
var dev_panel: Control
var _dev_god_btn: Button
var _title_best_lbl: Label

var _panels: DrawLayer
var _reticle: DrawLayer
var _banners: DrawLayer
var _font: Font
var _font_b: FontVariation
var _font_c: FontVariation
var _ui_click: AudioStreamPlayer
var _ui_aux: AudioStreamPlayer
var _sfx: Dictionary = {}

var toast_timer: float = 0.0
var hud_visible_minimal: bool = true
var show_crosshair: bool = true
var _clean_capture: bool = false

# --- Snapshot of game state the canvases draw from ---
var _sig: int = -1
var _hp: float = 100.0
var _hp_max: float = 100.0
var _hp_ghost: float = 100.0
var _regen: bool = false
var _slowed: bool = false
var _wave: int = 1
var _points: int = 0
var _points_shown: float = 0.0
var _hostiles: int = 0
var _wave_total: int = 0
var _intermission: float = -1.0
var _objective: String = ""
var _obj_bearing: float = INF
var _obj_dist: float = 0.0
var _heading: float = 0.0
var _w_name: String = ""
var _w_mode: String = ""
var _w_tags: String = ""
var _mag: int = 0
var _mag_size: int = 1
var _reserve: int = 0
var _is_melee: bool = false
var _melee_trait: String = ""
var _reloading: bool = false
var _reload_frac: float = 0.0
var _slots: Array = [] # [key, label, active, empty]
var _gren_label: String = ""
var _gren_count: int = 0
var _melee_label: String = ""
var _god: bool = false
var _perk_tags: Array[String] = []
var _prompt: String = ""
var _prompt_detail: String = ""
var _spread_px: float = 6.0
var _ads: float = 0.0
var _sprint: float = 0.0
var _shotgun: bool = false
var _melee_focus: bool = false
var _melee_charge: float = 0.0
var _grab: float = -1.0
var _scope: float = 0.0
var _dmg_arcs: Array[Dictionary] = [] # {"pos": Vector3, "t": float}
var _last_dmg_time: float = -99.0
var _cam_xf: Transform3D = Transform3D.IDENTITY
var _popups: Array[Dictionary] = [] # {"text", "col", "age"}
var _banner_title: String = ""
var _banner_sub: String = ""
var _banner_age: float = 99.0
var _banner_dur: float = 3.0
var _banner_col: Color = COL_TEXT
var _toasts: Array[Dictionary] = [] # {"text", "age", "dur"}
var _rec_accum: float = 1.0
var _rec_clock0: float = 0.0
var _focus_tick: int = 0

signal start_requested
signal start_daylight_requested
signal restart_requested
signal quit_to_title_requested
signal graphics_action(key: String)
signal option_action(key: String, dir: int)
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
	_font = ThemeDB.fallback_font
	_font_b = FontVariation.new()
	_font_b.base_font = _font
	_font_b.variation_embolden = 0.55
	_font_b.spacing_glyph = 1
	_font_c = FontVariation.new()
	_font_c.base_font = _font
	_font_c.variation_embolden = 0.4
	_font_c.variation_transform = Transform2D(Vector2(0.86, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)

	for k in ["ui_click", "ui_hover", "ui_buy", "ui_deny", "points_tick", "wave_start", "wave_clear"]:
		var ap := "res://assets/audio/%s.wav" % k
		if ResourceLoader.exists(ap):
			_sfx[k] = load(ap)
	_ui_click = AudioStreamPlayer.new()
	_ui_click.volume_db = -9.0
	add_child(_ui_click)
	_ui_aux = AudioStreamPlayer.new()
	_ui_aux.volume_db = -7.0
	add_child(_ui_aux)

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

	scope_overlay = SniperScopeOverlay.new()
	scope_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	scope_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scope_overlay.visible = false
	add_child(scope_overlay)

	_panels = _make_layer(0)
	_reticle = _make_layer(1)
	_banners = _make_layer(2)

	# Understated top-right recorder stamp
	rec_label = Label.new()
	rec_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rec_label.offset_left = -330
	rec_label.offset_top = 20
	rec_label.offset_right = -MARGIN
	rec_label.offset_bottom = 66
	rec_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rec_label.add_theme_font_size_override("font_size", 12)
	rec_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.92, 0.62))
	rec_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	rec_label.add_theme_constant_override("shadow_offset_x", 1)
	rec_label.add_theme_constant_override("shadow_offset_y", 1)
	rec_label.text = "REC ●  2026-11-24 23:41:08\nBODYCAM-04 // UNIT-K9"
	rec_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rec_label)

	# Plain-text mirrors of the drawn HUD. Hidden; kept so tools and tests can read the current values as strings.
	stats_label = Label.new()
	stats_label.visible = false
	add_child(stats_label)
	prompt_label = Label.new()
	prompt_label.visible = false
	add_child(prompt_label)
	toast_label = Label.new()
	toast_label.visible = false
	add_child(toast_label)

	hit_marker = TacticalHitmarker.new()
	hit_marker.set_anchors_preset(Control.PRESET_CENTER)
	hit_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_marker.visible = false
	add_child(hit_marker)
	scope_overlay.update_scope(0.0, 1.0, Vector2.ZERO)

	perf_label = Label.new()
	perf_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	perf_label.offset_left = MARGIN
	perf_label.offset_top = -168
	perf_label.offset_right = 600
	perf_label.offset_bottom = -124
	perf_label.add_theme_font_size_override("font_size", 12)
	perf_label.add_theme_color_override("font_color", Color(0.72, 0.96, 0.72, 0.90))
	perf_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	perf_label.add_theme_constant_override("shadow_offset_x", 1)
	perf_label.add_theme_constant_override("shadow_offset_y", 1)
	perf_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	perf_label.visible = false
	add_child(perf_label)

	_build_title_overlay()
	_build_defeat_overlay()
	_build_settings_overlay()
	_build_loading_overlay()
	_set_gameplay_layers_visible(false)


func _make_layer(kind: int) -> DrawLayer:
	var l := DrawLayer.new()
	l.hud = self
	l.kind = kind
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _set_gameplay_layers_visible(v: bool) -> void:
	if _panels: _panels.visible = v
	if _reticle: _reticle.visible = v
	if _banners: _banners.visible = v


func play_ui(kind: String, pitch := 1.0) -> void:
	if not _sfx.has(kind):
		return
	var pl := _ui_click if (kind == "ui_click" or kind == "ui_hover") else _ui_aux
	pl.stream = _sfx[kind]
	pl.pitch_scale = pitch
	pl.play()


# ---------------------------------------------------------------------------------------------------------------------
# Shared widget styling
# ---------------------------------------------------------------------------------------------------------------------

func _box(bg: Color, border: Color, bw := 1, margin := 10.0, radius := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_content_margin_all(margin)
	sb.set_corner_radius_all(radius)
	return sb


func _style_button(b: Button, primary := false, font_size := 14) -> void:
	var base := Color(0.10, 0.115, 0.13, 0.92)
	var edge := Color(0.30, 0.34, 0.36, 0.9)
	if primary:
		base = Color(0.20, 0.155, 0.07, 0.95)
		edge = Color(0.86, 0.66, 0.28, 0.95)
	var n := _box(base, edge, 1, 9.0)
	var h := _box(base.lightened(0.10), COL_AMBER, 1, 9.0)
	var pr := _box(base.darkened(0.25), COL_AMBER, 2, 9.0)
	var d := _box(Color(0.07, 0.075, 0.08, 0.7), Color(0.18, 0.20, 0.21, 0.7), 1, 9.0)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_stylebox_override("focus", h)
	b.add_theme_stylebox_override("disabled", d)
	b.add_theme_font_override("font", _font_b)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", COL_TEXT if not primary else Color(1.0, 0.90, 0.66))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.78))
	b.add_theme_color_override("font_pressed_color", COL_AMBER)
	b.add_theme_color_override("font_disabled_color", Color(0.42, 0.45, 0.46))
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): play_ui("ui_click"))
	b.mouse_entered.connect(func():
		if not b.disabled:
			play_ui("ui_hover"))


func _label(text: String, size: int, col: Color, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if bold:
		l.add_theme_font_override("font", _font_b)
	return l


func _make_card_style(border_col := Color(0.28, 0.34, 0.36, 0.92)) -> StyleBoxFlat:
	var sb := _box(COL_PANEL, border_col, 1, 20.0, 3)
	sb.border_width_top = 2
	return sb


func _rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.30, 0.35, 0.37, 0.55)
	r.custom_minimum_size = Vector2(0, 1)
	return r


# ---------------------------------------------------------------------------------------------------------------------
# Title
# ---------------------------------------------------------------------------------------------------------------------

func _build_title_overlay() -> void:
	title_panel = Control.new()
	title_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.012, 0.014, 0.018, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_panel.add_child(shade)
	# Darker column behind the menu so text never fights the scene
	var col := ColorRect.new()
	col.anchor_bottom = 1.0
	col.offset_right = 520
	col.color = Color(0.008, 0.010, 0.013, 0.66)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_panel.add_child(col)

	var vb := VBoxContainer.new()
	vb.anchor_top = 0.5
	vb.anchor_bottom = 0.5
	vb.offset_left = 72
	vb.offset_right = 460
	vb.offset_top = -250
	vb.offset_bottom = 250
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)

	vb.add_child(_label("BODYCAM-04  //  UNIT-K9  //  CASE 1124", 11, Color(0.92, 0.36, 0.30, 0.9)))
	var t := _label("DEADCAM", 64, Color(0.95, 0.94, 0.90), true)
	vb.add_child(t)
	var t2 := Label.new()
	t2.text = "B L A C K O U T"
	t2.add_theme_font_size_override("font_size", 24)
	t2.add_theme_color_override("font_color", COL_AMBER)
	vb.add_child(t2)
	var tag := _label("The asylum lost power at 23:41. Nobody came back out.", 13, COL_DIM)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(tag)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 14)
	vb.add_child(sp)

	var btn := Button.new()
	btn.text = "DEPLOY  —  BLACKOUT NIGHT"
	btn.custom_minimum_size = Vector2(380, 50)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_button(btn, true, 16)
	btn.pressed.connect(func(): emit_signal("start_requested"))
	vb.add_child(btn)

	var day_btn := Button.new()
	day_btn.text = "DEPLOY  —  WINTER DAYLIGHT"
	day_btn.custom_minimum_size = Vector2(380, 42)
	day_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_button(day_btn)
	day_btn.pressed.connect(func(): emit_signal("start_daylight_requested"))
	vb.add_child(day_btn)

	var cfg_btn := Button.new()
	cfg_btn.text = "SETTINGS"
	cfg_btn.custom_minimum_size = Vector2(380, 42)
	cfg_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_button(cfg_btn)
	cfg_btn.pressed.connect(func(): emit_signal("open_settings_requested"))
	vb.add_child(cfg_btn)

	if not OS.has_feature("web"):
		var quit_btn := Button.new()
		quit_btn.text = "QUIT TO DESKTOP"
		quit_btn.custom_minimum_size = Vector2(380, 38)
		quit_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_button(quit_btn)
		quit_btn.pressed.connect(func(): get_tree().quit())
		vb.add_child(quit_btn)

	_title_best_lbl = _label("", 12, COL_DIM)
	vb.add_child(_title_best_lbl)
	title_panel.add_child(vb)

	# Field manual: the whole control scheme and the loop, readable at a glance
	var manual := PanelContainer.new()
	manual.anchor_left = 1.0
	manual.anchor_right = 1.0
	manual.anchor_top = 0.5
	manual.anchor_bottom = 0.5
	manual.offset_left = -470
	manual.offset_right = -48
	manual.offset_top = -214
	manual.offset_bottom = 214
	manual.add_theme_stylebox_override("panel", _box(Color(0.03, 0.036, 0.044, 0.82), COL_LINE, 1, 18.0, 3))
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 7)
	mv.add_child(_label("FIELD MANUAL", 15, COL_AMBER, true))
	mv.add_child(_rule())
	mv.add_child(_controls_grid())
	mv.add_child(_rule())
	mv.add_child(_label("HOW TO SURVIVE", 12, COL_AMBER, true))
	for line in [
		"Kills pay points. Spend them on wall weapons, gates, traps and ammo.",
		"Start the generator to power the armory bench, then upgrade to MK-II.",
		"Headshots stagger, leg shots cripple, heavy melee knocks them flat.",
		"Health comes back after five seconds without taking a hit.",
	]:
		var hl := _label("›  " + line, 12, COL_TEXT)
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mv.add_child(hl)
	manual.add_child(mv)
	title_panel.add_child(manual)
	add_child(title_panel)


func _controls_grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 4)
	var rows := [
		["WASD", "Move", "SHIFT", "Sprint"],
		["LMB", "Fire / swing", "RMB", "Aim / charge heavy"],
		["R", "Reload", "E", "Interact / buy"],
		["V", "Quick melee / shove", "G", "Throw grenade"],
		["Q", "Cycle grenade", "F", "Flashlight"],
		["1-3", "Firearms", "4 · 5", "Special · melee"],
		["C / CTRL", "Crouch", "SPACE", "Jump"],
		["I", "Loadout", "ESC", "Pause"],
	]
	for r in rows:
		for i in range(4):
			var is_key := (i % 2 == 0)
			var l := _label(str(r[i]), 12, COL_AMBER if is_key else COL_TEXT, is_key)
			if is_key:
				l.custom_minimum_size = Vector2(66, 0)
			else:
				l.custom_minimum_size = Vector2(118, 0)
			g.add_child(l)
	return g


func set_best_record(best_wave: int, best_kills: int) -> void:
	if _title_best_lbl:
		_title_best_lbl.text = ("BEST RUN   WAVE %02d   ·   %d KILLS" % [best_wave, best_kills]) if best_wave > 0 else ""


# ---------------------------------------------------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------------------------------------------------

func _build_loading_overlay() -> void:
	loading_overlay = ColorRect.new()
	loading_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_overlay.color = Color(0.014, 0.016, 0.020, 1.0)
	loading_overlay.visible = false
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.offset_left = -330
	vb.offset_right = 330
	vb.offset_top = -80
	vb.offset_bottom = 80
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	var ttl := _label("DEADCAM  //  BLACKOUT", 22, Color(0.92, 0.92, 0.88), true)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ttl)
	_loading_label = _label("BODYCAM-04 // INITIALIZING OPTICS & LIGHTING...", 13, Color(0.78, 0.84, 0.80))
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_loading_label)
	_loading_bar_bg = ColorRect.new()
	_loading_bar_bg.color = Color(0.12, 0.14, 0.15)
	_loading_bar_bg.custom_minimum_size = Vector2(660, 3)
	_loading_bar = ColorRect.new()
	_loading_bar.color = COL_AMBER
	_loading_bar.size = Vector2(0, 3)
	_loading_bar_bg.add_child(_loading_bar)
	vb.add_child(_loading_bar_bg)
	_loading_tip = _label("", 12, COL_DIM)
	_loading_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loading_tip.text = "TIP   " + str(TIPS[int(Time.get_ticks_msec() / 7.0) % TIPS.size()])
	vb.add_child(_loading_tip)
	loading_overlay.add_child(vb)
	add_child(loading_overlay)


func set_loading_status(msg: String) -> void:
	if _loading_label:
		_loading_label.text = msg
	# "(n/m)" in the status text drives the progress bar
	var a := msg.find("(")
	var b := msg.find(")", a)
	var slash := msg.find("/", a)
	if a >= 0 and b > a and slash > a and slash < b and _loading_bar:
		var n := float(msg.substr(a + 1, slash - a - 1))
		var m := float(msg.substr(slash + 1, b - slash - 1))
		if m > 0.0:
			_loading_bar.size = Vector2(660.0 * clampf(n / m, 0.0, 1.0), 3)


# ---------------------------------------------------------------------------------------------------------------------
# Pause / settings
# ---------------------------------------------------------------------------------------------------------------------

func _build_settings_overlay() -> void:
	settings_panel = ColorRect.new()
	settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	(settings_panel as ColorRect).color = Color(0.010, 0.012, 0.016, 0.80)
	settings_panel.visible = false

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -330
	card.offset_top = -292
	card.offset_right = 330
	card.offset_bottom = 292
	card.add_theme_stylebox_override("panel", _make_card_style(Color(0.86, 0.66, 0.28, 0.9)))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 9)

	_settings_hdr = _label("PAUSED", 22, Color(0.95, 0.90, 0.72), true)
	vb.add_child(_settings_hdr)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	for tname in ["GAME", "GRAPHICS", "CONTROLS"]:
		var tb := Button.new()
		tb.text = tname
		tb.toggle_mode = true
		tb.custom_minimum_size = Vector2(130, 32)
		_style_button(tb, false, 13)
		var cap_t: String = tname
		tb.pressed.connect(func(): _show_settings_tab(cap_t))
		tab_row.add_child(tb)
		_settings_tab_btns[tname] = tb
	vb.add_child(tab_row)
	vb.add_child(_rule())

	var body := Control.new()
	body.custom_minimum_size = Vector2(620, 378)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# GAME tab
	var game_tab := VBoxContainer.new()
	game_tab.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_tab.add_theme_constant_override("separation", 7)
	for spec in [
		["sens", "MOUSE SENSITIVITY"], ["ads_sens", "AIM-DOWN-SIGHTS SENSITIVITY"], ["fov", "FIELD OF VIEW"],
		["volume", "MASTER VOLUME"], ["crosshair", "HIP-FIRE CROSSHAIR"], ["invert_y", "INVERT VERTICAL LOOK"],
		["bodycam", "BODYCAM LENS DISTORTION"], ["grain", "SENSOR GRAIN"],
	]:
		game_tab.add_child(_option_row(str(spec[0]), str(spec[1])))
	body.add_child(game_tab)
	_settings_tabs["GAME"] = game_tab

	# GRAPHICS tab
	var gfx_tab := VBoxContainer.new()
	gfx_tab.set_anchors_preset(Control.PRESET_FULL_RECT)
	gfx_tab.add_theme_constant_override("separation", 5)
	_settings_renderer_lbl = _label("", 12, COL_GREEN)
	gfx_tab.add_child(_settings_renderer_lbl)
	_settings_res_lbl = _label("", 11, COL_DIM)
	gfx_tab.add_child(_settings_res_lbl)
	for k in ["preset", "upscaler", "res_scale", "ssr", "ssao", "vol_fog", "voxel_gi", "pom", "telemetry"]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(620, 30)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_button(b, false, 12)
		var captured_k: String = k
		b.pressed.connect(func(): emit_signal("graphics_action", captured_k))
		gfx_tab.add_child(b)
		_settings_btns[k] = b
	body.add_child(gfx_tab)
	_settings_tabs["GRAPHICS"] = gfx_tab

	# CONTROLS tab
	var ctl_tab := VBoxContainer.new()
	ctl_tab.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctl_tab.add_theme_constant_override("separation", 8)
	ctl_tab.add_child(_controls_grid())
	ctl_tab.add_child(_rule())
	for line in [
		"MELEE   LMB chains a three-hit combo. Hold RMB to charge the weapon's heavy move. V shoves.",
		"QUICK MELEE   V with a firearm out whips the melee weapon across without switching.",
		"GRABBED   Mash V or LMB to break free.",
		"F3 telemetry   ·   F8 quality preset   ·   F9 day / night",
	]:
		var cl := _label(line, 12, COL_TEXT)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ctl_tab.add_child(cl)
	body.add_child(ctl_tab)
	_settings_tabs["CONTROLS"] = ctl_tab
	vb.add_child(body)
	vb.add_child(_rule())

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	btn_row.add_theme_constant_override("separation", 8)
	var close_btn := Button.new()
	close_btn.text = "RESUME  [ESC]"
	close_btn.custom_minimum_size = Vector2(160, 40)
	_style_button(close_btn, true)
	close_btn.pressed.connect(func(): emit_signal("settings_closed"))
	btn_row.add_child(close_btn)
	_settings_inv_btn = Button.new()
	_settings_inv_btn.text = "LOADOUT  [I]"
	_settings_inv_btn.custom_minimum_size = Vector2(140, 40)
	_style_button(_settings_inv_btn)
	_settings_inv_btn.pressed.connect(func(): emit_signal("open_inventory_requested"))
	btn_row.add_child(_settings_inv_btn)
	_settings_rst_btn = Button.new()
	_settings_rst_btn.text = "RESTART RUN"
	_settings_rst_btn.custom_minimum_size = Vector2(140, 40)
	_style_button(_settings_rst_btn)
	_settings_rst_btn.pressed.connect(func(): emit_signal("restart_requested"))
	btn_row.add_child(_settings_rst_btn)
	_settings_title_btn = Button.new()
	_settings_title_btn.text = "MAIN MENU"
	_settings_title_btn.custom_minimum_size = Vector2(130, 40)
	_style_button(_settings_title_btn)
	_settings_title_btn.pressed.connect(func(): emit_signal("quit_to_title_requested"))
	btn_row.add_child(_settings_title_btn)
	vb.add_child(btn_row)

	card.add_child(vb)
	settings_panel.add_child(card)
	add_child(settings_panel)
	_show_settings_tab("GAME")
	_build_inventory_overlay()
	_build_dev_overlay()


func _option_row(key: String, title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := _label(title, 13, COL_TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var dn := Button.new()
	dn.text = "‹"
	dn.custom_minimum_size = Vector2(38, 32)
	_style_button(dn, false, 16)
	dn.pressed.connect(func(): emit_signal("option_action", key, -1))
	row.add_child(dn)
	var val := _label("", 13, COL_AMBER, true)
	val.custom_minimum_size = Vector2(120, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(val)
	_option_value_lbls[key] = val
	var up := Button.new()
	up.text = "›"
	up.custom_minimum_size = Vector2(38, 32)
	_style_button(up, false, 16)
	up.pressed.connect(func(): emit_signal("option_action", key, 1))
	row.add_child(up)
	return row


func _show_settings_tab(tname: String) -> void:
	for k in _settings_tabs.keys():
		(_settings_tabs[k] as Control).visible = (str(k) == tname)
	for k in _settings_tab_btns.keys():
		(_settings_tab_btns[k] as Button).button_pressed = (str(k) == tname)


func update_option_labels(vals: Dictionary) -> void:
	for k in vals.keys():
		if _option_value_lbls.has(k):
			(_option_value_lbls[k] as Label).text = str(vals[k])


func set_settings_context(in_match: bool) -> void:
	if _settings_hdr:
		_settings_hdr.text = "PAUSED" if in_match else "SETTINGS"
	if _settings_inv_btn:
		_settings_inv_btn.visible = in_match
	if _settings_rst_btn:
		_settings_rst_btn.visible = in_match
	if _settings_title_btn:
		_settings_title_btn.visible = in_match


func update_settings_labels(state: Dictionary) -> void:
	if _settings_renderer_lbl:
		_settings_renderer_lbl.text = str(state.get("renderer", "FORWARD+"))
	if _settings_res_lbl:
		_settings_res_lbl.text = str(state.get("res_info", ""))
	var on_off := func(v) -> String: return "ON" if v else "OFF"
	var rows := {
		"preset": "QUALITY PRESET  [F8]", "upscaler": "UPSCALER / ANTI-ALIASING", "res_scale": "3D RESOLUTION SCALE",
		"ssr": "SCREEN-SPACE REFLECTIONS", "ssao": "AMBIENT OCCLUSION", "vol_fog": "VOLUMETRIC FOG",
		"voxel_gi": "VOXEL GI INDIRECT BOUNCE", "pom": "PARALLAX BRICK & GROUND", "telemetry": "PERFORMANCE TELEMETRY  [F3]",
	}
	for k in rows.keys():
		if not _settings_btns.has(k):
			continue
		var v = state.get(k, "")
		var vs: String = on_off.call(v) if v is bool else str(v)
		(_settings_btns[k] as Button).text = "%s     %s" % [str(rows[k]), vs]


# ---------------------------------------------------------------------------------------------------------------------
# Loadout
# ---------------------------------------------------------------------------------------------------------------------

func _build_inventory_overlay() -> void:
	inventory_panel = ColorRect.new()
	inventory_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	(inventory_panel as ColorRect).color = Color(0.010, 0.012, 0.016, 0.80)
	inventory_panel.visible = false

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -390
	card.offset_top = -300
	card.offset_right = 390
	card.offset_bottom = 300
	card.add_theme_stylebox_override("panel", _make_card_style(Color(0.46, 0.72, 0.56, 0.9)))

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	outer.add_child(_label("LOADOUT", 22, Color(0.95, 0.90, 0.72), true))
	outer.add_child(_label("Three firearm slots, one special, one melee weapon, three throwables. The run is paused.", 12, COL_DIM))
	outer.add_child(_rule())

	_inv_body = VBoxContainer.new()
	_inv_body.add_theme_constant_override("separation", 6)
	_inv_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(_inv_body)

	var close_b := Button.new()
	close_b.text = "RESUME  [I / ESC]"
	close_b.custom_minimum_size = Vector2(200, 40)
	close_b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_style_button(close_b, true)
	close_b.pressed.connect(func(): emit_signal("inventory_closed"))
	outer.add_child(close_b)

	card.add_child(outer)
	inventory_panel.add_child(card)
	add_child(inventory_panel)


func _inv_small_btn(text: String, disabled := false) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	b.custom_minimum_size = Vector2(0, 30)
	_style_button(b, false, 12)
	return b


func refresh_inventory(player: PlayerBodycam) -> void:
	if _inv_body == null or player == null:
		return
	for ch in _inv_body.get_children():
		ch.queue_free()

	_inv_body.add_child(_label("FIREARMS", 12, COL_GREEN, true))
	for i in range(PlayerBodycam.MAX_FIREARM_SLOTS):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 0)
		if i < player.firearm_slots.size():
			var wi := player.firearm_slots[i]
			var wname := str(PlayerBodycam.WEAPONS[wi]["name"])
			var tags: Array[String] = []
			if player.is_weapon_upgraded(wi): tags.append("MK-II")
			if player.has_attachment(wi, "optic"): tags.append("RDS")
			if player.has_attachment(wi, "suppressor"): tags.append("SD")
			if player.has_attachment(wi, "ext_mag") and not player.is_weapon_upgraded(wi): tags.append("EXT")
			if not tags.is_empty():
				wname += " [%s]" % "+".join(tags)
			var active := wi == player.current_weapon
			var nm := _label("[%d]  %s   %d / %d%s" % [i + 1, wname, player.ammo_in_mag[wi], player.ammo_reserve[wi], "    ◂ EQUIPPED" if active else ""], 14, Color(1.0, 0.95, 0.72) if active else COL_TEXT, active)
			col.add_child(nm)
			col.add_child(_label("      " + PlayerBodycam.describe_weapon(wi), 11, COL_DIM))
			row.add_child(col)
			var ci := i
			var b_up := _inv_small_btn("▲", i == 0)
			b_up.pressed.connect(func(): emit_signal("inventory_action", "swap", [ci, ci - 1]))
			row.add_child(b_up)
			var b_dn := _inv_small_btn("▼", i >= player.firearm_slots.size() - 1)
			b_dn.pressed.connect(func(): emit_signal("inventory_action", "swap", [ci, ci + 1]))
			row.add_child(b_dn)
			var b_eq := _inv_small_btn("EQUIP")
			b_eq.pressed.connect(func(): emit_signal("inventory_action", "equip_slot", ci))
			row.add_child(b_eq)
			var b_dr := _inv_small_btn("DROP", player.firearm_slots.size() <= 1)
			b_dr.pressed.connect(func(): emit_signal("inventory_action", "drop_slot", ci))
			row.add_child(b_dr)
		else:
			col.add_child(_label("[%d]  — empty —   buy from a wall mount or an evidence chest" % (i + 1), 13, Color(0.46, 0.50, 0.52)))
			row.add_child(col)
		_inv_body.add_child(row)

	var sp_row := HBoxContainer.new()
	sp_row.add_theme_constant_override("separation", 6)
	if player.special_slot >= 0:
		var sw := player.special_slot
		var mk2 := " MK-II" if player.is_weapon_upgraded(sw) else ""
		var active_s := "    ◂ EQUIPPED" if player.current_weapon == sw else ""
		var sp_lbl := _label("[4]  %s%s   %d / %d%s" % [PlayerBodycam.WEAPONS[sw]["name"], mk2, player.ammo_in_mag[sw], player.ammo_reserve[sw], active_s], 14, Color(1.0, 0.78, 0.36))
		sp_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sp_row.add_child(sp_lbl)
		var b_sp := _inv_small_btn("EQUIP")
		b_sp.pressed.connect(func(): emit_signal("inventory_action", "equip_special", 0))
		sp_row.add_child(b_sp)
	else:
		sp_row.add_child(_label("[4]  — no special weapon —   evidence chests can roll one", 13, Color(0.46, 0.50, 0.52)))
	_inv_body.add_child(sp_row)
	_inv_body.add_child(_rule())

	_inv_body.add_child(_label("MELEE    [5] equip  ·  LMB combo  ·  hold RMB heavy  ·  [V] shove / quick slash", 12, COL_GREEN, true))
	var m_row := HFlowContainer.new()
	m_row.add_theme_constant_override("h_separation", 6)
	m_row.add_theme_constant_override("v_separation", 6)
	for mid: String in player.owned_melee:
		var m_nm := str(PlayerBodycam.MELEE_CATALOG[mid]["name"])
		var m_btn := _inv_small_btn(("★ " + m_nm) if player.equipped_melee_id == mid else m_nm)
		var cap_mid := mid
		m_btn.pressed.connect(func(): emit_signal("inventory_action", "select_melee", cap_mid))
		m_row.add_child(m_btn)
	var un_btn := _inv_small_btn("★ UNARMED (GUN BASH)" if player.equipped_melee_id == "" else "UNARMED (GUN BASH)")
	un_btn.pressed.connect(func(): emit_signal("inventory_action", "select_melee", ""))
	m_row.add_child(un_btn)
	_inv_body.add_child(m_row)
	if player.equipped_melee_id != "" and PlayerBodycam.MELEE_CATALOG.has(player.equipped_melee_id):
		var md: Dictionary = PlayerBodycam.MELEE_CATALOG[player.equipped_melee_id]
		_inv_body.add_child(_label("      DMG %d  ·  REACH %.1fm  ·  %s" % [int(md["damage"]), float(md["reach"]), str(md.get("trait", ""))], 11, COL_DIM))
	_inv_body.add_child(_rule())

	_inv_body.add_child(_label("THROWABLES    [G] throw  ·  [Q] cycle", 12, COL_GREEN, true))
	var g_row := HBoxContainer.new()
	g_row.add_theme_constant_override("separation", 8)
	for gt: String in PlayerBodycam.GRENADE_ORDER:
		var cnt: int = int(player.grenade_counts.get(gt, 0))
		var lbl := "%s  ×%d" % [PlayerBodycam.GRENADE_LABELS[gt], cnt]
		var gb := _inv_small_btn(("★ " + lbl) if player.equipped_grenade == gt else lbl)
		gb.custom_minimum_size = Vector2(150, 32)
		var cap_gt := gt
		gb.pressed.connect(func(): emit_signal("inventory_action", "select_grenade", cap_gt))
		g_row.add_child(gb)
	_inv_body.add_child(g_row)


# ---------------------------------------------------------------------------------------------------------------------
# Dev menu
# ---------------------------------------------------------------------------------------------------------------------

func _build_dev_overlay() -> void:
	dev_panel = ColorRect.new()
	dev_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	(dev_panel as ColorRect).color = Color(0.015, 0.012, 0.022, 0.80)
	dev_panel.visible = false

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -450
	card.offset_top = -340
	card.offset_right = 450
	card.offset_bottom = 340
	card.add_theme_stylebox_override("panel", _make_card_style(Color(0.86, 0.56, 0.22, 0.94)))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.add_child(_label("DEV SPAWN MENU  [`]", 18, Color(1.0, 0.76, 0.34), true))
	vb.add_child(_label("GIVE WEAPON", 11, COL_DIM, true))

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	for wi in range(PlayerBodycam.WEAPONS.size()):
		if wi == 3:
			continue
		var wb := Button.new()
		wb.text = str(PlayerBodycam.WEAPONS[wi]["name"])
		wb.custom_minimum_size = Vector2(208, 26)
		_style_button(wb, false, 11)
		var cap_wi := wi
		wb.pressed.connect(func(): emit_signal("dev_action", "give_weapon", cap_wi))
		grid.add_child(wb)
	vb.add_child(grid)

	vb.add_child(_label("GIVE MELEE", 11, COL_DIM, true))
	var mrow := GridContainer.new()
	mrow.columns = 3
	mrow.add_theme_constant_override("h_separation", 6)
	mrow.add_theme_constant_override("v_separation", 6)
	for mid in ["knife", "fire_axe", "machete", "bat", "bat_spiked", "crowbar"]:
		var mb := Button.new()
		mb.text = str(PlayerBodycam.MELEE_CATALOG[mid]["name"])
		mb.custom_minimum_size = Vector2(278, 26)
		_style_button(mb, false, 11)
		var cap_m: String = mid
		mb.pressed.connect(func(): emit_signal("dev_action", "give_melee", cap_m))
		mrow.add_child(mb)
	vb.add_child(mrow)

	vb.add_child(_label("DEBUG", 11, COL_DIM, true))
	var cgrid := GridContainer.new()
	cgrid.columns = 4
	cgrid.add_theme_constant_override("h_separation", 5)
	cgrid.add_theme_constant_override("v_separation", 5)
	var dbg_specs := [
		["+5000 POINTS", "add_points"],
		["MAX AMMO + GRENADES", "refill_all"],
		["GOD MODE: OFF", "toggle_god"],
		["UPGRADE HELD MK-II", "upgrade_cur"],
		["INSTALL OPTIC (RDS)", "attach_optic"],
		["INSTALL SUPPRESSOR", "attach_suppressor"],
		["KILL ALL ZOMBIES", "kill_all"],
		["SKIP TO NEXT WAVE", "next_wave"],
		["SPAWN RIOT BRUISER", "spawn_bruiser"],
		["SPAWN BLOATER", "spawn_exploder"],
		["SPAWN CRAWLER", "spawn_crawler"],
		["SPAWN ZOMBIE NEAR", "spawn_zombie"],
		["SPAWN SPITTER", "spawn_spitter"],
		["SPAWN SCREAMER", "spawn_screamer"],
		["SPAWN RUNNER", "spawn_runner"],
		["TOGGLE DAYLIGHT [F9]", "toggle_daylight"],
		["POWER ON + OPEN GATES", "unlock_world"],
	]
	for sp in dbg_specs:
		var db := Button.new()
		db.text = sp[0]
		db.custom_minimum_size = Vector2(208, 27)
		_style_button(db, false, 11)
		var cap_a: String = sp[1]
		db.pressed.connect(func(): emit_signal("dev_action", cap_a, null))
		if cap_a == "toggle_god":
			_dev_god_btn = db
		cgrid.add_child(db)
	vb.add_child(cgrid)

	var close_d := Button.new()
	close_d.text = "CLOSE  [` / ESC]"
	close_d.custom_minimum_size = Vector2(200, 36)
	close_d.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_style_button(close_d, true)
	close_d.pressed.connect(func(): emit_signal("dev_closed"))
	vb.add_child(close_d)

	card.add_child(vb)
	dev_panel.add_child(card)
	add_child(dev_panel)


func refresh_dev_menu(player: PlayerBodycam) -> void:
	if _dev_god_btn and player:
		_dev_god_btn.text = "GOD MODE: ON" if player.god_mode else "GOD MODE: OFF"


# ---------------------------------------------------------------------------------------------------------------------
# Debrief
# ---------------------------------------------------------------------------------------------------------------------

func _build_defeat_overlay() -> void:
	defeat_panel = ColorRect.new()
	defeat_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	(defeat_panel as ColorRect).color = Color(0.03, 0.006, 0.006, 0.84)
	defeat_panel.visible = false

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.offset_left = -300
	vb.offset_top = -230
	vb.offset_right = 300
	vb.offset_bottom = 230
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)

	vb.add_child(_label("BODYCAM-04  //  FEED TERMINATED", 12, Color(0.92, 0.36, 0.30, 0.9)))
	vb.add_child(_label("SIGNAL LOST", 48, Color(0.94, 0.26, 0.21), true))
	_defeat_tag = _label("", 14, COL_AMBER, true)
	vb.add_child(_defeat_tag)
	defeat_info = _label("", 13, COL_DIM)
	vb.add_child(defeat_info)
	vb.add_child(_rule())
	_defeat_grid = GridContainer.new()
	_defeat_grid.columns = 4
	_defeat_grid.add_theme_constant_override("h_separation", 26)
	_defeat_grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(_defeat_grid)
	vb.add_child(_rule())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var btn := Button.new()
	btn.text = "REDEPLOY"
	btn.custom_minimum_size = Vector2(220, 46)
	_style_button(btn, true, 16)
	btn.pressed.connect(func(): emit_signal("restart_requested"))
	row.add_child(btn)
	var tb := Button.new()
	tb.text = "MAIN MENU"
	tb.custom_minimum_size = Vector2(160, 46)
	_style_button(tb)
	tb.pressed.connect(func(): emit_signal("quit_to_title_requested"))
	row.add_child(tb)
	vb.add_child(row)

	defeat_panel.add_child(vb)
	add_child(defeat_panel)


func show_defeat(stats: Dictionary) -> void:
	for ch in _defeat_grid.get_children():
		ch.queue_free()
	var rows := [
		["WAVE REACHED", "%02d" % int(stats.get("wave", 1))],
		["TIME SURVIVED", str(stats.get("time", "0:00"))],
		["KILLS", str(int(stats.get("kills", 0)))],
		["HEADSHOTS", "%d  (%d%%)" % [int(stats.get("headshots", 0)), int(stats.get("hs_pct", 0))]],
		["ACCURACY", "%d%%" % int(stats.get("accuracy", 0))],
		["POINTS EARNED", str(int(stats.get("earned", 0)))],
		["DAMAGE TAKEN", str(int(stats.get("damage_taken", 0)))],
		["KILLED BY", str(stats.get("killer", "THE INFECTED"))],
	]
	for r in rows:
		var k := _label(str(r[0]), 11, COL_DIM, true)
		k.custom_minimum_size = Vector2(120, 0)
		_defeat_grid.add_child(k)
		var v := _label(str(r[1]), 17, COL_TEXT, true)
		v.custom_minimum_size = Vector2(130, 0)
		_defeat_grid.add_child(v)
	_defeat_tag.text = "NEW BEST RUN" if bool(stats.get("new_best", false)) else ""
	defeat_info.text = "SURVIVED WAVE %d  •  KILLS: %d  •  HEADSHOTS: %d" % [int(stats.get("wave", 1)), int(stats.get("kills", 0)), int(stats.get("headshots", 0))]
	defeat_panel.visible = true
	_set_gameplay_layers_visible(false)


# ---------------------------------------------------------------------------------------------------------------------
# Runtime API
# ---------------------------------------------------------------------------------------------------------------------

func set_world_texture(tex: Texture2D) -> void:
	if post_rect:
		post_rect.texture = tex


func set_capture_mode(clean: bool) -> void:
	_clean_capture = clean
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
	rec_label.visible = not clean
	_set_gameplay_layers_visible(not clean)
	if hit_marker:
		hit_marker.visible = false
	if scope_overlay:
		scope_overlay.update_scope(0.0, 1.0, Vector2.ZERO)
	post_mat.set_shader_parameter("fixed_time", 42.0 if clean else -1.0)
	post_mat.set_shader_parameter("glitch_amount", 0.0)
	post_mat.set_shader_parameter("yaw_vel", 0.0)
	post_mat.set_shader_parameter("hit_ca_boost", 0.0)


func show_toast(msg: String, dur := 3.2) -> void:
	if msg == "":
		return
	toast_label.text = msg
	toast_timer = dur
	# Newest message first; an identical message refreshes instead of stacking
	for t in _toasts:
		if str(t["text"]) == msg:
			t["age"] = 0.0
			t["dur"] = dur
			return
	_toasts.push_front({"text": msg, "age": 0.0, "dur": dur})
	while _toasts.size() > 3:
		_toasts.pop_back()
	if _banners:
		_banners.queue_redraw()


func show_banner(title: String, sub: String, col := COL_TEXT, dur := 3.2) -> void:
	_banner_title = title
	_banner_sub = sub
	_banner_col = col
	_banner_age = 0.0
	_banner_dur = dur


func show_hit(is_headshot: bool, killed: bool = false) -> void:
	hit_marker.trigger(is_headshot, killed)


func push_points(amount: int, label: String = "") -> void:
	if amount == 0 and label == "":
		return
	var txt := (("+%d" % amount) if amount > 0 else str(amount)) if amount != 0 else ""
	if label != "":
		txt = (txt + "  " + label).strip_edges()
	var col := COL_AMBER if amount >= 0 else COL_RED
	if label.begins_with("HEADSHOT") or label.begins_with("BACKSTAB") or label.begins_with("SILENCED"):
		col = Color(1.0, 0.42, 0.30)
	_popups.push_front({"text": txt, "col": col, "age": 0.0})
	while _popups.size() > 5:
		_popups.pop_back()
	if amount > 0:
		play_ui("points_tick", randf_range(0.96, 1.08))


func is_any_menu_open() -> bool:
	return title_panel.visible or defeat_panel.visible or settings_panel.visible or inventory_panel.visible or dev_panel.visible


func update_hud(delta: float, player: PlayerBodycam, wave: int, points: int, zombies_left: int, active_zombies: int = -1, ctx: Dictionary = {}) -> void:
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
	var sa: float = player.sniper_scope_alpha if not player.dead else 0.0
	if scope_overlay:
		var ir: float = player.sniper_iris_scale if not player.dead else 1.0
		scope_overlay.update_scope(sa, ir, Vector2.ZERO)
		post_mat.set_shader_parameter("fisheye_strength", lerpf(float(ctx.get("fisheye", 0.212)), 0.035, sa))

	var in_run := not _clean_capture and not title_panel.visible and not defeat_panel.visible and not (loading_overlay and loading_overlay.visible)
	if _panels.visible != in_run:
		_set_gameplay_layers_visible(in_run)
	if not in_run:
		return

	# --- recorder stamp, once a second ---
	_rec_accum += delta
	if _rec_accum >= 1.0 and rec_label.visible:
		_rec_accum = 0.0
		var sec: int = int(Time.get_ticks_msec() / 1000.0)
		var blink := "●" if (sec % 2 == 0) else "  "
		rec_label.text = "REC %s  2026-11-24 23:%02d:%02d\nBODYCAM-04 // UNIT-K9%s" % [blink, (41 + int(sec / 60.0)) % 60, sec % 60, "  [GOD]" if player.god_mode else ""]

	# --- snapshot ---
	var cw := player.current_weapon
	var wd: Dictionary = PlayerBodycam.WEAPONS[cw]
	_is_melee = bool(wd.get("is_melee", false))
	_mag = player.ammo_in_mag[cw]
	_reserve = player.ammo_reserve[cw]
	_mag_size = maxi(1, player.get_weapon_mag_size(cw))
	_reloading = player.is_reloading
	_reload_frac = clampf(player.reload_elapsed / maxf(player.reload_dur, 0.05), 0.0, 1.0) if _reloading else 0.0
	_hp = player.health
	_hp_max = player.max_health
	if _hp_ghost < _hp:
		_hp_ghost = _hp
	else:
		_hp_ghost = maxf(_hp, _hp_ghost - delta * 42.0)
	_regen = player.regen_delay <= 0.0 and _hp < _hp_max and not player.dead
	_slowed = player.slow_timer > 0.0
	_wave = wave
	_points = points
	_points_shown = move_toward(_points_shown, float(points), maxf(absf(float(points) - _points_shown) * delta * 6.0, delta * 120.0))
	_hostiles = zombies_left
	_wave_total = int(ctx.get("wave_total", 0))
	_intermission = float(ctx.get("intermission", -1.0))
	_objective = str(ctx.get("objective", ""))
	_god = player.god_mode
	_perk_tags = player.get_perk_tags()
	_ads = player._ads_blend
	_sprint = player._sprint_blend
	_scope = sa
	_shotgun = (cw == 2 or cw == 9 or cw == 11)
	_melee_charge = player._melee_charge if player._melee_charging else 0.0
	_grab = player.grab_struggle if player.grabbed_by != null else -1.0
	_cam_xf = player.camera.global_transform
	_heading = fposmod(-rad_to_deg(player.yaw), 360.0)
	if ctx.has("objective_pos"):
		var op: Vector3 = ctx["objective_pos"]
		var to := op - player.global_position
		_obj_dist = Vector2(to.x, to.z).length()
		_obj_bearing = fposmod(rad_to_deg(atan2(to.x, -to.z)), 360.0)
	else:
		_obj_bearing = INF

	var vp_h := maxf(_reticle.size.y, 1.0)
	var spread := player.get_spread_now()
	_spread_px = clampf(spread / tan(deg_to_rad(player.camera.fov) * 0.5) * (vp_h * 0.5) * 1.42, 4.0, 90.0)

	_focus_tick = (_focus_tick + 1) % 4
	if _is_melee:
		if _focus_tick == 0:
			_melee_focus = player.get_melee_focus()
	else:
		_melee_focus = false

	if player.last_damage_time != _last_dmg_time:
		_last_dmg_time = player.last_damage_time
		if player.last_damage_dir != Vector3.ZERO:
			_dmg_arcs.push_front({"pos": player.last_damage_dir, "t": 0.0})
			while _dmg_arcs.size() > 4:
				_dmg_arcs.pop_back()
	for a in _dmg_arcs:
		a["t"] = float(a["t"]) + delta
	while not _dmg_arcs.is_empty() and float(_dmg_arcs[_dmg_arcs.size() - 1]["t"]) > 1.6:
		_dmg_arcs.pop_back()
	for pp in _popups:
		pp["age"] = float(pp["age"]) + delta
	while not _popups.is_empty() and float(_popups[_popups.size() - 1]["age"]) > 1.5:
		_popups.pop_back()

	# Interaction prompt (every frame, never throttled)
	var obj := player.get_looked_interactable()
	_prompt = obj.get_prompt(points, player) if obj else ""
	_prompt_detail = obj.get_prompt_detail(player) if (obj and obj.has_method("get_prompt_detail")) else ""
	prompt_label.text = _prompt

	# Weapon block text
	if _is_melee:
		var md: Dictionary = PlayerBodycam.MELEE_CATALOG.get(player.equipped_melee_id, PlayerBodycam.MELEE_CATALOG["knife"])
		_w_name = str(md["name"])
		_melee_trait = str(md.get("trait", ""))
		_w_mode = "MELEE"
		_w_tags = ""
	else:
		_w_name = str(wd["name"])
		_w_mode = player.get_fire_mode_label(cw)
		var tags: Array[String] = []
		if player.is_weapon_upgraded(cw): tags.append("MK-II")
		if player.has_attachment(cw, "optic"): tags.append("RDS")
		if player.has_attachment(cw, "suppressor"): tags.append("SD")
		if player.has_attachment(cw, "ext_mag") and not player.is_weapon_upgraded(cw): tags.append("EXT")
		_w_tags = " ".join(tags)
	_gren_label = str(PlayerBodycam.GRENADE_LABELS.get(player.equipped_grenade, "FRAG"))
	_gren_count = int(player.grenade_counts.get(player.equipped_grenade, 0))
	_melee_label = "SPIKED BAT" if player.equipped_melee_id == "bat_spiked" else (str(PlayerBodycam.MELEE_CATALOG[player.equipped_melee_id]["name"]).split(" ")[-1] if (player.equipped_melee_id != "" and PlayerBodycam.MELEE_CATALOG.has(player.equipped_melee_id)) else "GUN BASH")

	_slots.clear()
	for i in range(PlayerBodycam.MAX_FIREARM_SLOTS):
		if i < player.firearm_slots.size():
			var wi := player.firearm_slots[i]
			_slots.append([str(i + 1), player._weapon_short_label(wi), wi == cw, false])
		else:
			_slots.append([str(i + 1), "", false, true])
	if player.special_slot >= 0:
		_slots.append(["4", player._weapon_short_label(player.special_slot), player.special_slot == cw, false])
	if player.equipped_melee_id != "":
		_slots.append(["5", _melee_label.split(" ")[-1], cw == 3, false])

	# Redraw the static panels only when something they show has changed (or while a bar is animating)
	var sig := cw * 7919 + _mag * 131 + _reserve * 17 + int(_hp) * 3 + int(_hp_ghost) + wave * 1009 + int(_points_shown) * 5 + zombies_left * 53 + _wave_total * 11
	sig += (1 if _reloading else 0) * 97 + (1 if _regen else 0) * 89 + (1 if _slowed else 0) * 83 + _gren_count * 71 + hash(_objective) % 9973 + hash(_w_name + _w_tags + _gren_label + _melee_label) % 7907
	sig += _perk_tags.size() * 1999 + int(_hp_max)
	sig += int(_heading * 0.5) * 3 + int(_obj_dist) + (int(_intermission * 4.0) if _intermission >= 0.0 else -1) * 13 + _slots.size() * 5 + (1 if _god else 0)
	if sig != _sig:
		_sig = sig
		_panels.queue_redraw()
	_reticle.queue_redraw()

	var banner_active := _banner_age < _banner_dur
	if banner_active:
		_banner_age += delta
	var any_toast := false
	for t in _toasts:
		t["age"] = float(t["age"]) + delta
		any_toast = true
	while not _toasts.is_empty() and float(_toasts[_toasts.size() - 1]["age"]) > float(_toasts[_toasts.size() - 1]["dur"]):
		_toasts.pop_back()
	if banner_active or any_toast:
		_banners.queue_redraw()

	stats_label.text = "[%s] %s  %s  •  HP %d%%  •  PTS %d  •  HOSTILES %d" % [
		player.get_slot_key_for_weapon(cw), _w_name, "MELEE" if _is_melee else ("%02d / %03d" % [_mag, _reserve]), int(_hp), points, zombies_left
	]


# ---------------------------------------------------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------------------------------------------------

func _txt(ci: CanvasItem, font: Font, pos: Vector2, text: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	ci.draw_string(font, pos + Vector2(1.0, 1.0), text, align, width, size, Color(0.0, 0.0, 0.0, col.a * 0.82))
	ci.draw_string(font, pos, text, align, width, size, col)


func _tw(font: Font, text: String, size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x


func _keycap(ci: CanvasItem, pos: Vector2, key: String, size := 12, col := COL_AMBER) -> float:
	# Draws a key legend box with its left-middle at pos; returns the width used
	var w := maxf(_tw(_font_b, key, size) + 10.0, 20.0)
	var r := Rect2(pos.x, pos.y - 10.0, w, 20.0)
	ci.draw_rect(r, Color(0.02, 0.025, 0.03, 0.78), true)
	ci.draw_rect(r, Color(col.r, col.g, col.b, 0.85), false, 1.0)
	_txt(ci, _font_b, Vector2(pos.x, pos.y + float(size) * 0.36), key, size, col, HORIZONTAL_ALIGNMENT_CENTER, w)
	return w


func _draw_panels(ci: CanvasItem) -> void:
	var sz := _panels.size
	var w := sz.x
	var h := sz.y
	var a := 0.92

	# ---- Top-left: wave, hostiles, points, objective ----
	var x0 := MARGIN
	_txt(ci, _font_b, Vector2(x0, 42.0), "WAVE", 12, Color(COL_DIM, a))
	_txt(ci, _font_c, Vector2(x0 + 46.0, 46.0), "%02d" % _wave, 30, Color(COL_TEXT, a))
	var hx := x0 + 104.0
	if _intermission >= 0.0:
		_txt(ci, _font_b, Vector2(hx, 30.0), "NEXT WAVE IN", 11, Color(COL_GREEN, a))
		_txt(ci, _font_c, Vector2(hx, 47.0), "%0.1fs" % _intermission, 16, Color(COL_GREEN, a))
	else:
		_txt(ci, _font_b, Vector2(hx, 30.0), "HOSTILES", 11, Color(COL_DIM, a))
		_txt(ci, _font_c, Vector2(hx + 66.0, 31.0), str(_hostiles), 14, Color(COL_RED if _hostiles > 0 else COL_GREEN, a))
		var bar_w := 118.0
		ci.draw_rect(Rect2(hx, 38.0, bar_w, 3.0), Color(0.0, 0.0, 0.0, 0.55), true)
		if _wave_total > 0:
			var done := clampf(1.0 - float(_hostiles) / float(_wave_total), 0.0, 1.0)
			ci.draw_rect(Rect2(hx, 38.0, bar_w * done, 3.0), Color(COL_RED, 0.85), true)
	var pts_s := str(int(round(_points_shown)))
	_txt(ci, _font_c, Vector2(x0, 76.0), pts_s, 22, Color(COL_AMBER, a))
	_txt(ci, _font_b, Vector2(x0 + _tw(_font_c, pts_s, 22) + 6.0, 75.0), "PTS", 11, Color(COL_AMBER, 0.75))
	if _objective != "":
		ci.draw_rect(Rect2(x0, 87.0, 2.0, 15.0), Color(COL_AMBER, 0.9), true)
		_txt(ci, _font, Vector2(x0 + 9.0, 99.0), _objective, 12, Color(COL_TEXT, 0.86))

	# ---- Top-centre: compass strip with objective marker ----
	var cx := w * 0.5
	var strip_w := 300.0
	var px_per_deg := strip_w / 120.0
	var cy := 26.0
	ci.draw_line(Vector2(cx - strip_w * 0.5, cy + 8.0), Vector2(cx + strip_w * 0.5, cy + 8.0), Color(1, 1, 1, 0.16), 1.0)
	var start_deg := int(floor((_heading - 60.0) / 15.0)) * 15
	for d in range(start_deg, start_deg + 136, 15):
		var off := angle_difference(deg_to_rad(_heading), deg_to_rad(float(d)))
		var dx := rad_to_deg(off) * px_per_deg
		if absf(dx) > strip_w * 0.5:
			continue
		var fade := clampf(1.0 - absf(dx) / (strip_w * 0.5), 0.0, 1.0)
		var dn := posmod(d, 360)
		if dn % 90 == 0:
			var letter: String = ["N", "E", "S", "W"][int(dn / 90.0)]
			_txt(ci, _font_b, Vector2(cx + dx - 20.0, cy + 2.0), letter, 12, Color(COL_TEXT, 0.85 * fade), HORIZONTAL_ALIGNMENT_CENTER, 40.0)
			ci.draw_line(Vector2(cx + dx, cy + 4.0), Vector2(cx + dx, cy + 12.0), Color(1, 1, 1, 0.6 * fade), 1.5)
		else:
			ci.draw_line(Vector2(cx + dx, cy + 6.0), Vector2(cx + dx, cy + 10.0), Color(1, 1, 1, 0.34 * fade), 1.0)
	ci.draw_line(Vector2(cx, cy + 12.0), Vector2(cx, cy + 16.0), Color(COL_TEXT, 0.8), 1.5)
	if _obj_bearing != INF:
		var ooff := rad_to_deg(angle_difference(deg_to_rad(_heading), deg_to_rad(_obj_bearing)))
		var odx := clampf(ooff * px_per_deg, -strip_w * 0.5, strip_w * 0.5)
		var mp := Vector2(cx + odx, cy + 8.0)
		ci.draw_colored_polygon(PackedVector2Array([mp + Vector2(0, -6), mp + Vector2(5, 0), mp + Vector2(0, 6), mp + Vector2(-5, 0)]), Color(COL_AMBER, 0.95))
		_txt(ci, _font_b, Vector2(mp.x - 30.0, cy + 30.0), "%dm" % int(_obj_dist), 10, Color(COL_AMBER, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 60.0)

	# ---- Bottom-left: vitals and carried equipment ----
	var by := h - MARGIN
	var hp_frac := clampf(_hp / maxf(_hp_max, 1.0), 0.0, 1.0)
	var ghost_frac := clampf(_hp_ghost / maxf(_hp_max, 1.0), 0.0, 1.0)
	var hp_col := COL_TEXT if hp_frac > 0.5 else (COL_AMBER if hp_frac > 0.25 else COL_RED)
	_txt(ci, _font_c, Vector2(x0, by - 4.0), "%d" % int(ceil(_hp)), 34, Color(hp_col, a))
	var bx := x0 + 74.0
	var bw := 190.0
	var bar_y := by - 22.0
	ci.draw_rect(Rect2(bx, bar_y, bw, 7.0), Color(0.0, 0.0, 0.0, 0.58), true)
	ci.draw_rect(Rect2(bx, bar_y, bw * ghost_frac, 7.0), Color(0.80, 0.14, 0.10, 0.75), true)
	ci.draw_rect(Rect2(bx, bar_y, bw * hp_frac, 7.0), Color(hp_col, 0.92), true)
	for k in range(1, 4):
		ci.draw_rect(Rect2(bx + bw * 0.25 * float(k) - 0.5, bar_y, 1.0, 7.0), Color(0.0, 0.0, 0.0, 0.7), true)
	var status := "VITALS"
	var st_col := Color(COL_DIM, a)
	if _slowed:
		status = "ACID BURN — SLOWED"
		st_col = Color(0.66, 0.86, 0.22, a)
	elif _regen:
		status = "RECOVERING"
		st_col = Color(COL_GREEN, a)
	elif hp_frac <= 0.25:
		status = "CRITICAL — BREAK CONTACT"
		st_col = Color(COL_RED, a)
	_txt(ci, _font_b, Vector2(bx, bar_y - 6.0), status, 10, st_col)
	if _god:
		_txt(ci, _font_b, Vector2(bx + bw - 90.0, bar_y - 6.0), "GOD MODE", 10, Color(COL_AMBER, a), HORIZONTAL_ALIGNMENT_RIGHT, 90.0)
	# equipment row
	var ex := x0
	var ey := by - 58.0
	ex += _keycap(ci, Vector2(ex, ey), "G", 11) + 6.0
	var gtxt := "%s  ×%d" % [_gren_label, _gren_count]
	_txt(ci, _font_b, Vector2(ex, ey + 4.0), gtxt, 12, Color(COL_TEXT if _gren_count > 0 else COL_DIM, a))
	ex += _tw(_font_b, gtxt, 12) + 16.0
	ex += _keycap(ci, Vector2(ex, ey), "V", 11) + 6.0
	_txt(ci, _font_b, Vector2(ex, ey + 4.0), "SHOVE" if _is_melee else _melee_label, 12, Color(COL_TEXT, a))
	# active perks
	var pkx := x0
	for tag in _perk_tags:
		var tw_p := _tw(_font_b, tag, 10) + 12.0
		var pr := Rect2(pkx, ey - 34.0, tw_p, 16.0)
		ci.draw_rect(pr, Color(0.10, 0.22, 0.14, 0.72), true)
		ci.draw_rect(pr, Color(COL_GREEN, 0.8), false, 1.0)
		_txt(ci, _font_b, Vector2(pkx, ey - 22.0), tag, 10, Color(COL_GREEN, a), HORIZONTAL_ALIGNMENT_CENTER, tw_p)
		pkx += tw_p + 5.0

	# ---- Bottom-right: weapon, ammunition, slots ----
	var rx := w - MARGIN
	if _is_melee:
		_txt(ci, _font_c, Vector2(rx - 420.0, by - 4.0), _w_name, 28, Color(COL_TEXT, a), HORIZONTAL_ALIGNMENT_RIGHT, 420.0)
		_txt(ci, _font_b, Vector2(rx - 420.0, by - 36.0), _melee_trait, 11, Color(COL_AMBER, a), HORIZONTAL_ALIGNMENT_RIGHT, 420.0)
	else:
		var res_s := "/ %03d" % _reserve
		var res_w := _tw(_font_c, res_s, 18)
		var low := float(_mag) <= float(_mag_size) * 0.25
		var mag_col := COL_RED if _mag <= 0 else (COL_AMBER if low else COL_TEXT)
		_txt(ci, _font_c, Vector2(rx - res_w, by - 6.0), res_s, 18, Color(COL_DIM if _reserve > 0 else COL_RED, a))
		_txt(ci, _font_c, Vector2(rx - res_w - 8.0 - 160.0, by - 4.0), "%02d" % _mag, 44, Color(mag_col, a), HORIZONTAL_ALIGNMENT_RIGHT, 160.0)
		var nm := _w_name + (("  " + _w_tags) if _w_tags != "" else "")
		_txt(ci, _font_b, Vector2(rx - 420.0, by - 48.0), nm, 12, Color(COL_TEXT, a), HORIZONTAL_ALIGNMENT_RIGHT, 420.0)
		var mode_w := _tw(_font_b, _w_mode, 10) + 10.0
		var nm_w := _tw(_font_b, nm, 12)
		var mr := Rect2(rx - nm_w - mode_w - 8.0, by - 60.0, mode_w, 15.0)
		ci.draw_rect(mr, Color(0.0, 0.0, 0.0, 0.5), true)
		ci.draw_rect(mr, Color(COL_DIM, 0.7), false, 1.0)
		_txt(ci, _font_b, Vector2(mr.position.x, by - 49.0), _w_mode, 10, Color(COL_DIM, a), HORIZONTAL_ALIGNMENT_CENTER, mode_w)
		# magazine pips: one cell per round up to 30, then proportional
		var cells := mini(_mag_size, 30)
		var cell_w := 4.0 if cells > 15 else 6.0
		var px0 := rx - float(cells) * (cell_w + 1.0)
		var filled := int(ceil(float(_mag) / float(_mag_size) * float(cells)))
		for c in range(cells):
			ci.draw_rect(Rect2(px0 + float(c) * (cell_w + 1.0), by - 74.0, cell_w, 5.0), Color(mag_col, 0.9) if c < filled else Color(0.0, 0.0, 0.0, 0.55), true)
	# slot chips
	var sx := rx
	var sy := by - (64.0 if _is_melee else 100.0)
	for i in range(_slots.size() - 1, -1, -1):
		var s: Array = _slots[i]
		var label := str(s[1]) if not bool(s[3]) else "—"
		var cw := _tw(_font_b, label, 11) + 30.0
		var r := Rect2(sx - cw, sy - 10.0, cw, 20.0)
		var active := bool(s[2])
		ci.draw_rect(r, Color(0.86, 0.66, 0.28, 0.24) if active else Color(0.0, 0.0, 0.0, 0.46), true)
		ci.draw_rect(r, Color(COL_AMBER, 0.95) if active else Color(1, 1, 1, 0.16), false, 1.0)
		_txt(ci, _font_b, Vector2(r.position.x + 6.0, sy + 4.0), str(s[0]), 11, Color(COL_AMBER, 0.95) if active else Color(COL_DIM, 0.8))
		_txt(ci, _font_b, Vector2(r.position.x + 20.0, sy + 4.0), label, 11, Color(COL_TEXT, a) if not bool(s[3]) else Color(COL_DIM, 0.5))
		sx -= cw + 4.0


func _draw_reticle(ci: CanvasItem) -> void:
	var sz := _reticle.size
	var c := sz * 0.5
	var t_now := Time.get_ticks_msec() * 0.001

	# ---- Crosshair ----
	if show_crosshair and _scope < 0.05:
		var alpha := (1.0 - _ads) * lerpf(1.0, 0.35, _sprint) * (0.45 if _reloading else 0.8)
		if alpha > 0.02:
			var sh := Color(0.0, 0.0, 0.0, alpha * 0.6)
			var wc := Color(0.96, 0.96, 0.92, alpha)
			if _is_melee:
				var fc := Color(COL_AMBER, 0.95) if _melee_focus else wc
				ci.draw_circle(c, 2.6, sh)
				ci.draw_circle(c, 1.6, fc)
				if _melee_focus:
					# Brackets close in when a swing will connect
					for sgn: float in [-1.0, 1.0]:
						ci.draw_arc(c, 13.0, (PI if sgn < 0.0 else 0.0) - 0.62, (PI if sgn < 0.0 else 0.0) + 0.62, 10, fc, 1.6, true)
			elif _shotgun:
				ci.draw_arc(c, _spread_px, 0.0, TAU, 40, sh, 2.6, true)
				ci.draw_arc(c, _spread_px, 0.0, TAU, 40, Color(wc, alpha * 0.7), 1.2, true)
				ci.draw_circle(c, 1.4, wc)
			else:
				var g := _spread_px
				for dir: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
					ci.draw_line(c + dir * g, c + dir * (g + 7.0), sh, 3.2)
					ci.draw_line(c + dir * g, c + dir * (g + 7.0), wc, 1.4)
				ci.draw_circle(c, 1.2, wc)

	# ---- Reload progress ring ----
	if _reloading:
		ci.draw_arc(c, 24.0, -PI * 0.5, -PI * 0.5 + TAU, 48, Color(0, 0, 0, 0.35), 3.0, true)
		ci.draw_arc(c, 24.0, -PI * 0.5, -PI * 0.5 + TAU * _reload_frac, 48, Color(COL_TEXT, 0.9), 2.0, true)
	# ---- Heavy melee charge ring ----
	if _melee_charge > 0.01:
		var full := _melee_charge >= 1.0
		var cc := Color(1.0, 1.0, 0.92, 0.95) if (full and fmod(t_now, 0.16) < 0.08) else Color(COL_AMBER, 0.95)
		ci.draw_arc(c, 20.0, -PI * 0.5, -PI * 0.5 + TAU, 40, Color(0, 0, 0, 0.35), 4.0, true)
		ci.draw_arc(c, 20.0, -PI * 0.5, -PI * 0.5 + TAU * _melee_charge, 40, cc, 2.6, true)

	# ---- Incoming damage direction ----
	for arc in _dmg_arcs:
		var loc := _cam_xf.basis.inverse() * ((arc["pos"] as Vector3) - _cam_xf.origin)
		var ang := atan2(loc.x, -loc.z) - PI * 0.5
		var fade := clampf(1.0 - float(arc["t"]) / 1.6, 0.0, 1.0)
		var rad := 96.0 + (1.0 - fade) * 10.0
		ci.draw_arc(c, rad, ang - 0.30, ang + 0.30, 16, Color(0.0, 0.0, 0.0, 0.5 * fade), 9.0, true)
		ci.draw_arc(c, rad, ang - 0.28, ang + 0.28, 16, Color(0.98, 0.20, 0.14, 0.92 * fade), 5.0, true)

	# ---- Score popups ----
	var py := c.y + 24.0
	for i in range(_popups.size()):
		var pp: Dictionary = _popups[i]
		var age := float(pp["age"])
		var al := clampf(1.0 - (age - 0.9) / 0.6, 0.0, 1.0) * clampf(age / 0.06, 0.0, 1.0)
		var rise := (1.0 - exp(-age * 7.0)) * 12.0
		var pc: Color = pp["col"]
		_txt(ci, _font_b, Vector2(c.x + 44.0, py + float(i) * 17.0 - rise), str(pp["text"]), 13, Color(pc, al))

	# ---- Contextual hints under the crosshair ----
	var hint := ""
	var hint_col := COL_AMBER
	if _grab >= 0.0:
		var gw := 190.0
		var gy := c.y + 64.0
		_txt(ci, _font_b, Vector2(c.x - 200.0, gy), "GRABBED — MASH", 15, Color(COL_RED, 0.95 if fmod(t_now, 0.3) < 0.2 else 0.7), HORIZONTAL_ALIGNMENT_RIGHT, 284.0)
		_keycap(ci, Vector2(c.x + 92.0, gy - 5.0), "V", 13, COL_RED)
		ci.draw_rect(Rect2(c.x - gw * 0.5, gy + 12.0, gw, 6.0), Color(0, 0, 0, 0.6), true)
		ci.draw_rect(Rect2(c.x - gw * 0.5, gy + 12.0, gw * clampf(_grab, 0.0, 1.0), 6.0), Color(COL_RED, 0.95), true)
	elif not _is_melee and not _reloading:
		if _mag <= 0 and _reserve > 0:
			hint = "RELOAD"
		elif _mag <= 0 and _reserve <= 0:
			hint = "NO AMMO"
			hint_col = COL_RED
		elif float(_mag) <= float(_mag_size) * 0.25 and _mag_size > 2:
			hint = "LOW AMMO"
	if hint != "":
		var hy := c.y + 58.0
		var blink := 0.95 if (hint == "LOW AMMO" or fmod(t_now, 0.7) < 0.5) else 0.5
		var hw := _tw(_font_b, hint, 13)
		if hint == "RELOAD":
			var kc := _keycap(ci, Vector2(c.x - (hw + 30.0) * 0.5, hy - 5.0), "R", 12)
			_txt(ci, _font_b, Vector2(c.x - (hw + 30.0) * 0.5 + kc + 8.0, hy), hint, 13, Color(hint_col, blink))
		else:
			_txt(ci, _font_b, Vector2(c.x - hw * 0.5, hy), hint, 13, Color(hint_col, blink * (0.7 if hint == "LOW AMMO" else 1.0)))

	# ---- Interaction prompt ----
	if _prompt != "" and _grab < 0.0:
		var txt := _prompt
		var has_key := txt.begins_with("[E] ")
		if has_key:
			txt = txt.substr(4)
		var locked := txt.contains("NEEDED") or txt.contains("FIRST]")
		var price := ""
		var pa := txt.rfind("(")
		if pa > 0 and txt.ends_with(")") and txt.contains("PTS"):
			price = txt.substr(pa + 1, txt.length() - pa - 2).replace(" NEEDED", "")
			txt = txt.substr(0, pa).strip_edges()
		var main_w := _tw(_font_b, txt, 15)
		var price_w := (_tw(_font_c, price, 15) + 22.0) if price != "" else 0.0
		var key_w := 30.0 if has_key else 0.0
		var total := key_w + main_w + price_w + 28.0
		var y := c.y + 104.0
		var r := Rect2(c.x - total * 0.5, y - 17.0, total, 34.0)
		ci.draw_rect(r, Color(0.02, 0.025, 0.03, 0.72), true)
		ci.draw_rect(Rect2(r.position.x, r.position.y, 2.0, r.size.y), Color(COL_RED if locked else COL_AMBER, 0.95), true)
		var tx := r.position.x + 14.0
		if has_key:
			_keycap(ci, Vector2(tx, y), "E", 13, COL_DIM if locked else COL_AMBER)
			tx += key_w
		_txt(ci, _font_b, Vector2(tx, y + 5.0), txt, 15, Color(COL_TEXT, 0.72 if locked else 0.96))
		if price != "":
			_txt(ci, _font_c, Vector2(tx + main_w + 14.0, y + 5.0), price, 15, Color(COL_RED if locked else COL_AMBER, 0.98))
		if _prompt_detail != "":
			var dw := _tw(_font, _prompt_detail, 11) + 24.0
			ci.draw_rect(Rect2(c.x - dw * 0.5, y + 20.0, dw, 20.0), Color(0.02, 0.025, 0.03, 0.62), true)
			_txt(ci, _font, Vector2(c.x - 300.0, y + 34.0), _prompt_detail, 11, Color(0.80, 0.84, 0.82, 0.98), HORIZONTAL_ALIGNMENT_CENTER, 600.0)


func _draw_banners(ci: CanvasItem) -> void:
	var sz := _banners.size
	var cx := sz.x * 0.5
	# ---- Toast stack under the compass ----
	var ty := 78.0
	for t in _toasts:
		var age := float(t["age"])
		var dur := float(t["dur"])
		var al := clampf(age / 0.15, 0.0, 1.0) * clampf((dur - age) / 0.5, 0.0, 1.0)
		var txt := str(t["text"])
		var tw := _tw(_font_b, txt, 13)
		var r := Rect2(cx - tw * 0.5 - 14.0, ty - 15.0, tw + 28.0, 22.0)
		ci.draw_rect(r, Color(0.02, 0.025, 0.03, 0.62 * al), true)
		ci.draw_rect(Rect2(r.position.x, r.position.y, 2.0, r.size.y), Color(COL_AMBER, 0.9 * al), true)
		_txt(ci, _font_b, Vector2(cx - tw * 0.5, ty), txt, 13, Color(0.96, 0.90, 0.74, al))
		ty += 26.0
	# ---- Wave banner ----
	if _banner_age < _banner_dur and _banner_title != "":
		var u := _banner_age / _banner_dur
		var al2 := clampf(_banner_age / 0.25, 0.0, 1.0) * clampf((_banner_dur - _banner_age) / 0.7, 0.0, 1.0)
		var by := sz.y * 0.27
		var spread := lerpf(0.0, 1.0, 1.0 - exp(-_banner_age * 6.0))
		var tw2 := _tw(_font_b, _banner_title, 46)
		var line_w := (tw2 * 0.5 + 60.0) * spread
		ci.draw_line(Vector2(cx - line_w, by - 46.0), Vector2(cx + line_w, by - 46.0), Color(_banner_col, 0.55 * al2), 1.0)
		ci.draw_line(Vector2(cx - line_w, by + 14.0), Vector2(cx + line_w, by + 14.0), Color(_banner_col, 0.55 * al2), 1.0)
		_txt(ci, _font_b, Vector2(cx - 500.0, by), _banner_title, 46, Color(_banner_col, al2), HORIZONTAL_ALIGNMENT_CENTER, 1000.0)
		if _banner_sub != "":
			_txt(ci, _font_b, Vector2(cx - 500.0, by + 38.0), _banner_sub, 14, Color(COL_TEXT, al2 * (0.6 + 0.4 * u)), HORIZONTAL_ALIGNMENT_CENTER, 1000.0)
