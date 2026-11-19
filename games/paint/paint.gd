extends Node3D
## Symulator schnięcia farby: pokój z 4 ścianami. Gracz sam maluje wałkiem, potem czeka w czasie rzeczywistym.
## Zapis (sekcja „paint”): wall, last_seen, dried, ruined, waited, loads_watched oraz per ściana w<i>_*:
## state, paint_id, color, start_unix, dried_at, touch_x/y, cheated, coverage.
## Grubość farby na ścianie: user://paint_wall_<i>.bin (PaintMask).

const COLORS := [
	["NRGeek czerwony", Color(0.78, 0.05, 0.09)],
	["Biel PRL-owska", Color(0.9, 0.88, 0.8)],
	["Zieleń szpitalna", Color(0.55, 0.74, 0.6)],
	["Błękit klatki schodowej", Color(0.42, 0.58, 0.8)],
]
const WALL := Vector2(5.2, 2.6)      # szerokość × wysokość ściany [m]; środek dołu ściany = (0, 0, 0)
const ROLLER_W := 0.36               # szerokość wałka [m]
const ROLL_M := 7.0                  # na tyle metrów ściany starcza jedno nabranie farby
const COAT := 0.75                   # ile warstwy zostawia jedno przejście pełnym wałkiem
const TRAY := Vector3(0.45, 0.0, 1.0)
## Rekwizyt każdej ściany: środek (x od środka ściany, y od podłogi) i rozmiar [m]. Farby pod nim nie widać.
const WALL_PROPS := [
	{"prop": "window", "pos": Vector2(1.35, 1.55), "dim": Vector2(1.5, 1.4)},
	{"prop": "door", "pos": Vector2(1.7, 1.05), "dim": Vector2(1.0, 2.1)},
	{"prop": "radiator", "pos": Vector2(0.0, 0.47), "dim": Vector2(1.2, 0.62)},
	{},
]
const MESSAGES := [
	"Farba schnie.",
	"Nic się nie dzieje. Tak ma być.",
	"Nie dotykaj. Wiemy, że chcesz.",
	"Gdzieś na świecie ktoś właśnie ogląda trawę, jak rośnie. Słabiak.",
	"Czy wiesz, że farba schnie szybciej, gdy na nią nie patrzysz? (Nieprawda).",
	"Rozpuszczalnik paruje z prędkością dokładnie jednego rozpuszczalnika na sekundę.",
	"To jest gra. Naprawdę. Sprawdź tytuł.",
	"Możesz wyłączyć grę. Farba będzie schnąć dalej.",
	"Sąsiad z góry właśnie zaczął wiercić. Farba nie zwraca na to uwagi.",
	"Jeszcze trochę. Albo dużo. Zależy od farby.",
	"Ten sam poziom napięcia co w finale wyścigów kredensów.",
	"Farba wysycha od krawędzi. Krawędzie są już prawie suche. Prawie.",
	"Są jeszcze trzy inne ściany. Q i E. Tylko uprzedzamy: ładuje się długo.",
]

var wall_i := 0
var state := "choose"
var paint_id := "acrylic"
var color_i := 0
var mask := PaintMask.new()
var mask_tex: ImageTexture
var wall_mat: ShaderMaterial
var roller: Node3D
var tray: Node3D
var can: Node3D
var props: Node3D
var cam: Camera3D
var loading: PaintLoading

var roller_half := Vector2(ROLLER_W / 2.0 / WALL.x, 0.03 / WALL.y)   # odcisk wałka w UV
var roller_pos := Vector2(0.0, 1.3)   # punkt styku wałka na ścianie [m]
var ink := 1.0                       # farba na wałku 0..1
var rolling := false                  # LPM wciśnięty
var _was_rolling := false
var dipping := false
var switching := false
var msg_t := 0.0
var msg_i := 0
var _roll_snd := 0.0
var _tick_t := 0.0
var _seen_t := 0.0
var _stare_t := 0.0
var _first_tick := true
var _last_clock := 0.0
var _last_mono := 0.0
var _mouse := Vector2.ZERO            # ostatnia pozycja kursora (ze zdarzeń, więc działa też z wejściem wstrzykniętym w testach)

