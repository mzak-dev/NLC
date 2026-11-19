class_name MapKanaly
extends Decor
## Kanały burzowe pod Starym Miastem (56 × 36 m, strop 3,0 m, otoczenie „sewer”). Pierścień tuneli
## wyłożonych kafelkami; środkiem każdego biegnie ściek (woda na −0,6 m, 2,5 m szerokości), po obu
## stronach betonowe chodniki po 4 m z obrzeżami. Na drugą stronę przejeżdża się kładkami z kraty
## (przyczepność 0,6, balustrady z blachy). Kto wpadnie do ścieku, wraca na tor (jak po wywrotce).
## Linia jazdy (na planie zgodnie z ruchem wskazówek zegara): start w komorze zbiorczej KZ-3 (klinkier,
## ceglane filary, szeroko — miejsce na wyprzedzanie) → w prawo na chodnik wewnętrzny kolektora
## południowego → kładka K-3 na chodnik zewnętrzny (szlam, właz) → łuk przy ścianie → kolektor zachodni,
## kładka K-4 na chodnik wewnętrzny (obok zasuwy) → łuk wokół bloku → kolektor północny, kładka K-1 na
## chodnik zewnętrzny → prosta pod włazem i pod rurą przelewową → łuk → kolektor wschodni, kładka K-2
## nad ściekiem z powrotem do komory.
## Własne dekoracje: grate_bridge (kładka), manhole (właz ze smugą światła i klamrami), edge (obrzeże
## ścieku), tiles (pasy kafli, brud i zacieki), services (rury i korytko kablowe na ścianie), rib (żebro
## stropu / belka komory), column (ceglany filar), inflow (rura przelewowa z wodospadem), sluice
## (zasuwa), cabinet (szafa sterownicza), bulkhead (pomarańczowa oprawa ścienna), rat (szczur).
## Ze wspólnych (Decor): paint (tablice i graffiti), floor_text.

const H := 3.0
const LVL := -0.6                              # poziom wody w ścieku
const YELLOW := Color(0.95, 0.75, 0.1)
const BLACK := Color(0.05, 0.05, 0.05)
const IRON := Color(0.07, 0.07, 0.065)
const TILE := Color(0.6, 0.64, 0.54)           # kafle ścian (styl „tile” rozjaśnia kolor)
const SLIME := Color(0.24, 0.36, 0.08, 0.8)
const WATER_C := Color(0.15, 0.17, 0.09)
const RUST := Color(0.4, 0.27, 0.17)
const WOOD := Color(0.6, 0.45, 0.28)
const CARTON := Color(0.6, 0.45, 0.3)
const ENAMEL := Color(0.1, 0.22, 0.5)          # niebieskie emaliowane tablice
const ORANGE_LAMP := Color(1.0, 0.55, 0.2)
## Kładki nad ściekiem (pokoje z kratą): północna K-1, wschodnia K-2, południowa K-3, zachodnia K-4.
const BRIDGES := [Rect2(15.0, 4.0, 6.4, 2.5), Rect2(49.5, 8.15, 2.5, 6.4), Rect2(26.45, 29.5, 6.4, 2.5), Rect2(4.0, 16.1, 2.5, 6.4)]
## Lica ścian tuneli od strony chodnika: [x0, z0, x1, z1, obrót wpisu (lokalne +Z = od ściany)].
const FACES := [
	[0.6, 0.075, 55.4, 0.075, 0.0],             # północna
	[0.6, 35.925, 55.4, 35.925, 180.0],         # południowa
	[0.075, 0.6, 0.075, 35.4, 270.0],           # zachodnia
	[55.925, 0.6, 55.925, 35.4, 90.0],          # wschodnia
	[10.425, 10.425, 37.075, 10.425, 180.0],    # blok od północy
	[10.425, 25.575, 37.075, 25.575, 0.0],      # blok od południa
	[10.425, 10.425, 10.425, 25.575, 90.0],     # blok od zachodu
]
## Linia jazdy: narożniki łamanej [x, z, promień łuku]; punkt 0 = start/meta w komorze KZ-3.
## Łuki liczy _path(); kładki przecina się ukosem (ok. 65°), żeby zakręty miały promień 4,5 m.
const ROUTE := [
	[43.25, 20.575, 0.0],                       # start / meta (komora)
	[40.5, 27.55, 6.0],                         # z komory w prawo na chodnik południowy
	[31.0, 27.55, 4.5], [28.4, 34.0, 4.5],      # kładka K-3 na chodnik zewnętrzny
	[1.6, 34.4, 4.6],                           # łuk w prawo przy ścianie
	[2.0, 21.3, 4.5], [8.0, 18.7, 4.5],         # kładka K-4 na chodnik wewnętrzny
	[8.0, 8.0, 4.5],                            # łuk wokół narożnika bloku
	[17.5, 8.0, 4.5], [20.0, 2.0, 4.5],         # kładka K-1 na chodnik zewnętrzny
	[54.4, 1.6, 4.6],                           # łuk w prawo przy ścianie
	[54.2, 9.6, 4.5], [46.0, 13.6, 4.5],        # kładka K-2 do komory
]


