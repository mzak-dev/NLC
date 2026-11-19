extends Node3D
## Wyścigi kredensów: wybór kredensu → odliczanie → wyścig (gracz + 3 boty) → wyniki.
## Oprawa w race_ui.gd. --autorace: same boty, headless, assert że wszyscy kończą (test).
## --shot=race: autopilot do zrzutu. --trace: wypisuje pozycje botów co 3 s.
## --wreck=5.5: każdy kredens dostaje na starcie uderzenie o tej sile (podgląd uszkodzeń).

enum S { SELECT, COUNTDOWN, RACE, RESULTS }

const TYPES := Kredens.TYPES
const CHAIN_TIMEOUT := 2.5   # s bez umiejętności = łańcuch zaliczony

var state := S.SELECT
var laps := 3
var auto := false
var apt: Apartment
var curve: Curve3D
var length := 0.0
var racers: Array[Dictionary] = []
var player: Kredens
var cam: Camera3D
var cam_fwd := Vector3.FORWARD
var race_t := 0.0
var sel := 0
var last_type := 0
var _end_t := -1.0
var ui: RaceUI
var fx: TrackFX              # linia jazdy + bramki punktów kontrolnych
var cp_i := 0
var cp_lap := 0
var splits: Array[float] = []
var best_splits: Array[float] = []
var feel: RaceFeel          # null w trybie headless (testy)
var _feel_off := Vector2.ZERO
var maps := RaceMaps.all()
var map_i := 0

# łańcuch umiejętności gracza
var chain_pts := 0.0
var chain_mult := 1.0
var chain_idle := 0.0
var chain_last := ""
var skill_total := 0


func _ready() -> void:
	auto = Collection.args.has("autorace") or Collection.args.get("shot", "").begins_with("race")
	if Collection.args.has("autorace"):
		laps = int(Collection.args.get("laps", "3"))
	for i in maps.size():
		if maps[i].id == Collection.args.get("map", ""):
			map_i = i
	cam = Camera3D.new()
	cam.fov = 68
	add_child(cam)
	cam.look_at_from_position(Vector3(16, 28, 36), Vector3(16, 0, 12))
	ui = RaceUI.new()
	add_child(ui)
	if DisplayServer.get_name() != "headless":
		feel = RaceFeel.new()
		add_child(feel)
		feel.setup(cam)
	_load_map()
	ui.build([["Jeszcze raz", func(): _start(last_type)], ["Zmień kredens", _show_select], ["Wróć do menu", Collection.back_to_menu]])
	ui.set_map(apt.m, curve)
	if auto and Collection.args.get("shot", "") != "race_select":
		_start(1)
		if Collection.args.get("shot", "") == "race_results":   # podgląd ekranu wyników do zrzutu
			get_tree().create_timer(2.0).timeout.connect(_show_results)
	else:
		_show_select()


# ---------- przebieg ----------

func _show_select() -> void:
	state = S.SELECT
	_clear_racers()
	ui.show_select()
	_update_select()


## Buduje świat wybranej mapy od nowa (stary znika razem z kredensami).
func _load_map() -> void:
	_clear_racers()
	if apt:
		apt.queue_free()
	apt = Apartment.new()
	add_child(apt)
	apt.build(maps[map_i])
	curve = apt.curve
	length = curve.get_baked_length()
	fx = TrackFX.new()
	apt.add_child(fx)
	fx.setup(curve, 5.0, 4.5)
	if not Collection.args.has("autorace"):
		laps = maps[map_i].get("laps", 3)
	if ui.track_lbl:
		ui.set_map(apt.m, curve)


## Klucze zapisu rekordów: mieszkanie bez prefiksu (zgodność ze starszymi zapisami), inne mapy z prefiksem.
func _key(k: String) -> String:
	return k if maps[map_i].id == "m4" else maps[map_i].id + "_" + k


func _update_select() -> void:
	var ty: Dictionary = TYPES[sel]
	var stats := {
		"Prędkość": ty.vmax / 10.5,
		"Przyspieszenie": ty.accel / 6.0,
		"Prowadzenie": ty.steer * ty.grip / 0.8,
		"Stabilność": 1.0 - ty.com * ty.roll / 0.25,
		"Masa": ty.mass / 230.0,
	}
	var wins_all := 0
	for t in TYPES:
		wins_all += int(Collection.get_val("race", _key("wins_" + t.id), 0))
	ui.set_select(ty, sel, TYPES.size(), stats, Collection.get_val("race", _key("wins_" + ty.id), 0), wins_all,
		Collection.get_val("race", _key("best_" + ty.id), 0.0), Collection.get_val("race", _key("best_lap_any"), 0.0), laps)


