extends "res://scripts/interactions/interactable.gd"
## The front door: exit to the forest for the day's work.
## Locked until the axe has been taken (GameState.has_axe).
## Owner: builder-core (CONTRACT.md §1/§6).

const FOREST_SCENE := "res://scenes/forest.tscn"

@onready var _visual: Node2D = get_node_or_null("Visual")


func _ready() -> void:
	super._ready()
	if not GameState.axe_changed.is_connected(_on_axe_changed):
		GameState.axe_changed.connect(_on_axe_changed)
	_refresh()


## The door must not work before the axe is obtained.
func can_interact() -> bool:
	if not GameState.has_axe:
		return false
	if SceneTransition.is_busy():
		return false
	return super.can_interact()


func interact(_by: Node) -> void:
	if not can_interact():
		return
	SceneTransition.transition_to(FOREST_SCENE)


func _on_axe_changed(_has_axe: bool) -> void:
	_refresh()


## Dim the door while it is locked; full colour once it can be opened.
func _refresh() -> void:
	if is_instance_valid(_visual):
		_visual.modulate = Color(1, 1, 1, 1) if GameState.has_axe else Color(0.45, 0.45, 0.5, 1)