var choose_ui: Control
var status_ui: Control
var clock_card: Control
var title_lbl: Label
var timer_lbl: Label
var bar: ProgressBar
var sub_lbl: Label
var msg_lbl: Label
var stats_lbl: Label
var walls_lbl: Label
var choose_head: Label
var touch_btn: Button
var again_btn: Button
var finish_btn: Button
var note_lbl: Label
var _go_btn: Button
var _paint_btns := {}     # id farby -> Button


func _ready() -> void:
	_migrate()
	wall_i = int(Collection.args.get("wall", Collection.get_val("paint", "wall", 0)))   # --wall=N do zrzutów
	_mouse = get_viewport().get_mouse_position()
	_build_world()
	_build_ui()
	_last_clock = Time.get_unix_time_from_system()
	_last_mono = Time.get_ticks_msec() / 1000.0
	_load_wall()
	var shot: String = Collection.args.get("shot", "")
	if shot.begins_with("paint"):
		_shot_setup(shot)
	_tick()


## Stary zapis (jedna ściana, płaskie klucze) → ściana 0.
func _migrate() -> void:
	if not Collection.save.has_section_key("paint", "state"):
		return
	for k in ["state", "paint_id", "color", "start_unix", "touch_x", "touch_y"]:
		if Collection.save.has_section_key("paint", k):
			Collection.save.set_value("paint", PaintTime.key(0, k), Collection.get_val("paint", k))
			Collection.save.erase_section_key("paint", k)
	Collection.set_val("paint", "wall", 0)     # zapisuje plik już bez starych kluczy


func _wget(k: String, default: Variant = null, wall := -1) -> Variant:
	return Collection.get_val("paint", PaintTime.key(wall_i if wall < 0 else wall, k), default)


func _wset(k: String, v: Variant, wall := -1) -> void:
	Collection.set_val("paint", PaintTime.key(wall_i if wall < 0 else wall, k), v)


func _mask_path() -> String:
	return "user://paint_wall_%d.bin" % wall_i


func _save_mask() -> void:
	if Collection.args.has("shot"):
		return
	var f := FileAccess.open(_mask_path(), FileAccess.WRITE)
	if f:
		f.store_buffer(mask.data.to_byte_array())


func _upload_mask() -> void:
	if mask_tex == null:
		mask_tex = ImageTexture.create_from_image(mask.to_image())
		wall_mat.set_shader_parameter("mask", mask_tex)
	else:
		mask_tex.update(mask.to_image())


## Czysta maska dla bieżącej ściany (z miejscem zasłoniętym przez rekwizyt).
func _new_mask() -> void:
	mask = PaintMask.new()
	_block_prop()


func _block_prop() -> void:
	var wp: Dictionary = WALL_PROPS[wall_i]
	if wp.is_empty():
		return
	var pos: Vector2 = wp.pos
	var size: Vector2 = wp.dim
	mask.block(Rect2((pos.x - size.x / 2 + WALL.x / 2) / WALL.x, 1.0 - (pos.y + size.y / 2) / WALL.y,
			size.x / WALL.x, size.y / WALL.y))


## Wczytuje stan ściany wall_i: farbę, kolor, maskę, rekwizyt, i wchodzi w jej stan.
func _load_wall() -> void:
	state = _wget("state", "choose")
	paint_id = _wget("paint_id", "acrylic")
	color_i = _wget("color", 0)
	mask = PaintMask.new()
	var bytes := PackedByteArray()
	if FileAccess.file_exists(_mask_path()) and not Collection.args.has("shot"):
		bytes = FileAccess.get_file_as_bytes(_mask_path())
	if not mask.load_bytes(bytes) and state in ["drying", "dry", "ruined"]:
		mask.fill(1.0)       # zapis sprzed masek: ściana była pomalowana w całości
	_block_prop()
	_upload_mask()
	for c in props.get_children():
		c.queue_free()
	var wp: Dictionary = WALL_PROPS[wall_i]
	if not wp.is_empty():
		var n := PaintProps.build(wp.prop, wp.dim)
		n.position = Vector3(wp.pos.x, wp.pos.y, 0.0)
		props.add_child(n)
	wall_mat.set_shader_parameter("seed", wall_i * 17.0)
	var tp := Vector2(-1, -1)
	if state == "ruined":
		tp = Vector2(_wget("touch_x", 0.5), _wget("touch_y", 0.5))
	wall_mat.set_shader_parameter("touch_pos", tp)
	_apply_color()
	for id in _paint_btns:
		_paint_btns[id].set_pressed_no_signal(id == paint_id)
	note_lbl.text = PaintTime.find(paint_id).note
	ink = 1.0
	_enter(state)


