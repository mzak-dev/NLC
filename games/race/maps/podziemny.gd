class_name MapPodziemny
extends Decor
## Parking podziemny −2 (60 × 40 m, strop 3,4 m, 2 okrążenia). Start przy budce parkingowego →
## pas północny z garbem-rampą → szlaban na wyjeździe → pętla wokół rozdzielni (plama oleju,
## autobus za murkiem) → alejka 1 obok źle zaparkowanego auta → nawrót wokół filara → alejka 2
## z porzuconym wózkiem → nawrót wokół filara → pas południowy przez myjnię (mokro i piana) →
## pas zachodni ze szlabanem → start.
## Własne dekoracje: booth (budka), carwash (myjnia), exit_sign (zielone znaki), door, cabinets,
## beam (belki stropu), hangers (wieszaki rur), duct (kanał wentylacyjny), vent (czerpnia),
## pillar_mark (strefy na filarach + gaśnice), height_bar (ogranicznik wysokości), hump_marks (pasy na
## garbie). Ze wspólnych (Decor): floor_text (numery miejsc, napisy), paint (napisy na ścianach).

const YELLOW := Color(0.95, 0.78, 0.1)
const WHITE := Color(0.9, 0.9, 0.88)
const H := 3.4
const CAR_COLORS := [Color(0.75, 0.1, 0.1), Color(0.15, 0.3, 0.75), Color(0.85, 0.85, 0.82), Color(0.2, 0.5, 0.25),
	Color(0.08, 0.08, 0.09), Color(0.55, 0.56, 0.58), Color(0.45, 0.15, 0.55), Color(0.3, 0.65, 0.8), Color(0.9, 0.55, 0.1)]
const ZONES := {"A": Color(0.95, 0.78, 0.1), "B": Color(0.2, 0.45, 0.85), "C": Color(0.2, 0.65, 0.3), "D": Color(0.95, 0.45, 0.1)}
const ORANGE := Color(0.95, 0.4, 0.05)


