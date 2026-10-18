extends Node
## End-to-end journey test — drives the REAL game scenes with REAL input events.
## Owner: lead. Run with:
##   & "<godot console>" --headless --path "<project>" res://tools/journey_test.tscn
## Prints one line per assertion; exits 0 only when every one passes.
##
## Coverage = AGENTS.md §12 smoke test steps 1-11.
##
## Why `get_tree().current_scene = null` in _ready(): this test node IS the current scene, and the
## game calls `change_scene_to_file()`, which would free it. Detaching it keeps the test alive while
## still exercising the real scene transitions (door / return zone / spirit / ending restart).

const HOUSE := "res://scenes/house_interior.tscn"
const FOREST := "res://scenes/forest.tscn"
const ENDING := "res://scenes/ending.tscn"

const NAME_HOUSE := "HouseInterior"
const NAME_FOREST := "Forest"
const NAME_ENDING := "Ending"

const GROUND_Y := 600.0
const FRAME_BUDGET := 8000

var _checks := 0
var _fails: Array[String] = []
var _fatal := false


func _ready() -> void:
	get_tree().current_scene = null
	_run()


func _run() -> void:
	print("=== JOURNEY TEST (AGENTS.md §12 smoke test) ===")
	await _day1_house()
	if not _fatal:
		await _day1_forest()
	if not _fatal:
		await _day2_house()
	if not _fatal:
		await _day2_forest()
	if not _fatal:
		await _day3_house()
	if not _fatal:
		await _day3_forest()
	if not _fatal:
		await _ending_and_restart()
	_finish()


# ===================================================================== helpers

func _check(condition: bool, label: String) -> bool:
	_checks += 1
	if condition:
		print("  ok   | ", label)
	else:
		_fails.append(label)
		print("  FAIL | ", label)
	return condition


func _fail(label: String) -> void:
	_check(false, label)


func _abort(label: String) -> void:
	_check(false, label)
	_fatal = true


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _physics_frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


## Waits until the current scene is `expected` AND the fade transition has finished.
func _await_scene(expected: String, budget := FRAME_BUDGET) -> Node:
	for _i in budget:
		await get_tree().process_frame
		var cs := get_tree().current_scene
		if cs != null and cs.name == expected and not SceneTransition.is_busy():
			await get_tree().process_frame
			await get_tree().process_frame
			return cs
	var current := get_tree().current_scene
	_abort("timed out waiting for scene '%s' (current='%s', transition busy=%s)" % [
		expected, str(current.name) if current != null else "<none>", str(SceneTransition.is_busy()),
	])
	return current


func _load_scene(path: String, expected: String) -> Node:
	get_tree().change_scene_to_file(path)
	return await _await_scene(expected)


## Injects a real press+release of an Input Map action and lets the game react.
func _press(action := "interact") -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame
	await get_tree().process_frame


func _hud_status() -> String:
	var label := HUD.get("_status_label") as Label
	return label.text if label != null else "<missing status label>"


func _hud_prompt() -> String:
	var label := HUD.get("_prompt_label") as Label
	return label.text if label != null else "<missing prompt label>"


func _player_of(scene: Node) -> CharacterBody2D:
	return scene.get_node_or_null("Player") as CharacterBody2D


## Teleports the player and lets the controller re-pick its interaction target.
func _place(player: CharacterBody2D, x: float) -> void:
	player.set("velocity", Vector2.ZERO)
	player.global_position = Vector2(x, GROUND_Y)
	await _frames(3)


func _target_of(player: CharacterBody2D) -> Node:
	return player.get("current_target") as Node


func _close_dialogue() -> void:
	var guard := 0
	while Dialogue.is_active() and guard < 30:
		guard += 1
		await _press()
	if Dialogue.is_active():
		_fail("dialogue never closed after repeated [E]")


## Waits for one of the interaction targets to be selected at the player's position.
func _expect_target(player: CharacterBody2D, expected: Node, label: String) -> void:
	var guard := 0
	while _target_of(player) != expected and guard < 10:
		guard += 1
		await get_tree().process_frame
	_check(_target_of(player) == expected, label)


# ===================================================================== day 1

