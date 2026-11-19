# Wyścigi kredensów: nowe mapy i tryby gry — projekt

Data: 2026-11-15. Dotyczy `games/race/`. Uzupełnia `docs/DESIGN.md` (sekcja 3).

## Po co

Wyścigi mają dziś trzy trasy (mieszkanie i dwa warianty tego samego garażu) i jeden tryb: gracz
przeciw trzem botom. Chcemy, żeby to była gra, do której siada się we kilka osób przy jednym
ekranie i która ma po co wracać: różne, szczegółowe trasy i turniej.

## Cele

- 7 tras wyraźnie różnych wyglądem, nawierzchnią i charakterem jazdy. Obowiązkowe (życzenie
  użytkownika): **doki, kanały, parking przed sklepem, parking podziemny**.
- Trzy tryby: **szybki wyścig**, **turniej**, **gra na kanapie** z podzielonym ekranem.
- **Do 4 graczy** na jednym ekranie (decyzja użytkownika).
- Dotychczasowe zapisy rekordów mieszkania M4 zostają.

## Nie-cele

- Gra przez sieć. Tryb drużynowy. Wznawianie przerwanego turnieju. Edytor tras.
- Trasy wielopoziomowe (tor zostaje płaski; rampy i progi tak, piętra nie).
- Ściany pod kątem (zostają osiowe — na tym stoi przenikanie ścian i minimapa).
- Nowe typy kredensów, odblokowania.

## Anty-cele

- Gra jednoosobowa nie może wyglądać ani działać gorzej niż dziś.
- Żadnych prawdziwych marek sklepów, aut, firm (własne, żartobliwe nazwy).
- Żadnych pobieranych assetów — jak dotąd wszystko z prymitywów i tekstur generowanych w kodzie.
- Bot, który nie umie ukończyć trasy, to błąd trasy, nie bota.

## Ograniczenia zastane w kodzie

- Mapy to dane (`RaceMaps`), świat stawia `Apartment.build(map)`. Zna dwa otoczenia: mieszkanie
  na IV piętrze (`_estate`) i kryty garaż (`_garage_extras`), przełączane kluczem `indoor`.
- Podłoga to jedna płyta z kolizją na cały plan — nie da się zrobić wody ani dziury.
- Progi (`humps`) biegną tylko wzdłuż osi Z.
- `race.gd` zakłada jednego gracza: `racers[3]` to gracz, jedna kamera, jeden HUD, jeden
  `RaceFeel`, jeden łańcuch umiejętności, jedne międzyczasy.
- Sterowanie czyta globalne akcje (`drive_forward` itd.), bez rozróżniania urządzeń.
- Jakość obrazu jest ciężka (SDFGI, SSIL, SSR, mgła wolumetryczna).
- Testy: `tests/test_all.gd` (logika) i `--autorace` (4 boty muszą ukończyć wyścig).

## Podejścia

Jak zrobić wspólną grę:

