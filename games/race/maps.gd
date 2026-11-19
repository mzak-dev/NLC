class_name RaceMaps
extends RefCounted
## Rejestr map wyścigu kredensów. Każda mapa to klasa (extends Decor) ze statycznym data();
## Apartment.build(map) buduje z danych świat, a dekoracje oddaje instancji klasy z klucza „builder”.
## Klucze danych: id, name, place, size, height, env, ceiling, wall_style, clearance, laps, rooms,
##                water, rugs, walls, doors, path, humps, furniture, props, pillars, cars, arrows, lines, lamps.


## Klasy map w kolejności menu.
static func classes() -> Array:
	return [MapM4, MapPodziemny, MapDoki, MapKanaly]


## Dane wszystkich map z dopisaną klasą budującą dekoracje („builder”).
static func all() -> Array:
	var out := []
	for c in classes():
		var d: Dictionary = c.data()
		d["builder"] = c
		out.append(d)
	return out
