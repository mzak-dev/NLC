class_name Decor
extends RefCounted
## Dekoracje mapy: wpis [rodzaj, x, z, obrót°, opcje] trafia do metody „k_<rodzaj>”; klasy map
## (extends Decor) dopisują własne rodzaje. Obrót jak wszędzie: 0° = lokalne +X wzdłuż świata +X,
## 90° = wzdłuż +Z; punkt lokalny l → świat (x, z) + l.rotated(deg_to_rad(rot)).
## Materiały ze wspólnej pamięci podręcznej (mat) — mniej wywołań rysowania.
##
## Wspólne rodzaje i ich opcje:
##   tree      {h = 5, crown = 2.2}                     — pień z kolizją, korona
##   bush      {r = 0.7}                                — krzak z kolizją
##   streetlamp{h = 5, color, energy = 2.5, range = 13, shadow = false} — słup z kolizją, wysięgnik na +X
##   container {stack = 1..3, color, colors = [..]}     — kontener 20' (6,06 × 2,44) wzdłuż lokalnego X
##   pipe      {len = 6, r = 0.15, y = 2.5, color}      — rura wzdłuż lokalnego X, bez kolizji
##   sign      {text, color, text_color, w = 1.2, h = 0.6, y = 2.0, pole = true} — tablica (+ słupek z kolizją)
##   bench     {color}                                  — ławka 1,8 m wzdłuż X, z kolizją
##   barrier   {len = 4, color}                         — szlaban: słupki bez kolizji, belka-rekwizyt (2 kg) na 1 m
##   neon      {text, color, size = 0.8, y = 3.0, light = true} — świecący napis (+ słaba lampa bez cienia)
##   floor_text{text, size = 0.32, color}                — napis na podłodze, czytelny w kierunku (sin rot, −cos rot)
##   paint     {text, size = 0.4, y = 2.0, color, plate, disc} — napis na ścianie (lokalne +Z = od ściany)

var apt: Apartment

static var _mats := {}


func _init(a: Apartment) -> void:
	apt = a


func build(e: Array) -> void:
	var fn := "k_" + str(e[0])
	if has_method(fn):
		call(fn, e)
	else:
		push_error("Decor: nieznany rodzaj dekoracji „%s”" % e[0])


# ---------- pomocnicy ----------

## Opcje wpisu (piąte pole) albo pusty słownik.
static func opts(e: Array) -> Dictionary:
	return e[4] if e.size() > 4 and e[4] is Dictionary else {}


## Węzeł dekoracji w (x, z) obrócony o rot° — dzieci budujemy w jego układzie lokalnym.
func root(e: Array) -> Node3D:
	var n := Node3D.new()
	n.position = Vector3(e[1], 0, e[2])
	n.rotation.y = -deg_to_rad(e[3] if e.size() > 3 else 0.0)
	apt.add_child(n)
	return n


