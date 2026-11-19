extends SceneTree
## Ładuje wszystkie skrypty — wyłapuje błędy parsowania.

func _init() -> void:
	for p in ["res://core/collection.gd", "res://menu/xmb.gd", "res://games/klamka/handle_sim.gd", "res://games/klamka/klamka.gd",
			"res://games/race/apartment.gd", "res://games/race/kredens.gd", "res://games/race/race.gd",
			"res://games/paint/paint_time.gd", "res://games/paint/paint.gd", "res://games/race/tournament.gd", "res://games/race/player_input.gd", "res://games/race/lobby.gd",
			"res://games/paint/paint_mask.gd", "res://games/paint/paint_props.gd",
			"res://games/race/decor.gd", "res://games/race/maps/m4.gd", "res://games/race/maps/podziemny.gd", "res://games/race/maps/doki.gd", "res://games/race/maps/kanaly.gd", "res://games/race/maps.gd", "res://games/race/track_check.gd", "res://games/race/backdrop.gd",
			"res://core/achievements.gd"]:
		var s: Script = load(p)
		print(("ok   " if s and s.can_instantiate() else "FAIL ") + p)
	quit()
