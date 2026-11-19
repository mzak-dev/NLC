class_name Tournament
extends RefCounted
## Turniej: 4 wyścigi na wylosowanych trasach, punkty 10/7/5/3 za miejsca 1–4.
## Klucze uczestników: ludzie "P1".."P4", boty "bot:<id typu>".

const POINTS := [10, 7, 5, 3]
const RACES := 4

var tracks: Array[String] = []
var round := 0
var points := {}   # klucz -> suma punktów
var last := {}     # klucz -> miejsce (1..4) w ostatnim wyścigu

func _init(track_ids: Array[String] = []) -> void:
	tracks = track_ids

## Losuje n różnych tras z ids (bez powtórek, o ile starczy tras).
static func draw_tracks(ids: Array, rng: RandomNumberGenerator, n := RACES) -> Array[String]:
	var pool := ids.duplicate()
	var out: Array[String] = []
	while out.size() < n and not pool.is_empty():
		out.append(pool.pop_at(rng.randi() % pool.size()))
	return out

## Dopisuje wyniki wyścigu; order = klucze w kolejności mety.
func add_race(order: Array[String]) -> void:
	for i in order.size():
		var k := order[i]
		points[k] = int(points.get(k, 0)) + POINTS[mini(i, POINTS.size() - 1)]
		last[k] = i + 1
	round += 1

## Klucze od najlepszego: punkty malejąco, remis rozstrzyga ostatni wyścig.
func standings() -> Array[String]:
	var keys: Array[String] = []
	for k in points:
		keys.append(k)
	keys.sort_custom(func(a: String, b: String) -> bool:
		if points[a] != points[b]:
			return points[a] > points[b]
		return last[a] < last[b])
	return keys

func done() -> bool:
	return round >= RACES