# ---------- świat ----------

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-25, -38, 0)
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	add_child(sun)
	var lamp := OmniLight3D.new()            # żarówka na kablu: daje pas odblasku na mokrej farbie
	lamp.position = Vector3(-1.4, 2.2, 1.5)
	lamp.light_color = Color(1.0, 0.88, 0.7)
	lamp.light_energy = 0.9
	lamp.omni_range = 7.0
	add_child(lamp)

	var grey := Kredens.mat(Color(0.6, 0.6, 0.58), 0.9)
	PaintProps.box(self, Vector3(WALL.x + 0.4, 0.1, 6), Vector3(0, -0.05, 3.0), Kredens.mat(Color(0.5, 0.48, 0.44), 0.8))   # wylewka
	PaintProps.box(self, Vector3(WALL.x + 0.4, 0.1, 6), Vector3(0, WALL.y + 0.05, 3.0), Kredens.mat(Color(0.82, 0.81, 0.78), 0.9))  # sufit
	for sx in [-1.0, 1.0]:
		PaintProps.box(self, Vector3(0.1, WALL.y, 6), Vector3(sx * (WALL.x / 2 + 0.05), WALL.y / 2, 3.0), grey)
	PaintProps.box(self, Vector3(WALL.x, 0.02, 1.6), Vector3(0, 0.01, 0.8), Kredens.mat(Color(0.85, 0.82, 0.75), 1.0))   # folia malarska

	var wall := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = WALL
	wall.mesh = q
	wall.position = Vector3(0, WALL.y / 2, 0)
	wall_mat = ShaderMaterial.new()
	wall_mat.shader = preload("res://games/paint/paint_wall.gdshader")
	wall_mat.set_shader_parameter("wall_size", WALL)
	wall.material_override = wall_mat
	add_child(wall)
	props = Node3D.new()
	add_child(props)

	tray = PaintProps.tray(Color.WHITE)
	tray.position = TRAY
	add_child(tray)
	can = PaintProps.can(Color.WHITE)
	can.position = TRAY + Vector3(0.55, 0, -0.1)
	add_child(can)
	roller = PaintProps.roller(Color.WHITE, ROLLER_W)
	roller.position = TRAY + Vector3(0, 0.12, 0)
	add_child(roller)

	cam = Camera3D.new()
	cam.fov = 55
	add_child(cam)


func _apply_color() -> void:
	var c: Color = COLORS[color_i][1]
	wall_mat.set_shader_parameter("paint", c)
	(tray.get_child(1) as MeshInstance3D).material_override = Kredens.mat(c, 0.08)
	(can.get_child(1) as MeshInstance3D).material_override = Kredens.mat(c, 0.1)
	(roller.get_child(0) as MeshInstance3D).material_override = Kredens.mat(c.darkened(0.1), 0.35)


