extends Control
## Menu w stylu XMB: kategorie poziomo, pozycje pionowo, fala w tle, zegar, intro.

const CAT_GAP := 240.0
const ITEM_GAP := 104.0

var cats: Array[Dictionary] = []
var cat_i := 1
var item_i: Array[int] = []
var cat_nodes: Array[Dictionary] = []
var item_nodes: Array = []          # [kategoria][pozycja] -> Dictionary węzłów
var editing := false
var content: Control
var popup: PanelContainer
var popup_text: RichTextLabel
var clock: Label
var bg_mat: ShaderMaterial
var _tick := 0.0
var logo_view: TextureRect
var _logo_id := ""


func _ready() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	bg_mat = ShaderMaterial.new()
	bg_mat.shader = preload("res://menu/xmb_wave.gdshader")
	bg.material = bg_mat
	add_child(bg)
	content = Control.new()
	content.set_anchors_preset(PRESET_FULL_RECT)
	content.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(content)
	_define()
	_build()
	_refresh_texts()
	_layout(1.0)
	if Collection.args.get("shot", "") == "menu_trophies":
		cat_i = 2
		_show_achievements("paint")
	if Collection.intro_done:
		return
	Collection.intro_done = true
	_intro()


func _define() -> void:
	cats = [
		{"name": "Ustawienia", "icon": "settings", "items": [
			{"id": "volume", "icon": "volume", "title": "Głośność", "desc": "Enter, potem ← / → zmienia głośność"},
			{"id": "fullscreen", "icon": "fullscreen", "title": "Pełny ekran", "desc": "Enter przełącza"},
			{"id": "vsync", "icon": "vsync", "title": "Synchronizacja pionowa", "desc": "Enter przełącza"},
			{"id": "driving_line", "icon": "race", "title": "Linia jazdy (wyścigi)", "desc": "Strzałki na torze: zielone OK, czerwone hamuj"},
			{"id": "quit", "icon": "power", "title": "Wyłącz kolekcję", "desc": "Farba i tak będzie schnąć dalej."},
		]},
		{"name": "Gry", "icon": "games", "items": [
			{"id": "paint", "icon": "paint", "title": "Symulator schnięcia farby",
				"desc": "Pomaluj ścianę. Poczekaj. Naprawdę poczekaj."},
			{"id": "race", "icon": "race", "title": "Wyścigi kredensów",
				"desc": "Pięć kredensów, jedno mieszkanie, zero litości dla parkietu."},
			{"id": "klamka", "icon": "klamka", "title": "Symulator naciskania klamki",
				"desc": "Zaawansowana fizyka sprężyny powrotnej. Naciskaj odpowiedzialnie."},
		]},
		{"name": "Osiągnięcia", "icon": "trophy", "items": Achievements.GAMES.keys().map(func(g: String) -> Dictionary:
			return {"id": "ach_" + g, "icon": g if Collection.GAMES.has(g) else "trophy", "title": Achievements.GAMES[g], "desc": ""})},
		{"name": "Informacje", "icon": "info", "items": [
			{"id": "about", "icon": "about", "title": "O kolekcji", "desc": "Skąd to się wzięło"},
			{"id": "book", "icon": "book", "title": "Książka „Retrospekcje”", "desc": "ksiazkanrgeek.pl"},
			{"id": "yt", "icon": "tv", "title": "Kanał NRGeek", "desc": "youtube.com/@NRGeek00"},
		]},
	]
	item_i.resize(cats.size())
	item_i.fill(0)


func _icon(name: String) -> Texture2D:
	return Collection.icon(name)


func _label(size: int, parent: Control) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(l)
	return l


