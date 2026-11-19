class_name Apartment
extends Node3D
## Budowniczy toru: z danych mapy (RaceMaps) stawia podłogi (z kolizją per pomieszczenie), wodę,
## ściany, meble, progi, rekwizyty; strop z lampami dla map ze stropem; filary, auta, strzałki i linie;
## otoczenie (Backdrop) i dekoracje (Decor). Oś X w prawo, Z „w dół” na planie, jednostki: metry.
## Obrót w danych (auta, dekoracje): stopnie, 0° = przód na +X, 90° = na +Z; punkt lokalny l →
## świat pos + l.rotated(deg_to_rad(rot)); węzeł 3D: rotation.y = -deg_to_rad(rot).

const T := 0.15
const LAYER_STATIC := 1
const LAYER_PROPS := 4
const MAX_SHADOWS := 8      # lampy punktowe z cieniem na mapę (wydajność)

## Wymiary zaparkowanych aut: [długość, szerokość, wys. nadwozia, dł. kabiny, wys. kabiny, promień koła]
const CAR_DIMS := {"maly": [3.0, 1.4, 0.72, 1.6, 0.52, 0.26], "duzy": [4.3, 1.65, 0.72, 2.2, 0.55, 0.3],
	"bus": [10.0, 2.5, 2.4, 0.0, 0.0, 0.45], "van": [4.9, 1.9, 1.55, 0.0, 0.0, 0.32]}

var curve: Curve3D
var m: Dictionary          # bieżąca mapa (RaceMaps)
var deco: Decor            # budowniczy dekoracji mapy (instancja klasy z klucza „builder”)
var env: Environment       # środowisko otoczenia (Backdrop.set_quality przełącza jakość)
## Rzut przeszkód stałych na podłogę (dla walidatora trasy): prostokąt obrócony o angle [rad]
## wokół środka; punkt lokalny l → świat center + l.rotated(angle).
var obstacles: Array[Dictionary] = []
var _fade_segs: Array[Dictionary] = []
var _shadows := 0
var _flick: Array[Dictionary] = []                 # migające lampy {light, mat, e, ph}
var _water_mats: Array[StandardMaterial3D] = []    # tafle wody (przesuwana normal mapa)
var _wall_cache := {}
var _t := 0.0


func build(map: Dictionary) -> void:
	m = map
	deco = m.get("builder", Decor).new(self)
	env = Backdrop.build(self, m)
	_floors()
	_water()
	var h: float = m.get("height", 2.8)
	for w in m.get("walls", []):
		_wall(Vector2(w[0], w[1]), Vector2(w[2], w[3]), 0.0, w[4] if w.size() > 4 else h, true, w[5] if w.size() > 5 else "")
	for d in m.get("doors", []):
		_wall(Vector2(d[0], d[1]), Vector2(d[2], d[3]), 2.1, h, false, "")
	for f in m.get("furniture", []):
		_furniture(f)
	for p in m.get("props", []):
		_prop(p)
	for hp in m.get("humps", []):
		_hump(hp)
	var covered: bool = m.get("ceiling", m.get("env", "flat") in ["garage", "sewer"])
	if covered:
		_ceiling()
	_ground_details(covered)
	for e in m.get("decor", []):
		deco.build(e)
	curve = make_curve(m.path)
	set_process(not (_flick.is_empty() and _water_mats.is_empty()))


## Czy kolejne światło może rzucać cień (najwyżej MAX_SHADOWS na mapę). Zużywa miejsce z budżetu.
func take_shadow() -> bool:
	if _shadows >= MAX_SHADOWS:
		return false
	_shadows += 1
	return true


## Zamknięta, gładka linia jazdy przez punkty planu (styczne z sąsiednich punktów).
static func make_curve(path: Array) -> Curve3D:
	var c := Curve3D.new()
	c.bake_interval = 0.2
	var n := path.size()
	for i in n + 1:
		var p: Vector2 = path[i % n]
		var tan: Vector2 = (path[(i + 1) % n] - path[(i - 1 + n) % n]) * 0.22
		c.add_point(Vector3(p.x, 0, p.y), Vector3(-tan.x, 0, -tan.y), Vector3(tan.x, 0, tan.y))
	return c