# ---------- UI ----------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	Collection.vignette(layer, 0.65)
	choose_ui = PanelContainer.new()
	choose_ui.position = Vector2(40, 40)
	choose_ui.custom_minimum_size = Vector2(560, 0)
	Collection.glass(choose_ui)
	layer.add_child(choose_ui)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	choose_ui.add_child(v)
	var lg := Collection.logo_rect("paint", 420)
	lg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(lg)
	var accent := ColorRect.new()
	accent.color = Collection.RED
	accent.custom_minimum_size = Vector2(64, 3)
	accent.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(accent)
	choose_head = Label.new()
	choose_head.modulate = Color(1, 0.4, 0.45)
	v.add_child(choose_head)
	var group := ButtonGroup.new()
	for p in PaintTime.PAINTS:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s   —   %s" % [p.name, PaintTime.fmt(p.secs)]
		b.pressed.connect(func():
			paint_id = p.id
			note_lbl.text = p.note
			Collection.tone(760, 0.05, 0.15))
		v.add_child(b)
		_paint_btns[p.id] = b
	note_lbl = Label.new()
	note_lbl.add_theme_font_size_override("font_size", 20)
	note_lbl.modulate.a = 0.75
	v.add_child(note_lbl)
	var hc := Label.new()
	hc.text = "Kolor"
	hc.modulate = Color(1, 0.4, 0.45)
	v.add_child(hc)
	var row := HBoxContainer.new()
	v.add_child(row)
	for i in COLORS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(120, 56)
		b.tooltip_text = COLORS[i][0]
		var sb := StyleBoxFlat.new()
		sb.bg_color = COLORS[i][1]
		sb.set_corner_radius_all(8)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.pressed.connect(func():
			color_i = i
			_apply_color()
			Collection.tone(880, 0.05, 0.15))
		row.add_child(b)
	_go_btn = Button.new()
	_go_btn.text = "Maluj!"
	_go_btn.custom_minimum_size = Vector2(0, 64)
	_go_btn.add_theme_font_size_override("font_size", 32)
	_go_btn.pressed.connect(_start_painting)
	v.add_child(_go_btn)

	# Status rozłożony po krawędziach ekranu, żeby środek (ściana z farbą) był wolny.
	status_ui = Control.new()
	status_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	status_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(status_ui)
	var info := _card(Control.PRESET_TOP_LEFT)
	title_lbl = Label.new()
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1, 0.45, 0.5))
	info.add_child(title_lbl)
	sub_lbl = Label.new()
	sub_lbl.add_theme_font_size_override("font_size", 22)
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART      # karta nie wchodzi pod etykietę ściany na środku
	sub_lbl.custom_minimum_size = Vector2(560, 0)
	info.add_child(sub_lbl)
	var clock := _card(Control.PRESET_TOP_RIGHT)
	clock_card = clock.get_parent()
	timer_lbl = Label.new()
	timer_lbl.add_theme_font_size_override("font_size", 76)
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock.add_child(timer_lbl)

	bar = ProgressBar.new()                     # cienki pasek na samym dole ekranu
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -6
	bar.show_percentage = false
	bar.max_value = 1.0
	status_ui.add_child(bar)

	msg_lbl = _shadow_label(26, Control.PRESET_BOTTOM_LEFT, status_ui)
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.custom_minimum_size = Vector2(720, 0)
	msg_lbl.offset_bottom = -64
	msg_lbl.modulate = Color(1, 1, 1, 0.85)
	stats_lbl = _shadow_label(17, Control.PRESET_BOTTOM_LEFT, status_ui)
	stats_lbl.offset_bottom = -26
	stats_lbl.modulate.a = 0.6

	var br := HBoxContainer.new()
	br.add_theme_constant_override("separation", 16)
	br.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 40)
	br.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	br.grow_vertical = Control.GROW_DIRECTION_BEGIN
	br.offset_bottom = -30
	status_ui.add_child(br)
	finish_btn = Button.new()
	finish_btn.text = "Skończ malować"
	finish_btn.focus_mode = Control.FOCUS_NONE     # w trakcie malowania nic nie trzyma fokusu
	finish_btn.pressed.connect(_finish_painting)
	br.add_child(finish_btn)
	touch_btn = Button.new()
	touch_btn.text = "Dotknij farby"
	touch_btn.pressed.connect(_touch)
	br.add_child(touch_btn)
	again_btn = Button.new()
	again_btn.pressed.connect(_restart)
	br.add_child(again_btn)

	# która ściana + podgląd stanu wszystkich czterech (widoczne zawsze)
	walls_lbl = _shadow_label(22, Control.PRESET_CENTER_TOP, layer)
	walls_lbl.grow_vertical = Control.GROW_DIRECTION_END
	walls_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	walls_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hb := Collection.hints(layer, [["lb_rb", "Ściana"], ["grab", "Maluj / dotknij"], ["x", "Nabierz farbę"], ["mode", "Skończ"], ["pause", "Menu"]])
	hb.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 40)
	hb.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hb.position.y += 150
	hb.scale = Vector2(0.85, 0.85)

	var top := CanvasLayer.new()     # ekran ładowania nad całym UI gry
	top.layer = 5
	add_child(top)
	loading = PaintLoading.new()
	top.add_child(loading)


## Mała szklana karta przypięta do rogu ekranu.
func _card(preset: int) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 36)
	if preset == Control.PRESET_TOP_RIGHT:
		pc.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	Collection.glass(pc, 20, 16)
	status_ui.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	pc.add_child(v)
	return v


func _shadow_label(size: int, preset: int, parent: Node) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 40)
	l.grow_vertical = Control.GROW_DIRECTION_BEGIN
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


