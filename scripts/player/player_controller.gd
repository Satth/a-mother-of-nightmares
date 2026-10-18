class_name PlayerController
extends CharacterBody2D
## Side-scroller controller: left/right only (no jump), plus E interaction.
## Owner: lead. Interface frozen in CONTRACT.md §4.

signal interacted(target: Node)

@export var speed := 220.0
@export var acceleration := 1800.0
@export var friction := 2400.0
@export var interact_range := 60.0

var input_enabled := true
var current_target: Node = null

var _visual: Node2D


func _ready() -> void:
	add_to_group("player")
	_visual = get_node_or_null("Visual")


func set_input_enabled(value: bool) -> void:
	input_enabled = value
	if not value:
		current_target = null
		HUD.clear_prompt()


func _physics_process(delta: float) -> void:
	velocity.y = 0.0
	var dir := 0.0
	if _accepts_movement():
		dir = Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	move_and_slide()
	if is_instance_valid(_visual):
		var s := signf(velocity.x)
		if absf(s) > 0.01:
			_visual.scale.x = absf(_visual.scale.x) * (1.0 if s > 0.0 else -1.0)


func _accepts_movement() -> bool:
	return input_enabled and not Dialogue.is_active() and not SceneTransition.is_busy()


func _process(_delta: float) -> void:
	_update_target()


func _update_target() -> void:
	if not input_enabled or Dialogue.is_active() or SceneTransition.is_busy():
		if current_target != null:
			current_target = null
			HUD.clear_prompt()
		return

	var best: Node = null
	var best_dist := interact_range * interact_range
	for node in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(node):
			continue
		if not (node is Node2D):
			continue
		if node.has_method("can_interact") and not node.can_interact():
			continue
		var d: float = (node as Node2D).global_position.distance_squared_to(global_position)
		if d <= best_dist:
			best_dist = d
			best = node

	if best != current_target:
		current_target = best
		if current_target != null and current_target.has_method("get_prompt"):
			HUD.set_prompt(current_target.get_prompt())
		else:
			HUD.clear_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if Dialogue.is_active() or SceneTransition.is_busy():
		return
	if event.is_action_pressed("interact") and is_instance_valid(current_target):
		current_target.interact(self)
		interacted.emit(current_target)
		get_viewport().set_input_as_handled()
