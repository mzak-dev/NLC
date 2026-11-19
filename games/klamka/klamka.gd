extends Node3D
## Symulator naciskania klamki: ręczne przeciąganie myszą albo nacisk zadaną siłą, telemetria i rekordy.

const PRESETS := {
	"PRL — mosiądz": {"k": 2.2, "c": 0.004, "f": 0.012, "e": 0.45, "i": 0.0012},
	"Nowoczesna — inox": {"k": 2.8, "c": 0.009, "f": 0.006, "e": 0.30, "i": 0.0008},
	"Zmęczona sprężyna (kamienica)": {"k": 0.9, "c": 0.002, "f": 0.02, "e": 0.62, "i": 0.0011},
	"Luźna z demobilu": {"k": 1.4, "c": 0.001, "f": 0.03, "e": 0.78, "i": 0.0016},
}
const HIST := 600            # 5 s przy 120 Hz
const HAND_K := 25.0         # sztywność „ręki” [N·m/rad]
const HAND_C := 0.15         # tłumienie „ręki”
const MAX_F := 250.0

var sim := HandleSim.new()
var mode := "hand"
var grabbing := false
var grab_y := 0.0
var drag_px := 0.0
var push_left := 0.0
var force_n := 60.0
var push_ms := 150.0
var applied := 0.0
var pressing := false
var released_t := -1.0
var history := PackedFloat32Array()
var hist_i := 0
var latch_open := false
var orbit := Vector2(0.45, -0.12)
var dist := 0.75
var orbiting := false
var pad_pull := false     # klamka trzymana spustem RT
var _last_bounces := 0

var cam: Camera3D
var handle_pivot: Node3D
var grip: Node3D
var bolt: MeshInstance3D
var door_hinge: Node3D
var graph: Control
var stats: Label
var force_lbl: Label
var sliders := {}
var _mode_btns: Array[Button] = []
var _preset_btn: OptionButton
var _preset_i := 0
var _presets_seen := {}
var hand_box: Control
var force_box: Control
var val_force: Label
var val_angle: Label
var val_bounce: Label
var hint: Label
var toast: PanelContainer
var toast_lbl: Label


func _ready() -> void:
	history.resize(HIST)
	_build_world()
	_build_ui()
	_apply_preset(PRESETS.keys()[0])


# ---------- świat ----------

func _mat(c: Color, rough := 0.6, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = m
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, r: float, h: float, pos: Vector3, rot: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	mi.mesh = c
	mi.position = pos
	mi.rotation = rot
	mi.material_override = m
	parent.add_child(mi)
	return mi


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.04, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.62)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 35, 0)
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	add_child(sun)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.9, 1.9, 1.2)
	lamp.light_color = Color(1.0, 0.85, 0.65)
	lamp.light_energy = 0.7
	lamp.omni_range = 5.0
	lamp.shadow_enabled = true
	add_child(lamp)

	var wall_m := _mat(Color(0.55, 0.52, 0.45), 0.9)
	var frame_m := _mat(Color(0.93, 0.92, 0.88), 0.4)
	_box(self, Vector3(6, 0.1, 4), Vector3(0, -0.05, 1), _mat(Color(0.35, 0.22, 0.13), 0.7))
	_box(self, Vector3(2.0, 2.8, 0.15), Vector3(-1.45, 1.4, -0.09), wall_m)
	_box(self, Vector3(2.0, 2.8, 0.15), Vector3(1.45, 1.4, -0.09), wall_m)
	_box(self, Vector3(0.9, 0.8, 0.15), Vector3(0, 2.4, -0.09), wall_m)
	_box(self, Vector3(0.07, 2.07, 0.19), Vector3(-0.485, 1.035, -0.07), frame_m)
	_box(self, Vector3(0.07, 2.07, 0.19), Vector3(0.485, 1.035, -0.07), frame_m)
	_box(self, Vector3(1.04, 0.07, 0.19), Vector3(0, 2.035, -0.07), frame_m)

	door_hinge = Node3D.new()
	door_hinge.position = Vector3(-0.45, 0, -0.02)
	add_child(door_hinge)
	var door_m := _mat(Color(0.36, 0.22, 0.12), 0.45)
	_box(door_hinge, Vector3(0.9, 1.99, 0.04), Vector3(0.45, 0.995, 0), door_m)
	var inset := _mat(Color(0.31, 0.19, 0.1), 0.5)
	_box(door_hinge, Vector3(0.62, 0.7, 0.01), Vector3(0.45, 1.55, 0.022), inset)
	_box(door_hinge, Vector3(0.62, 0.7, 0.01), Vector3(0.45, 0.55, 0.022), inset)

	var brass := _mat(Color(0.9, 0.68, 0.32), 0.3, 0.55)
	var dark := _mat(Color(0.05, 0.05, 0.05), 0.8)
	_box(door_hinge, Vector3(0.046, 0.24, 0.008), Vector3(0.81, 0.98, 0.024), brass)   # szyld
	_box(door_hinge, Vector3(0.01, 0.026, 0.002), Vector3(0.81, 0.9, 0.0285), dark)     # dziurka od klucza
	_cyl(door_hinge, 0.006, 0.002, Vector3(0.81, 0.916, 0.0285), Vector3(PI / 2, 0, 0), dark)
	bolt = _box(door_hinge, Vector3(0.03, 0.026, 0.018), Vector3(0.9, 1.05, 0), brass)  # zatrzask

	handle_pivot = Node3D.new()
	handle_pivot.position = Vector3(0.81, 1.05, 0.028)
	door_hinge.add_child(handle_pivot)
	_cyl(handle_pivot, 0.011, 0.05, Vector3(0, 0, 0.025), Vector3(PI / 2, 0, 0), brass)
	var lever := _box(handle_pivot, Vector3(0.13, 0.017, 0.022), Vector3(-0.06, 0, 0.05), brass)
	lever.rotation.z = 0.04
	var tip := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.014
	sph.height = 0.028
	tip.mesh = sph
	tip.material_override = brass
	tip.position = Vector3(-0.125, -0.002, 0.05)
	handle_pivot.add_child(tip)
	grip = Node3D.new()
	grip.position = Vector3(-0.09, 0, 0.05)
	handle_pivot.add_child(grip)

	cam = Camera3D.new()
	cam.fov = 50
	cam.h_offset = -0.13
	var attr := CameraAttributesPractical.new()   # głębia ostrości: klamka ostra, reszta drzwi miękko rozmyta
	attr.dof_blur_far_enabled = true
	attr.dof_blur_far_transition = 0.45
	attr.dof_blur_amount = 0.12
	cam.attributes = attr
	add_child(cam)


