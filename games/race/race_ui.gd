class_name RaceUI
extends CanvasLayer
## Oprawa wyścigu inspirowana grami wyścigowymi z otwartym światem / torowymi (własna, bez cudzych znaków):
## • HUD: tabela pozycji z paskiem nagłówka, prędkościomierz-tarcza, karta czasu okrążenia, minimapa, łańcuch umiejętności.
## • Menu wyboru i wyniki: półprzezroczysty pas przez ekran z kafelkami i paskiem informacyjnym na dole.

const RED := Color(0.86, 0.07, 0.12)
const TILE_BG := Color(0.06, 0.06, 0.08, 0.62)
const SPEED_MAX := 45.0

var curve: Curve3D
var map: Dictionary
var track_lbl: Label
var track_map: Control
var italic: Font
var bold: Font
var light: Font
var regular: Font

# HUD
var hud: Control
var board_title: Label
var board_rows: Array[Dictionary] = []
var speedo: Control
var speed_val := 0.0
var pos_val := 1
var speed_lbl: Label
var minimap: Control
var map_dots: Array = []
var skill_box: VBoxContainer
var skill_pts_lbl: Label
var skill_name_lbl: Label
var center_lbl: Label
var info_lbl: Label

# wybór
var select_ui: Control
var preview: Node3D
var sel_name: Label
var sel_count: Label
var sel_desc: Label
var sel_bars := {}
var prof_wins: Label
var prof_best: Label
var prof_ring_wins: Control
var ring_wins := 0.0
var strip_lbls: Array[Label] = []

# wyniki
var results_ui: Control
var res_place: Label
var res_name: Label
var res_rows: VBoxContainer
var res_best: Label
var res_skill: Label
var res_note: Label
var res_first: Button


## Bahnschrift (font systemowy Windows, w stylu DIN) jako font zmienny: grubość przez oś „wght”.
## Bez sztucznego pochylenia — ono deformowało litery.
static func _weight(w: int) -> Font:
	var base := SystemFont.new()
	base.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Arial", "Sans-Serif"])
	var v := FontVariation.new()
	v.base_font = base
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): w}
	return v


func _init() -> void:
	light = _weight(300)
	regular = _weight(400)
	bold = _weight(700)
	italic = _weight(600)   # nazwa historyczna: font nagłówków (półgruby)


func build(actions: Array) -> void:
	_build_hud()
	_build_select()
	_build_results(actions)


# =====================================================================  pomocnicze

func _l(parent: Node, text: String, size: int, font: Font = null, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", font if font else regular)
	parent.add_child(l)
	return l


func _shadow(l: Label) -> Label:
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


## Kafelek: ciemne półprzezroczyste tło i czerwona kreska u góry.
func _tile(parent: Control, min_size := Vector2.ZERO, accent := true) -> VBoxContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = TILE_BG
	sb.border_color = RED
	sb.border_width_top = 3 if accent else 0
	sb.set_content_margin_all(22)
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = min_size
	parent.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	return v


## Pas przez cały ekran (matowe szkło), w którym siedzą kafelki — jak w menu gier torowych.
func _band(parent: Control) -> HBoxContainer:
	var band := PanelContainer.new()
	band.anchor_left = 0.0
	band.anchor_right = 1.0
	band.anchor_top = 0.2
	band.anchor_bottom = 0.8
	Collection.glass(band, 0, 0)
	parent.add_child(band)
	var center := CenterContainer.new()
	band.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	center.add_child(row)
	return row


func _logo(parent: Control) -> void:
	var t := Collection.logo_rect("race", 400)
	t.position = Vector2(100, 40)
	parent.add_child(t)


func _hints(parent: Control, items: Array) -> HBoxContainer:
	var h := Collection.hints(parent, items)
	h.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 60)
	h.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	h.grow_vertical = Control.GROW_DIRECTION_BEGIN
	return h


