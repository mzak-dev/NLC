class_name Kredens
extends VehicleBody3D
## Kredens na kółkach meblowych. Przód = +Z (kredens jedzie bokiem, jak przy przeprowadzce),
## fronty szafek patrzą w +X. Sterowanie: gracz albo bot jadący po Curve3D.

const TYPES := [
	{"id": "standard", "name": "Kredens PRL „Standard”",
		"desc": "Orzech, nadstawka z szybkami, kryształy po babci. Stał w każdym M3. Zbalansowany.",
		"color": Color(0.42, 0.25, 0.13), "w": 1.5, "d": 0.5, "hl": 0.82, "doors": 2, "drawers": 1, "ht": 0.9, "dt": 0.34, "glass": true,
		"mass": 110.0, "accel": 4.2, "vmax": 8.5, "steer": 0.62, "com": 0.22, "roll": 0.18, "grip": 1.0},
	{"id": "shadow", "name": "Kredens „Shadow”",
		"desc": "Dokładnie ten sam kredens, tylko czarny. A każdy wie, że czarne jest szybsze.",
		"color": Color(0.02, 0.02, 0.025), "rough": 0.12, "knob": Color(0.85, 0.85, 0.9),
		"w": 1.5, "d": 0.5, "hl": 0.82, "doors": 2, "drawers": 1, "ht": 0.9, "dt": 0.34, "glass": true,
		"mass": 110.0, "accel": 4.7, "vmax": 9.6, "steer": 0.62, "com": 0.22, "roll": 0.18, "grip": 1.0},
	{"id": "witryna", "name": "Witryna Babci",
		"desc": "Wysoka, przeszklona, pełna kryształów. Zwrotna i lekka, ale lubi się przewracać.",
		"color": Color(0.88, 0.85, 0.78), "w": 0.95, "d": 0.45, "hl": 0.55, "doors": 2, "drawers": 0, "ht": 1.25, "dt": 0.4, "glass": true,
		"mass": 70.0, "accel": 4.6, "vmax": 8.8, "steer": 0.7, "com": 0.42, "roll": 0.3, "grip": 1.08},
	{"id": "masyw", "name": "Dębowy Masyw",
		"desc": "Gdański, rzeźbiony, ciężki jak przeprowadzka na czwarte piętro. Wolno rusza, ale taranuje wszystko.",
		"color": Color(0.27, 0.15, 0.07), "w": 1.9, "d": 0.62, "hl": 0.95, "doors": 3, "drawers": 1, "ht": 0.0, "dt": 0.0, "glass": false,
		"mass": 220.0, "accel": 3.1, "vmax": 10.0, "steer": 0.5, "com": 0.16, "roll": 0.1, "grip": 0.95},
	{"id": "flatpack", "name": "Meblościanka do samodzielnego montażu",
		"desc": "Sosna, otwarte półki, dwie śrubki zostały w woreczku. Szybko rusza, wolno jedzie.",
		"color": Color(0.86, 0.72, 0.5), "w": 1.2, "d": 0.42, "hl": 0.72, "doors": 2, "drawers": 0, "ht": 0.7, "dt": 0.3, "glass": false, "open": true,
		"mass": 45.0, "accel": 5.6, "vmax": 7.8, "steer": 0.68, "com": 0.25, "roll": 0.16, "grip": 1.1},
]
const BASE_GRIP := 1.4
const Y0 := 0.2           # spód kredensu nad punktem zawieszenia (prześwit na progi)

