extends Interactable
## Cuttable tree (forest). Owner: builder-forest.
##
## Cutting can never over-count: the amount that really landed in GameState is taken from the
## RETURN VALUE of GameState.add_wood(), and the node is one_shot on top of that.
## Day 3 gives no more wood; on day 2 a fallen branch can still block the way ("branch_blocked").

@export var wood_amount := 1

var _body: Array = []
var _stump: CanvasItem = null


func _ready() -> void:
	super._ready()
	_body.clear()
	for child in get_children():
		if child is CanvasItem and child.name != "Stump":
			_body.append(child)
	_stump = get_node_or_null("Stump")
	if _stump != null:
		_stump.visible = false


func can_interact() -> bool:
	if GameState.day >= 3:
		return false
	if is_in_group("branch_blocked"):
		return false
	return super.can_interact()


func interact(_by: Node) -> void:
	if not can_interact():
		return
	var counted: int = GameState.add_wood(wood_amount)
	if counted <= 0:
		return
	mark_used()
	_fell()


## Visible feedback: the tree loses trunk and canopy and leaves a stump behind.
func _fell() -> void:
	for part in _body:
		if is_instance_valid(part):
			part.visible = false
	if is_instance_valid(_stump):
		_stump.visible = true