- **A. Osobny widok na gracza, jeden wspólny świat (wybrane, moja decyzja — użytkownik zostawił
  „jak" mnie).** Każdy gracz dostaje `SubViewport` dzielący `World3D` z główną sceną, w nim własną
  kamerę, własny `RaceFeel` i własny HUD. Jedna ścieżka kodu dla 1–4 graczy: jeden gracz to po
  prostu jeden widok na cały ekran. Koszt: świat rysowany do 4 razy.
- **B. Jedna kamera oddalająca się tak, żeby objąć wszystkich.** Tanie, ale w korytarzach ze
  ścianami nieczytelne, a użytkownik prosił o podzielony ekran. Odrzucone.
- **C. Gra po sieci.** Nikt o to nie prosił. Odrzucone.

## Trasy

Dotychczasowe `parking` i `parking2` znikają; zastępuje je jedna lepsza trasa o nowym id
(stare rekordy garażu przepadają — to inny układ). M4 bez zmian, klucze zapisu bez prefiksu.

Każda trasa: plan, liczba okrążeń dobrana tak, żeby wyścig trwał 2–3 minuty, własne nawierzchnie
(mnożnik przyczepności), przeszkody stałe, rekwizyty latające po uderzeniu i co najmniej jeden
element, którego nie ma nigdzie indziej.

| id | Nazwa | Plan, okr. | Otoczenie | Charakter i wyróżnik |
|---|---|---|---|---|
| `m4` | Mieszkanie M4 | 32×24, 3 | mieszkanie IV p. | bez zmian |
| `podziemny` | Parking podziemny −2 | ok. 60×40, 2 | garaż, strop 3,4 m | szybkie alejki i ciasne nawroty między filarami |
| `doki` | Doki portowe | ok. 70×46, 2 | otwarty teren, pochmurny świt, mgła | nabrzeże bez barierek nad wodą, labirynt kontenerów |
| `kanaly` | Kanały | ok. 56×36, 3 | kryte, ciemno, zielonkawa mgła | wąskie chodniki po obu stronach ścieku, kładki |
| `sklep` | Parking przed sklepem | ok. 64×44, 3 | otwarty teren, zmierzch, latarnie | luźne wózki sklepowe, krawężniki, objazd rampą dostaw |
| `dzialki` | Ogródki działkowe | ok. 60×44, 2 | otwarty teren, słoneczne popołudnie | żwir i trawa — mało przyczepności, ciasne alejki |
| `szkola` | Szkoła | ok. 56×36, 3 | wnętrze bez sufitu (jak M4), parter | długi korytarz i śliski parkiet sali gimnastycznej |

Szczegóły (to, co ma być widać i czuć; dokładne współrzędne ustala budujący):

**Parking podziemny −2.** Zatoki z autami przy ścianach, autobus w zatoczce, źle zaparkowane auta
w alejkach, filary, strzałki pod stropem, żółte osie i numery miejsc. Nowe: garb-rampa (ok. 0,35 m)
na jednej prostej, dwa szlabany jako lekkie belki wyłamywane uderzeniem, strefa myjni (mokro i
piana, przyczepność ok. 0,45), plama oleju, budka parkingowego, rury pod stropem, zielone znaki
ewakuacyjne, jedna migająca lampa, porzucony wózek sklepowy.

**Doki portowe.** Południowa krawędź planu to nabrzeże: woda, pachołki cumownicze, żadnych
barierek. Kontenery w stosach 1–3 (różne kolory, blacha falista) tworzą korytarze. Suwnica bramowa
nad torem (przejazd pod nią), tory kolejowe w poprzek trasy jako dwa niskie progi, magazyn z
otwartymi wrotami (przejazd przez halę: gładki beton ok. 0,9, regały z paletami), wózek widłowy,
palety, beczki i skrzynie jako rekwizyty. W tle statek przy nabrzeżu i żurawie. Nawierzchnie:
asfalt ok. 1,15, płyty betonowe 1,0, mokre nabrzeże ok. 0,7, stalowe płyty ok. 0,6.

**Kanały.** Ściek (woda) biegnie środkiem tuneli; jedzie się chodnikami szerokości 3,5–4 m po obu
stronach, na drugą stronę przejeżdża się kładkami z kraty (ok. 0,6). Jedna duża komora zbiorcza z
filarami, gdzie robi się szeroko i można wyprzedzać. Plamy szlamu (ok. 0,4), rury wzdłuż ścian,
kraty, włazy w stropie ze smugą światła, pomarańczowe lampy awaryjne, beczki i kartony.

**Parking przed sklepem.** Fasada marketu z własną nazwą (propozycja: „DELIKATESY KREDENS") z
neonem i przeszklonym wejściem. Rzędy miejsc z autami, wyspy z krawężnikami i drzewkami, wiaty na
wózki i **luźne wózki sklepowe** (lekkie, latają), latarnie świecące naprawdę, progi zwalniające,
przejście dla pieszych, kałuże po deszczu, kontenery na odzież, automat paczkowy, stojak rowerowy,
budka z kurczakiem z rożna. Trasa objeżdża sklep: wąska rampa dostaw z tyłu, palety i dostawczak.

**Ogródki działkowe.** Brama „ROD Relaks" na starcie. Alejki żwirowe (ok. 0,8) i skróty po trawie
(ok. 0,65), grządki (ziemia ok. 0,5), altanki, szklarnie, płoty z siatki (niskie), kompostowniki,
beczki na deszczówkę, taczki, krasnale ogrodowe jako rekwizyty, kałuża przy wężu ogrodowym.

**Szkoła.** Korytarz z lastryko (ok. 0,95), szafki i ławki pod ścianami, szatnia z boksami, sala
gimnastyczna z lakierowanym parkietem (ok. 0,7), liniami boiska, kozłem, drabinkami, bramkami,
materacami (ok. 1,5 — hamują) i piłkami lekarskimi jako rekwizytami; stołówka ze stołami i
krzesłami; świeżo umyta podłoga z żółtym znakiem (ok. 0,4).

### Co musi umieć budowniczy świata

- **Otoczenie jako klucz mapy** zamiast `indoor`: mieszkanie (jak dziś), garaż (jak dziś), kanał
  (strop, ciemno, mgła), otwarty teren na poziomie ziemi (niebo, słońce, ziemia po horyzont, tło;
  pora dnia i pogoda z danych mapy), szkoła (jak mieszkanie, ale parter i boisko dookoła).
- **Woda.** Kolizja podłogi z prostokątów pomieszczeń zamiast jednej płyty; woda to obszar bez
  podłogi z taflą poniżej. Kredens, który spadnie poniżej podłogi, wraca na tor dotychczasowym
  mechanizmem „postaw kredens" (liczy się jak wywrotka; karą jest stracony czas).
- **Progi w obu osiach**, ściany o własnej wysokości (płoty, krawężniki), meble z obrotem.
- **Dekoracje złożone** (kontener, suwnica, latarnia, wiata, altanka, szklarnia, rura, wózek
  sklepowy itd.) budowane z prymitywów. Żeby `apartment.gd` nie spuchł, idą do nowego pliku
  `games/race/decor.gd`.
- **Klamra bezpieczeństwa:** światła z cieniami tylko tam, gdzie to coś daje (latarnie i lampy
  w większości bez cieni).

## Tryby i przebieg

```
wejście do gry → TRYB → POCZEKALNIA → [wyścig → wyniki] × N → koniec
                 Szybki wyścig        dołączanie graczy, wybór kredensów,
                 Turniej              trasa (szybki) / lista 4 tras (turniej)
```

- **Poczekalnia** zastępuje dzisiejszy ekran wyboru. Pierwszy gracz jest zawsze; kolejni dołączają
  przyciskiem na swoim urządzeniu i odchodzą przyciskiem „wstecz". Każdy wybiera kredens sam,
  strzałkami na swoim urządzeniu; ten sam typ może wziąć kilku graczy. Trasę (szybki wyścig)
  wybiera gracz 1. Start, gdy gracz 1 zatwierdzi. Jeden gracz = dzisiejsza gra, bez dodatkowych
  kroków poza wyborem trybu.
- **Stawka to zawsze 4 kredensy.** Boty dopełniają do czterech i biorą typy, których nie wzięli
  ludzie. Ludzie startują z końca stawki, w losowej kolejności.
- **Szybki wyścig:** jedna trasa. Wyniki → „Jeszcze raz / Zmień ustawienia / Wróć do menu".
- **Turniej:** 4 trasy wylosowane z siedmiu bez powtórek, pokazane w poczekalni, z przyciskiem
  „Losuj ponownie". Punkty za miejsca 1–4: **10 / 7 / 5 / 3**. Po każdym wyścigu klasyfikacja
  wyścigu i tabela turnieju → „Następny wyścig". Po ostatnim plansza zwycięzcy. Remis rozstrzyga
  lepsze miejsce w ostatnim wyścigu. Wyjście w trakcie = turniej przepada.
- **Kanapa** to nie osobny tryb, tylko 2–4 graczy w poczekalni; działa w szybkim wyścigu i w turnieju.
  Gracze ścigają się ze sobą i z botami.
- **Koniec wyścigu:** kto dojedzie, widzi „META!" i miejsce, a jego kredens przejmuje autopilot
  (jak dziś). Wyniki pojawiają się 2,5 s po mecie ostatniego człowieka; boty, które nie dojechały,
  są szeregowane według postępu (jak dziś).
- **Limit po mecie pierwszego człowieka (moja decyzja):** gdy pierwszy człowiek minie metę,
  pozostali ludzie widzą odliczanie 45 s. Po nim wyścig się kończy, a kto nie dojechał — człowiek
  czy bot — jest szeregowany według postępu, za tymi, którzy dojechali, i dostaje punkty za to
  miejsce. Przy jednym graczu nic się nie zmienia.
- **Zapis:** rekord okrążenia per trasa i per typ kredensu oraz wygrane per typ — w każdym trybie,
  dla dowolnego człowieka. Nowe: liczba wygranych turniejów (`race/cups`). Dotychczasowe klucze i
  ich znaczenie bez zmian.

### Podzielony ekran

- 1 gracz: cały ekran. 2 graczy: góra/dół (szeroki obraz lepiej służy jeździe). 3–4: siatka 2×2;
  przy trzech graczach czwarte pole pokazuje dużą minimapę i tabelę pozycji.
- Każdy widok ma komplet HUD-u gracza: miejsce, okrążenie, czas, prędkościomierz, minimapę,
  łańcuch umiejętności, międzyczasy, komunikaty. HUD skaluje się z widokiem (ten sam układ,
  mniejszy), w widokach ćwiartkowych bez tabeli pozycji i paska podpowiedzi.
- Gracze mają kolory: 1 czerwony, 2 niebieski, 3 żółty, 4 zielony — znacznik nad kredensem,
  kropka na minimapie, akcent HUD-u.
- Linia jazdy jest osobna dla każdego gracza i widać ją tylko w jego widoku.
- Łańcuch umiejętności, międzyczasy i punkty kontrolne liczone osobno dla każdego gracza.
- Ściany przenikają, gdy zasłaniają któregokolwiek gracza (materiał ściany jest wspólny — przy
  kilku widokach ściana bywa przezroczysta także u sąsiada; akceptujemy).
- Odliczanie, pauza i wyniki są na całym ekranie, wspólne.
- **Wydajność:** przy 2+ widokach wyłączone SDFGI, SSIL, SSR i mgła wolumetryczna; zostają cienie
  głównego światła, SSAO i glow. Przy jednym graczu jakość jak dziś.
- **Cel (moja decyzja):** 60 kl./s w 1920×1080 na maszynie użytkownika (Radeon RX 9070 XT) —
  przy jednym graczu na każdej trasie i przy czterech widokach. Mierzone licznikiem klatek
  wypisywanym w trybie zrzutów. Budżet na trasę: najwyżej 8 świateł z cieniami, reszta bez.
  Jeśli cztery widoki nie trzymają celu, widoki dostają niższą skalę renderowania; dekoracji
  nie ubywa.

### Sterowanie

- Wyścig z jednym człowiekiem: jak dziś — WASD, strzałki i dowolny pad naraz.
- Kilku graczy: każdy ma jedno urządzenie. **Klawiatura A:** WASD, ręczny Spacja, postaw R.
  **Klawiatura B:** strzałki, ręczny prawy Shift, postaw prawy Ctrl. **Pady 1–4:** jak dziś
  (spusty, lewa gałka, X, Y). Maksymalnie 4 graczy łącznie.
- Pauzę wywołuje każdy.

Poczekalnia (moja decyzja — start i dołączanie to różne przyciski, żeby samotny gracz nie
dorobił się przypadkiem drugiego):

- **Gracz 1 to urządzenie, którym wybrano tryb.** Tylko on startuje wyścig (Enter / A) i wybiera
  trasę. Dopóki nikt nie dołączył z klawiatury, gracz 1 na klawiaturze ma ją całą (WASD i strzałki).
- **Dołączanie:** inny pad — A; druga osoba na klawiaturze — prawy Shift (dostaje strzałki,
  gracz 1 zostaje przy WASD). Gdy gracz 1 gra padem, klawiatura dołącza Spacją (WASD) i prawym
  Shiftem (strzałki).
- **Odejście:** pad — B; klawiatura A — Q; klawiatura B — Delete. Gracz 1 „wstecz" wraca do
  wyboru trybu.
- Poczekalnia pokazuje przy każdym polu gracza, czym dołączyć i czym odejść.

## Testy i weryfikacja

- **Walidator tras** w `tests/test_all.gd`, dla każdej mapy: unikalne id; każdy punkt linii jazdy
  leży na podłodze (w prostokącie pomieszczenia, poza wodą); linia jazdy ma odstęp od ścian,
  mebli, filarów i aut. Odstęp domyślny to 1,3 m; mapa może podać własny, mniejszy (klucz w
  danych), jeśli autowyścig na niej przechodzi. **M4 dostaje 0,75 m** — jej szykana w pokoju
  dziecięcym ma dziś 0,77 m od lica ściany (0,84 m od jej osi) i nie ruszamy jej, żeby zapisane
  rekordy zachowały sens.
- **Turniej:** czysta funkcja punktów i rozstrzygania remisów + test.
- **Autowyścig** bez okna na każdej trasie (`--autorace --map=<id>`): cztery boty kończą w limicie.
- **Zrzuty** każdej trasy i podzielonego ekranu (`--shot=race --map=<id> --players=N`, boty za
  kierownicą) do obejrzenia.
- Ręcznie przez użytkownika: gra na 2–4 urządzeniach, płynność przy 4 widokach.

## Moje decyzje (do korekty)

- Lista tras spoza obowiązkowej czwórki: ogródki działkowe i szkoła; M4 zostaje bez zmian.
- Dwa stare warianty garażu scalone w jeden nowy.
- Stawka zawsze 4; turniej to 4 losowe trasy, punkty 10/7/5/3.
- Podział dla 2 graczy góra/dół.
- Niższa jakość oświetlenia w podzielonym ekranie.
- Kara za wodę to sam powrót na tor.
- Projekt nie jest commitowany — repozytorium nie ma jeszcze żadnego commita, zostawiam to
  użytkownikowi.

## Zostawione budującemu

- Dokładne współrzędne tras, rozstaw przeszkód, wartości przyczepności i liczba okrążeń — strojone
  walidatorem i autowyścigiem.
- Podział kodu na pliki (HUD gracza osobno od menu, `decor.gd`, sterowanie per urządzenie).
- Sposób ukrywania linii jazdy w cudzych widokach i blaknięcia bramek przy kilku kamerach.
- Wygląd poczekalni, tabeli turnieju i planszy zwycięzcy w istniejącym stylu `RaceUI`.
- Aktualizacja `docs/DESIGN.md` (multiplayer wypada z nie-celów, nowa lista tras i trybów).
