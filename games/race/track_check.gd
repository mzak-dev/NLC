class_name TrackCheck
extends RefCounted
## Walidator trasy zbudowanej przez Apartment: linia jazdy w pokojach, poza wodą, z zapasem od
## przeszkód i wody; pokoje nie nachodzą na wodę; sensowna liczba okrążeń i punktów linii.

const STEP := 0.5          # odstęp próbek linii jazdy [m]


## Lista problemów (pusta = trasa poprawna). Kolejne złe próbki tego samego rodzaju dają jeden wpis.
static func problems(apt: Apartment) -> PackedStringArray:
	var m := apt.m
	var id: String = m.get("id", "?")
	var out := PackedStringArray()
	var clr: float = m.get("clearance", 1.3)
	var rooms: Array = m.get("rooms", [])
	var water: Array = m.get("water", [])
	var run_kind := ""          # rodzaj bieżącej serii złych próbek
	var run_d := INF            # najgorsza odległość w serii
	var run_p := Vector2.ZERO   # gdzie wypadła
	var total := apt.curve.get_baked_length()
	var o := 0.0
	while o <= total:
		var p3 := apt.curve.sample_baked(o)
		var p := Vector2(p3.x, p3.z)
		o += STEP
		var kind := ""
		var d := INF
		if not rooms.any(func(r: Dictionary) -> bool: return (r.rect as Rect2).has_point(p)):
			kind = "poza pokojami"
		elif water.any(func(w: Dictionary) -> bool: return (w.rect as Rect2).has_point(p)):
			kind = "w wodzie"
		else:
			var d_obs := INF
			for ob in apt.obstacles:
				d_obs = minf(d_obs, box_distance(p, ob.center, ob.half, ob.angle))
			var d_wat := INF
			for w in water:
				var rc: Rect2 = w.rect
				d_wat = minf(d_wat, box_distance(p, rc.get_center(), rc.size * 0.5))
			if minf(d_obs, d_wat) < clr:
				kind = "od przeszkody" if d_obs <= d_wat else "od wody"
				d = minf(d_obs, d_wat)
		if kind != run_kind:
			if run_kind != "":
				out.append(_message(id, run_kind, run_d, run_p, clr))
			run_kind = kind
			run_d = d
			run_p = p
		elif d < run_d:
			run_d = d
			run_p = p
	if run_kind != "":
		out.append(_message(id, run_kind, run_d, run_p, clr))
	for r in rooms:
		for w in water:
			if (r.rect as Rect2).intersection(w.rect).get_area() > 0.01:
				out.append("%s: pokój %s nachodzi na wodę %s" % [id, r.rect, w.rect])
	var laps: int = m.get("laps", 3)
	if laps < 1 or laps > 5:
		out.append("%s: liczba okrążeń %d poza 1..5" % [id, laps])
	if m.path.size() < 8:
		out.append("%s: linia jazdy ma tylko %d punktów (min 8)" % [id, m.path.size()])
	return out


## Odległość punktu od prostokąta obróconego o angle [rad] wokół środka (0 = punkt w środku).
static func box_distance(p: Vector2, center: Vector2, half: Vector2, angle := 0.0) -> float:
	var l := (p - center).rotated(-angle)
	return (l.abs() - half).max(Vector2.ZERO).length()


static func _message(id: String, kind: String, d: float, p: Vector2, clr: float) -> String:
	var at := "przy (%.1f, %.1f)" % [p.x, p.y]
	if kind == "poza pokojami" or kind == "w wodzie":
		return "%s: linia jazdy %s %s" % [id, kind, at]
	return "%s: %s m %s %s, min %s" % [id, _pl(d), kind, at, _pl(clr)]


## Liczba po polsku: przecinek dziesiętny, dwa miejsca.
static func _pl(x: float) -> String:
	return ("%.2f" % x).replace(".", ",")
