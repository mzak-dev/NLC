# NRGeek Legacy Collection — projekt i plan

## Kontekst
NRGeek (kanał YT o retro, recenzjach i „najgorszych grach”) kiedyś prosił o takie gry i nikt nie odpowiedział. Robimy odpowiedź: jedna gra w Godocie, menu w stylu XMB z PS3 (dark mode, kolory logo: czerwień / czerń / biel), trzy absurdalne gry jako kafelki. Folder projektu jest pusty. Godot 4.7.2 (bez Mono): `C:\Users\matis\Desktop\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_win64_console.exe`.

**Cele:** klimat PS3 (płynna fala, dźwięki nawigacji, zegar), trzy grywalne gry, humor w stylu kanału, postęp zapisywany.
**Nie-cele:** multiplayer, eksport/instalator (później), modele z Blendera, lokalizacja EN.
**Anty-cele:** żadnych assetów Sony (logo, ikon, dźwięków, fontów) — tylko styl; żadnego C++ (decyzja: wszystko GDScript, C++ dopiero gdy profiler pokaże potrzebę).

## Decyzje użytkownika
- Wyścigi: gracz + **3 boty AI**, kilka okrążeń.
- Farba: **wybór farby, realny czas schnięcia**, liczy się też przy zamkniętej grze.
- **Tylko GDScript.**
- Jazda: **B — kredensy na kółkach meblowych** (`VehicleBody3D` + `VehicleWheel3D`).
- Ściany: **pełne 2,8 m + przenikanie** — ściany zasłaniające kredens robią się półprzezroczyste.
- Całość kodu piszę ja (bez punktów „Twój wkład”).
- Zapis wyścigu: najlepsze okrążenie i wygrane per typ kredensu, bez odblokowań.

## Moje decyzje (do korekty)
- UI po polsku; font systemowy (`SystemFont` „Segoe UI”), bez pobierania.
- Cała geometria (pokoje, kredensy, klamka, pędzel) generowana w kodzie z prymitywów; `.tscn` to tylko korzeń + skrypt.
- Przenikanie ścian: ściany to segmenty z danych, każdy z własnym materiałem; co klatkę test przecięcia 2D (XZ) odcinka kamera→kredens gracza z segmentami, trafione tweenują alfę do ~0,25. Bez sufitu. Kamera: wygładzony pościg bez SpringArm (zasłanianie załatwia przenikanie).
- Przewracanie (skutek wyboru B) jest cechą, nie bugiem: `wheel_roll_influence` + wysokość środka masy per typ = statystyka „Stabilność”. Auto-postawienie po 1,5 s do góry nogami / na boku (respawn na ostatnim checkpoincie), ręcznie klawisz **R**.
- Kółka: promień fizyczny `VehicleWheel3D` większy (~8–10 cm) niż widoczne kółko meblowe, sensowny skok zawieszenia — inaczej zahaczają o łączenia i dywany.
- Warstwy kolizji: 1 podłoga/ściany, 2 kredensy, 3 rekwizyty (krzesła, buty). Maska kredensu = 1|2 (promienie kół nie trafiają rekwizytów), maska rekwizytów = 1|2|3 → kredens pcha rekwizyty jednostronnie.
- Fizyka 3D: Jolt ustawiony jawnie (`physics/3d/physics_engine`), 120 Hz.
- `.gitignore`: `.godot/`, `.remember/`.

## Approaches (rozważone)
- Jazda: A ślizgający się mebel (arcade, stabilny) / **B VehicleBody3D na kółkach (wybrane — fizyczna komedia, ryzyko wywrotek opanowane powyżej)** / C kinematyka (bez przepychania).
- Architektura: **jeden projekt, każda gra = scena, wspólny autoload (wybrane)** / osobne projekty + launcher (4 eksporty, brak wspólnego UI — odrzucone).
- Język: **GDScript (wybrane)** / GDExtension C++ (build godot-cpp+scons, DLL — zbędne dla ~30 linii fizyki).

