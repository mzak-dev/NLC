# Wyścigi kredensów: mapy i tryby — plan wdrożenia

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 7 tras (w tym doki, kanały, parking przed sklepem, parking podziemny) i tryby: szybki wyścig, turniej, do 4 graczy na podzielonym ekranie.

**Architecture:** Mapy to klasy w `games/race/maps/` — każda zwraca dane (`data()`) i dziedziczy po `Decor`, więc trzyma też budowniczych swoich unikalnych dekoracji. `Apartment` stawia świat z danych i rejestruje każdą przeszkodę, a `TrackCheck` sprawdza na tej liście linię jazdy. Każdy gracz-człowiek ma własny `PlayerView` (SubViewport na wspólnym `World3D`, kamera, `RaceFeel`, `RaceHUD`); logika poczekalni, turnieju i wejścia per urządzenie to czyste klasy z testami.

**Tech Stack:** Godot 4.7.2, GDScript, Jolt, Forward+.

**Spec:** `docs/superpowers/specs/2026-11-15-wyscigi-mapy-tryby-design.md`

## Global Constraints

- Tylko GDScript; żadnych pobieranych assetów — geometria z prymitywów, tekstury generowane w kodzie.
- Teksty UI po polsku. Żadnych prawdziwych marek (sklep: „DELIKATESY KREDENS", działki: „ROD Relaks").
- Klucze zapisu M4 bez zmian (bez prefiksu); inne trasy z prefiksem `<id>_`. Nowy klucz `race/cups`.
- Odstęp linii jazdy od przeszkód: domyślnie 1,3 m, klucz mapy `clearance`; M4 = 0,75 (zmierzone 0,77 m od lica ściany).
- Turniej: 4 trasy losowane bez powtórek, punkty 10 / 7 / 5 / 3, remis → lepsze miejsce w ostatnim wyścigu.
- Wyniki 2,5 s po mecie ostatniego człowieka; przy 2+ ludziach limit 45 s od mety pierwszego.
- Stawka zawsze 4 kredensy, boty biorą typy nie wzięte przez ludzi.
- Kolory graczy: 1 `Color(0.86,0.07,0.12)`, 2 `Color(0.15,0.45,0.95)`, 3 `Color(0.98,0.8,0.1)`, 4 `Color(0.2,0.75,0.3)`.
- Podział: 1 — cały ekran; 2 — góra/dół; 3–4 — siatka 2×2 (przy 3 czwarte pole = minimapa + tabela).
- Przy 2+ widokach wyłączone SDFGI, SSIL, SSR, mgła wolumetryczna. Najwyżej 8 świateł z cieniami na trasę.
- Cel: 60 kl./s w 1920×1080 (RX 9070 XT) przy 1 i przy 4 widokach; fallback: `scaling_3d_scale` widoków.
- Sterowanie: patrz Task 2 (tabela klawiszy ze specu).
- **Bez commitów** — repozytorium nie ma jeszcze żadnego commita, commit tylko na prośbę użytkownika. Kroki „Punkt kontrolny" zastępują commity.

Polecenia (Git Bash, z katalogu projektu):

```bash
GODOT="/c/Users/matis/Desktop/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_win64_console.exe"
"$GODOT" --headless --path . --import                                # po dodaniu class_name
"$GODOT" --headless --path . --script res://tests/test_all.gd       # testy logiki → „WYNIK: OK"
"$GODOT" --headless --path . --script res://tests/check_scripts.gd  # parsowanie → same „ok"
"$GODOT" --headless --fixed-fps 120 --path . res://games/race/race.tscn -- --autorace --map=<id>   # → „AUTORACE OK"
"$GODOT" --position -10000,-10000 --path . -- --shot=race --map=<id> [--players=N] [--fps]   # okno poza ekranem → „SHOT <ścieżka png>" [i „FPS <n>"]
```

## Review Focus

1. **Pad odłączony w trakcie wyścigu** — kredens tego gracza staje (zerowe wejście), gra działa dalej. Test w Task 2.
2. **Naciśnięcie, którym wybrano tryb, „przecieka" do poczekalni** jako start lub dołączenie — poczekalnia po wyborze trybu ma dokładnie 1 gracza i stoi. Test w Task 12 (`tests/lobby_flow.gd`).
3. **Kredens utknął na czymś wysokim, nieprzewrócony** (kontener, paleta, dach auta) — po 3 s sam wraca na tor. Test w Task 2.
4. **Kilku graczy wybrało ten sam kredens** — dozwolone, boty biorą wyłącznie typy niewybrane, gracze rozróżnialni znacznikami. Test w Task 2.
5. **Zmiana rozmiaru okna / pełny ekran przy podzielonym ekranie** — widoki zachowują proporcje (kotwice, nie piksele). Test w Task 11.

---

## Struktura plików

| Plik | Odpowiedzialność |
|---|---|
| `games/race/tournament.gd` (nowy) | `Tournament`: losowanie tras, punkty, klasyfikacja |
| `games/race/lobby.gd` (nowy) | `Lobby`: miejsca graczy, dołączanie/odchodzenie, wybór typów, typy botów |
| `games/race/player_input.gd` (nowy) | `PlayerInput`: zdarzenie → (urządzenie, akcja); odczyt jazdy per urządzenie |
| `games/race/kredens.gd` | sterowanie przez `PlayerInput`, ratunek z wody i „z wysoka" |
| `games/race/maps.gd` | `RaceMaps`: tylko lista klas map |
| `games/race/maps/*.gd` (nowe, 7) | `MapM4`, `MapPodziemny`, `MapDoki`, `MapKanaly`, `MapSklep`, `MapDzialki`, `MapSzkola` |
| `games/race/decor.gd` (nowy) | `Decor`: pomocnicy budowy + wspólne dekoracje + modele rekwizytów |
| `games/race/backdrop.gd` (nowy) | `Backdrop`: otoczenie (niebo, światło, mgła, tło, osiedle M4), jakość |
| `games/race/apartment.gd` | budowa z danych: podłogi per pomieszczenie, woda, ściany, progi, extras, rejestr przeszkód |
| `games/race/track_check.gd` (nowy) | `TrackCheck`: walidator trasy |
| `games/race/floor.gdshader` | tryby 6–11 |
| `games/race/skill_chain.gd` (nowy) | `SkillChain`: łańcuch umiejętności jednego gracza |
| `games/race/player_view.gd` (nowy) | `PlayerView`: widok gracza (viewport, kamera, feel, HUD) + `split_rects` |
| `games/race/race_hud.gd` (nowy) | `RaceHUD`: HUD jednego gracza (wydzielony z `RaceUI`) + rysowanie minimapy |
| `games/race/race_ui.gd` | wybór trybu, poczekalnia, odliczanie, wyniki, tabela turnieju |
| `games/race/race_feel.gd`, `speed_fx.gdshader`, `track_fx.gd` | praca per widok |
| `games/race/race.gd` | przebieg: tryb → poczekalnia → wyścigi → wyniki; N ludzi |
| `core/collection.gd` | `--fps` w trybie zrzutów |
| `menu/xmb.gd`, `docs/DESIGN.md` | opisy |
| `tests/test_all.gd`, `tests/check_scripts.gd`, `tests/lobby_flow.gd` (nowy) | testy |