# ---------- UI ----------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	Collection.vignette(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(40, 40)
	panel.custom_minimum_size = Vector2(520, 0)
	Collection.glass(panel)
	layer.add_child(panel)
	Collection.slide_in(panel, Vector2(-60, 0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var title := Label.new()
	title.hide()
	var lg := Collection.logo_rect("klamka", 300)
	lg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(lg)
	title.add_theme_font_size_override("font_size", 30)
	v.add_child(title)
	var accent := ColorRect.new()
	accent.color = Collection.RED
	accent.custom_minimum_size = Vector2(64, 3)
	accent.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(accent)

	var modes := HBoxContainer.new()
	v.add_child(modes)
	var group := ButtonGroup.new()
	for m in [["hand", "Ręcznie (mysz)"], ["force", "Zadana siła"]]:
		var b := Button.new()
		b.text = m[1]
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = m[0] == mode
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_set_mode.bind(m[0]))
		b.focus_mode = Control.FOCUS_NONE
		modes.add_child(b)
		_mode_btns.append(b)

	hand_box = Label.new()
	hand_box.text = "Złap klamkę lewym przyciskiem i pociągnij w dół.\nPuść i patrz, jak odbija. PPM — obrót, kółko — zoom."
	hand_box.add_theme_font_size_override("font_size", 20)
	hand_box.modulate.a = 0.8
	v.add_child(hand_box)

	force_box = VBoxContainer.new()
	v.add_child(force_box)
	_slider(force_box, "force", "Siła nacisku", 0, MAX_F, 1, force_n, "%.0f N", func(x): force_n = x)
	_slider(force_box, "dur", "Czas nacisku", 10, 600, 10, push_ms, "%.0f ms", func(x): push_ms = x)
	var push := Button.new()
	push.text = "Naciśnij  [Spacja]"
	push.pressed.connect(_push)
	force_box.add_child(push)
	force_box.hide()

	var sep := Label.new()
	sep.text = "Parametry klamki"
	sep.add_theme_font_size_override("font_size", 22)
	sep.modulate = Color(1, 0.4, 0.45)
	v.add_child(sep)
	var preset := OptionButton.new()
	_preset_btn = preset
	preset.focus_mode = Control.FOCUS_NONE
	for p in PRESETS:
		preset.add_item(p)
	preset.item_selected.connect(func(i):
		_preset_i = i
		_apply_preset(PRESETS.keys()[i]))
	v.add_child(preset)
	_slider(v, "k", "Sztywność sprężyny", 0.3, 5.0, 0.05, sim.stiffness, "%.2f N·m/rad", func(x): sim.stiffness = x)
	_slider(v, "c", "Tłumienie", 0.0, 0.03, 0.0005, sim.damping, "%.4f", func(x): sim.damping = x)
	_slider(v, "f", "Tarcie", 0.0, 0.08, 0.001, sim.friction, "%.3f N·m", func(x): sim.friction = x)
	_slider(v, "e", "Odbijalność", 0.0, 0.95, 0.01, sim.restitution, "%.2f", func(x): sim.restitution = x)
	_slider(v, "i", "Bezwładność", 0.0003, 0.003, 0.0001, sim.inertia, "%.4f kg·m²", func(x): sim.inertia = x)

	var gp := PanelContainer.new()
	gp.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	gp.custom_minimum_size = Vector2(680, 0)
	gp.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	gp.grow_vertical = Control.GROW_DIRECTION_BEGIN
	gp.offset_right = -40
	gp.offset_bottom = -40
	Collection.glass(gp)
	layer.add_child(gp)
	Collection.slide_in(gp, Vector2(60, 0), 0.15)
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 10)
	gp.add_child(gv)
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 24)
	gv.add_child(tiles)
	val_force = _tile(tiles, "SIŁA [N]")
	val_angle = _tile(tiles, "KĄT [°]")
	val_bounce = _tile(tiles, "ODBICIA")
	graph = Control.new()
	graph.custom_minimum_size = Vector2(640, 170)
	graph.draw.connect(_draw_graph)
	gv.add_child(graph)
	force_lbl = Label.new()
	force_lbl.add_theme_font_size_override("font_size", 17)
	force_lbl.modulate.a = 0.65
	gv.add_child(force_lbl)
	stats = Label.new()
	stats.add_theme_font_size_override("font_size", 19)
	gv.add_child(stats)

	hint = Label.new()
	hint.text = "Złap i pociągnij  ↓"
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(hint)

	var hb := Collection.hints(layer, [["grab", "Naciśnij klamkę"], ["x", "Naciśnij (tryb siły)"], ["mode", "Tryb"], ["lb_rb", "Preset"], ["stick_r", "Kamera"], ["pause", "Menu"]])
	hb.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 14)
	hb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hb.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hb.scale = Vector2(0.8, 0.8)

	toast = PanelContainer.new()
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast.offset_top = 40
	Collection.glass(toast, 18)
	toast.hide()
	layer.add_child(toast)
	toast_lbl = Label.new()
	toast_lbl.add_theme_font_size_override("font_size", 30)
	toast.add_child(toast_lbl)