## Struktura plików
```
project.godot, icon.svg, docs/DESIGN.md (kopia tej sekcji projektu)
core/collection.gd          autoload: save (ConfigFile user://save.cfg), ustawienia, go_to() z fade, pauza Esc w grach, sfx (AudioStreamWAV generowany), tryb --shot
menu/xmb.tscn, xmb.gd, xmb_wave.gdshader, icons/*.svg (własne białe ikony liniowe)
games/klamka/klamka.tscn, klamka.gd, handle_sim.gd (czysta fizyka, RefCounted)
games/race/race.tscn, race.gd (stany: wybór → odliczanie → wyścig → wyniki, HUD, checkpointy, pozycje)
games/race/kredens.gd       VehicleBody3D: budowa modelu z typu, sterowanie gracz/bot, auto-postawienie
games/race/apartment.gd     budowa mieszkania z danych + ścieżka Curve3D + checkpointy
games/race/floor.gdshader   parkiet / kafelki / wykładzina / panele (uniform trybu)
games/paint/paint.tscn, paint.gd, paint_wall.gdshader, paint_time.gd (czysta logika czasu),
games/paint/paint_mask.gd (grubość farby, czysta logika), paint_props.gd (rekwizyty), loading.gd (ekran ładowania)
core/achievements.gd        lista osiągnięć + czysta logika (odblokowuje Collection.unlock)
tests/test_all.gd           SceneTree, asserty, uruchamiany headless
```

## 1. Menu XMB
```
                                                  14.11  01:42
  [Ustawienia]   ( GRY )   [Informacje]        <- kategorie poziomo
                  Symulator schnięcia farby    <- zaznaczony: większy, jasny + opis
                  Wyścigi kredensów               i „na żywo” z save (np. „Emulsja: 34 min do końca”)
                  Symulator naciskania klamki
  tło: ciemny gradient (czerń → głęboka czerwień) + 2–3 półprzezroczyste fale z poświatą + iskry
```
- Tło: `ColorRect` + shader canvas_item (warstwy sinusów, miękka krawędź, hash-owe iskry), jasność lekko zależna od godziny (ukłon w PS3). Punkt startowy matematyki: port „Playstation Waves” (godotshaders).
- Kategorie: **Gry** (3), **Ustawienia** (głośność ←/→, pełny ekran, V-Sync), **Informacje** (O kolekcji, Autorzy, ksiazkanrgeek.pl → `OS.shell_open`).
- Nawigacja: strzałki/WASD/pad; Enter/Spacja/A — wejdź; Esc/Backspace/B — wstecz. Tweeny skali/alfy, dźwięki blip/confirm, krótkie intro „NR GEEK” (własny tekstowy znak) z wezbraniem fali, fade do gry.
- W każdej grze Esc → pauza z autoloadu: „Wznów / Wróć do menu”.

