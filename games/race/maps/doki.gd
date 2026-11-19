class_name MapDoki
extends Decor
## Doki portowe (70 × 46 m, otwarty teren o pochmurnym świcie, 2 okrążenia). Start na drodze północnej
## (asfalt) między stosami kontenerów → wrotami zachodnimi do magazynu nr 3 (gładki beton, regały z
## paletami, wózki widłowe) → nawrót w prawo i wrotami południowymi na plac → w prawo na nabrzeże: na
## zachód wzdłuż krawędzi BEZ barierek (mokre płyty, pachołki cumownicze, przycumowany holownik) → pod
## suwnicą bramową z wiszącym kontenerem → po stalowych płytach → przejazd przez dwa tory bocznicy →
## na północ eskiem przez labirynt kontenerów → start. Kto wyjedzie za krawędź, wpada do wody i wraca na tor.
## Tło za basenem: statek „SZAFA GDAŃSKA” przy przeciwległym nabrzeżu, żurawie portowe, szopy, silosy,
## falochron z latarnią, boje.
## Własne dekoracje: bollard (pachołek cumowniczy), quay_edge (krawędź nabrzeża), gantry (suwnica
## bramowa), rails (tory z podsypką, przejazdem i kozłami oporowymi), andrew (krzyż św. Andrzeja), wagon
## (platforma z kontenerami / lokomotywa manewrowa), rack (regał z paletami), forklift (wózek widłowy),
## gate (wrota magazynu), roof (dach hali), office (kontener-biuro), mast (maszt oświetleniowy),
## portal_sign (drogowskaz nad jezdnią), lifebuoy (koło ratunkowe), tug (holownik z cumami), ship
## (statek), crane (żuraw portowy), far_quay (przeciwległe nabrzeże z falochronem), buoy (boja).

const YELLOW := Color(0.95, 0.75, 0.1)
const WHITE := Color(0.9, 0.9, 0.88)
const ORANGE := Color(0.95, 0.4, 0.05)
const WALL := Color(0.55, 0.62, 0.68)       # niebieskoszara blacha magazynu
const WOOD := Color(0.62, 0.47, 0.3)
const CARTON := Color(0.62, 0.46, 0.3)
const WH := 6.5                             # wysokość ścian magazynu
const WATER := -0.8                         # poziom wody w basenie
const QUAY := 40.0                          # z krawędzi nabrzeża
const PUDDLE := Color(0.5, 0.6, 0.7, 0.32)


