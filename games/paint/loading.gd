class_name PaintLoading
extends Control
## Ekran ładowania przy zmianie ściany, w duchu wielkich gier RPG: trwa za długo, pokazuje model
## bez związku z czymkolwiek i poradę z niczego. Model można obracać. Po 3 s da się pominąć.

signal finished

const SKIP_AFTER := 3.0
## Pasek postępu: [ułamek czasu, wartość]. Staje, cofa się i wisi na 99%.
const KEYS := [[0.0, 0.0], [0.1, 0.31], [0.24, 0.31], [0.3, 0.64], [0.36, 0.57], [0.55, 0.83], [0.7, 0.99], [1.0, 0.99]]
const TIPS := [
	"Farba schnie szybciej, jeśli na nią nie patrzysz. Nie mamy na to dowodów.",
	"Wałek trzymaj za rączkę. Drugi koniec jest mokry.",
	"Kredensy nie występują w tej grze. Ten na ekranie zabłądził.",
	"Jeśli ekran ładowania trwa dłużej niż schnięcie farby, wybierz wolniejszą farbę.",
	"Naciśnięcie klamki nie przyspiesza ładowania. Sprawdzaliśmy.",
	"Ściana z oknem ma okno. Ściana z drzwiami ma drzwi. Prosimy nie pytać o gołą ścianę.",
	"Możesz pominąć ten ekran. Farba ci tego nie zapomni.",
	"Ten model nie ma nic wspólnego z poradą. Porada nie ma nic wspólnego z grą.",
	"Zieleń szpitalna uspokaja. Zwłaszcza po ośmiu godzinach farby olejnej.",
	"W prawdziwym życiu drugą warstwę kładzie się po wyschnięciu pierwszej. Tutaj nikt nie ma na to czasu.",
	"Przestawienie zegara systemowego to nie strategia, tylko charakter.",
	"Ładowanie ściany trwa tyle, bo ściana jest duża.",
	"Wskazówka: sufit jest u góry.",
	"Każda ściana ma własny zegar. Tak, to znaczy cztery razy więcej czekania.",
	"Jeśli pasek postępu się cofnął, to znaczy, że wszystko działa.",
	"Nie dotykaj mokrej farby. Ta porada pojawi się jeszcze wiele razy. Nie pomoże.",
	"Lakier do drewna na ścianie? Nikt cię nie powstrzyma. A powinien.",
	"Fachowiec przyjdzie w czwartek. Nie powiedział, w który.",
	"Kaloryfer nie grzeje. To tylko model. Jak wszystko tutaj.",
	"Zapisuj grę często. Żartujemy, gra zapisuje się sama.",
	"Obracaj model myszką. To jedyna rozgrywka na tym ekranie.",
	"99% to też wynik.",
	"Pamiętaj o przerwach. Od patrzenia na farbę też trzeba odpocząć.",
	"Sąsiad pyta, kiedy koniec remontu. Farba nie odpowiada.",
	"Wałek zostawiony w kuwecie na noc staje się rzeźbą.",
]

var _pivot: Node3D
var _bar: ProgressBar
var _pct: Label
var _tip: Label
var _head: Label
var _level: Label
var _xp: ProgressBar
var _skip: Control
var _spin: TextureRect
var _font := SystemFont.new()
var _t := 0.0
var _dur := 10.0
var _skipped := false
var _running := false


func _ready() -> void:
	_font.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Arial"])
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)   # sam set_anchors_preset w drzewie zachowałby rozmiar 0×0
	mouse_filter = MOUSE_FILTER_STOP      # zasłania grę: kliknięcia nie trafiają w przyciski pod spodem
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.03, 0.03)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)
	Collection.vignette(self, 0.9)
	move_child(bg, 0)
	_build_model_view()

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT, PRESET_MODE_MINSIZE, 90)
	left.grow_vertical = GROW_DIRECTION_BEGIN
	left.offset_bottom = -130
	left.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(left)
	_level = _label(left, 28, Color(1, 0.3, 0.35))
	_xp = ProgressBar.new()
	_xp.custom_minimum_size = Vector2(340, 14)
	_xp.size_flags_horizontal = SIZE_SHRINK_BEGIN
	_xp.show_percentage = false
	_xp.max_value = 1.0
	left.add_child(_xp)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 40)
	left.add_child(gap)
	_head = _label(left, 22, Color(1, 1, 1, 0.7))
	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.86, 0.07, 0.12, 0.08)
	sb.border_color = Collection.RED
	sb.set_border_width_all(2)
	sb.set_content_margin_all(14)
	box.add_theme_stylebox_override("panel", sb)
	left.add_child(box)
	_tip = _label(box, 27, Color(1, 0.86, 0.86))
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.custom_minimum_size = Vector2(760, 0)

	_pct = _label(self, 20, Color(1, 1, 1, 0.6))
	_pct.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT, PRESET_MODE_MINSIZE, 90)
	_pct.grow_vertical = GROW_DIRECTION_BEGIN
	_pct.offset_bottom = -34
	_bar = ProgressBar.new()
	_bar.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	_bar.offset_top = -6
	_bar.show_percentage = false
	_bar.max_value = 1.0
	add_child(_bar)

	_spin = TextureRect.new()                # kręcąca się strzałka w rogu
	_spin.texture = Collection.icon("restart")
	_spin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_spin.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	_spin.offset_left = -150
	_spin.offset_right = -70
	_spin.offset_top = -130
	_spin.offset_bottom = -50
	_spin.pivot_offset = Vector2(40, 40)
	_spin.modulate = Collection.RED.lightened(0.2)
	_spin.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_spin)
	_skip = Collection.hints(self, [["accept", "Pomiń"]])
	_skip.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT, PRESET_MODE_MINSIZE, 70)
	_skip.grow_horizontal = GROW_DIRECTION_BEGIN
	_skip.grow_vertical = GROW_DIRECTION_BEGIN
	_skip.offset_left -= 110      # na lewo od strzałki
	_skip.offset_right -= 110
	hide()


