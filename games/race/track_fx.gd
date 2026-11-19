class_name TrackFX
extends Node3D
## Linia jazdy z podpowiedzią hamowania (jak w Forzie) i bramki punktów kontrolnych.
##
## Linia: strzałki na podłodze przed kredensem gracza. Kolor mówi, czy przy obecnej prędkości
## wyrobisz się w nadchodzący zakręt: zielony = OK, żółty = odpuść gaz, czerwony = hamuj.
## Dopuszczalna prędkość w każdym punkcie trasy:
##   v_zakręt = sqrt(a_boczne / krzywizna),  potem przejście wstecz po pętli:
##   v_dop[i] = min(v_zakręt[i], sqrt(v_dop[i+1]² + 2·opóźnienie·krok))  — czyli „zdążysz wyhamować”.

const STEP := 0.5           # m między próbkami profilu prędkości
const CHEVRON_GAP := 1.6    # m między strzałkami
const LINE_AHEAD := 34.0    # m linii przed graczem
const CHECKPOINTS := 5

var curve: Curve3D
var length := 0.0
var v_allowed := PackedFloat32Array()
var cps := PackedFloat32Array()        # offsety punktów kontrolnych (bez startu/mety)
var gates: Array[Dictionary] = []
var show_line := true
var _im := ImmediateMesh.new()
var _line: MeshInstance3D


func setup(c: Curve3D, a_lat: float, decel: float) -> void:
	curve = c
	length = c.get_baked_length()
	_profile(a_lat, decel)
	_line = MeshInstance3D.new()
	_line.mesh = _im
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	_line.material_override = m
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)
	for i in CHECKPOINTS:
		cps.append(length * (i + 1) / (CHECKPOINTS + 1))
	_gate(0.0, true)
	for o in cps:
		_gate(o, false)


## Przelicza profil prędkości pod konkretny kredens (przyczepność, hamulce).
func reprofile(a_lat: float, decel: float) -> void:
	_profile(a_lat, decel)


func _dir(o: float) -> Vector3:
	var a := curve.sample_baked(fposmod(o - 0.25, length))
	var b := curve.sample_baked(fposmod(o + 0.25, length))
	return (b - a).normalized()


func _profile(a_lat: float, decel: float) -> void:
	var n := int(length / STEP)
	v_allowed.resize(n)
	for i in n:
		var o := i * STEP
		var ang := absf(_dir(o - 1.5).signed_angle_to(_dir(o + 1.5), Vector3.UP))
		var k := ang / 3.0                                       # krzywizna [1/m]
		v_allowed[i] = clampf(sqrt(a_lat / maxf(k, 0.0005)), 1.5, 40.0)
	for _pass in 2:                                              # pętla: dwa przebiegi wstecz
		for j in range(n - 1, -1, -1):
			var nxt := v_allowed[(j + 1) % n]
			v_allowed[j] = minf(v_allowed[j], sqrt(nxt * nxt + 2.0 * decel * STEP))


## Dopuszczalna prędkość [m/s] w punkcie trasy.
func allowed(o: float) -> float:
	return v_allowed[int(fposmod(o, length) / STEP) % v_allowed.size()]


static func color_for(ratio: float) -> Color:
	if ratio < 0.9:
		return Color(0.2, 0.95, 0.35)
	if ratio < 1.05:
		return Color(1.0, 0.85, 0.15)
	return Color(1.0, 0.15, 0.12)


## Przerysowuje strzałki przed graczem. off = pozycja gracza na trasie, speed w m/s.
func update_line(off: float, speed: float) -> void:
	_im.clear_surfaces()
	if not show_line:
		return
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var d := 3.5 - fposmod(off, CHEVRON_GAP)
	while d < LINE_AHEAD:
		var o := off + d
		var p := curve.sample_baked(fposmod(o, length)) + Vector3.UP * 0.03
		var f := _dir(o)
		var s := Vector3(f.z, 0, -f.x)
		var c := color_for(speed / allowed(o))
		c.a = lerpf(0.95, 0.25, d / LINE_AHEAD)
		# najpierw ciemna, szersza obwódka (czytelność na czerwonych kafelkach), potem kolor
		for layer in 2:
			var outline := layer == 0
			_im.surface_set_color(Color(0, 0, 0, c.a * 0.6) if outline else c)
			var grow := 0.09 if outline else 0.0
			var lift := Vector3.UP * (0.0 if outline else 0.005)
			var tip := p + f * (0.3 + grow) + lift
			for side in [1.0, -1.0]:          # ramię strzałki „>” jako czworokąt
				var back: Vector3 = p - f * (0.5 + grow) + s * (0.85 + grow) * side + lift
				var w: Vector3 = s * (0.2 + grow) * side
				for v in [tip - w, tip + w, back + w, tip - w, back + w, back - w]:
					_im.surface_add_vertex(v)
		d += CHEVRON_GAP
	_im.surface_end()


# ---------- bramki ----------

func _gate(o: float, start: bool) -> void:
	var g := Node3D.new()
	var p := curve.sample_baked(fposmod(o, length))
	var f := _dir(o)
	g.transform = Transform3D(Basis.looking_at(f, Vector3.UP), p)
	add_child(g)
	var col := Color(1, 1, 1) if start else Collection.RED
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(col, 0.75)
	var post := StandardMaterial3D.new()
	post.albedo_color = Color(0.12, 0.12, 0.14)
	post.metallic = 0.6
	post.roughness = 0.3
	for side in [-1.3, 1.3]:
		_box(g, Vector3(0.1, 2.1, 0.1), Vector3(side, 1.05, 0), post)
		_box(g, Vector3(0.03, 1.9, 0.12), Vector3(side, 1.0, 0), glow)
	_box(g, Vector3(2.7, 0.32, 0.06), Vector3(0, 2.15, 0), glow)
	var l := Label3D.new()
	l.text = "START / META" if start else "PUNKT KONTROLNY"
	l.font_size = 40
	l.pixel_size = 0.004
	l.modulate = Color(0.05, 0.05, 0.07) if start else Color.WHITE
	l.outline_size = 0
	l.position = Vector3(0, 2.15, 0.04)       # strona widoczna dla nadjeżdżającego
	g.add_child(l)
	var l2 := l.duplicate()
	l2.position.z = -0.04
	l2.rotation.y = PI
	g.add_child(l2)
	gates.append({"node": g, "mat": glow, "base": col, "start": start, "labels": [l, l2]})


func _box(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## Błysk bramki po przejechaniu: zielony/czerwony zależnie od międzyczasu, potem powrót.
func flash_gate(i: int, good: bool) -> void:
	var g: Dictionary = gates[i]
	var m: StandardMaterial3D = g.mat
	var c := Color(0.2, 1.0, 0.4, 0.95) if good else Color(1.0, 0.25, 0.2, 0.95)
	m.albedo_color = c
	var t := create_tween()
	t.tween_interval(0.4)
	t.tween_property(m, "albedo_color", Color(g.base, 0.75), 0.8)


## Bramki bliżej niż kilka metrów od kamery bledną, żeby nie zasłaniały widoku przy przejeździe.
func fade_gates(cam_pos: Vector3) -> void:
	for g in gates:
		var d: float = (g.node as Node3D).global_position.distance_to(cam_pos)
		var a := clampf((d - 2.5) / 5.0, 0.0, 1.0)
		var m: StandardMaterial3D = g.mat
		m.albedo_color.a = 0.75 * a
		for l in g.labels:
			(l as Label3D).modulate.a = a
		(g.node as Node3D).visible = a > 0.01
