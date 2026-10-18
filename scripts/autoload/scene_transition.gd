extends CanvasLayer
## Fade + scene change. Persistent state lives in GameState, so a scene swap is safe.
## Owner: lead. Interface frozen in CONTRACT.md §2.

signal transition_finished

const DEFAULT_FADE := 0.35

var _rect: ColorRect
var _busy := false


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func is_busy() -> bool:
	return _busy


func transition_to(scene_path: String, fade_out: float = DEFAULT_FADE, fade_in: float = DEFAULT_FADE) -> void:
	if _busy:
		return
	_busy = true
	await _fade(1.0, fade_out)
	get_tree().change_scene_to_file(scene_path)
	# Give the tree a couple of frames so the new scene exists before fading in.
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade(0.0, fade_in)
	_busy = false
	transition_finished.emit()


func _fade(target_alpha: float, duration: float) -> void:
	if duration <= 0.0:
		_rect.color.a = target_alpha
		return
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", target_alpha, duration)
	await tween.finished
