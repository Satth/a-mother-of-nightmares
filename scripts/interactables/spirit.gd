extends Interactable
## The mother's spirit. Waits in the forest on day 3, blocks the way home
## and ends the run when the player talks to her. Owner: builder-forest.

const ENDING_SCENE := "res://scenes/ending.tscn"

var _done := false


func _ready() -> void:
	super._ready()


func interact(_by: Node) -> void:
	if _done or SceneTransition.is_busy():
		return
	_done = true
	HUD.clear_prompt()
	SceneTransition.transition_to(ENDING_SCENE)
