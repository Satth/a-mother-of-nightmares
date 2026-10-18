extends Node
## Visual verification tool. Owner: lead.
##
## The Godot MCP bridge is offline for this session, so this replaces its screenshot ability.
## It loads every day of every playable scene through the REAL scenes, waits for the renderer,
## and writes a PNG plus the mean luminance of the frame (objective "is it actually drawn, and is
## it a black screen?" evidence).
##
## Run it WITHOUT --headless (a real rendering device is required):
##   & "<godot console>" --path "<project>" res://tools/screenshots.tscn
##
## Output: `SHOT <path> size=<w>x<h> mean_luma=<0..1>` per captured frame, exit 0.

const OUT_DIR := "C:/Users/Usuario/AppData/Local/Temp/opencode/screens"

const HOUSE := "res://scenes/house_interior.tscn"
const FOREST := "res://scenes/forest.tscn"
const ENDING := "res://scenes/ending.tscn"

const NAME_HOUSE := "HouseInterior"
const NAME_FOREST := "Forest"
const NAME_ENDING := "Ending"

const GROUND_Y := 600.0

var _shots := 0


func _ready() -> void:
	get_tree().current_scene = null
	_run()


func _run() -> void:
	var abs_dir := DirAccess.make_dir_recursive_absolute(OUT_DIR)
	print("SHOT_DIR ", OUT_DIR, " (created=", abs_dir == OK, ")")

	# ---- house, one frame per day
	for day in [1, 2, 3]:
		await _set_day(day)
		var house := await _load(HOUSE, NAME_HOUSE)
		await _settle(30)
		if day == 1:
			# Talking to the child: the player must first stand next to the child, otherwise there is
			# no interaction target and no prompt. (Caught by the identical luma of the first two
			# shots in the previous run.) Prompt first, then the dialogue box.
			var player := house.get_node_or_null("Player") as CharacterBody2D
			var child := house.get_node_or_null("Child")
			if player != null:
				_place(player, 560.0)
				await _settle(20)
			await _capture("house_day1_prompt_child")
			if player != null and child != null and player.get("current_target") == child:
				child.call("interact", player)
			else:
				printerr("SHOT_NO_CHILD_TARGET: prompt shot did not target the child")
			await _settle(40)
			if Dialogue.is_active():
				await _capture("house_day1_dialogue")
			else:
				printerr("SHOT_DIALOGUE_NOT_OPEN")
		elif day == 2:
			await _capture("house_day2")
		else:
			await _capture("house_day3_empty_bed")

	# ---- forest, one frame per day (plus day 1 before/after chopping)
	for day in [1, 2, 3]:
		await _set_day(day)
		var forest := await _load(FOREST, NAME_FOREST)
		var player := forest.get_node_or_null("Player") as CharacterBody2D
		await _settle(30)
		await _capture("forest_day%d_start" % day)

		if day == 1:
			if player != null:
				_place(player, 480.0)
				await _settle(20)
				await _capture("forest_day1_at_tree")
			GameState.add_wood(3)
			await _settle(40)
			if player != null:
				_place(player, 1040.0)
			await _settle(20)
			await _capture("forest_day1_dusk")
		elif day == 2:
			if player != null:
				_place(player, 868.0)
			await _settle(20)
			await _capture("forest_day2_branch")
		else:
			if player != null:
				_place(player, 400.0)
				Input.action_press("move_right")
				await _wait_physics(60)
				Input.action_release("move_right")
			await _settle(20)
			await _capture("forest_day3_spirit_blocks")

	# ---- ending
	await _set_day(3)
	await _load(ENDING, NAME_ENDING)
	await _wait_physics(120)  # let the fade-in finish
	await _capture("ending")

	print("=== %d screenshots written to %s ===" % [_shots, OUT_DIR])
	print("SCREENSHOTS_OK")
	get_tree().quit(0)


# ------------------------------------------------------------------ helpers

func _set_day(day: int) -> void:
	# Goes through the real signals so the HUD and the Atmosphere autoload stay in sync.
	GameState.reset()
	for _i in (day - 1):
		GameState.advance_day()
	await get_tree().process_frame


func _load(path: String, expected: String) -> Node:
	get_tree().change_scene_to_file(path)
	for _i in 900:
		await get_tree().process_frame
		var cs := get_tree().current_scene
		if cs != null and cs.name == expected:
			return cs
	printerr("SHOT_LOAD_FAILED: ", path)
	return get_tree().current_scene


func _settle(frames: int) -> void:
	for _i in frames:
		await get_tree().process_frame


func _wait_physics(frames: int) -> void:
	for _i in frames:
		await get_tree().physics_frame


func _place(player: CharacterBody2D, x: float) -> void:
	player.set("velocity", Vector2.ZERO)
	player.global_position = Vector2(x, GROUND_Y)


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	if tex == null:
		printerr("SHOT_NO_VIEWPORT_TEXTURE: ", name)
		return
	var img := tex.get_image()
	if img == null:
		printerr("SHOT_NO_IMAGE: ", name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var err := img.save_png(path)
	_shots += 1
	print("SHOT %s size=%dx%d mean_luma=%.3f err=%d" % [
		path, img.get_width(), img.get_height(), _mean_luma(img), err,
	])


## Mean luminance of a coarse sample of the frame: a black screen reads ~0.0, a lit scene much more.
func _mean_luma(img: Image) -> float:
	var total := 0.0
	var samples := 0
	var step_x: int = maxi(1, img.get_width() / 64)
	var step_y: int = maxi(1, img.get_height() / 36)
	var x := 0
	while x < img.get_width():
		var y := 0
		while y < img.get_height():
			var c := img.get_pixel(x, y)
			total += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			samples += 1
			y += step_y
		x += step_x
	if samples == 0:
		return 0.0
	return total / float(samples)