static func data() -> Dictionary:
	var decor := []
	var lines := []
	# kontenery 20' (6,06 × 2,44 wzdłuż lokalnego X, drzwi na +X): [x, z, obrót, piętra, kolory pięter?]
	var blue := Color(0.1, 0.3, 0.55)
	for c in [
		# przy płocie północnym (droga startowa)
		[4.5, 1.35, 0, 2], [11.0, 1.35, 180, 1], [17.5, 1.35, 0, 3], [24.0, 1.35, 180, 2], [30.5, 1.35, 0, 1], [37.0, 1.35, 0, 2],
		# południowa strona drogi północnej
		[23.2, 11.0, 0, 2], [29.4, 11.0, 180, 3], [35.6, 11.0, 0, 1], [40.0, 11.0, 90, 2], [42.5, 11.0, 90, 1],
		# labirynt: kolumna przy płocie zachodnim, ściana od placu, bloki wcinające się w esek
		[1.3, 6.0, 90, 2], [1.3, 12.15, 270, 1], [1.3, 18.3, 90, 2], [1.3, 24.45, 270, 1], [3.6, 28.75, 0, 2],
		[18.8, 13.2, 90, 3], [18.8, 19.3, 270, 2], [18.8, 25.4, 90, 3], [18.8, 31.6, 270, 2],
		[14.5, 13.5, 180, 3], [6.9, 22.3, 0, 3, [blue, Color(0.62, 0.14, 0.1), Color(0.5, 0.5, 0.52)]], [16.2, 22.0, 90, 2],
		[14.5, 29.5, 0, 2],
		# plac w środku pętli
		[31.4, 16.6, 0, 3], [37.6, 16.6, 0, 1], [31.4, 19.05, 180, 2], [37.6, 19.05, 180, 2], [42.2, 18.5, 90, 2],
		[31.0, 24.6, 0, 2], [37.2, 24.6, 180, 3], [31.0, 27.05, 0, 1],
		# północny brzeg nabrzeża i plac przed magazynem
		[30.6, 30.8, 180, 2], [36.8, 30.8, 0, 1], [41.2, 29.0, 90, 3], [43.75, 28.4, 270, 2], [48.1, 28.9, 0, 1],
		# róg południowo-wschodni
		[64.8, 31.0, 90, 2], [68.6, 29.0, 270, 3], [68.6, 35.2, 90, 1],
		# za płotem (tło)
		[-5.5, 10.0, 90, 3], [-5.5, 22.0, 270, 2], [-8.5, 31.0, 0, 1], [76.0, 12.0, 90, 2], [76.0, 24.0, 270, 3], [79.0, 33.0, 0, 1],
	]:
		decor.append(["container", c[0], c[1], c[2], {"stack": c[3], "colors": c[4] if c.size() > 4 else []}])
	# labirynt: otwarty kontener, oznaczenia właścicieli i bloków, lampy, linie stanowisk
	decor.append_array([
		["open_doors", 9.93, 22.3, 0.0, {"color": blue}],
		["paint", 6.9, 23.54, 0.0, {"text": "KRDU 451203 7", "size": 0.3, "y": 2.15}],
		["paint", 16.2, 25.05, 0.0, {"text": "PRLU 120934 5", "size": 0.2, "y": 2.25}],
		["paint", 14.5, 14.74, 0.0, {"text": "SZFU 300112 0", "size": 0.3, "y": 2.15}],
		["paint", 17.56, 19.3, 90.0, {"text": "BLOK C", "size": 0.9, "y": 3.7}],
		["paint", 2.54, 12.15, 270.0, {"text": "BLOK B", "size": 0.8, "y": 1.45}],
		["streetlamp", 3.2, 16.4, 0.0, {"color": Color(1.0, 0.7, 0.42), "energy": 1.8, "range": 11.0}],
		["streetlamp", 17.0, 26.6, 180.0, {"color": Color(1.0, 0.7, 0.42), "energy": 1.8, "range": 11.0}],
		["floor_text", 12.4, 19.6, 0.0, {"text": "C-04", "size": 0.6, "color": YELLOW}],
	])
	for l in [[3.75, 20.95, 10.1, 20.95], [10.1, 20.95, 10.1, 23.65], [11.3, 12.1, 17.5, 12.1], [11.3, 12.1, 11.3, 14.9],
			[11.3, 30.9, 17.5, 30.9], [11.3, 28.1, 11.3, 30.9], [14.8, 18.8, 14.8, 25.2]]:
		lines.append([l[0], l[1], l[2], l[3], YELLOW, 0.1])
	# nabrzeże: krawędź, pachołki co ~6 m (przerwy na suwnicę i tory), koła ratunkowe
	decor.append(["quay_edge", 0.0, QUAY, 0.0, {"len": 70.0, "ladders": [12.0, 39.5, 62.0]}])
	for x in [3.0, 9.0, 15.0, 30.5, 35.0, 48.5, 54.0, 59.5, 65.0, 69.0]:
		decor.append(["bollard", x, 39.55, 0.0, {}])
	for x in [6.0, 33.0, 51.8]:
		decor.append(["lifebuoy", x, 39.5, 0.0, {}])
	# suwnica nad jezdnią: nogi na szynach z = 33,2 i 39,2, x = 38 i 46, wysięg nad wodę
	decor.append(["gantry", 42.0, 36.2, 90.0, {"span": 6.0, "len": 8.0, "trolley": 0.8, "color": Color(0.1, 0.35, 0.55)}])
	for z in [33.2, 39.2]:
		lines.append([30.0, z, 62.0, z, Color(0.52, 0.52, 0.54), 0.12])     # szyny jezdne suwnicy
	lines.append([30.0, 33.75, 62.0, 33.75, Color(0.11, 0.11, 0.12), 0.32])  # kanał kablowy
	# bocznica: dwa tory w poprzek nabrzeża (przejazd = progi), platforma i lokomotywa na placu
	decor.append(["rails", 21.6, 13.4, 90.0, {"len": 26.35, "cross": [18.8, 25.2], "buf0": true, "buf1": true}])
	decor.append(["rails", 26.0, 19.5, 90.0, {"len": 20.25, "cross": [12.7, 19.1], "buf0": true, "buf1": true}])
	decor.append(["wagon", 21.6, 22.6, 90.0, {"colors": [Color(0.62, 0.14, 0.1), Color(0.85, 0.85, 0.82)]}])
	decor.append(["wagon", 26.0, 25.5, 90.0, {"loco": true}])
	decor.append(["andrew", 29.0, 33.55, 270.0, {}])
	decor.append(["andrew", 28.9, 39.45, 270.0, {}])
	decor.append(["floor_text", 32.6, 37.0, 270.0, {"text": "UWAGA TORY", "size": 0.6, "color": YELLOW}])
	lines.append([28.6, 32.6, 28.6, 38.5, WHITE, 0.3])
	# magazyn nr 3: wrota, dach, regały, wózki widłowe, napisy
	decor.append_array([
		["gate", 44.0, 5.5, 90.0, {"w": 6.0, "text": "MAGAZYN 3", "inner": "WYJŚCIE"}],
		["gate", 58.0, 25.0, 0.0, {"w": 6.0, "text": "MAGAZYN 3", "inner": "NABRZEŻE"}],
		["roof", 55.0, 12.5, 0.0, {"w": 22.0, "d": 25.0, "lamps": [[-5.5, -7.0, false], [3.0, -6.5, true], [-3.5, 4.5, false], [5.0, 6.5, true]]}],
		["rack", 55.0, 0.75, 0.0, {"len": 16.2, "name": "A"}],
		["rack", 65.25, 12.5, 90.0, {"len": 21.6, "name": "B"}],
		["rack", 53.1, 17.75, 90.0, {"len": 10.8, "depth": 2.2, "name": "C"}],
		["rack", 47.6, 16.4, 90.0, {"len": 13.5, "depth": 2.2, "name": "D"}],
		["forklift", 62.0, 15.5, 0.0, {"lift": 1.62, "load": true}],
		["forklift", 62.0, 28.2, 270.0, {"lift": 0.2, "load": true, "color": Color(0.85, 0.18, 0.1)}],
		["paint", 43.92, 12.6, 90.0, {"text": "MAGAZYN 3", "size": 0.9, "y": 5.65}],
		["paint", 49.5, 25.08, 0.0, {"text": "3", "size": 1.6, "y": 3.9, "disc": YELLOW}],
		["paint", 55.0, 0.08, 0.0, {"text": "STREFA SKŁADOWANIA", "size": 0.32, "y": 5.4, "plate": Color(0.1, 0.3, 0.6)}],
		["paint", 65.92, 4.0, 270.0, {"text": "UWAGA WÓZKI WIDŁOWE", "size": 0.22, "y": 5.4, "plate": YELLOW, "color": Color(0.05, 0.05, 0.05)}],
		["floor_text", 40.0, 5.5, 90.0, {"text": "WOLNO", "size": 0.9}],
		["floor_text", 58.0, 21.5, 180.0, {"text": "WYJAZD", "size": 0.7}],
	])
	for l in [[46.3, 9.4, 46.3, 23.4], [48.9, 9.4, 48.9, 23.4], [51.8, 12.1, 51.8, 23.4], [54.4, 12.1, 54.4, 23.4],
			[64.45, 1.5, 64.45, 23.5], [46.7, 1.5, 63.3, 1.5], [60.2, 12.8, 60.2, 18.2], [60.2, 12.8, 64.2, 12.8], [60.2, 18.2, 64.2, 18.2]]:
		lines.append([l[0], l[1], l[2], l[3], YELLOW, 0.1])
	# droga północna: stanowiska kontenerów, krawędź, drogowskaz, latarnie
	lines.append([1.0, 2.8, 40.3, 2.8, WHITE, 0.1])
	for x in [7.75, 14.25, 20.75, 27.25, 33.75]:
		lines.append([x, 0.2, x, 2.8, WHITE, 0.1])
	lines.append([14.5, 8.0, 38.6, 8.0, WHITE, 0.12])
	var bay := 1
	for x in [4.5, 11.0, 17.5, 24.0, 30.5, 37.0]:
		decor.append(["floor_text", x, 3.35, 0.0, {"text": "C%d" % bay, "size": 0.5}])
		bay += 1
	decor.append(["portal_sign", 33.0, 5.5, 90.0, {"w": 5.3, "text": "MAGAZYN 3   PROSTO\nNABRZEŻE 2   W PRAWO"}])
	for x in [8.5, 21.0, 40.5]:
		decor.append(["streetlamp", x, 3.05, 90.0, {"color": Color(1.0, 0.7, 0.42), "energy": 1.6, "range": 11.0}])
	# żółta linia bezpieczeństwa wzdłuż krawędzi (przerwy na podsypkę torów)
	for seg in [[0.2, 20.0], [23.2, 24.4], [27.6, 69.8]]:
		lines.append([seg[0], 38.75, seg[1], 38.75, YELLOW, 0.15])
	# biuro nabrzeża, maszty oświetleniowe
	decor.append_array([
		["office", 3.2, 31.6, 0.0, {}],
		["mast", 34.3, 21.8, 0.0, {"h": 18.0}],
		["mast", 1.2, 33.9, 0.0, {"h": 16.0, "energy": 2.0, "range": 22.0}],
		["mast", 66.2, 38.6, 0.0, {"h": 16.0, "energy": 2.0, "range": 22.0}],
	])
	# tło za wodą: holownik przy naszym nabrzeżu, statek i żurawie przy przeciwległym, boje
	decor.append_array([
		["tug", 60.0, 42.65, 180.0, {"name": "HERKULES 3", "ropes": [[4.2, Vector2(54.0, 39.55)], [-4.6, Vector2(65.0, 39.55)]]}],
		["far_quay", 0.0, 77.0, 0.0, {}],
		["ship", 34.0, 71.0, 0.0, {"name": "SZAFA GDAŃSKA", "port": "SZCZECIN"}],
		["crane", 8.0, 82.5, 262.0, {"y": 0.6, "angle": 40.0, "hook": 14.0}],
		["crane", 37.0, 82.0, 276.0, {"y": 0.6, "angle": 30.0, "hook": 16.0, "color": Color(0.9, 0.62, 0.1)}],
		["crane", 63.0, 82.5, 292.0, {"y": 0.6, "angle": 46.0, "hook": 9.0}],
		["crane", 96.0, 82.0, 250.0, {"y": 0.6, "angle": 34.0, "hook": 6.0, "color": Color(0.9, 0.62, 0.1)}],
		["buoy", -6.0, 50.0, 0.0, {"color": Color(0.8, 0.1, 0.08)}],
		["buoy", 12.0, 56.0, 0.0, {"color": Color(0.1, 0.55, 0.2)}],
		["buoy", 84.0, 52.0, 0.0, {"color": Color(0.8, 0.1, 0.08)}],
		["buoy", 100.0, 58.0, 0.0, {"color": Color(0.1, 0.55, 0.2)}],
	])
	return {
		"id": "doki", "name": "DOKI PORTOWE", "place": "nabrzeże portowe o świcie",
		"laps": 5, "size": Vector2(70, 46), "env": "open", "mood": "swit", "ground": Color(0.3, 0.3, 0.31),
		"wall_style": "metal",
		"rooms": [
			{"rect": Rect2(0, 0, 44, 9.5), "floor": 5, "a": Color(0.16, 0.16, 0.17), "b": Color(0.28, 0.28, 0.29), "wall": WALL, "grip": 1.15},    # asfalt
			{"rect": Rect2(44, 0, 26, 26), "floor": 6, "a": Color(0.6, 0.6, 0.58), "b": Color(0.52, 0.52, 0.51), "wall": WALL, "grip": 0.9},      # hala
			{"rect": Rect2(0, 9.5, 20, 22.5), "floor": 6, "a": Color(0.45, 0.45, 0.44), "b": Color(0.37, 0.37, 0.36), "wall": WALL, "grip": 1.0}, # labirynt
			{"rect": Rect2(20, 9.5, 24, 22.5), "floor": 6, "a": Color(0.4, 0.4, 0.39), "b": Color(0.33, 0.33, 0.32), "wall": WALL, "grip": 1.0},  # plac
			{"rect": Rect2(44, 26, 26, 6), "floor": 6, "a": Color(0.45, 0.45, 0.44), "b": Color(0.37, 0.37, 0.36), "wall": WALL, "grip": 1.0},   # przed magazynem
			{"rect": Rect2(0, 32, 28, 8), "floor": 6, "a": Color(0.3, 0.31, 0.32), "b": Color(0.24, 0.25, 0.26), "wall": WALL, "grip": 0.7},    # mokre płyty
			{"rect": Rect2(28, 32, 8, 8), "floor": 9, "a": Color(0.44, 0.45, 0.47), "b": Color(0.3, 0.31, 0.33), "wall": WALL, "grip": 0.6},     # stalowe płyty
			{"rect": Rect2(36, 32, 34, 8), "floor": 6, "a": Color(0.3, 0.31, 0.32), "b": Color(0.24, 0.25, 0.26), "wall": WALL, "grip": 0.7},   # mokre płyty
		],
		"water": [{"rect": Rect2(-400, QUAY, 870, 600), "level": WATER, "color": Color(0.07, 0.16, 0.18)}],     # morze po horyzont
		"rugs": [
			{"rect": Rect2(39.0, 35.3, 3.4, 1.7), "puddle": true, "color": PUDDLE, "grip": 0.7},
			{"rect": Rect2(9.6, 33.6, 2.6, 2.4), "puddle": true, "color": PUDDLE, "grip": 0.7},
			{"rect": Rect2(29.0, 35.4, 2.2, 1.6), "puddle": true, "color": PUDDLE, "grip": 0.6},
			{"rect": Rect2(49.8, 33.4, 2.8, 1.5), "puddle": true, "color": PUDDLE, "grip": 0.7},
			{"rect": Rect2(63.0, 37.4, 3.2, 1.5), "puddle": true, "color": PUDDLE, "grip": 0.7},
			{"rect": Rect2(16.0, 38.0, 2.4, 1.2), "puddle": true, "color": PUDDLE, "grip": 0.7},
		],
		"walls": [
			[0, 0, 44, 0, 2.4, "fence"], [66, 0, 70, 0, 2.4, "fence"], [0, 0, 0, 40, 2.4, "fence"], [70, 0, 70, 40, 2.4, "fence"],
			[44, 0, 66, 0, WH], [66, 0, 66, 25, WH], [44, 0, 44, 2.5, WH], [44, 8.5, 44, 25, WH],     # magazyn: wrota zachodnie z 2,5–8,5
			[44, 25, 55, 25, WH], [61, 25, 66, 25, WH],                                               # wrota południowe x 55–61
		],
		"humps": [      # przejazd przez tory: płyty przejazdowe na wysokości główek szyn, wzdłuż X
			[20.1, 32.2, 6.4, 0.6, 1.8, 0.1, Color(0.2, 0.2, 0.21), "x"],
			[24.5, 32.2, 6.4, 0.6, 1.8, 0.1, Color(0.2, 0.2, 0.21), "x"],
		],
		"cars": [[5.0, 5.4, 0.0, Color(0.88, 0.88, 0.86), "van"], [3.6, 35.6, 0.0, Color(0.2, 0.3, 0.45), "maly"]],
		"props": [
			[45.0, 34.5, 0.35, 0.7, 0.35, 2.5, ORANGE, "cone"], [40.0, 34.4, 0.35, 0.7, 0.35, 2.5, ORANGE, "cone"],    # pod suwnicą
			[36.6, 34.5, 0.35, 0.7, 0.35, 2.5, ORANGE, "cone"],
			[4.2, 38.3, 0.6, 0.9, 0.6, 18.0, Color(0.15, 0.3, 0.6), "barrel"],                                          # beczki na krawędzi
			[4.9, 38.85, 0.6, 0.9, 0.6, 18.0, Color(0.7, 0.12, 0.08), "barrel"],
			[3.6, 38.95, 0.6, 0.9, 0.6, 18.0, Color(0.85, 0.6, 0.1), "barrel"],
			[16.3, 33.4, 1.0, 0.8, 1.0, 12.0, WOOD, "crate"], [16.7, 34.6, 0.8, 0.7, 0.8, 9.0, WOOD.darkened(0.15), "crate"],
			[47.0, 38.9, 1.2, 0.14, 1.0, 12.0, WOOD, "pallet"], [24.0, 33.4, 0.9, 0.8, 0.9, 10.0, WOOD, "crate"],
			[55.2, 27.6, 1.2, 0.14, 1.0, 12.0, WOOD, "pallet"], [55.4, 28.8, 0.9, 0.8, 0.9, 10.0, WOOD, "crate"],         # plac przed wyjazdem
			[45.6, 9.6, 1.2, 0.14, 1.0, 12.0, WOOD, "pallet"], [50.3, 9.9, 0.5, 0.4, 0.5, 1.5, CARTON],                    # magazyn
			[50.9, 10.4, 0.45, 0.35, 0.45, 1.2, CARTON.darkened(0.1)], [63.0, 2.6, 0.6, 0.9, 0.6, 18.0, Color(0.15, 0.3, 0.6), "barrel"],
			[63.7, 3.15, 0.6, 0.9, 0.6, 18.0, Color(0.7, 0.12, 0.08), "barrel"], [56.0, 23.4, 0.9, 0.8, 0.9, 10.0, WOOD, "crate"],
			[41.5, 1.9, 1.2, 0.14, 1.0, 12.0, WOOD, "pallet"], [37.2, 8.6, 0.6, 0.9, 0.6, 18.0, Color(0.2, 0.45, 0.2), "barrel"],   # droga północna
			[37.9, 9.0, 0.6, 0.9, 0.6, 18.0, Color(0.15, 0.3, 0.6), "barrel"],
			[3.6, 25.0, 0.6, 0.9, 0.6, 18.0, Color(0.7, 0.12, 0.08), "barrel"], [15.6, 17.4, 1.0, 0.8, 1.0, 12.0, WOOD, "crate"],   # labirynt
		],
		"arrows": [[26.0, 5.5, 0.0], [37.0, 5.5, 0.0], [46.0, 37.0, 180.0], [17.5, 37.0, 180.0]],
		"path": PATH, "lines": lines, "decor": decor,
	}


