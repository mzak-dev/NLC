extends Node
## Autoload „Collection”: zapis, ustawienia, przejścia między scenami, pauza, dźwięki, tryb zrzutów.

const SAVE_PATH := "user://save.cfg"
const MENU := "res://menu/xmb.tscn"
const GAMES := {
	"paint": "res://games/paint/paint.tscn",
	"race": "res://games/race/race.tscn",
	"klamka": "res://games/klamka/klamka.tscn",
}
const RED := Color(0.86, 0.07, 0.12)

var save := ConfigFile.new()
var args := {}            # --klucz=wartość z linii poleceń (po „--”)
var intro_done := false
var _busy := false
var _fade: ColorRect
var _fade_logo: TextureRect
var _pause: InGameXMB
var using_pad := false    # ostatnie wejście z kontrolera → podpowiedzi pokazują przyciski pada
signal input_mode_changed(pad: bool)
var _tones := {}
var ui_theme: Theme
var _toast: Control
var _toast_lbls: Array[Label] = []
var _toasts: Array = []   # kolejka [nagłówek, tytuł, opis]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if not (args.has("shot") or args.has("autorace")):
		save.load(SAVE_PATH)
	_setup_input()
	_setup_theme()
	_build_overlay()
	apply_settings()
	if args.has("shot"):
		intro_done = true
		_shot_mode.call_deferred()


# ---------- zapis / ustawienia ----------

func get_val(section: String, key: String, default: Variant = null) -> Variant:
	return save.get_value(section, key, default)


func set_val(section: String, key: String, value: Variant) -> void:
	save.set_value(section, key, value)
	if not (args.has("shot") or args.has("autorace")):   # tryby testowe nie ruszają zapisu gracza
		save.save(SAVE_PATH)


func apply_settings() -> void:
	var vol: float = get_val("settings", "volume", 0.8)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(vol, 0.0001)))
	if not args.has("shot") and DisplayServer.get_name() != "headless":
		var fs: bool = get_val("settings", "fullscreen", false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_WINDOWED)
		var vs: bool = get_val("settings", "vsync", true)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vs else DisplayServer.VSYNC_DISABLED)


# ---------- osiągnięcia ----------

## Odblokowuje osiągnięcie (raz) i pokazuje powiadomienie. Lista: core/achievements.gd.
func unlock(game: String, id: String) -> void:
	var k := Achievements.key(game, id)
	if save.has_section_key("ach", k) or args.has("autorace"):
		return
	var a := Achievements.find(game, id)
	if a.is_empty():
		push_warning("Nieznane osiągnięcie: " + k)
		return
	set_val("ach", k, Time.get_unix_time_from_system())
	toast("OSIĄGNIĘCIE ODBLOKOWANE", a.title, a.desc)
	if game != "kolekcja" and Achievements.all_done(save):
		unlock("kolekcja", "platinum")


## Powiadomienie u góry ekranu; kolejne czekają w kolejce.
func toast(head: String, title: String, text: String) -> void:
	_toasts.append([head, title, text])
	if _toasts.size() == 1:
		_next_toast()


func _next_toast() -> void:
	var it: Array = _toasts[0]
	for i in 3:
		_toast_lbls[i].text = it[i]
	_toast.show()
	_toast.modulate.a = 0.0
	for i in 3:
		get_tree().create_timer(i * 0.12).timeout.connect(tone.bind(660.0 * pow(1.26, i), 0.25, 0.2))
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_toast, "modulate:a", 1.0, 0.25)
	t.tween_interval(3.5)
	t.tween_property(_toast, "modulate:a", 0.0, 0.5)
	t.tween_callback(func():
		_toast.hide()
		_toasts.pop_front()
		if not _toasts.is_empty():
			_next_toast())


# ---------- sceny ----------

func go_to(path: String) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	_pause.hide()
	var game_id := ""
	for k in GAMES:
		if GAMES[k] == path:
			game_id = k
	_fade_logo.texture = logo(game_id)
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_fade, "color:a", 1.0, 0.35)
	if _fade_logo.texture:     # plansza tytułowa gry
		t.tween_property(_fade_logo, "modulate:a", 1.0, 0.35)
		t.tween_interval(0.9)
	await t.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	t = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	t.tween_property(_fade, "color:a", 0.0, 0.45)
	t.tween_property(_fade_logo, "modulate:a", 0.0, 0.3)
	_busy = false


