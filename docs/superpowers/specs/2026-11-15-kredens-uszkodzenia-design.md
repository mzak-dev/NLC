# Uszkodzenia kredensów — projekt (krótki)

## Po co
Zderzenia w wyścigu mają być widać i czuć: drzwiczki się otwierają, zawartość wypada,
szyba pęka, części odpadają — i rozwalony kredens jedzie inaczej niż cały.

## Cele
- Reakcja na uderzenie stopniowana siłą, taka sama dla gracza i botów.
- Uszkodzenia zmieniają jazdę (decyzja użytkownika).
- Podgląd w menu wyboru (`race_ui.gd`, `Kredens.build_model`) działa bez zmian.

## Poza zakresem
Odpadające kółka, deformacja siatki, naprawy/pickupy, pasek uszkodzeń w HUD,
zapisywanie uszkodzeń między wyścigami.

## Anty-cel
Rozbijanie się nie może być opłacalną taktyką: lżejszy kredens rusza szybciej,
ale każda strata musi kosztować więcej w prowadzeniu, niż daje w przyspieszeniu.

## Podejścia
1. **Części w kodzie + udawany zawias (wybrane).** `build_model` grupuje części;
   kredens sam obraca drzwi sprężyną i przepina odpadające części do świata jako
   `RigidBody3D`. Stabilne na `VehicleBody3D`, tanie przy 4 kredensach.
2. **Pełne jointy.** `HingeJoint3D` na drzwiach, każdy kryształ jako bryła w środku.
   Najbardziej „prawdziwe", ale jointy na pojeździe drgają, a ~80 brył stale w symulacji.
3. **Podmiana na gruz.** Przy jednym progu cały kredens zamienia się w kawałki.
   Najprostsze, ale bez stopniowania i kończy jazdę.

## Jak to działa

**Wykrywanie.** `Kredens._physics_process` liczy skok prędkości w jednym kroku fizyki
`|v − v_poprz|` [m/s] (bez dzielenia przez `dt`: przy 120 Hz przyspieszenie z jednego kroku
jest zbyt zaszumione). Jedno zderzenie liczy się raz (0,3 s przerwy). `reset_to_track` zeruje `v_poprz`, żeby teleport nie liczył się jako uderzenie.

**Progi** (stałe do strojenia w grze):

| Siła | Skutek wizualny | Skutek w jeździe |
|---|---|---|
| lekkie ≥ 1,5 m/s | drzwi się odblokowują i bujają od przeciążeń | −4% prędkości maks. na każde otwarte drzwi (opór) |
| średnie ≥ 3,0 m/s | połowa pozostałej zawartości wylatuje, szyba pęka w odłamki | masa spada (zawartość ≈ 15% masy) |
| mocne ≥ 5,5 m/s | jedne drzwi odpadają; przy drugim mocnym odpada nadstawka | masa −4% za drzwi, −25% za nadstawkę, środek ciężkości niżej, znika górna kolizja; **luzy na kółkach: −6% przyczepności i drżenie skrętu za każde mocne uderzenie (maks. −30%)** |

Siła silnika zostaje liczona od masy nominalnej (`t.mass`), więc lżejszy kredens rusza
szybciej, ale łatwiej go zepchnąć i gorzej trzyma tor.

Progi sprawdzone na wyścigu botów (`--autorace`, 3 okrążenia): 32 uderzenia,
mediana 2,3 m/s, maks. 6,6 m/s — większość lekkich, kilka średnich, 2 mocne.

**Części.** `build_model` zwraca ten sam `Node3D`, a w `meta` listy: `doors` (pivot na
krawędzi z zawiasem), `contents`, `glass`, `top` (nadstawka z półkami). Meblościanka
(`open: true`) nie ma drzwi — wypadają tylko książki. Za drzwiami dolnej szafki są
niewidoczne garnki i talerze (3 na drzwi), tworzone dopiero w chwili wypadania.

**Odłamki.** `RigidBody3D` na warstwie 4 (jak `Apartment._prop`), startują z prędkością
kredensu plus impuls na zewnątrz, znikają po 8 s. Są dziećmi kredensu (`top_level`),
więc znikają razem z nim i nie kolidują z własnym kredensem.

**Trwałość.** Uszkodzenia zostają do końca wyścigu; `R` stawia kredens, ale nie naprawia.
Nowy wyścig = nowy kredens.

## Sprawdzenie
Jeden test w `tests/test_all.gd`: seria uderzeń o znanej sile → otwarte drzwi, mniejsza
masa, niższa przyczepność; uderzenie poniżej progu nic nie zmienia.

## Zostawione wykonawcy
Dokładne wartości progów i procentów (strojenie w grze), wygląd odłamków szyby.
