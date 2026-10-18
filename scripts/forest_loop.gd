extends Node2D
## Forest loop for a single day. Owner: builder-forest.
## Uses only CONTRACT.md §2 interfaces (GameState / HUD / SceneTransition / Dialogue).
##
## Day 1: walk right, cut 3 trees -> dusk -> walk back to the return zone -> one day older.
## Day 2: colder and foggy; a fallen branch physically blocks the third tree until removed.
## Day 3: near-monochrome, nothing left to cut, the spirit waits at x=560 and ends the run.

const HOUSE_SCENE := "res://scenes/house_interior.tscn"
const SPIRIT_SCENE := "res://scenes/interactables/spirit.tscn"

const SKY_DAY1 := Color(0.10, 0.16, 0.13, 1.0)
const SKY_DAY2 := Color(0.09, 0.13, 0.19, 1.0)
const SKY_DAY3 := Color(0.11, 0.11, 0.12, 1.0)
const GROUND_DAY1 := Color(0.16, 0.11, 0.07, 1.0)
const GROUND_DAY2 := Color(0.13, 0.13, 0.14, 1.0)
const GROUND_DAY3 := Color(0.12, 0.12, 0.13, 1.0)

@export var return_zone := Vector2(80.0, 600.0)
@export var return_radius := 64.0
@export var spirit_position := Vector2(560.0, 600.0)

var _dusk := false
var _transitioning := false
var _no_way_back_shown := false

var _trees: Array = []
var _obstacle: Node2D = null
var _spirit: Node2D = null

@onready var _sky: ColorRect = $Sky
@onready var _ground: ColorRect = $Ground
@onready var _fog: ColorRect = $Fog
@onready var _overlay: ColorRect = $Overlay
@onready var _anomaly: Node2D = $Anomaly
@onready var _return_marker: Node2D = $ReturnMarker
@onready var _far: Node2D = $FarTrees
@onready var _tree_holder: Node2D = $Trees
@onready var _prop_holder: Node2D = $Props
@onready var _spirit_holder: Node2D = $Spirits
@onready var _player: PlayerController = $Player


func _ready() -> void:
	# Guarded like the other scenes so a reload/retry can never double-connect (AGENTS.md §7).
	if not GameState.day_changed.is_connected(_on_day_changed):
		GameState.day_changed.connect(_on_day_changed)
	if not GameState.wood_changed.is_connected(_on_wood_changed):
		GameState.wood_changed.connect(_on_wood_changed)
	_collect_nodes()
	_setup_day()
	_update_hud()


func _collect_nodes() -> void:
	_trees.clear()
	for child in _tree_holder.get_children():
		_trees.append(child)
	_obstacle = get_node_or_null("Props/Obstacle") as Node2D


# ---------------------------------------------------------------- per-day setup

func _setup_day() -> void:
	match GameState.day:
		2:
			_setup_day_two()
		3:
			_setup_day_three()
		_:
			_setup_day_one()
	_apply_palette()


func _setup_day_one() -> void:
	_remove_obstacle()
	_anomaly.visible = false
	_return_marker.visible = false


func _setup_day_two() -> void:
	_anomaly.visible = false
	_return_marker.visible = false
	# The branch keeps the third tree on hold until it is removed (see obstacle.gd).
	var third := _tree_at(2)
	if third != null:
		third.add_to_group("branch_blocked")


func _setup_day_three() -> void:
	_remove_obstacle()
	_anomaly.visible = false
	_return_marker.visible = false
	_spawn_spirit()


func _remove_obstacle() -> void:
	if is_instance_valid(_obstacle):
		_obstacle.queue_free()
	_obstacle = null


func _spawn_spirit() -> void:
	if is_instance_valid(_spirit):
		return
	var packed := load(SPIRIT_SCENE) as PackedScene
	if packed == null:
		push_warning("forest: cannot load " + SPIRIT_SCENE)
		return
	var node := packed.instantiate() as Node2D
	if node == null:
		return
	node.position = spirit_position
	_spirit_holder.add_child(node)
	_spirit = node