func _clear_racers() -> void:
	for r in racers:
		r.car.queue_free()
	racers.clear()
	player = null


func _start(type_i: int) -> void:
	last_type = type_i
	ui.show_hud()
	_clear_racers()
	chain_pts = 0.0
	chain_mult = 1.0
	chain_last = ""
	skill_total = 0
	ui.skill_bank(0)
	var others: Array = range(TYPES.size())
	others.erase(type_i)
	others.shuffle()
	var grid: Array = others.slice(0, 3)
	grid.append(type_i)         # gracz startuje z końca stawki
	for slot in 4:
		var off := length - 3.0 - (slot / 2) * 3.4
		var p := curve.sample_baked(off)
		var dir := (curve.sample_baked(off + 1.0) - p).normalized()
		var side := Vector3(dir.z, 0, -dir.x) * (1.3 if slot % 2 == 0 else -1.3)
		var car := Kredens.new()
		car.setup(TYPES[grid[slot]])
		car.is_bot = slot != 3 or auto
		car.curve = curve
		car.surface_fn = apt.grip_at
		car.lane = randf_range(-0.5, 0.5) if slot != 3 else 0.0
		car.skill = randf_range(0.92, 1.0) if slot != 3 else 1.0
		car.track_off = off
		add_child(car)
		car.global_transform = Transform3D(Basis.looking_at(-dir, Vector3.UP), p + side + Vector3(0, 0.25, 0))
		racers.append({"car": car, "name": TYPES[grid[slot]].name, "id": TYPES[grid[slot]].id, "player": slot == 3,
			"progress": off - length, "last_off": off, "laps_done": -1, "lap_start": 0.0, "best": INF, "finish": -1.0})
	player = racers[3].car
	player.damaged.connect(func(lv: int):
		if lv >= 2:
			Collection.tone(1500 + randf() * 700, 0.12 * lv, 0.25, 0.9))   # brzęk szkła i garnków
	fx.reprofile(4.2 * player.t.grip, player.t.accel * 1.1)
	cp_i = 0
	cp_lap = 0
	splits.clear()
	best_splits.clear()
	if feel:
		feel.attach(player)
	cam_fwd = player.global_basis.z
	cam.global_position = player.global_position - cam_fwd * 6.0 + Vector3.UP * 3.0
	race_t = 0.0
	_end_t = -1.0
	state = S.COUNTDOWN
	var tw := create_tween()
	for txt in ["3", "2", "1"]:
		tw.tween_callback(func():
			ui.center(txt)
			Collection.tone(440, 0.15, 0.3))
		tw.tween_interval(0.8 if not Collection.args.has("autorace") else 0.01)
	tw.tween_callback(_go)


func _go() -> void:
	ui.center("START!")
	Collection.tone(880, 0.35, 0.3)
	state = S.RACE
	for r in racers:
		r.car.controls_enabled = true
		if Collection.args.has("wreck"):     # --wreck=5.5: uderzenie na starcie (zrzuty, testy)
			r.car.take_hit(float(Collection.args.wreck))
	get_tree().create_timer(1.0).timeout.connect(func():
		if state == S.RACE:
			ui.center(""))


func _physics_process(dt: float) -> void:
	if state != S.RACE:
		return
	race_t += dt
	for r in racers:
		var car: Kredens = r.car
		var off := Apartment.closest_near(curve, car.global_position, r.last_off)
		r.progress += Apartment.wrap_delta(off - r.last_off, length)
		r.last_off = off
		if r.player:
			_checkpoints(r)
		var done := floori(r.progress / length)
		if done <= r.laps_done or r.finish >= 0.0:
			continue
		if r.laps_done < 0:
			r.laps_done = 0
			continue
		var lap_t: float = race_t - r.lap_start
		r.lap_start = race_t
		r.laps_done = done
		r.best = minf(r.best, lap_t)
		if r.player:
			if lap_t <= r.best:
				best_splits = splits.duplicate()
			splits.clear()
			fx.flash_gate(0, lap_t <= r.best)
		if r.player and not auto:
			Collection.tone(1046, 0.2, 0.25)
			ui.flash("Okrążenie %d:  %s" % [done, RaceUI.fmt_time(lap_t)])
		if done >= laps:
			r.finish = race_t
			if r.player and not auto:
				car.is_bot = true
				ui.center("META!")
				ui.flash("Pozycja %d" % (_order().find(r) + 1))
				_end_t = race_t + 2.5
	if not auto:
		_skills(dt)
	if Collection.args.has("trace") and Engine.get_physics_frames() % 360 == 0:
		var line := "t=%5.1f" % race_t
		for r in racers:
			var c: Kredens = r.car
			line += " | %s (%.1f,%.1f) v=%.1f off=%.0f" % [r.id, c.global_position.x, c.global_position.z, c.linear_velocity.length(), r.last_off]
		print(line)
	var all_done := racers.all(func(r): return r.finish >= 0.0)
	if Collection.args.has("autorace"):
		_check_autorace(all_done)
	elif _end_t > 0.0 and race_t >= _end_t:
		_show_results()