func _strip(parent: Control) -> void:
	var s := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.05, 0.85)
	sb.border_color = RED
	sb.border_width_top = 2
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	s.add_theme_stylebox_override("panel", sb)
	s.anchor_left = 0.0
	s.anchor_right = 1.0
	s.anchor_top = 1.0
	s.anchor_bottom = 1.0
	s.offset_top = -54
	parent.add_child(s)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 26)
	s.add_child(h)
	for i in 4:
		if i > 0:
			var sep := ColorRect.new()
			sep.color = Color(1, 1, 1, 0.25)
			sep.custom_minimum_size = Vector2(1, 0)
			h.add_child(sep)
		var l := _l(h, "", 20, null, Color(1, 1, 1, 0.85))
		strip_lbls.append(l)


func _bar_row(parent: Control, caption: String) -> ProgressBar:
	var r := HBoxContainer.new()
	parent.add_child(r)
	var l := _l(r, caption.to_upper(), 16, bold, Color(1, 1, 1, 0.7))
	l.custom_minimum_size = Vector2(150, 0)
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 1.0
	b.custom_minimum_size = Vector2(170, 10)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(b)
	return b


func _ring(parent: Control, get_frac: Callable) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(56, 56)
	c.draw.connect(func():
		var ctr := c.size * 0.5
		c.draw_arc(ctr, 22, 0, TAU, 48, Color(1, 1, 1, 0.15), 4, true)
		c.draw_arc(ctr, 22, -PI / 2, -PI / 2 + TAU * clampf(get_frac.call(), 0.0, 1.0), 48, Color(1, 1, 1, 0.95), 4, true))
	parent.add_child(c)
	return c


# =====================================================================  HUD w trakcie jazdy
# Czysty HUD wyścigów torowych: duże cienkie cyfry z małymi etykietami, skośne półprzezroczyste
# plakietki, minimapa jako sama linia trasy, cienki łuk prędkościomierza.

var place_lbl: Label
var place_of_lbl: Label
var lap_lbl: Label
var lap_of_lbl: Label
var race_time_lbl: Label
var best_lbl: Label
var badge: PanelContainer
var badge_lbl: Label
var race_t := 0.0
var cp_box: VBoxContainer
var cp_title: Label
var cp_time: Label


## Skośna plakietka (półprzezroczysta, jak w HUD-ach gier torowych).
func _slant(parent: Control, color := Color(0.05, 0.06, 0.08, 0.55), pad := Vector2(18, 4)) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.skew = Vector2(0.22, 0)
	sb.content_margin_left = pad.x
	sb.content_margin_right = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_bottom = pad.y
	pc.add_theme_stylebox_override("panel", sb)
	parent.add_child(pc)
	return pc


func _caption(parent: Control, text: String) -> Label:
	var l := _shadow(_l(parent, text, 17, bold, Color(1, 1, 1, 0.92)))
	l.uppercase = true
	return l