## 2. Symulator naciskania klamki
- Scena 3D: drzwi (płyta + ościeżnica), szyld, klamka mosiężna (prymitywy), widoczny zatrzask na krawędzi drzwi wysuwany proporcjonalnie do kąta. Kamera zbliżenie, PPM = lekki orbit.
- Model (`handle_sim.gd`, kąt θ w dół, 0 = spoczynek): `I·θ'' = F·r − k·(θ + θ_pre) − c·θ' − τ_tarcia·sign(θ')`; ograniczniki θ=0 i θ_max≈45° z restytucją `e` (odbicie θ' = −e·θ', liczone jako odbicie gdy |θ'| > próg). Całkowanie semi-implicit Euler, 16 podkroków na tick fizyki.
- Tryb **Ręcznie**: przeciąganie myszą w dół po klamce = siła; puszczenie → sprężyna odbija.
- Tryb **Siła**: suwak siły (0–200 N) + czas nacisku (10–500 ms) + „Naciśnij”.
- Zaawansowane suwaki: sztywność, tłumienie, tarcie, odbijalność, bezwładność; presety: „PRL mosiądz”, „Nowoczesna inox”, „Zmęczona sprężyna (kamienica)”, „Luźna z demobilu”.
- Telemetria: wykres kąta z ostatnich 5 s (`_draw`), maks. kąt, liczba odbić, czas uspokojenia, „Zatrzask zwolniony!” gdy θ > 0,8·θ_max (drzwi lekko się uchylają). Rekord odbić w save. Dźwięk: klik zatrzasku, metaliczny „ping” przy odbiciu.

## 3. Wyścigi kredensów
**Mieszkanie (pętla wokół centralnego bloku, ~26×20 m, przejścia 4 m):**
```
 +-----------------+-----------------+
 | SALON (parkiet) |>KUCHNIA(kafelki)|   start/meta w salonie
 |  kanapa, ława,  |  stół + 4 krzesła|  krzesła/buty/kwiatki = lekkie RigidBody (latają)
 |  dywan, TV      |  lodówka         |
 +--^----[BLOK]----+-------v---------+
 | PRZEDPOKÓJ      |< SYPIALNIA       |
 | (panele) buty,  | (wykładzina)     |
 | wieszak         | łóżko, szafa     |
 +-----------------+------------------+
```
- Nawierzchnia zmienia `wheel_friction_slip` (koło sprawdza `get_contact_body()` → meta `surface` podłogi).
- Checkpointy (`Area3D`) w 4 przejściach + linia mety; okrążenie liczone po kolei; 3 okrążenia. Pozycja = okrążenia·N + checkpoint + `Curve3D.get_closest_offset`.
- **Typy kredensów** (statystyki → masa, `engine_force`, skręt, środek masy, `wheel_roll_influence`):
  | Typ | Charakter |
  |---|---|
  | Kredens PRL „Standard” | orzech, nadstawka z szybkami — zbalansowany |
  | Kredens „Shadow” | ten sam model, czarny lakier, szybszy „bo czarny” (ukłon w czarnego malucha) |
  | Witryna Babci | wysoka, przeszklona, kryształy — zwrotna, lekka, lubi się przewracać |
  | Dębowy Masyw (gdański) | niski, szeroki, ciężki — wolny start, wysoka v max, taranuje |
  | Meblościanka do samodzielnego montażu | sosna — szybkie przyspieszenie, niska v max |
- Model z prymitywów: cokół, korpus, blat, szuflady z gałkami, drzwiczki, nadstawka, szyby (przezroczysty materiał), 4 kółka meblowe (`VehicleWheel3D`, przód skrętny, tył napęd).
- Boty: cel = punkt z wyprzedzeniem na `Curve3D`, gaz zależny od krzywizny, cofanie gdy utknie > 2 s, te same fizyki co gracz; losowe 3 typy inne niż gracza.
- Ściany pełne 2,8 m z nadprożami nad przejściami; przenikanie jak w „Moich decyzjach”.
- Kamera: wygładzony pościg za kredensem. HUD: okr. 1/3, poz. 2/4, czas, najlepsze okrążenie, km/h, odliczanie 3-2-1, tabela wyników. Ekran wyboru: obracający się podgląd 3D + paski statystyk.
- Oprawa: `WorldEnvironment` (SSAO, glow, tonemap), `DirectionalLight3D` z cieniami, niebo proceduralne; podłogi shaderem (deski / jodełka / kafle / wykładzina).
- Sterowanie: WASD/strzałki + pad, Spacja hamulec ręczny, R postaw kredens.

## 4. Symulator schnięcia farby
- Scena 3D: pokój z jedną widoczną ścianą 5,2 × 2,6 m (zagruntowana szara), wałek, kuweta i puszka z prymitywów (`paint_props.gd`).
- **Cztery ściany** (z oknem, z drzwiami, z kaloryferem, goła), każda z własną farbą, kolorem i zegarem. Q/E (LB/RB) przełącza; fizycznie to jedna ściana z podmienianym stanem i rekwizytem — przejście zasłania ekran ładowania.
- Wybór farby (realistyczne czasy „suche w dotyku”): Szybkoschnąca 15 min, Emulsja akrylowa 1 h, Lateksowa 2 h, Olejna 8 h, Lakier do drewna 24 h. 4 kolory do wyboru (w tym „NRGeek czerwony”). Każda farba ma `sheen` — szorstkość po wyschnięciu (olejna i lakier zostają błyszczące).
- **Malowanie ręczne**: wałek idzie za myszą (pad: lewa gałka), LPM/RT zostawia farbę. `PaintMask` (`paint_mask.gd`, czysta logika) trzyma grubość powłoki w „warstwach” na siatce 256×128 (piksel ≈ 2 cm): jedno przejście = 0,75 warstwy niezależnie od prędkości i kierunku, od 0,5 piksel liczy się jako pomalowany, od 2,5 farba spływa. Farby na wałku starcza na 7 m — Spacja/X macza w kuwecie. „Skończ malować” (Tab/Y) od 50% pokrycia; dopiero wtedy rusza zegar. Miejsce pod rekwizytem nie liczy się do pokrycia.
- Shader ściany (`paint_wall.gdshader`): krycie `1 − exp(−k·grubość)` (cienka warstwa prześwituje podkładem), mapa normalnych z wysokości (tynk, „baranek” po wałku, zakładki pasów), zacieki pod przemalowanymi miejscami, schnięcie plamami (cienkie miejsca i krawędzie pierwsze, zacieki ostatnie), mokra powłoka z `CLEARCOAT`.
- Schnięcie: `wetness` 1→0. UI: licznik, pasek, rotujące teksty, podgląd stanu wszystkich ścian u góry. Kliknięcie w mokrą ścianę (albo „Dotknij farby”) zostawia odcisk w tym miejscu — ściana zepsuta.
- Trwałość (sekcja `paint`): `wall`, `last_seen`, liczniki, a per ściana `w<i>_state|paint_id|color|start_unix|dried_at|touch_x|touch_y|cheated|coverage`; maska w `user://paint_wall_<i>.bin`. Czas z `Time.get_unix_time_from_system()` — schną wszystkie ściany, także przy zamkniętej grze. Stary zapis jednej ściany migruje na ścianę 0.
- **Zegar systemowy**: `PaintTime.clock_cheat()` łapie cofnięcie zegara względem `last_seen` oraz skok czasu ściennego względem monotonicznego w trakcie gry. Skutek: osiągnięcie + dopisek „wyschła nieuczciwie”, bez kary. Skok w przód przy wyłączonej grze wychodzi dopiero przy cofnięciu zegara.
- Parametr testowy `--paint-speed=N` (mnożnik czasu) tylko do weryfikacji.

## 5. Ekran ładowania (zmiana ściany)
`games/paint/loading.gd` — celowo długi (8–15 s), pasek staje, cofa się i wisi na 99%. Po prawej obracany model bez związku z czymkolwiek (wałek, puszka, kaloryfer, okno, kredens, klamka, „brak_modelu.obj”; mysz/prawa gałka obraca), po lewej „POZIOM CIERPLIWOŚCI N” (rośnie z każdym obejrzanym ekranem), numer katalogowy i porada z listy `TIPS`. Po 3 s Enter/A pomija. Stylistyka kolekcji (czerń, czerwień, Bahnschrift), nie cudza.

## 6. Osiągnięcia
- Dane w `core/achievements.gd` (`Achievements.LIST`: gra → lista `{id, title, desc, secret}`), zapis w sekcji `ach` jako `<gra>.<id>` = czas odblokowania.
- `Collection.unlock(gra, id)` odblokowuje raz i pokazuje powiadomienie (`Collection.toast`, kolejka) nad każdą sceną. Komplet daje „Platynę”.
- Menu: kategoria „Osiągnięcia” z pozycją na grę („3 / 14 odblokowanych”); Enter otwiera przewijaną listę (↑/↓), sekretne jako „???”.
- Ton prześmiewczy: lakier 24 h = „Masochista”, przestawiony zegar = „Podróżnik w czasie”, pominięty ekran ładowania = „Nie mam całego dnia”.

## Kolejność wykonania
0. `git init`, `project.godot` (main = menu, autoload, InputMap klawiatura+pad, 1920×1080 stretch `canvas_items`/`expand`, Forward+, 120 Hz fizyki), `icon.svg`, `docs/DESIGN.md`.
1. `core/collection.gd` + menu XMB.
2. Klamka (`handle_sim.gd` + testy najpierw, potem scena/UI/wykres).
3. Wyścigi (kredens + strojenie jazdy → mieszkanie → boty → okrążenia/HUD → wybór/wyniki) + test auto-wyścigu.
4. Farba (`paint_time.gd` + testy, shader, pędzel, UI, zapis).
5. Weryfikacja końcowa.

## Weryfikacja
- Najpierw import świeżego projektu: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --import` (inaczej `class_name` nie są znane). Test nie używa nazw autoloadów bezpośrednio (`root.get_node("/root/Collection")`).
- Testy logiki: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_all.gd` — klamka (puszczona z θ_max wraca do 0, ≥1 odbicie przy e=0.5, siła poniżej napięcia wstępnego nie rusza klamki), farba (pozostały czas z zapisanego znacznika po „restarcie”), kolejność pozycji w wyścigu.
- Auto-wyścig headless: `--headless --fixed-fps 120 --path . res://games/race/race.tscn -- --autorace` (scena wyścigu podana wprost — bez niej startuje menu i nic się nie dzieje;szybciej niż czas rzeczywisty bez zmiany kroku fizyki; NIE `time_scale`) — 4 boty, assert: wszystkie kończą 3 okrążenia w limicie czasu (sprawdza tor, AI, odzyskiwanie po wywrotce).
- Zrzuty: `--path . -- --shot=menu|klamka|race|paint` → PNG w `user://shots/` po ~3 s, przeglądam je wizualnie.
  Farba: `paint` (schnie), `paint_painting`, `paint_dry`, `paint_choose`, `paint_loading`, `paint_stroke` (prawdziwe pociągnięcie wałkiem przez wstrzyknięte zdarzenia myszy), `paint_switch --delay=18` (pełna zmiana ściany), `--wall=N`. Menu: `menu_trophies` (lista osiągnięć), `--toast` (powiadomienie).
- Ręcznie: Ty grasz — menu (nawigacja, ustawienia, zegar), każda gra i powrót przez Esc.
- Eksport .exe — poza zakresem (wymaga szablonów eksportu), dodamy na życzenie.