func _tile(parent: Control, caption: String) -> Label:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", -6)
	parent.add_child(box)
	var c := Label.new()
	c.text = caption
	c.add_theme_font_size_override("font_size", 15)
	c.add_theme_color_override("font_color", Color(1, 0.45, 0.5))
	box.add_child(c)
	var v := Label.new()
	v.add_theme_font_size_override("font_size", 52)
	box.add_child(v)
	return v


func _toast(text: String) -> void:
	toast_lbl.text = text
	toast.show()
	toast.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(toast, "modulate:a", 1.0, 0.25)
	t.tween_interval(1.8)
	t.tween_property(toast, "modulate:a", 0.0, 0.5)
	t.tween_callback(toast.hide)


func _slider(parent: Control, key: String, title: String, lo: float, hi: float, st: float, val: float, f: String, cb: Callable) -> void:
	var row := VBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 18)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = st
	s.focus_mode = Control.FOCUS_NONE
	row.add_child(s)
	s.value_changed.connect(func(x):
		cb.call(x)
		l.text = "%s: %s" % [title, f % x])
	s.value = val
	l.text = "%s: %s" % [title, f % val]
	sliders[key] = s


func _apply_preset(preset: String) -> void:
	var p: Dictionary = PRESETS[preset]
	for k in p:
		sliders[k].value = p[k]
	_presets_seen[preset] = true
	if _presets_seen.size() == PRESETS.size():
		Collection.unlock("klamka", "all_presets")


func _set_mode(m: String) -> void:
	mode = m
	hand_box.visible = m == "hand"
	force_box.visible = m == "force"
	Collection.tone(700, 0.04, 0.15)


# ---------- wejście ----------

