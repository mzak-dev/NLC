class_name Backdrop
extends RefCounted
## Otoczenie toru według klucza mapy „env”: niebo/tło, słońce, lampy pokojowe, osiedle, teren.
##   flat   — mieszkanie na IV piętrze z osiedlem dookoła (M4),
##   garage — kryty parking (ciemne tło, mgiełka spalin),
##   sewer  — jak garaż, ciemniej, zielonkawa mgła,
##   open   — teren na poziomie ziemi: niebo i słońce według „mood”, ziemia „ground” po horyzont, bloki w tle,
##   school — jak open, bez bloków (wnętrze bez sufitu na parterze).
## Pora dnia „mood”: swit | zmierzch | popoludnie | dzien.

const FLOOR_H := 2.8
const GROUND_Y := -4.0 * FLOOR_H - 0.6      # ziemia pod mieszkaniem na IV piętrze
const OPEN_Y := -0.02                        # ziemia wokół toru na parterze

## Pora dnia: niebo (góra, horyzont), słońce (kąt nachylenia, azymut, kolor, energia), mgła (gęstość, kolor), otoczenie.
const MOODS := {
	"swit": {"top": Color(0.36, 0.41, 0.5), "hor": Color(0.72, 0.7, 0.7), "rot": Vector3(-12, 115, 0),
		"sun": Color(0.8, 0.86, 1.0), "e": 0.75, "fog": 0.012, "fog_c": Color(0.62, 0.66, 0.72), "amb": 0.45},
	"zmierzch": {"top": Color(0.04, 0.06, 0.2), "hor": Color(0.95, 0.48, 0.22), "rot": Vector3(-7, -70, 0),
		"sun": Color(1.0, 0.55, 0.3), "e": 0.3, "fog": 0.0, "fog_c": Color.BLACK, "amb": 0.3},
	"popoludnie": {"top": Color(0.25, 0.35, 0.55), "hor": Color(0.6, 0.55, 0.5), "rot": Vector3(-58, -32, 0),
		"sun": Color(1.0, 0.9, 0.78), "e": 1.6, "fog": 0.0, "fog_c": Color.BLACK, "amb": 0.35},
	"dzien": {"top": Color(0.22, 0.42, 0.75), "hor": Color(0.66, 0.73, 0.8), "rot": Vector3(-62, 30, 0),
		"sun": Color(1.0, 0.98, 0.94), "e": 1.4, "fog": 0.0, "fog_c": Color.BLACK, "amb": 0.35},
}


## Stawia otoczenie jako dzieci `apt` i zwraca środowisko (do przełączania jakości).
static func build(apt: Apartment, m: Dictionary) -> Environment:
	var kind: String = m.get("env", "flat")
	var env: Environment
	if kind == "garage" or kind == "sewer":
		env = _covered(apt, kind == "sewer")
	elif kind == "open" or kind == "school":
		env = _sky(apt, MOODS.get(m.get("mood", "dzien"), MOODS.dzien))
		_open_ground(apt, m, kind == "open")
		if kind == "school":
			_room_lamps(apt, m)
	else:
		env = _sky(apt, MOODS.popoludnie)
		_room_lamps(apt, m)
		_estate(apt, m)
	var we := WorldEnvironment.new()
	we.environment = env
	apt.add_child(we)
	return env


## Pełna jakość (jeden widok) albo lżejsza (2+ widoki: bez SDFGI, SSIL, SSR i mgły wolumetrycznej).
static func set_quality(env: Environment, full: bool) -> void:
	env.sdfgi_enabled = full
	env.ssil_enabled = full
	env.ssr_enabled = full
	env.volumetric_fog_enabled = full and env.get_meta("vfog", false)


## Wspólne ustawienia jakości: AgX, GI (SDFGI = światło odbite od ścian i podłóg), SSIL, odbicia SSR, SSAO, glow.
static func _quality(e: Environment) -> void:
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	e.tonemap_exposure = 1.1
	e.sdfgi_enabled = true
	e.sdfgi_use_occlusion = true
	e.sdfgi_energy = 1.2
	e.ssil_enabled = true
	e.ssr_enabled = true
	e.ssr_max_steps = 48
	e.ssao_enabled = true
	e.ssao_intensity = 1.6
	e.glow_enabled = true
	e.glow_intensity = 0.6
	e.glow_bloom = 0.05
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.08
	e.adjustment_contrast = 1.05


## Garaż / kanał: ciemne tło, światło tylko z lamp, mgiełka (w kanale gęstsza i zielonkawa).
static func _covered(apt: Apartment, sewer: bool) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.025)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.56, 0.6)
	_quality(env)
	env.ambient_light_energy = 0.15 if sewer else 0.25
	env.volumetric_fog_enabled = true          # mgiełka — snopy światła lamp
	env.set_meta("vfog", true)
	env.volumetric_fog_density = 0.03 if sewer else 0.012
	env.volumetric_fog_albedo = Color(0.55, 0.75, 0.5) if sewer else Color(0.8, 0.8, 0.85)
	var top := DirectionalLight3D.new()     # miękkie wypełnienie z góry
	top.rotation_degrees = Vector3(-80, 20, 0)
	top.light_energy = 0.1 if sewer else 0.25
	apt.add_child(top)
	return env