## Ikona XMB: PNG (dostarczone ikony gier) albo SVG (Lucide).
func icon(name: String) -> Texture2D:
	var png := "res://menu/icons/%s.png" % name
	return load(png) if ResourceLoader.exists(png) else load("res://menu/icons/%s.svg" % name)


## Logo gry (assets/logos/<id>.webp) albo null.
func logo(game_id: String) -> Texture2D:
	var p := "res://assets/logos/%s.webp" % game_id
	return load(p) if ResourceLoader.exists(p) else null


## TextureRect z logo gry o zadanej szerokości (wysokość z proporcji).
func logo_rect(game_id: String, width: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = logo(game_id)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if t.texture:
		var s: Vector2 = t.texture.get_size()
		t.custom_minimum_size = Vector2(width, width * s.y / s.x)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func back_to_menu() -> void:
	go_to(MENU)


func _in_game() -> bool:
	var s := get_tree().current_scene
	return s != null and s.scene_file_path != MENU


func _input(event: InputEvent) -> void:
	var pad := event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.4)
	var kb := event is InputEventKey or event is InputEventMouseButton
	if (pad and not using_pad) or (kb and using_pad):
		using_pad = pad
		input_mode_changed.emit(pad)
	if _pause.visible and event.is_pressed():
		_pause.handle(event)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and _in_game() and not _busy and not _pause.visible:
		set_paused(true)
		get_viewport().set_input_as_handled()


func set_paused(p: bool) -> void:
	get_tree().paused = p
	if p:
		tone(520, 0.08)
		var path := get_tree().current_scene.scene_file_path
		var id := ""
		for k in GAMES:
			if GAMES[k] == path:
				id = k
		_pause.open(id)
	else:
		tone(440, 0.06)
		_pause.hide()


# ---------- szklane panele i winieta ----------

## Zamienia tło panelu na matowe szkło z rozmyciem tego, co pod spodem.
func glass(c: Control, margin := 22, radius := 18) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE          # maska wnętrza (shader podmienia na szkło)
	sb.border_color = Color(1, 0, 0)   # maska krawędzi
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = true
	c.add_theme_stylebox_override("panel", sb)
	var m := ShaderMaterial.new()
	m.shader = preload("res://core/glass.gdshader")
	c.material = m


## Dodaje winietę na całym ekranie pod podanym węzłem UI (zwykle na dole CanvasLayer).
func vignette(parent: Node, strength := 0.55) -> void:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = preload("res://core/vignette.gdshader")
	m.set_shader_parameter("strength", strength)
	r.material = m
	parent.add_child(r)
	parent.move_child(r, 0)


## Wjazd panelu: zanikanie + przesunięcie z boku.
func slide_in(c: Control, from := Vector2(-40, 0), delay := 0.0) -> void:
	c.modulate.a = 0.0
	await c.get_tree().process_frame     # poczekaj, aż kontenery policzą rozmiar i pozycję
	await c.get_tree().process_frame
	var t := c.create_tween().set_parallel()
	t.tween_property(c, "modulate:a", 1.0, 0.45).set_delay(delay)
	t.tween_property(c, "position", c.position, 0.55).from(c.position + from).set_delay(delay) 		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ---------- podpowiedzi przycisków (klawiatura / pad, przełączane automatycznie) ----------

## Klucze akcji → [ikony klawiatury/myszy, ikony pada Xbox]  (Kenney „Input Prompts”, CC0, assets/prompts/).
const GLYPHS := {
	"accept": [["keyboard_enter"], ["xbox_button_color_a"]],
	"back": [["keyboard_escape"], ["xbox_button_color_b"]],
	"x": [["keyboard_space"], ["xbox_button_color_x"]],
	"y": [["keyboard_r"], ["xbox_button_color_y"]],
	"pause": [["keyboard_escape"], ["xbox_button_menu"]],
	"lr": [["keyboard_arrows_horizontal"], ["xbox_dpad_horizontal"]],
	"ud": [["keyboard_arrows_vertical"], ["xbox_dpad_vertical"]],
	"rt": [["keyboard_w"], ["xbox_rt"]],
	"lt": [["keyboard_s"], ["xbox_lt"]],
	"lb_rb": [["keyboard_q", "keyboard_e"], ["xbox_lb", "xbox_rb"]],
	"stick_l": [["keyboard_arrows_horizontal"], ["xbox_stick_l"]],
	"stick_r": [["mouse_right"], ["xbox_stick_r"]],
	"grab": [["mouse_left"], ["xbox_rt"]],
	"mode": [["keyboard_tab"], ["xbox_button_color_y"]],
}