## Bryła stała: kolizja + mesh (gdy m != null) + przeszkoda w świecie (dla walidatora), gdy wystaje
## ponad podłogę. m = null: sama kolizja (wygląd zbudowany osobno).
func solid(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Apartment.LAYER_STATIC
	body.collision_mask = 0
	body.position = pos
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	if m != null:
		box(body, size, Vector3.ZERO, m)
	parent.add_child(body)
	var t := body.transform        # przekształcenie do układu apt (węzły mogą jeszcze nie być w drzewie)
	var p := parent
	while p != null and p != apt:
		t = p.transform * t
		p = p.get_parent() as Node3D
	if t.origin.y + size.y * 0.5 > 0.05:
		var ax := t.basis.x
		apt.add_obstacle(Vector2(t.origin.x, t.origin.z), Vector2(size.x, size.z) * 0.5, atan2(ax.z, ax.x))


static func box(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = m
	parent.add_child(mi)
	return mi


## Pionowy walec (obróć zwrócony węzeł, żeby położyć go wzdłuż innej osi).
static func cyl(parent: Node3D, r: float, h: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 16
	cm.rings = 1
	mi.mesh = cm
	mi.position = pos
	mi.material_override = m
	parent.add_child(mi)
	return mi


static func sphere(parent: Node3D, r: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.position = pos
	mi.material_override = m
	parent.add_child(mi)
	return mi


## Stożek (ścięty, gdy top > 0).
static func cone(parent: Node3D, r: float, top: float, h: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := cyl(parent, r, h, pos, m)
	(mi.mesh as CylinderMesh).top_radius = top
	return mi


## Wspólny materiał (pamięć podręczna po kolorze, chropowatości i metaliczności). Nie modyfikuj zwróconego.
static func mat(c: Color, rough := 0.7, metal := 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f" % [c, rough, metal]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		m.metallic = metal
		if c.a < 0.999:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mats[key] = m
	return _mats[key]


## Świecący materiał (lampy, neony), też współdzielony.
static func glow(c: Color, energy := 3.0) -> StandardMaterial3D:
	var key := "glow|%s|%.2f" % [c, energy]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = energy
		_mats[key] = m
	return _mats[key]


## Napis 3D; size = wysokość liter [m]. Czytelny od strony lokalnego +Z (obróć rodzica/napis).
static func label(parent: Node3D, text: String, size: float, pos: Vector3, color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 64
	l.pixel_size = size / 64.0
	l.modulate = color
	l.outline_size = 0
	l.position = pos
	l.double_sided = false
	parent.add_child(l)
	return l


## Cienki prostopadłościan od a do b (lina, zastrzał, pręt kratownicy).
static func _beam(parent: Node3D, a: Vector3, b: Vector3, t: float, m: Material) -> MeshInstance3D:
	var d := b - a
	var mi := box(parent, Vector3(t, t, d.length()), (a + b) * 0.5, m)
	mi.basis = Basis.looking_at(d, Vector3.UP if absf(d.normalized().y) < 0.99 else Vector3.RIGHT)
	return mi


## Wiele brył jednym wywołaniem rysowania (MultiMesh z kolorem instancji):
## items = [[środek, rozmiar, kolor], …]; cylinders = walce zamiast prostopadłościanów.
static func _boxes(parent: Node3D, items: Array, rough := 0.8, metal := 0.0, shadow := true, cylinders := false) -> void:
	if items.is_empty():
		return
	var pm: PrimitiveMesh
	if cylinders:
		var cm := CylinderMesh.new()
		cm.top_radius = 0.5
		cm.bottom_radius = 0.5
		cm.height = 1.0
		cm.radial_segments = 12
		cm.rings = 1
		pm = cm
	else:
		pm = BoxMesh.new()
	pm.material = _tint(rough, metal)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = pm
	mm.instance_count = items.size()
	for i in items.size():
		var it: Array = items[i]
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(it[1]), it[0]))
		mm.set_instance_color(i, it[2])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## Wspólny materiał z kolorem z wierzchołków/instancji (dla _boxes).
static func _tint(rough: float, metal: float) -> StandardMaterial3D:
	var key := "tint|%.2f|%.2f" % [rough, metal]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.roughness = rough
		m.metallic = metal
		_mats[key] = m
	return _mats[key]


## Lampa punktowa; cień tylko gdy chciany i budżet mapy (Apartment.take_shadow) jeszcze pozwala.
func lamp(parent: Node3D, pos: Vector3, color: Color, energy: float, reach: float, shadow_wanted: bool) -> OmniLight3D:
	var ol := OmniLight3D.new()
	ol.position = pos
	ol.light_color = color
	ol.light_energy = energy
	ol.omni_range = reach
	ol.shadow_enabled = shadow_wanted and apt.take_shadow()
	parent.add_child(ol)
	return ol


# ---------- wspólne rodzaje dekoracji ----------

func k_tree(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var h: float = o.get("h", 5.0)
	var cr: float = o.get("crown", 2.2)
	solid(n, Vector3(0.4, h * 0.6, 0.4), Vector3(0, h * 0.3, 0), mat(Color(0.3, 0.22, 0.15), 0.9))
	var leaf := mat(o.get("color", Color(0.2, 0.4, 0.16)), 0.95)
	sphere(n, cr, Vector3(0, h - cr * 0.6, 0), leaf)
	sphere(n, cr * 0.7, Vector3(cr * 0.5, h - cr * 0.2, cr * 0.3), leaf)


func k_bush(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var r: float = o.get("r", 0.7)
	var leaf := mat(o.get("color", Color(0.22, 0.42, 0.18)), 0.95)
	sphere(n, r, Vector3(0, r * 0.8, 0), leaf)
	sphere(n, r * 0.7, Vector3(r * 0.6, r * 0.6, 0.1), leaf)
	solid(n, Vector3(r * 1.6, r * 1.4, r * 1.6), Vector3(0, r * 0.7, 0), null)


func k_streetlamp(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var h: float = o.get("h", 5.0)
	var pole := mat(Color(0.28, 0.3, 0.32), 0.5, 0.6)
	solid(n, Vector3(0.18, h, 0.18), Vector3(0, h * 0.5, 0), pole)
	box(n, Vector3(1.4, 0.08, 0.08), Vector3(0.65, h - 0.05, 0), pole)
	var c: Color = o.get("color", Color(1.0, 0.78, 0.48))
	box(n, Vector3(0.6, 0.12, 0.3), Vector3(1.25, h - 0.12, 0), pole)
	box(n, Vector3(0.5, 0.03, 0.24), Vector3(1.25, h - 0.19, 0), glow(c, 6.0))
	lamp(n, Vector3(1.25, h - 0.45, 0), c, o.get("energy", 2.5), o.get("range", 13.0), o.get("shadow", false))


const CONTAINER_COLORS := [Color(0.62, 0.14, 0.1), Color(0.1, 0.3, 0.55), Color(0.15, 0.45, 0.25),
	Color(0.85, 0.55, 0.1), Color(0.5, 0.5, 0.52), Color(0.1, 0.45, 0.5)]
const CONTAINER := Vector3(6.06, 2.59, 2.44)


func k_container(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var stack: int = clampi(o.get("stack", 1), 1, 3)
	var cols: Array = o.get("colors", [])
	var hs := int(absf(float(e[1]) * 7.0 + float(e[2]) * 13.0))      # kolory „losowe”, ale stałe dla miejsca
	for i in stack:
		var c: Color = cols[i] if i < cols.size() else (o.get("color", CONTAINER_COLORS[hs % 6]) if i == 0 \
			else CONTAINER_COLORS[(hs + i * 2) % 6])
		var y := CONTAINER.y * (i + 0.5)
		box(n, CONTAINER - Vector3(0.02, 0.02, 0.0), Vector3(0, y, 0), corrugated(c))
		var dark := mat(c.darkened(0.35), 0.6, 0.4)
		box(n, Vector3(0.06, CONTAINER.y - 0.1, CONTAINER.z - 0.1), Vector3(CONTAINER.x * 0.5, y, 0), dark)   # drzwi
		for s in [-0.4, 0.4]:
			box(n, Vector3(0.03, CONTAINER.y - 0.3, 0.05), Vector3(CONTAINER.x * 0.5 + 0.04, y, s), mat(Color(0.2, 0.2, 0.2), 0.4, 0.8))
	# jedna kolizja na cały stos (wygląd już jest)
	solid(n, Vector3(CONTAINER.x, CONTAINER.y * stack, CONTAINER.z), Vector3(0, CONTAINER.y * stack * 0.5, 0), null)


## Blacha falista: pionowe żebra z normal mapy (tekstura raz na grę), kolor ze wspólnej pamięci.
static var _ribs: ImageTexture


static func corrugated(c: Color) -> StandardMaterial3D:
	var key := "rib|%s" % c
	if _mats.has(key):
		return _mats[key]
	if _ribs == null:
		var img := Image.create(64, 4, false, Image.FORMAT_RGB8)
		for x in 64:
			var nx := cos(x / 64.0 * TAU * 4.0) * 0.7     # 4 żebra na teksturę
			for y in 4:
				img.set_pixel(x, y, Color(nx * 0.5 + 0.5, 0.5, 1.0))
		img.generate_mipmaps()           # bez mipmap żebra migoczą (mora) z daleka
		_ribs = ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	m.metallic = 0.35
	m.normal_enabled = true
	m.normal_texture = _ribs
	m.normal_scale = 1.0
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(1.25, 1.25, 1.25)        # żebro co 0,2 m
	_mats[key] = m
	return m


func k_pipe(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var ln: float = o.get("len", 6.0)
	var r: float = o.get("r", 0.15)
	var y: float = o.get("y", 2.5)
	var pm := mat(o.get("color", Color(0.45, 0.47, 0.5)), 0.45, 0.6)
	var p := cyl(n, r, ln, Vector3(0, y, 0), pm)
	p.rotation.z = PI / 2
	var f := 0.0
	while f <= ln + 0.01:
		var fl := cyl(n, r * 1.35, 0.06, Vector3(f - ln * 0.5, y, 0), pm)
		fl.rotation.z = PI / 2
		f += 3.0


func k_sign(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var w: float = o.get("w", 1.2)
	var h: float = o.get("h", 0.6)
	var y: float = o.get("y", 2.0)
	var bg: Color = o.get("color", Color(0.1, 0.45, 0.2))
	if o.get("pole", true):
		solid(n, Vector3(0.08, y, 0.08), Vector3(0, y * 0.5, 0), mat(Color(0.5, 0.52, 0.55), 0.5, 0.6))
	box(n, Vector3(w, h, 0.04), Vector3(0, y + h * 0.5, 0), mat(bg, 0.5))
	var tc: Color = o.get("text_color", Color.WHITE)
	label(n, o.get("text", ""), h * 0.45, Vector3(0, y + h * 0.5, -0.025), tc).rotation.y = PI
	label(n, o.get("text", ""), h * 0.45, Vector3(0, y + h * 0.5, 0.025), tc)


func k_bench(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var wood := mat(o.get("color", Color(0.5, 0.32, 0.16)), 0.8)
	var iron := mat(Color(0.15, 0.15, 0.16), 0.5, 0.7)
	solid(n, Vector3(1.8, 0.45, 0.5), Vector3(0, 0.225, 0), null)
	for z in [-0.15, 0.0, 0.15]:
		box(n, Vector3(1.8, 0.04, 0.12), Vector3(0, 0.45, z), wood)
	box(n, Vector3(1.8, 0.14, 0.04), Vector3(0, 0.75, 0.24), wood)
	box(n, Vector3(1.8, 0.14, 0.04), Vector3(0, 0.6, 0.24), wood)
	for x in [-0.75, 0.75]:
		box(n, Vector3(0.06, 0.45, 0.45), Vector3(x, 0.225, 0), iron)
		box(n, Vector3(0.06, 0.45, 0.04), Vector3(x, 0.65, 0.24), iron)


## Szlaban w poprzek drogi (belka wzdłuż lokalnego X): słupki bez kolizji, belka to lekki rekwizyt
## (2 kg), który czeka uśpiony na wysokości 1 m, aż ktoś go wyłamie.
func k_barrier(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var ln: float = o.get("len", 4.0)
	var post := mat(Color(0.85, 0.85, 0.82), 0.6)
	box(n, Vector3(0.3, 1.1, 0.3), Vector3(-ln * 0.5 - 0.2, 0.55, 0), mat(o.get("color", Color(0.9, 0.75, 0.1)), 0.5))
	box(n, Vector3(0.08, 0.95, 0.08), Vector3(ln * 0.5, 0.475, 0), post)
	var beam := RigidBody3D.new()
	beam.collision_layer = Apartment.LAYER_PROPS
	beam.collision_mask = Apartment.LAYER_STATIC | 2 | Apartment.LAYER_PROPS
	beam.mass = 2.0
	beam.can_sleep = true
	beam.sleeping = true
	beam.position = Vector3(0, 1.0, 0)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(ln, 0.1, 0.1)
	cs.shape = bs
	beam.add_child(cs)
	var k := 0
	var x := -ln * 0.5
	while x < ln * 0.5 - 0.01:
		var seg := minf(0.5, ln * 0.5 - x)
		box(beam, Vector3(seg, 0.1, 0.1), Vector3(x + seg * 0.5, 0, 0), mat(Color(0.85, 0.1, 0.1) if k % 2 == 0 else Color.WHITE, 0.5))
		x += seg
		k += 1
	n.add_child(beam)


## Napis malowany na podłodze {text, size = 0.32, color}; górą w stronę lokalnego −Z, czyli czytelny
## dla jadącego w świecie w kierunku (sin rot, −cos rot): 90° → +X, 180° → +Z, 270° → −X, 0° → −Z.
func k_floor_text(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var l := label(n, o.get("text", ""), o.get("size", 0.32), Vector3(0, 0.007, 0), o.get("color", Color(0.85, 0.85, 0.82)))
	l.rotation.x = -PI / 2
	l.shaded = true
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD


## Napis na ścianie (lokalne +Z = od ściany) {text, size, y, color, plate = tło, disc = okrągłe tło}.
func k_paint(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var s: float = o.get("size", 0.4)
	var y: float = o.get("y", 2.0)
	var text: String = o.get("text", "")
	if o.has("plate"):
		box(n, Vector3(s * (0.68 * text.length() + 0.8), s * 1.6, 0.02), Vector3(0, y, 0.01), mat(o.plate, 0.6))
	if o.has("disc"):
		var d := cyl(n, s * 0.85, 0.02, Vector3(0, y, 0.01), mat(o.disc, 0.6))
		d.rotation.x = PI / 2
	var l := label(n, text, s, Vector3(0, y, 0.025), o.get("color", Color(0.05, 0.05, 0.05) if o.has("disc") else Color.WHITE))
	l.shaded = true
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD


func k_neon(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var c: Color = o.get("color", Color(1.0, 0.2, 0.5))
	var size: float = o.get("size", 0.8)
	var y: float = o.get("y", 3.0)
	var l := label(n, o.get("text", ""), size, Vector3(0, y, 0), Color(c.r * 2.5, c.g * 2.5, c.b * 2.5))
	l.shaded = false
	l.double_sided = true
	if o.get("light", true):
		lamp(n, Vector3(0, y, 0.8), c, 1.2, 6.0, false)


# ---------- modele rekwizytów (dopasowane do prostopadłościanu size, środek w zerze) ----------

static func prop_model(kind: String, size: Vector3, color: Color) -> Node3D:
	var n := Node3D.new()
	var hy := size.y * 0.5
	var r := minf(size.x, size.z) * 0.5
	match kind:
		"cone":
			box(n, Vector3(size.x, size.y * 0.06, size.z), Vector3(0, -hy + size.y * 0.03, 0), mat(color, 0.6))
			cone(n, r * 0.85, r * 0.12, size.y * 0.94, Vector3(0, size.y * 0.03, 0), mat(color, 0.6))
			cone(n, r * 0.52, r * 0.4, size.y * 0.16, Vector3(0, size.y * 0.1, 0), mat(Color(0.95, 0.95, 0.95), 0.4))
		"barrel":
			cyl(n, r, size.y, Vector3.ZERO, mat(color, 0.5, 0.4))
			for y in [-0.3, 0.3]:
				cyl(n, r * 1.03, size.y * 0.04, Vector3(0, size.y * y, 0), mat(color.darkened(0.3), 0.5, 0.5))
		"crate":
			box(n, size * 0.94, Vector3.ZERO, mat(color, 0.85))
			var frame := mat(color.darkened(0.25), 0.85)
			for y in [-1.0, 1.0]:
				box(n, Vector3(size.x, size.y * 0.12, size.z), Vector3(0, y * (hy - size.y * 0.06), 0), frame)
			box(n, Vector3(size.x * 0.12, size.y, size.z), Vector3.ZERO, frame)
		"pallet":
			var wood := mat(color, 0.9)
			for z in [-1.0, 0.0, 1.0]:
				box(n, Vector3(size.x, size.y * 0.6, size.z * 0.12), Vector3(0, -size.y * 0.2, z * (size.z * 0.44)), wood)
			for i in 5:
				box(n, Vector3(size.x * 0.14, size.y * 0.25, size.z), Vector3((i - 2) * size.x * 0.215, hy - size.y * 0.125, 0), wood)
			box(n, Vector3(size.x, size.y * 0.15, size.z), Vector3(0, -hy + size.y * 0.075, 0), wood)
		"cart":
			var wire := mat(color, 0.35, 0.8)
			var by := hy * 0.25
			var bh := size.y * 0.45
			box(n, Vector3(size.x * 0.85, 0.02, size.z * 0.9), Vector3(size.x * 0.05, by - bh * 0.5, 0), wire)
			for s in [-1.0, 1.0]:
				box(n, Vector3(size.x * 0.85, bh, 0.02), Vector3(size.x * 0.05, by, s * size.z * 0.45), wire)
				box(n, Vector3(0.02, bh, size.z * 0.9), Vector3(s * size.x * 0.425 + size.x * 0.05, by, 0), wire)
				box(n, Vector3(0.03, size.y * 0.5, 0.03), Vector3(-size.x * 0.35, -hy + size.y * 0.25, s * size.z * 0.4), wire)
				box(n, Vector3(0.03, size.y * 0.5, 0.03), Vector3(size.x * 0.4, -hy + size.y * 0.25, s * size.z * 0.4), wire)
			box(n, Vector3(0.05, 0.05, size.z), Vector3(-size.x * 0.47, hy - 0.04, 0), mat(Color(0.8, 0.1, 0.1), 0.5))
			for x in [-0.35, 0.4]:
				for s in [-1.0, 1.0]:
					var w := cyl(n, 0.06, 0.04, Vector3(size.x * x, -hy + 0.06, s * size.z * 0.4), mat(Color(0.1, 0.1, 0.1), 0.8))
					w.rotation.x = PI / 2
		"chair":
			var cm := mat(color, 0.7)
			box(n, Vector3(size.x, size.y * 0.06, size.z), Vector3(0, 0.0, 0), cm)
			box(n, Vector3(size.x, size.y * 0.45, size.z * 0.08), Vector3(0, hy - size.y * 0.225, -size.z * 0.46), cm)
			for x in [-1.0, 1.0]:
				for z in [-1.0, 1.0]:
					box(n, Vector3(0.04, hy, 0.04), Vector3(x * (size.x * 0.5 - 0.03), -hy * 0.5, z * (size.z * 0.5 - 0.03)), cm)
		"ball":
			sphere(n, minf(r, hy), Vector3.ZERO, mat(color, 0.6))
		"gnome":
			cone(n, r * 0.9, r * 0.6, size.y * 0.45, Vector3(0, -hy + size.y * 0.225, 0), mat(color, 0.6))
			sphere(n, r * 0.5, Vector3(0, -hy + size.y * 0.55, 0), mat(Color(0.95, 0.75, 0.62), 0.6))
			cone(n, r * 0.45, 0.005, size.y * 0.32, Vector3(0, hy - size.y * 0.16, 0), mat(Color(0.85, 0.1, 0.1), 0.6))
			var beard := cone(n, r * 0.4, 0.01, size.y * 0.2, Vector3(0, -hy + size.y * 0.42, -r * 0.35), mat(Color(0.95, 0.95, 0.95), 0.9))
			beard.rotation.x = PI
		"tire":
			var tm := TorusMesh.new()
			tm.inner_radius = r * 0.5
			tm.outer_radius = r
			var t := MeshInstance3D.new()
			t.mesh = tm
			t.scale = Vector3(1, size.y / (r * 0.5), 1)
			t.material_override = mat(Color(0.06, 0.06, 0.06), 0.9)
			n.add_child(t)
		"wet_sign":
			var y := mat(Color(0.98, 0.8, 0.05), 0.4)
			for s in [-1.0, 1.0]:
				var p := box(n, Vector3(size.x, size.y, 0.02), Vector3(0, 0, s * size.z * 0.25), y)
				p.rotation.x = -s * atan2(size.z * 0.25, size.y * 0.5)     # szczyty schodzą się nad środkiem
				var l := label(n, "!", size.y * 0.4, Vector3(0, 0, s * (size.z * 0.25 + 0.015)), Color(0.05, 0.05, 0.05))
				l.rotation.y = 0.0 if s > 0 else PI
				l.rotation.x = s * p.rotation.x
		_:
			box(n, size, Vector3.ZERO, mat(color, 0.6))
	return n


## Kształt kolizji rekwizytu danego rodzaju (piłka toczy się, beczka i opona to walce).
static func prop_shape(kind: String, size: Vector3) -> Shape3D:
	var r := minf(size.x, size.z) * 0.5
	match kind:
		"ball":
			var s := SphereShape3D.new()
			s.radius = minf(r, size.y * 0.5)
			return s
		"barrel", "tire":
			var c := CylinderShape3D.new()
			c.radius = r
			c.height = size.y
			return c
	var b := BoxShape3D.new()
	b.size = size
	return b