# ---------- stany ----------

func _enter(st: String) -> void:
	var was := state
	state = st
	choose_ui.visible = st == "choose"
	status_ui.visible = st != "choose"
	finish_btn.visible = st == "painting"
	touch_btn.visible = st in ["drying", "dry"]
	again_btn.visible = st in ["drying", "dry", "ruined"]
	bar.visible = st in ["painting", "drying"]
	clock_card.visible = st in ["drying", "dry"]
	rolling = false
	_was_rolling = false
	_stare_t = 0.0
	var p := PaintTime.find(paint_id)
	wall_mat.set_shader_parameter("sheen", p.sheen)
	wall_mat.set_shader_parameter("wetness", 0.0 if st == "dry" else 1.0)
	match st:
		"choose":
			choose_head.text = "%s — wybierz farbę" % PaintTime.WALLS[wall_i]
			wall_mat.set_shader_parameter("touch_pos", Vector2(-1, -1))
		"painting":
			title_lbl.text = "MALOWANIE"
			msg_lbl.text = "Prowadź wałek po ścianie. Jedna warstwa prześwituje — jak w życiu."
		"drying":
			title_lbl.text = "FARBA SCHNIE"
			again_btn.text = "Zacznij od nowa"
			msg_lbl.text = MESSAGES[0]
		"dry":
			title_lbl.text = "WYSCHŁO!"
			timer_lbl.text = "00:00:00"
			sub_lbl.text = "%s, kolor: %s. Sucha w dotyku. Gratulacje — przetrwałeś." % [p.name, COLORS[color_i][0]]
			if _wget("cheated", false):
				sub_lbl.text += "\nWyschła nieuczciwie. Zegar systemowy wszystko pamięta."
			msg_lbl.text = "Możesz teraz z dumą powiedzieć, że oglądałeś, jak schnie farba. Do końca."
			again_btn.text = "Pomaluj jeszcze raz"
		"ruined":
			title_lbl.text = "ODCISK DŁONI"
			sub_lbl.text = "Klasyk. Każdy to robi. Ściana do poprawki."
			msg_lbl.text = "Mówiliśmy: nie dotykać."
			again_btn.text = "Maluj od nowa"
	_update_stats()
	# fokus dla pada/klawiatury: poza malowaniem zawsze jest przycisk, który A/Enter naciśnie
	match st:
		"choose":
			_go_btn.grab_focus.call_deferred()
		"painting":
			get_viewport().gui_release_focus.call_deferred()
		"drying", "dry":
			touch_btn.grab_focus.call_deferred()
		"ruined":
			again_btn.grab_focus.call_deferred()
	if st != was or not status_ui.visible:
		Collection.slide_in(choose_ui if st == "choose" else status_ui, Vector2(-60, 0) if st == "choose" else Vector2(0, 30))


func _start_painting() -> void:
	_wset("paint_id", paint_id)
	_wset("color", color_i)
	_wset("cheated", false)
	_wset("state", "painting")
	_apply_color()
	_new_mask()
	_upload_mask()
	ink = 1.0
	if paint_id == "varnish":
		Collection.unlock("paint", "masochist")
	elif paint_id == "quick":
		Collection.unlock("paint", "impatient")
	Collection.tone(330, 0.3, 0.12, 0.8)
	_enter("painting")


func _finish_painting() -> void:
	var cov := mask.coverage()
	if cov < 0.5:
		msg_lbl.text = "Pół ściany to jeszcze nie ściana. Maluj dalej."
		Collection.tone(200, 0.15, 0.2)
		return
	_save_mask()
	_wset("coverage", cov)
	_wset("start_unix", Time.get_unix_time_from_system())
	_wset("state", "drying")
	if cov >= 0.99:
		Collection.unlock("paint", "perfectionist")
	elif cov < 0.85:
		Collection.unlock("paint", "botcher")
	if mask.excess() > 0.005:
		Collection.unlock("paint", "sag")
	Collection.tone(660, 0.1)
	_enter("drying")


## Nabranie farby: wałek jedzie do kuwety i wraca pełny.
func _dip() -> void:
	if dipping:
		return
	dipping = true
	rolling = false
	var t := create_tween()
	t.tween_property(roller, "position", TRAY + Vector3(0, 0.1, 0.05), 0.3)
	t.tween_callback(Collection.tone.bind(240, 0.2, 0.15, 0.7))
	t.tween_interval(0.25)
	t.tween_callback(func():
		ink = 1.0
		dipping = false)