## Rejestruje przeszkodę stałą: środek, połowy wymiarów i obrót [rad] (konwencja jak wyżej).
func add_obstacle(center: Vector2, half: Vector2, angle := 0.0) -> void:
	obstacles.append({"center": center, "half": half, "angle": angle})


## Najbliższy punkt toru szukany tylko w okolicy poprzedniego — na nawrotach dwa odcinki leżą
## blisko siebie i globalne get_closest_offset przeskakiwałoby między nimi.
## Gdy pojazd odleciał daleko (ponad 3 m od toru), wraca do wyszukiwania globalnego.
static func closest_near(c: Curve3D, pos: Vector3, last: float, back := 4.0, ahead := 10.0) -> float:
	var total := c.get_baked_length()
	var flat := Vector3(pos.x, 0, pos.z)
	var best := last
	var best_d := INF
	var o := last - back
	while o <= last + ahead:
		var d := c.sample_baked(fposmod(o, total)).distance_squared_to(flat)
		if d < best_d:
			best_d = d
			best = fposmod(o, total)
		o += 0.25
	return best if best_d < 9.0 else c.get_closest_offset(flat)


## Zmiana pozycji na zamkniętej pętli: przejście przez metę nie robi skoku o całą długość.
static func wrap_delta(d: float, total: float) -> float:
	if d > total * 0.5:
		return d - total
	if d < -total * 0.5:
		return d + total
	return d


## Mnożnik przyczepności nawierzchni w danym punkcie.
func grip_at(pos: Vector3) -> float:
	var p := Vector2(pos.x, pos.z)
	for r in m.get("rugs", []):
		if r.rect.has_point(p):
			return r.grip
	for r in m.get("rooms", []):
		if r.rect.has_point(p):
			return r.grip
	return 1.0


## Ściany między kamerą a celem robią się półprzezroczyste.
func update_fade(cam: Vector3, target: Vector3, dt: float) -> void:
	var c := Vector2(cam.x, cam.z)
	var p := Vector2(target.x, target.z)
	for s in _fade_segs:
		var hit: bool = Geometry2D.segment_intersects_segment(c, p, s.a, s.b) != null \
			or Geometry2D.get_closest_point_to_segment(c, s.a, s.b).distance_to(c) < 0.9
		s.alpha = move_toward(s.alpha, 0.2 if hit else 1.0, dt * 4.0)
		var m: StandardMaterial3D = s.mat
		m.albedo_color.a = s.alpha
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if s.alpha < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED


## Migające lampy i falująca woda.
func _process(dt: float) -> void:
	_t += dt
	for f in _flick:
		var r := fposmod(sin(floor(_t * 12.0) * 12.9898 + f.ph) * 43758.5453, 1.0)
		var on := r > 0.22 and fposmod(_t + f.ph, 4.0) > 0.35     # nerwowe przerwy + dłuższe zgaśnięcie co 4 s
		f.light.light_energy = f.e if on else f.e * 0.06
		f.mat.emission_energy_multiplier = 4.0 if on else 0.25
	for wm in _water_mats:
		wm.uv1_offset += Vector3(0.025, 0.0, 0.015) * dt


# ---------- materiały ----------

## Tekstury generowane raz: beton z żółto-czarnym pasem i czerwonymi liniami, cegła, kafelki, siatka.
static var _garage_tex: ImageTexture
static var _brick_tex: ImageTexture
static var _tile_tex: ImageTexture
static var _fence_tex: ImageTexture
static var _water_n: NoiseTexture2D


static func _concrete_image(w: int, h: int, height: float) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for y in h:
		var hm := (1.0 - (y + 0.5) / h) * height      # wysokość nad podłogą [m]
		for x in w:
			var xm := x / float(w) * 2.0
			var c := Color(0.56, 0.56, 0.54) * (0.9 + rng.randf() * 0.12)
			c = c.darkened(0.06 * sin(xm * 7.0 + hm * 1.3) * sin(xm * 2.0))
			if hm < 0.6:
				c = Color(0.95, 0.75, 0.08) if int(floor((xm + hm) / 0.3)) % 2 == 0 else Color(0.06, 0.06, 0.06)
			elif (hm > 0.6 and hm < 0.67) or (hm > 1.9 and hm < 1.96):
				c = Color(0.8, 0.08, 0.08)
			img.set_pixel(x, y, c)
	return img


