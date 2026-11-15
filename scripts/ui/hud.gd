extends CanvasLayer

var _prompt: Label
var _health: Label
var _ammo: Label
var _journal_panel: PanelContainer
var _journal_list: ItemList
var _journal_text: Label
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS

	_prompt = Label.new()
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -230
	_prompt.offset_left = -300
	_prompt.offset_right = 300
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 20)
	add_child(_prompt)

	_health = Label.new()
	_health.position = Vector2(24, 20)
	_health.add_theme_font_size_override("font_size", 22)
	_health.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	add_child(_health)

	_ammo = Label.new()
	_ammo.position = Vector2(24, 52)
	_ammo.add_theme_font_size_override("font_size", 20)
	_ammo.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
	add_child(_ammo)

	_toast = Label.new()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 60
	_toast.offset_left = -300
	_toast.offset_right = 300
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.modulate.a = 0.0
	add_child(_toast)

	_build_journal()
	GameState.health_changed.connect(_update_health)
	GameState.prompt_changed.connect(_update_prompt)
	GameState.ammo_changed.connect(_update_ammo)
	GameState.message.connect(toast)
	_update_health()
	_update_ammo()


func _build_journal() -> void:
	_journal_panel = PanelContainer.new()
	_journal_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_journal_panel.offset_left = 100
	_journal_panel.offset_right = -100
	_journal_panel.offset_top = 60
	_journal_panel.offset_bottom = -60
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.96)
	style.border_color = Color(0.5, 0.5, 0.5)
	style.set_border_width_all(2)
	style.set_content_margin_all(20)
	_journal_panel.add_theme_stylebox_override("panel", style)
	add_child(_journal_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	_journal_panel.add_child(row)

	_journal_list = ItemList.new()
	_journal_list.custom_minimum_size = Vector2(300, 0)
	_journal_list.item_selected.connect(_on_document_selected)
	row.add_child(_journal_list)

	_journal_text = Label.new()
	_journal_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_journal_text.custom_minimum_size = Vector2(600, 0)
	_journal_text.add_theme_font_size_override("font_size", 20)
	row.add_child(_journal_text)

	_journal_panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("journal"):
		return
	if _journal_panel.visible:
		_close_journal()
	elif not GameState.ui_blocked():
		_open_journal()


func _open_journal() -> void:
	_journal_list.clear()
	for document in GameState.documents:
		_journal_list.add_item(document["title"])
	_journal_text.text = "Nothing collected yet." if GameState.documents.is_empty() else "Select a document.\n\nTab to close."
	_journal_panel.show()
	GameState.freeze()


func _close_journal() -> void:
	_journal_panel.hide()
	GameState.unfreeze()


func _on_document_selected(index: int) -> void:
	_journal_text.text = GameState.documents[index]["text"]


func _update_health() -> void:
	_health.text = "♥ ".repeat(GameState.health).strip_edges()


func _update_ammo() -> void:
	_ammo.text = "Bullets: %d" % GameState.ammo if GameState.has_item("gun") else ""


func _update_prompt() -> void:
	_prompt.text = GameState.prompt_text


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 1.0)