func _build() -> void:
	for c in cats.size():
		var root := Control.new()
		content.add_child(root)
		var icon := TextureRect.new()
		icon.texture = _icon(cats[c]["icon"])
		icon.size = Vector2(128, 128)
		icon.position = Vector2(-64, -64)
		icon.pivot_offset = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		root.add_child(icon)
		var lbl := _label(28, root)
		lbl.text = cats[c]["name"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size = Vector2(320, 40)
		lbl.position = Vector2(-160, 70)
		cat_nodes.append({"root": root, "icon": icon, "label": lbl})
		var row: Array[Dictionary] = []
		for it in cats[c]["items"]:
			var r := Control.new()
			content.add_child(r)
			var ic := TextureRect.new()
			ic.texture = _icon(it.get("icon", cats[c]["icon"]))
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.size = Vector2(76, 76)
			ic.position = Vector2(-38, -38)
			r.add_child(ic)
			var title := _label(34, r)
			title.position = Vector2(64, -30)
			var desc := _label(22, r)
			desc.position = Vector2(66, 14)
			desc.modulate = Color(1, 1, 1, 0.75)
			row.append({"root": r, "title": title, "desc": desc})
		item_nodes.append(row)
	var hb := Collection.hints(self, [["lr", "Kategoria"], ["ud", "Wybierz"], ["accept", "Uruchom"], ["back", "Wstecz"]])
	hb.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT, PRESET_MODE_MINSIZE, 50)
	hb.grow_horizontal = GROW_DIRECTION_BEGIN
	hb.grow_vertical = GROW_DIRECTION_BEGIN
	logo_view = TextureRect.new()
	logo_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_view.anchor_left = 0.56
	logo_view.anchor_right = 0.95
	logo_view.anchor_top = 0.42
	logo_view.anchor_bottom = 0.82
	logo_view.mouse_filter = MOUSE_FILTER_IGNORE
	logo_view.modulate.a = 0.0
	content.add_child(logo_view)
	clock = _label(30, self)
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
	clock.offset_left = -420
	clock.offset_right = -60
	clock.offset_top = 40
	popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(900, 0)
	popup.set_anchors_and_offsets_preset(PRESET_CENTER)
	popup.grow_horizontal = GROW_DIRECTION_BOTH
	popup.grow_vertical = GROW_DIRECTION_BOTH
	popup.add_theme_stylebox_override("panel", Collection._box(Color(0.04, 0.04, 0.05, 0.985), Color(1, 1, 1, 0.12), 24))
	popup.hide()
	popup_text = RichTextLabel.new()
	popup_text.bbcode_enabled = true
	popup_text.fit_content = true
	popup.add_child(popup_text)
	add_child(popup)


func _refresh_texts() -> void:
	var now := Time.get_datetime_dict_from_system()
	clock.text = "%02d.%02d   %02d:%02d" % [now.day, now.month, now.hour, now.minute]
	# jasność tła zależna od pory dnia (najjaśniej ~10:00, najciemniej ~2:00 — jak w PS3)
	var h: float = now.hour + now.minute / 60.0
	bg_mat.set_shader_parameter("brightness", 0.82 + 0.18 * cos((h - 10.0) / 24.0 * TAU))
	for c in cats.size():
		for i in cats[c]["items"].size():
			var it: Dictionary = cats[c]["items"][i]
			var n: Dictionary = item_nodes[c][i]
			n.title.text = it.title + _value_suffix(it.id)
			n.desc.text = it.desc + _live_info(it.id)


func _value_suffix(id: String) -> String:
	match id:
		"volume":
			var v: float = Collection.get_val("settings", "volume", 0.8)
			return "   %s%d%%%s" % ["◀ " if editing else "", roundi(v * 100), " ▶" if editing else ""]
		"fullscreen":
			return "   " + ("Wł." if Collection.get_val("settings", "fullscreen", false) else "Wył.")
		"vsync":
			return "   " + ("Wł." if Collection.get_val("settings", "vsync", true) else "Wył.")
		"driving_line":
			return "   " + ("Wł." if Collection.get_val("settings", "driving_line", true) else "Wył.")
	return ""


func _live_info(id: String) -> String:
	if id.begins_with("ach_"):
		var g := id.trim_prefix("ach_")
		return "%d / %d odblokowanych" % [Achievements.count(g, Collection.save), Achievements.LIST[g].size()]
	match id:
		"paint":
			var drying := 0
			var soonest := INF
			for w in PaintTime.WALLS.size():
				if Collection.get_val("paint", PaintTime.key(w, "state"), "") != "drying":
					continue
				var p := PaintTime.find(Collection.get_val("paint", PaintTime.key(w, "paint_id"), "acrylic"))
				var left := PaintTime.remaining(Collection.get_val("paint", PaintTime.key(w, "start_unix"), 0.0), p.secs,
						Time.get_unix_time_from_system(), PaintTime.speed())
				if left <= 0.0:
					return "\nFarba wyschła! Wejdź i zobacz."
				drying += 1
				soonest = minf(soonest, left)
			if drying > 0:
				return "\nSchnących ścian: %d, najbliższa za %s" % [drying, PaintTime.fmt(soonest)]
			var dried: int = Collection.get_val("paint", "dried", 0)
			return "\nWyschniętych ścian: %d" % dried if dried > 0 else ""
		"race":
			var best: float = Collection.get_val("race", "best_lap_any", 0.0)
			return "\nNajlepsze okrążenie: %.2f s" % best if best > 0 else ""
		"klamka":
			var rec: int = Collection.get_val("klamka", "record_bounces", 0)
			return "\nRekord odbić: %d" % rec if rec > 0 else ""
	return ""