static func data() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2002            # stały układ aut
	var cars := []
	var lines := []
	var decor := []
	var pillars := [
		Vector2(16, 9), Vector2(24, 9), Vector2(32, 9), Vector2(40, 9), Vector2(50, 9), Vector2(54, 9),
		Vector2(18, 16), Vector2(24, 16), Vector2(30, 16), Vector2(38, 16),       # (18, 16), (34, 23): filary na końcach ścian, wokół nich nawroty
		Vector2(16, 23), Vector2(25, 23), Vector2(34, 23), Vector2(44, 23),
		Vector2(50, 21), Vector2(54, 21), Vector2(44, 27), Vector2(36, 31.5),
	]
	# miejsca postojowe: [x0, liczba, z przy ścianie, z od alejki, obrót auta, strefa]
	for row in [[17.0, 13, 0.2, 3.4, 90.0, "A"], [18.0, 9, 39.8, 36.6, 270.0, "D"]]:
		var x0: float = row[0]
		var zb: float = row[2]
		var zf: float = row[3]
		var dz := signf(zf - zb)
		for i in row[1] + 1:
			var x: float = x0 + i * 2.6
			lines.append([x, zb, x, zf, WHITE, 0.1])
			if i % 3 == 0 and i > 0 and i < row[1]:      # filar co trzy miejsca
				pillars.append(Vector2(x, zf - dz * 0.4))
		for i in row[1]:
			var cx: float = x0 + i * 2.6 + 1.3
			decor.append(["floor_text", cx, zf + dz * 0.22, 0.0 if dz > 0 else 180.0, {"text": "%s%02d" % [row[5], i + 1]}])   # górą do ściany
			if rng.randf() > 0.74:
				continue
			var col: Color = CAR_COLORS[rng.randi() % CAR_COLORS.size()]
			var kind := "maly"
			if dz < 0:          # południe: głębsze miejsca, zmieszczą się większe auta i dostawczak
				kind = ["maly", "maly", "duzy", "van"][rng.randi() % 4]
			var depth: float = Apartment.CAR_DIMS[kind][0]
			cars.append([cx, zb + dz * (depth * 0.5 + 0.05), row[4], col, kind])
	cars.append_array([
		[50.5, 31.0, 0.0, Color(0.92, 0.9, 0.82), "bus"],          # autobus w zatoczce za murkiem
		[58.25, 29.5, 180.0, Color(0.15, 0.3, 0.75), "maly"],     # miejsca przy ścianie wschodniej
		[58.25, 34.7, 180.0, Color(0.85, 0.85, 0.82), "maly"],
		[58.25, 37.3, 180.0, Color(0.75, 0.1, 0.1), "maly"],
		[34.0, 9.8, 0.0, Color(0.85, 0.75, 0.1), "maly"],          # alejka 1: przy ścianie…
		[28.5, 14.7, 170.0, Color(0.2, 0.5, 0.25), "duzy"],        # …i źle zaparkowany, ukosem w alejkę
		[29.0, 22.0, 12.0, Color(0.75, 0.1, 0.1), "maly"],         # alejka 2, też ukosem
		[20.0, 24.0, 180.0, Color(0.15, 0.3, 0.75), "maly"],       # pas południowy, wzdłuż ściany
		[35.0, 24.0, 0.0, Color(0.55, 0.56, 0.58), "duzy"],        # w środku nawrotu
		[1.1, 20.8, 90.0, Color(0.85, 0.85, 0.82), "maly"],        # pas zachodni
		[2.2, 34.0, 90.0, Color(0.9, 0.9, 0.9), "van"],            # róg południowo-zachodni
	])
	# żółte osie alejek (przerywane), z przerwami na garb i myjnię
	var gaps := [Rect2(29.5, 3.5, 7.8, 5.5), Rect2(21.5, 25, 11, 7)]
	for seg in [[Vector2(17, 6.4), Vector2(50, 6.4)], [Vector2(19, 12.5), Vector2(44, 12.5)], [Vector2(19, 19.5), Vector2(33, 19.5)],
			[Vector2(12, 28.5), Vector2(38, 28.5)], [Vector2(57, 14.5), Vector2(57, 20)], [Vector2(47, 16), Vector2(47, 21)],
			[Vector2(4, 9.5), Vector2(4, 22)]]:
		_dashes(lines, seg[0], seg[1], gaps)
	# kreskowane pola wyłączone z ruchu, myjnia i zatoczka autobusu
	_hatch(lines, Rect2(10.4, 0.25, 5.6, 3.2), YELLOW)          # wysepka budki
	_hatch(lines, Rect2(49.6, 21.45, 4.8, 1.0), YELLOW)         # pod rozdzielnią (wewnątrz nawrotu)
	_hatch(lines, Rect2(44.25, 21.6, 1.2, 4.8), YELLOW)
	_frame(lines, Rect2(45.1, 29.3, 10.8, 3.4), YELLOW)
	for z in [28.2, 30.8, 33.4, 36.0, 38.6]:
		lines.append([56.6, z, 59.8, z, WHITE, 0.1])
	_frame(lines, Rect2(22.6, 25.9, 8.8, 5.2), WHITE)
	lines.append([54.3, 12.7, 59.8, 12.7, WHITE, 0.25])         # linie STOP przed szlabanami
	lines.append([0.3, 18.4, 7.8, 18.4, WHITE, 0.25])
	# rury pod stropem (z wieszakami): [x, z, obrót, długość, promień, wysokość osi, kolor]
	# (każda od ściany do ściany)
	for p in [[30.0, 8.35, 0.0, 60.0, 0.09, 2.9, Color(0.75, 0.1, 0.08)], [30.0, 8.7, 0.0, 60.0, 0.13, 2.85, Color(0.5, 0.52, 0.55)],
			[29.0, 15.45, 0.0, 42.0, 0.06, 2.95, Color(0.9, 0.75, 0.1)], [26.0, 22.45, 0.0, 36.0, 0.11, 2.88, Color(0.35, 0.45, 0.38)],
			[22.0, 23.6, 0.0, 44.0, 0.07, 2.95, Color(0.75, 0.1, 0.08)], [59.35, 20.0, 90.0, 40.0, 0.14, 2.85, Color(0.5, 0.52, 0.55)],
			[44.6, 24.5, 90.0, 31.0, 0.08, 2.9, Color(0.75, 0.1, 0.08)], [0.55, 20.0, 90.0, 40.0, 0.12, 2.86, Color(0.5, 0.52, 0.55)]]:
		decor.append(["pipe", p[0], p[1], p[2], {"len": p[3], "r": p[4], "y": p[5], "color": p[6]}])
		decor.append(["hangers", p[0], p[1], p[2], {"len": p[3], "y": p[5] + p[4]}])
	for x in [2, 10, 18, 26, 34, 42, 50, 58]:
		decor.append(["beam", x, 20.0, 90.0, {"len": 40.0}])
	# oznaczenia filarów: strefa z położenia, kolejne numery w strefie
	var count := {}
	pillars.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	for p in pillars:
		var z: String = "A" if p.y < 9.5 else ("B" if p.y < 16.5 else ("C" if p.y < 23.5 else "D"))
		count[z] = count.get(z, 0) + 1
		var lone: bool = p in [Vector2(36, 31.5), Vector2(50, 21), Vector2(54, 21), Vector2(44, 27)]
		decor.append(["pillar_mark", p.x, p.y, 180.0 if p.y > 30 else 0.0,     # gaśnica od strony alejki
			{"text": "%s%d" % [z, count[z]], "color": ZONES[z], "all": lone, "ext": count[z] % 3 == 1}])
	decor.append_array([
		["booth", 12.6, 1.7, 0.0, {}],
		["height_bar", 16.4, 6.4, 90.0, {"len": 5.0}],
		["hump_marks", 30.0, 3.9, 0.0, {"w": 4.95, "ramp": 2.6, "top": 1.6, "h": 0.35}],
		["sign", 26.6, 8.2, 90.0, {"text": "UWAGA PRÓG", "color": YELLOW, "text_color": Color(0.05, 0.05, 0.05), "w": 0.9, "h": 0.45, "y": 1.5}],
		["floor_text", 24.5, 6.0, 90.0, {"text": "WOLNO", "size": 0.9}],
		["barrier", 57.0, 13.5, 0.0, {"len": 5.0}],
		["floor_text", 57.2, 12.0, 180.0, {"text": "STOP", "size": 0.7}],
		["barrier", 4.0, 17.5, 0.0, {"len": 6.4}],
		["floor_text", 4.0, 19.1, 0.0, {"text": "STOP", "size": 0.7}],
		["carwash", 27.0, 28.5, 90.0, {}],
		["floor_text", 34.6, 28.5, 270.0, {"text": "MYJNIA", "size": 0.8}],
		["duct", 30.5, 33.3, 0.0, {"len": 27.0}],
		["vent", 12.5, 31.48, 180.0, {}],
		["paint", 17.08, 35.0, 270.0, {"text": "WENTYLATORNIA", "size": 0.28, "y": 2.3, "plate": Color(0.15, 0.2, 0.3)}],
		["door", 49.92, 17.0, 90.0, {"text": "ROZDZIELNIA", "warn": true}],
		["cabinets", 54.08, 16.0, 270.0, {"n": 3}],
		["exit_sign", 4.5, 0.08, 0.0, {"door": true}],
		["exit_sign", 0.08, 30.5, 270.0, {"door": true}],
		["exit_sign", 23.0, 12.6, 90.0, {"hang": true}],
		["exit_sign", 31.5, 28.5, 90.0, {"hang": true}],
		["exit_sign", 57.2, 19.6, 0.0, {"hang": true}],
		["exit_sign", 4.0, 22.6, 0.0, {"hang": true}],
		["paint", 59.92, 4.5, 90.0, {"text": "-2", "size": 1.1, "y": 1.75, "disc": YELLOW}],
		["paint", 0.08, 13.5, 270.0, {"text": "-2", "size": 1.1, "y": 1.75, "disc": YELLOW}],
		["paint", 7.0, 0.08, 0.0, {"text": "POZIOM -2", "size": 0.4, "y": 2.45, "plate": Color(0.95, 0.78, 0.1), "color": Color(0.05, 0.05, 0.05)}],
		["paint", 20.0, 15.92, 180.0, {"text": "STREFA B", "size": 0.38, "y": 2.45, "plate": ZONES["B"]}],
		["paint", 30.0, 23.08, 0.0, {"text": "STREFA C", "size": 0.38, "y": 2.45, "plate": ZONES["C"]}],
		["paint", 52.0, 26.92, 180.0, {"text": "ZATOCZKA BUS", "size": 0.2, "y": 0.86, "plate": Color(0.9, 0.9, 0.88), "color": Color(0.1, 0.1, 0.1)}],
	])
	var lamps := [
		Vector2(6, 5.5), Vector2(14, 5.5), Vector2(22, 5.5), Vector2(30, 5.5), Vector2(38, 5.5), Vector2(46, 5.5),
		Vector2(54, 5.5), Vector2(57, 13), Vector2(57, 17), Vector2(52, 24), Vector2(52.5, 31), Vector2(54, 36.5),
		Vector2(47, 22), Vector2(55.5, 28.5), Vector2(44, 12.5), Vector2(36, 12.5), Vector2(28, 12.5), Vector2(20, 12.5),
		Vector2(12, 12.5), Vector2(11, 19.5), Vector2(20, 19.5), Vector2(28, 19.5), Vector2(36, 19.5), Vector2(41, 19.5),
		Vector2(40, 27.5), Vector2(33, 27.5), Vector2(21, 27.5), Vector2(14, 27.5), Vector2(6, 27.5), Vector2(22, 35),
		Vector2(30, 35), Vector2(38, 35), Vector2(4, 20), Vector2(4, 13), Vector2(4, 34),
	]
	return {
		"id": "podziemny", "name": "PARKING PODZIEMNY -2", "place": "parking podziemny, poziom -2",
		"laps": 4, "size": Vector2(60, 40), "height": H, "env": "garage", "ceiling": true, "wall_style": "garage",
		"lamp_color": Color(0.92, 0.97, 1.0), "lamp_energy": 1.5, "flicker": [21],
		"rooms": [
			{"rect": Rect2(0, 0, 60, 3.6), "floor": 6, "a": Color(0.46, 0.46, 0.45), "b": Color(0.38, 0.38, 0.37), "wall": Color.WHITE, "grip": 1.0},
			{"rect": Rect2(0, 3.6, 60, 32.8), "floor": 5, "a": Color(0.17, 0.17, 0.18), "b": Color(0.3, 0.3, 0.31), "wall": Color.WHITE, "grip": 1.0},
			{"rect": Rect2(0, 36.4, 60, 3.6), "floor": 6, "a": Color(0.46, 0.46, 0.45), "b": Color(0.38, 0.38, 0.37), "wall": Color.WHITE, "grip": 1.0},
		],
		"rugs": [
			{"rect": Rect2(22.6, 25.9, 8.8, 5.2), "puddle": true, "color": Color(0.7, 0.82, 0.95, 0.38), "grip": 0.45},   # myjnia
			{"rect": Rect2(50.4, 24.2, 3.2, 2.3), "puddle": true, "color": Color(0.02, 0.02, 0.03, 0.85), "grip": 0.35},  # olej
		],
		"walls": [
			[0, 0, 60, 0], [60, 0, 60, 40], [0, 40, 60, 40], [0, 0, 0, 40],
			[8, 9, 50, 9],                                                        # pas północny | alejka 1
			[50, 9, 54, 9], [54, 9, 54, 21], [50, 21, 54, 21], [50, 9, 50, 21],   # rozdzielnia
			[18, 16, 44, 16],                                                     # alejka 1 | alejka 2
			[8, 23, 34, 23],                                                      # alejka 2 | pas południowy
			[44, 16, 44, 27], [44, 27, 60, 27, 1.1],                              # pętla wschodnia, murek zatoczki
			[8, 9, 8, 23],                                                        # pas zachodni
		],
		"path": PATH,
		"humps": [
			[30.0, 3.9, 4.95, 2.6, 1.6, 0.35, Color(0.52, 0.52, 0.5), "x"],      # garb-rampa na pasie północnym
		],
		"furniture": [[8.0, 31.5, 9.0, 8.4, H, Color.WHITE, "brick"]],          # wentylatornia
		"props": [
			[25.5, 21.6, 0.95, 1.0, 0.6, 9.0, Color(0.72, 0.74, 0.78), "cart"],  # porzucony wózek sklepowy
			[26.0, 13.4, 0.35, 0.7, 0.35, 2.5, ORANGE, "cone"],                  # pachołki przy źle zaparkowanym
			[31.2, 13.6, 0.35, 0.7, 0.35, 2.5, ORANGE, "cone"],
			[55.0, 14.9, 0.35, 0.7, 0.35, 2.5, ORANGE, "cone"],
			[47.9, 26.3, 0.35, 0.7, 0.35, 2.5, ORANGE, "cone"],
			[58.9, 25.6, 0.6, 0.9, 0.6, 18.0, Color(0.12, 0.22, 0.5), "barrel"], # cieknąca beczka
			[32.8, 31.3, 0.5, 0.75, 0.55, 3.0, YELLOW, "wet_sign"],
			[21.8, 25.9, 0.5, 0.75, 0.55, 3.0, YELLOW, "wet_sign"],
			[17.7, 30.6, 0.7, 0.22, 0.7, 8.0, Color(0.05, 0.05, 0.05), "tire"],
			[18.6, 31.4, 0.7, 0.22, 0.7, 8.0, Color(0.05, 0.05, 0.05), "tire"],
			[18.1, 33.6, 1.2, 0.14, 0.8, 12.0, Color(0.6, 0.45, 0.28), "pallet"],
			[9.4, 24.0, 0.5, 0.4, 0.5, 1.5, Color(0.55, 0.42, 0.26)],          # kartony
			[10.1, 24.2, 0.45, 0.35, 0.45, 1.2, Color(0.5, 0.38, 0.22)],
		],
		"pillars": pillars, "cars": cars, "lines": lines, "lamps": lamps, "decor": decor,
		"arrows": [[27.8, 6, 0], [43.8, 6, 0], [57, 15.5, 90], [47, 18.5, 270], [31.2, 12.6, 180],
			[12.4, 16, 90], [24.2, 19.5, 0], [32, 19.5, 0], [40, 23, 90], [37.5, 28.5, 180], [14, 28.5, 180], [4, 15, 270]],
	}