func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and mode == "hand":
				var sp := cam.unproject_position(grip.global_position)
				if sp.distance_to(event.position) < 110.0:
					grabbing = true
					grab_y = event.position.y
					drag_px = 0.0
					_begin_press()
			elif not event.pressed:
				grabbing = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			orbiting = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			dist = maxf(0.35, dist - 0.05)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			dist = minf(1.6, dist + 0.05)
	elif event is InputEventMouseMotion:
		if grabbing:
			drag_px = maxf(0.0, event.position.y - grab_y)
		if orbiting:
			orbit.x = clampf(orbit.x - event.relative.x * 0.005, -1.0, 1.1)
			orbit.y = clampf(orbit.y - event.relative.y * 0.005, -0.7, 0.5)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		if mode == "force":
			_push()
	elif event.is_action_pressed("ui_accept") and mode == "force":
		_push()
	elif event.is_action_pressed("pad_mode"):
		_mode_btns[1 if mode == "hand" else 0].button_pressed = true
		_set_mode("force" if mode == "hand" else "hand")
	elif event.is_action_pressed("pad_prev") or event.is_action_pressed("pad_next"):
		_preset_i = posmod(_preset_i + (1 if event.is_action("pad_next") else -1), PRESETS.size())
		_preset_btn.select(_preset_i)
		_apply_preset(PRESETS.keys()[_preset_i])
		Collection.tone(760, 0.05, 0.15)
	elif mode == "force" and (event.is_action_pressed("ui_left", true) or event.is_action_pressed("ui_right", true)):
		sliders["force"].value += 10.0 if event.is_action("ui_right") else -10.0


func _push() -> void:
	if force_n >= MAX_F:
		Collection.unlock("klamka", "brute")
	push_left = push_ms / 1000.0
	_begin_press()


func _begin_press() -> void:
	sim.bounces = 0
	_last_bounces = 0
	sim.max_theta = 0.0
	pressing = true
	released_t = -1.0


# ---------- symulacja ----------

func _physics_process(dt: float) -> void:
	applied = 0.0
	# RT = siła nacisku ręki (analogowo): pełne wciśnięcie spustu = klamka do oporu
	var rt := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
	if mode == "hand" and rt > 0.08:
		if not pad_pull:
			pad_pull = true
			_begin_press()
		var pt := rt * sim.theta_max * 1.15
		applied = clampf((HAND_K * (pt - sim.theta) - HAND_C * sim.omega) / sim.lever, 0.0, MAX_F)
		Input.start_joy_vibration(0, 0.0, clampf(applied / MAX_F, 0.0, 0.4), 0.05)
	elif pad_pull:
		pad_pull = false
	if grabbing:
		var target := drag_px / 240.0 * sim.theta_max * 1.15
		applied = clampf((HAND_K * (target - sim.theta) - HAND_C * sim.omega) / sim.lever, 0.0, MAX_F)
	elif pad_pull:
		pass
	elif push_left > 0.0:
		applied = force_n
		push_left -= dt
	sim.step(applied, dt)

	if sim.bounces > _last_bounces:
		_last_bounces = sim.bounces
		var loud := clampf(sim.last_impact / 50.0, 0.04, 0.35)
		Collection.tone(1700.0 + randf() * 300.0 if sim.theta == 0.0 else 900.0, 0.18, loud, 0.15)

	if pressing and not grabbing and not pad_pull and push_left <= 0.0:
		if released_t < 0.0:
			released_t = 0.0
		released_t += dt
		if sim.at_rest():
			pressing = false
			_finish_press()

	history[hist_i] = sim.theta
	hist_i = (hist_i + 1) % HIST

	var latch := clampf(sim.theta / (0.8 * sim.theta_max), 0.0, 1.0)
	bolt.position.x = 0.9 - latch * 0.016
	if latch >= 1.0 and not latch_open:
		_open_door()


func _open_door() -> void:
	latch_open = true
	Collection.unlock("klamka", "first_open")
	Collection.tone(320, 0.06, 0.3, 0.5)
	var t := create_tween()
	t.tween_property(door_hinge, "rotation:y", 0.16, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_interval(1.4)
	t.tween_property(door_hinge, "rotation:y", 0.0, 0.25).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		Collection.tone(160, 0.2, 0.45, 0.7)
		latch_open = false)


