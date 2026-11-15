extends Control

const WORLD_SCENE := "res://scenes/world.tscn"


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.02, 0.02, 0.03)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(360, 0)
	box.offset_left = -180
	box.offset_right = 180
	box.offset_top = -190
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var title := Label.new()
	title.text = "THE CALLING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A psychological horror demo"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	box.add_child(subtitle)

	box.add_child(Control.new())
	var new_button := _add_button(box, "New Game", _on_new_game)
	var continue_button := _add_button(box, "Continue", _on_continue)
	continue_button.disabled = not GameState.has_save()
	_add_button(box, "Quit", func() -> void: get_tree().quit())

	var controls := Label.new()
	controls.text = "WASD / arrows: move    Shift: run    E: interact / continue\nSpace / click: shoot (once you find the gun)    F: flashlight    Tab: journal"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	box.add_child(controls)

	new_button.grab_focus()
	ScreenFade.rect.modulate.a = 1.0
	ScreenFade.fade_in(1.0)


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _on_new_game() -> void:
	GameState.new_game()
	_start()


func _on_continue() -> void:
	if GameState.load_game():
		_start()


func _start() -> void:
	await ScreenFade.fade_out(0.8)
	get_tree().change_scene_to_file(WORLD_SCENE)
