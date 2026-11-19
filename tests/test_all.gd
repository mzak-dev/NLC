extends SceneTree
## Uruchom: godot --headless --path . --script res://tests/test_all.gd

var failed := 0


func check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		failed += 1
		printerr("  FAIL ", what)


## W _process, nie w _init: kredens musi być w drzewie sceny, a drzewo rusza dopiero z pierwszą klatką.
func _process(_dt: float) -> bool:
	print("Klamka:")
	var h := HandleSim.new()
	h.step(h.breakaway_force() * 0.9, 1.0)
	check(h.theta == 0.0, "siła poniżej progu nie rusza klamki")
	h.step(200.0, 0.3)
	check(is_equal_approx(h.theta, h.theta_max), "200 N dociska klamkę do dolnego ogranicznika")
	h.bounces = 0
	var t := 0.0
	while not h.at_rest() and t < 5.0:
		h.step(0.0, 1.0 / 120.0)
		t += 1.0 / 120.0
	check(h.at_rest(), "puszczona wraca do spoczynku (%.2f s)" % t)
	check(h.bounces >= 1, "odbija się od górnego ogranicznika (%d odbić)" % h.bounces)
	var dead := HandleSim.new()
	dead.restitution = 0.0
	dead.theta = dead.theta_max
	for i in 240:
		dead.step(0.0, 1.0 / 120.0)
	check(dead.bounces == 1 and dead.at_rest(), "restytucja 0: jedno uderzenie, bez odbić")

	var held := HandleSim.new()
	for i in 240:
		held.step(250.0 if i % 2 == 0 else 120.0, 1.0 / 120.0)
	check(held.bounces == 0, "dociskanie do oporu nie nabija odbić")
	print("Farba:")
	check(PaintTime.remaining(1000.0, 3600.0, 1000.0) == 3600.0, "na starcie cały czas")
	check(is_equal_approx(PaintTime.remaining(1000.0, 3600.0, 2800.0), 1800.0), "po 30 min zostaje 30 min (także po restarcie gry)")
	check(PaintTime.remaining(1000.0, 3600.0, 99999.0) == 0.0, "po czasie zero, nie ujemnie")
	check(PaintTime.remaining(1000.0, 3600.0, 1060.0, 60.0) == 0.0, "mnożnik testowy przyspiesza")
	check(PaintTime.fmt(3661.0) == "01:01:01", "format hh:mm:ss")
	check(PaintTime.key(2, "state") == "w2_state", "klucz zapisu ściany")
	check(not PaintTime.clock_cheat(1000.0, 5000.0, 1.0, 1.0), "uczciwe czekanie to nie oszustwo")
	check(not PaintTime.clock_cheat(0.0, 5000.0), "pierwsze uruchomienie to nie oszustwo")
	check(PaintTime.clock_cheat(5000.0, 1000.0), "cofnięty zegar wykryty")
	check(PaintTime.clock_cheat(1000.0, 90000.0, 86400.0, 1.0), "skok zegara w trakcie gry wykryty")

	print("Maska farby:")
	var half := Vector2(0.05, 0.02)
	var m := PaintMask.new()
	check(m.coverage() == 0.0 and m.excess() == 0.0, "pusta ściana: 0% pokrycia, brak zacieków")
	m.stamp(Vector2(0.5, 0.0), Vector2(0.5, 1.0), half, 0.75)
	check(absf(m.at(Vector2(0.5, 0.5)) - 0.75) < 0.1, "jedno przejście zostawia ~0,75 warstwy (%.2f)" % m.at(Vector2(0.5, 0.5)))
	check(absf(m.coverage() - 0.1) < 0.02, "pas szerokości 10%% ściany = ~10%% pokrycia (%.3f)" % m.coverage())
	var slow := PaintMask.new()     # ten sam pas w 50 krótkich ruchach (wolna mysz, dużo klatek)
	for i in 50:
		slow.stamp(Vector2(0.5, i / 50.0), Vector2(0.5, (i + 1) / 50.0), half, 0.75)
	check(absf(slow.at(Vector2(0.5, 0.5)) - m.at(Vector2(0.5, 0.5))) < 0.1, "grubość nie zależy od prędkości wałka")
	var diag := PaintMask.new()     # ruch po skosie: środek pasa dostaje tyle samo co przy ruchu pionowym
	diag.stamp(Vector2(0.3, 0.0), Vector2(0.7, 1.0), half, 0.75)
	check(absf(diag.at(Vector2(0.5, 0.5)) - 0.75) < 0.1, "ukośny ruch też zostawia ~0,75 warstwy (%.2f)" % diag.at(Vector2(0.5, 0.5)))
	m.stamp(Vector2(0.5, 0.0), Vector2(0.5, 1.0), half, 0.75)
	check(m.at(Vector2(0.5, 0.5)) > 1.3, "drugie przejście pogrubia powłokę")
	check(m.excess() == 0.0, "dwie warstwy jeszcze nie spływają")
	for i in 3:
		m.stamp(Vector2(0.5, 0.0), Vector2(0.5, 1.0), half, 0.75)
	check(m.excess() > 0.05, "pięć warstw w jednym miejscu = zacieki")
	var full := PaintMask.new()
	full.fill(1.0)
	check(full.coverage() == 1.0, "zamalowana cała ściana = 100%")
	var blocked := PaintMask.new()
	blocked.block(Rect2(0.0, 0.0, 0.5, 1.0))
	check(blocked.coverage() == 0.0, "okno nie liczy się do pokrycia")
	blocked.stamp(Vector2(0.75, 0.0), Vector2(0.75, 1.0), Vector2(0.25, 0.02), 0.75)
	check(blocked.coverage() > 0.98, "pomalowana reszta ściany z oknem = 100%% (%.3f)" % blocked.coverage())
	var copy := PaintMask.new()
	check(copy.load_bytes(m.data.to_byte_array()) and copy.coverage() == m.coverage(), "maska przeżywa zapis i odczyt")
	check(not copy.load_bytes(PackedByteArray([1, 2, 3])), "uszkodzony plik maski jest odrzucany")

	print("Osiągnięcia:")
	var ids := {}
	var texts_ok := true
	for g in Achievements.LIST:
		for a in Achievements.LIST[g]:
			ids[Achievements.key(g, a.id)] = true
			texts_ok = texts_ok and a.title != "" and a.desc != ""
	var total := 0
	for g in Achievements.LIST:
		total += Achievements.LIST[g].size()
	check(ids.size() == total, "identyfikatory osiągnięć są unikalne (%d)" % total)
	check(texts_ok, "każde osiągnięcie ma tytuł i opis")
	check(Achievements.LIST.keys() == Achievements.GAMES.keys(), "każda grupa osiągnięć ma nazwę w menu")
	var sv := ConfigFile.new()
	check(Achievements.count("paint", sv) == 0 and not Achievements.all_done(sv), "pusty zapis: nic nie odblokowane")
	for g in Achievements.LIST:
		if g != "kolekcja":
			for a in Achievements.LIST[g]:
				sv.set_value("ach", Achievements.key(g, a.id), 1.0)
	check(Achievements.all_done(sv), "komplet bez platyny daje platynę")
	check(Achievements.find("paint", "nie_ma_takiego").is_empty(), "nieznane osiągnięcie = pusty wynik")

	print("Wyścig:")
	check(is_equal_approx(Apartment.wrap_delta(-95.0, 100.0), 5.0), "przejście przez metę liczy się do przodu")
	check(is_equal_approx(Apartment.wrap_delta(95.0, 100.0), -5.0), "cofanie przez metę liczy się do tyłu")
	check(is_equal_approx(Apartment.wrap_delta(1.5, 100.0), 1.5), "zwykły ruch bez zmian")

	print("Trasy:")
	var seen := {}
	for mp in RaceMaps.all():
		check(not seen.has(mp.id), "%s: unikalne id" % mp.id)
		seen[mp.id] = true
		var apt := Apartment.new()
		apt.build(mp)
		var probs := TrackCheck.problems(apt)
		check(probs.is_empty(), "%s: trasa poprawna %s" % [mp.id, probs])
		apt.free()
	var bad := MapM4.data()
	bad.builder = MapM4
	bad.path = bad.path.duplicate()
	bad.path[3] = Vector2(21.0, 5.5)            # w środek wyspy kuchennej
	var apt2 := Apartment.new()
	apt2.build(bad)
	check(not TrackCheck.problems(apt2).is_empty(), "walidator łapie linię przez mebel")
	apt2.free()
	var tm := {"id": "test", "name": "T", "place": "", "laps": 1, "size": Vector2(20, 20), "height": 3.0, "env": "open",
		"mood": "dzien", "rooms": [{"rect": Rect2(0, 0, 20, 14), "floor": 6, "a": Color.GRAY, "b": Color.DIM_GRAY, "wall": Color.WHITE, "grip": 1.0}],
		"rugs": [], "walls": [], "water": [{"rect": Rect2(0, 14, 20, 6), "level": -0.8, "color": Color(0.1, 0.2, 0.25)}],
		"path": [Vector2(4, 4), Vector2(10, 3), Vector2(16, 4), Vector2(17, 8), Vector2(16, 11), Vector2(10, 11.5), Vector2(4, 11), Vector2(3, 8)],
		"decor": [["container", 10, 7, 90.0, {}]], "builder": Decor}
	var ta := Apartment.new()
	ta.build(tm)
	var near := false
	for o in ta.obstacles:     # kontener 6 m wzdłuż X obrócony o 90° → 6 m wzdłuż Z: z 4..10
		var lp: Vector2 = (Vector2(10, 10.5) - o.center).rotated(-o.angle)
		near = near or (lp.abs() - o.half).max(Vector2.ZERO).length() < 0.6
	check(near, "obrócony kontener zajmuje miejsce wzdłuż Z")
	check(not TrackCheck.problems(ta).is_empty(), "linia za blisko kontenera / wody jest wykrywana")
	ta.free()

	print("Uszkodzenia kredensu:")
	for ty in Kredens.TYPES:
		var k := Kredens.new()
		k.setup(ty)
		root.add_child(k)
		var nm: String = ty.id
		k.take_hit(Kredens.HIT_LIGHT * 0.9)
		check(k.latched and k.mass == ty.mass, nm + ": uderzenie poniżej progu nic nie zmienia")
		k.take_hit(Kredens.HIT_LIGHT)
		check(not k.latched and k.mass == ty.mass and k.grip_k == 1.0, nm + ": lekkie odblokowuje drzwi, nie rusza masy")
		k.take_hit(Kredens.HIT_MED)
		check(k.mass < ty.mass and k.grip_k == 1.0, nm + ": średnie wyrzuca zawartość (masa %.0f → %.0f)" % [ty.mass, k.mass])
		for i in 8:
			k.take_hit(Kredens.HIT_HARD)
		check(is_equal_approx(k.grip_k, Kredens.GRIP_FLOOR), nm + ": mocne uderzenia zabierają przyczepność do dolnej granicy")
		check(k.mass > ty.mass * 0.4 and k.mass < ty.mass * 0.9, nm + ": wrak jest lżejszy, ale nie pusty (%.0f kg)" % k.mass)
		check(ty.ht <= 0.0 or k.center_of_mass.y < ty.com, nm + ": bez nadstawki środek ciężkości jest niżej")
		k.free()

	print("Turniej:")
	var trng := RandomNumberGenerator.new()
	trng.seed = 5
	var tids := ["m4", "podziemny", "doki", "kanaly", "sklep", "dzialki", "szkola"]
	var picked := Tournament.draw_tracks(tids, trng)
	check(picked.size() == 4, "turniej losuje 4 trasy")
	var uniq := {}
	for p in picked:
		uniq[p] = true
	check(uniq.size() == 4, "trasy bez powtórek")
	var tour := Tournament.new(picked)
	tour.add_race(["P1", "bot:a", "P2", "bot:b"])
	check(tour.points["P1"] == 10 and tour.points["bot:b"] == 3, "punkty 10/7/5/3")
	tour.add_race(["bot:b", "P2", "bot:a", "P1"])
	check(tour.standings() == ["bot:b", "P1", "P2", "bot:a"], "remis rozstrzyga ostatni wyścig")
	check(not tour.done(), "po 2 z 4 wyścigów turniej trwa")
	tour.add_race(["P1", "P2", "bot:a", "bot:b"])
	tour.add_race(["P1", "P2", "bot:a", "bot:b"])
	check(tour.done(), "po 4 wyścigach koniec")

	print("Poczekalnia i sterowanie:")
	var lb := Lobby.new("kb")
	check(lb.handle("kb_a", "join") == "" and lb.slots.size() == 1, "Spacja nie dorabia fantomowego gracza")
	check(lb.handle("kb_b", "join") == "changed" and lb.slots[0].device == "kb_a" and lb.slots[1].device == "kb_b", "prawy Shift dzieli klawiaturę")
	check(lb.handle("kb_b", "leave") == "changed" and lb.slots.size() == 1 and lb.slots[0].device == "kb", "po odejściu P1 znów ma całą klawiaturę")
	check(lb.handle("kb", "accept") == "start", "Enter startuje")
	var lp := Lobby.new("pad0")
	check(lp.handle("pad0", "join") == "start", "A gracza 1 startuje")
	lp.handle("pad1", "join"); lp.handle("kb_a", "join"); lp.handle("pad2", "join")
	check(lp.handle("pad3", "join") == "" and lp.slots.size() == 4, "najwyżej 4 graczy")
	check(lp.handle("pad0", "leave") == "back", "B gracza 1 wraca do wyboru trybu")
	check(lp.slots[1].type_i != lp.slots[0].type_i, "nowy gracz dostaje inny kredens")
	lp.handle("pad1", "right")
	check(lp.focus == 1, "podgląd pokazuje ostatnio zmieniającego")
	check(Lobby.new("kb").race_devices() == ["any"], "jeden gracz jedzie jak dawniej")
	var r2 := RandomNumberGenerator.new()
	var bots := Lobby.bot_types([0, 0, 1], 5, r2)
	check(bots.size() == 1 and bots[0] >= 2, "boty biorą tylko niewybrane typy")
	check(Lobby.bot_types([2], 5, r2).size() == 3, "jeden człowiek + 3 boty")
	var zero := PlayerInput.read("pad7")
	check(zero.throttle == 0.0 and zero.steer == 0.0 and not zero.handbrake, "odłączony pad = zerowe wejście")
	var ev := InputEventKey.new(); ev.physical_keycode = KEY_SPACE; ev.pressed = true
	check(PlayerInput.lobby_event(ev) == ["kb_a", "join"], "Spacja = dołącz WASD")
	var k := Kredens.new()
	var rescued := false
	for i in 31: rescued = k.stuck_high(0.1, 1.0, 0.1)
	check(rescued, "utknięty wysoko wraca po 3 s")
	check(not k.stuck_high(0.1, 1.0, 2.0), "jadący wysoko (np. po rampie) nie jest ratowany")
	k.free()
	var lkp := Lobby.new("kb")
	lkp.handle("pad1", "join")
	check(lkp.race_devices() == ["kb", "pad1"], "P1 na klawiaturze + pad: każdy ma swoje urządzenie")
	Input.action_press("drive_forward")
	check(PlayerInput.read("kb").throttle == 0.0 and PlayerInput.read("any").throttle > 0.0, "kb nie czyta akcji podpiętych pod pady")
	Input.action_release("drive_forward")

	print("WYNIK: ", "OK" if failed == 0 else "%d błędów" % failed)
	quit(1 if failed else 0)
	return true