# Uszkodzenia. Siła uderzenia = skok prędkości w jednym kroku fizyki [m/s].
const HIT_LIGHT := 1.5    # drzwi się odblokowują
const HIT_MED := 3.0      # zawartość wypada, szyba pęka
const HIT_HARD := 5.5     # odpadają części, luzy na kółkach
const HIT_COOLDOWN := 0.3 # jedno zderzenie trwa kilka kroków — liczymy je raz
const DOOR_MAX := 1.9     # maks. kąt otwarcia drzwi [rad]
const DOOR_DRAG := 0.04   # ubytek prędkości maks. na każde otwarte drzwi
const CONTENT_SHARE := 0.15  # część masy kredensu, którą stanowi zawartość
const DOOR_SHARE := 0.04
const TOP_SHARE := 0.25
const GRIP_LOSS := 0.06   # ubytek przyczepności na mocne uderzenie…
const GRIP_FLOOR := 0.7   # …ale nie niżej niż tyle
const DEBRIS_LIFE := 8.0  # po tylu sekundach odłamki znikają (boty nie klinują się na gruzie)

signal damaged(level: int)    # 1 lekkie, 2 średnie, 3 mocne

var t: Dictionary
var is_bot := false
var device := "any"        # urządzenie wejścia człowieka (patrz PlayerInput)
var controls_enabled := false
var curve: Curve3D
var surface_fn: Callable
var lane := 0.0
var track_off := -1.0      # ostatnia znana pozycja na torze (szukanie lokalne)
var skill := 1.0
var flips := 0
var flip_t := 0.0
var wheels: Array[VehicleWheel3D] = []
var _stuck_t := 0.0
var _high_t := 0.0         # jak długo stoi wysoko (utknięty na meblu)
var _reset_prev := false
var _reverse_t := 0.0
var latched := true        # drzwi zamknięte na zatrzask
var hard_hits := 0
var grip_k := 1.0          # mnożnik przyczepności od luzów na kółkach
var vmax_k := 1.0          # mnożnik prędkości maks. od otwartych drzwi
var _parts := {}
var _stash := 0            # garnki i talerze schowane za drzwiami (powstają dopiero, gdy wypadają)
var _items := 1            # ile sztuk zawartości było na starcie (udział w masie)
var _lost := 0.0           # utracona część masy
var _prev_v := Vector3.ZERO
var _hit_cd := 0.0
var _t := 0.0
var _top_shape: CollisionShape3D


func setup(type: Dictionary) -> void:
	t = type
	mass = t.mass
	collision_layer = 2
	collision_mask = 1 | 2
	linear_damp = 0.3
	angular_damp = 1.0
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, t.com, 0)
	var model := build_model(t)
	add_child(model)
	_parts = model.get_meta("parts")
	_stash = _parts.doors.size() * 3
	_items = maxi(1, _parts.contents.size() + _stash)
	var d: float = t.d
	var w: float = t.w
	var hl: float = t.hl
	_shape(Vector3(d, hl + 0.08, w), Vector3(0, Y0 + (hl + 0.08) * 0.5, 0))
	if t.ht > 0.0:
		_top_shape = _shape(Vector3(t.dt, t.ht, w - 0.08), Vector3(-d * 0.5 + t.dt * 0.5, Y0 + 0.08 + hl + 0.03 + t.ht * 0.5, 0))
	var castor := Kredens.mat(Color(0.08, 0.08, 0.08), 0.5)
	for corner in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var wh := VehicleWheel3D.new()
		wh.position = Vector3(corner.x * (d * 0.5 - 0.06), 0.17, corner.y * (w * 0.5 - 0.1))
		wh.use_as_steering = corner.y > 0
		wh.use_as_traction = corner.y < 0
		wh.wheel_radius = 0.075
		wh.wheel_rest_length = 0.1
		wh.suspension_travel = 0.1
		wh.suspension_stiffness = 50.0
		wh.suspension_max_force = mass * 30.0
		wh.damping_compression = 2.0
		wh.damping_relaxation = 2.5
		wh.wheel_friction_slip = BASE_GRIP * t.grip
		wh.wheel_roll_influence = t.roll
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.075
		cm.bottom_radius = 0.075
		cm.height = 0.045
		mi.mesh = cm
		mi.rotation.z = PI / 2
		mi.material_override = castor
		wh.add_child(mi)
		add_child(wh)
		wheels.append(wh)


func _shape(size: Vector3, pos: Vector3) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = pos
	add_child(cs)
	return cs