func _finish_press() -> void:
	var total: int = Collection.get_val("klamka", "presses", 0) + 1
	Collection.set_val("klamka", "presses", total)
	if total >= 100:
		Collection.unlock("klamka", "presses_100")
	if total >= 1000:
		Collection.unlock("klamka", "presses_1000")
	if sim.max_theta == 0.0:
		Collection.unlock("klamka", "too_weak")
	elif sim.bounces == 0 and sim.max_theta > 0.5 * sim.theta_max:
		Collection.unlock("klamka", "quiet")
	if sim.bounces >= 5:
		Collection.unlock("klamka", "springy")
	var rec: int = Collection.get_val("klamka", "record_bounces", 0)
	if sim.bounces > rec:
		Collection.set_val("klamka", "record_bounces", sim.bounces)
		_toast("NOWY REKORD:  %d odbić" % sim.bounces)
		Collection.tone(880, 0.1)
		Collection.tone(1320, 0.25)


func _process(_dt: float) -> void:
	var rs := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if rs.length() > 0.15:
		orbit.x = clampf(orbit.x - rs.x * _dt * 1.5, -1.0, 1.1)
		orbit.y = clampf(orbit.y - rs.y * _dt * 1.5, -0.7, 0.5)
	handle_pivot.rotation.z = sim.theta
	var target := Vector3(0.36, 1.03, 0.06)
	var off := Vector3(sin(orbit.x) * cos(orbit.y), sin(-orbit.y), cos(orbit.x) * cos(orbit.y)) * dist
	cam.position = target + off
	cam.look_at(target)
	var settle := "—" if released_t < 0.0 else ("%.2f s" % released_t)
	(cam.attributes as CameraAttributesPractical).dof_blur_far_distance = dist + 0.12
	val_force.text = "%.0f" % applied
	val_angle.text = "%.1f" % rad_to_deg(sim.theta)
	val_bounce.text = str(sim.bounces)
	force_lbl.text = "Próg ruszenia: %.1f N    Napięcie wstępne sprężyny: %.0f°" % [sim.breakaway_force(), rad_to_deg(sim.preload_rad)]
	var sp := cam.unproject_position(grip.global_position)
	var near := mode == "hand" and not grabbing and sp.distance_to(get_viewport().get_mouse_position()) < 110.0
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if near or grabbing else Input.CURSOR_ARROW)
	hint.position = sp + Vector2(-60, 40)
	hint.modulate.a = (0.55 + 0.45 * sin(Time.get_ticks_msec() / 260.0)) if (mode == "hand" and not grabbing and sim.at_rest()) else 0.0
	stats.text = "Maks. kąt: %.1f°   Odbicia: %d   Uspokojenie: %s\nZatrzask: %s   Rekord odbić: %d   Naciśnięć łącznie: %d" % [
		rad_to_deg(sim.max_theta), sim.bounces, settle,
		"ZWOLNIONY!" if latch_open else "%d%%" % roundi(100.0 * clampf(sim.theta / (0.8 * sim.theta_max), 0, 1)),
		Collection.get_val("klamka", "record_bounces", 0), Collection.get_val("klamka", "presses", 0)]
	graph.queue_redraw()


func _draw_graph() -> void:
	var s := graph.size
	graph.draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.3))
	for i in range(1, 5):     # siatka: co 1 s i co 25% skoku
		graph.draw_line(Vector2(s.x * i / 5.0, 0), Vector2(s.x * i / 5.0, s.y), Color(1, 1, 1, 0.06), 1.0)
		graph.draw_line(Vector2(0, s.y * i / 4.0), Vector2(s.x, s.y * i / 4.0), Color(1, 1, 1, 0.06), 1.0)
	var y_latch := s.y * (1.0 - 0.8)
	graph.draw_dashed_line(Vector2(0, y_latch), Vector2(s.x, y_latch), Color(1, 0.3, 0.3, 0.5), 1.0, 6.0)
	graph.draw_string(graph.get_theme_default_font(), Vector2(s.x - 150, y_latch - 6), "zwolnienie zatrzasku", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.4, 0.45, 0.7))
	var pts := PackedVector2Array()
	pts.resize(HIST)
	for i in HIST:
		var v := history[(hist_i + i) % HIST] / sim.theta_max
		pts[i] = Vector2(s.x * i / float(HIST - 1), s.y * (1.0 - v) - 1.0)
	graph.draw_polyline(pts, Color(1.0, 0.2, 0.25, 0.18), 7.0, true)   # poświata
	graph.draw_polyline(pts, Color(1.0, 0.35, 0.4), 2.0, true)
	graph.draw_string(graph.get_theme_default_font(), Vector2(8, 20), "kąt klamki — ostatnie 5 s", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.6))