## Duża para liczb „2 | 4” z cienką kreską pomiędzy.
func _pair(parent: Control) -> Array:
	var box := _slant(parent, Color(0.05, 0.06, 0.08, 0.5), Vector2(16, 0))
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	box.add_child(h)
	var a := _shadow(_l(h, "1", 64, light))
	var bar := ColorRect.new()
	bar.color = Color(1, 1, 1, 0.8)
	bar.custom_minimum_size = Vector2(2, 0)
	bar.size_flags_vertical = Control.SIZE_FILL
	h.add_child(bar)
	var b := _shadow(_l(h, "4", 48, light, Color(1, 1, 1, 0.85)))
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	return [a, b]


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)

	# lewa góra: MIEJSCE 2 | 4 + plakietka zdarzeń
	var tl := VBoxContainer.new()
	tl.position = Vector2(70, 50)
	tl.add_theme_constant_override("separation", 2)
	hud.add_child(tl)
	_caption(tl, "Miejsce")
	var pp := _pair(tl)
	place_lbl = pp[0]
	place_of_lbl = pp[1]
	badge = _slant(tl, Color(0.86, 0.07, 0.12, 0.85), Vector2(12, 2))
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	badge_lbl = _l(badge, "", 17, bold)
	badge.modulate.a = 0.0

	# lewy dół: OKRĄŻENIE 1 | 3
	var bl := VBoxContainer.new()
	bl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 60)
	bl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bl.offset_left = 70
	bl.add_theme_constant_override("separation", 2)
	hud.add_child(bl)
	_caption(bl, "Okrążenie")
	var lp := _pair(bl)
	lap_lbl = lp[0]
	lap_of_lbl = lp[1]

	# lewa strona: minimapa (sama linia trasy, bez ramki)
	minimap = Control.new()
	minimap.custom_minimum_size = Vector2(260, 200)
	minimap.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE, 40)
	minimap.grow_vertical = Control.GROW_DIRECTION_BOTH
	minimap.draw.connect(_draw_minimap.bind(minimap, true))
	hud.add_child(minimap)

	# prawa góra: CZAS WYŚCIGU, NAJLEPSZE OKRĄŻENIE, tabela
	var tr := VBoxContainer.new()
	tr.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 50)
	tr.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tr.offset_right = -70
	tr.alignment = BoxContainer.ALIGNMENT_END
	tr.add_theme_constant_override("separation", 2)
	hud.add_child(tr)
	_caption(tr, "Czas wyścigu").size_flags_horizontal = Control.SIZE_SHRINK_END
	var tbox := _slant(tr, Color(0.05, 0.06, 0.08, 0.5), Vector2(18, 0))
	tbox.size_flags_horizontal = Control.SIZE_SHRINK_END
	race_time_lbl = _shadow(_l(tbox, "00:00.000", 56, light))
	var bcap := _caption(tr, "Najlepsze okrążenie")
	bcap.size_flags_horizontal = Control.SIZE_SHRINK_END
	var bbox := _slant(tr, Color(0.05, 0.06, 0.08, 0.5), Vector2(14, 0))
	bbox.size_flags_horizontal = Control.SIZE_SHRINK_END
	best_lbl = _shadow(_l(bbox, "--:--.---", 30, light))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	tr.add_child(gap)
	board_title = _caption(tr, "")
	board_title.size_flags_horizontal = Control.SIZE_SHRINK_END
	for i in 4:
		var row := _slant(tr, Color(0.05, 0.06, 0.08, 0.45), Vector2(12, 1))
		row.size_flags_horizontal = Control.SIZE_SHRINK_END
		row.custom_minimum_size = Vector2(330, 0)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		row.add_child(h)
		var pos := _l(h, str(i + 1), 18, bold)
		pos.custom_minimum_size = Vector2(18, 0)
		var nm := _l(h, "", 18, regular)
		nm.clip_text = true
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var g := _l(h, "", 17, regular, Color(1, 1, 1, 0.7))
		board_rows.append({"style": row.get_theme_stylebox("panel"), "pos": pos, "gap": g, "name": nm})

	# prawy dół: cienki łuk prędkości z dużą liczbą
	speedo = Control.new()
	speedo.custom_minimum_size = Vector2(240, 240)
	speedo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 50)
	speedo.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	speedo.grow_vertical = Control.GROW_DIRECTION_BEGIN
	speedo.draw.connect(_draw_speedo)
	hud.add_child(speedo)
	speed_lbl = _shadow(_l(speedo, "0", 80, light))
	speed_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_lbl.position = Vector2(20, 82)
	speed_lbl.size = Vector2(160, 90)
	var unit := _shadow(_l(speedo, "KM/H", 16, bold, Color(1, 1, 1, 0.8)))
	unit.position = Vector2(126, 168)

	# łańcuch umiejętności (góra, środek)
	skill_box = VBoxContainer.new()
	skill_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 60)
	skill_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	skill_box.alignment = BoxContainer.ALIGNMENT_CENTER
	skill_box.modulate.a = 0.0
	hud.add_child(skill_box)
	skill_pts_lbl = _shadow(_l(skill_box, "", 44, light, Color(1, 0.88, 0.3)))
	skill_pts_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_name_lbl = _shadow(_l(skill_box, "", 20, bold))
	skill_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	cp_box = VBoxContainer.new()
	cp_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 170)
	cp_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cp_box.add_theme_constant_override("separation", 2)
	cp_box.modulate.a = 0.0
	hud.add_child(cp_box)
	var cpt := _slant(cp_box, Color(0.86, 0.07, 0.12, 0.85), Vector2(18, 2))
	cpt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cp_title = _l(cpt, "", 18, bold)
	var cpv := _slant(cp_box, Color(0.05, 0.06, 0.08, 0.6), Vector2(18, 0))
	cpv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cp_time = _shadow(_l(cpv, "", 40, light))

	center_lbl = _shadow(_l(hud, "", 180, light))
	center_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	info_lbl = _shadow(_l(hud, "", 32, regular))
	info_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	info_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	info_lbl.position.y += 170
	var help := Collection.hints(hud, [["stick_l", "Skręt"], ["rt", "Gaz"], ["lt", "Hamulec"], ["x", "Ręczny"], ["y", "Postaw"], ["pause", "Menu"]])
	help.scale = Vector2(0.8, 0.8)
	help.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 14)
	help.grow_horizontal = Control.GROW_DIRECTION_BOTH
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	help.modulate.a = 0.7


