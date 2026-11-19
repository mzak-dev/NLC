class_name RaceFeel
extends Node
## Poczucie prędkości i imersja w wyścigu (wnioski z researchu):
## • FOV rośnie z prędkością, kamera lekko się zbliża i podnosi (badanie: wyższa kamera przy dużej
##   prędkości = większe odczucie szybkości), przechyla się w zakrętach.
## • Drżenie: delikatne, wysokoczęstotliwościowe przy prędkości + „trauma” po uderzeniach (nie pływające).
## • Post-FX: subtelne rozmycie radialne i aberracja na krawędziach, smugi prędkości, winieta, ziarno
##   (mocny motion blur wg badań OBNIŻA odczucie prędkości — więc tylko lekko).
## • Pyłki w powietrzu mijające kamerę (paralaksa), kurz spod kółek w poślizgu.
## • Dźwięk: turkot kółek meblowych zależny od prędkości, pisk w poślizgu, łomot przy uderzeniu.

const FOV_MIN := 64.0
const FOV_MAX := 90.0
const SPEED_REF := 10.0      # m/s, przy której efekty są pełne

var cam: Camera3D
var car: Kredens
var s := 0.0                 # wygładzona prędkość względna 0..1
var trauma := 0.0
var roll := 0.0
var _prev_v := Vector3.ZERO
var _t := 0.0
var _noise := FastNoiseLite.new()
var fx: ShaderMaterial
var dust: CPUParticles3D
var motes: CPUParticles3D
var _gen: AudioStreamGeneratorPlayback
var _player: AudioStreamPlayer
var _phase := 0.0
var _brown := 0.0
var _slide := 0.0


func setup(camera: Camera3D) -> void:
	cam = camera
	_noise.frequency = 2.5
	var layer := CanvasLayer.new()
	layer.layer = 0                          # pod HUD-em (RaceUI ma warstwę 1)
	add_child(layer)
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx = ShaderMaterial.new()
	fx.shader = preload("res://games/race/speed_fx.gdshader")
	r.material = fx
	layer.add_child(r)
	# pyłki w powietrzu przed kamerą (świat, nie lokalne — mijają kamerę przy jeździe)
	motes = CPUParticles3D.new()
	motes.amount = 160
	motes.lifetime = 3.0
	motes.local_coords = false
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motes.emission_box_extents = Vector3(5, 2, 6)
	motes.position = Vector3(0, 0, -7)
	motes.gravity = Vector3(0, -0.02, 0)
	motes.initial_velocity_min = 0.0
	motes.initial_velocity_max = 0.05
	motes.scale_amount_min = 0.4
	motes.scale_amount_max = 1.0
	motes.mesh = _quad(0.012, Color(1, 0.95, 0.85, 0.3))
	cam.add_child(motes)
	var gs := AudioStreamGenerator.new()
	gs.mix_rate = 22050
	gs.buffer_length = 0.1
	_player = AudioStreamPlayer.new()
	_player.stream = gs
	_player.volume_db = -8
	add_child(_player)


func attach(k: Kredens) -> void:
	car = k
	_prev_v = Vector3.ZERO
	if dust and is_instance_valid(dust):
		dust.queue_free()
	dust = CPUParticles3D.new()
	dust.amount = 60
	dust.lifetime = 0.9
	dust.local_coords = false
	dust.emitting = false
	dust.position = Vector3(0, 0.08, -0.3)
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(0.4, 0.02, k.t.w * 0.4)
	dust.direction = Vector3(0, 1, 0)
	dust.spread = 60
	dust.initial_velocity_min = 0.3
	dust.initial_velocity_max = 1.0
	dust.gravity = Vector3(0, 0.2, 0)
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 3.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.3))
	curve.add_point(Vector2(1, 1))
	dust.scale_amount_curve = curve
	dust.color = Color(0.8, 0.78, 0.72, 0.25)
	dust.mesh = _quad(0.12, Color(1, 1, 1, 1))
	k.add_child(dust)
	if not _player.playing:
		_player.play()
		_gen = _player.get_stream_playback()


