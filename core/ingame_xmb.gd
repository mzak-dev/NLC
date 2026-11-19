class_name InGameXMB
extends Control
## Nakładka XMB w trakcie gry (jak menu wywoływane przyciskiem konsoli): rozmyta, przyciemniona gra,
## ta sama fala co w menu kolekcji, kategoria = bieżąca gra, pionowa lista opcji w stylu XMB, zegar,
## podpowiedzi przycisków. Sterowanie: ↑↓ / d-pad, ←→ zmienia wartość, A/Enter wybiera, B/Esc/Start wraca.

const ITEM_GAP := 96.0
const GAME_INFO := {
	"paint": ["Symulator schnięcia farby", "paint"],
	"race": ["Wyścigi kredensów", "race"],
	"klamka": ["Symulator naciskania klamki", "klamka"],
}

var items := [
	{"id": "resume", "icon": "play", "title": "Wznów grę", "desc": "Wróć dokładnie tam, gdzie było."},
	{"id": "restart", "icon": "restart", "title": "Zacznij od nowa", "desc": "Uruchom tę grę ponownie."},
	{"id": "volume", "icon": "volume", "title": "Głośność", "desc": "← → zmienia głośność"},
	{"id": "fullscreen", "icon": "fullscreen", "title": "Pełny ekran", "desc": "Wybierz, aby przełączyć"},
	{"id": "quit", "icon": "quit", "title": "Wyjdź do kolekcji", "desc": "Powrót do menu głównego."},
]
var sel := 0
var nodes: Array[Dictionary] = []
var cat_icon: TextureRect
var cat_label: Label
var clock: Label
var wave_mat: ShaderMaterial
var content: Control
var _tick := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var blur := ColorRect.new()          # rozmyta i przyciemniona klatka gry
	blur.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bm := ShaderMaterial.new()
	bm.shader = Shader.new()
	bm.shader.code = """shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, 4.0).rgb * 0.5 + textureLod(screen_tex, SCREEN_UV, 5.5).rgb * 0.5;
	COLOR = vec4(c * 0.45, 1.0);
}"""
	blur.material = bm
	add_child(blur)
	var wave := ColorRect.new()
	wave.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	wave_mat = ShaderMaterial.new()
	wave_mat.shader = preload("res://menu/xmb_wave.gdshader")
	wave.material = wave_mat
	wave.modulate.a = 0.55
	add_child(wave)
	content = Control.new()
	content.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(content)

	var cat := Control.new()
	content.add_child(cat)
	cat.position = Vector2(0, 0)
	cat_icon = TextureRect.new()
	cat_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cat_icon.size = Vector2(128, 128)
	cat.add_child(cat_icon)
	cat_label = _label(28, cat)
	cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_label.size = Vector2(420, 40)
	for it in items:
		var r := Control.new()
		content.add_child(r)
		var ic := TextureRect.new()
		ic.texture = Collection.icon(it.icon)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.size = Vector2(72, 72)
		ic.position = Vector2(-36, -36)
		r.add_child(ic)
		var t := _label(34, r)
		t.position = Vector2(62, -30)
		var d := _label(22, r)
		d.position = Vector2(64, 14)
		nodes.append({"root": r, "title": t, "desc": d})
	clock = _label(30, self)
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
	clock.offset_left = -420
	clock.offset_right = -60
	clock.offset_top = 40
	var bar := Collection.hints(self, [["ud", "Wybierz"], ["accept", "OK"], ["back", "Wróć do gry"]])
	bar.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT, PRESET_MODE_MINSIZE, 50)
	bar.grow_horizontal = GROW_DIRECTION_BEGIN
	bar.grow_vertical = GROW_DIRECTION_BEGIN
	hide()


func _label(size: int, parent: Control) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(l)
	return l


func open(game_id: String) -> void:
	var info: Array = GAME_INFO.get(game_id, ["Gra", "games"])
	cat_icon.texture = Collection.icon(info[1])
	cat_label.text = info[0]
	sel = 0
	_refresh()
	show()
	content.modulate.a = 0.0
	content.position = Vector2(-40, 0)
	var t := create_tween().set_parallel().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(content, "modulate:a", 1.0, 0.3)
	t.tween_property(content, "position", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_layout(1.0)


func _refresh() -> void:
	var now := Time.get_datetime_dict_from_system()
	clock.text = "%02d.%02d   %02d:%02d" % [now.day, now.month, now.hour, now.minute]
	for i in items.size():
		var it: Dictionary = items[i]
		var suffix := ""
		match it.id:
			"volume":
				suffix = "   ◀ %d%% ▶" % roundi(Collection.get_val("settings", "volume", 0.8) * 100)
			"fullscreen":
				suffix = "   " + ("Wł." if Collection.get_val("settings", "fullscreen", false) else "Wył.")
		nodes[i].title.text = it.title + suffix
		nodes[i].desc.text = it.desc


func _process(delta: float) -> void:
	if not visible:
		return
	_layout(1.0 - exp(-delta * 12.0))
	_tick += delta
	if _tick > 1.0:
		_tick = 0.0
		_refresh()


func _layout(k: float) -> void:
	var cx := size.x * 0.27
	var cy := size.y * 0.30
	cat_icon.position = Vector2(cx - 64, cy - 64)
	cat_label.position = Vector2(cx - 210, cy + 70)
	for i in nodes.size():
		var y: float
		if i >= sel:
			y = cy + 200.0 + (i - sel) * ITEM_GAP + (20.0 if i > sel else 0.0)
		else:
			y = cy - 130.0 - (sel - 1 - i) * ITEM_GAP
		var r: Control = nodes[i].root
		r.position = r.position.lerp(Vector2(cx, y), k)
		r.modulate.a = lerpf(r.modulate.a, 1.0 if i == sel else 0.45, k)
		var sc := 1.0 if i == sel else 0.82
		r.scale = r.scale.lerp(Vector2(sc, sc), k)
		nodes[i].desc.modulate.a = lerpf(nodes[i].desc.modulate.a, 0.8 if i == sel else 0.0, k)


func handle(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up", true):
		_move(-1)
	elif event.is_action_pressed("ui_down", true):
		_move(1)
	elif event.is_action_pressed("ui_left", true) or event.is_action_pressed("ui_right", true):
		if items[sel].id == "volume":
			var v: float = Collection.get_val("settings", "volume", 0.8)
			v = clampf(v + (0.1 if event.is_action("ui_right") else -0.1), 0.0, 1.0)
			Collection.set_val("settings", "volume", snappedf(v, 0.1))
			Collection.apply_settings()
			Collection.tone(880, 0.05)
			_refresh()
	elif event.is_action_pressed("ui_accept"):
		_activate(items[sel].id)
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		Collection.set_paused(false)


func _move(d: int) -> void:
	var n := clampi(sel + d, 0, items.size() - 1)
	if n != sel:
		sel = n
		Collection.tone(980, 0.04, 0.15)


func _activate(id: String) -> void:
	Collection.tone(660, 0.05)
	Collection.tone(990, 0.12, 0.2)
	match id:
		"resume":
			Collection.set_paused(false)
		"restart":
			Collection.go_to(get_tree().current_scene.scene_file_path)
		"fullscreen":
			Collection.set_val("settings", "fullscreen", not Collection.get_val("settings", "fullscreen", false))
			Collection.apply_settings()
			_refresh()
		"quit":
			Collection.back_to_menu()