func _draw_speedo() -> void:
	var c := Vector2(120, 120)
	var start := PI * 0.8
	var sweep := PI * 1.4
	var f := clampf(speed_val / SPEED_MAX, 0.0, 1.0)
	speedo.draw_arc(c, 104, start, start + sweep, 72, Color(0, 0, 0, 0.35), 14, true)
	speedo.draw_arc(c, 104, start, start + sweep, 72, Color(1, 1, 1, 0.22), 2, true)
	speedo.draw_arc(c, 104, start, start + sweep * f, 72, Color(1, 1, 1, 0.95), 4, true)
	for i in 10:   # krótkie kreski co 5 km/h na zewnątrz łuku
		var a := start + sweep * i / 9.0
		var dir := Vector2(cos(a), sin(a))
		speedo.draw_line(c + dir * 112, c + dir * (122 if i % 3 == 0 else 117), Color(1, 1, 1, 0.6), 2, true)
	var na := start + sweep * f
	speedo.draw_circle(c + Vector2(cos(na), sin(na)) * 104, 5, RED)


func _to_map(p: Vector2, area: Vector2) -> Vector2:
	var sz: Vector2 = map.size
	var s := minf(area.x / sz.x, area.y / sz.y)
	return (area - sz * s) * 0.5 + p * s


func _draw_minimap(ctl: Control, with_dots: bool) -> void:
	var a := ctl.size
	if not with_dots:   # kafelek w menu: tło + ściany
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.02, 0.02, 0.03, 0.55)
		sb.set_corner_radius_all(10)
		ctl.draw_style_box(sb, Rect2(Vector2.ZERO, a))
	var inner := a - Vector2(24, 24)
	var off := Vector2(12, 12)
	var pts := PackedVector2Array()
	var total := curve.get_baked_length()
	var d := 0.0
	while d <= total:
		var p := curve.sample_baked(d)
		pts.append(off + _to_map(Vector2(p.x, p.z), inner))
		d += 0.8
	pts.append(pts[0])
	if not with_dots:
		for w in map.walls:
			ctl.draw_line(off + _to_map(Vector2(w[0], w[1]), inner), off + _to_map(Vector2(w[2], w[3]), inner), Color(1, 1, 1, 0.22), 2)
	ctl.draw_polyline(pts, Color(0, 0, 0, 0.45), 7, true)
	ctl.draw_polyline(pts, Color(1, 1, 1, 0.9) if with_dots else Color(1, 0.3, 0.35, 0.9), 3, true)
	var st := curve.sample_baked(0.0)
	var sp := off + _to_map(Vector2(st.x, st.z), inner)
	ctl.draw_line(sp + Vector2(-7, 0), sp + Vector2(7, 0), RED, 4)
	if not with_dots:
		return
	for dot in map_dots:
		var mp := off + _to_map(dot.pos, inner)
		if dot.player:
			ctl.draw_circle(mp, 8, Color(0, 0, 0, 0.6))
			ctl.draw_circle(mp, 6, RED)
		else:
			ctl.draw_circle(mp, 5.5, Color(0, 0, 0, 0.6))
			ctl.draw_circle(mp, 4, Color.WHITE)


