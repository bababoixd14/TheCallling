extends Node

signal health_changed
signal prompt_changed
signal ammo_changed
signal message(text: String)

const MAX_HEALTH := 3
const SAVE_PATH := "user://the_calling_save.json"

var flags := {}
var items := {}
var documents: Array[Dictionary] = []
var health := MAX_HEALTH
var ammo := 0
var deaths := 0
var current_room := "cabin"
var current_spawn := "start"
var respawn_room := "cabin"
var respawn_spawn := "start"
var prompt_text := ""
var corpse_room := ""
var corpse_pos := Vector2.ZERO

var _freeze_count := 0


func _ready() -> void:
	_setup_inputs()


func _setup_inputs() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E],
		"flashlight": [KEY_F],
		"run": [KEY_SHIFT],
		"journal": [KEY_TAB],
		"shoot": [KEY_SPACE],
	}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode as Key
			InputMap.action_add_event(action, event)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("shoot", click)


func new_game() -> void:
	flags = {}
	items = {}
	documents.clear()
	health = MAX_HEALTH
	ammo = 0
	deaths = 0
	current_room = "cabin"
	current_spawn = "start"
	respawn_room = "cabin"
	respawn_spawn = "start"
	prompt_text = ""
	corpse_room = ""
	_freeze_count = 0


func freeze() -> void:
	_freeze_count += 1


func unfreeze() -> void:
	_freeze_count = maxi(_freeze_count - 1, 0)


func ui_blocked() -> bool:
	return _freeze_count > 0 or Dialogue.is_open or SceneManager.busy


func set_prompt(text: String) -> void:
	if text == prompt_text:
		return
	prompt_text = text
	prompt_changed.emit()


func set_flag(flag: String) -> void:
	flags[flag] = true


func has_flag(flag: String) -> bool:
	return flags.has(flag)


func add_item(id: String, display_name: String) -> void:
	items[id] = display_name
	ammo_changed.emit()


func add_ammo(amount: int) -> void:
	ammo = maxi(ammo + amount, 0)
	ammo_changed.emit()


func has_item(id: String) -> bool:
	return items.has(id)


func add_document(id: String, title: String, text: String) -> void:
	if has_document(id):
		return
	documents.append({"id": id, "title": title, "text": text})


func has_document(id: String) -> bool:
	for document in documents:
		if document["id"] == id:
			return true
	return false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"flags": flags,
		"items": items,
		"documents": documents,
		"health": health,
		"ammo": ammo,
		"deaths": deaths,
		"room": current_room,
		"spawn": current_spawn,
		"respawn_room": respawn_room,
		"respawn_spawn": respawn_spawn,
		"corpse_room": corpse_room,
		"corpse_pos": [corpse_pos.x, corpse_pos.y],
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	new_game()
	flags = parsed.get("flags", {})
	items = parsed.get("items", {})
	for document in parsed.get("documents", []):
		documents.append(document)
	health = int(parsed.get("health", MAX_HEALTH))
	ammo = int(parsed.get("ammo", 0))
	deaths = int(parsed.get("deaths", 0))
	current_room = parsed.get("room", "cabin")
	current_spawn = parsed.get("spawn", "start")
	respawn_room = parsed.get("respawn_room", "cabin")
	respawn_spawn = parsed.get("respawn_spawn", "start")
	corpse_room = parsed.get("corpse_room", "")
	var saved_pos: Array = parsed.get("corpse_pos", [0, 0])
	corpse_pos = Vector2(saved_pos[0], saved_pos[1])
	return true