func _label(parent: Control, size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


## Podgląd modelu: osobny świat 3D, światło z góry i czerwona kontra (jak wybór kredensu w wyścigach).
func _build_model_view() -> void:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.anchor_left = 0.5
	svc.anchor_right = 0.98
	svc.anchor_top = 0.04
	svc.anchor_bottom = 0.92
	svc.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(svc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	svc.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.8)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 25, 0)
	key.light_energy = 2.2
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, 160, 0)
	rim.light_color = Color(1.0, 0.35, 0.35)
	rim.light_energy = 0.9
	vp.add_child(rim)
	var cam := Camera3D.new()
	cam.fov = 30
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, 0.5, 4.4), Vector3.ZERO)
	_pivot = Node3D.new()
	vp.add_child(_pivot)


func _models() -> Array:
	return [
		["Wałek malarski, 36 cm", func(): return PaintProps.roller(Collection.RED)],
		["Puszka farby, 5 l", func(): return PaintProps.can(Collection.RED)],
		["Kaloryfer żeliwny, 14 żeberek", func(): return PaintProps.build("radiator", Vector2(1.2, 0.62))],
		["Okno. Po prostu okno", func(): return PaintProps.build("window", Vector2(1.5, 1.4))],
		["Kredens (zabłądził)", func(): return Kredens.build_model(Kredens.TYPES.pick_random())],
		["Klamka z szyldem", func(): return PaintProps.handle()],
		["brak_modelu.obj", func(): return PaintProps.missing()],
	]


## Wyśrodkowuje model w punkcie obrotu i skaluje go do ~1,5 m, żeby każdy rekwizyt mieścił się w kadrze.
func _fit(n: Node3D) -> void:
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = n.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var s := 1.5 / maxf(box.get_longest_axis_size(), 0.01)
	n.scale = Vector3.ONE * s
	n.position = -box.get_center() * s


## Pokazuje ekran na 8–15 s. mid wykona się, gdy ekran już wszystko zasłania (tam podmienia się ścianę).
## Zwraca true, jeśli gracz pominął ładowanie.
func run(mid := Callable()) -> bool:
	_t = 0.0
	_skipped = false
	_dur = randf_range(8.0, 15.0)
	var lvl: int = Collection.get_val("paint", "loads_watched", 0) + 1
	_level.text = "POZIOM CIERPLIWOŚCI %d" % lvl
	_xp.value = randf_range(0.15, 0.95)
	var model: Array = _models().pick_random()
	_head.text = "Katalog NRGeek nr %04d  ·  %s" % [randi_range(1, 9999), model[0]]
	_tip.text = TIPS.pick_random()
	for c in _pivot.get_children():
		c.queue_free()
	var node: Node3D = model[1].call()
	_pivot.add_child(node)
	_fit(node)
	_pivot.rotation.y = 0.6
	_skip.hide()
	_bar.value = 0.0
	modulate.a = 0.0
	show()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.3)
	await tw.finished
	if mid.is_valid():
		mid.call()
	_running = true
	await finished
	tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	await tw.finished
	hide()
	return _skipped


func _process(dt: float) -> void:
	if not visible:
		return
	var rs := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	_pivot.rotation.y += dt * (0.5 + (rs * 3.0 if absf(rs) > 0.15 else 0.0))
	_spin.rotation += dt * 2.5
	if not _running:
		return
	_t += dt
	var x := _t / _dur
	var v := 0.99
	for i in KEYS.size() - 1:
		if x < KEYS[i + 1][0]:
			v = remap(x, KEYS[i][0], KEYS[i + 1][0], KEYS[i][1], KEYS[i + 1][1])
			break
	_bar.value = v
	_pct.text = "Wczytywanie ściany…  %d%%" % int(v * 100.0)
	_skip.visible = _t >= SKIP_AFTER
	if _t >= _dur:
		_running = false
		finished.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()   # nie przepuszczaj Entera do przycisków gry pod spodem
		if _running and _t >= SKIP_AFTER:
			_running = false
			_skipped = true
			finished.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_pivot.rotation.y += event.relative.x * 0.01