## Linia jazdy. Punkt 0 = start/meta przy budce.
const PATH := [
	Vector2(14, 6), Vector2(24, 6), Vector2(36, 5.8), Vector2(44, 5.3), Vector2(51, 5),                          # pas północny
	Vector2(54.5, 5.94), Vector2(57.06, 8.5), Vector2(58, 12),                                                     # łuk r = 7 w prawo
	Vector2(57.6, 16.5), Vector2(57.2, 20.5), Vector2(55.74, 24.04), Vector2(52.2, 25.5), Vector2(48.66, 24.04),  # nawrót r = 5
	Vector2(47.2, 20.5), Vector2(47.2, 18.3), Vector2(46.4, 15.3), Vector2(44.2, 13.1), Vector2(41.2, 12.3),     # łuk r = 6 w lewo
	Vector2(36, 12), Vector2(28, 11.7), Vector2(22, 11.1),                                                         # alejka 1
	Vector2(17.6, 10.8), Vector2(13.92, 12.32), Vector2(12.4, 16), Vector2(13.92, 19.68), Vector2(17.6, 21.2),  # nawrót r = 5,2 wokół filara
	Vector2(22, 20.7), Vector2(28, 19.2),                                                                          # alejka 2
	Vector2(34.5, 17.5), Vector2(38.39, 19.11), Vector2(40, 23), Vector2(38.39, 26.89), Vector2(34.5, 28.5),     # nawrót r = 5,5 wokół filara
	Vector2(30, 28.5), Vector2(22, 28.5), Vector2(16, 28.5), Vector2(11, 28.5),                                  # myjnia
	Vector2(7.5, 27.56), Vector2(4.94, 25), Vector2(4, 21.5), Vector2(4, 15), Vector2(4, 12),                    # łuk r = 7, pas zachodni
	Vector2(4.8, 9), Vector2(7, 6.8), Vector2(10, 6),                                                              # łuk r = 6
]