func _process(delta: float) -> void:
	_layout(1.0 - exp(-delta * 11.0))
	# logo wybranej gry (jak plansza gry w XMB)
	var id: String = cats[cat_i]["items"][item_i[cat_i]]["id"]
	var want := id if Collection.GAMES.has(id) else ""
	if want != _logo_id:
		_logo_id = want
		if want != "":
			logo_view.texture = Collection.logo(want)
			logo_view.modulate.a = 0.0
			logo_view.position.x = 40.0
	var tgt := 1.0 if _logo_id != "" else 0.0
	logo_view.modulate.a = move_toward(logo_view.modulate.a, tgt, delta * 4.0)
	logo_view.position.x = lerpf(logo_view.position.x, logo_view.anchor_left * size.x, 1.0 - exp(-delta * 8.0))
	_tick += delta
	if _tick > 1.0:
		_tick = 0.0
		_refresh_texts()


func _layout(k: float) -> void:
	var sz := size
	var cx := sz.x * 0.27
	var cy := sz.y * 0.30
	for c in cats.size():
		var n: Dictionary = cat_nodes[c]
		var sel := c == cat_i
		var root: Control = n.root
		root.position = root.position.lerp(Vector2(cx + (c - cat_i) * CAT_GAP, cy), k)
		var s := 1.0 if sel else 0.68
		n.icon.scale = n.icon.scale.lerp(Vector2(s, s), k)
		root.modulate.a = lerpf(root.modulate.a, 1.0 if sel else 0.55, k)
		n.label.modulate.a = lerpf(n.label.modulate.a, 1.0 if sel else 0.0, k)
		for i in item_nodes[c].size():
			var it: Dictionary = item_nodes[c][i]
			var si := item_i[c]
			var y: float
			if i >= si:
				y = cy + 200.0 + (i - si) * ITEM_GAP + (24.0 if i > si else 0.0)
			else:
				y = cy - 140.0 - (si - 1 - i) * ITEM_GAP
			var r: Control = it.root
			r.position = r.position.lerp(Vector2(cx + (c - cat_i) * CAT_GAP, y), k)
			var a := 0.0
			if sel:
				a = 1.0 if i == si else 0.5
			r.modulate.a = lerpf(r.modulate.a, a, k)
			var sc := 1.0 if (sel and i == si) else 0.82
			r.scale = r.scale.lerp(Vector2(sc, sc), k)
			it.desc.modulate.a = lerpf(it.desc.modulate.a, 0.8 if (sel and i == si) else 0.0, k)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if popup.visible:
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_move_item(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_move_item(1)
		return
	if popup.visible:
		if event.is_action_pressed("ui_up", true) or event.is_action_pressed("ui_down", true):
			popup_text.get_v_scroll_bar().value += 120.0 if event.is_action("ui_down") else -120.0
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			popup.hide()
			Collection.tone(440, 0.06)
		return
	if editing:
		if event.is_action_pressed("ui_left", true) or event.is_action_pressed("ui_right", true):
			var v: float = Collection.get_val("settings", "volume", 0.8)
			v = clampf(v + (0.1 if event.is_action("ui_right") else -0.1), 0.0, 1.0)
			Collection.set_val("settings", "volume", snappedf(v, 0.1))
			Collection.apply_settings()
			Collection.tone(880, 0.05)
			_refresh_texts()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			editing = false
			Collection.tone(660, 0.06)
			_refresh_texts()
		return
	if event.is_action_pressed("ui_left", true):
		_move_cat(-1)
	elif event.is_action_pressed("ui_right", true):
		_move_cat(1)
	elif event.is_action_pressed("ui_up", true):
		_move_item(-1)
	elif event.is_action_pressed("ui_down", true):
		_move_item(1)
	elif event.is_action_pressed("ui_accept"):
		_activate(cats[cat_i]["items"][item_i[cat_i]]["id"])


func _move_cat(d: int) -> void:
	var n := clampi(cat_i + d, 0, cats.size() - 1)
	if n != cat_i:
		cat_i = n
		Collection.tone(760, 0.05, 0.18)


func _move_item(d: int) -> void:
	var n := clampi(item_i[cat_i] + d, 0, cats[cat_i]["items"].size() - 1)
	if n != item_i[cat_i]:
		item_i[cat_i] = n
		Collection.tone(980, 0.04, 0.15)


func _activate(id: String) -> void:
	Collection.tone(660, 0.05)
	Collection.tone(990, 0.12, 0.2)
	match id:
		"paint", "race", "klamka":
			Collection.go_to(Collection.GAMES[id])
		"volume":
			editing = true
		"fullscreen", "vsync", "driving_line":
			var def := id != "fullscreen"
			Collection.set_val("settings", id, not Collection.get_val("settings", id, def))
			Collection.apply_settings()
		"quit":
			get_tree().quit()
		"book":
			OS.shell_open("https://www.ksiazkanrgeek.pl")
		"yt":
			OS.shell_open("https://www.youtube.com/@NRGeek00")
		_ when id.begins_with("ach_"):
			_show_achievements(id.trim_prefix("ach_"))
		"about":
			_popup_scroll(false)
			popup_text.text = "[font_size=40][b]NRGeek Legacy Collection[/b][/font_size]\n\n" \
				+ "NRGeek kiedyś poprosił o takie gry. Nikt nie odpowiedział na wezwanie.\nAż do teraz.\n\n" \
				+ "• Symulator schnięcia farby — farba schnie w czasie rzeczywistym, także przy wyłączonej grze.\n" \
				+ "• Wyścigi kredensów — kredensy na kółkach meblowych, pięć okrążeń po M3.\n" \
				+ "• Symulator naciskania klamki — sprężyna, tłumienie, odbicia, wykres.\n\n" \
				+ "[color=#ffffff99]Fanowski projekt. Enter / Esc zamyka.[/color]"
			popup.show()
	_refresh_texts()


## Popup dopasowany do treści (krótki tekst) albo o stałej wysokości z przewijaniem (lista).
func _popup_scroll(on: bool) -> void:
	popup_text.fit_content = not on
	popup_text.scroll_active = on
	popup_text.custom_minimum_size.y = 780.0 if on else 0.0
	popup.set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_MINSIZE)   # wyśrodkuj dla nowej wysokości