## Pasek podpowiedzi: items = [[klucz z GLYPHS, opis], ...]. Sam się przełącza przy zmianie urządzenia.
func hints(parent: Node, items: Array) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(h)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Arial"])
	var slots: Array = []
	for it in items:
		var g := HBoxContainer.new()
		g.add_theme_constant_override("separation", 4)
		h.add_child(g)
		var icons := HBoxContainer.new()
		icons.add_theme_constant_override("separation", 0)
		g.add_child(icons)
		var dl := Label.new()
		dl.text = it[1]
		dl.add_theme_font_override("font", font)
		dl.add_theme_font_size_override("font_size", 21)
		dl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		dl.add_theme_constant_override("shadow_offset_y", 2)
		g.add_child(dl)
		slots.append([it[0], icons])
	var apply := func(pad: bool):
		for sl in slots:
			var box: HBoxContainer = sl[1]
			for c in box.get_children():
				c.queue_free()
			for name in GLYPHS[sl[0]][1 if pad else 0]:
				var tr := TextureRect.new()
				tr.texture = load("res://assets/prompts/%s.png" % name)
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr.custom_minimum_size = Vector2(44, 44)
				box.add_child(tr)
	apply.call(using_pad)
	input_mode_changed.connect(apply)
	h.tree_exiting.connect(func(): input_mode_changed.disconnect(apply))
	return h


# ---------- dźwięk: krótkie tony generowane w pamięci ----------

func tone(freq: float, dur := 0.07, vol := 0.25, noise := 0.0) -> void:
	var key := "%d|%.3f|%.2f|%.2f" % [freq, dur, vol, noise]
	if not _tones.has(key):
		var rate := 44100
		var n := int(rate * dur)
		var data := PackedByteArray()
		data.resize(n * 2)
		for i in n:
			var t := float(i) / rate
			var env := exp(-t * 5.0 / dur) * minf(1.0, t / 0.004)
			var s := sin(TAU * freq * t) * (1.0 - noise) + randf_range(-1.0, 1.0) * noise
			data.encode_s16(i * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32767.0))
		var w := AudioStreamWAV.new()
		w.format = AudioStreamWAV.FORMAT_16_BITS
		w.mix_rate = rate
		w.data = data
		_tones[key] = w
	var p := AudioStreamPlayer.new()
	p.stream = _tones[key]
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


# ---------- wejście, motyw, nakładka ----------

