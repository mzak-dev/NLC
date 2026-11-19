class_name PaintTime
extends RefCounted
## Czysta logika czasu schnięcia (bez sceny) — testowana w tests/test_all.gd.

## sheen = szorstkość powłoki po wyschnięciu (olejna i lakier zostają błyszczące, jak w życiu).
const PAINTS: Array[Dictionary] = [
	{"id": "quick", "name": "Farba szybkoschnąca", "secs": 15 * 60, "sheen": 0.9, "note": "Dla niecierpliwych. Nadal trzeba czekać."},
	{"id": "acrylic", "name": "Emulsja akrylowa", "secs": 3600, "sheen": 0.85, "note": "Klasyk blokowiska. Godzina."},
	{"id": "latex", "name": "Farba lateksowa", "secs": 2 * 3600, "sheen": 0.6, "note": "Zmywalna. Dwie godziny."},
	{"id": "oil", "name": "Farba olejna", "secs": 8 * 3600, "sheen": 0.3, "note": "Pachnie latami 80. Osiem godzin."},
	{"id": "varnish", "name": "Lakier do drewna", "secs": 24 * 3600, "sheen": 0.12, "note": "Doba. Nie dotykać. Serio."},
]
const WALLS := ["Ściana z oknem", "Ściana z drzwiami", "Ściana z kaloryferem", "Goła ściana"]


## Klucz zapisu stanu konkretnej ściany (sekcja „paint”), np. key(2, "state") -> "w2_state".
static func key(wall: int, k: String) -> String:
	return "w%d_%s" % [wall, k]


## Czy ktoś majstrował przy zegarze systemowym: zegar cofnął się względem ostatnio widzianego czasu
## albo podczas działania gry czas ścienny uciekł monotonicznemu (wall_delta vs mono_delta, w sekundach).
## Skok w przód przy wyłączonej grze wygląda jak uczciwe czekanie — wychodzi na jaw przy cofnięciu zegara.
# ponytail: na Windows licznik monotoniczny biegnie też w uśpieniu; na systemach, gdzie staje,
# wybudzenie laptopa dałoby fałszywy alarm — wtedy porównywać z czasem z ostatniej klatki.
static func clock_cheat(last_seen: float, now: float, wall_delta := 0.0, mono_delta := 0.0, tol := 120.0) -> bool:
	return (last_seen > 0.0 and now < last_seen - tol) or wall_delta - mono_delta > tol


static func find(id: String) -> Dictionary:
	for p in PAINTS:
		if p.id == id:
			return p
	return PAINTS[1]


## Pozostały czas w sekundach; speed > 1 tylko do testów (--paint-speed=N).
static func remaining(start_unix: float, total: float, now: float, speed := 1.0) -> float:
	return clampf(total - (now - start_unix) * speed, 0.0, total)


static func fmt(secs: float) -> String:
	var s := int(ceil(secs))
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


static func speed() -> float:
	var c = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Collection")
	return float(c.args.get("paint-speed", "1")) if c else 1.0
