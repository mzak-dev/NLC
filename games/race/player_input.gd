class_name PlayerInput
extends RefCounted
## Wejście per urządzenie (couch co-op). Urządzenia: "any" (dzisiejsze akcje: klawiatura + każdy pad),
## "kb" (cała klawiatura, tylko w poczekalni), "kb_a" (WASD), "kb_b" (strzałki), "pad<N>" (N = InputEvent.device).

const DEAD := 0.15       # strefa martwa gałki w jeździe
const MENU_STICK := 0.6  # próg gałki w menu poczekalni

static var _rshift := false
static var _rctrl := false
static var _stick: Dictionary = {}    # "device:oś" -> -1/0/1, żeby gałka wysyłała zdarzenie tylko przy przekroczeniu progu


## Prawy Shift (ręczny) i prawy Ctrl (postaw) dla kb_b — wołać z _input z każdym zdarzeniem.
static func feed(e: InputEvent) -> void:
	var k := e as InputEventKey
	if k == null:
		return
	if k.physical_keycode == KEY_SHIFT and k.location == KEY_LOCATION_RIGHT:
		_rshift = k.pressed
	elif k.physical_keycode == KEY_CTRL and k.location == KEY_LOCATION_RIGHT:
		_rctrl = k.pressed


## {throttle -1..1, steer (+ = w lewo), handbrake, reset}
static func read(device: String) -> Dictionary:
	var r := {"throttle": 0.0, "steer": 0.0, "handbrake": false, "reset": false}
	match device:
		"any":    # jeden człowiek: akcje, czyli klawiatura + każdy pad
			r.throttle = Input.get_action_strength("drive_forward") - Input.get_action_strength("drive_back")
			r.steer = Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")
			r.handbrake = Input.is_action_pressed("handbrake")
			r.reset = Input.is_action_pressed("reset_car")
		"kb":     # cała klawiatura, bez padów (akcje są podpięte też pod pady innych graczy)
			var a := read("kb_a")
			var b := read("kb_b")
			r.throttle = clampf(a.throttle + b.throttle, -1.0, 1.0)
			r.steer = clampf(a.steer + b.steer, -1.0, 1.0)
			r.handbrake = a.handbrake or b.handbrake
			r.reset = a.reset or b.reset
		"kb_a":
			r.throttle = _key(KEY_W) - _key(KEY_S)
			r.steer = _key(KEY_A) - _key(KEY_D)
			r.handbrake = Input.is_physical_key_pressed(KEY_SPACE)
			r.reset = Input.is_physical_key_pressed(KEY_R)
		"kb_b":
			r.throttle = _key(KEY_UP) - _key(KEY_DOWN)
			r.steer = _key(KEY_LEFT) - _key(KEY_RIGHT)
			r.handbrake = _rshift
			r.reset = _rctrl
		_:
			if device.begins_with("pad"):
				var n := device.substr(3).to_int()
				r.throttle = Input.get_joy_axis(n, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(n, JOY_AXIS_TRIGGER_LEFT)
				var x := Input.get_joy_axis(n, JOY_AXIS_LEFT_X)
				r.steer = 0.0 if absf(x) < DEAD else -x
				r.handbrake = Input.is_joy_button_pressed(n, JOY_BUTTON_X)
				r.reset = Input.is_joy_button_pressed(n, JOY_BUTTON_Y)
	return r


static func _key(code: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(code) else 0.0


## Zdarzenie -> [urządzenie, akcja] poczekalni albo []. Akcje: join leave accept back left right up down reroll.
static func lobby_event(e: InputEvent) -> Array:
	var k := e as InputEventKey
	if k != null:
		if not k.pressed or k.echo:
			return []
		match k.physical_keycode:
			KEY_SPACE: return ["kb_a", "join"]
			KEY_SHIFT: return ["kb_b", "join"] if k.location == KEY_LOCATION_RIGHT else []
			KEY_Q: return ["kb_a", "leave"]
			KEY_DELETE: return ["kb_b", "leave"]
			KEY_ENTER, KEY_KP_ENTER: return ["kb", "accept"]
			KEY_BACKSPACE: return ["kb", "back"]
			KEY_TAB: return ["kb", "reroll"]
			KEY_W: return ["kb_a", "up"]
			KEY_S: return ["kb_a", "down"]
			KEY_A: return ["kb_a", "left"]
			KEY_D: return ["kb_a", "right"]
			KEY_UP: return ["kb_b", "up"]
			KEY_DOWN: return ["kb_b", "down"]
			KEY_LEFT: return ["kb_b", "left"]
			KEY_RIGHT: return ["kb_b", "right"]
		return []
	var b := e as InputEventJoypadButton
	if b != null:
		if not b.pressed:
			return []
		var dev := "pad%d" % b.device
		match b.button_index:
			JOY_BUTTON_A: return [dev, "join"]
			JOY_BUTTON_B: return [dev, "leave"]
			JOY_BUTTON_Y: return [dev, "reroll"]
			JOY_BUTTON_DPAD_UP: return [dev, "up"]
			JOY_BUTTON_DPAD_DOWN: return [dev, "down"]
			JOY_BUTTON_DPAD_LEFT: return [dev, "left"]
			JOY_BUTTON_DPAD_RIGHT: return [dev, "right"]
		return []
	var m := e as InputEventJoypadMotion
	if m != null and (m.axis == JOY_AXIS_LEFT_X or m.axis == JOY_AXIS_LEFT_Y):
		var key := "%d:%d" % [m.device, m.axis]
		var now := 0 if absf(m.axis_value) < MENU_STICK else (1 if m.axis_value > 0.0 else -1)
		var was: int = _stick.get(key, 0)
		_stick[key] = now
		if now == 0 or now == was:
			return []
		var d := "pad%d" % m.device
		if m.axis == JOY_AXIS_LEFT_X:
			return [d, "right" if now > 0 else "left"]
		return [d, "down" if now > 0 else "up"]
	return []