# ---------- jazda ----------

func _physics_process(dt: float) -> void:
	_t += dt
	var dv := linear_velocity - _prev_v
	_prev_v = linear_velocity
	_hit_cd -= dt
	if _hit_cd <= 0.0 and dv.length() >= HIT_LIGHT:
		_hit_cd = HIT_COOLDOWN
		take_hit(dv.length())
	_swing_doors(global_basis.inverse() * dv / dt, dt)
	var vmax: float = t.vmax * vmax_k
	var fwd := linear_velocity.dot(global_basis.z)
	var reset_pressed := false
	var input := Vector3.ZERO      # x = gaz, y = skręt (+ w lewo), z = ręczny
	if controls_enabled:
		if is_bot:
			input = _bot_input(dt)
		else:
			var r := PlayerInput.read(device)
			input = Vector3(r.throttle, r.steer, 1.0 if r.handbrake else 0.0)
			reset_pressed = r.reset and not _reset_prev    # tylko zbocze
			_reset_prev = r.reset
	var max_steer: float = t.steer * lerpf(1.0, 0.55, clampf(absf(fwd) / vmax, 0.0, 1.0))
	# luzy na kółkach: kredens myszkuje tym mocniej, im więcej mocnych uderzeń zebrał
	var wobble := sin(_t * 19.0) * 0.015 * minf(hard_hits, 5.0)
	steering = move_toward(steering, input.y * max_steer + wobble, dt * 3.0)
	# kółka meblowe są obrotowe: tylne skręcają przeciwnie, co skraca promień skrętu długiego kredensu
	for wh in wheels:
		if not wh.use_as_steering:
			wh.steering = -steering * 0.6
	var force: float = t.mass * t.accel * 0.5
	brake = 0.0
	if input.x > 0.0:
		engine_force = input.x * force if fwd < vmax * skill else 0.0
	elif input.x < 0.0:
		engine_force = input.x * force * (1.5 if fwd > 0.5 else 0.6)
	else:
		engine_force = 0.0
		brake = 0.4 if controls_enabled else 3.0
	for wh in wheels:
		var g: float = BASE_GRIP * t.grip * grip_k * (surface_fn.call(wh.global_position) if surface_fn.is_valid() else 1.0)
		if input.z > 0.0 and not wh.use_as_steering:
			g *= 0.35
		wh.wheel_friction_slip = g

	if global_basis.y.dot(Vector3.UP) < 0.4:
		flip_t += dt
	else:
		flip_t = 0.0
	if flip_t > 1.5 or reset_pressed or stuck_high(dt, global_position.y, linear_velocity.length()):
		reset_to_track()
	elif global_position.y < -1.2:       # wpadł do dziury / pod mapę
		reset_to_track()
		var col := get_node_or_null("/root/Collection")    # bez identyfikatora autoloadu: skrypt kompiluje się też w testach
		if col != null:
			col.tone(120, 0.4, 0.3, 0.9)    # plusk


## Utknięty wysoko (np. na meblu): y > 0.8 i prawie stoi dłużej niż 3 s. Zwraca true raz i zeruje licznik.
func stuck_high(dt: float, y: float, speed: float) -> bool:
	if y > 0.8 and speed < 0.5:
		_high_t += dt
		if _high_t > 3.001:      # drobny zapas na błąd sumowania floatów
			_high_t = 0.0
			return true
	else:
		_high_t = 0.0
	return false


## Pozycja na torze [m od startu]; szukana lokalnie, żeby nawroty nie myliły odcinków.
func track() -> float:
	track_off = Apartment.closest_near(curve, global_position, track_off) if track_off >= 0.0 		else curve.get_closest_offset(global_position)
	return track_off


func reset_to_track() -> void:
	if curve == null:
		return
	var length := curve.get_baked_length()
	var off := track()
	var p := curve.sample_baked(off)
	var dir := (curve.sample_baked(fposmod(off + 1.0, length)) - p).normalized()
	global_transform = Transform3D(Basis.looking_at(-dir, Vector3.UP), p + Vector3(0, 0.3, 0))
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_prev_v = Vector3.ZERO     # teleport to nie uderzenie
	flip_t = 0.0
	flips += 1


