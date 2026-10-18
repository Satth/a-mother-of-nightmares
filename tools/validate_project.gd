extends Node
## Headless smoke validation used by every agent (see CONTRACT.md).
## MUST run as a scene so autoloads are registered:
##   & "C:\Users\Usuario\Downloads\Compressed\Godot_v4.7.2-stable_win64_console.exe" \
##       --headless --path "<project>" res://tools/validate.tscn
## Exits 0 when the foundation is sane, 1 otherwise.

func _ready() -> void:
	var failures: Array[String] = []

	# 1. Input Map
	for action in ["move_left", "move_right", "interact"]:
		if not InputMap.has_action(action):
			failures.append("missing input action: %s" % action)
		elif InputMap.action_get_events(action).is_empty():
			failures.append("input action has no events: %s" % action)

	# 2. Autoloads
	for name in ["GameState", "Dialogue", "HUD", "SceneTransition"]:
		if get_node_or_null("/root/" + name) == null:
			failures.append("missing autoload: %s" % name)

	# 3. Foundation scripts exist and compile
	var script_paths := [
		"res://scripts/autoload/game_state.gd",
		"res://scripts/autoload/dialogue.gd",
		"res://scripts/autoload/hud.gd",
		"res://scripts/autoload/scene_transition.gd",
		"res://scripts/interactions/interactable.gd",
		"res://scripts/player/player_controller.gd",
	]
	for path in script_paths:
		if not ResourceLoader.exists(path):
			failures.append("missing script: %s" % path)

	# 4. GameState behaviour contract (AGENTS.md §6)
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.reset()
		if gs.day != 1 or gs.wood != 0 or gs.has_axe:
			failures.append("GameState.reset did not restore the initial state")
		if not gs.child_present():
			failures.append("child must be present on day 1")
		gs.set_axe(true)
		var counted: int = gs.add_wood(5)
		if gs.wood != 3 or counted != 3:
			failures.append("add_wood must clamp to WOOD_TARGET (got %d/%d)" % [gs.wood, counted])
		if not gs.wood_complete():
			failures.append("wood_complete must be true at the target")
		gs.advance_day()
		if gs.day != 2 or gs.wood != 0 or gs.has_axe:
			failures.append("advance_day must move to day 2 and reset per-day progress")
		gs.advance_day()
		gs.advance_day()
		if gs.day != 3:
			failures.append("day must be capped at 3 (got %d)" % gs.day)
		if gs.child_present():
			failures.append("child must be absent on day 3")
		gs.reset()
		if gs.day != 1 or gs.wood != 0:
			failures.append("reset after day 3 failed")

	# 5. Player scene
	var player_scene := load("res://scenes/player/player.tscn") as PackedScene
	if player_scene == null:
		failures.append("cannot load res://scenes/player/player.tscn")
	else:
		var inst := player_scene.instantiate()
		if inst == null:
			failures.append("cannot instantiate the player scene")
		else:
			if not inst.is_in_group("player"):
				failures.append("player instance is not in group 'player'")
			inst.free()

	if failures.is_empty():
		print("VALIDATE_OK")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("VALIDATE_FAIL: ", f)
		get_tree().quit(1)