static func fmt_time(t: float) -> String:
	if t == INF or t < 0.0:
		return "--:--.---"
	return "%02d:%06.3f" % [int(t) / 60, fmod(t, 60.0)]


## d: lap, laps, pos, lap_t, race_t, best, speed, rows [{name, gap, player}], dots [{pos, dir, player}], flipped
func hud_update(d: Dictionary) -> void:
	for i in board_rows.size():
		var r: Dictionary = board_rows[i]
		var it: Dictionary = d.rows[i]
		r.name.text = it.name
		r.gap.text = it.gap
		var sb: StyleBoxFlat = r.style
		sb.bg_color = Color(0.86, 0.07, 0.12, 0.85) if it.player else Color(0.05, 0.06, 0.08, 0.45)
	speed_val = d.speed
	speed_lbl.text = str(roundi(d.speed))
	place_lbl.text = str(d.pos)
	place_of_lbl.text = str(d.rows.size())
	lap_lbl.text = str(d.lap)
	lap_of_lbl.text = str(d.laps)
	race_time_lbl.text = fmt_time(d.get("race_t", d.lap_t))
	best_lbl.text = fmt_time(d.best)
	if d.pos < pos_val and d.get("race_t", 0.0) > 2.0:
		_badge("DOBRE WYPRZEDZENIE")
	pos_val = d.pos
	map_dots = d.dots
	info_lbl.text = "Kredens leży!  [R] — postaw" if d.flipped else (info_lbl.text if not info_lbl.text.begins_with("Kredens") else "")
	speedo.queue_redraw()
	minimap.queue_redraw()


## Plakietka punktu kontrolnego: międzyczas i różnica do najlepszego okrążenia (zielona = szybciej).
func checkpoint(i: int, n: int, split: float, delta: float) -> void:
	cp_title.text = "PUNKT KONTROLNY  %d/%d" % [i, n]
	if is_nan(delta):
		cp_time.text = fmt_time(split)
		cp_time.add_theme_color_override("font_color", Color.WHITE)
	else:
		cp_time.text = "%s%.2f" % ["−" if delta <= 0.0 else "+", absf(delta)]
		cp_time.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45) if delta <= 0.0 else Color(1.0, 0.35, 0.3))
	cp_box.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.8)
	t.tween_property(cp_box, "modulate:a", 0.0, 0.4)


func _badge(text: String) -> void:
	badge_lbl.text = text
	var t := create_tween()
	t.tween_property(badge, "modulate:a", 1.0, 0.15)
	t.tween_interval(1.6)
	t.tween_property(badge, "modulate:a", 0.0, 0.4)


func center(text: String) -> void:
	center_lbl.text = text
	if text != "":
		center_lbl.pivot_offset = center_lbl.size * 0.5
		center_lbl.scale = Vector2(1.6, 1.6)
		create_tween().tween_property(center_lbl, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func flash(text: String) -> void:
	info_lbl.text = text
	get_tree().create_timer(2.0).timeout.connect(func():
		if info_lbl.text == text:
			info_lbl.text = "")


## Łańcuch umiejętności: punkty × mnożnik nad kredensem; znika, gdy łańcuch wygaśnie.
func skill(skill_name: String, pts: int, mult: float) -> void:
	skill_pts_lbl.text = "%d  ×%.1f" % [pts, mult]
	skill_name_lbl.text = "◆ " + skill_name if skill_name != "" else ""
	skill_box.modulate.a = 1.0 if skill_name != "" or pts > 0 else 0.0


func skill_bank(total: int) -> void:
	if total <= 0:
		skill_box.modulate.a = 0.0
		return
	skill_name_lbl.text = "ZALICZONE"
	var t := create_tween()
	t.tween_interval(0.8)
	t.tween_property(skill_box, "modulate:a", 0.0, 0.4)


# =====================================================================  wybór kredensu
# Układ jak „garaż” w grach z otwartym światem: świat w tle (kamera jedzie po trasie),
# przyciemnienie od lewej i od dołu, duży kredens na obrotowym podeście po prawej,
# informacje i osiągi po lewej, karta trasy w prawym górnym rogu, karuzela kredensów na dole.

var cards: Array[Dictionary] = []
var sel_wins: Label
var stat_vals := {}


func _shade(parent: Control, horizontal: bool, from_a: float, to_at: float) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.02, 0.03, from_a))
	g.set_color(1, Color(0.02, 0.02, 0.03, 0.0))
	g.set_offset(1, to_at)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 256
	if horizontal:
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(1, 0)
	else:
		gt.fill_from = Vector2(0, 1)
		gt.fill_to = Vector2(0, 0)
	var r := TextureRect.new()
	r.texture = gt
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)


