extends "res://scripts/interactions/interactable.gd"
## The axe, hanging at home. Taking it unlocks the door.
## Owner: builder-core (CONTRACT.md §1/§6).

@onready var _visual: Node2D = get_node_or_null("Visual")


func _ready() -> void:
	super._ready()
	_refresh()


## Not interactable once the player already carries the axe.
func can_interact() -> bool:
	if GameState.has_axe:
		return false
	return super.can_interact()


func interact(_by: Node) -> void:
	if not can_interact():
		return
	GameState.set_axe(true)
	mark_used()
	_refresh()


func _refresh() -> void:
	if is_instance_valid(_visual):
		_visual.visible = not GameState.has_axe
