extends Interactable
## Fallen branch that blocks the way to the third tree (day 2 only). Owner: builder-forest.
##
## One interaction removes it for good: the visual disappears, the physical blocker is destroyed
## and the trees waiting behind it become cuttable again.

var _removed := false


func _ready() -> void:
	super._ready()


func is_removed() -> bool:
	return _removed


func can_interact() -> bool:
	if _removed:
		return false
	return super.can_interact()


func interact(_by: Node) -> void:
	if not can_interact():
		return
	_removed = true
	mark_used()
	_clear()


func _clear() -> void:
	for child in get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = false
		if child is CollisionObject2D:
			child.queue_free()
	for node in get_tree().get_nodes_in_group("branch_blocked"):
		node.remove_from_group("branch_blocked")