func _build_select() -> void:
	select_ui = Control.new()
	select_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(select_ui)
	_shade(select_ui, true, 0.85, 0.62)
	_shade(select_ui, false, 0.8, 0.45)

	# duży podgląd kredensu (przezroczysty, na cały ekran — kredens stoi po prawej)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.anchor_left = 0.4
	svc.anchor_right = 0.78
	svc.anchor_top = 0.14
	svc.anchor_bottom = 0.8
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_ui.add_child(svc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	svc.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.8)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := SpotLight3D.new()            # punktowe światło z góry jak w salonie
	key.position = Vector3(1.2, 4.0, 1.5)
	key.look_at_from_position(key.position, Vector3(0, 0.6, 0))
	key.spot_angle = 30
	key.light_energy = 6.0
	key.shadow_enabled = true
	vp.add_child(key)
	var rim := DirectionalLight3D.new()     # kontra z tyłu w kolorze NRGeek
	rim.rotation_degrees = Vector3(-20, -150, 0)
	rim.light_color = Color(1.0, 0.35, 0.35)
	rim.light_energy = 0.8
	vp.add_child(rim)
	var podium := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.25
	disc.bottom_radius = 1.3
	disc.height = 0.06
	podium.mesh = disc
	podium.position.y = -0.24
	var pm := Apartment.mat(Color(0.18, 0.18, 0.2), 0.12)
	pm.metallic = 0.6
	podium.material_override = pm
	vp.add_child(podium)
	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.25
	tor.outer_radius = 1.29
	ring.mesh = tor
	ring.position.y = -0.2
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = RED
	ring.material_override = rm
	vp.add_child(ring)
	var pc := Camera3D.new()
	pc.fov = 30
	vp.add_child(pc)
	pc.look_at_from_position(Vector3(7.0, 2.2, 0), Vector3(0, 0.75, 0))
	preview = Node3D.new()
	vp.add_child(preview)

	_logo(select_ui)

	# lewa kolumna: nazwa, opis, osiągi
	var left := VBoxContainer.new()
	left.position = Vector2(120, 210)
	left.custom_minimum_size = Vector2(560, 0)
	left.add_theme_constant_override("separation", 8)
	select_ui.add_child(left)
	var top := HBoxContainer.new()
	left.add_child(top)
	_caption(top, "Wybierz kredens   ")
	sel_count = _caption(top, "")
	sel_count.add_theme_color_override("font_color", Color(1, 0.45, 0.5))
	sel_name = _shadow(_l(left, "", 54, bold))
	sel_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sel_name.custom_minimum_size = Vector2(560, 0)
	sel_desc = _shadow(_l(left, "", 21, regular, Color(1, 1, 1, 0.85)))
	sel_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sel_desc.custom_minimum_size = Vector2(560, 0)
	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	left.add_child(sep)
	_caption(left, "Osiągi")
	for k in ["Prędkość", "Przyspieszenie", "Prowadzenie", "Stabilność", "Masa"]:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 14)
		left.add_child(r)
		var l := _shadow(_l(r, k.to_upper(), 16, bold, Color(1, 1, 1, 0.75)))
		l.custom_minimum_size = Vector2(170, 0)
		var b := ProgressBar.new()
		b.show_percentage = false
		b.max_value = 1.0
		b.custom_minimum_size = Vector2(300, 8)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(b)
		stat_vals[k] = _shadow(_l(r, "", 18, light))
		sel_bars[k] = b
	sel_wins = _shadow(_l(left, "", 18, regular, Color(1, 1, 1, 0.7)))

	# prawy górny róg: karta trasy
	var trk := PanelContainer.new()
	Collection.glass(trk, 18, 12)
	trk.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 50)
	trk.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	select_ui.add_child(trk)
	var tv := VBoxContainer.new()
	trk.add_child(tv)
	var th := HBoxContainer.new()
	tv.add_child(th)
	_caption(th, "Trasa").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ud := TextureRect.new()
	ud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ud.custom_minimum_size = Vector2(30, 30)
	ud.texture = load("res://assets/prompts/keyboard_arrows_vertical.png")
	th.add_child(ud)
	Collection.input_mode_changed.connect(func(pad):
		ud.texture = load("res://assets/prompts/%s.png" % ("xbox_dpad_vertical" if pad else "keyboard_arrows_vertical")))
	track_lbl = _l(tv, "", 26, bold)
	track_map = Control.new()
	track_map.custom_minimum_size = Vector2(340, 210)
	track_map.draw.connect(_draw_minimap.bind(track_map, false))
	tv.add_child(track_map)

	# karuzela kredensów (dół)
	var car := HBoxContainer.new()
	car.add_theme_constant_override("separation", 10)
	car.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 0)
	car.grow_horizontal = Control.GROW_DIRECTION_BOTH
	car.grow_vertical = Control.GROW_DIRECTION_BEGIN
	car.offset_top = -190
	car.offset_bottom = -120
	select_ui.add_child(car)
	for i in Kredens.TYPES.size():
		var pc2 := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		sb.border_color = RED
		pc2.add_theme_stylebox_override("panel", sb)
		pc2.custom_minimum_size = Vector2(250, 66)
		car.add_child(pc2)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", -2)
		pc2.add_child(cv)
		var num := _l(cv, "%02d" % (i + 1), 15, bold)
		var nm := _l(cv, Kredens.TYPES[i].name, 18, regular)
		nm.clip_text = true
		cards.append({"panel": pc2, "style": sb, "num": num, "name": nm})

	_strip(select_ui)
	var hb := _hints(select_ui, [["ud", "Trasa"], ["lr", "Kredens"], ["accept", "Start"], ["pause", "Menu"]])
	hb.offset_bottom = -72


