extends CanvasLayer

signal answered(correct: bool)

var _panel: PanelContainer
var _input: LineEdit
var _correct_code := ""


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(320, 150)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_panel.add_child(box)

	var title := Label.new()
	title.text = "Enter the 4-digit code"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_input = LineEdit.new()
	_input.max_length = 4
	_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_input.add_theme_font_size_override("font_size", 30)
	_input.text_submitted.connect(_on_submitted)
	box.add_child(_input)

	var hint := Label.new()
	hint.text = "Enter to confirm, Esc to cancel"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	_panel.hide()


func ask(correct_code: String) -> bool:
	_correct_code = correct_code
	_input.text = ""
	_panel.show()
	_input.grab_focus()
	GameState.freeze()
	var result: bool = await answered
	_panel.hide()
	GameState.unfreeze()
	return result


func _on_submitted(text: String) -> void:
	answered.emit(text == _correct_code)


func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		answered.emit(false)