## Niebo proceduralne i słońce z cieniami według pory dnia.
static func _sky(apt: Apartment, md: Dictionary) -> Environment:
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = md.top
	sm.sky_horizon_color = md.hor
	sky.sky_material = sm
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = md.amb
	_quality(env)
	if md.fog > 0.0:
		env.fog_enabled = true
		env.fog_density = md.fog
		env.fog_light_color = md.fog_c
		env.fog_sky_affect = 0.6
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = md.rot
	sun.light_energy = md.e
	sun.light_color = md.sun
	sun.light_angular_distance = 1.2            # miękkie krawędzie cieni
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	apt.add_child(sun)
	return env


## Ciepła lampa nad środkiem każdego pomieszczenia (wnętrza bez sufitu: mieszkanie, szkoła).
static func _room_lamps(apt: Apartment, m: Dictionary) -> void:
	for r in m.get("rooms", []):
		var lamp := OmniLight3D.new()
		var rc: Rect2 = r.rect
		lamp.position = Vector3(rc.get_center().x, 2.5, rc.get_center().y)
		lamp.light_color = Color(1.0, 0.86, 0.66)
		lamp.light_energy = 0.35
		lamp.omni_range = 10.0
		lamp.shadow_enabled = apt.take_shadow()
		apt.add_child(lamp)


# ---------- osiedle wokół mieszkania (żeby za ścianami nie było pustki) ----------
# Mieszkanie jest na IV piętrze: pod nim stoi bryła bloku, dookoła trawa, chodniki i sąsiednie bloki.

static var _facade: ImageTexture


static func _facade_tex() -> ImageTexture:
	if _facade:
		return _facade
	var cell := Vector2i(48, 45)          # jedno okno + ściana: 3 m × 2,8 m
	var img := Image.create(cell.x * 8, cell.y * 8, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1983
	var wall := Color(0.78, 0.76, 0.7)
	for cy in 8:
		for cx in 8:
			var lit := rng.randf() < 0.25
			var glass := Color(0.95, 0.78, 0.45) if lit else Color(0.18, 0.22, 0.28).lightened(rng.randf() * 0.15)
			var balcony := rng.randf() < 0.3
			for y in cell.y:
				for x in cell.x:
					var c := wall * (0.94 + 0.06 * rng.randf())
					if x > 10 and x < 38 and y > 8 and y < 32:
						c = glass
						if x == 24 or y == 20:
							c = Color(0.9, 0.9, 0.88)       # szprosy
					if balcony and y >= 30 and y < 40 and x > 4 and x < 44:
						c = Color(0.55, 0.55, 0.52)
					if y >= cell.y - 2:
						c = wall * 0.8                       # linia stropu
					img.set_pixel(cx * cell.x + x, cy * cell.y + y, c)
	_facade = ImageTexture.create_from_image(img)
	return _facade


static func _facade_mat() -> StandardMaterial3D:
	var fm := Apartment.mat(Color.WHITE, 0.85)
	fm.albedo_texture = _facade_tex()
	fm.uv1_triplanar = true
	fm.uv1_world_triplanar = true
	fm.uv1_scale = Vector3(1.0 / 24.0, 1.0 / (FLOOR_H * 8.0), 1.0 / 24.0)
	return fm


static func _block(apt: Apartment, pos: Vector3, size: Vector3, fm: Material, roof_on := true) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos + Vector3(0, size.y * 0.5, 0)
	mi.material_override = fm
	apt.add_child(mi)
	if not roof_on:
		return
	var roof := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(size.x + 0.4, 0.4, size.z + 0.4)
	roof.mesh = rb
	roof.position = pos + Vector3(0, size.y + 0.2, 0)
	roof.material_override = Decor.mat(Color(0.3, 0.3, 0.32), 0.9)
	apt.add_child(roof)


static func _estate(apt: Apartment, m: Dictionary) -> void:
	var sz: Vector2 = m.size
	# bryła własnego bloku pod mieszkaniem (od ziemi do podłogi, bez dachu)
	_block(apt, Vector3(sz.x * 0.5, GROUND_Y, sz.y * 0.5), Vector3(sz.x + 0.6, -GROUND_Y - 0.25, sz.y + 0.6), _facade_mat(), false)
	# ziemia: trawa + chodniki
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600, 600)
	ground.mesh = pm
	ground.position = Vector3(sz.x * 0.5, GROUND_Y, sz.y * 0.5)
	ground.material_override = Apartment.surface(Color(0.32, 0.45, 0.22), 1.0, 0.2, 0.5)
	apt.add_child(ground)
	for z in [-14.0, sz.y + 14.0]:
		var walk := MeshInstance3D.new()
		var wm := PlaneMesh.new()
		wm.size = Vector2(300, 6)
		walk.mesh = wm
		walk.position = Vector3(sz.x * 0.5, GROUND_Y + 0.02, z)
		walk.material_override = Apartment.surface(Color(0.55, 0.55, 0.53), 0.95, 0.5, 0.3)
		apt.add_child(walk)
	_neighbours(apt, m, GROUND_Y, true)