## Materiał ściany w danym stylu; ściany przenikające (fade) dostają własny egzemplarz, reszta wspólny.
func _wall_mat(color: Color, style: String, fade: bool) -> StandardMaterial3D:
	var key := "%s|%s" % [style, color]
	if not fade and _wall_cache.has(key):
		return _wall_cache[key]
	var wm := _new_wall_mat(color, style)
	if not fade:
		_wall_cache[key] = wm
	return wm


func _new_wall_mat(color: Color, style: String) -> StandardMaterial3D:
	match style:
		"garage":
			if _garage_tex == null:
				_garage_tex = ImageTexture.create_from_image(_concrete_image(256, 448, m.get("height", 2.8)))
			var gm := _tex_mat(_garage_tex, Vector3(0.5, 1.0 / m.get("height", 2.8), 0.5), 0.85)
			if _plaster_n == null:
				surface(Color.WHITE)
			gm.normal_enabled = true
			gm.normal_texture = _plaster_n
			gm.normal_scale = 0.2
			return gm
		"brick":
			return _brick_mat()
		"tile":
			if _tile_tex == null:
				var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
				var rng := RandomNumberGenerator.new()
				rng.seed = 11
				for y in 128:
					for x in 128:
						var grout := x % 16 == 0 or y % 16 == 0
						img.set_pixel(x, y, Color(0.6, 0.6, 0.58) if grout else Color.WHITE * (0.96 + 0.04 * rng.randf()))
				img.generate_mipmaps()
				_tile_tex = ImageTexture.create_from_image(img)
			var tm := _tex_mat(_tile_tex, Vector3.ONE / 1.2, 0.25)      # kafel 15 cm
			tm.albedo_color = color.lightened(0.3)
			return tm
		"fence":
			if _fence_tex == null:
				var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
				for y in 32:
					for x in 32:
						var wire := (x + y) % 16 < 2 or posmod(x - y, 16) < 2
						img.set_pixel(x, y, Color(0.62, 0.64, 0.66, 1.0 if wire else 0.0))
				_fence_tex = ImageTexture.create_from_image(img)
			var fm := _tex_mat(_fence_tex, Vector3(5, 5, 5), 0.45)      # oczko siatki 10 cm
			fm.metallic = 0.6
			fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			fm.cull_mode = BaseMaterial3D.CULL_DISABLED
			return fm
		"metal":
			var mm: StandardMaterial3D = Decor.corrugated(color).duplicate()
			return mm
	return surface(color.lightened(0.08), 0.92)


static func _tex_mat(tex: Texture2D, scale: Vector3, rough: float) -> StandardMaterial3D:
	var tm := mat(Color.WHITE, rough)
	tm.albedo_texture = tex
	tm.uv1_triplanar = true
	tm.uv1_world_triplanar = true
	tm.uv1_scale = scale
	return tm


func _brick_mat() -> StandardMaterial3D:
	if _brick_tex == null:
		var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for y in 256:
			var row := y / 16                      # 16 rzędów cegieł na 2 m
			for x in 256:
				var xx := (x + (16 if row % 2 else 0)) % 256
				var mortar := y % 16 < 2 or xx % 32 < 2
				var c := Color(0.62, 0.62, 0.6) if mortar else Color(0.5, 0.2, 0.14) * (0.85 + 0.2 * rng.randf())
				img.set_pixel(x, y, c)
		_brick_tex = ImageTexture.create_from_image(img)
	return _tex_mat(_brick_tex, Vector3(0.5, 0.5, 0.5), 0.9)


## Szum jako tekstura (raz na grę): plamistość tynku/betonu i normal mapa nierówności.
static var _plaster: NoiseTexture2D
static var _plaster_n: NoiseTexture2D


static func _noise_tex(freq: float, normal: bool, bump := 4.0) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_octaves = 5
	var t := NoiseTexture2D.new()
	t.width = 512
	t.height = 512
	t.seamless = true
	t.noise = n
	t.as_normal_map = normal
	t.bump_strength = bump
	return t