func _bot_input(dt: float) -> Vector3:
	var length := curve.get_baked_length()
	var spd := linear_velocity.length()
	var off := track()
	var look := 2.5 + spd * 0.45
	var tgt := curve.sample_baked(fposmod(off + look, length))
	var tan := (curve.sample_baked(fposmod(off + look + 0.5, length)) - tgt).normalized()
	tgt += Vector3(tan.z, 0, -tan.x) * lane
	var local := to_local(tgt)
	var ang := atan2(local.x, local.z)
	var steer := clampf(ang * 2.2, -1.0, 1.0)
	var here := (curve.sample_baked(fposmod(off + 1.0, length)) - curve.sample_baked(off)).normalized()
	var far := (curve.sample_baked(fposmod(off + look + 4.5, length)) - curve.sample_baked(fposmod(off + look + 3.5, length))).normalized()
	var bend := absf(here.signed_angle_to(far, Vector3.UP))
	var thr := 1.0
	if spd > 3.5 and bend > 0.8:
		thr = 0.15
	if spd > 2.5 and absf(ang) > 1.1:
		thr = -0.6
	if _reverse_t > 0.0:
		_reverse_t -= dt
		return Vector3(-0.8, -steer, 0)
	_stuck_t = _stuck_t + dt if (spd < 0.6 and thr > 0.0) else 0.0
	if _stuck_t > 1.5:
		_stuck_t = 0.0
		_reverse_t = 1.0
	return Vector3(thr, steer, 0)


# ---------- uszkodzenia ----------

## Uderzenie o sile `s` (skok prędkości [m/s]). Publiczne, żeby dało się je testować bez fizyki.
func take_hit(s: float) -> void:
	if s < HIT_LIGHT:
		return
	if latched:
		latched = false
		for dr in _parts.doors:
			dr.w = 3.0            # zatrzask puszcza: drzwi odskakują
	if s >= HIT_MED:
		_spill(0.5)
		_break_glass()
	if s >= HIT_HARD:
		hard_hits += 1
		if hard_hits == 2 and _parts.top != null:
			_rip_top()
		else:
			_rip_door()
	_retune()
	damaged.emit(3 if s >= HIT_HARD else 2 if s >= HIT_MED else 1)


## Jak straty przekładają się na jazdę. Siła silnika liczy się od masy z tabeli (t.mass),
## więc lżejszy kredens rusza szybciej — ale łatwiej go zepchnąć i gorzej trzyma tor.
func _retune() -> void:
	mass = t.mass * (1.0 - _lost)
	center_of_mass.y = t.com * (0.6 if t.ht > 0.0 and _parts.top == null else 1.0)
	grip_k = maxf(GRIP_FLOOR, 1.0 - GRIP_LOSS * hard_hits)


## Udawany zawias: drzwi to wahadło w poziomie, napędzane przeciążeniami kredensu (acc lokalnie).
func _swing_doors(acc: Vector3, dt: float) -> void:
	var open := 0
	if not latched:
		for dr in _parts.doors:
			var a: float = dr.get("a", 0.0)
			var w: float = dr.get("w", 0.0)
			w += 2.5 * (-cos(a) * acc.x + dr.side * sin(a) * acc.z) * dt
			w -= w * 2.0 * dt
			a += w * dt
			if a < 0.0 or a > DOOR_MAX:
				a = clampf(a, 0.0, DOOR_MAX)
				w *= -0.3
			dr.a = a
			dr.w = w
			dr.pivot.rotation.y = dr.side * a
			if a > 0.3:
				open += 1
	vmax_k = 1.0 - DOOR_DRAG * open