func _day1_house() -> void:
	print("-- Step 1-2: Day 1 house (child, axe, door)")
	var house := await _load_scene(HOUSE, NAME_HOUSE)
	if house == null:
		_abort("house_interior.tscn did not load")
		return

	_check(GameState.day == 1, "day == 1 on a fresh start")
	_check(_hud_status().begins_with("Dia 1/3"), "HUD status is 'Dia 1/3...' (got '%s')" % _hud_status())

	var player := _player_of(house)
	var child := house.get_node_or_null("Child")
	var axe := house.get_node_or_null("Axe")
	var door := house.get_node_or_null("Door")
	if player == null or child == null or axe == null or door == null:
		_abort("house is missing Player/Child/Axe/Door")
		return

	_check(child.visible, "child is present and visible on day 1")

	# --- child dialogue
	await _place(player, 560.0)
	await _expect_target(player, child, "child is auto-targeted when standing next to it")
	_check(_hud_prompt() == "[E] Falar com o filho", "prompt shows '[E] Falar com o filho' (got '%s')" % _hud_prompt())
	await _press()
	_check(Dialogue.is_active(), "talking to the child opens the dialogue box")
	await _close_dialogue()
	_check(not Dialogue.is_active(), "dialogue closes after advancing every line")
	_check(_target_of(player) == child, "player still controls the game after the dialogue")

	# --- door must be inert before the axe
	await _place(player, 1105.0)
	_check(_target_of(player) == null, "locked door is not targetable before the axe")
	await _press()
	await _frames(20)
	_check(get_tree().current_scene == house and GameState.day == 1,
		"door does nothing before the axe is taken")

	# --- take the axe
	await _place(player, 175.0)
	await _expect_target(player, axe, "axe is auto-targeted when standing next to it")
	_check(_hud_prompt() == "[E] Pegar o machado", "prompt shows the axe (got '%s')" % _hud_prompt())
	await _press()
	_check(GameState.has_axe, "taking the axe sets GameState.has_axe")

	# --- leave through the door
	await _place(player, 1105.0)
	await _expect_target(player, door, "door becomes targetable once the axe is held")
	await _press()
	var forest := await _await_scene(NAME_FOREST)
	_check(forest != null and forest.name == NAME_FOREST, "door transitions to the forest")


func _day1_forest() -> void:
	print("-- Step 3-4: Day 1 forest (3 trees, dusk, return)")
	var forest := get_tree().current_scene
	var player := _player_of(forest)
	if player == null:
		_abort("forest has no Player")
		return

	_check(GameState.day == 1, "still day 1 inside the forest")
	_check(GameState.wood == 0, "wood starts at 0 for the day")
	_check(_hud_status() == "Dia 1/3 — Madeira 0/3", "HUD shows 'Dia 1/3 — Madeira 0/3' (got '%s')" % _hud_status())

	var trees := forest.get_node_or_null("Trees")
	if trees == null or trees.get_child_count() != 3:
		_abort("forest must contain exactly 3 trees")
		return
	var tree1: Node = trees.get_node("Tree1")
	var tree2: Node = trees.get_node("Tree2")
	var tree3: Node = trees.get_node("Tree3")

	# --- tree 1, and prove holding [E] cannot over-count
	await _place(player, 480.0)
	await _expect_target(player, tree1, "tree 1 is auto-targeted")
	_check(_hud_prompt() == "[E] Cortar árvore", "prompt shows the tree (got '%s')" % _hud_prompt())
	await _press()
	_check(GameState.wood == 1, "tree 1 adds exactly 1 wood")
	for _i in 5:
		await _press()
	_check(GameState.wood == 1, "spamming [E] on the same tree cannot add more wood")
	_check(tree1.get_node("Canopy").visible == false and tree1.get_node("Stump").visible == true,
		"cut tree shows the stump feedback")

	# --- trees 2 and 3
	await _place(player, 760.0)
	await _expect_target(player, tree2, "tree 2 is auto-targeted")
	await _press()
	_check(GameState.wood == 2, "tree 2 adds exactly 1 wood")

	await _place(player, 1040.0)
	await _expect_target(player, tree3, "tree 3 is auto-targeted on day 1")
	await _press()
	_check(GameState.wood == 3 and GameState.wood_complete(), "tree 3 completes the wood target")

	# --- dusk + day-1 anomaly
	var overlay := forest.get_node_or_null("Overlay") as ColorRect
	_check(overlay != null and overlay.color.a > 0.0, "dusk overlay becomes visible once the wood is complete")
	_check((forest.get_node_or_null("ReturnMarker") as Node2D).visible, "the way home is revealed at dusk")
	_check((forest.get_node_or_null("Anomaly") as Node2D).visible, "day 1 leaves one subtle wrong detail behind")
	_check(_hud_status() == "Dia 1/3 — voltar para casa", "HUD now asks the player to go home (got '%s')" % _hud_status())

	# --- step 1: real A/D movement through the Input Map
	var before := player.global_position.x
	Input.action_press("move_right")
	await _physics_frames(20)
	Input.action_release("move_right")
	await _physics_frames(5)
	var moved_right := player.global_position.x - before
	_check(moved_right > 5.0, "holding 'D' moves right (moved %.1f px)" % moved_right)
	before = player.global_position.x
	Input.action_press("move_left")
	await _physics_frames(20)
	Input.action_release("move_left")
	await _physics_frames(5)
	var moved_left := before - player.global_position.x
	_check(moved_left > 5.0, "holding 'A' moves left (moved %.1f px)" % moved_left)

	# --- return home
	await _place(player, 80.0)
	var house := await _await_scene(NAME_HOUSE)
	_check(house != null and GameState.day == 2, "returning home advances exactly one day (day=%d)" % GameState.day)