static func data() -> Dictionary:
	var water := []
	for rc in _channel():
		water.append({"rect": rc, "level": LVL, "color": WATER_C})
	var rooms := []
	for rc in [Rect2(0, 0, 56, 4), Rect2(0, 32, 56, 4), Rect2(0, 4, 4, 28), Rect2(52, 4, 4, 28),
			Rect2(6.5, 6.5, 43, 4), Rect2(6.5, 25.5, 43, 4), Rect2(6.5, 10.5, 4, 15)]:
		rooms.append({"rect": rc, "floor": 6, "a": Color(0.37, 0.38, 0.35), "b": Color(0.29, 0.3, 0.28), "wall": TILE, "grip": 0.95})
	rooms.append({"rect": Rect2(37, 10.5, 12.5, 15), "floor": 11, "a": Color(0.46, 0.26, 0.17), "b": Color(0.3, 0.18, 0.13), "wall": TILE, "grip": 0.9})
	var walls := [[0, 0, 56, 0], [56, 0, 56, 36], [0, 36, 56, 36], [0, 0, 0, 36],
		[10.5, 10.5, 37, 10.5], [10.5, 25.5, 37, 25.5], [10.5, 10.5, 10.5, 25.5], [37, 10.5, 37, 25.5, H, "brick"]]
	var decor := []
	var names := ["K-1", "K-2", "K-3", "K-4"]
	for i in BRIDGES.size():
		var b: Rect2 = BRIDGES[i]
		rooms.append({"rect": b, "floor": 9, "a": Color(0.45, 0.46, 0.47), "b": Color(0.3, 0.31, 0.33), "wall": Color(0.3, 0.38, 0.44), "grip": 0.6})
		var c := b.get_center()
		if b.size.x > b.size.y:          # ściek wzdłuż X: balustrady wzdłuż Z
			walls.append([b.position.x + 0.075, b.position.y, b.position.x + 0.075, b.end.y, 1.0, "metal"])
			walls.append([b.end.x - 0.075, b.position.y, b.end.x - 0.075, b.end.y, 1.0, "metal"])
			decor.append(["grate_bridge", c.x, c.y, 0.0, {"len": b.size.x, "span": b.size.y, "name": names[i]}])
		else:
			walls.append([b.position.x, b.position.y + 0.075, b.end.x, b.position.y + 0.075, 1.0, "metal"])
			walls.append([b.position.x, b.end.y - 0.075, b.end.x, b.end.y - 0.075, 1.0, "metal"])
			decor.append(["grate_bridge", c.x, c.y, 90.0, {"len": b.size.y, "span": b.size.x, "name": names[i]}])
	# obrzeża ścieku: każdy brzeg wody od strony chodnika (bez brzegów pod kładkami)
	for w in water:
		for ed in Apartment._water_edges(w.rect, water):
			var a: Vector2 = ed[0]
			var b2: Vector2 = ed[1]
			var out: Vector2 = ed[2]
			var probe := (a + b2) * 0.5 + out * 0.2
			if BRIDGES.any(func(br: Rect2) -> bool: return br.has_point(probe)):
				continue
			var mid := (a + b2) * 0.5
			decor.append(["edge", mid.x, mid.y, rad_to_deg(atan2(out.x, -out.y)), {"len": a.distance_to(b2)}])
	# ściany tuneli: kafle z brudem; rury i korytka (z przerwami na klamry włazów i rury przelewowe)
	var pipes := [
		[[0.17, 2.32, 0.3, RUST], [0.07, 2.72, 0.16, Color(0.6, 0.12, 0.08)]],
		[[0.2, 2.35, 0.33, Color(0.33, 0.36, 0.38)], [0.06, 2.75, 0.15, Color(0.85, 0.68, 0.1)]],
		[[0.15, 2.4, 0.28, RUST]],
		[[0.22, 2.3, 0.35, Color(0.3, 0.33, 0.3)]],
		[[0.12, 2.45, 0.25, Color(0.35, 0.4, 0.42)]],
		[[0.12, 2.45, 0.25, Color(0.35, 0.4, 0.42)], [0.06, 2.75, 0.15, Color(0.6, 0.12, 0.08)]],
		[[0.1, 2.5, 0.22, Color(0.6, 0.12, 0.08)]],
	]
	var gaps := [[[35.3, 36.7], [43.6, 45.4]], [[11.3, 12.7]], [], [[25.0, 27.0]], [], [], []]
	for i in FACES.size():
		var f: Array = FACES[i]
		_run(decor, "tiles", f, f[0], f[1], f[2], f[3], {})
		var along_x: bool = f[1] == f[3]
		var s0: float = f[0] if along_x else f[1]
		var s1: float = f[2] if along_x else f[3]
		for g in gaps[i] + [[s1, s1]]:
			var p0 := Vector2(s0, f[1]) if along_x else Vector2(f[0], s0)
			var p1 := Vector2(g[0], f[1]) if along_x else Vector2(f[0], g[0])
			_run(decor, "services", f, p0.x, p0.y, p1.x, p1.y, {"pipes": pipes[i], "tray": 1.95 if i != 3 else -1.0})
			s0 = g[1]
	# żebra stropu w poprzek tuneli, belki i filary komory
	for x in [14.5, 22.0, 28.5, 35.0]:
		decor.append(["rib", x, 5.25, 90.0, {"len": 10.35}])
	for x in [11.0, 18.5, 25.8, 33.3]:
		decor.append(["rib", x, 30.75, 90.0, {"len": 10.35}])
	for z in [14.6, 24.0]:
		decor.append(["rib", 5.25, z, 0.0, {"len": 10.35}])
	var beam := {"w": 0.45, "h": 0.35, "p0": false, "p1": false}
	for z in [14.5, 20.0]:                          # od ściany komory do filarów zachodnich
		decor.append(["rib", 38.34, z, 0.0, beam.merged({"len": 2.53})])
	for z in [18.5, 24.0]:                          # od filarów wschodnich nad ściekiem do ściany
		decor.append(["rib", 52.16, z, 0.0, beam.merged({"len": 7.53, "p1": true})])
	decor.append(["rib", 39.6, 17.25, 90.0, beam.merged({"len": 5.5})])
	decor.append(["rib", 48.4, 21.25, 90.0, beam.merged({"len": 5.5})])
	var cols := [[39.6, 14.5, "F-1"], [39.6, 20.0, "F-2"], [48.4, 18.5, "F-3"], [48.4, 24.0, "F-4"]]
	for c in cols:
		decor.append(["column", c[0], c[1], 0.0, {"text": c[2]}])
	decor.append_array([
		["manhole", 36.0, 0.825, 0.0, {"ladder": 0.75}],
		["manhole", 43.2, 17.5, 0.0, {}],
		["manhole", 12.0, 35.175, 180.0, {"ladder": 0.75}],
		["inflow", 44.5, 0.075, 0.0, {"len": 4.3}],
		["inflow", 55.925, 26.0, 90.0, {"len": 4.3}],
		["sluice", 45.0, 30.75, 90.0, {"text": "ZASUWA Z-2"}],
		["sluice", 5.25, 10.0, 0.0, {"text": "ZASUWA Z-1"}],
		["cabinet", 37.08, 12.4, 270.0, {}],
		["bulkhead", 37.08, 16.2, 270.0, {}],
		["bulkhead", 37.08, 23.4, 270.0, {}],
		["bulkhead", 55.92, 12.0, 90.0, {}],
		["bulkhead", 55.92, 20.5, 90.0, {}],
		["bulkhead", 10.42, 18.0, 90.0, {}],
		["bulkhead", 3.5, 35.92, 180.0, {}],
		["rat", 31.0, 10.1, 0.0, {}],
		["rat", 53.4, 33.6, 200.0, {}],
		["rat", 0.6, 14.2, 80.0, {}],
		["rat", 38.2, 25.2, 160.0, {}],
		# tablice, oznaczenia i graffiti
		["paint", 26.0, 0.08, 0.0, {"text": "KOLEKTOR PÓŁNOCNY  K-1", "size": 0.2, "y": 1.62, "plate": ENAMEL}],
		["paint", 37.4, 0.08, 0.0, {"text": "WYJŚCIE AWARYJNE", "size": 0.12, "y": 1.62, "plate": Color(0.08, 0.5, 0.2)}],
		["paint", 28.0, 10.42, 180.0, {"text": "KOLEKTOR K-2", "size": 0.3, "y": 1.7, "plate": ENAMEL}],
		["paint", 24.0, 35.92, 180.0, {"text": "TU BYŁ ZBYSZEK", "size": 0.42, "y": 0.95, "color": Color(0.8, 0.15, 0.12)}],
		["paint", 41.5, 35.92, 180.0, {"text": "KREDENSY GÓRĄ!", "size": 0.4, "y": 0.97, "color": Color(0.25, 0.75, 0.35)}],
		["paint", 13.6, 35.92, 180.0, {"text": "WYJŚCIE AWARYJNE", "size": 0.12, "y": 1.62, "plate": Color(0.08, 0.5, 0.2)}],
		["paint", 0.08, 26.0, 270.0, {"text": "KOLEKTOR ZACHODNI  K-4", "size": 0.2, "y": 1.62, "plate": ENAMEL}],
		["paint", 22.0, 25.58, 0.0, {"text": "KOLEKTOR POŁUDNIOWY  K-3", "size": 0.2, "y": 1.62, "plate": ENAMEL}],
		["paint", 37.085, 17.25, 270.0, {"text": "KOMORA ZBIORCZA  KZ-3", "size": 0.3, "y": 2.2, "plate": ENAMEL}],
		["paint", 37.085, 21.6, 270.0, {"text": "UWAGA! GAZY KANAŁOWE", "size": 0.16, "y": 1.6, "plate": YELLOW, "color": BLACK}],
		["paint", 37.085, 19.4, 270.0, {"text": "ZAKAZ PALENIA", "size": 0.14, "y": 1.6, "plate": Color(0.75, 0.1, 0.08)}],
		["paint", 55.92, 22.6, 90.0, {"text": "PRZEPOMPOWNIA  →", "size": 0.25, "y": 1.9, "plate": Color(0.5, 0.1, 0.08)}],
		["paint", 55.92, 8.0, 90.0, {"text": "KOLEKTOR WSCHODNI  K-2", "size": 0.2, "y": 1.62, "plate": ENAMEL}],
		# napisy na chodnikach
		["floor_text", 13.6, 8.0, 90.0, {"text": "KŁADKA", "size": 0.45, "color": YELLOW}],
		["floor_text", 35.2, 27.55, 270.0, {"text": "KŁADKA", "size": 0.45, "color": YELLOW}],
		["floor_text", 1.85, 26.5, 0.0, {"text": "KŁADKA", "size": 0.45, "color": YELLOW}],
		["floor_text", 54.27, 6.6, 180.0, {"text": "KŁADKA", "size": 0.4, "color": YELLOW}],
		["floor_text", 27.4, 1.92, 90.0, {"text": "ŚLISKO", "size": 0.45, "color": YELLOW}],
		["floor_text", 20.4, 34.12, 270.0, {"text": "ŚLISKO", "size": 0.45, "color": YELLOW}],
		["floor_text", 46.4, 23.2, 154.0, {"text": "KZ-3", "size": 0.8}],
	])
	for x in [6.0, 16.0, 46.0, 52.0]:
		decor.append(["paint", x, 0.08, 0.0, {"text": "0+%03d" % int(x * 5.0), "size": 0.13, "y": 1.95, "plate": Color(0.92, 0.92, 0.88), "color": BLACK}])
	for x in [7.0, 31.0, 48.0]:
		decor.append(["paint", x, 35.92, 180.0, {"text": "3+%03d" % int((56.0 - x) * 5.0), "size": 0.13, "y": 1.95, "plate": Color(0.92, 0.92, 0.88), "color": BLACK}])
	# kratki ściekowe przy obrzeżach (linie): [x, z, wzdłuż X?]
	var lines := []
	for g in [[8.0, 3.3, true], [26.5, 3.3, true], [40.0, 3.3, true], [48.0, 3.3, true], [11.0, 7.2, true], [27.0, 7.2, true],
			[35.0, 7.2, true], [43.0, 7.2, true], [7.0, 32.7, true], [22.0, 32.7, true], [37.0, 32.7, true], [46.0, 32.7, true],
			[14.0, 28.8, true], [22.0, 28.8, true], [34.0, 28.8, true], [3.3, 9.0, false], [3.3, 27.0, false], [7.2, 13.5, false],
			[7.2, 24.5, false], [52.7, 17.0, false], [52.7, 29.0, false]]:
		_grate(lines, g[0], g[1], g[2], 0.9, 0.45)
	_grate(lines, 46.2, 22.0, true, 1.2, 1.2)        # wpust w komorze
	_grate(lines, 40.9, 12.2, true, 1.2, 1.2)
	return {
		"id": "kanaly", "name": "KANAŁY", "place": "kanały burzowe pod Starym Miastem",
		"laps": 5, "size": Vector2(56, 36), "height": H, "env": "sewer", "ceiling": true, "wall_style": "tile",
		"lamp_color": ORANGE_LAMP, "lamp_energy": 1.7, "flicker": [15],
		"rooms": rooms, "water": water, "walls": walls, "path": _path(), "lines": lines, "decor": decor,
		"rugs": [
			{"rect": Rect2(30.0, 0.5, 3.6, 3.0), "puddle": true, "color": SLIME, "grip": 0.4},       # szlam na prostej
			{"rect": Rect2(15.5, 32.6, 3.4, 2.9), "puddle": true, "color": SLIME, "grip": 0.4},
			{"rect": Rect2(37.4, 15.4, 1.5, 3.4), "puddle": true, "color": SLIME, "grip": 0.4},      # pod ścianą komory
			{"rect": Rect2(52.6, 19.0, 2.2, 4.0), "puddle": true, "color": SLIME, "grip": 0.4},
			{"rect": Rect2(0.6, 8.0, 2.4, 3.0), "puddle": true, "color": SLIME, "grip": 0.4},
			{"rect": Rect2(43.4, 2.7, 2.2, 1.1), "puddle": true, "color": Color(0.45, 0.52, 0.45, 0.4), "grip": 0.7},   # chlapie z rury
		],
		"lamps": [
			Vector2(18.2, 5.25), Vector2(6.0, 5.25), Vector2(12.0, 5.25), Vector2(25.0, 5.25), Vector2(32.0, 5.25), Vector2(39.0, 5.25),
			Vector2(50.75, 5.25), Vector2(46.0, 5.25), Vector2(50.75, 18.5), Vector2(50.75, 25.0), Vector2(50.75, 30.75), Vector2(44.0, 30.75),
			Vector2(29.65, 30.75), Vector2(37.0, 30.75), Vector2(22.0, 30.75), Vector2(15.0, 30.75), Vector2(8.0, 30.75), Vector2(5.25, 26.0),
			Vector2(5.25, 19.3), Vector2(5.25, 12.0), Vector2(5.25, 5.25), Vector2(50.75, 11.3), Vector2(44.5, 12.4), Vector2(43.0, 23.6),
		],
		"arrows": [[31.0, 1.85, 0.0], [54.25, 5.2, 90.0], [36.5, 27.55, 180.0], [9.0, 34.2, 180.0], [1.85, 27.5, 270.0],
			[8.0, 13.8, 270.0], [11.6, 8.0, 0.0]],
		"props": [
			[24.8, 0.5, 0.6, 0.9, 0.6, 18.0, Color(0.15, 0.3, 0.6), "barrel"],        # beczki pod ścianą północną
			[25.5, 0.55, 0.6, 0.9, 0.6, 18.0, Color(0.6, 0.14, 0.08), "barrel"],
			[40.6, 0.45, 0.5, 0.4, 0.5, 1.5, CARTON],                                  # kartony
			[41.2, 0.5, 0.45, 0.35, 0.45, 1.2, CARTON.darkened(0.1)],
			[40.9, 0.48, 0.4, 0.3, 0.4, 1.0, CARTON.lightened(0.1)],
			[38.0, 11.2, 0.6, 0.9, 0.6, 18.0, Color(0.85, 0.6, 0.1), "barrel"],       # komora: beczki przy szafie
			[38.7, 11.05, 0.6, 0.9, 0.6, 18.0, Color(0.15, 0.3, 0.6), "barrel"],
			[38.3, 11.9, 0.6, 0.9, 0.6, 18.0, Color(0.2, 0.4, 0.2), "barrel"],
			[47.6, 21.3, 1.0, 0.8, 1.0, 12.0, WOOD, "crate"],
			[40.4, 21.2, 0.5, 0.4, 0.5, 1.5, CARTON],
			[40.9, 21.6, 0.45, 0.35, 0.45, 1.2, CARTON.darkened(0.15)],
			[19.5, 35.4, 0.5, 0.4, 0.5, 1.5, CARTON],                                  # chodnik południowy
			[20.2, 35.45, 0.45, 0.35, 0.45, 1.2, CARTON.darkened(0.1)],
			[9.5, 35.3, 0.7, 0.22, 0.7, 8.0, BLACK, "tire"],
			[23.5, 35.35, 0.6, 0.9, 0.6, 18.0, Color(0.6, 0.14, 0.08), "barrel"],
			[0.6, 27.2, 0.6, 0.9, 0.6, 18.0, Color(0.85, 0.6, 0.1), "barrel"],        # chodnik zachodni
			[10.0, 14.0, 0.5, 0.4, 0.5, 1.5, CARTON],
			[30.0, 9.8, 1.2, 0.14, 1.0, 12.0, WOOD, "pallet"],                         # za ściekiem (tło)
			[31.4, 9.85, 0.9, 0.8, 0.9, 10.0, WOOD, "crate"],
			[44.0, 9.9, 0.6, 0.9, 0.6, 18.0, Color(0.15, 0.3, 0.6), "barrel"],
			[55.3, 30.0, 0.6, 0.9, 0.6, 18.0, Color(0.6, 0.14, 0.08), "barrel"],
			[54.8, 30.6, 0.6, 0.9, 0.6, 18.0, Color(0.85, 0.6, 0.1), "barrel"],
			[53.2, 34.6, 1.2, 0.14, 1.0, 12.0, WOOD, "pallet"],
			[53.2, 34.6, 0.9, 0.7, 0.8, 9.0, WOOD.darkened(0.15), "crate"],
			[1.0, 9.6, 1.0, 0.8, 1.0, 12.0, WOOD, "crate"],
			[0.9, 12.4, 0.5, 0.4, 0.5, 1.5, CARTON],
		],
	}


