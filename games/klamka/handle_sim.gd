class_name HandleSim
extends RefCounted
## Klamka jako obrotowa masa ze sprężyną powrotną (z napięciem wstępnym), tłumieniem,
## tarciem Coulomba i dwoma ogranicznikami z restytucją.
## θ = 0: spoczynek (oparta o górny ogranicznik), θ = theta_max: wciśnięta do oporu.

var inertia := 0.0012       # kg·m²
var stiffness := 2.2        # N·m/rad
var preload_rad := 0.5          # rad — napięcie wstępne dociska klamkę do ogranicznika
var damping := 0.004        # N·m·s/rad
var friction := 0.012       # N·m
var restitution := 0.45     # 0 = martwe uderzenie, 1 = idealne odbicie
var theta_max := deg_to_rad(45.0)
var lever := 0.09           # m — ramię siły (miejsce chwytu)
var bounce_speed := 0.8     # rad/s — wolniejsze uderzenia nie liczą się jako odbicia

var theta := 0.0
var omega := 0.0
var bounces := 0
var max_theta := 0.0
var last_impact := 0.0      # prędkość ostatniego odbicia (do dźwięku)


## Siła [N] potrzebna, żeby klamka w ogóle drgnęła.
func breakaway_force() -> float:
	return (stiffness * preload_rad + friction) / lever


func step(force_n: float, dt: float, substeps := 16) -> void:
	var h := dt / substeps
	for i in substeps:
		var torque := force_n * lever - stiffness * (theta + preload_rad) - damping * omega
		if absf(omega) > 1e-3:
			torque -= friction * signf(omega)
		elif absf(torque) <= friction:
			torque = 0.0
		else:
			torque -= friction * signf(torque)
		omega += torque / inertia * h
		theta += omega * h
		_hit_stop(force_n == 0.0)
		max_theta = maxf(max_theta, theta)


## counts: liczyć odbicia tylko gdy klamka jest puszczona — dociskanie ręką do oporu to nie odbicia.
func _hit_stop(counts := true) -> void:
	var v := 0.0
	if theta < 0.0 and omega < 0.0:
		theta = 0.0
		v = -omega
	elif theta > theta_max and omega > 0.0:
		theta = theta_max
		v = omega
	else:
		theta = clampf(theta, 0.0, theta_max)
		return
	if v > bounce_speed:
		if counts:
			bounces += 1
			last_impact = v
		omega = -omega * restitution
	else:
		omega = 0.0


func at_rest() -> bool:
	return theta == 0.0 and absf(omega) < 1e-3