## Wyrzuca część `frac` pozostałej zawartości: to, co widać na półkach, i garnki zza drzwi.
func _spill(frac: float) -> void:
	var c: Array = _parts.contents
	for i in ceili(c.size() * frac):
		var mi: MeshInstance3D = c.pop_at(randi() % c.size())
		_detach(mi, mi.mesh.get_aabb().size, Vector3.ZERO, t.mass * CONTENT_SHARE / _items)
		_lost += CONTENT_SHARE / _items
	if _parts.doors.is_empty():
		return
	for i in ceili(_stash * frac):
		_stash -= 1
		var plate := randf() < 0.5
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.09 if plate else 0.07
		cm.bottom_radius = 0.06 if plate else 0.07
		cm.height = 0.02 if plate else 0.1
		mi.mesh = cm
		mi.material_override = mat(Color(0.92, 0.9, 0.85) if plate else Color(0.55, 0.1, 0.08), 0.3, 0.0 if plate else 0.6)
		mi.position = _parts.doors.pick_random().slot + Vector3(0, randf_range(-0.15, 0.15), randf_range(-0.1, 0.1))
		add_child(mi)
		_detach(mi, cm.get_aabb().size, Vector3.ZERO, t.mass * CONTENT_SHARE / _items)
		_lost += CONTENT_SHARE / _items


func _break_glass() -> void:
	var g: MeshInstance3D = _parts.glass
	if g == null:
		return
	_parts.glass = null
	var pane: Vector3 = (g.mesh as BoxMesh).size
	for i in 8:
		var sz := Vector3(0.005, randf_range(0.06, 0.16), randf_range(0.06, 0.16))
		var shard := _box(self, sz, g.position + Vector3(0, randf_range(-0.5, 0.5) * pane.y, randf_range(-0.5, 0.5) * pane.z), g.material_override)
		_detach(shard, sz, Vector3.ZERO, 0.2)
	g.queue_free()


func _rip_door() -> void:
	if _parts.doors.is_empty():
		return
	if _parts.doors.size() == 1:
		_spill(1.0)           # znikają ostatnie drzwi — nic już nie trzyma garnków w środku
	var dr: Dictionary = _parts.doors.pop_at(randi() % _parts.doors.size())
	_detach(dr.pivot, dr.size, dr.center, t.mass * DOOR_SHARE)
	_lost += DOOR_SHARE


func _rip_top() -> void:
	_spill(1.0)
	_break_glass()
	_detach(_parts.top, _parts.top_size, _parts.top_center, t.mass * TOP_SHARE)
	_parts.top = null
	_lost += TOP_SHARE
	_top_shape.queue_free()


## Odrywa część od kredensu: dostaje własną bryłę i leci dalej z jego prędkością.
## ponytail: odłamek jest dzieckiem kredensu z top_level — znika razem z nim i z nim nie koliduje;
## jeśli gruz ma zostawać na torze po restarcie wyścigu, przepiąć go do świata.
func _detach(node: Node3D, size: Vector3, center: Vector3, m: float) -> void:
	var body := RigidBody3D.new()
	body.top_level = true
	body.collision_layer = 4      # Apartment.LAYER_PROPS
	body.collision_mask = 1 | 2 | 4
	body.mass = maxf(m, 0.1)
	body.add_collision_exception_with(self)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = center
	body.add_child(cs)
	var xf := node.global_transform
	add_child(body)
	body.global_transform = xf
	node.reparent(body, false)
	node.transform = Transform3D.IDENTITY
	body.linear_velocity = linear_velocity + global_basis.x * randf_range(0.5, 2.5) + Vector3(randf_range(-1, 1), randf_range(0.5, 2.5), randf_range(-1, 1))
	body.angular_velocity = Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6))
	get_tree().create_timer(DEBRIS_LIFE, false).timeout.connect(body.queue_free)


# ---------- model z prymitywów ----------

## Drewno: tekstura słojów (szum z zawirowaniem, rozciągnięty pionowo) + normal mapa, triplanar.
static var _grain: NoiseTexture2D
static var _grain_n: NoiseTexture2D