## Linia jazdy. Punkt 0 = start/meta na drodze północnej.
const PATH := [
	Vector2(21, 5.5), Vector2(28, 5.5), Vector2(35, 5.5), Vector2(41, 5.5),                                        # droga północna
	Vector2(46, 5.5), Vector2(52, 5.5), Vector2(55, 6.3), Vector2(57.2, 8.5), Vector2(58, 11.5),                  # wrota, łuk r = 6 w hali
	Vector2(58, 16), Vector2(58, 21), Vector2(58, 25.5), Vector2(58, 30),                                         # przez halę na plac
	Vector2(57.06, 33.5), Vector2(54.5, 36.06), Vector2(51, 37),                                                  # łuk r = 7 na nabrzeże
	Vector2(45, 37), Vector2(39, 37), Vector2(33, 37), Vector2(27, 37), Vector2(21, 37), Vector2(13, 37),          # suwnica, płyty, tory
	Vector2(10.5, 36.33), Vector2(8.67, 34.5), Vector2(8, 32),                                                    # łuk r = 5
	Vector2(8.93, 29), Vector2(10.95, 26), Vector2(12.5, 22), Vector2(10.95, 18), Vector2(8.93, 15), Vector2(8, 12), # esek w labiryncie
	Vector2(8.87, 8.75), Vector2(11.25, 6.37), Vector2(14.5, 5.5),                                                # łuk r = 6,5
]


# ---------- pomocnicy ----------

## Ruch dekoracji: obrót wokół Y (spin [rad/s]) albo kołysanie na wodzie (bob [m], rock [rad]).
class Motion extends Node3D:
	var spin := 0.0
	var bob := 0.0
	var rock := 0.0
	var ph := 0.0
	var _t := 0.0
	var _y0 := 0.0

	func _ready() -> void:
		_y0 = position.y

	func _process(dt: float) -> void:
		_t += dt
		if spin != 0.0:
			rotate_object_local(Vector3.UP, spin * dt)
			return
		position.y = _y0 + sin(_t * 1.1 + ph) * bob
		rotation.x = sin(_t * 0.8 + ph * 1.7) * rock
		rotation.z = sin(_t * 0.95 + ph) * rock


## Dziób: romb (obrócony kwadrat o przekątnej w) rozciągnięty wzdłuż X o stretch, od y0 do y1.
static func _bow(parent: Node3D, at: Vector3, w: float, y0: float, y1: float, stretch: float, m: Material) -> void:
	var b := Node3D.new()
	b.position = at
	b.scale = Vector3(stretch, 1, 1)
	parent.add_child(b)
	box(b, Vector3(w * 0.7071, y1 - y0, w * 0.7071), Vector3(0, (y0 + y1) * 0.5, 0), m).rotation.y = PI / 4


# ---------- nabrzeże ----------

## Pachołek cumowniczy: żeliwny „grzybek” z żółtym wierzchem, płyta podstawy ze śrubami.
func k_bollard(e: Array) -> void:
	var n := root(e)
	var iron := mat(Color(0.09, 0.09, 0.1), 0.55, 0.45)
	solid(n, Vector3(0.44, 0.58, 0.44), Vector3(0, 0.29, 0), null)
	box(n, Vector3(0.56, 0.05, 0.56), Vector3(0, 0.025, 0), iron)
	cone(n, 0.19, 0.15, 0.42, Vector3(0, 0.26, 0), iron)
	cyl(n, 0.25, 0.08, Vector3(0, 0.5, 0), iron)
	cyl(n, 0.255, 0.035, Vector3(0, 0.555, 0), mat(YELLOW, 0.6))
	for k in 4:
		var a := k * PI / 2 + PI / 4
		cyl(n, 0.03, 0.04, Vector3(cos(a) * 0.22, 0.06, sin(a) * 0.22), iron)


