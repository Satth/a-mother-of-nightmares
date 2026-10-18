class_name Interactable
extends Node2D
## Base class for anything the player can press E on.
## Owner: lead. Interface frozen in CONTRACT.md §5.
## Concrete subclasses must declare groups=["interactable"] in their .tscn and,
## if they override _ready(), must call super._ready().

@export var prompt_text := "Interagir"
@export var one_shot := false

var _used := false


func _ready() -> void:
	if not is_in_group("interactable"):
		add_to_group("interactable")


func can_interact() -> bool:
	if one_shot and _used:
		return false
	return true


func get_prompt() -> String:
	return prompt_text


func interact(_by: Node) -> void:
	pass


func mark_used() -> void:
	_used = true
