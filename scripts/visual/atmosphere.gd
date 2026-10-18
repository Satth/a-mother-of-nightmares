extends CanvasLayer
## Per-day colour grade (warm -> cold/fog -> near-monochrome dark).
## Owner: atmos. Register as autoload `Atmosphere` -> res://scripts/visual/atmosphere.gd
##
## Strictly cosmetic and removable without consequence: it owns only its own ColorRect children,
## never frees anything, never touches other nodes and no behaviour depends on it.
## Sits on layer 40, i.e. UNDER the HUD (layer 50), so prompts/status stay readable on top.

const LAYER := 40

## Subtle overlays: alpha stays low so gameplay visuals and HUD text remain readable.
@export var day1_tint := Color(0.72, 0.50, 0.26, 0.14) ## warm / slightly sepia
@export var day2_tint := Color(0.34, 0.48, 0.78, 0.20) ## cold / desaturated blue
@export var day3_tint := Color(0.06, 0.06, 0.10, 0.44) ## near-monochrome, dark, heavy

const FOG_ALPHA_BASE := 0.05
const FOG_ALPHA_SWING := 0.03
const FOG_WIDTH := 1600.0
const FOG_LEFT := -160.0

var _grade: ColorRect
var _fog: ColorRect
var _fog_time := 0.0


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_grade()
	_build_fog()
	# Guarded so a scene reload / re-entry cannot double-connect.
	if not GameState.day_changed.is_connected(_on_day_changed):
		GameState.day_changed.connect(_on_day_changed)
	_apply_day(GameState.day)


func _build_grade() -> void:
	_grade = ColorRect.new()
	_grade.color = day1_tint
	_grade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_grade)


## Optional, asset-free "fog": one faint drifting ColorRect, only shown on day 2.
func _build_fog() -> void:
	_fog = ColorRect.new()
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog.color = Color(0.78, 0.86, 1.0, FOG_ALPHA_BASE)
	_fog.position = Vector2(FOG_LEFT, 0.0)
	_fog.size = Vector2(FOG_WIDTH, 720.0)
	_fog.visible = false
	add_child(_fog)


func _on_day_changed(day: int) -> void:
	_apply_day(day)


func _apply_day(day: int) -> void:
	if _grade == null:
		return
	match day:
		2:
			_grade.color = day2_tint
		3:
			_grade.color = day3_tint
		_:
			_grade.color = day1_tint
	if _fog != null:
		_fog.visible = day == 2


func _process(delta: float) -> void:
	if _fog == null or not _fog.visible:
		return
	_fog_time += delta
	_fog.position.x = FOG_LEFT + sin(_fog_time * 0.12) * 80.0
	_fog.color.a = FOG_ALPHA_BASE + (sin(_fog_time * 0.23) * 0.5 + 0.5) * FOG_ALPHA_SWING