## Przerywana linia (kreska 1,5 m co 3 m); kreski, których środek wypada w którymś z prostokątów gaps, pomijamy.
static func _dashes(lines: Array, a: Vector2, b: Vector2, gaps: Array) -> void:
	var d := a.distance_to(b)
	var dir := (b - a) / d
	var t := 0.0
	while t + 1.5 <= d:
		var p := a + dir * t
		var q := a + dir * (t + 1.5)
		if not gaps.any(func(g: Rect2) -> bool: return g.has_point((p + q) * 0.5)):
			lines.append([p.x, p.y, q.x, q.y, YELLOW])
		t += 3.0


## Pole wyłączone z ruchu: ramka i ukośne pasy co 0,7 m.
static func _hatch(lines: Array, rc: Rect2, c: Color) -> void:
	_frame(lines, rc, c)
	var k := rc.position.x - rc.end.y + 0.35          # pasy z = x - k
	while k < rc.end.x - rc.position.y:
		var x0 := maxf(rc.position.x, rc.position.y + k)
		var x1 := minf(rc.end.x, rc.end.y + k)
		if x1 - x0 > 0.05:
			lines.append([x0, x0 - k, x1, x1 - k, c, 0.1])
		k += 0.7


static func _frame(lines: Array, rc: Rect2, c: Color) -> void:
	var p := rc.position
	var e := rc.end
	lines.append_array([[p.x, p.y, e.x, p.y, c, 0.1], [e.x, p.y, e.x, e.y, c, 0.1], [e.x, e.y, p.x, e.y, c, 0.1], [p.x, e.y, p.x, p.y, c, 0.1]])


# ---------- własne dekoracje ----------

## Węzeł obracający się w kółko (szczotki myjni).
class Spin extends Node3D:
	var axis := Vector3.UP
	var speed := 4.0

	func _process(dt: float) -> void:
		rotate_object_local(axis, speed * dt)