static func wood(c: Color, rough := 0.55) -> StandardMaterial3D:
	if _grain == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX
		n.frequency = 0.012
		n.fractal_octaves = 4
		n.domain_warp_enabled = true
		n.domain_warp_amplitude = 20.0
		_grain = NoiseTexture2D.new()
		_grain.width = 512
		_grain.height = 512
		_grain.seamless = true
		_grain.noise = n
		var ramp := Gradient.new()
		ramp.set_color(0, Color(0.7, 0.7, 0.7))
		ramp.set_color(1, Color(1, 1, 1))
		_grain.color_ramp = ramp
		_grain_n = NoiseTexture2D.new()
		_grain_n.width = 512
		_grain_n.height = 512
		_grain_n.seamless = true
		_grain_n.noise = n
		_grain_n.as_normal_map = true
		_grain_n.bump_strength = 3.0
	var m := mat(c, rough)
	m.albedo_texture = _grain
	m.normal_enabled = true
	m.normal_texture = _grain_n
	m.normal_scale = 0.35
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.6, 5.0, 0.6)    # słoje biegną pionowo
	return m


static func mat(c: Color, rough := 0.55, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = m
	parent.add_child(mi)
	return mi


static func _ball(parent: Node3D, r: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	mi.position = pos
	mi.material_override = m
	parent.add_child(mi)
	return mi


## Zwraca model; w meta "parts" części, które mogą się ruszać i odpadać:
## doors [{pivot, side, size, center, slot}], contents [MeshInstance3D], glass, top (+ top_size, top_center).
static func build_model(ty: Dictionary) -> Node3D:
	var root := Node3D.new()
	var parts := {"doors": [], "contents": [], "glass": null, "top": null}
	root.set_meta("parts", parts)
	var dark := mat(Color(0.03, 0.025, 0.02), 0.9)
	var col: Color = ty.color
	var wood := Kredens.wood(col, ty.get("rough", 0.55))
	var trim := Kredens.wood(col.darkened(0.3) if col.v > 0.1 else col.lightened(0.08), ty.get("rough", 0.6))
	var knob := mat(ty.get("knob", Color(0.86, 0.64, 0.3)), 0.3, 1.0)
	var glass := mat(Color(0.75, 0.88, 1.0, 0.22), 0.04, 0.3)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var crystal := mat(Color(0.9, 0.95, 1.0, 0.6), 0.02, 0.5)
	crystal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var d: float = ty.d
	var w: float = ty.w
	var hl: float = ty.hl
	var n: int = ty.doors
	var open: bool = ty.get("open", false)
	_box(root, Vector3(d - 0.04, 0.08, w - 0.06), Vector3(0, Y0 + 0.04, 0), trim)
	var yb := Y0 + 0.08
	_box(root, Vector3(d, hl, w), Vector3(0, yb + hl * 0.5, 0), wood)
	var ytop := yb + hl
	_box(root, Vector3(d + 0.04, 0.03, w + 0.04), Vector3(0, ytop + 0.015, 0), wood)
	var fx := d * 0.5 + 0.008
	var dw := w / n
	var drawer_h := 0.16 if ty.drawers > 0 else 0.0
	var door_h := hl - drawer_h - 0.04
	for i in n:
		var zc := -w * 0.5 + (i + 0.5) * dw
		if drawer_h > 0.0:
			_box(root, Vector3(0.016, drawer_h - 0.03, dw - 0.03), Vector3(fx, ytop - 0.02 - drawer_h * 0.5, zc), trim)
			_ball(root, 0.016, Vector3(fx + 0.02, ytop - 0.02 - drawer_h * 0.5, zc), knob)
		var dy := yb + 0.02 + door_h * 0.5
		if open:
			_box(root, Vector3(0.01, 0.02, dw - 0.04), Vector3(fx - 0.01, dy, zc), trim)
			for b in 4:
				var bc := Color.from_hsv(fmod(0.13 * (i * 4 + b), 1.0), 0.6, 0.6)
				parts.contents.append(_box(root, Vector3(d * 0.7, door_h * 0.38, 0.05), Vector3(0, dy + 0.02 + door_h * 0.19, zc - dw * 0.3 + b * 0.07), mat(bc)))
		else:
			# drzwi wiszą na pivocie przy zawiasie (krawędź przeciwna do gałki); pod spodem ciemne wnętrze
			var side := 1.0 if i % 2 == 0 else -1.0
			var pw := dw - 0.03
			var off := side * pw * 0.5
			var piv := Node3D.new()
			piv.position = Vector3(fx, dy, zc - off)
			root.add_child(piv)
			_box(piv, Vector3(0.016, door_h - 0.03, pw), Vector3(0, 0, off), trim)
			_box(piv, Vector3(0.008, door_h * 0.72, dw * 0.66), Vector3(0.012, 0, off), wood)
			_ball(piv, 0.018, Vector3(0.025, door_h * 0.2, off + side * dw * 0.38), knob)
			_box(root, Vector3(0.004, door_h - 0.05, pw - 0.02), Vector3(d * 0.5 + 0.002, dy, zc), dark)
			parts.doors.append({"pivot": piv, "side": side, "size": Vector3(0.03, door_h - 0.03, pw),
				"center": Vector3(0.005, 0, off), "slot": Vector3(fx + 0.06, dy, zc)})
	if ty.ht <= 0.0:
		# Dębowy Masyw: rzeźbiony gzyms zamiast nadstawki
		_box(root, Vector3(d + 0.08, 0.07, w + 0.08), Vector3(0, ytop + 0.065, 0), trim)
		for k in 5:
			_ball(root, 0.035, Vector3(fx, ytop + 0.12, -w * 0.4 + k * w * 0.2), trim)
		return root
	var dt: float = ty.dt
	var ht: float = ty.ht
	var xb := -d * 0.5 + dt * 0.5
	var y1 := ytop + 0.03
	var iw := w - 0.08
	var top := Node3D.new()
	root.add_child(top)
	parts.top = top
	parts.top_size = Vector3(dt, ht, iw)
	parts.top_center = Vector3(xb, y1 + ht * 0.5, 0)
	_box(top, Vector3(0.02, ht, iw), Vector3(-d * 0.5 + 0.01, y1 + ht * 0.5, 0), wood)
	for s in [-1.0, 1.0]:
		_box(top, Vector3(dt, ht, 0.025), Vector3(xb, y1 + ht * 0.5, s * (iw * 0.5 - 0.0125)), wood)
	_box(top, Vector3(dt + 0.05, 0.05, iw + 0.06), Vector3(xb + 0.025, y1 + ht + 0.025, 0), trim)
	var shelves := 2 if ht < 1.0 else 3
	for k in shelves:
		var sy := y1 + ht * float(k + 1) / (shelves + 1)
		_box(top, Vector3(dt - 0.03, 0.015, iw - 0.05), Vector3(xb, sy, 0), wood)
	for k in shelves + 1:
		var sy := y1 + ht * float(k) / (shelves + 1) + 0.008
		for j in 4:
			var z := -iw * 0.35 + j * iw * 0.233
			if open:
				var bc := Color.from_hsv(fmod(0.21 * (k * 4 + j), 1.0), 0.55, 0.65)
				parts.contents.append(_box(top, Vector3(dt * 0.7, 0.18, 0.05), Vector3(xb, sy + 0.09, z), mat(bc)))
			else:
				parts.contents.append(_ball(top, 0.045, Vector3(xb + 0.03, sy + 0.045, z), crystal))
	if ty.glass:
		parts.glass = _box(top, Vector3(0.006, ht - 0.04, iw - 0.04), Vector3(xb + dt * 0.5, y1 + ht * 0.5, 0), glass)
		_box(top, Vector3(0.02, ht, 0.03), Vector3(xb + dt * 0.5, y1 + ht * 0.5, 0), trim)
		_box(top, Vector3(0.02, 0.03, iw), Vector3(xb + dt * 0.5, y1 + 0.015, 0), trim)
	return root