## Dotknięcie ściany w punkcie uv (kliknięcie); bez punktu (przycisk, pad) — gdzieś na środku.
func _touch(uv := Vector2(-1, -1)) -> void:
	if state == "dry":
		msg_lbl.text = "Sucha jak pieprz. Możesz dotykać do woli."
		Collection.tone(520, 0.1)
		return
	if uv.x < 0.0:
		uv = Vector2(randf_range(0.35, 0.65), randf_range(0.35, 0.65))
	if mask.at(uv) < 0.3:
		msg_lbl.text = "Tam nie ma farby. Dotknąłeś gołej ściany. Też dobrze."
		Collection.tone(520, 0.1)
		return
	var p := PaintTime.find(paint_id)
	if _left(wall_i) / p.secs < 0.05:
		Collection.unlock("paint", "so_close")
	Collection.unlock("paint", "fingerprint")
	wall_mat.set_shader_parameter("touch_pos", uv)
	_wset("touch_x", uv.x)
	_wset("touch_y", uv.y)
	_wset("state", "ruined")
	Collection.set_val("paint", "ruined", Collection.get_val("paint", "ruined", 0) + 1)
	Collection.tone(140, 0.25, 0.4, 0.6)
	_enter("ruined")


func _restart() -> void:
	_wset("state", "choose")
	_new_mask()
	_upload_mask()
	_save_mask()
	Collection.tone(440, 0.08)
	_enter("choose")


## Zmiana ściany: zapis, ekran ładowania (pod nim podmiana ściany), osiągnięcia za cierpliwość lub jej brak.
func _switch_wall(d: int) -> void:
	if switching or dipping:
		return
	switching = true
	rolling = false
	_save_mask()
	var skipped: bool = await loading.run(func():
		wall_i = posmod(wall_i + d, WALL_PROPS.size())
		Collection.set_val("paint", "wall", wall_i)
		_load_wall()
		_update_walls())
	switching = false
	if skipped:
		Collection.unlock("paint", "no_time")
	else:
		var n: int = Collection.get_val("paint", "loads_watched", 0) + 1
		Collection.set_val("paint", "loads_watched", n)
		if n >= 10:
			Collection.unlock("paint", "bar_fan")


## Pozostały czas schnięcia ściany [s].
func _left(wall: int) -> float:
	var p := PaintTime.find(_wget("paint_id", "acrylic", wall))
	var now := Time.get_unix_time_from_system()
	return PaintTime.remaining(_wget("start_unix", now, wall), p.secs, now, PaintTime.speed())


## Raz na sekundę: pilnuje zegara systemowego i wszystkich czterech ścian (schną też nieoglądane).
func _tick() -> void:
	var now := Time.get_unix_time_from_system()
	var mono := Time.get_ticks_msec() / 1000.0
	if PaintTime.clock_cheat(Collection.get_val("paint", "last_seen", 0.0), now, now - _last_clock, mono - _last_mono):
		Collection.unlock("paint", "time_traveller")
		for w in WALL_PROPS.size():
			var st: String = _wget("state", "choose", w)
			if st == "drying" or (st == "dry" and _wget("dried_at", 0.0, w) > now):
				_wset("cheated", true, w)
		Collection.set_val("paint", "last_seen", now)    # nowy punkt odniesienia: jedno wykrycie na jedno przestawienie
	_last_clock = now
	_last_mono = mono
	_seen_t += 1.0
	if _seen_t >= 30.0:
		_seen_t = 0.0
		Collection.set_val("paint", "last_seen", now)
	var all_dry := true
	for w in WALL_PROPS.size():
		if _wget("state", "choose", w) == "drying" and _left(w) <= 0.0:
			_wset("state", "dry", w)
			_wset("dried_at", now, w)
			Collection.set_val("paint", "dried", Collection.get_val("paint", "dried", 0) + 1)
			Collection.set_val("paint", "waited", Collection.get_val("paint", "waited", 0.0)
					+ PaintTime.find(_wget("paint_id", "acrylic", w)).secs)
			Collection.unlock("paint", "witness")
			if _first_tick:
				Collection.unlock("paint", "absentee")
			if w == wall_i and not switching:
				for i in 3:
					get_tree().create_timer(i * 0.18).timeout.connect(Collection.tone.bind(523.0 * pow(1.26, i), 0.3, 0.25))
				_enter("dry")
		all_dry = all_dry and _wget("state", "choose", w) == "dry"
	if all_dry:
		Collection.unlock("paint", "renovation")
	_first_tick = false
	_update_walls()