## Belka stropowa wzdłuż lokalnego X {len}.
func k_beam(e: Array) -> void:
	var n := root(e)
	box(n, Vector3(opts(e).get("len", 10.0), 0.3, 0.4), Vector3(0, H - 0.15, 0), mat(Color(0.52, 0.52, 0.5), 0.95))


## Wieszaki rury co 3 m wzdłuż lokalnego X {len, y = wierzch rury}.
func k_hangers(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var ln: float = o.get("len", 6.0)
	var y: float = o.get("y", 3.0)
	var steel := mat(Color(0.35, 0.36, 0.38), 0.5, 0.7)
	var x := -ln * 0.5 + 1.5
	while x < ln * 0.5:
		box(n, Vector3(0.025, H - y, 0.025), Vector3(x, (H + y) * 0.5, 0), steel)
		x += 3.0


## Oznaczenie filara: kolorowy pas ze strefą i numerem {text, color, all = napisy na 4 ścianach, ext = gaśnica}.
func k_pillar_mark(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	box(n, Vector3(0.79, 0.5, 0.79), Vector3(0, 2.4, 0), mat(o.get("color", YELLOW), 0.6))
	box(n, Vector3(0.79, 0.06, 0.79), Vector3(0, 2.12, 0), mat(Color(0.95, 0.95, 0.93), 0.6))
	var faces := [0.0, PI, PI / 2, -PI / 2] if o.get("all", false) else [0.0, PI]
	for a in faces:
		var f := Node3D.new()
		f.rotation.y = a
		n.add_child(f)
		var l := label(f, o.get("text", ""), 0.3, Vector3(0, 2.4, 0.4), Color(0.05, 0.05, 0.05))
		l.shaded = true
	if o.get("ext", false):          # gaśnica na wieszaku od strony +Z
		var red := mat(Color(0.8, 0.05, 0.05), 0.35)
		box(n, Vector3(0.12, 0.1, 0.06), Vector3(0, 1.3, 0.405), mat(Color(0.2, 0.2, 0.2), 0.5, 0.6))
		cyl(n, 0.075, 0.48, Vector3(0, 1.0, 0.47), red)
		box(n, Vector3(0.05, 0.08, 0.05), Vector3(0, 1.29, 0.47), mat(Color(0.1, 0.1, 0.1), 0.5))
		box(n, Vector3(0.3, 0.3, 0.01), Vector3(0, 1.62, 0.38), red)
		label(n, "GAŚNICA", 0.05, Vector3(0, 1.62, 0.39), Color.WHITE).shaded = true


## Budka parkingowego (przód na lokalne +Z): kasa z oknem, parkingowy w środku, automat biletowy.
func k_booth(e: Array) -> void:
	var n := root(e)
	solid(n, Vector3(2.4, 2.45, 1.8), Vector3(0, 1.225, 0), null)
	var dark := mat(Color(0.2, 0.22, 0.25), 0.5, 0.5)
	box(n, Vector3(2.4, 1.0, 1.8), Vector3(0, 0.5, 0), mat(Color(0.88, 0.88, 0.84), 0.6))
	box(n, Vector3(2.42, 0.12, 1.82), Vector3(0, 0.93, 0), mat(YELLOW, 0.5))
	box(n, Vector3(2.3, 1.3, 1.7), Vector3(0, 1.65, 0), mat(Color(0.55, 0.7, 0.78, 0.28), 0.05, 0.2))
	for x in [-1.16, 1.16]:
		for z in [-0.86, 0.86]:
			box(n, Vector3(0.08, 1.3, 0.08), Vector3(x, 1.65, z), dark)
	box(n, Vector3(2.7, 0.14, 2.1), Vector3(0, 2.37, 0), dark)
	box(n, Vector3(2.7, 0.28, 0.04), Vector3(0, 2.3, 1.07), mat(Color(0.1, 0.2, 0.45), 0.5))
	label(n, "KASA PARKINGU", 0.15, Vector3(0, 2.3, 1.095), Color(1.6, 1.4, 0.5))
	box(n, Vector3(0.5, 0.25, 0.03), Vector3(0.5, 1.12, 0.91), mat(Color(0.05, 0.05, 0.05), 0.3))   # okienko
	box(n, Vector3(0.6, 0.4, 0.02), Vector3(-0.6, 0.6, 0.91), mat(Color(0.95, 0.95, 0.95), 0.6))   # cennik
	var cl := label(n, "CENNIK\n1 h — 4 zł\ndoba — 30 zł", 0.06, Vector3(-0.6, 0.6, 0.925), Color(0.1, 0.1, 0.1))
	cl.shaded = true
	# wnętrze: blat, monitor, parkingowy, lampka
	box(n, Vector3(2.2, 0.06, 0.5), Vector3(0, 1.0, 0.55), mat(Color(0.55, 0.4, 0.25), 0.7))
	box(n, Vector3(0.4, 0.3, 0.05), Vector3(0.45, 1.2, 0.45), dark)
	box(n, Vector3(0.36, 0.25, 0.01), Vector3(0.45, 1.2, 0.48), glow(Color(0.5, 0.8, 1.0), 1.5))
	box(n, Vector3(0.42, 0.5, 0.26), Vector3(-0.35, 1.28, 0.1), mat(Color(0.1, 0.15, 0.3), 0.8))
	sphere(n, 0.12, Vector3(-0.35, 1.66, 0.1), mat(Color(0.9, 0.72, 0.6), 0.7))
	cyl(n, 0.13, 0.07, Vector3(-0.35, 1.78, 0.1), mat(Color(0.1, 0.15, 0.3), 0.8))
	box(n, Vector3(0.2, 0.02, 0.12), Vector3(-0.35, 1.76, 0.22), mat(Color(0.05, 0.05, 0.05), 0.5))
	lamp(n, Vector3(0, 2.1, 0), Color(1.0, 0.85, 0.6), 0.6, 3.5, false)
	# automat biletowy obok
	var t := Node3D.new()
	t.position = Vector3(2.1, 0, 1.2)
	n.add_child(t)
	solid(t, Vector3(0.35, 1.25, 0.35), Vector3(0, 0.625, 0), mat(YELLOW, 0.5))
	box(t, Vector3(0.25, 0.18, 0.02), Vector3(0, 1.0, 0.18), glow(Color(0.3, 0.9, 0.5), 1.2))
	box(t, Vector3(0.12, 0.03, 0.02), Vector3(0, 0.75, 0.18), mat(Color(0.05, 0.05, 0.05), 0.4))
	label(t, "BILET", 0.07, Vector3(0, 1.17, 0.18), Color(0.05, 0.05, 0.05)).shaded = true


## Ogranicznik wysokości na łańcuchach, belka wzdłuż lokalnego X {len}.
func k_height_bar(e: Array) -> void:
	var n := root(e)
	var ln: float = opts(e).get("len", 5.0)
	var y := 2.5
	var k := 0
	var x := -ln * 0.5
	while x < ln * 0.5 - 0.01:
		var seg := minf(0.4, ln * 0.5 - x)
		box(n, Vector3(seg, 0.12, 0.12), Vector3(x + seg * 0.5, y, 0), mat(YELLOW if k % 2 == 0 else Color(0.05, 0.05, 0.05), 0.5))
		x += seg
		k += 1
	var steel := mat(Color(0.35, 0.36, 0.38), 0.5, 0.7)
	for s in [-1.5, 1.5]:
		box(n, Vector3(0.03, H - y - 0.06, 0.03), Vector3(s, (H + y + 0.06) * 0.5, 0), steel)
	box(n, Vector3(0.95, 0.3, 0.03), Vector3(0, y + 0.22, 0), mat(Color(0.95, 0.95, 0.93), 0.5))
	box(n, Vector3(1.01, 0.04, 0.035), Vector3(0, y + 0.37, 0), mat(Color(0.8, 0.05, 0.05), 0.5))
	for s in [-1.0, 1.0]:
		var l := label(n, "MAKS. 2,4 m", 0.13, Vector3(0, y + 0.22, s * 0.02), Color(0.05, 0.05, 0.05))
		l.rotation.y = 0.0 if s > 0 else PI
		l.shaded = true


## Żółto-czarne pasy na garbie-rampie wzdłuż lokalnego X {w = szerokość wzdłuż Z, ramp, top, h};
## (x, z) wpisu = początek najazdu i brzeg garbu, jak w „humps”.
func k_hump_marks(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var w: float = o.get("w", 4.0)
	var rl: float = o.get("ramp", 1.5)
	var tp: float = o.get("top", 1.5)
	var h: float = o.get("h", 0.3)
	var a := atan2(h, rl)
	var stripe := rl / cos(a) / 6.0
	for i in 6:
		var m: Material = mat(YELLOW if i % 2 == 0 else Color(0.06, 0.06, 0.06), 0.6)
		var s := (i + 0.5) * rl / 6.0
		var up := box(n, Vector3(stripe, 0.012, w - 0.1), Vector3(s, s * h / rl + 0.004, w * 0.5), m)
		up.rotation.z = a
		var dn := box(n, Vector3(stripe, 0.012, w - 0.1), Vector3(rl * 2.0 + tp - s, s * h / rl + 0.004, w * 0.5), m)
		dn.rotation.z = -a
	for x in [rl + 0.12, rl + tp - 0.12]:
		box(n, Vector3(0.2, 0.012, w - 0.1), Vector3(x, h + 0.004, w * 0.5), mat(YELLOW, 0.6))


## Drzwi w ścianie (lokalne +Z = do pomieszczenia) {text, warn = trójkąt „wysokie napięcie”}.
func k_door(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	_door(n, Color(0.32, 0.4, 0.48))
	if o.has("text"):
		box(n, Vector3(0.12 * str(o.text).length() + 0.3, 0.26, 0.02), Vector3(0, 2.35, 0.01), mat(Color(0.1, 0.2, 0.45), 0.5))
		label(n, o.text, 0.16, Vector3(0, 2.35, 0.025), Color.WHITE).shaded = true
	if o.get("warn", false):
		var d := box(n, Vector3(0.32, 0.32, 0.015), Vector3(0, 1.55, 0.07), mat(YELLOW, 0.5))
		d.rotation.z = PI / 4
		var l := label(n, "!", 0.24, Vector3(0, 1.53, 0.08), Color(0.05, 0.05, 0.05))
		l.shaded = true
		label(n, "WYSOKIE NAPIĘCIE", 0.06, Vector3(0, 1.25, 0.075), Color(0.8, 0.05, 0.05)).shaded = true


func _door(n: Node3D, c: Color) -> void:
	var frame := mat(Color(0.25, 0.26, 0.28), 0.5, 0.6)
	box(n, Vector3(1.15, 2.15, 0.04), Vector3(0, 1.075, 0.02), frame)
	box(n, Vector3(0.95, 2.03, 0.05), Vector3(0, 1.015, 0.04), mat(c, 0.55, 0.3))
	box(n, Vector3(0.7, 0.04, 0.05), Vector3(0, 1.0, 0.085), mat(Color(0.7, 0.7, 0.72), 0.3, 0.8))   # pochwyt
	box(n, Vector3(0.3, 0.4, 0.01), Vector3(0, 1.6, 0.068), mat(Color(0.3, 0.38, 0.45, 0.6), 0.05))   # szybka


## Zielony znak ewakuacyjny: na drzwiach do klatki {door = true} albo podwieszony, dwustronny {hang = true}.
func k_exit_sign(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	if o.get("door", false):
		_door(n, Color(0.45, 0.47, 0.5))
		_exit_panel(n, Vector3(0, 2.4, 0.04), false)
	if o.get("hang", false):
		var y := 2.9
		_exit_panel(n, Vector3(0, y, 0), true)
		var steel := mat(Color(0.35, 0.36, 0.38), 0.5, 0.7)
		for s in [-0.45, 0.45]:
			box(n, Vector3(0.02, H - y - 0.16, 0.02), Vector3(s, (H + y + 0.16) * 0.5, 0), steel)


func _exit_panel(n: Node3D, pos: Vector3, both: bool) -> void:
	var p := Node3D.new()
	p.position = pos
	n.add_child(p)
	box(p, Vector3(1.1, 0.32, 0.05), Vector3.ZERO, glow(Color(0.08, 0.75, 0.25), 2.2))
	for a in ([0.0, PI] if both else [0.0]):
		var f := Node3D.new()
		f.rotation.y = a
		p.add_child(f)
		var wm := glow(Color(1, 1, 1), 1.6)
		var z := 0.03
		# biegnący ludzik
		sphere(f, 0.032, Vector3(-0.38, 0.1, z), wm)
		var torso := box(f, Vector3(0.035, 0.11, 0.01), Vector3(-0.4, 0.02, z), wm)
		torso.rotation.z = -0.4
		for leg in [[-0.44, -0.08, 0.6], [-0.37, -0.09, -0.5], [-0.36, 0.03, 1.1], [-0.45, 0.04, -1.0]]:
			var b := box(f, Vector3(0.025, 0.1, 0.01), Vector3(leg[0], leg[1], z), wm)
			b.rotation.z = leg[2]
		# strzałka
		box(f, Vector3(0.12, 0.03, 0.01), Vector3(-0.22, 0, z), wm)
		for s in [-1.0, 1.0]:
			var hd := box(f, Vector3(0.07, 0.03, 0.01), Vector3(-0.15, s * 0.022, z), wm)
			hd.rotation.z = -s * PI / 4
		label(f, "WYJŚCIE", 0.13, Vector3(0.17, 0, z), Color(1.4, 1.4, 1.4))


## Szafy elektryczne pod ścianą (lokalne +Z = od ściany) {n}.
func k_cabinets(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var cnt: int = o.get("n", 2)
	var grey := mat(Color(0.55, 0.57, 0.58), 0.45, 0.3)
	var dark := mat(Color(0.15, 0.15, 0.16), 0.5)
	for i in cnt:
		var x := (i - (cnt - 1) * 0.5) * 0.85
		solid(n, Vector3(0.8, 1.9, 0.4), Vector3(x, 0.95, 0.2), grey)
		box(n, Vector3(0.01, 1.8, 0.01), Vector3(x, 0.95, 0.405), dark)
		box(n, Vector3(0.03, 0.15, 0.03), Vector3(x + 0.08, 1.0, 0.415), dark)
		var d := box(n, Vector3(0.14, 0.14, 0.01), Vector3(x - 0.2, 1.55, 0.405), mat(YELLOW, 0.5))
		d.rotation.z = PI / 4
		cyl(n, 0.05, H - 1.9, Vector3(x + 0.25, (H + 1.9) * 0.5, 0.15), mat(Color(0.4, 0.42, 0.44), 0.5, 0.5))


## Kanał wentylacyjny z blachy ocynkowanej pod stropem, wzdłuż lokalnego X {len}.
func k_duct(e: Array) -> void:
	var n := root(e)
	var ln: float = opts(e).get("len", 10.0)
	var galv := mat(Color(0.68, 0.7, 0.72), 0.35, 0.75)
	var y := 2.85
	box(n, Vector3(ln, 0.42, 0.75), Vector3(0, y, 0), galv)
	var steel := mat(Color(0.35, 0.36, 0.38), 0.5, 0.7)
	var x := -ln * 0.5 + 0.75
	var i := 0
	while x < ln * 0.5:
		box(n, Vector3(0.05, 0.47, 0.8), Vector3(x, y, 0), galv)
		if i % 2 == 1:
			for s in [-0.33, 0.33]:
				box(n, Vector3(0.025, H - y - 0.21, 0.025), Vector3(x + 0.1, (H + y + 0.21) * 0.5, s), steel)
		if i % 4 == 2:
			box(n, Vector3(0.5, 0.02, 0.4), Vector3(x + 0.75, y - 0.215, 0), mat(Color(0.2, 0.2, 0.22), 0.6))   # kratka
		x += 1.5
		i += 1


## Czerpnia na ścianie wentylatorni (lokalne +Z = od ściany): żaluzja i drzwi.
func k_vent(e: Array) -> void:
	var n := root(e)
	var frame := mat(Color(0.4, 0.42, 0.45), 0.5, 0.6)
	box(n, Vector3(1.9, 1.2, 0.05), Vector3(-1.7, 2.1, 0.03), mat(Color(0.08, 0.08, 0.09), 0.9))
	for i in 7:
		var s := box(n, Vector3(1.8, 0.14, 0.02), Vector3(-1.7, 1.62 + i * 0.16, 0.08), frame)
		s.rotation.x = 0.6
	_door(n, Color(0.55, 0.3, 0.15))


## Myjnia: brama nad torem (lokalne Z = kierunek jazdy) z obracającymi się szczotkami, nogi poza
## torem, kapiąca woda, piana na podłodze, sygnalizator i terminal od strony wjazdu (lokalne −Z).
func k_carwash(e: Array) -> void:
	var n := root(e)
	var half := 3.0
	var top := 3.05
	var blue := mat(Color(0.12, 0.32, 0.7), 0.4, 0.5)
	var steel := mat(Color(0.7, 0.72, 0.75), 0.35, 0.8)
	var bristle := [mat(Color(0.15, 0.4, 0.95), 0.95), mat(Color(0.9, 0.2, 0.25), 0.95)]
	for s in [-1.0, 1.0]:
		solid(n, Vector3(0.45, top + 0.225, 0.7), Vector3(s * half, (top + 0.225) * 0.5, 0), blue)
		for k in 4:
			box(n, Vector3(0.47, 0.15, 0.72), Vector3(s * half, 0.075 + k * 0.15, 0), mat(YELLOW if k % 2 == 0 else Color(0.05, 0.05, 0.05), 0.6))
	box(n, Vector3(half * 2 + 0.45, 0.45, 0.8), Vector3(0, top, 0), blue)
	box(n, Vector3(half * 2 - 0.5, 0.03, 0.12), Vector3(0, top - 0.24, 0.3), glow(Color(0.6, 0.85, 1.0), 3.0))
	box(n, Vector3(half * 2 - 0.5, 0.03, 0.12), Vector3(0, top - 0.24, -0.3), glow(Color(0.6, 0.85, 1.0), 3.0))
	for s in [-1.0, 1.0]:
		var l := label(n, "MYJNIA", 0.28, Vector3(0, top, s * 0.41), Color(0.6, 1.8, 2.6))
		l.rotation.y = 0.0 if s > 0 else PI
	# górna szczotka w poprzek toru
	var roll := Spin.new()
	roll.axis = Vector3.RIGHT
	roll.speed = 6.0
	roll.position = Vector3(0, 2.55, 0)
	n.add_child(roll)
	cyl(roll, 0.08, half * 2 - 1.0, Vector3.ZERO, steel).rotation.z = PI / 2
	for k in 4:
		var f := box(roll, Vector3(half * 2 - 1.2, 0.5, 0.05), Vector3.ZERO, bristle[k % 2])
		f.rotation.x = k * PI / 4
	for s in [-1.0, 1.0]:
		box(n, Vector3(0.06, 0.32, 0.06), Vector3(s * (half - 0.5), 2.65, 0), steel)
	# boczne szczotki (z kolizją, poza torem)
	for s in [-1.0, 1.0]:
		var sb := Spin.new()
		sb.speed = 5.0 * s
		sb.position = Vector3(s * 2.2, 1.25, 0)
		n.add_child(sb)
		cyl(sb, 0.06, 1.9, Vector3.ZERO, steel)
		for k in 4:
			var f := box(sb, Vector3(0.78, 1.85, 0.04), Vector3.ZERO, bristle[k % 2])
			f.rotation.y = k * PI / 4
		box(n, Vector3(0.05, top - 0.225 - 2.2, 0.05), Vector3(s * 2.2, (2.2 + top - 0.225) * 0.5, 0), steel)
		solid(n, Vector3(0.8, 1.9, 0.8), Vector3(s * 2.2, 1.25, 0), null)
	# sygnalizator i terminal od strony wjazdu
	box(n, Vector3(0.22, 0.5, 0.12), Vector3(-half, 2.25, -0.42), mat(Color(0.05, 0.05, 0.05), 0.5))
	sphere(n, 0.06, Vector3(-half, 2.37, -0.49), mat(Color(0.35, 0.03, 0.03), 0.4))
	sphere(n, 0.06, Vector3(-half, 2.13, -0.49), glow(Color(0.1, 1.0, 0.3), 4.0))
	box(n, Vector3(0.08, 1.0, 0.08), Vector3(-half + 0.1, 0.5, -0.75), steel)
	box(n, Vector3(0.36, 0.5, 0.2), Vector3(-half + 0.1, 1.2, -0.75), mat(Color(0.25, 0.27, 0.3), 0.5, 0.4))
	box(n, Vector3(0.22, 0.14, 0.01), Vector3(-half + 0.1, 1.3, -0.855), glow(Color(0.4, 0.8, 1.0), 1.5))
	var pl := label(n, "ZAPŁAĆ", 0.05, Vector3(-half + 0.1, 1.08, -0.86), Color.WHITE)
	pl.rotation.y = PI
	lamp(n, Vector3(0, 2.2, -0.9), Color(0.85, 0.93, 1.0), 1.4, 7.0, true)
	# kapiąca woda spod belki
	var drip := CPUParticles3D.new()
	drip.position = Vector3(0, top - 0.25, 0)
	drip.amount = 90
	drip.lifetime = 0.55
	drip.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	drip.emission_box_extents = Vector3(half - 0.5, 0.02, 0.35)
	drip.direction = Vector3.DOWN
	drip.spread = 4.0
	drip.initial_velocity_min = 1.2
	drip.initial_velocity_max = 2.2
	var qm := QuadMesh.new()
	qm.size = Vector2(0.02, 0.14)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(0.75, 0.88, 1.0, 0.45)
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = dm
	drip.mesh = qm
	n.add_child(drip)
	# piana na mokrej podłodze
	var foam := mat(Color(0.95, 0.97, 1.0), 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 36:
		var r := rng.randf_range(0.12, 0.4)
		var s := sphere(n, r, Vector3(rng.randf_range(-2.9, 2.9), 0.0, rng.randf_range(-4.0, 4.0)), foam)
		s.scale = Vector3(1, 0.28, 1)