---

### Task 1: Turniej

**Files:**
- Create: `games/race/tournament.gd`
- Test: `tests/test_all.gd`

**Interfaces:**
- Produces:
  - `class_name Tournament extends RefCounted`
  - `const POINTS := [10, 7, 5, 3]`, `const RACES := 4`
  - `var tracks: Array[String]`, `var round := 0`, `var points := {}` (klucz → int), `var last := {}` (klucz → miejsce 1..4 w ostatnim wyścigu)
  - `static func draw_tracks(ids: Array, rng: RandomNumberGenerator, n := RACES) -> Array[String]`
  - `func _init(track_ids: Array[String])`
  - `func add_race(order: Array[String]) -> void` — klucze w kolejności mety
  - `func standings() -> Array[String]`
  - `func done() -> bool`
  - Klucze uczestników: ludzie `"P1"`..`"P4"`, boty `"bot:<id typu>"`.

- [ ] **Step 1: Testy w `tests/test_all.gd` (nowa sekcja „Turniej:")**

```gdscript
var rng := RandomNumberGenerator.new()
rng.seed = 5
var ids := ["m4", "podziemny", "doki", "kanaly", "sklep", "dzialki", "szkola"]
var picked := Tournament.draw_tracks(ids, rng)
check(picked.size() == 4, "turniej losuje 4 trasy")
var uniq := {}
for p in picked: uniq[p] = true
check(uniq.size() == 4, "trasy bez powtórek")
var t := Tournament.new(picked)
t.add_race(["P1", "bot:a", "P2", "bot:b"])
check(t.points["P1"] == 10 and t.points["bot:b"] == 3, "punkty 10/7/5/3")
t.add_race(["bot:b", "P2", "bot:a", "P1"])
check(t.standings() == ["bot:b", "P1", "P2", "bot:a"], "remis rozstrzyga ostatni wyścig")
check(not t.done(), "po 2 z 4 wyścigów turniej trwa")
t.add_race(["P1", "P2", "bot:a", "bot:b"])
t.add_race(["P1", "P2", "bot:a", "bot:b"])
check(t.done(), "po 4 wyścigach koniec")
```

- [ ] **Step 2: Uruchom testy** → FAIL („Tournament" nieznane / błąd parsowania).
- [ ] **Step 3: Zaimplementuj `Tournament`** (sortowanie `standings()` przez `sort_custom`: punkty malejąco, przy równych mniejsze `last`).
- [ ] **Step 4: `--import`, testy** → „WYNIK: OK".
- [ ] **Step 5: Punkt kontrolny** — dopisz `tournament.gd` do `tests/check_scripts.gd`, uruchom → same „ok".

---

### Task 2: Wejście per urządzenie, poczekalnia, ratunki kredensu

**Files:**
- Create: `games/race/player_input.gd`, `games/race/lobby.gd`
- Modify: `games/race/kredens.gd`
- Test: `tests/test_all.gd`

**Interfaces:**
- Produces:
  - Urządzenia (String): `"any"` (jeden człowiek w wyścigu — dzisiejsze akcje, klawiatura + każdy pad), `"kb"` (cała klawiatura, tylko w poczekalni), `"kb_a"` (WASD), `"kb_b"` (strzałki), `"pad<N>"` (N = `InputEvent.device`).
  - `class_name PlayerInput extends RefCounted`
    - `static func read(device: String) -> Dictionary` → `{throttle: float -1..1, steer: float (+ = w lewo), handbrake: bool, reset: bool}`
    - `static func lobby_event(e: InputEvent) -> Array` → `[device, action]` albo `[]`; akcje: `join, leave, accept, back, left, right, up, down, reroll`
    - `static func feed(e: InputEvent) -> void` — śledzi prawy Shift / prawy Ctrl (`InputEventKey.location == KEY_LOCATION_RIGHT`) dla `kb_b`
  - `class_name Lobby extends RefCounted`
    - `const MAX := 4`; `var slots: Array[Dictionary]` (`{device: String, type_i: int}`); `var focus := 0`
    - `func _init(first_device: String, type_i := 0)`
    - `func handle(device: String, action: String) -> String` → `"" | "changed" | "start" | "back" | "track_prev" | "track_next" | "reroll"`
    - `func race_devices() -> Array[String]` — przy 1 graczu `["any"]`
    - `static func bot_types(human_types: Array, n_types: int, rng: RandomNumberGenerator) -> Array[int]` — `4 - human_types.size()` różnych typów spoza `human_types`
  - `Kredens`: `var device := "any"`; `func stuck_high(dt: float, y: float, speed: float) -> bool`

Mapowanie `lobby_event` (kody fizyczne):

| Wejście | Wynik |
|---|---|
| Spacja | `["kb_a","join"]` |
| prawy Shift | `["kb_b","join"]` |
| Q / Delete | `["kb_a","leave"]` / `["kb_b","leave"]` |
| Enter, KP Enter / Backspace / Tab | `["kb","accept"]` / `["kb","back"]` / `["kb","reroll"]` |
| W S A D | `["kb_a", up/down/left/right]` |
| strzałki | `["kb_b", up/down/left/right]` |
| pad A / B / Y | `["padN","join"]` / `["padN","leave"]` / `["padN","reroll"]` |
| pad krzyżak, lewa gałka (próg 0,6, tylko przy przekroczeniu) | `["padN", kierunek]` |

Echa klawiszy ignorowane.

Reguły `Lobby.handle` (P1 = `slots[0]`):
- Gdy P1 to `"kb"`, wszystkie urządzenia klawiaturowe należą do P1, z wyjątkiem `kb_b/join` — to dzieli klawiaturę (P1 → `"kb_a"`, nowy gracz `"kb_b"`). `kb_a/join` przy P1 `"kb"` → `""` (brak fantomowego gracza).
- Gdy P1 to `"kb_a"`: `kb` (Enter/Backspace/Tab) i `kb_a` należą do P1, `kb_b` do drugiego gracza. Gdy `kb_b` odejdzie, P1 wraca na `"kb"`.
- Gdy P1 to pad: Spacja dołącza `"kb_a"`, prawy Shift `"kb_b"`; klawisze `kb` nic nie robią.
- `join` z pada P1 = `start`; `leave` z pada P1 = `back`; `join` z nowego urządzenia przy `slots.size() < MAX` dodaje gracza z `type_i` = pierwszy typ różny od typów pozostałych graczy (jeśli wszystkie wzięte — 0).
- `leave` z urządzenia gracza 2–4 usuwa go; Q/Delete gracza P1 → `""`.
- `left/right` właściciela zmienia jego `type_i` cyklicznie (`Kredens.TYPES.size()`), ustawia `focus`; `up/down/accept/back/reroll` tylko od P1.

- [ ] **Step 1: Testy (sekcja „Poczekalnia i sterowanie:")**

```gdscript
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
```

- [ ] **Step 2: Uruchom testy** → FAIL.
- [ ] **Step 3: Zaimplementuj `PlayerInput`** — `read`: `"any"`/`"kb"` przez akcje `drive_*`, `steer_*`, `handbrake`, `reset_car`; `"kb_a"`: `Input.is_physical_key_pressed` (W S A D, Spacja, R); `"kb_b"`: strzałki + `feed`-owane prawy Shift (ręczny) / prawy Ctrl (postaw); `"padN"`: `Input.get_joy_axis` (RT, LT, LEFT_X ze strefą martwą 0,15), `is_joy_button_pressed` (X, Y).
- [ ] **Step 4: Zaimplementuj `Lobby`** według reguł powyżej.
- [ ] **Step 5: Kredens** — w `_physics_process` wejście człowieka z `PlayerInput.read(device)`, `reset` z wykrywaniem zbocza (poprzedni stan w polu); `if global_position.y < -1.2: reset_to_track()` + „plusk" (`Collection.tone(120, 0.4, 0.3, 0.9)`); `stuck_high`: licznik rośnie, gdy `y > 0.8 and speed < 0.5`, zwraca `true` po > 3,0 s i się zeruje; w każdym innym przypadku licznik = 0; gdy `true` → `reset_to_track()`.
- [ ] **Step 6: `--import`, testy, check_scripts** → OK. Autowyścig M4 (`--map=m4`) → „AUTORACE OK" (sterowanie botów bez zmian).
- [ ] **Step 7: Ręcznie** — sprawdź, że Windows zgłasza `location` dla prawego Shiftu: tymczasowy `print` w `feed` przy jednym uruchomieniu gry, potem usuń. Jeśli `location` przychodzi puste, zamień klawisze `kb_b` na `.` (ręczny) i `/` (postaw) i dołączanie na `.`; zanotuj w specu.

---

### Task 3: Mapy jako klasy, rejestr przeszkód, walidator

**Files:**
- Create: `games/race/decor.gd` (szkielet), `games/race/maps/m4.gd`, `games/race/track_check.gd`
- Modify: `games/race/maps.gd`, `games/race/apartment.gd`, `games/race/race.gd` (tylko odczyt map)
- Test: `tests/test_all.gd`

**Interfaces:**
- Produces:
  - `class_name Decor extends RefCounted`; `var apt: Apartment`; `func _init(a: Apartment)`; `func build(e: Array) -> void` — woła `"k_" + e[0]` przez `has_method`/`call`, nieznany rodzaj → `push_error`.
  - `class_name MapM4 extends Decor` z `static func data() -> Dictionary` (dane M4 bez zmian, poza `"indoor": false` → `"env": "flat"` i nowym `"clearance": 0.8`).
  - `RaceMaps`: `static func classes() -> Array` (na razie `[MapM4]`), `static func all() -> Array` — `c.data()` z dopisanym `"builder": c`.
  - `Apartment`: `var obstacles: Array[Dictionary]` (`{center: Vector2, half: Vector2, angle: float}`), `func add_obstacle(center: Vector2, half: Vector2, angle := 0.0) -> void`, `static func make_curve(path: Array) -> Curve3D` (wydzielone z `build`), `var deco: Decor` (instancja `m.builder`).
  - Konwencja obrotu (wszędzie: auta, dekoracje, przeszkody): kąt w stopniach, 0° = przód na +X, 90° = na +Z; punkt lokalny `l` → świat `pos + l.rotated(deg_to_rad(rot))`; węzeł 3D `rotation.y = -deg_to_rad(rot)`.
  - `class_name TrackCheck extends RefCounted`; `static func problems(apt: Apartment) -> PackedStringArray`.

- [ ] **Step 1: Testy (sekcja „Trasy:")**

```gdscript
var seen := {}
for m in RaceMaps.all():
	check(not seen.has(m.id), "%s: unikalne id" % m.id)
	seen[m.id] = true
	var apt := Apartment.new()
	apt.build(m)
	var probs := TrackCheck.problems(apt)
	check(probs.is_empty(), "%s: trasa poprawna %s" % [m.id, probs])
	apt.free()
var bad := MapM4.data()
bad.builder = MapM4
bad.path = bad.path.duplicate()
bad.path[3] = Vector2(21.0, 5.5)            # w środek wyspy kuchennej
var apt2 := Apartment.new()
apt2.build(bad)
check(not TrackCheck.problems(apt2).is_empty(), "walidator łapie linię przez mebel")
apt2.free()
```

- [ ] **Step 2: Uruchom** → FAIL (`RaceMaps.all()` bez `builder`, brak `TrackCheck`).
- [ ] **Step 3: Przenieś M4** do `maps/m4.gd`; usuń `parking()` i `parking_long()` z `maps.gd` (zastąpi je Task 5); `race.gd` czyta `maps[map_i].get("ceiling", false)` zamiast `indoor` do wysokości kamery (2,0 pod stropem, 2,9 bez).
- [ ] **Step 4: Rejestr przeszkód** — `_static_box` rejestruje każde pudło o górze > 0,05 m (ściany, meble, filary); `_parked_car` rejestruje obrócony prostokąt auta (wymiary z `const CAR_DIMS`); progi i podłogi nie.
- [ ] **Step 5: `TrackCheck.problems`** — próbki linii co 0,5 m: (a) punkt leży w jakimś `rooms[].rect` i w żadnym `water[].rect`; (b) odległość od każdej przeszkody (prostokąt obrócony: punkt do lokalnych współrzędnych, `(abs(p) - half).max(0).length()`) i od każdego prostokąta wody ≥ `m.get("clearance", 1.3)`; (c) żaden pokój nie nachodzi na wodę (pole przecięcia > 0,01); (d) `laps` w 1..5, `path.size() >= 8`. Kolejne złe próbki zlewa w jeden komunikat: `"<id>: 0,92 m od przeszkody przy (x, z), min 1,30"`.
- [ ] **Step 6: `--import`, testy** → OK. Jeśli M4 nie mieści się w 0,8 m: ustaw `clearance` na zmierzone minimum zaokrąglone w dół do 0,05 — **bez ruszania linii jazdy M4** — i popraw liczbę w specu.
- [ ] **Step 7: Punkt kontrolny** — check_scripts (dopisz nowe pliki), autowyścig M4 → OK.

---

### Task 4: Budowniczy świata — otoczenia, woda, nowe nawierzchnie, wspólne dekoracje, licznik FPS

**Files:**
- Create: `games/race/backdrop.gd`
- Modify: `games/race/apartment.gd`, `games/race/decor.gd`, `games/race/floor.gdshader`, `core/collection.gd`
- Test: `tests/test_all.gd`

**Interfaces:**
- Consumes: Task 3 (`Decor`, `add_obstacle`, konwencja obrotu).
- Produces:
  - Klucze danych mapy (pełna lista; nowe pogrubione): `id, name, place, laps, size, height, clearance, wall_style, rooms, rugs, walls, doors, path, humps, furniture, props, pillars, cars, lamps, arrows, lines`, **`env`** (`"flat"|"garage"|"sewer"|"open"|"school"`), **`mood`** (`"swit"|"zmierzch"|"popoludnie"|"dzien"`), **`ground`** (Color terenu wokół), **`ceiling`** (bool), **`water`** (`[{rect: Rect2, level: float, color: Color}]`), **`decor`** (`[[kind, x, z, rot, opts: Dictionary]]`), **`lamp_color`**, **`lamp_energy`**, **`flicker`** (indeksy lamp).
  - Rozszerzenia wpisów: ściana `[x1,z1,x2,z2, h?, style?]` (style: `plain, garage, brick, tile, fence, metal`; przenikanie tylko gdy h > 1,2); próg `[..7 pól.., axis?]` (`"x"` = najazd wzdłuż X: `[x_start, z, szer_wzdłuż_Z, najazd, blat, wys, kolor, "x"]`); rekwizyt `[..7 pól.., kind?]`; linia `[x1,z1,x2,z2, color, width?]` pod dowolnym kątem; auto: rodzaj `"van"`.
  - Tryby podłogi: 0 parkiet, 1 kafelki, 2 wykładzina, 3 panele, 4 dywan, 5 asfalt, **6 płyty betonowe, 7 żwir, 8 trawa, 9 blacha ryflowana, 10 lastryko, 11 kostka brukowa**.
  - `class_name Backdrop extends RefCounted`; `static func build(apt: Apartment, m: Dictionary) -> Environment`; `static func set_quality(env: Environment, full: bool) -> void`. `Apartment.env: Environment`.
  - `Apartment.take_shadow() -> bool` (budżet 8).
  - `Decor` — pomocnicy: `root(e: Array) -> Node3D`, `solid(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> void` (kolizja + mesh + przeszkoda w świecie), `box(parent, size, pos, m) -> MeshInstance3D`, `cyl(parent, r, h, pos, m) -> MeshInstance3D`, `mat(c: Color, rough := 0.7, metal := 0.0) -> StandardMaterial3D` (z pamięcią podręczną po kolorze), `label(parent, text, size, pos, color) -> Label3D`, `lamp(parent, pos, color, energy, range, shadow_wanted) -> OmniLight3D`; `static func prop_model(kind: String, size: Vector3, color: Color) -> Node3D`.
  - Wspólne rodzaje `k_*`: `tree, bush, streetlamp, container (opts: stack 1–3, color), pipe (opts: len, r, y — bez kolizji), sign (opts: text), bench, barrier (słupki bez kolizji na torze + belka-rekwizyt o masie 2, startuje uśpiona, na wys. 1,0), neon (opts: text, color)`.
  - Modele rekwizytów: `box` (domyślny), `cone, barrel, crate, pallet, cart, chair, ball, gnome, tire, wet_sign`.
  - `Collection`: `--fps` w trybie zrzutów (V-Sync wyłączony, średnia z 3 s przed zrzutem, linia `FPS <n>`).

- [ ] **Step 1: Testy (dopisz do sekcji „Trasy:")**

```gdscript
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
```

- [ ] **Step 2: Uruchom** → FAIL.
- [ ] **Step 3: `Backdrop`** — przenieś `_environment`, `_quality`, `_estate` z `Apartment`. `flat` = dzisiejsze M4 z osiedlem. `garage` = dzisiejszy parking. `sewer` = jak garaż, ciemniej (ambient 0,15), mgła wolumetryczna zielonkawa (gęstość ~0,03). `open`: niebo proceduralne + słońce z cieniami według `mood` (świt: nisko, chłodne, mgła 0,02; zmierzch: słońce 0,3, pomarańczowy horyzont, granatowe niebo; popołudnie: ciepłe 1,6; dzień: neutralne 1,4), teren `ground` po horyzont (y = −0,02). `school` = `open`, tylko bez osiedla. `set_quality(env, false)` wyłącza SDFGI, SSIL, SSR, mgłę wolumetryczną; `true` przywraca.
- [ ] **Step 4: `Apartment`** — podłoga z kolizją per pomieszczenie (zamiast jednej płyty); woda: tafla (przezroczysty materiał, połysk, normal mapa szumu) na `level` + betonowe ściany studni pod krawędzią pokoi, górą na −0,01; prostokąty wody → `add_obstacle`. Ściany z wysokością i stylem. Progi z osią. Strop, lampy sufitowe (z `lamp_color`, `lamp_energy`, migotanie w `_process` dla `flicker`), filary, auta, strzałki — dla każdej mapy z `ceiling`; linie i auta dla każdej mapy. Strzałki bez stropu malowane na podłodze. Cienie lamp tylko przez `take_shadow()` (co 6. lampa chce cienia). Rekwizyty z `Decor.prop_model`. Dekoracje: `deco.build(e)` dla każdego wpisu `decor`.
- [ ] **Step 5: `floor.gdshader`** — tryby 6–11 (płyty 2×2 m z fugą i plamami; żwir drobne ziarna; trawa szum dwóch zieleni; blacha ryflowana wzór rombów, metal; lastryko odpryski na jasnym tle; kostka 0,2×0,1 m w cegiełkę).
- [ ] **Step 6: `Decor`** — pomocnicy i wspólne rodzaje (materiały z pamięci podręcznej — mniej wywołań rysowania).
- [ ] **Step 7: `Collection --fps`**.
- [ ] **Step 8: `--import`, testy, check_scripts, autowyścig M4** → OK. Zrzut M4 (`--shot=race --map=m4 --fps`) — obejrzyj: wygląda jak przed zmianą; zanotuj FPS jako punkt odniesienia.

---

### Trasy: wspólne kroki zadań 5–10

Wspólne kroki każdej trasy (Task N):

**Files:** Create `games/race/maps/<id>.gd` (`class_name Map<Nazwa> extends Decor`, `static func data()`, unikalne `k_*`); Modify `games/race/maps.gd` (dopisz klasę do `classes()`).

- [ ] **Step 1:** Dopisz klasę do `RaceMaps.classes()` z minimalnym `data()` (pokoje + obrys + linia jazdy) → testy: walidator przechodzi albo pokazuje konkretne kolizje.
- [ ] **Step 2:** Zbuduj trasę według opisu poniżej: nawierzchnie, ściany, przeszkody, dekoracje, rekwizyty, tło.
- [ ] **Step 3:** Testy → „<id>: trasa poprawna" ok.
- [ ] **Step 4:** Autowyścig `--map=<id>` → „AUTORACE OK", wywrotki ≤ 2 na bota; w razie porażki popraw linię jazdy lub rozstaw (nie bota).
- [ ] **Step 5:** Zrzut `--shot=race --map=<id> --fps` oraz `--shot=race_select --map=<id>` — obejrzyj: trasa czytelna, detale widać, nic nie lewituje / nie przenika; FPS ≥ 60 (inaczej: mniej cieni, wspólne materiały).
- [ ] **Step 6: Punkt kontrolny** — testy + check_scripts.

#### Task 5: `podziemny` — Parking podziemny −2 (`MapPodziemny`)
60×40, 2 okr., `env: garage`, `ceiling`, wys. 3,4. Bazą jest układ dawnego `parking_long` (pas północny → pętla wokół pomieszczenia technicznego → dwie alejki z nawrotami → pas południowy → pas zachodni). Nowe: garb-rampa 0,35 m (próg, oś `x`) na pasie północnym; 2 × `barrier` (wyjazd z pasa północnego, pas zachodni); myjnia na pasie południowym (dywan przyczepności 0,45 z pianą + `k_carwash`: brama ze szczotkami nad torem, nogi poza torem); plama oleju; `k_booth` (budka parkingowego przy starcie); rury pod stropem (`pipe`); `k_exit_sign` (zielone znaki); 1 migająca lampa; porzucony `cart`. Numery miejsc (`label` na podłodze) i żółte osie.

#### Task 6: `doki` — Doki portowe (`MapDoki`)
ok. 70×46, 2 okr., `env: open`, `mood: swit`, `ground` ciemny beton. Woda: pas przy południowej krawędzi (nabrzeże bez barierek, linia jazdy ≥ 1,3 m od wody). Trasa: start na północnej drodze (asfalt 1,15) → na wschód wzdłuż stosów kontenerów → przez halę magazynową (ściany z szerokimi wrotami, beton 0,9, `k_rack` z paletami, `k_forklift`) → wyjazd na południe → na zachód wzdłuż nabrzeża (mokre płyty 0,7, `k_bollard` co ~6 m na krawędzi) pod `k_gantry` (suwnica: nogi poza torem, belka nad torem) i po stalowych płytach (0,6) → przejazd przez tory (2 niskie progi `x` + `k_rails`) → na północ labiryntem kontenerów (esek) → start. Obrys: płot/kontenery na N, E, W. Tło (poza planem, bez kolizji na torze): `k_ship` (kadłub ~60 m za wodą), `k_crane` (żurawie), morze po horyzont. Rekwizyty: beczki, skrzynie, palety, pachołki.

#### Task 7: `kanaly` — Kanały (`MapKanaly`)
ok. 56×36, 3 okr., `env: sewer`, `ceiling` 3,0, `wall_style: tile`, lampy pomarańczowe (`lamp_color`). Pierścień tuneli: w każdym ściek pośrodku (woda, poziom −0,6, szer. ~2,5 m) i chodniki 3,5–4 m po obu stronach (beton, obrzeża). Trasa: chodnikami, z przejazdami na drugą stronę po `k_grate_bridge` (kładka: pokój z blachą 0,6 nad wodą + balustrady — ściany `metal` h 1,0), najmniej 3 przejazdy. Komora zbiorcza (ok. 18×18) z filarami, gdzie jest szeroko. Szlam (dywany 0,4, zielonkawe), `pipe` wzdłuż ścian, kratki ściekowe (linie), `k_manhole` (jasny krąg w stropie + SpotLight w dół, cień przez `take_shadow`), beczki, kartony.

#### Task 8: `sklep` — Parking przed sklepem (`MapSklep`)
ok. 64×44, 3 okr., `env: open`, `mood: zmierzch`. `k_store` w północno-środkowej części: bryła sklepu z fasadą na południe, `neon` „DELIKATESY KREDENS", przeszklone wejście (kolizja całej bryły). Trasa wokół sklepu: przed fasadą (`k_cart_shelter` z wózkami) → bokiem → za sklepem wąska droga dostaw (rampa — próg, `van` i palety) → drugim bokiem → slalom między rzędami miejsc (auta, `k_island`: krawężnik h 0,15 + trawa + drzewko) → start. Asfalt 1,15, chodniki z kostki 1,0, kałuże (0,45), progi zwalniające, przejście dla pieszych (linie). `streetlamp` świecące (cienie przez budżet), luźne wózki `cart` (lekkie, ~10 szt.), `k_clothes_bin`, `k_parcel_locker`, `k_bike_rack`, `k_chicken_stand` (budka z kurczakiem z rożna). Obrys: krawężniki/ogrodzenie, za nim ulica i bloki (`flat`-owe fasady z `Backdrop` nie są potrzebne — wystarczą bryły `k_block`).

#### Task 9: `dzialki` — Ogródki działkowe (`MapDzialki`)
ok. 60×44, 2 okr., `env: open`, `mood: popoludnie`, `ground` zielony. Siatka działek ogrodzonych płotem (`fence` h 1,0), alejki żwirowe (0,8) 4–5 m. Start przy `k_gate` („ROD Relaks"). Trasa krętymi alejkami, co najmniej jeden odcinek przez trawę (0,65) i róg z grządkami (ziemia, tryb 7 w brązach, 0,5). Na działkach (za płotem): `k_shed` (altanki), `k_greenhouse`, `k_compost`, `tree`, `bush`. Przy alejkach: beczki na deszczówkę, kałuża przy wężu (0,45). Rekwizyty: taczki (`box`), `gnome`, `chair` (leżaki).

#### Task 10: `szkola` — Szkoła (`MapSzkola`)
ok. 56×36, 3 okr., `env: school`, `mood: dzien`, bez stropu, `wall_style: plain`. Pomieszczenia: korytarz (lastryko 0,95) z `k_lockers` i ławkami, szatnia z boksami (`k_cloak`), sala gimnastyczna (parkiet lakierowany 0,7, linie boiska jako `lines`, `k_wall_bars`, `k_goal`, `k_vault`, materace = dywany 1,5 + model), stołówka (stoły `k_table`, krzesła `chair`), świeżo umyta podłoga (0,4 + `wet_sign`). Trasa przechodzi przez wszystkie cztery strefy, salę objeżdża pętlą. Piłki lekarskie (`ball`, ciężkie). Wokół budynku boisko i fasada szkoły (`k_school_facade`).

---

### Task 11: Podzielony ekran

**Files:**
- Create: `games/race/skill_chain.gd`, `games/race/player_view.gd`, `games/race/race_hud.gd`
- Modify: `games/race/race.gd`, `games/race/race_ui.gd`, `games/race/race_feel.gd`, `games/race/speed_fx.gdshader`, `games/race/track_fx.gd`, `games/race/apartment.gd`
- Test: `tests/test_all.gd`

**Interfaces:**
- Consumes: `PlayerInput`, `Kredens.device`, `Backdrop.set_quality`, `Apartment.env`.
- Produces:
  - `class_name SkillChain extends RefCounted`: `const TIMEOUT := 2.5`; `var pts, mult, last, total, banked`; `func step(dt: float, airborne: bool, speed: float, side: float, grip: float) -> String` (zwraca nazwę bieżącej umiejętności albo `""`; `banked` > 0 w kroku, w którym łańcuch został zaliczony); `func flush() -> int`. Progi i stawki — z dzisiejszego `race.gd::_skills`.
  - `class_name PlayerView extends Node`: `const COLORS := [...]` (Global Constraints); `static func split_rects(n: int) -> Array[Rect2]` (znormalizowane: 1 → całość; 2 → góra, dół; 3–4 → ćwiartki LG, PG, LD, PD); `func setup(world: World3D, idx: int, rect: Rect2, n_views: int, view_layer: CanvasLayer, fx_layer: CanvasLayer, hud_layer: CanvasLayer) -> void`; `func follow(car: Kredens, dt: float, high: float, racing: bool) -> void`; `var cam: Camera3D`, `var hud: RaceHUD`, `var feel: RaceFeel`.
  - `class_name RaceHUD extends Control`: przeniesione z `RaceUI` (`hud_update`, `checkpoint`, `skill`, `skill_bank`, `flash`, `set_map`); nowe `func build(compact: bool, color: Color)`, `func info(text: String)` (trwały napis, np. odliczanie limitu); `static func fmt_time(t) -> String`, `static func font(weight: int) -> Font`, `static func draw_track(ctl: Control, map: Dictionary, curve: Curve3D, dots: Array, with_walls: bool)`; kropki `{pos, dir, color}`.
  - `TrackFX`: `func add_line(idx: int, a_lat: float, decel: float) -> void`, `func update_line(idx: int, off: float, speed: float)`, `func fade_gates(cams: Array[Vector3])`; linia gracza `idx` na warstwie renderowania bit `10 + idx`.
  - `Apartment.update_fade(pairs: Array, dt: float)` — `pairs = [[kamera, cel], ...]`, ściana półprzezroczysta, gdy zasłania któregokolwiek.
  - `RaceFeel.setup(camera: Camera3D, fx_rect: ColorRect, volume_db: float)`.
  - `race.gd`: `var humans: Array[Dictionary]` (`{slot, device, racer, view, chain: SkillChain, cp_i, cp_lap, splits, best_splits}`); racer dostaje `human: int` (−1 = bot) i `key: String` (`"P1"`.., `"bot:<id>"`); argument `--players=N` (zrzuty: N ludzi na autopilocie, pady `pad0..`).

Układ warstw: `view_layer` 0 (SubViewportContainery), `fx_layer` 1 (prostokąty `speed_fx` — wszystkie po widokach, bo ekran do shadera kopiuje się raz przy pierwszym użyciu), `hud_layer` 2 (HUD-y), `RaceUI` 3. Widoki pozycjonowane **kotwicami** z `split_rects` (nie pikselami). SubViewport: `world_3d` wspólny, `msaa_3d` z ustawień projektu, `positional_shadow_atlas_size = 4096`; w wyścigu główny viewport `disable_3d = true` (w poczekalni `false` — tło jedzie po trasie jak dziś). HUD skalowany `s = clamp(h_widoku / 1080, 0.7, 1.0)`, rozmiar logiczny = rozmiar widoku / s; `compact` (2+ widoki) bez tabeli pozycji i paska podpowiedzi. Przy 3 widokach czwarta ćwiartka: duża minimapa + tabela (`RaceUI.show_overview`). Kamera gracza `cull_mask` wyklucza bity 10–13 poza własnym. Nad kredensem każdego człowieka (przy 2+ graczach) `Label3D` „G1".."G4" w kolorze gracza, billboard. `speed_fx`: geometria efektu z `UV` prostokąta (środek widoku), próbki ekranu z `SCREEN_UV` z przesunięciem przeskalowanym przez `uniform vec2 view_size` (znormalizowany rozmiar widoku). Dźwięk `RaceFeel`: `volume_db = -8 - 3 * (n - 1)`.

- [ ] **Step 1: Testy (sekcja „Podzielony ekran:")**

```gdscript
check(PlayerView.split_rects(1) == [Rect2(0, 0, 1, 1)], "1 gracz: cały ekran")
check(PlayerView.split_rects(2) == [Rect2(0, 0, 1, 0.5), Rect2(0, 0.5, 1, 0.5)], "2 graczy: góra/dół")
check(PlayerView.split_rects(4)[3] == Rect2(0.5, 0.5, 0.5, 0.5), "4 graczy: ćwiartki")
check(PlayerView.split_rects(3).size() == 3, "3 graczy: trzy ćwiartki")
var ch := SkillChain.new()
for i in 10: ch.step(0.1, false, 4.0, 2.0, 1.0)
check(ch.last == "POŚLIZG BOKIEM" and is_equal_approx(ch.pts, 150.0), "poślizg nalicza 150/s")
for i in 10: ch.step(0.1, true, 4.0, 0.0, 1.0)
check(is_equal_approx(ch.mult, 1.5) and is_equal_approx(ch.pts, 550.0), "nowa umiejętność podbija mnożnik")
var got := 0
for i in 26:
	ch.step(0.1, false, 1.0, 0.0, 1.0)
	got = maxi(got, ch.banked)
check(got == 825 and ch.total == 825, "cisza 2,5 s zalicza łańcuch")
```

- [ ] **Step 2: Uruchom** → FAIL.
- [ ] **Step 3: `SkillChain`** (wydziel z `race.gd`), **`RaceHUD`** (wydziel z `RaceUI`; `RaceUI` używa `RaceHUD.fmt_time/font/draw_track`), **`PlayerView`**, zmiany `RaceFeel`, `speed_fx`, `TrackFX`, `Apartment.update_fade`.
- [ ] **Step 4: `race.gd`** — wyścig z N ludźmi: siatka startowa (ludzie z końca stawki, losowo), widoki, linie, punkty kontrolne, łańcuchy i komunikaty per człowiek; tabela/kropki z kolorami; `Backdrop.set_quality(apt.env, humans.size() <= 1)` przy starcie i powrocie do poczekalni; dotychczasowy ekran wyboru i wyniki działają dla gracza 1 (pełna poczekalnia w Task 12). `_input` przekazuje zdarzenia do `PlayerInput.feed`.
- [ ] **Step 5: `--import`, testy, check_scripts, autowyścig M4 i `doki`** → OK.
- [ ] **Step 6: Zrzuty** `--shot=race --map=sklep --players=1|2|3|4 --fps` — obejrzyj: każdy widok ma swój HUD i swoją linię jazdy, efekty prędkości wyśrodkowane w widoku, przy 3 graczach ćwiartka podglądu. FPS ≥ 60 przy 1 i 4; jeśli 4 widoki < 60 → `scaling_3d_scale = 0.75` dla widoków przy 3–4 graczach, zmierz ponownie.
- [ ] **Step 7: Okno** — uruchom `--shot=race --players=4` z `--resolution 1280x720` i obejrzyj: widoki w tych samych proporcjach (Review Focus 5).

---

### Task 12: Wybór trybu i poczekalnia

**Files:**
- Modify: `games/race/race.gd`, `games/race/race_ui.gd`
- Create: `tests/lobby_flow.gd`

**Interfaces:**
- Consumes: `Lobby`, `PlayerInput.lobby_event`, `Tournament.draw_tracks`, `RaceHUD.draw_track`.
- Produces:
  - `race.gd`: `enum S { MODE, LOBBY, COUNTDOWN, RACE, RESULTS }`, `var mode := "quick"` (`"quick" | "cup"`), `var lobby: Lobby`, `var cup_tracks: Array[String]`.
  - `RaceUI`: `func show_modes(cups: int)`, `func set_mode(i: int)`, `func show_lobby(mode: String)`, `func set_lobby(d: Dictionary)` — `d = {slots: [{color, label, device_text, type_name}], focus_type: Dictionary, stats: Dictionary, track: {name, map, curve} (quick) | tracks: Array[String] (cup), hints: Array}`.

Przebieg: wejście do gry → ekran trybów (dwa kafelki „Szybki wyścig" / „Turniej", ← → wybór; liczba pucharów) → zatwierdzenie dowolnym urządzeniem (`accept` albo `join`) tworzy `Lobby(urządzenie)` (`kb_*` → `"kb"`), zdarzenie oznaczone jako obsłużone, przejście do poczekalni. Poczekalnia = dzisiejszy ekran wyboru (podgląd kredensu i osiągi gracza `focus`, karta trasy) + pas 4 kart graczy na dole w miejscu karuzeli (kolor, „GRACZ N", urządzenie, kredens, „◀ ▶"; puste: „Dołącz: pad A · Spacja · prawy Shift"; pod zajętą: „Odejdź: B / Q / Delete"). Szybki wyścig: trasa ↑↓ (P1). Turniej: lista 4 tras + „Tab / Y — losuj ponownie". `start` → wyścig (szybki: wybrana trasa; turniej: Task 13). `back` → ekran trybów. Szybki wyścig, wyniki: „Jeszcze raz" / „Zmień ustawienia" (poczekalnia, gracze zostają) / „Wróć do menu". Zrzut `--shot=race_select` pokazuje poczekalnię (z `--players=N` — N kart zajętych).

- [ ] **Step 1: Test przepływu `tests/lobby_flow.gd`** (`extends SceneTree`, ładuje `race.tscn`, czeka 2 klatki, wysyła `Input.parse_input_event` naciśnięcie i puszczenie pada A na urządzeniu 0, czeka 3 klatki):

```gdscript
check(race.state == race.S.LOBBY, "A na ekranie trybów otwiera poczekalnię")
check(race.lobby.slots.size() == 1 and race.lobby.slots[0].device == "pad0", "to samo naciśnięcie nie startuje ani nie dołącza")
# drugie naciśnięcie A tym samym padem → COUNTDOWN
```

Uruchomienie: `"$GODOT" --headless --path . --script res://tests/lobby_flow.gd` → `WYNIK: OK`.

- [ ] **Step 2: Uruchom** → FAIL.
- [ ] **Step 3: Zaimplementuj** ekran trybów, poczekalnię w `RaceUI`, obsługę w `race.gd` (`_input` → `PlayerInput.lobby_event` → `lobby.handle`; ustawianie urządzeń kredensów z `lobby.race_devices()`; boty z `Lobby.bot_types`).
- [ ] **Step 4: Testy, lobby_flow, check_scripts** → OK.
- [ ] **Step 5: Zrzuty** `--shot=race_select --players=1` i `--players=3` — obejrzyj: karty czytelne, podpowiedzi zgodne z regułami.
- [ ] **Step 6: Ręcznie (użytkownik)** — 1 gracz klawiaturą: tryb → Enter → jazda jak dawniej (WASD i strzałki); 2 graczy na klawiaturze; pad + klawiatura.

---

### Task 13: Turniej, koniec wyścigu, wyniki, zapis

**Files:**
- Modify: `games/race/race.gd`, `games/race/race_ui.gd`, `menu/xmb.gd`, `docs/DESIGN.md`

**Interfaces:**
- Consumes: `Tournament`, `humans`, `racer.key`.
- Produces:
  - `race.gd`: `var cup: Tournament` (null w szybkim), `var cutoff_t := -1.0`; boty turnieju mają stałe typy na cały turniej (wylosowane przy starcie).
  - `RaceUI.show_results(rows: Array, info: Dictionary, actions: Array)` — `rows = [{name, time, color (null = bot), points (turniej) }]`; `info = {title, big, sub, best, skill, note, standings: [{name, color, points}] | null}`; `actions = [[tekst, Callable], ...]`.

Zasady:
- Koniec wyścigu: wszyscy ludzie na mecie → wyniki po 2,5 s. Przy 2+ ludziach meta pierwszego ustawia `cutoff_t = race_t + 45`; HUD niedojechanych: `info("Koniec za %d s")`; po czasie wyniki, niedojechani według postępu (`_order` bez zmian). Przy 1 człowieku bez limitu.
- Lewy kafelek wyników: 1 człowiek — „TWOJE MIEJSCE" + miejsce; kilku — „NAJLEPSZY GRACZ" + „Gracz N — miejsce".
- Turniej: po wyścigu klasyfikacja wyścigu z punktami + kafelek tabeli turnieju; akcje „Następny wyścig" / „Przerwij turniej" (→ poczekalnia, turniej przepada). Po 4. wyścigu plansza zwycięzcy (duży napis „ZWYCIĘZCA TURNIEJU" + nazwa + tabela) i akcje „Nowy turniej" / „Wróć do menu". Wyjście pauzą do menu = turniej przepada.
- Nazwy: 1 człowiek → nazwa kredensu (jak dziś); kilku → „Gracz N" (wyniki: „Gracz N — <kredens>").
- Zapis (każdy tryb, dowolny człowiek): `best_<typ>` i `best_lap_any` z najlepszego okrążenia każdego człowieka; `wins_<typ>` gdy człowiek wygrał wyścig; `cups` += 1, gdy turniej wygrał człowiek. Notatka „NOWY REKORD TORU — Gracz N".
- XMB: opis gry „Siedem tras, pięć kredensów, do czterech graczy na jednej kanapie."; dodatkowa linia „Puchary: N" gdy > 0; tekst „O kolekcji": „…kredensy na kółkach meblowych, siedem tras, turniej i gra na podzielonym ekranie."
- `docs/DESIGN.md`: multiplayer wypada z nie-celów; sekcja 3 dostaje listę tras i trybów z odesłaniem do specu.

- [ ] **Step 1:** Zaimplementuj przebieg turnieju i koniec wyścigu w `race.gd`.
- [ ] **Step 2:** `RaceUI.show_results` z tabelą turnieju i planszą zwycięzcy.
- [ ] **Step 3:** Zapis + XMB + DESIGN.md.
- [ ] **Step 4:** Testy, lobby_flow, check_scripts → OK.
- [ ] **Step 5:** Zrzuty `--shot=race_results --players=2` i `--shot=race_results --mode=cup --players=2` (zrzut ustawia turniej po 1 wyścigu) — obejrzyj.

---

### Task 14: Weryfikacja końcowa

- [ ] **Step 1:** `--import`, `test_all`, `check_scripts`, `lobby_flow` → wszystko OK.
- [ ] **Step 2:** Autowyścig na każdej z 7 tras → 7 × „AUTORACE OK" (wypisz czasy i wywrotki).
- [ ] **Step 3:** Zrzuty każdej trasy (1 gracz) i `sklep` / `doki` przy 4 graczach z `--fps`; zbierz FPS w tabeli. Każda wartość ≥ 60 albo zapisz, czego brakuje.
- [ ] **Step 4:** Raport dla użytkownika: co działa, FPS, czego nie dało się sprawdzić bez ludzi (gra 2–4 osób na prawdziwych urządzeniach, rozróżnianie prawego Shiftu).