func _tree_at(index: int) -> Node:
	if index < 0 or index >= _trees.size():
		return null
	return _trees[index]


# ---------------------------------------------------------------- look and HUD

func _apply_palette() -> void:
	var day := GameState.day
	if day >= 3:
		_sky.color = SKY_DAY3
		_ground.color = GROUND_DAY3
		# Day 3 is graded by three stacked layers (this modulate, the Overlay below, and the global
		# Atmosphere autoload). Keep each one gentle: at 0.62 the player and the spirit were nearly
		# invisible in the rendered frame (mean luminance 0.074 for the whole screen).
		_set_world_modulate(Color(0.86, 0.86, 0.90, 1.0))
	elif day == 2:
		_sky.color = SKY_DAY2
		_ground.color = GROUND_DAY2
		_set_world_modulate(Color(0.90, 0.95, 1.0, 1.0))
	else:
		_sky.color = SKY_DAY1
		_ground.color = GROUND_DAY1
		_set_world_modulate(Color(1, 1, 1, 1))
	_fog.visible = day == 2
	_apply_overlay()


func _set_world_modulate(tint: Color) -> void:
	_far.modulate = tint
	_tree_holder.modulate = tint
	_prop_holder.modulate = tint
	_spirit_holder.modulate = tint
	if is_instance_valid(_player):
		_player.modulate = tint


func _apply_overlay() -> void:
	var day := GameState.day
	if day >= 3:
		_overlay.color = Color(0.04, 0.04, 0.06, 0.28)
	elif _dusk:
		_overlay.color = Color(0.03, 0.05, 0.15, 0.58) if day == 1 else Color(0.03, 0.06, 0.16, 0.62)
	elif day == 2:
		_overlay.color = Color(0.30, 0.42, 0.58, 0.14)
	else:
		_overlay.color = Color(0, 0, 0, 0)


func _status_text() -> String:
	var day := GameState.day
	if day >= 3:
		return "Dia 3/3 — ela espera entre as árvores"
	if _dusk or GameState.wood_complete():
		return "Dia %d/3 — voltar para casa" % day
	return "Dia %d/3 — Madeira %d/%d" % [day, GameState.wood, GameState.WOOD_TARGET]


func _update_hud() -> void:
	HUD.set_status(_status_text())


func _on_day_changed(_day: int) -> void:
	_update_hud()


func _on_wood_changed(_wood: int, _target: int) -> void:
	if GameState.wood_complete():
		_set_dusk()
	else:
		_update_hud()


## Dusk: darker world, objective "voltar para casa" and one subtle wrong detail on day 1.
func _set_dusk() -> void:
	if _dusk:
		return
	_dusk = true
	_apply_overlay()
	if GameState.day == 1:
		_anomaly.visible = true
	if GameState.day <= 2:
		_return_marker.visible = true
	_update_hud()


# ---------------------------------------------------------------- return / spirit

func _process(_delta: float) -> void:
	if _transitioning or SceneTransition.is_busy():
		return
	if not is_instance_valid(_player):
		return
	var inside := _player.global_position.distance_squared_to(return_zone) <= return_radius * return_radius
	if inside:
		_try_to_return()
	elif _no_way_back_shown:
		# Left the closed exit again: drop the hint and restore the normal day-3 status.
		_no_way_back_shown = false
		_update_hud()


func _try_to_return() -> void:
	if GameState.day >= 3:
		_show_no_way_back()
		return
	if not GameState.wood_complete():
		return
	_transitioning = true
	_player.set_input_enabled(false)
	HUD.clear_prompt()
	GameState.advance_day()
	SceneTransition.transition_to(HOUSE_SCENE)


## Day 3: the way home is closed. Reported through the HUD status, NOT through a Dialogue box:
## CONTRACT §6 forbids opening dialogue from `_process`, and a box opened here would race the very
## same frame's `[E]` press — the player could dismiss the one-shot hint before ever reading it.
func _show_no_way_back() -> void:
	if _no_way_back_shown:
		return
	_no_way_back_shown = true
	HUD.set_status("Dia 3/3 — não há caminho de volta")