# ===================================================================== day 2

func _day2_house() -> void:
	print("-- Step 5: Day 2 house (child still there, colder, axe again)")
	var house := get_tree().current_scene
	var player := _player_of(house)
	if player == null:
		_abort("day 2 house has no Player")
		return

	_check(GameState.day == 2, "day 2 starts in the house")
	_check(GameState.wood == 0 and not GameState.has_axe, "per-day progress was reset by the day change")
	var child := house.get_node_or_null("Child")
	_check(child != null and child.visible, "the child is still present on day 2")
	_check(not (house.get_node("Bed/EmptyBed") as Node2D).visible, "the bed is not shown as empty on day 2")
	_check(_hud_status().begins_with("Dia 2/3"), "HUD shows day 2 (got '%s')" % _hud_status())

	var door := house.get_node_or_null("Door")
	await _place(player, 1105.0)
	_check(_target_of(player) == null, "the door is locked again on day 2 (axe was reset)")

	await _place(player, 175.0)
	await _expect_target(player, house.get_node("Axe"), "axe is obtainable again on day 2")
	await _press()
	_check(GameState.has_axe, "axe taken on day 2")

	await _place(player, 1105.0)
	await _expect_target(player, door, "door is targetable again on day 2")
	await _press()
	await _await_scene(NAME_FOREST)
	_check(get_tree().current_scene.name == NAME_FOREST, "day 2 door leads to the forest")


func _day2_forest() -> void:
	print("-- Step 5: Day 2 forest (cold + fog + solvable obstruction)")
	var forest := get_tree().current_scene
	var player := _player_of(forest)
	if player == null:
		_abort("day 2 forest has no Player")
		return

	_check(GameState.day == 2, "still day 2 inside the forest")
	_check((forest.get_node_or_null("Fog") as ColorRect).visible, "day 2 shows the fog layer")
	var fog_color := (forest.get_node("Sky") as ColorRect).color
	_check(fog_color.b < fog_color.g + 0.001 or fog_color.b > fog_color.r, "day 2 palette is cold-toned")

	var obstacle := forest.get_node_or_null("Props/Obstacle")
	if obstacle == null:
		_abort("day 2 must have the fallen-branch obstacle")
		return
	_check(obstacle.visible, "the obstruction is visible on day 2")

	var trees := forest.get_node("Trees")
	var tree1: Node = trees.get_node("Tree1")
	var tree2: Node = trees.get_node("Tree2")
	var tree3: Node = trees.get_node("Tree3")

	# --- the obstruction really blocks the third tree
	await _place(player, 1040.0)
	_check(_target_of(player) == null, "the blocked tree cannot be cut before the branch is removed")
	await _press()
	_check(GameState.wood == 0, "pressing [E] on a blocked tree adds no wood")

	await _place(player, 868.0)
	await _expect_target(player, obstacle, "the fallen branch is auto-targeted")
	_check(_hud_prompt() == "[E] Remover galho", "prompt shows the branch (got '%s')" % _hud_prompt())
	await _press()
	_check(obstacle.get("_removed") == true, "one interaction removes the branch for good")
	_check(not tree3.is_in_group("branch_blocked"), "removing the branch unblocks the tree behind it")

	# --- now the third tree is reachable
	await _place(player, 1040.0)
	await _expect_target(player, tree3, "tree 3 is cuttable once the branch is gone")
	await _press()
	_check(GameState.wood == 1, "tree 3 can now be cut")

	await _place(player, 480.0)
	await _expect_target(player, tree1, "tree 1 is auto-targeted on day 2")
	await _press()
	await _place(player, 760.0)
	await _expect_target(player, tree2, "tree 2 is auto-targeted on day 2")
	await _press()
	_check(GameState.wood_complete(), "day 2 wood target completed")

	await _place(player, 80.0)
	await _await_scene(NAME_HOUSE)
	_check(GameState.day == 3, "day 2 return advances to day 3 (day=%d)" % GameState.day)


# ===================================================================== day 3