## Ściek: pierścień prostokątów wody z przerwami na kładki.
static func _channel() -> Array:
	var bn: Rect2 = BRIDGES[0]
	var be: Rect2 = BRIDGES[1]
	var bs: Rect2 = BRIDGES[2]
	var bw: Rect2 = BRIDGES[3]
	return [
		Rect2(4, 4, bn.position.x - 4, 2.5), Rect2(bn.end.x, 4, 52 - bn.end.x, 2.5),
		Rect2(49.5, 6.5, 2.5, be.position.y - 6.5), Rect2(49.5, be.end.y, 2.5, 29.5 - be.end.y),
		Rect2(4, 29.5, bs.position.x - 4, 2.5), Rect2(bs.end.x, 29.5, 52 - bs.end.x, 2.5),
		Rect2(4, 6.5, 2.5, bw.position.y - 6.5), Rect2(4, bw.end.y, 2.5, 29.5 - bw.end.y),
	]


## Linia jazdy z ROUTE: w każdym narożniku łuk o zadanym promieniu stycznie do obu odcinków (punkty
## co ok. 1,2 m), na długich prostych punkty pośrednie co ok. 6 m.
static func _path() -> Array:
	var raw := []
	var n := ROUTE.size()
	for i in n:
		var p := Vector2(ROUTE[i][0], ROUTE[i][1])
		var a := Vector2(ROUTE[i - 1][0], ROUTE[i - 1][1])
		var b := Vector2(ROUTE[(i + 1) % n][0], ROUTE[(i + 1) % n][1])
		var r: float = ROUTE[i][2]
		var d1 := (p - a).normalized()
		var d2 := (b - p).normalized()
		var th := d1.angle_to(d2)
		if r <= 0.0 or absf(th) < 0.001:
			raw.append(p)
			continue
		var t := r * tan(absf(th) * 0.5)
		var t1 := p - d1 * t
		var t2 := p + d2 * t
		var c := t1 + d1.rotated(signf(th) * PI * 0.5) * r
		var a0 := (t1 - c).angle()
		var da := wrapf((t2 - c).angle() - a0, -PI, PI)
		var k := maxi(1, ceili(absf(da) * r / 1.2))
		for j in k + 1:
			raw.append(c + Vector2.from_angle(a0 + da * j / k) * r)
	var out := []
	for i in raw.size():
		var p: Vector2 = raw[i]
		var q: Vector2 = raw[(i + 1) % raw.size()]
		out.append(p)
		var m := floori(p.distance_to(q) / 6.0)
		for j in range(1, m + 1):
			out.append(p.lerp(q, float(j) / (m + 1)))
	return out