## Sąsiednie bloki (różne wysokości) i drzewa wokół planu. Plan większy niż M4 odsuwa je proporcjonalnie;
## to, co wypadłoby w wodzie, nie powstaje.
static func _neighbours(apt: Apartment, m: Dictionary, gy: float, blocks: bool) -> void:
	var sz: Vector2 = m.size
	var mid := sz * 0.5
	var half_diag := mid.length()
	var k := maxf(1.0, half_diag / 20.0)
	var water: Array = m.get("water", [])
	var fm := _facade_mat()
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	var spots := [Vector2(16, -60), Vector2(-50, -55), Vector2(80, -62), Vector2(16, 88), Vector2(-60, 90),
		Vector2(95, 85), Vector2(-110, 15), Vector2(140, 10), Vector2(160, -90), Vector2(-150, -100)]
	for sp in spots:
		var floors := rng.randi_range(5, 11)
		var long := rng.randf() < 0.6
		var size := Vector3(rng.randf_range(50, 90) if long else 18, floors * FLOOR_H, 12 if long else 18)
		var at: Vector2 = mid + (sp - Vector2(16, 12)) * k
		if blocks and not _in_water(water, Rect2(at - Vector2(size.x, size.z) * 0.5, Vector2(size.x, size.z))):
			_block(apt, Vector3(at.x, gy, at.y), size, fm)
	var leaf := Apartment.surface(Color(0.2, 0.38, 0.15), 1.0, 0.8, 1.0)
	var bark := Decor.mat(Color(0.3, 0.22, 0.15), 0.9)
	for i in 30:
		var a := rng.randf() * TAU
		var r := rng.randf_range(30, 70) + maxf(0.0, half_diag - 20.0)
		var rr := rng.randf_range(2.5, 4.0)
		var tp := Vector3(mid.x + cos(a) * r, gy, mid.y + sin(a) * r)
		if _in_water(water, Rect2(tp.x - rr, tp.z - rr, rr * 2.0, rr * 2.0)):
			continue
		var trunk := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.25
		cm.bottom_radius = 0.35
		cm.height = 4.0
		trunk.mesh = cm
		trunk.position = tp + Vector3(0, 2.0, 0)
		trunk.material_override = bark
		apt.add_child(trunk)
		var crown := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rr
		sm.height = rr * 2.0
		crown.mesh = sm
		crown.position = tp + Vector3(0, 4.0 + rr * 0.7, 0)
		crown.material_override = leaf
		apt.add_child(crown)


static func _in_water(water: Array, rc: Rect2) -> bool:
	return water.any(func(w: Dictionary) -> bool: return (w.rect as Rect2).intersects(rc))


## Teren na parterze: płyty z kolizją (y = −0,02) po horyzont, z dziurami na wodę; w trybie open bloki w tle.
static func _open_ground(apt: Apartment, m: Dictionary, blocks: bool) -> void:
	var sz: Vector2 = m.size
	var pieces: Array[Rect2] = [Rect2(sz * 0.5 - Vector2(1000, 1000), Vector2(2000, 2000))]
	for w in m.get("water", []):
		var next: Array[Rect2] = []
		for p in pieces:
			next.append_array(rect_minus(p, w.rect))
		pieces = next
	var gm := Apartment.surface(m.get("ground", Color(0.32, 0.45, 0.22)), 1.0, 0.2, 0.5)
	for p in pieces:
		var body := StaticBody3D.new()
		body.collision_layer = Apartment.LAYER_STATIC
		body.collision_mask = 0
		body.position = Vector3(p.get_center().x, OPEN_Y - 0.1, p.get_center().y)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(p.size.x, 0.2, p.size.y)
		cs.shape = bs
		body.add_child(cs)
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = p.size
		mi.mesh = pm
		mi.position.y = 0.1
		mi.material_override = gm
		body.add_child(mi)
		apt.add_child(body)
	_neighbours(apt, m, OPEN_Y, blocks)


## Prostokąt a bez części wspólnej z b: do czterech prostokątów (pasy nad, pod, z lewej, z prawej).
static func rect_minus(a: Rect2, b: Rect2) -> Array[Rect2]:
	var i := a.intersection(b)
	if i.get_area() <= 0.0:
		return [a]
	var out: Array[Rect2] = []
	var parts := [
		Rect2(a.position.x, a.position.y, a.size.x, i.position.y - a.position.y),
		Rect2(a.position.x, i.end.y, a.size.x, a.end.y - i.end.y),
		Rect2(a.position.x, i.position.y, i.position.x - a.position.x, i.size.y),
		Rect2(i.end.x, i.position.y, a.end.x - i.end.x, i.size.y),
	]
	for p in parts:
		if p.size.x > 0.001 and p.size.y > 0.001:
			out.append(p)
	return out