func set_select(ty: Dictionary, i: int, n: int, stats: Dictionary, wins_type: int, wins_all: int, best: float, track_best: float, laps: int) -> void:
	sel_name.text = ty.name
	sel_count.text = "%d / %d" % [i + 1, n]
	sel_desc.text = ty.desc
	sel_wins.text = "Wygrane tym kredensem: %d   ·   Rekord okrążenia: %s   ·   Wygrane łącznie: %d" % [
		wins_type, fmt_time(best) if best > 0 else "brak", wins_all]
	for k in stats:
		var v := clampf(stats[k], 0.05, 1.0)
		create_tween().tween_property(sel_bars[k], "value", v, 0.25)
		stat_vals[k].text = "%.1f" % (v * 10.0)
	for c in cards.size():
		var on := c == i
		var sb: StyleBoxFlat = cards[c].style
		sb.bg_color = Color(1, 1, 1, 0.92) if on else Color(0.04, 0.04, 0.06, 0.6)
		sb.border_width_top = 4 if on else 0
		var fg := Color(0.05, 0.05, 0.07) if on else Color(1, 1, 1, 0.8)
		cards[c].name.add_theme_color_override("font_color", fg)
		cards[c].num.add_theme_color_override("font_color", RED if on else Color(1, 1, 1, 0.5))
	for c in preview.get_children():
		c.queue_free()
	var m := Kredens.build_model(ty)
	m.position.y = -0.2
	preview.add_child(m)
	var dd := Time.get_date_dict_from_system()
	var months := ["sty", "lut", "mar", "kwi", "maj", "cze", "lip", "sie", "wrz", "paź", "lis", "gru"]
	strip_lbls[0].text = "%d %s" % [dd.day, months[dd.month - 1]]
	strip_lbls[1].text = "Lokalizacja: " + map.place
	strip_lbls[2].text = "Okrążenia: %d" % laps
	strip_lbls[3].text = "Rekord toru: %s · sąsiedzi już dzwonią" % (fmt_time(track_best) if track_best > 0 else "brak")