## Wpis dekoracji wzdłuż odcinka lica ściany f (obrót z f[4]), od (x0, z0) do (x1, z1).
static func _run(decor: Array, kind: String, f: Array, x0: float, z0: float, x1: float, z1: float, o: Dictionary) -> void:
	var a := Vector2(x0, z0)
	var b := Vector2(x1, z1)
	if a.distance_to(b) < 0.5:
		return
	var mid := (a + b) * 0.5
	decor.append([kind, mid.x, mid.y, f[4], o.merged({"len": a.distance_to(b)})])


## Kratka ściekowa z linii: ciemne pole i jaśniejsze pręty w poprzek (len wzdłuż X albo Z).
static func _grate(lines: Array, x: float, z: float, along_x: bool, ln: float, w: float) -> void:
	var dx := ln * 0.5 if along_x else 0.0
	var dz := 0.0 if along_x else ln * 0.5
	lines.append([x - dx, z - dz, x + dx, z + dz, Color(0.03, 0.03, 0.03), w])
	var bar := Color(0.2, 0.2, 0.19)
	var k := int(ln / 0.15)
	for i in k + 1:
		var s := -ln * 0.5 + ln * i / k
		if along_x:
			lines.append([x + s, z - w * 0.5, x + s, z + w * 0.5, bar, 0.035])
		else:
			lines.append([x - w * 0.5, z + s, x + w * 0.5, z + s, bar, 0.035])