func _show_achievements(game: String) -> void:
	var list: Array = Achievements.LIST[game]
	var s := "[font_size=40][b]%s[/b][/font_size]   [color=#ffffff99]%d / %d[/color]\n" % [
		Achievements.GAMES[game], Achievements.count(game, Collection.save), list.size()]
	var bias: int = Time.get_time_zone_from_system().bias * 60
	for a in list:
		var at: float = Collection.get_val("ach", Achievements.key(game, a.id), 0.0)
		if at > 0.0:
			var d := Time.get_datetime_dict_from_unix_time(int(at) + bias)
			s += "\n[color=#ffd94d]★[/color]  [b]%s[/b]   [color=#ffffff66][font_size=18]%02d.%02d.%d[/font_size][/color]\n" % [a.title, d.day, d.month, d.year]
			s += "[color=#ffffffcc][font_size=22]%s[/font_size][/color]\n" % a.desc
		else:
			var secret: bool = a.get("secret", false)
			s += "\n[color=#ffffff55]☆  [b]%s[/b]\n[font_size=22]%s[/font_size][/color]\n" % [
				"???" if secret else a.title, "Sekretne. Domyśl się." if secret else a.desc]
	s += "\n[color=#ffffff99][font_size=20]↑ / ↓ przewija  ·  Enter / Esc zamyka[/font_size][/color]"
	_popup_scroll(true)
	popup_text.text = s
	popup_text.scroll_to_line(0)
	popup.show()


func _intro() -> void:
	content.modulate.a = 0.0
	clock.modulate.a = 0.0
	var logo := RichTextLabel.new()
	logo.bbcode_enabled = true
	logo.fit_content = true
	logo.scroll_active = false
	logo.set_anchors_and_offsets_preset(PRESET_CENTER)
	logo.custom_minimum_size = Vector2(1000, 0)
	logo.grow_horizontal = GROW_DIRECTION_BOTH
	logo.grow_vertical = GROW_DIRECTION_BOTH
	logo.text = "[center][font_size=150][b]NR[color=#dd1220]GEEK[/color][/b][/font_size]\n" \
		+ "[font_size=34][color=#ffffffaa]L E G A C Y   C O L L E C T I O N[/color][/font_size][/center]"
	logo.modulate.a = 0.0
	add_child(logo)
	var t := create_tween()
	t.tween_property(logo, "modulate:a", 1.0, 0.9)
	t.tween_callback(Collection.tone.bind(392, 0.9, 0.18))
	t.tween_interval(1.3)
	t.tween_property(logo, "modulate:a", 0.0, 0.6)
	t.tween_callback(logo.queue_free)
	t.tween_property(content, "modulate:a", 1.0, 0.7)
	t.parallel().tween_property(clock, "modulate:a", 1.0, 0.7)
