class_name MapM4
extends Decor
## Mieszkanie M4 na IV piętrze: salon, kuchnia z wyspą, korytarz, sypialnia, pokój dziecięcy.


static func data() -> Dictionary:
	return {
		"id": "m4", "name": "MIESZKANIE M4", "place": "mieszkanie M4, IV piętro",
		"size": Vector2(32, 24), "height": 2.8, "env": "flat", "wall_style": "plain", "clearance": 0.75,
		"rooms": ROOMS, "rugs": RUGS, "walls": WALLS, "doors": DOORS, "path": PATH, "humps": HUMPS,
		"furniture": FURNITURE, "props": PROPS,
	}


const ROOMS := [
	{"rect": Rect2(0, 0, 16, 11), "floor": 0, "a": Color(0.55, 0.33, 0.16), "b": Color(0.40, 0.22, 0.10), "wall": Color(0.55, 0.64, 0.5), "grip": 1.0},
	{"rect": Rect2(16, 0, 16, 11), "floor": 1, "a": Color(0.9, 0.9, 0.86), "b": Color(0.6, 0.1, 0.1), "wall": Color(0.92, 0.9, 0.82), "grip": 0.75},
	{"rect": Rect2(0, 11, 32, 3), "floor": 3, "a": Color(0.74, 0.62, 0.43), "b": Color(0.62, 0.5, 0.33), "wall": Color(0.86, 0.78, 0.58), "grip": 1.05},
	{"rect": Rect2(16, 14, 16, 10), "floor": 2, "a": Color(0.34, 0.38, 0.55), "b": Color(0.27, 0.3, 0.45), "wall": Color(0.76, 0.68, 0.8), "grip": 1.35},
	{"rect": Rect2(0, 14, 16, 10), "floor": 2, "a": Color(0.35, 0.6, 0.35), "b": Color(0.85, 0.75, 0.3), "wall": Color(0.95, 0.85, 0.6), "grip": 1.25},
]
## Dywany i kałuże: zmieniają przyczepność. „puddle” = rozlana woda (ślisko!).
const RUGS := [
	{"rect": Rect2(5, 1.2, 7, 3.2), "a": Color(0.5, 0.06, 0.08), "b": Color(0.85, 0.7, 0.4), "grip": 1.5},
	{"rect": Rect2(26, 19.5, 4, 3), "a": Color(0.85, 0.82, 0.72), "b": Color(0.35, 0.3, 0.25), "grip": 1.5},
	{"rect": Rect2(23, 7.3, 4.5, 2.8), "puddle": true, "grip": 0.4},
]
const WALLS := [
	[0, 0, 32, 0], [32, 0, 32, 24], [0, 24, 32, 24], [0, 0, 0, 24],
	[16, 0, 16, 1], [16, 4.5, 16, 11],                       # salon | kuchnia
	[0, 11, 1, 11], [4.5, 11, 17, 11], [21.5, 11, 32, 11],   # korytarz, strona północna
	[0, 14, 1, 14], [4.5, 14, 28.5, 14], [31.5, 14, 32, 14], # korytarz, strona południowa
	[16, 14, 16, 19.5], [16, 23, 16, 24],                    # sypialnia | pokój dziecięcy
	[5, 11, 5, 14], [17, 11, 17, 14],                        # wiatrołap, koniec korytarza
]
const DOORS := [[16, 1, 16, 4.5], [1, 11, 4.5, 11], [17, 11, 21.5, 11], [1, 14, 4.5, 14], [28.5, 14, 31.5, 14], [16, 19.5, 16, 23]]
## Linia jazdy. Punkt 0 = linia start/meta.
const PATH := [
	Vector2(7, 2.75), Vector2(15.5, 2.75), Vector2(22, 2.6), Vector2(28, 2.6),                       # salon → kuchnia
	Vector2(30.2, 4.0), Vector2(30.2, 7.4), Vector2(28, 8.9), Vector2(22, 8.9),                      # nawrót wokół wyspy
	Vector2(19.8, 9.8), Vector2(19.3, 11), Vector2(19.9, 12.4), Vector2(22, 12.6), Vector2(28, 12.6),  # esek do korytarza
	Vector2(30, 13.4), Vector2(30, 15), Vector2(30, 16.5), Vector2(30, 20),                          # skocznia
	Vector2(28.5, 21.6), Vector2(22, 21.6), Vector2(16.5, 21.3),                                      # sypialnia
	Vector2(13.5, 22.9), Vector2(11.6, 22.9), Vector2(9.2, 21.4), Vector2(6.7, 20.2), Vector2(4.2, 19.3), # szykana
	Vector2(2.75, 17), Vector2(2.75, 14), Vector2(2.75, 12.5), Vector2(2.75, 11), Vector2(2.75, 8),
	Vector2(3.4, 4.6), Vector2(5, 3),
]
## Progi: najazd, płaski blat, zjazd [x, z_start, szer., dł. najazdu, dł. blatu, wysokość, kolor]
const HUMPS := [[28.7, 15.6, 2.6, 1.5, 1.5, 0.2, Color(0.78, 0.62, 0.38)]]
## Meble stałe: [x, z, szer., głęb., wys., kolor]
const FURNITURE := [
	[6.0, 9.6, 3.0, 0.9, 0.85, Color(0.25, 0.35, 0.22)],      # kanapa
	[7.2, 0.15, 1.6, 0.5, 1.1, Color(0.15, 0.13, 0.12)],      # szafka z telewizorem
	[10.0, 10.4, 5.0, 0.45, 2.0, Color(0.38, 0.22, 0.1)],     # meblościanka
	[10.0, 6.0, 1.4, 0.8, 0.45, Color(0.4, 0.24, 0.12)],      # ława
	[13.5, 6.5, 0.9, 0.9, 0.8, Color(0.5, 0.2, 0.12)],        # fotel
	[17.0, 0.15, 9.0, 0.6, 0.9, Color(0.85, 0.85, 0.8)],      # szafki kuchenne
	[31.1, 0.15, 0.75, 0.7, 1.8, Color(0.95, 0.95, 0.93)],    # lodówka
	[21.0, 4.5, 7.0, 2.0, 0.9, Color(0.82, 0.8, 0.74)],       # wyspa kuchenna
	[21.0, 15.0, 3.5, 4.2, 0.55, Color(0.6, 0.55, 0.7)],      # łóżko
	[24.6, 15.0, 0.5, 0.45, 0.55, Color(0.45, 0.3, 0.18)],    # szafka nocna
	[17.0, 14.2, 2.4, 0.6, 2.2, Color(0.45, 0.3, 0.18)],      # szafa
	[11.0, 20.0, 1.1, 1.4, 1.1, Color(0.95, 0.6, 0.75)],      # domek dla lalek
	[6.0, 21.5, 1.4, 2.3, 0.6, Color(0.25, 0.45, 0.85)],      # skrzynia z zabawkami
	[9.0, 14.2, 2.0, 1.2, 0.6, Color(0.9, 0.9, 0.95)],        # łóżeczko
]
## Rekwizyty fizyczne (latają): [x, z, szer., wys., głęb., masa, kolor]
const PROPS := [
	[22.5, 7.0, 0.45, 0.9, 0.45, 5.0, Color(0.7, 0.55, 0.35)],    # krzesła przy wyspie
	[25.5, 7.0, 0.45, 0.9, 0.45, 5.0, Color(0.7, 0.55, 0.35)],
	[11.5, 3.9, 0.5, 0.4, 0.5, 3.0, Color(0.6, 0.15, 0.2)],       # pufa
	[15.2, 5.5, 0.3, 0.6, 0.3, 4.0, Color(0.2, 0.5, 0.2)],        # kwiatek
	[24.0, 12.2, 0.3, 0.12, 0.12, 0.6, Color(0.1, 0.1, 0.1)],     # buty w korytarzu
	[26.5, 12.9, 0.3, 0.12, 0.12, 0.6, Color(0.5, 0.3, 0.1)],
	[23.0, 13.2, 0.3, 0.12, 0.12, 0.6, Color(0.9, 0.9, 0.9)],
	[27.5, 21.8, 0.35, 0.25, 0.2, 0.8, Color(0.85, 0.5, 0.6)],    # kapcie
	[13.5, 21.8, 0.25, 0.25, 0.25, 0.5, Color(0.9, 0.2, 0.2)],    # klocki
	[14.0, 22.4, 0.25, 0.25, 0.25, 0.5, Color(0.2, 0.4, 0.9)],
	[9.5, 21.8, 0.25, 0.25, 0.25, 0.5, Color(0.95, 0.8, 0.1)],
	[8.5, 20.8, 0.25, 0.25, 0.25, 0.5, Color(0.2, 0.7, 0.3)],
	[4.0, 19.0, 0.25, 0.25, 0.25, 0.5, Color(0.9, 0.5, 0.1)],
	[5.0, 17.5, 0.4, 0.5, 0.35, 1.5, Color(0.55, 0.38, 0.2)],     # miś
]