# ---------- pomocnicy ----------

static var _concrete_m: StandardMaterial3D
static var _shaft_m: StandardMaterial3D
static var _drop_m: StandardMaterial3D


## Beton żeber, kołnierzy i cokołów (wspólny).
static func _concrete() -> StandardMaterial3D:
	if _concrete_m == null:
		_concrete_m = Apartment.surface(Color(0.44, 0.44, 0.41), 0.95, 1.0, 0.3)
	return _concrete_m


## Materiał elementu na ścianie (węzeł n, długość ln wzdłuż lokalnego X): własna kopia, która robi
## się półprzezroczysta razem ze ścianą, kiedy ta zasłania kredens przed kamerą.
func _fading(n: Node3D, ln: float, m: StandardMaterial3D) -> StandardMaterial3D:
	var fm: StandardMaterial3D = m.duplicate()
	var p := Vector2(n.position.x, n.position.z)
	var d := Vector2.from_angle(-n.rotation.y) * ln * 0.5
	apt._fade_segs.append({"a": p - d, "b": p + d, "mat": fm, "alpha": 1.0})
	return fm


## MultiMesh z _boxes, ale z własnym materiałem (kolor z instancji).
func _boxes_with(parent: Node3D, items: Array, m: StandardMaterial3D) -> void:
	if items.is_empty():
		return
	_boxes(parent, items, m.roughness, m.metallic, false)
	(parent.get_child(parent.get_child_count() - 1) as GeometryInstance3D).material_override = m


## Wiele obróconych walców jednym wywołaniem rysowania (kołnierze rur): xf = transformacje walca r = 1, h = 1.
static func _cylinders(parent: Node3D, xf: Array, m: Material) -> void:
	if xf.is_empty():
		return
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 1.0
	cm.radial_segments = 14
	cm.rings = 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cm
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = m
	parent.add_child(mi)


## Kropla / strumień wody (cząstki).
static func _drops() -> StandardMaterial3D:
	if _drop_m == null:
		_drop_m = StandardMaterial3D.new()
		_drop_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_drop_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_drop_m.albedo_color = Color(0.62, 0.7, 0.58, 0.5)
		_drop_m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	return _drop_m


static func _particles(parent: Node3D, pos: Vector3, amount: int, life: float, size: Vector2) -> CPUParticles3D:
	var cp := CPUParticles3D.new()
	cp.position = pos
	cp.amount = amount
	cp.lifetime = life
	var qm := QuadMesh.new()
	qm.size = size
	qm.material = _drops()
	cp.mesh = qm
	parent.add_child(cp)
	return cp


# ---------- kładka ----------

## Kładka nad ściekiem (lokalne X = wzdłuż ścieku {len}, Z = w poprzek {span}): krata pomostowa,
## żółte dźwigary i ciemny prześwit nad wodą po obu stronach, poręcze i pasy ostrzegawcze na końcach
## balustrad (balustrady to ściany „metal” z danych), tabliczki z nazwą {name}, lampki na słupkach.
func k_grate_bridge(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var ln: float = o.get("len", 6.4)
	var sp: float = o.get("span", 2.5)
	var hx := ln * 0.5
	var hz := sp * 0.5
	var lite := Color(0.5, 0.51, 0.52)
	box(n, Vector3(ln - 0.3, 0.004, sp), Vector3(0, 0.003, 0), mat(Color(0.025, 0.025, 0.025), 0.9))   # prześwit pod kratą
	var bars := []
	var x := -hx + 0.2
	while x <= hx - 0.2:                      # płaskowniki nośne co 9 cm
		bars.append([Vector3(x, 0.008, 0), Vector3(0.03, 0.008, sp), lite])
		x += 0.09
	var z := -hz + 0.1
	while z <= hz - 0.05:                     # pręty poprzeczne
		bars.append([Vector3(0, 0.01, z), Vector3(ln - 0.3, 0.006, 0.02), lite])
		z += 0.45
	for s in [-1.0, 1.0]:
		bars.append([Vector3(0, 0.009, s * (hz - 0.04)), Vector3(ln - 0.3, 0.014, 0.08), Color(0.2, 0.2, 0.21)])   # kątownik
		var k := 0
		x = -hx + 0.15
		while x < hx - 0.16:                  # żółto-czarny pas na chodniku przed kładką
			bars.append([Vector3(x + 0.15, 0.007, s * (hz + 0.09)), Vector3(0.3, 0.006, 0.14), YELLOW if k % 2 == 0 else BLACK])
			x += 0.3
			k += 1
		for sz in [-1.0, 1.0]:                # pasy na czołach balustrad
			for b in 5:
				bars.append([Vector3(s * (hx - 0.075), 0.098 + b * 0.196, sz * (hz + 0.081)), Vector3(0.17, 0.196, 0.012),
					YELLOW if b % 2 == 0 else BLACK])
	_boxes(n, bars, 0.45, 0.6, false)
	var girder := mat(Color(0.85, 0.62, 0.1), 0.5, 0.4)
	var dark := mat(Color(0.015, 0.018, 0.012), 1.0)
	var rail := mat(YELLOW, 0.45, 0.3)
	var plate := mat(Color(0.92, 0.92, 0.88), 0.5)
	for s in [-1.0, 1.0]:
		box(n, Vector3(0.02, 0.46, sp - 0.1), Vector3(s * (hx + 0.012), -0.47, 0), dark)             # prześwit pod pomostem
		box(n, Vector3(0.07, 0.24, sp + 0.2), Vector3(s * (hx + 0.035), -0.12, 0), girder)          # dźwigar
		box(n, Vector3(0.13, 0.03, sp + 0.2), Vector3(s * (hx + 0.065), -0.235, 0), girder)
		box(n, Vector3(0.07, 0.06, sp + 0.15), Vector3(s * (hx - 0.075), 1.03, 0), rail)             # poręcz
		for sz in [-1.0, 1.0]:                # słupki z lampkami ostrzegawczymi
			box(n, Vector3(0.06, 0.22, 0.06), Vector3(s * (hx - 0.075), 1.17, sz * (hz + 0.02)), mat(Color(0.2, 0.2, 0.21), 0.5, 0.6))
			sphere(n, 0.055, Vector3(s * (hx - 0.075), 1.31, sz * (hz + 0.02)), glow(Color(1.0, 0.45, 0.05), 5.0))
		box(n, Vector3(0.012, 0.26, 1.1), Vector3(s * (hx + 0.006), 0.62, 0), plate)                # tabliczka na zewnątrz
		var l := label(n, "KŁADKA %s\nmax 3,5 t" % o.get("name", ""), 0.085, Vector3(s * (hx + 0.014), 0.62, 0), BLACK)
		l.rotation.y = s * PI / 2
		l.shaded = true


# ---------- ściek i ściany ----------

## Obrzeże ścieku wzdłuż lokalnego X {len}, lokalne +Z = woda: kapinos, stalowy narożnik nad wodą,
## żółta linia na chodniku, mokry pas i glony na ścianie ścieku.
func k_edge(e: Array) -> void:
	var n := root(e)
	var ln: float = opts(e).get("len", 5.0)
	box(n, Vector3(ln, 0.012, 0.3), Vector3(0, 0.005, -0.15), mat(Color(0.5, 0.5, 0.47), 0.9))
	box(n, Vector3(ln, 0.11, 0.04), Vector3(0, -0.045, 0.02), mat(Color(0.25, 0.26, 0.27), 0.45, 0.7))
	box(n, Vector3(ln, 0.004, 0.1), Vector3(0, 0.006, -0.45), mat(Color(0.78, 0.64, 0.12), 0.7))
	box(n, Vector3(ln, 0.24, 0.01), Vector3(0, LVL + 0.28, 0.005), mat(Color(0.17, 0.19, 0.13), 0.6))
	box(n, Vector3(ln, 0.16, 0.012), Vector3(0, LVL + 0.07, 0.006), mat(Color(0.07, 0.13, 0.04), 1.0))


## Ściana tunelu wzdłuż lokalnego X {len} (lokalne +Z = od ściany): brudny cokół, ciemniejszy pas,
## zielony pas glazurowanych kafli, rdzawe zacieki i odpadnięte kafle.
func k_tiles(e: Array) -> void:
	var n := root(e)
	var ln: float = opts(e).get("len", 10.0)
	box(n, Vector3(ln, 0.32, 0.012), Vector3(0, 0.16, 0.006), _fading(n, ln, mat(Color(0.2, 0.19, 0.12), 0.95)))
	box(n, Vector3(ln, 0.3, 0.01), Vector3(0, 0.47, 0.005), _fading(n, ln, mat(Color(0.4, 0.41, 0.32), 0.85)))
	var stripe: StandardMaterial3D
	if Apartment._tile_tex != null:
		stripe = Apartment._tex_mat(Apartment._tile_tex, Vector3.ONE / 1.2, 0.25)
		stripe.albedo_color = Color(0.2, 0.42, 0.3)
	else:
		stripe = mat(Color(0.2, 0.42, 0.3), 0.25)
	box(n, Vector3(ln, 0.15, 0.012), Vector3(0, 1.24, 0.006), _fading(n, ln, stripe))
	var edge := _fading(n, ln, mat(Color(0.08, 0.18, 0.12), 0.3))
	box(n, Vector3(ln, 0.025, 0.014), Vector3(0, 1.152, 0.007), edge)
	box(n, Vector3(ln, 0.025, 0.014), Vector3(0, 1.328, 0.007), edge)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(n.position.x * 31.0 + n.position.z * 17.0))
	var items := []
	for i in int(ln / 1.4):
		var h := rng.randf_range(0.4, 1.6)
		items.append([Vector3(rng.randf_range(-ln * 0.5 + 0.3, ln * 0.5 - 0.3), 2.25 - h * 0.5, 0.004),
			Vector3(rng.randf_range(0.05, 0.22), h, 0.004), Color(0.46, 0.36, 0.24).lerp(Color(0.32, 0.34, 0.24), rng.randf())])
	for i in int(ln / 2.5):
		var y := rng.randf_range(0.75, 2.3)
		if absf(y - 1.24) < 0.15:
			continue
		items.append([Vector3(rng.randf_range(-ln * 0.5 + 0.3, ln * 0.5 - 0.3), y, 0.005), Vector3(0.15, 0.15, 0.006), Color(0.34, 0.33, 0.3)])
	_boxes_with(n, items, _fading(n, ln, _tint(0.9, 0.0)))