func _bind(action: String, keys: Array, buttons: Array = [], axes: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		InputMap.action_add_event(action, e)
	for ax in axes:
		var e := InputEventJoypadMotion.new()
		e.axis = ax[0]
		e.axis_value = ax[1]
		InputMap.action_add_event(action, e)


func _setup_input() -> void:
	_bind("ui_left", [KEY_A])
	_bind("ui_right", [KEY_D])
	_bind("ui_up", [KEY_W])
	_bind("ui_down", [KEY_S])
	_bind("ui_cancel", [KEY_BACKSPACE])
	_bind("drive_forward", [KEY_W, KEY_UP], [], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	_bind("drive_back", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_TRIGGER_LEFT, 1.0]])
	_bind("steer_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_bind("steer_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_bind("handbrake", [KEY_SPACE], [JOY_BUTTON_X])
	_bind("reset_car", [KEY_R], [JOY_BUTTON_Y])
	_bind("pause", [KEY_ESCAPE], [JOY_BUTTON_START, JOY_BUTTON_GUIDE])
	_bind("ui_accept", [], [JOY_BUTTON_A])
	_bind("ui_cancel", [], [JOY_BUTTON_B])
	_bind("ui_left", [], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_bind("ui_right", [], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_bind("ui_up", [], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_bind("ui_down", [], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_bind("pad_prev", [KEY_Q], [JOY_BUTTON_LEFT_SHOULDER])
	_bind("pad_next", [KEY_E], [JOY_BUTTON_RIGHT_SHOULDER])
	_bind("pad_mode", [KEY_TAB], [JOY_BUTTON_Y])


func _setup_theme() -> void:
	var th := Theme.new()
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Segoe UI", "Arial", "Sans-Serif"])
	th.default_font = f
	th.default_font_size = 26
	var normal := _box(Color(0.08, 0.08, 0.1, 0.85), Color(1, 1, 1, 0.12))
	var hover := _box(Color(0.14, 0.14, 0.17, 0.9), Color(1, 1, 1, 0.3))
	var focus := _box(Color(0.14, 0.05, 0.07, 0.9), RED)
	for t in ["Button", "OptionButton"]:
		th.set_stylebox("normal", t, normal)
		th.set_stylebox("hover", t, hover)
		th.set_stylebox("pressed", t, focus)
		th.set_stylebox("focus", t, focus)
		th.set_stylebox("hover_pressed", t, focus)
	th.set_stylebox("panel", "PanelContainer", _box(Color(0.04, 0.04, 0.05, 0.82), Color(1, 1, 1, 0.08), 18))
	th.set_stylebox("panel", "Panel", _box(Color(0.04, 0.04, 0.05, 0.82), Color(1, 1, 1, 0.08), 18))
	var fill := _box(RED, RED, 4)
	th.set_stylebox("fill", "ProgressBar", fill)
	th.set_stylebox("background", "ProgressBar", _box(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 4))
	get_tree().root.theme = th
	ui_theme = th
	# Kontrolki pod CanvasLayer nie dziedziczą motywu okna — nadaj go korzeniom UI.
	get_tree().node_added.connect(func(n: Node):
		if n is Control and not (n.get_parent() is Control) and n.theme == null:
			n.theme = ui_theme)


func _box(bg: Color, border: Color, margin := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(margin)
	return s


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_pause = InGameXMB.new()
	layer.add_child(_pause)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	_fade_logo = TextureRect.new()
	_fade_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fade_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_fade_logo.anchor_left = 0.25
	_fade_logo.anchor_right = 0.75
	_fade_logo.anchor_top = 0.25
	_fade_logo.anchor_bottom = 0.75
	_fade_logo.modulate.a = 0.0
	_fade_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade_logo)
	# powiadomienie o osiągnięciu: ikona + trzy linie tekstu, wyśrodkowane u góry
	_toast = CenterContainer.new()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 36
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.hide()
	layer.add_child(_toast)
	var pc := PanelContainer.new()
	glass(pc, 18)
	_toast.add_child(pc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	pc.add_child(row)
	var ic := TextureRect.new()
	ic.texture = icon("trophy")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.custom_minimum_size = Vector2(72, 72)
	ic.modulate = Color(1, 0.85, 0.3)
	row.add_child(ic)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	for spec in [[16, Color(1, 0.45, 0.5)], [30, Color.WHITE], [20, Color(1, 1, 1, 0.8)]]:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", spec[0])
		l.add_theme_color_override("font_color", spec[1])
		col.add_child(l)
		_toast_lbls.append(l)


# ---------- tryb zrzutów: --shot=menu|paint|race|klamka [--delay=3] ----------

func _shot_mode() -> void:
	var which: String = args["shot"]
	var game := which.get_slice("_", 0)   # np. race_select -> scena wyścigu, ekran wyboru
	if GAMES.has(game):
		get_tree().change_scene_to_file(GAMES[game])
	if args.has("fps"):            # --fps: bez V-Sync, 1920×1080, średnia klatek z 3 s przed zrzutem
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
	await get_tree().create_timer(float(args.get("delay", "3"))).timeout
	if args.has("fps"):
		var f0 := Engine.get_frames_drawn()
		var t0 := Time.get_ticks_usec()
		await get_tree().create_timer(3.0).timeout
		print("FPS %.0f" % ((Engine.get_frames_drawn() - f0) / ((Time.get_ticks_usec() - t0) / 1e6)))
	if args.has("toast"):          # --toast: zrzut z powiadomieniem o osiągnięciu
		unlock("paint", "masochist")
		await get_tree().create_timer(0.6).timeout
	if args.has("pause"):         # --pause: zrzut nakładki XMB w grze
		set_paused(true)
		await get_tree().create_timer(0.8, true).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://shots")
	var path := "user://shots/%s.png" % which
	get_viewport().get_texture().get_image().save_png(path)
	print("SHOT ", ProjectSettings.globalize_path(path))
	get_tree().quit()