static func _quad(size: float, c: Color) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = true
	m.albedo_color = c
	q.material = m
	return q


func hit(strength: float) -> void:
	trauma = minf(1.0, trauma + strength)


## Wywoływane po ustawieniu bazowej pozycji kamery: dokłada FOV, przechył, drżenie i efekty.
## Zwraca [przesunięcie odległości, przesunięcie wysokości] do użycia przy następnym ustawieniu kamery.
func update(dt: float, racing: bool) -> Vector2:
	_t += dt
	if car == null or not is_instance_valid(car):
		return Vector2.ZERO
	var v := car.linear_velocity
	var speed := Vector3(v.x, 0, v.z).length()
	s = lerpf(s, clampf(speed / SPEED_REF, 0.0, 1.0), 1.0 - exp(-dt * 3.0))
	var side := v.dot(car.global_basis.x)
	_slide = lerpf(_slide, clampf((absf(side) - 1.0) / 2.5, 0.0, 1.0), 1.0 - exp(-dt * 8.0))

	# uderzenia: gwałtowna zmiana prędkości
	var dv := (v - _prev_v).length() / maxf(dt, 0.001)
	_prev_v = v
	if racing and dv > 35.0:
		hit(clampf(dv / 140.0, 0.1, 0.8))
		Collection.tone(70 + randf() * 30, 0.3, clampf(dv / 200.0, 0.1, 0.5), 0.75)
	trauma = maxf(0.0, trauma - dt * 1.6)

	# FOV i przechył w zakrętach
	cam.fov = lerpf(cam.fov, lerpf(FOV_MIN, FOV_MAX, pow(s, 1.3)), 1.0 - exp(-dt * 4.0))
	var turn := car.angular_velocity.y
	roll = lerpf(roll, clampf(-turn * 0.05 * (0.3 + s), -0.08, 0.08), 1.0 - exp(-dt * 5.0))
	cam.rotate_object_local(Vector3.FORWARD, roll)

	# drżenie: ciągłe drobne przy prędkości (bruk/łączenia paneli) + trauma
	var amp := 0.004 * s * s + trauma * trauma * 0.05
	cam.h_offset = _noise.get_noise_2d(_t * 40.0, 0.0) * amp * 4.0
	cam.v_offset = _noise.get_noise_2d(0.0, _t * 40.0) * amp * 4.0
	cam.rotate_object_local(Vector3.RIGHT, _noise.get_noise_2d(_t * 30.0, 50.0) * amp)

	fx.set_shader_parameter("speed", s)
	fx.set_shader_parameter("hit", trauma)
	dust.emitting = racing and (_slide > 0.3 or (s > 0.5 and car.flip_t > 0.0))
	motes.speed_scale = 1.0
	_audio(speed)
	return Vector2(-0.8 * s, 0.35 * s)


## Turkot kółek meblowych (brązowy szum + niski ton) i pisk przy poślizgu — generowane na żywo.
func _audio(speed: float) -> void:
	if _gen == null:
		return
	var rate := 22050.0
	var freq := 30.0 + speed * 9.0
	var vol := clampf(speed / 6.0, 0.0, 1.0) * 0.5
	var sq := _slide * 0.25
	var n := _gen.get_frames_available()
	for i in n:
		_phase = fmod(_phase + freq / rate, 1.0)
		_brown = clampf(_brown + randf_range(-0.08, 0.08), -1.0, 1.0) * 0.995
		var rumble := (_brown * 0.7 + sin(_phase * TAU) * 0.3) * vol
		var squeal := sin(_phase * TAU * 31.0 + sin(_phase * TAU * 3.0) * 2.0) * sq
		var x := rumble + squeal
		_gen.push_frame(Vector2(x, x))
