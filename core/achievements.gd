class_name Achievements
extends RefCounted
## Osiągnięcia: same dane + czysta logika (testowane w tests/test_all.gd).
## Zapis: sekcja „ach”, klucz „<gra>.<id>” = czas odblokowania (unix). Odblokowuje Collection.unlock().

const GAMES := {
	"paint": "Symulator schnięcia farby",
	"race": "Wyścigi kredensów",
	"klamka": "Symulator naciskania klamki",
	"kolekcja": "Kolekcja",
}

const LIST := {
	"paint": [
		{"id": "masochist", "title": "Masochista", "desc": "Wybrałeś lakier do drewna. 24 godziny. Gratulujemy masochizmu."},
		{"id": "impatient", "title": "W gorącej wodzie kąpany", "desc": "Farba szybkoschnąca. 15 minut to też czekanie, tchórzu."},
		{"id": "perfectionist", "title": "Perfekcjonista", "desc": "100% pokrycia. Nikt tego nie sprawdzi. Ty wiesz."},
		{"id": "botcher", "title": "Fachowiec z ogłoszenia", "desc": "Skończyłeś z prześwitami. „Panie, tak miało być.”"},
		{"id": "sag", "title": "Zaciek", "desc": "Nałożyłeś tyle farby, że sama zeszła ze ściany."},
		{"id": "fingerprint", "title": "Musiałeś, prawda?", "desc": "Dotknąłeś mokrej farby. Mówiliśmy."},
		{"id": "so_close", "title": "Tak blisko", "desc": "Dotknąłeś farby, gdy zostało mniej niż 5% czasu. Brawo.", "secret": true},
		{"id": "witness", "title": "Świadek", "desc": "Widziałeś, jak wyschła ściana. Opowiesz wnukom."},
		{"id": "absentee", "title": "Zaocznie", "desc": "Ściana wyschła pod twoją nieobecność. Najlepszy sposób grania w tę grę."},
		{"id": "stare", "title": "Nie mrugnąłem", "desc": "10 minut ciągiem patrzyłeś, jak schnie farba. Wszystko w porządku?"},
		{"id": "renovation", "title": "Remont generalny", "desc": "Cztery suche ściany naraz. Teraz jeszcze sufit. Żartujemy. Chyba."},
		{"id": "no_time", "title": "Nie mam całego dnia", "desc": "Pominąłeś ekran ładowania. W symulatorze schnięcia farby."},
		{"id": "bar_fan", "title": "Koneser pasków postępu", "desc": "Obejrzałeś 10 ekranów ładowania do końca. Dobrowolnie."},
		{"id": "time_traveller", "title": "Podróżnik w czasie", "desc": "Przestawiłeś zegar systemowy. Farba to widziała. Nieładnie tak oszukiwać.", "secret": true},
	],
	"race": [
		{"id": "first_win", "title": "Mistrz parkietu", "desc": "Wygrałeś wyścig kredensów. Wpisz to do CV."},
		{"id": "last_place", "title": "Liczy się udział", "desc": "Ostatnie miejsce. Przegrałeś z meblami bez kierowcy."},
		{"id": "turtle", "title": "Żółw", "desc": "Kredens na plecach. Kryształy babci nie przeżyły."},
		{"id": "roofer", "title": "Dekarz", "desc": "Pięć dachowań w jednym wyścigu. To już styl jazdy.", "secret": true},
		{"id": "black_is_faster", "title": "Czarne jest szybsze", "desc": "Wygrałeś czarnym kredensem. Nauka potwierdzona."},
		{"id": "combo", "title": "Kombinator", "desc": "Łańcuch umiejętności ×3. Parkiet do cyklinowania."},
		{"id": "collector", "title": "Kolekcjoner mebli", "desc": "Wygrałeś każdym z pięciu kredensów. Komis meblowy czeka."},
	],
	"klamka": [
		{"id": "first_open", "title": "Otwarte!", "desc": "Otworzyłeś drzwi klamką. Kariera stoi otworem."},
		{"id": "too_weak", "title": "Za słabo", "desc": "Nacisnąłeś poniżej progu ruszenia. Klamka nawet nie drgnęła."},
		{"id": "quiet", "title": "Cichy lokator", "desc": "Klamka wróciła bez ani jednego odbicia. Sąsiedzi dziękują."},
		{"id": "springy", "title": "Sprężynowiec", "desc": "Pięć odbić po jednym puszczeniu. Fizyka bije brawo."},
		{"id": "brute", "title": "Urwiesz!", "desc": "Maksymalna siła nacisku. To klamka, nie siłownia."},
		{"id": "all_presets", "title": "Tester klamek", "desc": "Wypróbowałeś wszystkie klamki. Certyfikat wyślemy pocztą. Nie wyślemy."},
		{"id": "presses_100", "title": "Klamkoman", "desc": "100 naciśnięć. Drzwi proszą o litość."},
		{"id": "presses_1000", "title": "Zawodowy odźwierny", "desc": "1000 naciśnięć. Hotel Bristol dzwonił.", "secret": true},
	],
	"kolekcja": [
		{"id": "platinum", "title": "Platyna", "desc": "Odblokowałeś wszystko. Naprawdę nie masz co robić."},
	],
}


static func key(game: String, id: String) -> String:
	return game + "." + id


static func find(game: String, id: String) -> Dictionary:
	for a in LIST.get(game, []):
		if a.id == id:
			return a
	return {}


## Ile osiągnięć gry jest odblokowanych w danym zapisie.
static func count(game: String, save: ConfigFile) -> int:
	var n := 0
	for a in LIST[game]:
		if save.has_section_key("ach", key(game, a.id)):
			n += 1
	return n


## Czy wszystko poza platyną jest odblokowane.
static func all_done(save: ConfigFile) -> bool:
	for g in LIST:
		if g != "kolekcja" and count(g, save) < LIST[g].size():
			return false
	return true
