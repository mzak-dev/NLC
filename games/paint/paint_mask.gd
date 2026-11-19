class_name PaintMask
extends RefCounted
## Grubość farby na ścianie (czysta logika, testowana w tests/test_all.gd).
## Jeden float na piksel, jednostka = „warstwa”: 1.0 kryje w pełni, jedno przejście wałka daje mniej.

const W := 256
const H := 128            # 2:1 jak ściana 5,2 × 2,6 m → piksel ≈ 2 cm
const COVER := 0.5        # od tej grubości piksel liczy się jako pomalowany
const SAG := 2.5          # od tej grubości farba spływa (zacieki)
const MAX := 4.0

var data := PackedFloat32Array()
var _covered := 0
var _sagging := 0
var _blocked := 0         # piksele zasłonięte rekwizytem (okno, drzwi) — nie liczą się do pokrycia


func _init() -> void:
	data.resize(W * H)


## Dokłada farbę wzdłuż ruchu wałka from → to (UV 0..1). half = połowa odcisku wałka w UV,
## amount = ile warstw zostawia jedno pełne przejście. Ilość nie zależy od prędkości ani liczby klatek.
func stamp(from: Vector2, to: Vector2, half: Vector2, amount: float) -> void:
	var size := Vector2(W, H)
	var a := from * size
	var b := to * size
	var hp := half * size
	var dist := a.distance_to(b)
	var steps := maxi(1, ceili(dist))
	var dep := amount * 0.3          # przyłożenie wałka bez ruchu
	if dist > 0.001:
		var dir := (b - a) / dist
		# piksel jest pod wałkiem przez drogę równą cięciwie prostokąta odcisku wzdłuż kierunku ruchu
		var chord := minf(2.0 * hp.x / maxf(absf(dir.x), 0.0001), 2.0 * hp.y / maxf(absf(dir.y), 0.0001))
		dep = amount * (dist / steps) / chord
	for s in steps:
		var c := a.lerp(b, (s + 1.0) / steps)
		# piksele na brzegu odcisku dostają tyle farby, ile ich powierzchni wałek przykrywa —
		# bez tego zaokrąglanie do pikseli zawyża grubość i uzależnia ją od prędkości
		for y in range(clampi(floori(c.y - hp.y), 0, H - 1), clampi(floori(c.y + hp.y), 0, H - 1) + 1):
			var oy := maxf(0.0, minf(y + 1.0, c.y + hp.y) - maxf(y, c.y - hp.y))
			for x in range(clampi(floori(c.x - hp.x), 0, W - 1), clampi(floori(c.x + hp.x), 0, W - 1) + 1):
				var ox := maxf(0.0, minf(x + 1.0, c.x + hp.x) - maxf(x, c.x - hp.x))
				_put(y * W + x, data[y * W + x] + dep * ox * oy)


func _put(i: int, v: float) -> void:
	var old := data[i]
	v = minf(v, MAX)
	data[i] = v
	if old < COVER and v >= COVER:
		_covered += 1
	if old < SAG and v >= SAG:
		_sagging += 1


## Obszar zasłonięty rekwizytem: farby tam nie widać i nie liczy się do pokrycia.
func block(rect: Rect2) -> void:
	for y in range(clampi(roundi(rect.position.y * H), 0, H), clampi(roundi(rect.end.y * H), 0, H)):
		for x in range(clampi(roundi(rect.position.x * W), 0, W), clampi(roundi(rect.end.x * W), 0, W)):
			_put(y * W + x, maxf(data[y * W + x], 1.0))
			_blocked += 1


func fill(v: float) -> void:
	for i in data.size():
		_put(i, v)


func at(uv: Vector2) -> float:
	return data[clampi(int(uv.y * H), 0, H - 1) * W + clampi(int(uv.x * W), 0, W - 1)]


## Udział pomalowanej powierzchni (0..1), bez miejsc zasłoniętych.
func coverage() -> float:
	return float(_covered - _blocked) / maxi(1, W * H - _blocked)


## Udział powierzchni z zaciekami (0..1).
func excess() -> float:
	return float(_sagging) / (W * H)


func to_image() -> Image:
	return Image.create_from_data(W, H, false, Image.FORMAT_RF, data.to_byte_array())


## Wczytuje maskę z surowych bajtów (zapis: data.to_byte_array()). false, gdy rozmiar się nie zgadza.
func load_bytes(bytes: PackedByteArray) -> bool:
	if bytes.size() != W * H * 4:
		return false
	var src := bytes.to_float32_array()
	_covered = 0
	_sagging = 0
	_blocked = 0
	data.fill(0.0)
	for i in src.size():
		_put(i, src[i])
	return true