## Krawędź nabrzeża wzdłuż lokalnego X od 0 do len (lokalne +Z = woda): jasny kapinos, stalowy narożnik,
## gumowe odbojnice co 8 m i drabinki {ladders = [x, …]} na ścianie nabrzeża, pas glonów przy wodzie.
## Żadnych barierek — krawędź ma być otwarta.
func k_quay_edge(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var ln: float = o.get("len", 70.0)
	box(n, Vector3(ln, 0.012, 0.42), Vector3(ln * 0.5, 0.004, -0.21), mat(Color(0.58, 0.58, 0.56), 0.85))
	box(n, Vector3(ln, 0.16, 0.05), Vector3(ln * 0.5, -0.07, 0.02), mat(Color(0.2, 0.2, 0.21), 0.5, 0.7))
	box(n, Vector3(ln, 0.3, 0.02), Vector3(ln * 0.5, WATER + 0.12, 0.01), mat(Color(0.07, 0.11, 0.07), 1.0))
	var rubber := mat(Color(0.05, 0.05, 0.05), 0.9)
	var x := 4.0
	while x < ln:
		box(n, Vector3(0.45, 1.3, 0.3), Vector3(x, -0.62, 0.15), rubber)
		x += 8.0
	var steel := mat(Color(0.85, 0.7, 0.1), 0.5, 0.5)
	for lx in o.get("ladders", []):
		for s in [-0.22, 0.22]:
			box(n, Vector3(0.05, 1.7, 0.05), Vector3(lx + s, -0.8, 0.06), steel)
		for k in 5:
			box(n, Vector3(0.44, 0.035, 0.035), Vector3(lx, -0.2 - k * 0.3, 0.08), steel)


## Koło ratunkowe na słupku przy krawędzi (tablica od strony lądu, lokalne −Z).
func k_lifebuoy(e: Array) -> void:
	var n := root(e)
	solid(n, Vector3(0.12, 1.45, 0.12), Vector3(0, 0.725, 0), mat(Color(0.85, 0.85, 0.83), 0.5, 0.3))
	box(n, Vector3(0.8, 0.85, 0.04), Vector3(0, 1.05, -0.08), mat(Color(0.85, 0.12, 0.08), 0.6))
	var tm := TorusMesh.new()
	tm.inner_radius = 0.2
	tm.outer_radius = 0.31
	tm.rings = 16
	tm.ring_segments = 8
	var ring := MeshInstance3D.new()
	ring.mesh = tm
	ring.material_override = mat(Color(1.0, 0.45, 0.05), 0.6)
	ring.position = Vector3(0, 1.1, -0.16)
	ring.rotation.x = PI / 2
	n.add_child(ring)
	for k in 4:
		var a := k * PI / 2 + PI / 4
		box(n, Vector3(0.07, 0.13, 0.13), Vector3(cos(a) * 0.255, 1.1 + sin(a) * 0.255, -0.16), mat(WHITE, 0.6)).rotation.z = a
	var l := label(n, "KOŁO RATUNKOWE", 0.06, Vector3(0, 0.71, -0.105), WHITE)
	l.rotation.y = PI
	l.shaded = true


## Suwnica bramowa na szynach wzdłuż lokalnego Z: podwozia i nogi poza torem (lokalne X = ±span/2),
## dźwigary nad torem z wysięgiem nad wodę (+X), wózek z kabiną i kontener wiszący na zawiesiu nad
## jezdnią {span = 6, len = 8 (rozstaw nóg wzdłuż szyn), trolley = położenie wózka na X, color = kontener}.
func k_gantry(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var span: float = o.get("span", 6.0)
	var gauge: float = o.get("len", 8.0)
	var tx: float = o.get("trolley", 0.0)
	var hx := span * 0.5
	var hz := gauge * 0.5
	var h := 9.4                       # spód dźwigarów
	var cant := 5.0                    # wysięg nad wodę
	var paint := mat(Color(0.95, 0.6, 0.08), 0.5, 0.3)
	var dark := mat(Color(0.16, 0.16, 0.18), 0.5, 0.6)
	var black := mat(Color(0.05, 0.05, 0.05), 0.6)
	var cream := mat(Color(0.86, 0.86, 0.82), 0.5, 0.2)
	for sx in [-1.0, 1.0]:
		solid(n, Vector3(0.8, 1.1, gauge + 1.6), Vector3(sx * hx, 0.55, 0), null)          # podwozie (kolizja)
		box(n, Vector3(0.8, 0.6, gauge + 1.6), Vector3(sx * hx, 0.8, 0), paint)
		for sz in [-1.0, 1.0]:
			box(n, Vector3(0.7, 0.32, 1.6), Vector3(sx * hx, 0.34, sz * (hz + 0.05)), dark)  # wózek jezdny
			for k in [-0.45, 0.45]:
				var w := cyl(n, 0.24, 0.16, Vector3(sx * hx, 0.24, sz * (hz + 0.05) + k), black)
				w.rotation.z = PI / 2
			for k in 4:                                                                      # pasy na czole
				box(n, Vector3(0.82, 0.15, 0.04), Vector3(sx * hx, 0.575 + k * 0.15, sz * (hz + 0.81)),
					mat(YELLOW if k % 2 == 0 else Color(0.05, 0.05, 0.05), 0.6))
			solid(n, Vector3(0.7, h - 1.1, 0.7), Vector3(sx * hx, 1.1 + (h - 1.1) * 0.5, sz * hz), paint)   # noga
		box(n, Vector3(0.8, 0.8, gauge + 0.7), Vector3(sx * hx, h + 0.4, 0), paint)          # belka górna ramy
		_beam(n, Vector3(sx * hx, 1.7, -hz + 0.35), Vector3(sx * hx, h - 0.2, hz - 0.35), 0.3, paint)   # zastrzał
	# dźwigary w poprzek toru, z wysięgiem nad wodę, pomost z barierką
	var x0 := -hx - 0.6
	var x1 := hx + cant
	for sz in [-1.4, 1.4]:
		box(n, Vector3(x1 - x0, 1.2, 0.55), Vector3((x0 + x1) * 0.5, h + 1.4, sz), paint)
		var rz: float = sz + signf(sz) * 0.3
		box(n, Vector3(x1 - x0, 0.04, 0.04), Vector3((x0 + x1) * 0.5, h + 2.55, rz), dark)
		var px := x0 + 0.2
		while px < x1:
			box(n, Vector3(0.04, 0.55, 0.04), Vector3(px, h + 2.28, rz), dark)
			px += 1.6
		sphere(n, 0.14, Vector3(x1 - 0.3, h + 2.15, sz), glow(Color(1.0, 0.55, 0.05), 4.0))
		var l := label(n, "SUWNICA S-2   40 t", 0.42, Vector3(0.5, h + 1.4, sz + signf(sz) * 0.28), Color(0.06, 0.06, 0.06))
		l.rotation.y = 0.0 if sz > 0 else PI
		l.shaded = true
	for x in [x0 + 0.45, x1 - 0.45]:
		box(n, Vector3(0.9, 1.2, 3.4), Vector3(x, h + 1.4, 0), paint)
	# wózek z kabiną operatora
	box(n, Vector3(2.6, 1.0, 3.4), Vector3(tx, h + 2.5, 0), cream)
	box(n, Vector3(2.62, 0.18, 3.42), Vector3(tx, h + 2.9, 0), paint)
	var cab := Vector3(tx + 0.4, h - 0.3, 2.3)
	box(n, Vector3(1.5, 1.7, 1.4), cab, cream)
	box(n, Vector3(1.52, 0.8, 1.42), cab + Vector3(0, 0.15, 0), mat(Color(0.15, 0.22, 0.28), 0.1, 0.3))
	box(n, Vector3(0.3, 1.3, 0.3), Vector3(cab.x, h + 1.15, 2.0), dark)
	# liny, zawiesie i kontener wiszący nad jezdnią
	var cy := 5.9
	var top := cy + CONTAINER.y
	for s1 in [-0.8, 0.8]:
		for s2 in [-2.2, 2.2]:
			_beam(n, Vector3(tx + s1, top + 0.3, s2), Vector3(tx + s1 * 0.6, h + 2.0, s2 * 0.45), 0.035, black)
	box(n, Vector3(2.5, 0.3, 6.1), Vector3(tx, top + 0.15, 0), mat(YELLOW, 0.5, 0.3))
	var cc: Color = o.get("color", Color(0.1, 0.35, 0.55))
	box(n, Vector3(CONTAINER.z, CONTAINER.y, CONTAINER.x), Vector3(tx, cy + CONTAINER.y * 0.5, 0), corrugated(cc))
	box(n, Vector3(CONTAINER.z - 0.1, CONTAINER.y - 0.1, 0.06), Vector3(tx, cy + CONTAINER.y * 0.5, CONTAINER.x * 0.5), mat(cc.darkened(0.35), 0.6, 0.4))
	# reflektor roboczy pod dźwigarem
	box(n, Vector3(0.7, 0.14, 0.45), Vector3(tx, h + 0.73, -0.9), dark)
	box(n, Vector3(0.6, 0.02, 0.36), Vector3(tx, h + 0.65, -0.9), glow(Color(1.0, 0.95, 0.85), 5.0))
	lamp(n, Vector3(tx, h - 0.4, -0.9), Color(1.0, 0.93, 0.82), 2.2, 14.0, true)
	# drabina na nodze od strony lądu
	var lad := mat(YELLOW, 0.5, 0.4)
	for s in [-0.22, 0.22]:
		box(n, Vector3(0.05, h - 1.3, 0.05), Vector3(-hx - 0.42, 1.1 + (h - 1.3) * 0.5, -hz + s), lad)
	for k in 13:
		box(n, Vector3(0.04, 0.04, 0.44), Vector3(-hx - 0.42, 1.6 + k * 0.6, -hz), lad)


## Tory wzdłuż lokalnego X od 0 do len {cross = [od, do]: odcinek na płycie przejazdu (próg), buf0 / buf1 =
## kozioł oporowy na początku / końcu}. Poza przejazdem: podsypka, podkłady (MultiMesh) i rdzawe szyny.
func k_rails(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var ln: float = o.get("len", 20.0)
	var cr: Array = o.get("cross", [])
	var c0: float = cr[0] if cr.size() == 2 else ln
	var c1: float = cr[1] if cr.size() == 2 else ln
	var g := 0.7175                    # połowa rozstawu szyn 1435 mm
	var steel := mat(Color(0.55, 0.53, 0.5), 0.3, 0.85)
	var rust := mat(Color(0.36, 0.22, 0.14), 0.9, 0.3)
	var sleepers := []
	for seg in [[0.0, c0], [c1, ln]]:
		var a: float = seg[0]
		var b: float = seg[1]
		if b - a < 0.1:
			continue
		var mid := (a + b) * 0.5
		box(n, Vector3(b - a, 0.03, 3.0), Vector3(mid, 0.015, 0), mat(Color(0.36, 0.34, 0.32), 1.0))
		var x := a + 0.3
		while x < b - 0.1:
			sleepers.append([Vector3(x, 0.03, 0), Vector3(0.24, 0.06, 2.5), Color(0.5, 0.49, 0.46)])
			x += 0.62
		for s in [-1.0, 1.0]:
			box(n, Vector3(b - a, 0.06, 0.07), Vector3(mid, 0.075, s * g), rust)
			box(n, Vector3(b - a, 0.012, 0.072), Vector3(mid, 0.111, s * g), steel)
	_boxes(n, sleepers, 0.95)
	if cr.size() == 2:
		var mid2 := (c0 + c1) * 0.5
		for s in [-1.0, 1.0]:
			box(n, Vector3(c1 - c0, 0.012, 0.072), Vector3(mid2, 0.104, s * g), steel)
			box(n, Vector3(c1 - c0, 0.004, 0.06), Vector3(mid2, 0.1005, s * (g - 0.075)), mat(Color(0.03, 0.03, 0.03), 0.9))
	if o.get("buf0", false):
		_buffer(n, 0.55, 0.0)
	if o.get("buf1", false):
		_buffer(n, ln - 0.55, PI)


## Kozioł oporowy na końcu toru (czołem w stronę lokalnego +X węzła po obrocie ang).
func _buffer(parent: Node3D, x: float, ang: float) -> void:
	var b := Node3D.new()
	b.position = Vector3(x, 0, 0)
	b.rotation.y = ang
	parent.add_child(b)
	var red := mat(Color(0.75, 0.1, 0.08), 0.6, 0.3)
	var dark := mat(Color(0.15, 0.15, 0.16), 0.6, 0.5)
	solid(b, Vector3(0.7, 1.15, 2.3), Vector3(0, 0.575, 0), null)
	for s in [-0.7175, 0.7175]:
		_beam(b, Vector3(-0.3, 0.12, s), Vector3(0.05, 0.85, s), 0.14, dark)
		_beam(b, Vector3(0.3, 0.12, s), Vector3(0.05, 0.85, s), 0.12, dark)
		var bf := cyl(b, 0.17, 0.3, Vector3(0.3, 0.85, s * 1.2), dark)
		bf.rotation.z = PI / 2
	box(b, Vector3(0.3, 0.38, 2.25), Vector3(0.05, 0.85, 0), red)
	for k in 3:
		box(b, Vector3(0.31, 0.39, 0.25), Vector3(0.05, 0.85, (k - 1) * 0.65), mat(WHITE, 0.6))
	box(b, Vector3(0.04, 0.5, 0.5), Vector3(0.1, 1.35, 0), mat(Color(0.85, 0.1, 0.08), 0.5))    # tarcza „koniec toru”
	box(b, Vector3(0.045, 0.1, 0.42), Vector3(0.1, 1.35, 0), mat(WHITE, 0.5))
	box(b, Vector3(0.05, 0.6, 0.05), Vector3(0.05, 0.95, 0), dark)


## Krzyż św. Andrzeja (czytelny od lokalnego +Z) z sygnalizatorem i tabliczką.
func k_andrew(e: Array) -> void:
	var n := root(e)
	solid(n, Vector3(0.1, 2.7, 0.1), Vector3(0, 1.35, 0), mat(Color(0.8, 0.8, 0.8), 0.5, 0.5))
	var red := mat(Color(0.8, 0.08, 0.06), 0.5)
	var white := mat(Color(0.95, 0.95, 0.93), 0.5)
	for a in [0.55, -0.55]:
		box(n, Vector3(1.25, 0.24, 0.02), Vector3(0, 2.3, 0.07), red).rotation.z = a
		box(n, Vector3(1.15, 0.15, 0.02), Vector3(0, 2.3, 0.085), white).rotation.z = a
	box(n, Vector3(0.72, 0.34, 0.06), Vector3(0, 1.62, 0.08), mat(Color(0.05, 0.05, 0.05), 0.5))
	for s in [-0.2, 0.2]:
		var lm := cyl(n, 0.1, 0.03, Vector3(s, 1.62, 0.12), mat(Color(0.4, 0.04, 0.03), 0.25))
		lm.rotation.x = PI / 2
	box(n, Vector3(0.95, 0.2, 0.02), Vector3(0, 1.3, 0.07), white)
	label(n, "UWAGA POCIĄG", 0.1, Vector3(0, 1.3, 0.085), Color(0.75, 0.05, 0.05)).shaded = true


## Wagon na torze wzdłuż lokalnego X: platforma z dwoma kontenerami 20' {colors} albo lokomotywa
## manewrowa {loco = true}. Koła stoją na główkach szyn.
func k_wagon(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var dark := mat(Color(0.12, 0.12, 0.13), 0.6, 0.5)
	var loco: bool = o.get("loco", false)
	var ln := 9.0 if loco else 13.9
	var deck := 1.25
	solid(n, Vector3(ln, 3.9, 2.7), Vector3(0, 1.95, 0), null)
	box(n, Vector3(ln, 0.3, 2.6), Vector3(0, deck - 0.15, 0), dark)
	var wheel := mat(Color(0.25, 0.22, 0.2), 0.5, 0.7)
	for bx in [-ln * 0.33, ln * 0.33]:
		box(n, Vector3(2.4, 0.35, 2.0), Vector3(bx, 0.68, 0), dark)
		for wx in [-0.85, 0.85]:
			for s in [-0.7175, 0.7175]:
				cyl(n, 0.42, 0.12, Vector3(bx + wx, 0.54, s), wheel).rotation.x = PI / 2
	for sx in [-1.0, 1.0]:
		for s in [-0.85, 0.85]:
			cyl(n, 0.17, 0.4, Vector3(sx * (ln * 0.5 + 0.2), deck - 0.25, s), dark).rotation.z = PI / 2
		box(n, Vector3(0.1, 0.4, 2.6), Vector3(sx * ln * 0.5, deck - 0.25, 0), mat(Color(0.7, 0.1, 0.08), 0.6))
	if not loco:
		var cols: Array = o.get("colors", [Color(0.62, 0.14, 0.1), Color(0.1, 0.3, 0.55)])
		for i in 2:
			var c: Color = cols[i]
			var dir := -1.0 if i == 0 else 1.0
			var cx := dir * (CONTAINER.x * 0.5 + 0.08)
			box(n, CONTAINER, Vector3(cx, deck + CONTAINER.y * 0.5, 0), corrugated(c))
			box(n, Vector3(0.06, CONTAINER.y - 0.1, CONTAINER.z - 0.1), Vector3(cx + dir * CONTAINER.x * 0.5, deck + CONTAINER.y * 0.5, 0),
				mat(c.darkened(0.35), 0.6, 0.4))
		for s in [-1.0, 1.0]:
			var l := label(n, "Sgs 31 51 4566 123-4", 0.11, Vector3(0, deck - 0.15, s * 1.31), WHITE)
			l.rotation.y = 0.0 if s > 0 else PI
			l.shaded = true
		return
	var body := mat(Color(0.9, 0.42, 0.08), 0.5, 0.2)
	var cream := mat(Color(0.92, 0.86, 0.7), 0.5)
	var glass := mat(Color(0.1, 0.13, 0.16), 0.1, 0.3)
	box(n, Vector3(5.0, 1.9, 1.9), Vector3(-1.6, deck + 0.95, 0), body)            # długa maska
	box(n, Vector3(5.02, 0.22, 1.92), Vector3(-1.6, deck + 0.5, 0), cream)
	for k in 4:
		box(n, Vector3(0.8, 0.9, 1.94), Vector3(-3.4 + k * 1.2, deck + 1.3, 0), mat(Color(0.25, 0.25, 0.27), 0.6, 0.4))   # żaluzje
	box(n, Vector3(2.3, 2.5, 2.6), Vector3(2.15, deck + 1.25, 0), body)             # kabina
	box(n, Vector3(2.32, 0.7, 2.62), Vector3(2.15, deck + 1.85, 0), glass)
	box(n, Vector3(2.5, 0.12, 2.75), Vector3(2.15, deck + 2.56, 0), dark)
	box(n, Vector3(0.9, 1.3, 1.6), Vector3(3.85, deck + 0.65, 0), body)             # krótka maska
	cyl(n, 0.12, 0.5, Vector3(-2.6, deck + 2.1, 0), dark)                           # wydech
	for s in [-1.25, 1.25]:
		box(n, Vector3(5.2, 0.04, 0.04), Vector3(-1.5, deck + 1.0, s), mat(YELLOW, 0.5))   # poręcze
	for p in [Vector3(4.33, deck + 0.95, 0.55), Vector3(4.33, deck + 0.95, -0.55), Vector3(-4.12, deck + 1.6, 0.0)]:
		sphere(n, 0.09, p, glow(Color(1.0, 0.95, 0.8), 3.0))
	for s in [-1.0, 1.0]:
		var l := label(n, "LOK 07", 0.3, Vector3(2.15, deck + 1.0, s * 1.315), cream.albedo_color)
		l.rotation.y = 0.0 if s > 0 else PI
		l.shaded = true


## Otwarte drzwi dolnego kontenera stosu; (x, z) = środek czoła, lokalne +X = na zewnątrz {color}:
## skrzydła odchylone o 270° i przylegające do boków, ciemne wnętrze, ładunek widoczny w otworze.
func k_open_doors(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var c: Color = o.get("color", Color(0.1, 0.3, 0.55))
	var h := CONTAINER.y
	var w := CONTAINER.z
	box(n, Vector3(0.04, h - 0.14, w - 0.16), Vector3(0.09, h * 0.5, 0), mat(Color(0.025, 0.025, 0.03), 1.0))
	var leaf := mat(c.darkened(0.3), 0.6, 0.4)
	var bar := mat(Color(0.2, 0.2, 0.2), 0.4, 0.8)
	for s in [-1.0, 1.0]:
		box(n, Vector3(1.2, h - 0.1, 0.05), Vector3(-0.62, h * 0.5, s * (w * 0.5 + 0.03)), leaf)
		for bx in [-0.35, -0.85]:
			box(n, Vector3(0.04, h - 0.3, 0.04), Vector3(bx, h * 0.5, s * (w * 0.5 + 0.07)), bar)
	# ładunek w otworze: kartony na palecie, owinięta paleta, worki
	box(n, Vector3(0.05, 0.14, 1.0), Vector3(0.12, 0.07, -0.55), mat(WOOD, 0.9))
	box(n, Vector3(0.05, 1.1, 0.95), Vector3(0.13, 0.69, -0.55), mat(CARTON.darkened(0.35), 0.85))
	box(n, Vector3(0.05, 0.06, 0.96), Vector3(0.14, 0.69, -0.55), mat(CARTON.darkened(0.55), 0.85))
	box(n, Vector3(0.05, 1.5, 0.95), Vector3(0.12, 0.75, 0.55), mat(Color(0.5, 0.53, 0.56), 0.3))
	box(n, Vector3(0.05, 0.5, 0.9), Vector3(0.13, 1.6, -0.5), mat(Color(0.55, 0.5, 0.4), 0.9))


# ---------- magazyn ----------

## Wrota w ścianie wzdłuż lokalnego X (lokalne +Z = na zewnątrz) {w, h = 4,2, text, inner}: nadproże do
## wierzchu ściany, zwinięta roleta, ościeżnice w żółto-czarne pasy, tablice, lampa ostrzegawcza.
func k_gate(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var w: float = o.get("w", 6.0)
	var gh: float = o.get("h", 4.2)
	var dark := mat(Color(0.2, 0.21, 0.23), 0.5, 0.6)
	box(n, Vector3(w + 0.15, WH - gh, 0.15), Vector3(0, (WH + gh) * 0.5, 0), corrugated(WALL))
	box(n, Vector3(w + 0.5, 0.18, 0.3), Vector3(0, gh + 0.09, 0), dark)
	cyl(n, 0.32, w + 0.2, Vector3(0, gh + 0.5, -0.42), mat(Color(0.6, 0.62, 0.64), 0.4, 0.6)).rotation.z = PI / 2
	for k in 3:
		box(n, Vector3(w - 0.05, 0.14, 0.04), Vector3(0, gh - 0.05 - k * 0.15, -0.2), mat(Color(0.7, 0.72, 0.74), 0.45, 0.5))
	for s in [-1.0, 1.0]:
		box(n, Vector3(0.2, gh, 0.32), Vector3(s * (w * 0.5 + 0.1), gh * 0.5, 0), dark)
		for k in 6:
			box(n, Vector3(0.22, 0.2, 0.34), Vector3(s * (w * 0.5 + 0.1), 0.1 + k * 0.2, 0), mat(YELLOW if k % 2 == 0 else Color(0.05, 0.05, 0.05), 0.6))
	if o.has("text"):
		box(n, Vector3(4.4, 0.85, 0.05), Vector3(0, gh + 1.05, 0.11), mat(Color(0.08, 0.22, 0.5), 0.5))
		label(n, o.text, 0.42, Vector3(0, gh + 1.05, 0.14), Color.WHITE).shaded = true
	if o.has("inner"):
		box(n, Vector3(2.6, 0.5, 0.05), Vector3(0, gh + 1.0, -0.11), mat(Color(0.1, 0.5, 0.2), 0.5))
		var li := label(n, o.inner, 0.26, Vector3(0, gh + 1.0, -0.14), Color.WHITE)
		li.rotation.y = PI
		li.shaded = true
	box(n, Vector3(0.18, 0.12, 0.14), Vector3(w * 0.5 + 0.45, gh + 0.1, 0.14), dark)
	sphere(n, 0.11, Vector3(w * 0.5 + 0.45, gh + 0.25, 0.14), glow(Color(1.0, 0.55, 0.05), 4.0))


## Dach hali nad prostokątem w × d (środek w węźle, lokalne X wzdłuż w): blacha z okapem, świetliki,
## kratownice co 5,5 m, lampy wiszące {lamps = [[x, z, cień?], …]} (lokalnie).
func k_roof(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var w: float = o.get("w", 20.0)
	var d: float = o.get("d", 20.0)
	box(n, Vector3(w + 0.6, 0.25, d + 0.6), Vector3(0, WH + 0.125, 0), mat(Color(0.42, 0.44, 0.47), 0.8, 0.3))
	var steel := Color(0.3, 0.32, 0.35)
	var parts := []
	var x := -w * 0.5 + 2.75
	while x < w * 0.5:
		parts.append([Vector3(x, WH - 0.08, 0), Vector3(0.16, 0.16, d), steel])
		parts.append([Vector3(x, WH - 1.0, 0), Vector3(0.16, 0.16, d - 0.4), steel])
		var z := -d * 0.5 + 1.25
		while z < d * 0.5:
			parts.append([Vector3(x, WH - 0.54, z), Vector3(0.08, 0.84, 0.08), steel])
			z += 2.5
		x += 5.5
	_boxes(n, parts, 0.6, 0.5, false)
	for i in 3:
		var z := -d * 0.5 + (i + 1) * d / 4.0
		box(n, Vector3(w - 3.0, 0.03, 1.4), Vector3(0, WH - 0.01, z), glow(Color(0.82, 0.88, 0.95), 0.8))
		box(n, Vector3(w - 2.8, 0.35, 1.6), Vector3(0, WH + 0.4, z), mat(Color(0.55, 0.62, 0.7), 0.15, 0.3))
	var shade := mat(Color(0.25, 0.27, 0.3), 0.5, 0.6)
	for lp in o.get("lamps", []):
		var p := Vector3(lp[0], WH - 1.3, lp[1])
		# klosz i przewód bez cienia — inaczej lampa tuż pod kloszem rzuca na dach wielką ciemną plamę
		cone(n, 0.45, 0.12, 0.35, p, shade).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cyl(n, 0.4, 0.02, p - Vector3(0, 0.18, 0), glow(Color(1.0, 0.95, 0.85), 5.0))
		_beam(n, p + Vector3(0, 0.17, 0), Vector3(lp[0], WH - 0.1, lp[1]), 0.02, shade).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lamp(n, p - Vector3(0, 0.4, 0), Color(1.0, 0.93, 0.82), 1.6, 13.0, lp[2])


## Regał paletowy wzdłuż lokalnego X {len, depth = 1,1 (2,2 = podwójny), name}: niebieskie ramy co ~2,7 m,
## pomarańczowe belki na 3 poziomach, palety z towarem (kartony, folia, beczki, worki, skrzynie).
## Ramy i towar to MultiMesh (kilka wywołań rysowania na regał), towar bez cieni (i tak jest pod dachem).
func k_rack(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var ln: float = o.get("len", 10.8)
	var d: float = o.get("depth", 1.1)
	var hh := 4.6
	solid(n, Vector3(ln, hh, d), Vector3(0, hh * 0.5, 0), null)
	var blue := Color(0.12, 0.3, 0.62)
	var two_deep := d > 1.5
	var bays := maxi(1, roundi(ln / 2.7))
	var bw := ln / bays
	var faces: Array = [-d * 0.5 + 0.04, d * 0.5 - 0.04]
	if two_deep:
		faces.append_array([-0.08, 0.08])
	var frames := []
	for i in bays + 1:
		var x := -ln * 0.5 + i * bw
		for z in faces:
			frames.append([Vector3(x, hh * 0.5, z), Vector3(0.08, hh, 0.08), blue])
		for y in [0.4, 2.2, 4.0]:
			frames.append([Vector3(x, y, 0), Vector3(0.04, 0.04, d), blue])
	for lv in [1.5, 3.0, 4.5]:
		for z in faces:
			frames.append([Vector3(0, lv, z), Vector3(ln, 0.12, 0.06), Color(0.95, 0.45, 0.08)])
	_boxes(n, frames, 0.5, 0.4)
	var rows: Array = [-d * 0.25, d * 0.25] if two_deep else [0.0]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(float(e[1]) * 31.0 + float(e[2]) * 17.0))
	var goods := []
	var drums := []
	var drum_cols := [Color(0.15, 0.3, 0.65), Color(0.7, 0.12, 0.08), Color(0.2, 0.45, 0.2), Color(0.85, 0.6, 0.1)]
	for lv in [0.0, 1.56, 3.06]:
		for i in bays:
			for p in 2:
				for rz in rows:
					if rng.randf() < 0.18:
						continue
					var px: float = -ln * 0.5 + (i + 0.27 + p * 0.46) * bw
					var y0: float = lv + 0.14
					var z0: float = rz
					goods.append([Vector3(px, lv + 0.07, z0), Vector3(0.8, 0.14, 1.0), WOOD])
					var ht := rng.randf_range(0.7, 1.15)
					match rng.randi() % 5:
						0:      # kartony z taśmą
							var c := CARTON.lightened(rng.randf() * 0.12)
							goods.append([Vector3(px, y0 + ht * 0.5, z0), Vector3(0.76, ht, 0.96), c])
							goods.append([Vector3(px, y0 + ht * 0.5, z0), Vector3(0.77, 0.06, 0.97), c.darkened(0.25)])
						1:      # owinięte folią
							goods.append([Vector3(px, y0 + ht * 0.5, z0), Vector3(0.78, ht, 0.99), Color(0.78, 0.82, 0.86)])
						2:      # beczki 2 × 2
							var dc: Color = drum_cols[rng.randi() % drum_cols.size()]
							for bx in [-0.2, 0.2]:
								for bz in [-0.24, 0.24]:
									drums.append([Vector3(px + bx, y0 + 0.43, z0 + bz), Vector3(0.38, 0.86, 0.38), dc])
						3:      # worki w dwóch warstwach
							goods.append([Vector3(px, y0 + 0.2, z0), Vector3(0.74, 0.38, 0.94), Color(0.86, 0.8, 0.64)])
							goods.append([Vector3(px + 0.02, y0 + 0.56, z0 - 0.03), Vector3(0.7, 0.34, 0.9), Color(0.82, 0.77, 0.6)])
						_:      # skrzynia
							goods.append([Vector3(px, y0 + ht * 0.45, z0), Vector3(0.78, ht * 0.9, 0.98), WOOD.darkened(0.2)])
							goods.append([Vector3(px, y0 + ht * 0.45, z0), Vector3(0.8, 0.08, 1.0), WOOD.darkened(0.4)])
	_boxes(n, goods, 0.75, 0.0, false)
	_boxes(n, drums, 0.45, 0.4, false, true)
	if o.has("name"):
		for s in [-1.0, 1.0]:
			var t := Node3D.new()
			t.position = Vector3(s * (ln * 0.5 + 0.05), 4.25, 0)
			t.rotation.y = s * PI / 2
			n.add_child(t)
			box(t, Vector3(0.6, 0.5, 0.02), Vector3.ZERO, mat(Color(0.95, 0.95, 0.93), 0.5))
			label(t, "REGAŁ %s" % o.name, 0.12, Vector3(0, 0, 0.015), Color(0.08, 0.15, 0.4)).shaded = true


## Wózek widłowy (przód z masztem i widłami na lokalne +X) {lift = wysokość wideł, load, color}.
func k_forklift(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var paint := mat(o.get("color", Color(0.95, 0.68, 0.08)), 0.45, 0.2)
	var dark := mat(Color(0.12, 0.12, 0.13), 0.6, 0.4)
	var tyre := mat(Color(0.05, 0.05, 0.05), 0.9)
	var lift: float = o.get("lift", 0.15)
	solid(n, Vector3(2.2, 2.15, 1.16), Vector3(-0.15, 1.075, 0), null)
	box(n, Vector3(1.7, 0.55, 1.1), Vector3(-0.1, 0.55, 0), paint)
	box(n, Vector3(0.55, 0.85, 1.12), Vector3(-0.95, 0.72, 0), dark)                 # przeciwwaga
	box(n, Vector3(0.6, 0.3, 1.0), Vector3(-0.75, 1.0, 0), paint)
	for wv in [[0.55, 0.3], [-0.85, 0.24]]:
		for s in [-0.5, 0.5]:
			cyl(n, wv[1], 0.22, Vector3(wv[0], wv[1], s), tyre).rotation.x = PI / 2
	box(n, Vector3(0.5, 0.12, 0.5), Vector3(-0.4, 0.9, 0), dark)                      # fotel
	box(n, Vector3(0.1, 0.5, 0.5), Vector3(-0.65, 1.15, 0), dark)
	box(n, Vector3(0.06, 0.5, 0.06), Vector3(0.15, 1.05, 0), dark).rotation.z = 0.35
	cyl(n, 0.17, 0.03, Vector3(0.05, 1.3, 0), dark).rotation.z = 0.6
	for px in [-0.75, 0.55]:                                                         # dach ochronny
		for s in [-0.5, 0.5]:
			box(n, Vector3(0.06, 1.25, 0.06), Vector3(px, 1.45, s), dark)
	box(n, Vector3(1.4, 0.05, 1.1), Vector3(-0.1, 2.1, 0), dark)
	for k in 4:
		box(n, Vector3(0.04, 0.06, 1.0), Vector3(-0.65 + k * 0.33, 2.15, 0), dark)
	sphere(n, 0.08, Vector3(-0.6, 2.2, 0), glow(Color(1.0, 0.55, 0.05), 3.0))        # kogut
	for s in [-0.33, 0.33]:                                                          # maszt
		box(n, Vector3(0.08, 2.3, 0.1), Vector3(0.98, 1.2, s), dark)
	box(n, Vector3(0.06, 0.5, 0.8), Vector3(1.05, lift + 0.3, 0), dark)
	for s in [-0.28, 0.28]:
		box(n, Vector3(1.1, 0.05, 0.12), Vector3(1.62, lift + 0.03, s), dark)
	if o.get("load", false):
		box(n, Vector3(1.0, 0.14, 1.2), Vector3(1.62, lift + 0.13, 0), mat(WOOD, 0.9))
		box(n, Vector3(0.95, 0.8, 1.1), Vector3(1.62, lift + 0.6, 0), mat(CARTON, 0.85))
		box(n, Vector3(0.96, 0.06, 1.11), Vector3(1.62, lift + 0.6, 0), mat(CARTON.darkened(0.25), 0.85))
	for s in [-0.42, 0.42]:
		box(n, Vector3(0.04, 0.1, 0.14), Vector3(-1.23, 0.95, s), glow(Color(1.0, 0.1, 0.05), 1.5))
	label(n, "2,5 t", 0.14, Vector3(-0.95, 0.75, 0.565), Color(0.95, 0.95, 0.9)).shaded = true


# ---------- plac i droga ----------

## Kontener biurowy (lokalne +Z = front z oknami i drzwiami): ciepłe światło w oknach, drzwi ze
## schodkiem, klimatyzator, tablica, lampka nad wejściem.
func k_office(e: Array) -> void:
	var n := root(e)
	var y0 := 0.12
	solid(n, Vector3(CONTAINER.x, CONTAINER.y + y0, CONTAINER.z), Vector3(0, (CONTAINER.y + y0) * 0.5, 0), null)
	box(n, CONTAINER, Vector3(0, y0 + CONTAINER.y * 0.5, 0), corrugated(Color(0.86, 0.87, 0.84)))
	for x in [-2.8, 2.8]:
		for z in [-1.0, 1.0]:
			box(n, Vector3(0.3, y0, 0.3), Vector3(x, y0 * 0.5, z), mat(Color(0.5, 0.5, 0.48), 0.9))
	var frame := mat(Color(0.95, 0.95, 0.95), 0.5)
	var fz := CONTAINER.z * 0.5
	for x in [-1.9, -0.2]:
		box(n, Vector3(1.3, 1.0, 0.05), Vector3(x, 1.65, fz), frame)
		box(n, Vector3(1.15, 0.85, 0.03), Vector3(x, 1.65, fz + 0.02), glow(Color(1.0, 0.82, 0.55), 0.7))
		box(n, Vector3(1.15, 0.04, 0.04), Vector3(x, 1.65, fz + 0.04), frame)
		box(n, Vector3(0.04, 0.85, 0.04), Vector3(x, 1.65, fz + 0.04), frame)
	box(n, Vector3(0.95, 2.05, 0.05), Vector3(1.85, y0 + 1.03, fz), mat(Color(0.35, 0.4, 0.45), 0.5, 0.4))
	box(n, Vector3(0.12, 0.04, 0.06), Vector3(1.5, 1.15, fz + 0.05), mat(Color(0.75, 0.75, 0.75), 0.3, 0.8))
	box(n, Vector3(1.1, 0.12, 0.4), Vector3(1.85, 0.06, fz + 0.2), mat(Color(0.4, 0.42, 0.44), 0.6, 0.6))   # schodek
	box(n, Vector3(0.8, 0.5, 0.3), Vector3(-2.6, 2.15, fz + 0.15), mat(Color(0.85, 0.85, 0.83), 0.5))       # klimatyzator
	cyl(n, 0.18, 0.02, Vector3(-2.6, 2.15, fz + 0.31), mat(Color(0.2, 0.2, 0.2), 0.6)).rotation.x = PI / 2
	box(n, Vector3(2.4, 0.38, 0.03), Vector3(-1.0, 2.45, fz + 0.01), mat(Color(0.08, 0.25, 0.55), 0.5))
	label(n, "BIURO NABRZEŻA", 0.17, Vector3(-1.0, 2.45, fz + 0.03), Color.WHITE).shaded = true
	box(n, Vector3(0.25, 0.1, 0.18), Vector3(1.85, 2.4, fz + 0.09), glow(Color(1.0, 0.85, 0.6), 2.5))
	lamp(n, Vector3(1.85, 2.2, fz + 0.6), Color(1.0, 0.82, 0.55), 0.6, 4.5, false)
	box(n, Vector3(0.05, 1.6, 0.05), Vector3(-2.7, y0 + CONTAINER.y + 0.8, -0.8), mat(Color(0.5, 0.5, 0.5), 0.5, 0.6))   # antena


## Maszt oświetleniowy {h = 18, energy, range}: zwężający się słup, wieniec reflektorów, lampka na szczycie.
func k_mast(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var h: float = o.get("h", 18.0)
	var galv := mat(Color(0.6, 0.62, 0.64), 0.45, 0.7)
	box(n, Vector3(1.0, 0.35, 1.0), Vector3(0, 0.175, 0), mat(Color(0.55, 0.55, 0.53), 0.9))
	solid(n, Vector3(0.5, h, 0.5), Vector3(0, h * 0.5, 0), null)
	cone(n, 0.25, 0.13, h, Vector3(0, h * 0.5, 0), galv)
	cyl(n, 1.3, 0.12, Vector3(0, h, 0), galv)
	var c := Color(1.0, 0.86, 0.62)
	for k in 6:
		var a := k * TAU / 6.0
		var f := Node3D.new()
		f.position = Vector3(cos(a) * 1.05, h + 0.3, sin(a) * 1.05)
		f.rotation = Vector3(0.45, PI / 2 - a, 0)
		n.add_child(f)
		box(f, Vector3(0.55, 0.4, 0.18), Vector3.ZERO, mat(Color(0.25, 0.26, 0.28), 0.5, 0.5))
		box(f, Vector3(0.48, 0.32, 0.02), Vector3(0, 0, 0.1), glow(c, 5.0))
	sphere(n, 0.12, Vector3(0, h + 0.75, 0), glow(Color(1.0, 0.1, 0.05), 4.0))
	lamp(n, Vector3(0, h - 0.8, 0), c, o.get("energy", 3.0), o.get("range", 30.0), false)


## Drogowskaz nad jezdnią: dwa słupy poza torem (lokalne X = ±w/2), tablica czytelna z obu stron {w, text}.
func k_portal_sign(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var w: float = o.get("w", 6.0)
	var grey := mat(Color(0.6, 0.62, 0.64), 0.45, 0.7)
	for s in [-1.0, 1.0]:
		solid(n, Vector3(0.22, 5.6, 0.22), Vector3(s * w * 0.5, 2.8, 0), grey)
		box(n, Vector3(0.5, 0.1, 0.5), Vector3(s * w * 0.5, 0.05, 0), grey)
		box(n, Vector3(0.04, 0.35, 0.04), Vector3(s * 1.6, 5.3, 0), grey)
	box(n, Vector3(w + 0.3, 0.18, 0.18), Vector3(0, 5.55, 0), grey)
	var bw := minf(w - 0.6, 4.2)
	box(n, Vector3(bw + 0.1, 1.3, 0.05), Vector3(0, 4.5, 0), mat(Color.WHITE, 0.5))
	box(n, Vector3(bw, 1.2, 0.06), Vector3(0, 4.5, 0), mat(Color(0.08, 0.25, 0.6), 0.5))
	for s in [1.0, -1.0]:
		var l := label(n, o.get("text", ""), 0.24, Vector3(0, 4.5, s * 0.035), Color.WHITE)
		l.rotation.y = 0.0 if s > 0 else PI
		l.shaded = true


# ---------- woda i tło ----------

## Holownik przy nabrzeżu (lokalne X = od rufy do dziobu, lokalne +Z = burta od nabrzeża): czarny kadłub
## z czerwonym pasem, opony na burtach, nadbudówka ze sterówką, komin, obracający się radar, cumy do
## pachołków {name, ropes = [[x polera (lokalnie), pachołek (świat, Vector2)], …]}. Bez kolizji.
func k_tug(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var hull := mat(Color(0.07, 0.08, 0.09), 0.6, 0.3)
	var red := mat(Color(0.72, 0.1, 0.07), 0.6)
	var white := mat(Color(0.92, 0.92, 0.9), 0.5)
	var black := mat(Color(0.04, 0.04, 0.04), 0.7)
	var glass := mat(Color(0.1, 0.13, 0.16), 0.1, 0.3)
	var deck := 0.55
	var bw := 4.6
	var y0 := WATER - 0.6
	box(n, Vector3(10.0, deck - y0, bw), Vector3(-0.5, (deck + y0) * 0.5, 0), hull)
	_bow(n, Vector3(4.5, 0, 0), bw, y0, deck + 0.25, 1.25, hull)
	var st := Node3D.new()
	st.position = Vector3(-5.5, 0, 0)
	st.scale = Vector3(0.5, 1, 1)
	n.add_child(st)
	cyl(st, bw * 0.5, deck - y0, Vector3(0, (deck + y0) * 0.5, 0), hull)
	box(n, Vector3(10.02, 0.26, bw + 0.06), Vector3(-0.5, WATER + 0.2, 0), red)
	cyl(st, bw * 0.5 + 0.04, 0.26, Vector3(0, WATER + 0.2, 0), red)
	for s in [-1.0, 1.0]:
		box(n, Vector3(10.0, 0.4, 0.08), Vector3(-0.5, deck + 0.2, s * (bw * 0.5 - 0.04)), hull)      # nadburcie
		box(n, Vector3(10.0, 0.05, 0.14), Vector3(-0.5, deck + 0.42, s * (bw * 0.5 - 0.04)), red)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.18
	tm.outer_radius = 0.36
	tm.rings = 12
	tm.ring_segments = 6
	for x in [-4.0, -2.0, 0.0, 2.0, 4.0]:
		for s in [-1.0, 1.0]:
			var t := MeshInstance3D.new()
			t.mesh = tm
			t.material_override = black
			t.position = Vector3(x, deck - 0.35, s * (bw * 0.5 + 0.1))
			t.rotation.x = PI / 2
			n.add_child(t)
	box(n, Vector3(4.2, 1.5, 3.4), Vector3(0.6, deck + 0.75, 0), white)                 # nadbudówka
	for x in [-0.8, 0.2, 1.2]:
		for s in [-1.0, 1.0]:
			cyl(n, 0.15, 0.03, Vector3(x, deck + 0.9, s * 1.71), glass).rotation.x = PI / 2
	box(n, Vector3(2.4, 1.2, 3.0), Vector3(1.3, deck + 2.1, 0), white)                  # sterówka
	box(n, Vector3(2.42, 0.5, 3.02), Vector3(1.3, deck + 2.3, 0), glass)
	box(n, Vector3(2.7, 0.1, 3.3), Vector3(1.3, deck + 2.75, 0), mat(Color(0.2, 0.2, 0.22), 0.6))
	box(n, Vector3(1.0, 1.6, 1.2), Vector3(-0.9, deck + 2.3, 0), red)                   # komin
	box(n, Vector3(1.02, 0.3, 1.22), Vector3(-0.9, deck + 3.0, 0), black)
	box(n, Vector3(0.1, 1.6, 0.1), Vector3(1.6, deck + 3.6, 0), white)                  # maszt
	var radar := Motion.new()
	radar.spin = 1.6
	radar.position = Vector3(1.6, deck + 3.15, 0)
	n.add_child(radar)
	box(radar, Vector3(0.12, 0.08, 1.1), Vector3.ZERO, black)
	sphere(n, 0.07, Vector3(1.6, deck + 4.45, 0), glow(Color(1, 1, 0.9), 4.0))
	sphere(n, 0.06, Vector3(2.0, deck + 2.6, 1.55), glow(Color(0.1, 1.0, 0.3), 3.0))
	sphere(n, 0.06, Vector3(2.0, deck + 2.6, -1.55), glow(Color(1.0, 0.1, 0.05), 3.0))
	for bx in [-4.6, 4.2]:                                                              # polery
		for s in [-0.25, 0.25]:
			cyl(n, 0.12, 0.45, Vector3(bx, deck + 0.22, s), black)
	box(n, Vector3(0.3, 0.6, 0.3), Vector3(-3.2, deck + 0.3, 0), mat(Color(0.3, 0.3, 0.32), 0.5, 0.6))   # hak holowniczy
	var nm: String = o.get("name", "HERKULES")
	for s in [-1.0, 1.0]:
		var l := label(n, nm, 0.32, Vector3(3.2, deck - 0.3, s * (bw * 0.5 + 0.03)), WHITE)
		l.rotation.y = 0.0 if s > 0 else PI
		l.shaded = true
	var rope := mat(Color(0.85, 0.78, 0.55), 0.9)
	for r in o.get("ropes", []):
		var a := Vector3(r[0], deck + 0.4, 0.25)
		var lp: Vector2 = (r[1] - Vector2(e[1], e[2])).rotated(-deg_to_rad(e[3]))
		var b := Vector3(lp.x, 0.5, lp.y)
		var mid := (a + b) * 0.5 - Vector3(0, 0.3, 0)
		_beam(n, a, mid, 0.05, rope)
		_beam(n, mid, b, 0.05, rope)


## Statek z kontenerami przy przeciwległym nabrzeżu (lokalne X = od rufy do dziobu, +Z = burta przy
## nabrzeżu z cumami, −Z = burta widoczna z toru) {name, port}. Bez kolizji.
func k_ship(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var hull := mat(Color(0.1, 0.18, 0.32), 0.55, 0.25)
	var red := mat(Color(0.5, 0.1, 0.07), 0.7)
	var white := mat(Color(0.9, 0.9, 0.88), 0.6)
	var glass := mat(Color(0.08, 0.1, 0.13), 0.1, 0.4)
	var dark := mat(Color(0.12, 0.12, 0.13), 0.6, 0.5)
	var bw := 11.0
	var y0 := WATER - 1.5
	var dk := 5.2
	box(n, Vector3(50.0, dk - y0, bw), Vector3(0, (dk + y0) * 0.5, 0), hull)
	box(n, Vector3(50.04, 1.1, bw + 0.08), Vector3(0, WATER + 0.3, 0), red)         # czerwony pas (pod balastem)
	_bow(n, Vector3(25, 0, 0), bw, y0, dk + 0.8, 1.3, hull)
	_bow(n, Vector3(25, 0, 0), bw + 0.12, WATER - 0.25, WATER + 0.85, 1.3, red)
	var st := Node3D.new()
	st.position = Vector3(-25, 0, 0)
	st.scale = Vector3(0.42, 1, 1)
	n.add_child(st)
	cyl(st, bw * 0.5, dk - y0, Vector3(0, (dk + y0) * 0.5, 0), hull)
	cyl(st, bw * 0.5 + 0.06, 1.1, Vector3(0, WATER + 0.3, 0), red)
	box(n, Vector3(50.0, 0.12, bw - 0.4), Vector3(0, dk + 0.06, 0), mat(Color(0.42, 0.16, 0.12), 0.8))
	# nadbudówka na rufie, mostek ze skrzydłami, komin, maszty
	box(n, Vector3(9.0, 8.6, 10.0), Vector3(-19.5, dk + 4.3, 0), white)
	for k in 4:
		box(n, Vector3(9.04, 0.55, 10.04), Vector3(-19.5, dk + 1.3 + k * 2.1, 0), glass)
	box(n, Vector3(6.5, 2.4, 13.4), Vector3(-18.0, dk + 9.8, 0), white)
	box(n, Vector3(6.54, 0.9, 13.44), Vector3(-18.0, dk + 10.1, 0), glass)
	box(n, Vector3(7.0, 0.2, 13.8), Vector3(-18.0, dk + 11.1, 0), white)
	box(n, Vector3(3.6, 5.5, 3.2), Vector3(-23.0, dk + 11.3, 0), white)
	box(n, Vector3(3.62, 1.2, 3.22), Vector3(-23.0, dk + 12.2, 0), mat(Color(0.1, 0.35, 0.65), 0.5))
	box(n, Vector3(3.62, 0.8, 3.22), Vector3(-23.0, dk + 13.7, 0), mat(Color(0.05, 0.05, 0.05), 0.6))
	box(n, Vector3(0.3, 5.0, 0.3), Vector3(-17.5, dk + 13.6, 0), white)
	box(n, Vector3(0.2, 0.2, 4.0), Vector3(-17.5, dk + 15.0, 0), white)
	var radar := Motion.new()
	radar.spin = 1.2
	radar.position = Vector3(-17.5, dk + 12.6, 0)
	n.add_child(radar)
	box(radar, Vector3(0.2, 0.15, 2.6), Vector3.ZERO, dark)
	sphere(n, 0.15, Vector3(-17.5, dk + 16.2, 0), glow(Color(1, 1, 0.9), 5.0))
	sphere(n, 0.15, Vector3(-15.0, dk + 10.1, 6.75), glow(Color(0.1, 1.0, 0.3), 4.0))   # prawa burta zielona
	sphere(n, 0.15, Vector3(-15.0, dk + 10.1, -6.75), glow(Color(1.0, 0.1, 0.05), 4.0)) # lewa czerwona
	box(n, Vector3(0.3, 7.0, 0.3), Vector3(27.5, dk + 3.5, 0), white)
	sphere(n, 0.15, Vector3(27.5, dk + 7.1, 0), glow(Color(1, 1, 0.9), 5.0))
	box(n, Vector3(5.0, 1.6, bw - 1.0), Vector3(26.0, dk + 0.8, 0), hull)              # bak na dziobie
	# kontenery: 6 sekcji × 4 rzędy × 1–3 warstwy, pokrywy luków
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var cols := CONTAINER_COLORS + [Color(0.85, 0.85, 0.82), Color(0.35, 0.36, 0.38), Color(0.55, 0.25, 0.15)]
	var items := []
	for bay in 6:
		var bx := -12.0 + bay * 6.3
		items.append([Vector3(bx, dk + 0.3, 0), Vector3(6.1, 0.5, 10.0), Color(0.3, 0.32, 0.3)])
		for row in 4:
			for t in rng.randi_range(1, 3):
				items.append([Vector3(bx, dk + 0.55 + CONTAINER.y * (t + 0.5), (row - 1.5) * 2.46), Vector3(6.0, CONTAINER.y - 0.03, 2.42),
					cols[rng.randi() % cols.size()]])
	_boxes(n, items, 0.6, 0.3)
	# nazwa na burtach i rufie, kluzy kotwiczne, znaki zanurzenia
	var nm: String = o.get("name", "SZAFA GDAŃSKA")
	for s in [-1.0, 1.0]:
		var l := label(n, nm, 1.3, Vector3(14.0, dk - 1.4, s * (bw * 0.5 + 0.05)), Color(0.92, 0.92, 0.9))
		l.rotation.y = 0.0 if s > 0 else PI
		l.shaded = true
		box(n, Vector3(1.0, 1.0, 0.1), Vector3(23.0, dk - 1.2, s * (bw * 0.5 + 0.02)), dark)
		for k in 5:
			box(n, Vector3(0.5, 0.08, 0.04), Vector3(22.0, WATER + 0.9 + k * 0.6, s * (bw * 0.5 + 0.03)), mat(WHITE, 0.6))
	var sl := label(n, nm + "\n" + str(o.get("port", "SZCZECIN")), 0.8, Vector3(-27.4, dk - 2.2, 0), Color(0.92, 0.92, 0.9))
	sl.rotation.y = -PI / 2
	sl.shaded = true
	# cumy do przeciwległego nabrzeża
	var rope := mat(Color(0.8, 0.75, 0.6), 0.9)
	for r in [[22.0, 31.0], [-24.0, -33.0], [8.0, 14.0], [-12.0, -18.0]]:
		var a := Vector3(r[0], dk + 0.6, bw * 0.5 - 0.3)
		var b := Vector3(r[1], 1.0, bw * 0.5 + 1.1)
		var mid := (a + b) * 0.5 - Vector3(0, 0.6, 0)
		_beam(n, a, mid, 0.09, rope)
		_beam(n, mid, b, 0.09, rope)


## Żuraw portowy na portalu (tło): lokalne +X = kierunek wysięgnika {y = poziom nabrzeża, jib = 28,
## angle = 38°, hook = wysokość haka, color}. Bez kolizji.
func k_crane(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	n.position.y = o.get("y", 0.0)
	var paint := mat(o.get("color", Color(0.82, 0.28, 0.12)), 0.55, 0.3)
	var light := mat(Color(0.9, 0.88, 0.82), 0.6)
	var dark := mat(Color(0.15, 0.15, 0.17), 0.6, 0.5)
	var glass := mat(Color(0.1, 0.13, 0.16), 0.1, 0.3)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_beam(n, Vector3(sx * 3.6, 0.4, sz * 3.6), Vector3(sx * 1.9, 8.0, sz * 1.9), 0.6, paint)
			box(n, Vector3(1.4, 0.8, 1.0), Vector3(sx * 3.6, 0.4, sz * 3.6), dark)
		box(n, Vector3(0.3, 0.3, 6.0), Vector3(sx * 3.0, 3.2, 0), paint)
		box(n, Vector3(6.0, 0.3, 0.3), Vector3(0, 3.2, sx * 3.0), paint)
	box(n, Vector3(4.6, 0.8, 4.6), Vector3(0, 8.4, 0), paint)
	cyl(n, 2.1, 0.6, Vector3(0, 9.1, 0), dark)
	box(n, Vector3(6.6, 3.6, 4.2), Vector3(-1.2, 11.2, 0), light)                 # maszynownia
	box(n, Vector3(6.64, 0.5, 4.24), Vector3(-1.2, 12.0, 0), glass)
	box(n, Vector3(6.8, 0.25, 4.4), Vector3(-1.2, 13.1, 0), paint)
	box(n, Vector3(1.8, 2.0, 1.8), Vector3(2.9, 11.0, 1.3), light)                # kabina
	box(n, Vector3(1.84, 0.9, 1.84), Vector3(2.9, 11.4, 1.3), glass)
	box(n, Vector3(1.6, 2.4, 3.4), Vector3(-5.2, 11.6, 0), dark)                  # przeciwwaga
	var apex := Vector3(-1.0, 22.0, 0)
	for sz in [-1.0, 1.0]:                                                        # kozioł
		_beam(n, Vector3(-4.0, 13.2, sz * 1.8), apex + Vector3(0, 0, sz * 0.35), 0.45, paint)
		_beam(n, Vector3(1.6, 13.2, sz * 1.8), apex + Vector3(0, 0, sz * 0.35), 0.45, paint)
	# wysięgnik kratowy: 4 pasy zbiegające się ku końcówce i zygzak skratowania na bokach
	var a := deg_to_rad(o.get("angle", 38.0))
	var jl: float = o.get("jib", 28.0)
	var p0 := Vector3(2.6, 12.4, 0)
	var dir := Vector3(cos(a), sin(a), 0)
	var nrm := Vector3(-sin(a), cos(a), 0)
	var tip := p0 + dir * jl
	for s1 in [-1.0, 1.0]:
		for s2 in [-1.0, 1.0]:
			_beam(n, p0 + nrm * s1 * 0.6 + Vector3(0, 0, s2 * 0.8), tip + nrm * s1 * 0.25 + Vector3(0, 0, s2 * 0.25), 0.18, paint)
	var k := 0
	var t := 0.0
	while t < jl - 2.0:
		var t2 := t + 2.4
		var sg := 1.0 if k % 2 == 0 else -1.0
		for s2 in [-1.0, 1.0]:
			var q0 := p0 + dir * t + nrm * lerpf(0.6, 0.25, t / jl) * sg + Vector3(0, 0, s2 * lerpf(0.8, 0.25, t / jl))
			var q1 := p0 + dir * t2 - nrm * lerpf(0.6, 0.25, t2 / jl) * sg + Vector3(0, 0, s2 * lerpf(0.8, 0.25, t2 / jl))
			_beam(n, q0, q1, 0.08, paint)
		t = t2
		k += 1
	cyl(n, 0.4, 0.5, tip, dark).rotation.x = PI / 2
	_beam(n, apex, tip, 0.06, dark)
	var hy: float = o.get("hook", 8.0)
	_beam(n, tip, Vector3(tip.x, hy, 0), 0.05, dark)
	box(n, Vector3(0.5, 0.8, 0.4), Vector3(tip.x, hy - 0.4, 0), mat(YELLOW, 0.5))
	sphere(n, 0.18, apex + Vector3(0, 0.4, 0), glow(Color(1.0, 0.1, 0.05), 4.0))


## Przeciwległe nabrzeże za basenem (tło, bez kolizji); (x, z) = krawędź nabrzeża, lokalne +Z = w głąb lądu.
## Płyta nabrzeża z odbojnicami i pachołkami, szopy z dwuspadowymi dachami, silosy z galerią, stosy
## kontenerów, maszty; na zachodzie falochron z czerwono-białą latarnią.
func k_far_quay(e: Array) -> void:
	var n := root(e)
	var top := 0.6
	var conc := mat(Color(0.5, 0.5, 0.48), 0.9)
	box(n, Vector3(330, top - WATER + 2.0, 70), Vector3(35, (top + WATER - 2.0) * 0.5, 35), conc)
	var edge := []
	var bol := []
	var x := -120.0
	while x < 195.0:
		edge.append([Vector3(x, top - 0.9, -0.15), Vector3(0.5, 1.6, 0.3), Color(0.05, 0.05, 0.05)])
		bol.append([Vector3(x + 4.5, top + 0.25, 0.6), Vector3(0.45, 0.5, 0.45), Color(0.1, 0.1, 0.1)])
		x += 9.0
	_boxes(n, edge, 0.9)
	_boxes(n, bol, 0.6, 0.4, true, true)
	# szopy: [x, z, szer., gł., wys., kolor, napis]
	for s in [[-34.0, 30.0, 34.0, 20.0, 9.0, Color(0.62, 0.5, 0.38), "MAGAZYN 5"], [20.0, 30.0, 44.0, 22.0, 10.0, Color(0.55, 0.6, 0.65), "MAGAZYN 6"],
			[72.0, 28.0, 36.0, 18.0, 8.0, Color(0.6, 0.62, 0.55), "MAGAZYN 7"]]:
		var w: float = s[2]
		var d: float = s[3]
		var h: float = s[4]
		var c := Vector3(s[0], top, s[1])
		box(n, Vector3(w, h, d), c + Vector3(0, h * 0.5, 0), corrugated(s[5]))
		for sd in [-1.0, 1.0]:
			var r := box(n, Vector3(w + 0.8, 0.3, d * 0.56), c + Vector3(0, h + d * 0.11, sd * d * 0.24), mat(Color(0.35, 0.3, 0.28), 0.8))
			r.rotation.x = sd * 0.42
		for dx in [-w * 0.25, w * 0.25]:
			box(n, Vector3(6.0, 6.0, 0.1), c + Vector3(dx, 3.0, -d * 0.5 - 0.05), mat(Color(0.2, 0.22, 0.24), 0.6, 0.4))
		var l := label(n, s[6], 2.0, c + Vector3(0, h - 1.6, -d * 0.5 - 0.1), WHITE)
		l.rotation.y = PI
		l.shaded = true
	# silosy z galerią przenośnika
	var silo := mat(Color(0.72, 0.71, 0.66), 0.85)
	for k in 4:
		var p := Vector3(-80.0 + k * 8.6, top, 26.0)
		cyl(n, 4.0, 24.0, p + Vector3(0, 12.0, 0), silo)
		cone(n, 4.0, 0.6, 2.0, p + Vector3(0, 25.0, 0), silo)
	box(n, Vector3(36.0, 2.2, 2.4), Vector3(-67.0, top + 27.0, 26.0), mat(Color(0.6, 0.6, 0.58), 0.8))
	box(n, Vector3(3.0, 30.0, 3.0), Vector3(-88.0, top + 15.0, 26.0), mat(Color(0.6, 0.6, 0.58), 0.8))
	# stosy kontenerów
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var cols := CONTAINER_COLORS + [Color(0.85, 0.85, 0.82)]
	var stacks := []
	for ix in 7:
		for iz in 3:
			for t in rng.randi_range(1, 4):
				stacks.append([Vector3(100.0 + ix * 6.3, top + CONTAINER.y * (t + 0.5), 8.0 + iz * 2.5), Vector3(6.0, CONTAINER.y - 0.03, 2.42),
					cols[rng.randi() % cols.size()]])
	_boxes(n, stacks, 0.6, 0.3)
	# maszty oświetleniowe
	for mx in [-10.0, 50.0, 95.0]:
		cone(n, 0.4, 0.2, 22.0, Vector3(mx, top + 11.0, 12.0), mat(Color(0.6, 0.62, 0.64), 0.45, 0.7))
		box(n, Vector3(2.4, 0.6, 0.4), Vector3(mx, top + 22.2, 12.0), glow(Color(1.0, 0.86, 0.62), 4.0))
	# falochron i latarnia
	box(n, Vector3(7.0, 2.5, 30.0), Vector3(-58.0, WATER + 0.9, -13.0), mat(Color(0.45, 0.45, 0.43), 0.95))
	var lh := Vector3(-58.0, WATER + 2.15, -25.0)
	for k in 5:
		cyl(n, 1.3 - k * 0.1, 2.2, lh + Vector3(0, 1.1 + k * 2.2, 0), mat(Color(0.85, 0.1, 0.08) if k % 2 == 0 else WHITE, 0.6))
	cyl(n, 1.2, 0.15, lh + Vector3(0, 11.1, 0), _dark())
	cyl(n, 0.6, 1.2, lh + Vector3(0, 11.8, 0), glow(Color(1.0, 0.92, 0.7), 6.0))
	cone(n, 0.8, 0.1, 0.8, lh + Vector3(0, 12.8, 0), mat(Color(0.85, 0.1, 0.08), 0.6))


static func _dark() -> StandardMaterial3D:
	return mat(Color(0.12, 0.12, 0.13), 0.6, 0.5)


## Boja torowa kołysząca się na wodzie {color}.
func k_buoy(e: Array) -> void:
	var o := opts(e)
	var n := root(e)
	var b := Motion.new()
	b.bob = 0.12
	b.rock = 0.1
	b.ph = float(e[1]) * 0.37
	b.position = Vector3(0, WATER - 0.1, 0)
	n.add_child(b)
	var c: Color = o.get("color", Color(0.8, 0.1, 0.08))
	cyl(b, 0.65, 0.5, Vector3.ZERO, mat(c, 0.6))
	cyl(b, 0.66, 0.14, Vector3(0, 0.2, 0), mat(WHITE, 0.6))
	cone(b, 0.45, 0.08, 1.6, Vector3(0, 1.05, 0), mat(c, 0.6))
	box(b, Vector3(0.05, 0.6, 0.05), Vector3(0, 2.1, 0), _dark())
	sphere(b, 0.09, Vector3(0, 2.45, 0), glow(c.lightened(0.3), 4.0))