## Punkty kontrolne gracza: międzyczas od startu okrążenia, porównanie z najlepszym okrążeniem.
func _checkpoints(r: Dictionary) -> void:
	var target: float = cp_lap * length + fx.cps[cp_i]
	if r.progress < target:
		return
	var split: float = race_t - r.lap_start
	var delta := NAN
	if cp_i < best_splits.size():
		delta = split - best_splits[cp_i]
	splits.append(split)
	fx.flash_gate(cp_i + 1, is_nan(delta) or delta <= 0.0)
	if not auto:
		ui.checkpoint(cp_i + 1, fx.cps.size(), split, delta)
		Collection.tone(1320 if is_nan(delta) or delta <= 0.0 else 700, 0.12, 0.2)
	cp_i += 1
	if cp_i >= fx.cps.size():
		cp_i = 0
		cp_lap += 1


## Umiejętności w stylu gier z otwartym światem: poślizg bokiem, lot, jazda po kałuży.
## Każda nowa umiejętność w łańcuchu podbija mnożnik; po CHAIN_TIMEOUT s ciszy punkty są zaliczane.
func _skills(dt: float) -> void:
	if player.flips >= 1:
		Collection.unlock("race", "turtle")
	if player.flips >= 5:
		Collection.unlock("race", "roofer")
	if chain_mult >= 3.0:
		Collection.unlock("race", "combo")
	var v := player.linear_velocity
	var side := absf(v.dot(player.global_basis.x))
	var airborne := player.wheels.all(func(w): return not w.is_in_contact())
	var skill_name := ""
	var rate := 0.0
	if airborne and v.length() > 1.5:
		skill_name = "LOT Z PROGU"
		rate = 400.0
	elif apt.grip_at(player.global_position) < 0.5 and v.length() > 2.0:
		skill_name = "AKWAPLANING"
		rate = 250.0
	elif side > 1.4 and v.length() > 3.0:
		skill_name = "POŚLIZG BOKIEM"
		rate = 150.0
	if skill_name != "":
		if skill_name != chain_last:
			chain_mult = minf(chain_mult + (0.5 if chain_last != "" else 0.0), 5.0)
			chain_last = skill_name
		chain_pts += rate * dt
		chain_idle = 0.0
		ui.skill(skill_name, int(chain_pts), chain_mult)
	elif chain_pts > 0.0:
		chain_idle += dt
		if chain_idle > CHAIN_TIMEOUT:
			skill_total += int(chain_pts * chain_mult)
			ui.skill_bank(int(chain_pts * chain_mult))
			Collection.tone(1320, 0.12, 0.15)
			chain_pts = 0.0
			chain_mult = 1.0
			chain_last = ""


func _check_autorace(all_done: bool) -> void:
	var limit := 70.0 * laps
	if not all_done and race_t < limit:
		return
	for r in _order():
		print("  %-40s okr: %d  czas: %s  najlepsze: %.2f  wywrotki: %d  mocne uderzenia: %d  masa: %.0f/%.0f" % [r.name, r.laps_done,
			"%.2f" % r.finish if r.finish >= 0 else "—", r.best, r.car.flips, r.car.hard_hits, r.car.mass, r.car.t.mass])
	print("AUTORACE ", "OK" if all_done else "FAIL (limit %.0f s)" % limit)
	get_tree().quit(0 if all_done else 1)


func _order() -> Array:
	var o := racers.duplicate()
	o.sort_custom(func(a, b):
		if a.finish >= 0.0 and b.finish >= 0.0:
			return a.finish < b.finish
		if a.finish >= 0.0 or b.finish >= 0.0:
			return a.finish >= 0.0
		return a.progress > b.progress)
	return o


