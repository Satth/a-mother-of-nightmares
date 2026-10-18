extends CanvasLayer
## Minimal on-screen prompt + status readout.
## Owner: lead. Interface frozen in CONTRACT.md §2.

var _prompt_label: Label
var _status_label: Label


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_status_label = Label.new()
	_status_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_status_label.offset_left = 20.0
	_status_label.offset_top = 14.0
	_status_label.offset_right = 520.0
	_status_label.offset_bottom = 44.0
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_status_label.add_theme_constant_override("outline_size", 5)
	root.add_child(_status_label)

	_prompt_label = Label.new()
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.offset_left = -260.0
	_prompt_label.offset_right = 260.0
	_prompt_label.offset_top = -96.0
	_prompt_label.offset_bottom = -60.0
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 20)
	_prompt_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	_prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_prompt_label.add_theme_constant_override("outline_size", 6)
	root.add_child(_prompt_label)


func set_prompt(text: String) -> void:
	_prompt_label.text = ("[E] " + text) if text != "" else ""


func clear_prompt() -> void:
	set_prompt("")


func set_status(text: String) -> void:
	_status_label.text = text
