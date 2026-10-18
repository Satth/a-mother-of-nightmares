extends Node2D
## Ending scene. Owner: builder-forest. Interface: CONTRACT.md §6.
##
## Dark placeholder "image" (a dim silhouette + a closing line) that fades in, then waits for
## [E] to reset GameState and start over at the house. Input is ignored for the first moments so
## the same key press that arrived from the forest cannot restart the game instantly.

const HOUSE_SCENE := "res://scenes/house_interior.tscn"

@export var fade_in_duration := 1.0
@export var input_delay := 0.8

var _elapsed := 0.0
var _accepts_input := false
var _restarting := false


func _ready() -> void:
	HUD.set_status("")
	HUD.clear_prompt()
	modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)


func _process(delta: float) -> void:
	if _accepts_input:
		return
	_elapsed += delta
	if _elapsed >= input_delay:
		_accepts_input = true
		HUD.set_prompt("reiniciar")


func _unhandled_input(event: InputEvent) -> void:
	if not _accepts_input or _restarting:
		return
	if event.is_action_pressed("interact"):
		_restarting = true
		get_viewport().set_input_as_handled()
		HUD.clear_prompt()
		GameState.reset()
		SceneTransition.transition_to(HOUSE_SCENE)