func _show_results() -> void:
	state = S.RESULTS
	skill_total += int(chain_pts * chain_mult)
	chain_pts = 0.0
	var order := _order()
	var me: Dictionary = racers[3]
	var place := order.find(me) + 1
	var rows := []
	for r in order:
		rows.append({"name": r.name, "player": r.player, "time": RaceUI.fmt_time(r.finish) if r.finish >= 0.0 else "nie dojechał"})
	var note := ""
	var id: String = me.id
	var prev: float = Collection.get_val("race", _key("best_" + id), 0.0)
	if me.best < INF and (prev == 0.0 or me.best < prev):
		Collection.set_val("race", _key("best_" + id), me.best)
		note = "NOWY REKORD tego kredensu!"
	var any: float = Collection.get_val("race", _key("best_lap_any"), 0.0)
	if me.best < INF and (any == 0.0 or me.best < any):
		Collection.set_val("race", _key("best_lap_any"), me.best)
		note = "NOWY REKORD TORU!"
	if place == 1:
		Collection.set_val("race", _key("wins_" + id), Collection.get_val("race", _key("wins_" + id), 0) + 1)
		Collection.tone(784, 0.15)
		Collection.tone(1046, 0.4)
		Collection.unlock("race", "first_win")
		if id == "shadow":
			Collection.unlock("race", "black_is_faster")
		if TYPES.all(func(t): return Collection.get_val("race", _key("wins_" + t.id), 0) > 0):
			Collection.unlock("race", "collector")
	elif place == racers.size():
		Collection.unlock("race", "last_place")
	ui.show_results(place, me.name, rows, me.best, skill_total, note)


# ---------- kamera i HUD ----------

func _process(dt: float) -> void:
	if state == S.SELECT:
		cam.fov = 68.0
		cam.h_offset = 0.0
		cam.v_offset = 0.0
		# kamera tła jedzie powoli po trasie na wysokości oczu — zawsze wewnątrz mapy
		var off := fposmod(Time.get_ticks_msec() / 1000.0 * 1.6, length)
		var p := curve.sample_baked(off) + Vector3.UP * 1.5
		var ahead := curve.sample_baked(fposmod(off + 7.0, length)) + Vector3.UP * 1.0
		cam.global_position = cam.global_position.lerp(p, 1.0 - exp(-dt * 2.0)) if cam.global_position.distance_to(p) < 5.0 else p
		cam.look_at(ahead)
		return
	if player == null:
		return
	var b := player.global_basis
	var fwd := Vector3(b.z.x, 0, b.z.z)
	if fwd.length() > 0.3:
		cam_fwd = cam_fwd.slerp(fwd.normalized(), 1.0 - exp(-dt * 3.0)).normalized()
	var high := 2.0 if maps[map_i].get("ceiling", false) else 2.9   # pod stropem kamera niżej
	var want := player.global_position - cam_fwd * (5.2 + _feel_off.x) + Vector3.UP * (high + _feel_off.y)
	cam.global_position = cam.global_position.lerp(want, 1.0 - exp(-dt * 6.0))
	cam.look_at(player.global_position + Vector3.UP * 0.9 + cam_fwd * 1.5)
	if feel:
		_feel_off = feel.update(dt, state == S.RACE)
	apt.update_fade(cam.global_position, player.global_position + Vector3.UP, dt)
	fx.show_line = Collection.get_val("settings", "driving_line", true) and state != S.RESULTS
	fx.fade_gates(cam.global_position)
	fx.update_line(racers[3].last_off, Vector3(player.linear_velocity.x, 0, player.linear_velocity.z).length())

	var me: Dictionary = racers[3]
	var order := _order()
	var rows := []
	var dots := []
	for r in order:
		var gap := "—"
		if not r.player:
			var dm: float = r.progress - me.progress
			gap = ("+%.0f m" % dm) if dm >= 0.0 else ("%.0f m" % dm)
		rows.append({"name": r.name, "gap": gap, "player": r.player})
		var c: Kredens = r.car
		var f := Vector2(c.global_basis.z.x, c.global_basis.z.z)
		dots.append({"pos": Vector2(c.global_position.x, c.global_position.z), "dir": f.normalized() if f.length() > 0.1 else Vector2.UP, "player": r.player})
	ui.hud_update({
		"lap": clampi(me.laps_done + 1, 1, laps), "laps": laps, "pos": order.find(me) + 1,
		"lap_t": race_t - me.lap_start if state == S.RACE else 0.0, "race_t": race_t, "best": me.best,
		"speed": player.linear_velocity.length() * 3.6, "rows": rows, "dots": dots,
		"flipped": player.flip_t > 0.3 and state == S.RACE,
	})


func _unhandled_input(event: InputEvent) -> void:
	if state != S.SELECT:
		return
	if event.is_action_pressed("ui_left", true) or event.is_action_pressed("ui_right", true):
		sel = posmod(sel + (1 if event.is_action("ui_right") else -1), TYPES.size())
		Collection.tone(760, 0.05, 0.18)
		_update_select()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		map_i = posmod(map_i + (1 if event.is_action("ui_down") else -1), maps.size())
		Collection.tone(620, 0.08, 0.2)
		_load_map()
		_update_select()
	elif event.is_action_pressed("ui_accept"):
		Collection.tone(990, 0.12, 0.2)
		_start(sel)
