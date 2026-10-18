extends Node2D
## House interior — the start of every day (CONTRACT.md §6, owner: builder-core).
##
## Days 1-2: talk to the child, take the axe, leave through the door.
## Day 3: the child is gone (GameState.child_present() == false), the bed reads as
##        empty and the HUD says so. The axe is still obtainable because
##        GameState.advance_day() reset the per-day progress.

const BG_DAY_1 := Color(0.19, 0.16, 0.13, 1)
const BG_DAY_2 := Color(0.14, 0.16, 0.21, 1)
const BG_DAY_3 := Color(0.11, 0.11, 0.12, 1)

const MATTRESS_NORMAL := Color(0.62, 0.58, 0.52, 1)
const MATTRESS_EMPTY := Color(0.30, 0.31, 0.35, 1)

@onready var _background: ColorRect = $Background
@onready var _mattress: ColorRect = $Bed/Mattress
@onready var _pillow: ColorRect = $Bed/Pillow
@onready var _empty_bed: Node2D = $Bed/EmptyBed

var _child: Node = null


func _ready() -> void:
	_child = get_node_or_null("Child")
	# Connect once; the node is freed on scene change, so Godot drops these links.
	if not GameState.day_changed.is_connected(_on_day_changed):
		GameState.day_changed.connect(_on_day_changed)
	if not GameState.wood_changed.is_connected(_on_wood_changed):
		GameState.wood_changed.connect(_on_wood_changed)
	if not GameState.axe_changed.is_connected(_on_axe_changed):
		GameState.axe_changed.connect(_on_axe_changed)
	_apply_day_visuals()
	_update_status()


func _on_day_changed(_day: int) -> void:
	_apply_day_visuals()
	_update_status()


func _on_wood_changed(_wood: int, _target: int) -> void:
	_update_status()


func _on_axe_changed(_has_axe: bool) -> void:
	_update_status()


## Status format is frozen: "Dia X/3 — Madeira Y/3" (+ day-3 emptiness note).
func _update_status() -> void:
	var text := "Dia %d/%d — Madeira %d/%d" % [
		GameState.day, GameState.MAX_DAY, GameState.wood, GameState.WOOD_TARGET,
	]
	if GameState.day >= 3:
		text += " — o filho desapareceu, a cama está vazia"
	HUD.set_status(text)


func _apply_day_visuals() -> void:
	var day: int = GameState.day
	if is_instance_valid(_background):
		_background.color = _palette_for(day)
	_apply_child()
	_apply_bed(day)


func _palette_for(day: int) -> Color:
	match day:
		1:
			return BG_DAY_1
		2:
			return BG_DAY_2
		_:
			return BG_DAY_3


## Days 1-2: the child stays. Day 3: no child at all (freed so the player cannot
## even target it), only the empty bed below.
func _apply_child() -> void:
	if not is_instance_valid(_child):
		return
	if GameState.child_present():
		_child.visible = true
		return
	_child.visible = false
	_child.queue_free()
	_child = null


## Day 3 bed: dim sheet, no pillow, explicit "empty" caption.
func _apply_bed(day: int) -> void:
	var empty := day >= 3
	if is_instance_valid(_empty_bed):
		_empty_bed.visible = empty
	if is_instance_valid(_mattress):
		_mattress.color = MATTRESS_EMPTY if empty else MATTRESS_NORMAL
	if is_instance_valid(_pillow):
		_pillow.visible = not empty
