class_name Lobby
extends RefCounted
## Poczekalnia wyścigu: do 4 graczy, każdy z urządzeniem i wybranym kredensem. Czysta logika, bez UI.
## P1 = slots[0]. Gdy P1 gra na "kb", ma całą klawiaturę; prawy Shift dzieli ją na WASD (P1) i strzałki (nowy gracz).

const MAX := 4

var slots: Array[Dictionary] = []     # {device: String, type_i: int}
var focus := 0                        # slot, który ostatnio zmieniał kredens (podgląd)


func _init(first_device: String, type_i := 0) -> void:
	slots.append({"device": first_device, "type_i": type_i})


## Indeks gracza, do którego należy urządzenie (z regułami klawiatury P1), albo -1.
func _owner(device: String) -> int:
	var p1: String = slots[0].device
	if device.begins_with("kb"):
		if p1 == "kb":
			return 0
		if p1 == "kb_a" and device == "kb":
			return 0
		if p1.begins_with("pad") and device == "kb":
			return -1
	for i in slots.size():
		if slots[i].device == device:
			return i
	return -1


func _free_type() -> int:
	for t in Kredens.TYPES.size():
		var used := false
		for s in slots:
			if s.type_i == t:
				used = true
		if not used:
			return t
	return 0


func _add(device: String) -> bool:
	if slots.size() >= MAX:
		return false
	slots.append({"device": device, "type_i": _free_type()})
	return true


## Zwraca "" | "changed" | "start" | "back" | "track_prev" | "track_next" | "reroll".
func handle(device: String, action: String) -> String:
	var idx := _owner(device)
	var p1_pad: bool = slots[0].device.begins_with("pad")
	match action:
		"join":
			if device == "kb_b" and slots[0].device == "kb":
				if slots.size() >= MAX:
					return ""
				slots[0].device = "kb_a"
				_add("kb_b")
				return "changed"
			if idx == 0:
				return "start" if p1_pad else ""
			if idx > 0 or device == "kb":
				return ""
			return "changed" if _add(device) else ""
		"leave":
			if idx < 0:
				return ""
			if idx == 0:
				return "back" if p1_pad else ""
			slots.remove_at(idx)
			if slots[0].device == "kb_a" and not slots.any(func(s): return s.device == "kb_b"):
				slots[0].device = "kb"
			focus = mini(focus, slots.size() - 1)
			return "changed"
		"left", "right":
			if idx < 0:
				return ""
			var n := Kredens.TYPES.size()
			slots[idx].type_i = posmod(slots[idx].type_i + (1 if action == "right" else -1), n)
			focus = idx
			return "changed"
		"up", "down", "accept", "back", "reroll":
			if idx != 0:
				return ""
			match action:
				"up": return "track_prev"
				"down": return "track_next"
				"accept": return "start"
				"back": return "back"
				_: return "reroll"
	return ""


## Urządzenia do wyścigu; jeden człowiek jedzie jak dawniej na "any".
func race_devices() -> Array[String]:
	var out: Array[String] = []
	if slots.size() == 1:
		out.append("any")
		return out
	for s in slots:
		out.append(s.device)
	return out


## 4 - ludzie różnych typów spoza typów ludzi (losowa kolejność z rng).
static func bot_types(human_types: Array, n_types: int, rng: RandomNumberGenerator) -> Array[int]:
	var pool: Array[int] = []
	for t in n_types:
		if not human_types.has(t):
			pool.append(t)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	return pool.slice(0, maxi(0, 4 - human_types.size()))