## Materiał tynku/betonu: kolor + delikatna plamistość + normal mapa (triplanar w metrach świata).
static func surface(c: Color, rough := 0.9, scale := 1.5, normal_depth := 0.18) -> StandardMaterial3D:
	if _plaster == null:
		_plaster = _noise_tex(0.008, false)
		var ramp := Gradient.new()
		ramp.set_color(0, Color(0.93, 0.93, 0.93))
		ramp.set_color(1, Color(1, 1, 1))
		_plaster.color_ramp = ramp
		_plaster_n = _noise_tex(0.05, true, 6.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = _plaster
	m.roughness = rough
	m.normal_enabled = true
	m.normal_texture = _plaster_n
	m.normal_scale = normal_depth
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	return m


## Nowy (niewspółdzielony) materiał — do modyfikacji. Wspólne: Decor.mat.
static func mat(c: Color, rough := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


# ---------- budowa ----------

## Bryła stała z kolizją; angle [rad] w konwencji przeszkód. Wystająca ponad podłogę = przeszkoda.
func _static_box(size: Vector3, pos: Vector3, m: Material, angle := 0.0) -> MeshInstance3D:
	var body := StaticBody3D.new()
	body.collision_layer = LAYER_STATIC
	body.collision_mask = 0
	body.position = pos
	body.rotation.y = -angle
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	var mi := Decor.box(body, size, Vector3.ZERO, m)
	add_child(body)
	if pos.y + size.y * 0.5 > 0.05:      # ściany, meble, filary — nie podłogi
		add_obstacle(Vector2(pos.x, pos.z), Vector2(size.x, size.z) * 0.5, angle)
	return mi


## Podłoga: płyta z kolizją pod każdym pomieszczeniem (między nimi może być woda albo nic) + wzór z shadera.
func _floors() -> void:
	var slab := Decor.mat(Color(0.2, 0.2, 0.2))
	for r in m.get("rooms", []):
		var rc: Rect2 = r.rect
		_static_box(Vector3(rc.size.x, 0.2, rc.size.y), Vector3(rc.get_center().x, -0.1, rc.get_center().y), slab)
	var shader: Shader = preload("res://games/race/floor.gdshader")
	for r in m.get("rooms", []):
		_floor_quad(r.rect, 0.001, r.floor, r.a, r.b, shader)
	for r in m.get("rugs", []):
		if not r.get("puddle", false):
			_floor_quad(r.rect, 0.006, 4, r.a, r.b, shader)
			continue
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = r.rect.size
		mi.mesh = pm
		mi.position = Vector3(r.rect.get_center().x, 0.008, r.rect.get_center().y)
		var pm2 := mat(r.get("color", Color(0.55, 0.75, 1.0, 0.35)), 0.02)
		pm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pm2.metallic = 0.6
		mi.material_override = pm2
		add_child(mi)


func _floor_quad(rc: Rect2, y: float, mode: int, a: Color, b: Color, shader: Shader) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = rc.size
	mi.mesh = pm
	mi.position = Vector3(rc.get_center().x, y, rc.get_center().y)
	var sm := ShaderMaterial.new()
	sm.shader = shader
	sm.set_shader_parameter("mode", mode)
	sm.set_shader_parameter("col_a", a)
	sm.set_shader_parameter("col_b", b)
	if _plaster_n == null:
		surface(Color.WHITE)
	sm.set_shader_parameter("bump_tex", _plaster_n)
	mi.material_override = sm
	add_child(mi)


## Woda: obszar bez podłogi, tafla na „level”, ciemne dno, betonowe ściany studni pod krawędziami
## (górą na −0,01, czyli schowane pod płytą pokoju); prostokąt to przeszkoda dla walidatora.
## Kredens, który wpadnie, spada poniżej −1,2 m i wraca na tor (Kredens: „postaw”).
func _water() -> void:
	var water: Array = m.get("water", [])
	if water.is_empty():
		return
	if _water_n == null:
		_water_n = _noise_tex(0.02, true, 3.0)
	var concrete := surface(Color(0.42, 0.42, 0.4), 0.95, 1.0, 0.3)
	for w in water:
		var rc: Rect2 = w.rect
		var lvl: float = w.get("level", -0.8)
		var c: Color = w.get("color", Color(0.1, 0.2, 0.25))
		add_obstacle(rc.get_center(), rc.size * 0.5)
		var wm := mat(Color(c.r, c.g, c.b, 0.86), 0.04)
		wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wm.metallic = 0.25
		wm.metallic_specular = 0.9
		wm.normal_enabled = true
		wm.normal_texture = _water_n
		wm.normal_scale = 0.6
		wm.uv1_triplanar = true
		wm.uv1_world_triplanar = true
		wm.uv1_scale = Vector3.ONE * 0.12
		_water_mats.append(wm)
		_plane(rc, lvl, wm)
		_plane(rc, lvl - 1.2, Decor.mat(c.darkened(0.7), 1.0))
		var y0 := lvl - 1.3
		for e in _water_edges(rc, water):
			var a: Vector2 = e[0]
			var b: Vector2 = e[1]
			var out: Vector2 = e[2]
			var mid := (a + b) * 0.5 + out * 0.15
			var size := Vector3(a.distance_to(b) + 0.3, -0.01 - y0, 0.3)
			var mi := Decor.box(self, size, Vector3(mid.x, (y0 - 0.01) * 0.5, mid.y), concrete)
			mi.rotation.y = -atan2(b.y - a.y, b.x - a.x)


func _plane(rc: Rect2, y: float, mt: Material) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = rc.size
	mi.mesh = pm
	mi.position = Vector3(rc.get_center().x, y, rc.get_center().y)
	mi.material_override = mt
	add_child(mi)


## Odcinki brzegu prostokąta wody, które nie graniczą z inną wodą: [a, b, normalna na zewnątrz].
static func _water_edges(rc: Rect2, water: Array) -> Array:
	var out := []
	# [stała współrzędna, czy wzdłuż X, kierunek na zewnątrz, początek, koniec]
	var edges := [[rc.position.y, true, -1.0, rc.position.x, rc.end.x], [rc.end.y, true, 1.0, rc.position.x, rc.end.x],
		[rc.position.x, false, -1.0, rc.position.y, rc.end.y], [rc.end.x, false, 1.0, rc.position.y, rc.end.y]]
	for ed in edges:
		var spans := [Vector2(ed[3], ed[4])]
		for w in water:
			var o: Rect2 = w.rect
			if o == rc:
				continue
			# sąsiad przylega od zewnątrz tej krawędzi?
			var touch: float = (o.end.y if ed[2] < 0 else o.position.y) if ed[1] else (o.end.x if ed[2] < 0 else o.position.x)
			if absf(touch - ed[0]) > 0.05:
				continue
			var cover := Vector2(o.position.x, o.end.x) if ed[1] else Vector2(o.position.y, o.end.y)
			var next := []
			for s in spans:
				if cover.x > s.x:
					next.append(Vector2(s.x, minf(s.y, cover.x)))
				if cover.y < s.y:
					next.append(Vector2(maxf(s.x, cover.y), s.y))
			spans = next.filter(func(s: Vector2) -> bool: return s.y - s.x > 0.01)
		for s in spans:
			if ed[1]:
				out.append([Vector2(s.x, ed[0]), Vector2(s.y, ed[0]), Vector2(0, ed[2])])
			else:
				out.append([Vector2(ed[0], s.x), Vector2(ed[0], s.y), Vector2(ed[2], 0)])
	return out


## Ściana od y0 do y1 między punktami a i b (pod dowolnym kątem). style: plain, garage, brick, tile,
## fence, metal ("" = wall_style mapy). Przenika (półprzezroczysta przed kamerą) tylko gdy sięga wyżej
## niż 1,2 m (płot z siatki nie przenika — i tak jest ażurowy).
func _wall(a: Vector2, b: Vector2, y0: float, y1: float, solid: bool, style: String) -> void:
	var st: String = style if style != "" else m.get("wall_style", "plain")
	var length := a.distance_to(b) + (T if solid else 0.0)
	var dir := (b - a).normalized()
	var ang := atan2(dir.y, dir.x)
	var size := Vector3(length, y1 - y0, T)
	var mid := (a + b) * 0.5
	var normal := Vector2(-dir.y, dir.x)
	if normal.x + normal.y < 0.0:
		normal = -normal
	var color := Color(0.85, 0.82, 0.75)
	for side in [normal * 0.3, -normal * 0.3]:
		var r := _room_at(mid + side)
		if not r.is_empty():
			color = r.wall
			break
	var fade := y1 > 1.2 and st != "fence"       # wierzch powyżej 1,2 m (także nadproża drzwi)
	var wm := _wall_mat(color, st, fade)
	var pos := Vector3(mid.x, (y0 + y1) * 0.5, mid.y)
	if solid:
		_static_box(size, pos, wm, ang)
	else:
		Decor.box(self, size, pos, wm).rotation.y = -ang
	if st == "fence":            # słupki co 2,5 m i rurka u góry
		var fr := Node3D.new()
		fr.position = Vector3(mid.x, y0, mid.y)
		fr.rotation.y = -ang
		add_child(fr)
		var pm := Decor.mat(Color(0.45, 0.47, 0.5), 0.45, 0.6)
		var n := maxi(1, ceili(length / 2.5))
		for i in n + 1:
			Decor.box(fr, Vector3(0.06, y1 - y0 + 0.05, 0.06), Vector3(-length * 0.5 + length * i / n, (y1 - y0 + 0.05) * 0.5, 0), pm)
		Decor.box(fr, Vector3(length, 0.05, 0.05), Vector3(0, y1 - y0, 0), pm)
	if fade:
		_fade_segs.append({"a": a, "b": b, "mat": wm, "alpha": 1.0})


func _room_at(p: Vector2) -> Dictionary:
	for r in m.get("rooms", []):
		if r.rect.has_point(p):
			return r
	return {}


## Próg: najazd, płaski blat, zjazd (wszystko z kolizją).
## Wzdłuż Z: [x, z_start, szer. wzdłuż X, najazd, blat, wysokość, kolor]
## Wzdłuż X: [x_start, z, szer. wzdłuż Z, najazd, blat, wysokość, kolor, "x"]
func _hump(h: Array) -> void:
	var along_x: bool = h.size() > 7 and h[7] == "x"
	var cross: float = h[1] if along_x else h[0]
	var s: float = h[0] if along_x else h[1]
	var w: float = h[2]
	var l: float = h[3]
	var top: float = h[4]
	var ht: float = h[5]
	var mt := Decor.mat(h[6], 0.6)
	_board(cross, w, s, s + l, 0.0, ht, mt, along_x)
	_board(cross, w, s + l, s + l + top, ht, ht, mt, along_x)
	_board(cross, w, s + l + top, s + 2.0 * l + top, ht, 0.0, mt, along_x)


## Deska szerokości w (od c w poprzek), której górna powierzchnia biegnie od (s0, y0) do (s1, y1)
## wzdłuż Z (albo wzdłuż X, gdy along_x).
func _board(c: float, w: float, s0: float, s1: float, y0: float, y1: float, m: Material, along_x := false) -> void:
	var l := s1 - s0
	var ang := atan2(y1 - y0, l)
	var thick := 0.06 if y0 != y1 else y0
	var body := StaticBody3D.new()
	body.collision_layer = LAYER_STATIC
	body.collision_mask = 0
	var up := Vector3(0, cos(ang), -sin(ang))
	var p := Vector3(c + w * 0.5, (y0 + y1) * 0.5, (s0 + s1) * 0.5) - up * thick * 0.5   # x = w poprzek, z = wzdłuż
	body.rotation.x = -ang
	body.position = p
	if along_x:      # obrót o 90° wokół Y: lokalne „wzdłuż” (+Z) staje się +X
		body.basis = Basis(Vector3.UP, PI / 2) * body.basis
		body.position = Vector3(p.z, p.y, p.x)
	var size := Vector3(w, thick, sqrt(l * l + (y1 - y0) * (y1 - y0)))
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	Decor.box(body, size, Vector3.ZERO, m)
	add_child(body)


func _furniture(f: Array) -> void:
	var size := Vector3(f[2], f[4], f[3])
	var fm: Material = _brick_mat() if f.size() > 6 and f[6] == "brick" else Decor.mat(f[5], 0.6)
	_static_box(size, Vector3(f[0] + f[2] * 0.5, f[4] * 0.5, f[1] + f[3] * 0.5), fm)


## Rekwizyt fizyczny: [x, z, szer., wys., głęb., masa, kolor, rodzaj?] — rodzaj modelu z Decor.prop_model.
func _prop(p: Array) -> void:
	var kind: String = p[7] if p.size() > 7 else "box"
	var body := RigidBody3D.new()
	body.collision_layer = LAYER_PROPS
	body.collision_mask = LAYER_STATIC | 2 | LAYER_PROPS
	body.mass = p[5]
	var size := Vector3(p[2], p[3], p[4])
	body.position = Vector3(p[0], size.y * 0.5 + 0.01, p[1])
	var cs := CollisionShape3D.new()
	cs.shape = Decor.prop_shape(kind, size)
	body.add_child(cs)
	body.add_child(Decor.prop_model(kind, size, p[6]))
	add_child(body)


# ---------- strop, lampy, filary, auta, strzałki, linie ----------

## Strop z lampami (lamp_color, lamp_energy; „flicker” = indeksy migających), strzałki pod stropem.
func _ceiling() -> void:
	var sz: Vector2 = m.size
	var h: float = m.get("height", 2.8)
	var ceil := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(sz.x, 0.3, sz.y)
	ceil.mesh = cb
	ceil.position = Vector3(sz.x * 0.5, h + 0.15, sz.y * 0.5)
	ceil.material_override = surface(Color(0.5, 0.5, 0.5), 0.95, 1.0, 0.3)
	add_child(ceil)
	var lc: Color = m.get("lamp_color", Color(1.0, 0.88, 0.7))
	var le: float = m.get("lamp_energy", 1.4)
	var lamp_m := mat(Color(1, 0.95, 0.85))
	lamp_m.emission_enabled = true
	lamp_m.emission = m.get("lamp_color", Color(1.0, 0.85, 0.6))
	lamp_m.emission_energy_multiplier = 4.0
	var flicker: Array = m.get("flicker", [])
	var lamps: Array = m.get("lamps", [])
	for k in lamps.size():
		var p: Vector2 = lamps[k]
		var lm: StandardMaterial3D = lamp_m.duplicate() if k in flicker else lamp_m
		Decor.box(self, Vector3(1.2, 0.06, 0.35), Vector3(p.x, h - 0.03, p.y), lm)
		var ol := OmniLight3D.new()
		ol.position = Vector3(p.x, h - 0.35, p.y)
		ol.light_color = lc
		ol.light_energy = le
		ol.omni_range = 9.0
		ol.shadow_enabled = k % 6 == 0 and take_shadow()
		add_child(ol)
		if k in flicker:
			_flick.append({"light": ol, "mat": lm, "e": le, "ph": k * 1.7})
	var arrow_m := StandardMaterial3D.new()
	arrow_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow_m.albedo_color = Color(0.25, 0.85, 0.3)
	arrow_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for a in m.get("arrows", []):
		_arrow(a, h - 0.02, arrow_m)


## Filary, auta i linie (każda mapa); strzałki malowane na podłodze, gdy nie ma stropu.
## Strzałka: [x, z, kierunek°, kolor?]; linia: [x1, z1, x2, z2, kolor, szerokość = 0,12].
func _ground_details(covered: bool) -> void:
	var h: float = m.get("height", 2.8)
	var pillar_m := _wall_mat(Color.WHITE, m.get("wall_style", "plain"), false)
	for p in m.get("pillars", []):
		_static_box(Vector3(0.75, h, 0.75), Vector3(p.x, h * 0.5, p.y), pillar_m)
	for c in m.get("cars", []):
		_parked_car(c)
	if not covered:
		for a in m.get("arrows", []):
			_arrow(a, 0.005, Decor.mat(a[3] if a.size() > 3 else Color(0.92, 0.92, 0.9), 0.6))
	for l in m.get("lines", []):
		var a2 := Vector2(l[0], l[1])
		var b2 := Vector2(l[2], l[3])
		var mi := Decor.box(self, Vector3(a2.distance_to(b2), 0.004, l[5] if l.size() > 5 else 0.12),
			Vector3((a2.x + b2.x) * 0.5, 0.004, (a2.y + b2.y) * 0.5), Decor.mat(l[4], 0.6))
		mi.rotation.y = -atan2(b2.y - a2.y, b2.x - a2.x)


func _arrow(a: Array, y: float, mt: Material) -> void:
	var am := MeshInstance3D.new()
	am.mesh = _arrow_mesh()
	am.material_override = mt
	am.position = Vector3(a[0], y, a[1])
	am.rotation.y = -deg_to_rad(a[2])
	am.scale = Vector3.ONE * 0.7
	add_child(am)


## Płaska strzałka 2,4 m wskazująca +X (obracana przy wstawianiu).
static var _arrow_m: ArrayMesh


static func _arrow_mesh() -> ArrayMesh:
	if _arrow_m:
		return _arrow_m
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var pts := [Vector2(-1.2, -0.3), Vector2(0.2, -0.3), Vector2(0.2, 0.3), Vector2(-1.2, 0.3),
		Vector2(0.2, -0.7), Vector2(1.2, 0.0), Vector2(0.2, 0.7)]
	for tri in [[0, 1, 2], [0, 2, 3], [4, 5, 6]]:     # zgodnie z zegarem patrząc z góry = przód
		for i in tri:
			st.add_vertex(Vector3(pts[i].x, 0, pts[i].y))
	_arrow_m = st.commit()
	return _arrow_m


## Zaparkowane auto z prymitywów (przeszkoda stała). c = [x, z, kierunek°, kolor, rodzaj: maly|duzy|bus|van]
## Kierunek: 0° = przodem na +X, 90° = na +Z.
func _parked_car(c: Array) -> void:
	var kind: String = c[4]
	var d: Array = CAR_DIMS[kind]
	var length: float = d[0]
	var width: float = d[1]
	var body_h: float = d[2]
	var wr: float = d[5]
	var body := StaticBody3D.new()
	body.collision_layer = LAYER_STATIC
	body.collision_mask = 0
	body.position = Vector3(c[0], 0, c[1])
	body.rotation.y = -deg_to_rad(c[2]) + PI / 2   # model ma przód na +Z
	add_child(body)
	add_obstacle(Vector2(c[0], c[1]), Vector2(length, width) * 0.5, deg_to_rad(c[2]))   # długość wzdłuż kierunku jazdy
	var total_h: float = wr * 0.8 + body_h + d[4]
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(width, total_h, length)
	cs.shape = bs
	cs.position.y = total_h * 0.5
	body.add_child(cs)
	var paint := Decor.mat(c[3], 0.25, 0.3)
	var glass := Decor.mat(Color(0.06, 0.07, 0.09), 0.1)
	var y0 := wr * 0.8
	Decor.box(body, Vector3(width, body_h, length), Vector3(0, y0 + body_h * 0.5, 0), paint)
	if kind == "bus":
		Decor.box(body, Vector3(width + 0.02, 0.9, length - 1.0), Vector3(0, y0 + body_h - 0.75, 0.2), glass)
		Decor.box(body, Vector3(width - 0.1, 0.05, length), Vector3(0, y0 + body_h + 0.02, 0), Decor.mat(Color(0.9, 0.9, 0.9)))
	elif kind == "van":      # dostawczak: kabina z szybami z przodu, reszta to skrzynia
		Decor.box(body, Vector3(width + 0.02, 0.5, 1.1), Vector3(0, y0 + body_h - 0.42, length * 0.5 - 0.75), glass)
		Decor.box(body, Vector3(width - 0.2, 0.55, 0.04), Vector3(0, y0 + body_h - 0.42, length * 0.5 + 0.01), glass)
	else:
		Decor.box(body, Vector3(width - 0.12, d[4], d[3]), Vector3(0, y0 + body_h + d[4] * 0.5, -0.15), glass)
		Decor.box(body, Vector3(width - 0.16, 0.05, d[3] - 0.15), Vector3(0, y0 + body_h + d[4] + 0.02, -0.15), paint)
	for sx in [-1.0, 1.0]:
		Decor.box(body, Vector3(0.25, 0.12, 0.04), Vector3(sx * (width * 0.5 - 0.22), y0 + body_h * 0.6, length * 0.5 + 0.01), Decor.mat(Color(1, 1, 0.9)))
		Decor.box(body, Vector3(0.25, 0.12, 0.04), Vector3(sx * (width * 0.5 - 0.22), y0 + body_h * 0.6, -length * 0.5 - 0.01), Decor.mat(Color(0.8, 0.05, 0.05)))
	var tyre := Decor.mat(Color(0.05, 0.05, 0.05), 0.9)
	for zs in [-1.0, 1.0]:
		for xs in [-1.0, 1.0]:
			var w := Decor.cyl(body, wr, 0.2, Vector3(xs * (width * 0.5 - 0.08), wr, zs * (length * 0.5 - wr * 1.6)), tyre)
			w.rotation.z = PI / 2