func _update_walls() -> void:
	var parts := PackedStringArray()
	for w in WALL_PROPS.size():
		var s := "—"
		match _wget("state", "choose", w):
			"painting":
				s = "malowana"
			"drying":
				s = PaintTime.fmt(_left(w))
			"dry":
				s = "sucha"
			"ruined":
				s = "odcisk"
		parts.append(("[ %d: %s ]" if w == wall_i else "%d: %s") % [w + 1, s])
	walls_lbl.text = "%s  (%d/%d)\n%s" % [PaintTime.WALLS[wall_i], wall_i + 1, WALL_PROPS.size(), "     ".join(parts)]


func _update_stats() -> void:
	stats_lbl.text = "Wyschniętych ścian: %d   ·   Zepsutych: %d   ·   Łącznie przeczekane: %s" % [
		Collection.get_val("paint", "dried", 0), Collection.get_val("paint", "ruined", 0),
		PaintTime.fmt(Collection.get_val("paint", "waited", 0.0))]


func _exit_tree() -> void:
	_save_mask()
	Collection.set_val("paint", "last_seen", Time.get_unix_time_from_system())


# ---------- wejście ----------

func _uv(p: Vector2) -> Vector2:
	return Vector2(p.x / WALL.x + 0.5, 1.0 - p.y / WALL.y)


## Punkt ściany pod kursorem [m] (może leżeć poza ścianą).
func _mouse_wall() -> Vector2:
	var o := cam.project_ray_origin(_mouse)
	var n := cam.project_ray_normal(_mouse)
	if absf(n.z) < 0.001:
		return roller_pos
	var hit := o - n * (o.z / n.z)
	return Vector2(hit.x, hit.y)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:      # w _input, bo ruch nad kartami UI nie dociera do _unhandled_input
		_mouse = event.position


func _unhandled_input(event: InputEvent) -> void:
	if switching:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if state == "painting":
			rolling = event.pressed
		elif event.pressed and state in ["drying", "dry"]:
			var hit := _mouse_wall()
			if absf(hit.x) <= WALL.x / 2 and hit.y >= 0.0 and hit.y <= WALL.y:
				_touch(_uv(hit))
	elif event.is_action_pressed("pad_prev"):
		_switch_wall(-1)
	elif event.is_action_pressed("pad_next"):
		_switch_wall(1)
	elif state == "painting" and event.is_action_pressed("handbrake"):
		_dip()
	elif state == "painting" and event.is_action_pressed("pad_mode"):
		_finish_painting()


## Malowanie: wałek idzie za myszą (albo lewą gałką), wciśnięty zostawia farbę i się wyciera.
func _paint(dt: float) -> void:
	bar.value = mask.coverage()
	sub_lbl.text = "%s, %s  ·  pokrycie: %d%%  ·  farba na wałku: %d%%" % [
		PaintTime.find(paint_id).name, COLORS[color_i][0], int(mask.coverage() * 100.0), int(ink * 100.0)]
	if dipping:
		return
	var target := roller_pos
	var want := rolling
	if Collection.using_pad:
		var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.15:
			target += stick * 2.4 * dt
		want = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.3
	else:
		target = roller_pos.lerp(_mouse_wall(), 1.0 - exp(-dt * 25.0))
	target = target.clamp(Vector2(-WALL.x / 2, 0.0), Vector2(WALL.x / 2, WALL.y))
	var on := want and ink > 0.0
	if on:
		var to := _uv(target)
		mask.stamp(_uv(roller_pos) if _was_rolling else to, to, roller_half, COAT * smoothstep(0.0, 0.3, ink))
		ink = maxf(0.0, ink - roller_pos.distance_to(target) / ROLL_M)
		_upload_mask()
		_roll_snd -= dt
		if _roll_snd <= 0.0 and roller_pos.distance_to(target) > 0.002:
			_roll_snd = 0.22
			Collection.tone(170, 0.14, 0.05, 0.9)
		if ink <= 0.0:
			msg_lbl.text = "Wałek suchy. Nabierz farby z kuwety."
			Collection.tone(200, 0.15, 0.2)
	elif _was_rolling:
		_save_mask()      # koniec pociągnięcia — maska na dysk
	_was_rolling = on
	roller_pos = target
	var dest := Vector3(target.x, target.y, 0.0 if on else 0.07)
	roller.position = roller.position.lerp(dest, 1.0 - exp(-dt * 30.0))
	roller.rotation = roller.rotation.lerp(Vector3.ZERO, 1.0 - exp(-dt * 12.0))


