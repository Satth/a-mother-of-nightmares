extends CanvasLayer
## Minimal blocking dialogue box.
## Owner: lead. Interface frozen in CONTRACT.md §2.

signal finished

@export var panel_color := Color(0, 0, 0, 0.86)
@export var text_color := Color(1, 1, 1, 1)
@export var chars_per_second := 55.0

var _lines: Array[String] = []
var _index := 0
var _active := false
var _shown := 0.0

var _panel: Panel
var _label: Label
var _hint: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 40.0
	_panel.offset_right = -40.0
	_panel.offset_top = -170.0
	_panel.offset_bottom = -30.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = panel_color
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.7, 0.7, 0.8, 0.55)
	_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(_panel)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 24.0
	_label.offset_right = -24.0
	_label.offset_top = 16.0
	_label.offset_bottom = -40.0
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_font_size_override("font_size", 22)
	_panel.add_child(_label)

	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.offset_left = -200.0
	_hint.offset_top = -30.0
	_hint.offset_right = -16.0
	_hint.offset_bottom = -6.0
	_hint.text = "[E] continuar"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 0.7))
	_hint.add_theme_font_size_override("font_size", 14)
	_panel.add_child(_hint)


func is_active() -> bool:
	return _active


func show_lines(lines: Array) -> void:
	_lines.clear()
	for line in lines:
		_lines.append(str(line))
	_index = 0
	_active = _lines.size() > 0
	visible = _active
	if _active:
		_render_line()
	else:
		finished.emit()


func _render_line() -> void:
	_label.text = _lines[_index]
	_shown = 0.0
	_label.visible_characters = 0


func _process(delta: float) -> void:
	if _active and _shown < float(_label.text.length()):
		_shown += chars_per_second * delta
		_label.visible_characters = int(_shown)


func _reveal_all() -> void:
	_shown = float(_label.text.length())
	_label.visible_characters = -1


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _shown < float(_label.text.length()):
			_reveal_all()
			return
		_index += 1
		if _index >= _lines.size():
			_close()
		else:
			_render_line()


func _close() -> void:
	_active = false
	visible = false
	_lines.clear()
	finished.emit()
