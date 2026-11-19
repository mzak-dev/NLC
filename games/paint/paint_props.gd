class_name PaintProps
extends RefCounted
## Rekwizyty z prymitywów: wałek, kuweta, puszka, okno, drzwi, kaloryfer.
## Używane w pokoju (paint.gd) i jako eksponaty na ekranie ładowania (loading.gd).

static func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.material_override = m
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mesh(parent, b, pos, m, rot)


static func cyl(parent: Node3D, r: float, h: float, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	return _mesh(parent, c, pos, m, rot)


## Rekwizyt ściany po nazwie; size = szerokość × wysokość [m], środek w (0, 0), tył przy ścianie (z = 0).
static func build(prop: String, size: Vector2) -> Node3D:
	match prop:
		"window":
			return window(size)
		"door":
			return door(size)
		"radiator":
			return radiator(size)
	return Node3D.new()


## Wałek malarski. Punkt (0,0,0) = miejsce styku wałka ze ścianą; pierwsze dziecko to gąbka (do kolorowania).
static func roller(c: Color, width := 0.36) -> Node3D:
	var root := Node3D.new()
	cyl(root, 0.045, width, Vector3(0, 0, 0.045), Kredens.mat(c, 0.6), Vector3(0, 0, PI / 2))
	var steel := Kredens.mat(Color(0.75, 0.75, 0.78), 0.3, 1.0)
	box(root, Vector3(0.012, 0.012, 0.13), Vector3(width / 2 + 0.02, 0, 0.11), steel)
	box(root, Vector3(width / 2 + 0.03, 0.012, 0.012), Vector3(width / 4 + 0.01, 0, 0.17), steel)
	cyl(root, 0.006, 0.16, Vector3(0, -0.07, 0.2), steel, Vector3(-0.4, 0, 0))
	cyl(root, 0.02, 0.2, Vector3(0, -0.23, 0.27), Kredens.mat(Color(0.85, 0.1, 0.1), 0.5), Vector3(-0.4, 0, 0))
	return root


## Kuweta z farbą; drugie dziecko to tafla farby (do kolorowania).
static func tray(c: Color) -> Node3D:
	var root := Node3D.new()
	box(root, Vector3(0.46, 0.06, 0.38), Vector3(0, 0.03, 0), Kredens.mat(Color(0.12, 0.12, 0.14), 0.6))
	box(root, Vector3(0.4, 0.01, 0.2), Vector3(0, 0.062, 0.07), Kredens.mat(c, 0.08))
	return root


## Puszka farby; drugie dziecko to farba pod zdjętą pokrywką (do kolorowania).
static func can(c: Color) -> Node3D:
	var root := Node3D.new()
	cyl(root, 0.16, 0.24, Vector3(0, 0.12, 0), Kredens.mat(Color(0.75, 0.75, 0.78), 0.3, 1.0))
	cyl(root, 0.15, 0.01, Vector3(0, 0.243, 0), Kredens.mat(c, 0.1))
	return root


static func window(size: Vector2) -> Node3D:
	var root := Node3D.new()
	var frame := Kredens.mat(Color(0.92, 0.9, 0.85), 0.5)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.7, 0.82, 0.95)
	glass.emission_enabled = true
	glass.emission = Color(0.75, 0.85, 1.0)
	glass.emission_energy_multiplier = 1.6
	box(root, Vector3(size.x, size.y, 0.02), Vector3(0, 0, 0.02), glass)
	var t := 0.08
	for sx in [-1.0, 1.0]:
		box(root, Vector3(t, size.y, 0.09), Vector3(sx * (size.x - t) / 2, 0, 0.045), frame)
		box(root, Vector3(size.x, t, 0.09), Vector3(0, sx * (size.y - t) / 2, 0.045), frame)
	box(root, Vector3(0.05, size.y, 0.07), Vector3(0, 0, 0.04), frame)             # słupek
	box(root, Vector3(size.x, 0.05, 0.07), Vector3(0, size.y * 0.18, 0.04), frame) # szpros lufcika
	box(root, Vector3(size.x + 0.2, 0.04, 0.22), Vector3(0, -size.y / 2 - 0.02, 0.11), frame)   # parapet
	return root


static func door(size: Vector2) -> Node3D:
	var root := Node3D.new()
	var frame := Kredens.wood(Color(0.3, 0.18, 0.09))
	var t := 0.07
	box(root, Vector3(size.x, size.y, 0.02), Vector3(0, 0, 0.01), frame)
	for sx in [-1.0, 1.0]:
		box(root, Vector3(t, size.y, 0.1), Vector3(sx * (size.x - t) / 2, 0, 0.05), frame)
	box(root, Vector3(size.x, t, 0.1), Vector3(0, (size.y - t) / 2, 0.05), frame)
	box(root, Vector3(size.x - 2 * t, size.y - t, 0.04), Vector3(0, -t / 2, 0.045), Kredens.wood(Color(0.52, 0.33, 0.17)))
	var h := handle()
	h.position = Vector3(size.x / 2 - 0.2, -0.05, 0.065)
	root.add_child(h)
	return root


## Kaloryfer żeliwny: żeberka + rury.
static func radiator(size: Vector2) -> Node3D:
	var root := Node3D.new()
	var iron := Kredens.mat(Color(0.86, 0.84, 0.78), 0.45)
	box(root, Vector3(size.x, size.y, 0.01), Vector3(0, 0, 0.005), Kredens.mat(Color(0.2, 0.2, 0.2), 0.9))
	var n := int(size.x / 0.085)
	for i in n:
		box(root, Vector3(0.06, size.y, 0.13), Vector3((i - (n - 1) / 2.0) * 0.085, 0, 0.1), iron)
	for sy in [-1.0, 1.0]:
		cyl(root, 0.025, size.x + 0.16, Vector3(0, sy * (size.y / 2 - 0.07), 0.1), iron, Vector3(0, 0, PI / 2))
	return root


## Klamka z szyldem (gość z innej gry).
static func handle() -> Node3D:
	var root := Node3D.new()
	var brass := Kredens.mat(Color(0.83, 0.62, 0.25), 0.3, 1.0)
	box(root, Vector3(0.045, 0.22, 0.01), Vector3(0, 0, 0.005), brass)
	cyl(root, 0.011, 0.05, Vector3(0, 0.04, 0.03), brass, Vector3(PI / 2, 0, 0))
	box(root, Vector3(0.14, 0.02, 0.02), Vector3(-0.06, 0.04, 0.055), brass)
	return root


## „Model”, którego nie udało się wczytać.
static func missing() -> Node3D:
	var root := Node3D.new()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 0, 1)
	box(root, Vector3.ONE, Vector3.ZERO, m)
	for i in 4:
		var l := Label3D.new()
		l.text = "brak_modelu.obj"
		l.font_size = 64
		l.outline_size = 16
		l.rotation.y = i * PI / 2
		l.position = Vector3(sin(i * PI / 2), 0, cos(i * PI / 2)) * 0.51
		root.add_child(l)
	return root