# =====================================================================  wyniki

func _build_results(actions: Array) -> void:
	results_ui = Control.new()
	results_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	results_ui.hide()
	add_child(results_ui)
	_logo(results_ui)
	var row := _band(results_ui)
	var left := _tile(row, Vector2(380, 470))
	_l(left, "TWOJE MIEJSCE", 20, bold, Color(1, 1, 1, 0.7))
	res_place = _l(left, "1.", 150, italic)
	res_name = _l(left, "", 22, italic)
	res_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	res_name.custom_minimum_size = Vector2(330, 0)
	res_note = _l(left, "", 18, bold, Color(1, 0.85, 0.3))
	res_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	res_note.custom_minimum_size = Vector2(330, 0)

	var mid := _tile(row, Vector2(640, 470))
	_l(mid, "KLASYFIKACJA", 24, italic)
	res_rows = VBoxContainer.new()
	res_rows.add_theme_constant_override("separation", 6)
	mid.add_child(res_rows)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	row.add_child(col)
	var t1 := _tile(col, Vector2(380, 110))
	_l(t1, "NAJLEPSZE OKRĄŻENIE", 16, bold, Color(1, 1, 1, 0.7))
	res_best = _l(t1, "", 40, italic)
	var t2 := _tile(col, Vector2(380, 110))
	_l(t2, "PUNKTY UMIEJĘTNOŚCI", 16, bold, Color(1, 1, 1, 0.7))
	res_skill = _l(t2, "", 40, italic, Color(1, 0.9, 0.3))
	for a in actions:
		var b := Button.new()
		b.text = a[0]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(380, 64)
		b.add_theme_font_override("font", italic)
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(a[1])
		col.add_child(b)
		if res_first == null:
			res_first = b
	_hints(results_ui, [["ud", "Wybierz"], ["accept", "OK"], ["pause", "Menu"]])


## rows: [{name, time, player}] w kolejności miejsc.
func show_results(place: int, my_name: String, rows: Array, best: float, skill_pts: int, note: String) -> void:
	hud.hide()
	results_ui.show()
	res_place.text = "%d." % place
	res_name.text = my_name
	res_note.text = note
	res_best.text = fmt_time(best)
	res_skill.text = str(skill_pts)
	for c in res_rows.get_children():
		c.queue_free()
	for i in rows.size():
		var r: Dictionary = rows[i]
		var p := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.88) if r.player else Color(1, 1, 1, 0.06)
		sb.set_content_margin_all(10)
		p.add_theme_stylebox_override("panel", sb)
		res_rows.add_child(p)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		p.add_child(h)
		var fg := Color(0.05, 0.05, 0.07) if r.player else Color.WHITE
		var num := _l(h, "%d" % (i + 1), 24, italic, RED if i == 0 else fg)
		num.custom_minimum_size = Vector2(30, 0)
		var n := _l(h, r.name, 22, null, fg)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		_l(h, r.time, 22, bold, fg)
	res_first.grab_focus()
	Collection.slide_in(results_ui, Vector2(0, 30))


func show_select() -> void:
	hud.hide()
	results_ui.hide()
	select_ui.show()
	Collection.slide_in(select_ui, Vector2(0, 30))


func show_hud() -> void:
	select_ui.hide()
	results_ui.hide()
	hud.show()


func _process(dt: float) -> void:
	if select_ui.visible:
		preview.rotation.y += dt * 0.6


## Ustawia bieżącą mapę: minimapy, tytuł tabeli i kafelek trasy.
func set_map(m: Dictionary, c: Curve3D) -> void:
	map = m
	curve = c
	board_title.text = m.name
	track_lbl.text = m.name
	track_map.queue_redraw()
	minimap.queue_redraw()