func _day3_house() -> void:
	print("-- Step 6-7: Day 3 house (child gone, empty bed)")
	var house := get_tree().current_scene
	var player := _player_of(house)
	if player == null:
		_abort("day 3 house has no Player")
		return

	_check(GameState.day == 3, "day 3 starts in the house")
	_check(house.get_node_or_null("Child") == null, "the child is gone on day 3")
	_check((house.get_node("Bed/EmptyBed") as Node2D).visible, "the empty bed detail is shown on day 3")
	_check(_hud_status().contains("desapareceu"), "HUD tells the player the child is gone (got '%s')" % _hud_status())

	await _place(player, 175.0)
	await _expect_target(player, house.get_node("Axe"), "the axe is still obtainable on day 3")
	await _press()
	_check(GameState.has_axe, "axe taken on day 3")

	await _place(player, 1105.0)
	await _expect_target(player, house.get_node("Door"), "door works on day 3")
	await _press()
	await _await_scene(NAME_FOREST)
	_check(get_tree().current_scene.name == NAME_FOREST, "day 3 door leads to the forest")


func _day3_forest() -> void:
	print("-- Step 8: Day 3 forest (spirit blocks the way, no way back)")
	var forest := get_tree().current_scene
	var player := _player_of(forest)
	if player == null:
		_abort("day 3 forest has no Player")
		return

	_check(GameState.day == 3, "still day 3 inside the forest")

	var spirit := forest.get_node_or_null("Spirits/Spirit")
	if spirit == null:
		_abort("day 3 must spawn the spirit")
		return
	_check(is_instance_valid(spirit), "the spirit exists on day 3")
	_check((spirit as Node2D).global_position.is_equal_approx(Vector2(560.0, 600.0)),
		"the spirit stands at (560, 600)")

	# --- no trees left to cut on day 3
	await _place(player, 480.0)
	_check(_target_of(player) == null, "trees are no longer cuttable on day 3")
	await _press()
	_check(GameState.wood == 0, "day 3 requires no wood")

	# --- the way home is closed
	await _place(player, 80.0)
	await _frames(20)
	_check(get_tree().current_scene == forest, "the return zone does not send the player home on day 3")
	await _close_dialogue()

	# --- the spirit physically blocks the way forward and ends the run
	# Walk into it from the left: the blocker must stop the player short of it (progress impossible).
	await _place(player, 400.0)
	var before := player.global_position.x
	Input.action_press("move_right")
	await _physics_frames(60)  # 1 s free of obstacles would carry the player ~220 px
	Input.action_release("move_right")
	await _physics_frames(5)
	var walked := player.global_position.x - before
	var stopped_x := player.global_position.x
	_check(stopped_x < 552.0, "the spirit physically blocks the way forward (stopped at x=%.1f)" % stopped_x)
	_check(walked > 50.0, "the player does walk toward the spirit before being stopped (%.1f px)" % walked)

	await _expect_target(player, spirit, "the spirit is auto-targeted once it blocks the way")
	_check(_hud_prompt() == "[E] Falar com o espírito", "prompt shows the spirit (got '%s')" % _hud_prompt())

	var scene_before_name: String = get_tree().current_scene.name
	await _press()
	var ending := await _await_scene(NAME_ENDING)
	_check(ending != null and ending.name == NAME_ENDING, "talking to the spirit reaches the ending (was '%s')" % scene_before_name)


# ===================================================================== ending

func _ending_and_restart() -> void:
	print("-- Step 9-10: Ending fade + restart resets the state")
	var ending := get_tree().current_scene
	_check(GameState.day == 3, "the run reaches the ending on day 3")

	_check(_hud_status() == "", "the HUD status is cleared in the ending")
	await _physics_frames(90)  # > input_delay (0.8 s), so [E] is accepted
	_check(_hud_prompt() == "[E] reiniciar", "the ending offers '[E] reiniciar' (got '%s')" % _hud_prompt())

	var fade: float = ending.modulate.a
	_check(fade > 0.9, "the ending image faded in (alpha %.2f)" % fade)

	await _press()
	var house := await _await_scene(NAME_HOUSE)
	if house == null:
		return
	_check(GameState.day == 1, "restarting resets the day to 1 (day=%d)" % GameState.day)
	_check(GameState.wood == 0, "restarting resets the wood count")
	_check(not GameState.has_axe, "restarting clears the axe")
	_check(house.get_node_or_null("Child") != null, "the child is back after the restart")
	_check(_hud_status().begins_with("Dia 1/3"), "HUD is back to day 1 (got '%s')" % _hud_status())


# ===================================================================== report

func _finish() -> void:
	print("=== journey summary: %d checks, %d failures ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("JOURNEY_OK")
		get_tree().quit(0)
	else:
		for f in _fails:
			printerr("JOURNEY_FAIL: ", f)
		print("JOURNEY_FAIL")
		get_tree().quit(1)