## Instalacje na ścianie wzdłuż lokalnego X {len, pipes = [[r, y, odsunięcie, kolor], …], tray = y korytka
## kablowego albo < 0}: rury z kołnierzami co 3 m i obejmami co 2 m, korytko z trzema kablami.
func k_services(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var ln: float = o.get("len", 10.0)
	var steel := Color(0.3, 0.31, 0.32)
	var parts := []
	for p in o.get("pipes", []):
		var r: float = p[0]
		var y: float = p[1]
		var off: float = p[2]
		var pm := _fading(n, ln, mat(p[3], 0.5, 0.5))
		cyl(n, r, ln, Vector3(0, y, off), pm).rotation.z = PI / 2
		var xf := []
		var x := -ln * 0.5 + 0.4
		while x < ln * 0.5:
			xf.append(Transform3D(Basis(Vector3.BACK, PI / 2) * Basis.from_scale(Vector3(r * 1.3, 0.05, r * 1.3)), Vector3(x, y, off)))
			x += 3.0
		_cylinders(n, xf, pm)
		x = -ln * 0.5 + 1.0
		while x < ln * 0.5:
			parts.append([Vector3(x, y, off * 0.5), Vector3(0.05, 0.05, off), steel])
			parts.append([Vector3(x, y, off), Vector3(0.04, r * 2.0 + 0.06, r * 2.0 + 0.06), steel])
			x += 2.0
	var ty: float = o.get("tray", -1.0)
	if ty > 0.0:
		box(n, Vector3(ln, 0.05, 0.3), Vector3(0, ty, 0.2), _fading(n, ln, mat(Color(0.6, 0.62, 0.63), 0.4, 0.7)))
		var black := _fading(n, ln, mat(Color(0.04, 0.04, 0.04), 0.6))
		for z in [0.11, 0.19, 0.27]:
			box(n, Vector3(ln, 0.035, 0.035), Vector3(0, ty + 0.045, z), black)
		var x := -ln * 0.5 + 0.75
		while x < ln * 0.5:
			parts.append([Vector3(x, ty - 0.045, 0.18), Vector3(0.04, 0.04, 0.36), steel])
			x += 1.5
	_boxes_with(n, parts, _fading(n, ln, _tint(0.5, 0.6)))


## Żebro stropu w poprzek tunelu wzdłuż lokalnego X {len, w = 0,35, h = 0,22, p0 / p1 = pilaster ze
## skosem przy końcu −X / +X}. Bez kolizji.
func k_rib(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var ln: float = o.get("len", 10.0)
	var w: float = o.get("w", 0.35)
	var h: float = o.get("h", 0.22)
	var cm := _concrete()
	box(n, Vector3(ln, h, w), Vector3(0, H - h * 0.5, 0), cm)
	for s in [-1.0, 1.0]:
		if not o.get("p0" if s < 0.0 else "p1", true):
			continue
		box(n, Vector3(0.1, H, w + 0.08), Vector3(s * (ln * 0.5 - 0.05), H * 0.5, 0), cm)
		var hb := box(n, Vector3(0.56, 0.12, w), Vector3(s * (ln * 0.5 - 0.2), H - h - 0.2, 0), cm)
		hb.rotation.z = -s * PI / 4


## Ceglany filar komory z betonowym cokołem i głowicą, pasami ostrzegawczymi i numerem {text}.
func k_column(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	solid(n, Vector3(0.9, H, 0.9), Vector3(0, H * 0.5, 0), apt._brick_mat())
	var cm := _concrete()
	box(n, Vector3(1.1, 0.35, 1.1), Vector3(0, 0.175, 0), cm)
	box(n, Vector3(1.1, 0.3, 1.1), Vector3(0, H - 0.15, 0), cm)
	for k in 3:
		box(n, Vector3(0.92, 0.12, 0.92), Vector3(0, 0.62 + k * 0.12, 0), mat(YELLOW if k % 2 == 0 else BLACK, 0.6))
	for a in [0.0, PI / 2, PI, -PI / 2]:
		var f := Node3D.new()
		f.rotation.y = a
		n.add_child(f)
		box(f, Vector3(0.5, 0.3, 0.01), Vector3(0, 1.75, 0.455), mat(Color(0.92, 0.92, 0.88), 0.6))
		label(f, o.get("text", ""), 0.18, Vector3(0, 1.75, 0.462), BLACK).shaded = true


# ---------- właz, rura przelewowa, zasuwa ----------

## Właz w stropie (lokalne −Z = do ściany): betonowy kołnierz, krata z dziennym światłem, smuga
## światła, reflektor w dół (cień z budżetu mapy), kapiąca woda, mokra plama i klamry na ścianie
## {ladder = odległość środka włazu od lica ściany}.
func k_manhole(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var iron := mat(IRON, 0.5, 0.6)
	cyl(n, 0.6, 0.05, Vector3(0, H - 0.025, 0), _concrete())
	cyl(n, 0.45, 0.03, Vector3(0, H - 0.06, 0), iron)
	cyl(n, 0.36, 0.01, Vector3(0, H - 0.078, 0), glow(Color(0.85, 0.92, 1.0), 6.0))
	for k in 5:
		box(n, Vector3(0.74, 0.014, 0.035), Vector3(0, H - 0.086, (k - 2) * 0.13), iron)
	if _shaft_m == null:
		_shaft_m = StandardMaterial3D.new()
		_shaft_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shaft_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shaft_m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_shaft_m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_shaft_m.albedo_color = Color(0.5, 0.58, 0.48, 0.09)
		_shaft_m.proximity_fade_enabled = true
		_shaft_m.proximity_fade_distance = 0.6
	var shaft := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.36
	cm.bottom_radius = 1.2
	cm.height = H - 0.1
	cm.radial_segments = 24
	cm.rings = 1
	cm.cap_top = false
	cm.cap_bottom = false
	shaft.mesh = cm
	shaft.position = Vector3(0, (H - 0.1) * 0.5, 0)
	shaft.material_override = _shaft_m
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(shaft)
	var sl := SpotLight3D.new()
	sl.position = Vector3(0, H - 0.1, 0)
	sl.rotation.x = -PI / 2
	sl.light_color = Color(0.82, 0.9, 1.0)
	sl.light_energy = 5.0
	sl.spot_range = 5.0
	sl.spot_angle = 34.0
	sl.light_volumetric_fog_energy = 2.0
	sl.shadow_enabled = o.get("shadow", true) and apt.take_shadow()
	n.add_child(sl)
	var cp := _particles(n, Vector3(0, H - 0.1, 0), 10, 0.8, Vector2(0.015, 0.08))
	cp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	cp.emission_sphere_radius = 0.3
	cp.direction = Vector3.DOWN
	cp.initial_velocity_min = 0.2
	cp.initial_velocity_max = 0.5
	var wet := cyl(n, 0.8, 0.004, Vector3(0, 0.007, 0), mat(Color(0.2, 0.24, 0.2, 0.5), 0.05))
	wet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if o.has("ladder"):
		var d: float = o.ladder
		var steel := Color(0.45, 0.43, 0.4)
		var rungs := []
		var y := 0.45
		while y < H - 0.1:
			rungs.append([Vector3(0, y, -d + 0.16), Vector3(0.4, 0.03, 0.03), steel])
			for s in [-0.19, 0.19]:
				rungs.append([Vector3(s, y, -d + 0.08), Vector3(0.03, 0.03, 0.16), steel])
			y += 0.3
		_boxes(n, rungs, 0.45, 0.7)


## Rura przelewowa ze ściany nad chodnikiem (lokalne +Z = od ściany, {len}, {y = oś}) z wodospadem do
## ścieku: kołnierz w ścianie, wieszaki do stropu, strumień i plusk z cząstek, piana na wodzie.
func k_inflow(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var ln: float = o.get("len", 4.3)
	var y: float = o.get("y", 2.6)
	var r := 0.24
	var pm := mat(Color(0.36, 0.3, 0.24), 0.6, 0.5)
	cyl(n, r, ln, Vector3(0, y, ln * 0.5), pm).rotation.x = PI / 2
	for z in [0.3, ln * 0.5, ln - 0.05]:
		cyl(n, r * 1.25, 0.08, Vector3(0, y, z), pm).rotation.x = PI / 2
	box(n, Vector3(0.8, 0.8, 0.05), Vector3(0, y, 0.025), _concrete())
	cyl(n, r * 0.85, 0.02, Vector3(0, y, ln + 0.002), mat(Color(0.02, 0.025, 0.02), 1.0)).rotation.x = PI / 2
	var steel := mat(Color(0.3, 0.31, 0.32), 0.5, 0.7)
	for z in [ln * 0.3, ln * 0.78]:
		box(n, Vector3(0.04, H - y - r, 0.04), Vector3(0, (H + y + r) * 0.5, z), steel)
		box(n, Vector3(r * 2.0 + 0.08, 0.04, 0.06), Vector3(0, y - r - 0.02, z), steel)
	box(n, Vector3(r * 1.4, 0.3, 0.02), Vector3(0, y - r * 0.3, ln + 0.06), mat(Color(0.12, 0.2, 0.08, 0.7), 0.3))   # glony u wylotu
	var st := _particles(n, Vector3(0, y - r * 0.55, ln + 0.03), 150, 0.85, Vector2(0.09, 0.22))
	st.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	st.emission_box_extents = Vector3(r * 0.55, 0.05, 0.02)
	st.direction = Vector3(0, -0.1, 1)
	st.spread = 6.0
	st.initial_velocity_min = 1.0
	st.initial_velocity_max = 1.5
	st.scale_amount_min = 0.8
	st.scale_amount_max = 1.4
	var land := ln + 1.1
	cyl(n, 0.6, 0.02, Vector3(0, LVL + 0.012, land), mat(Color(0.8, 0.84, 0.76, 0.65), 1.0))
	var sp := _particles(n, Vector3(0, LVL + 0.02, land), 36, 0.45, Vector2(0.06, 0.06))
	sp.direction = Vector3.UP
	sp.spread = 55.0
	sp.initial_velocity_min = 1.0
	sp.initial_velocity_max = 1.9


## Zasuwa na ścieku (lokalne X = w poprzek ścieku, środek nad osią) {text}: prowadnice w wodzie,
## belka nad chodnikami, uniesiona rdzawa zasuwa, trzpień, przekładnia i pokrętło, piana pod zasuwą.
func k_sluice(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var sp := 2.5
	var paint := mat(Color(0.16, 0.36, 0.42), 0.55, 0.4)
	var rust := mat(Color(0.38, 0.22, 0.12), 0.9, 0.3)
	var steel := mat(Color(0.5, 0.5, 0.52), 0.35, 0.8)
	for s in [-1.0, 1.0]:
		box(n, Vector3(0.14, 3.0, 0.22), Vector3(s * (sp * 0.5 - 0.07), 0.8, 0), paint)
	box(n, Vector3(sp + 0.4, 0.22, 0.3), Vector3(0, 2.3, 0), paint)
	var gb := LVL + 0.15
	box(n, Vector3(sp - 0.3, 0.95, 0.07), Vector3(0, gb + 0.475, 0), rust)
	for k in 3:
		box(n, Vector3(sp - 0.3, 0.05, 0.11), Vector3(0, gb + 0.15 + k * 0.33, 0), rust)
	cyl(n, 0.04, 2.3 - gb - 0.95, Vector3(0, (2.3 + gb + 0.95) * 0.5, 0), steel)
	cyl(n, 0.035, 0.7, Vector3(0, 2.75, 0), steel)
	box(n, Vector3(0.36, 0.25, 0.3), Vector3(0, 2.53, 0), paint)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.25
	tm.outer_radius = 0.3
	tm.rings = 20
	tm.ring_segments = 8
	var wheel := MeshInstance3D.new()
	wheel.mesh = tm
	wheel.material_override = mat(Color(0.75, 0.1, 0.08), 0.5, 0.3)
	wheel.position = Vector3(0, 2.8, 0)
	n.add_child(wheel)
	for a in [0.0, PI / 2]:
		box(n, Vector3(0.52, 0.025, 0.025), Vector3(0, 2.8, 0), wheel.material_override).rotation.y = a
	box(n, Vector3(sp - 0.2, 0.012, 0.7), Vector3(0, LVL + 0.012, 0.4), mat(Color(0.78, 0.82, 0.72, 0.55), 1.0))
	for s in [-1.0, 1.0]:
		var l := label(n, o.get("text", ""), 0.1, Vector3(0, 2.3, s * 0.155), Color(0.92, 0.92, 0.88))
		l.rotation.y = 0.0 if s > 0 else PI
		l.shaded = true


# ---------- drobne ----------

## Szafa sterownicza przy ścianie (lokalne +Z = od ściany): drzwi, kontrolki, wyświetlacz, rura do stropu.
func k_cabinet(e: Array) -> void:
	var n := root(e)
	solid(n, Vector3(1.2, 1.9, 0.5), Vector3(0, 0.95, 0.25), mat(Color(0.52, 0.55, 0.53), 0.5, 0.3))
	var dark := mat(Color(0.12, 0.12, 0.13), 0.5)
	box(n, Vector3(0.01, 1.8, 0.01), Vector3(0, 0.95, 0.505), dark)
	for x in [-0.08, 0.08]:
		box(n, Vector3(0.03, 0.14, 0.03), Vector3(x, 1.0, 0.52), dark)
	box(n, Vector3(0.36, 0.2, 0.01), Vector3(-0.3, 1.5, 0.505), glow(Color(0.3, 0.9, 0.6), 1.4))
	var c := [Color(0.1, 1.0, 0.3), Color(1.0, 0.15, 0.1), Color(1.0, 0.65, 0.1)]
	for i in 3:
		sphere(n, 0.025, Vector3(0.2 + i * 0.1, 1.55, 0.51), glow(c[i], 4.0))
	box(n, Vector3(0.9, 0.16, 0.01), Vector3(0, 1.78, 0.505), mat(Color(0.92, 0.92, 0.88), 0.6))
	label(n, "STEROWANIE PRZEPOMPOWNI", 0.055, Vector3(0, 1.78, 0.512), BLACK).shaded = true
	var d := box(n, Vector3(0.16, 0.16, 0.01), Vector3(0.35, 1.2, 0.506), mat(YELLOW, 0.5))
	d.rotation.z = PI / 4
	cyl(n, 0.05, H - 1.9, Vector3(0.4, (H + 1.9) * 0.5, 0.2), mat(Color(0.4, 0.42, 0.44), 0.5, 0.5))


## Pomarańczowa oprawa ścienna w koszyku (lokalne +Z = od ściany) {y}: słaba lampa bez cienia.
func k_bulkhead(e: Array) -> void:
	var n := root(e)
	var y: float = opts(e).get("y", 2.25)
	var cage := mat(Color(0.18, 0.18, 0.18), 0.6, 0.4)
	box(n, Vector3(0.3, 0.2, 0.06), Vector3(0, y, 0.03), cage)
	var g := sphere(n, 0.1, Vector3(0, y, 0.1), glow(ORANGE_LAMP, 5.0))
	g.scale = Vector3(1.3, 0.8, 0.7)
	for x in [-0.07, 0.0, 0.07]:
		box(n, Vector3(0.012, 0.18, 0.012), Vector3(x, y, 0.18), cage)
	box(n, Vector3(0.28, 0.012, 0.012), Vector3(0, y, 0.18), cage)
	lamp(n, Vector3(0, y, 0.45), ORANGE_LAMP, 0.7, 6.0, false)


## Szczur (lokalne +X = przód) ze świecącymi oczkami.
func k_rat(e: Array) -> void:
	var n := root(e)
	var fur := mat(Color(0.22, 0.19, 0.17), 0.9)
	var pink := mat(Color(0.75, 0.52, 0.5), 0.6)
	sphere(n, 0.06, Vector3(0, 0.055, 0), fur).scale = Vector3(1.8, 0.9, 1.0)
	sphere(n, 0.038, Vector3(0.11, 0.06, 0), fur).scale = Vector3(1.4, 1.0, 1.0)
	sphere(n, 0.012, Vector3(0.16, 0.058, 0), pink)
	for s in [-1.0, 1.0]:
		sphere(n, 0.016, Vector3(0.095, 0.098, s * 0.025), pink)
		sphere(n, 0.007, Vector3(0.14, 0.072, s * 0.018), glow(Color(1.0, 0.15, 0.05), 3.0))
	_beam(n, Vector3(-0.1, 0.035, 0), Vector3(-0.32, 0.008, 0.09), 0.012, pink)