func _process(dt: float) -> void:
	var tsec := Time.get_ticks_msec() / 1000.0
	cam.look_at_from_position(Vector3(sin(tsec * 0.07) * 0.25, 1.35 + sin(tsec * 0.05) * 0.05, 3.6), Vector3(0, 1.3, 0))
	_tick_t += dt
	if _tick_t >= 1.0:
		_tick_t = 0.0
		_tick()
	if switching:
		return
	if state == "painting":
		_paint(dt)
		return
	if not dipping:      # wałek odpoczywa w kuwecie
		roller.position = roller.position.lerp(TRAY + Vector3(0, 0.12, 0.02), 1.0 - exp(-dt * 6.0))
		roller.rotation = roller.rotation.lerp(Vector3(-1.1, 0.3, 0), 1.0 - exp(-dt * 6.0))
	if state in ["drying", "ruined"]:
		var p := PaintTime.find(paint_id)
		var left := _left(wall_i)
		var wet: float = left / p.secs
		wall_mat.set_shader_parameter("wetness", wet)
		if state == "ruined":
			return
		timer_lbl.text = PaintTime.fmt(left)
		bar.value = 1.0 - wet
		sub_lbl.text = "%s  ·  wilgotność: %.1f%%  ·  pokrycie: %d%%" % [p.name, wet * 100.0, int(_wget("coverage", 1.0) * 100.0)]
		msg_t += dt
		if msg_t > 12.0:
			msg_t = 0.0
			msg_i = (msg_i + 1) % MESSAGES.size()
			msg_lbl.text = MESSAGES[msg_i]
		_stare_t += dt
		if _stare_t >= 600.0:
			Collection.unlock("paint", "stare")


# ---------- tryb zrzutów: --shot=paint | paint_painting | paint_dry | paint_choose | paint_loading | paint_switch | paint_stroke [--wall=N] ----------

func _shot_setup(shot: String) -> void:
	if shot == "paint_choose":
		return
	paint_id = "oil"
	_new_mask()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 13:      # pasy wałka: większość ściany, część podwójnie, jeden przemalowany do zacieków
		var u := 0.04 + i * 0.066
		for pass_i in (4 if i == 5 else (2 if i % 3 else 1)):
			mask.stamp(Vector2(u + rng.randf_range(-0.01, 0.01), 0.03),
					Vector2(u + rng.randf_range(-0.01, 0.01), rng.randf_range(0.8, 0.99)), roller_half, COAT)
	_upload_mask()
	_wset("paint_id", paint_id)
	_wset("coverage", mask.coverage())
	_wset("start_unix", Time.get_unix_time_from_system() - PaintTime.find(paint_id).secs * 0.45)
	match shot:
		"paint_painting":
			roller_pos = Vector2(-0.4, 1.5)
			_enter("painting")
		"paint_dry":
			_enter("dry")
		_:
			_wset("state", "drying")
			_enter("drying")
	match shot:
		"paint_loading":
			loading.run()
		"paint_switch":       # pełna zmiana ściany; zrzut z --delay=18 pokazuje następną ścianę
			_switch_wall(1)
		"paint_stroke":       # prawdziwa ścieżka wejścia: LPM + ruch myszy po czystej ścianie
			_new_mask()
			_upload_mask()
			_enter("painting")
			_shot_stroke()


func _shot_stroke() -> void:
	await get_tree().create_timer(0.5).timeout
	for i in 100:
		var mm := InputEventMouseMotion.new()
		mm.position = cam.unproject_position(Vector3(-2.2 + i * 0.03, 1.3 + sin(i * 0.3) * 1.0, 0))
		Input.parse_input_event(mm)
		if i == 2:
			var press := InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.pressed = true
			press.position = mm.position
			Input.parse_input_event(press)
		await get_tree().process_frame
