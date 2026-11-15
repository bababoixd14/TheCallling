extends CanvasLayer

signal finished

var is_open := false

var _panel: PanelContainer
var _label: Label
var _speaker: Label
var _lines: Array = []
var _index := 0
var _advance_ready := false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 120
	_panel.offset_right = -120
	_panel.offset_top = -170
	_panel.offset_bottom = -30
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.border_color = Color(0.5, 0.5, 0.5)
	style.set_border_width_all(2)
	style.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var box := VBoxContainer.new()
	_panel.add_child(box)

	_speaker = Label.new()
	_speaker.add_theme_color_override("font_color", Color(0.75, 0.6, 0.45))
	box.add_child(_speaker)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(900, 0)
	_label.add_theme_font_size_override("font_size", 22)
	box.add_child(_label)

	_panel.hide()


# Shows lines one by one. Plain strings are shown as they are;
# use "Speaker: text" to show a speaker name. Await it to wait for the end.
func say(lines: Array) -> void:
	if is_open or lines.is_empty():
		return
	_lines = lines
	_index = 0
	is_open = true
	_advance_ready = false
	_show_line()
	_panel.show()
	await get_tree().create_timer(0.2).timeout
	_advance_ready = true
	await finished


func _show_line() -> void:
	var line := str(_lines[_index])
	var parts := line.split(": ", true, 1)
	if parts.size() == 2 and parts[0].length() <= 12:
		_speaker.text = parts[0]
		_label.text = parts[1]
	else:
		_speaker.text = ""
		_label.text = line


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or not _advance_ready:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_index += 1
		if _index >= _lines.size():
			is_open = false
			_panel.hide()
			finished.emit()
		else:
			_show_line()
