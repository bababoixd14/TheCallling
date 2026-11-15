class_name World
extends Node2D

const PlayerScript := preload("res://scripts/player/player.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const AmbienceScript := preload("res://scripts/story/ambience.gd")
const CodeLockScript := preload("res://scripts/ui/code_lock.gd")

var player: CharacterBody2D
var hud: CanvasLayer
var objects: Node2D
var room_layer: Node2D
var spawns := {}
var brightness := 1.0

var _darkness: CanvasModulate
var _fog: ColorRect
var _title: Label
var _triggers: Array[Dictionary] = []
var _code_lock: CanvasLayer


func _ready() -> void:
	SceneManager.world = self
	SceneManager.busy = true

	var camera := Camera2D.new()
	camera.position = Vector2(640, 360)
	add_child(camera)

	_darkness = CanvasModulate.new()
	add_child(_darkness)

	room_layer = Node2D.new()
	room_layer.z_index = -20
	add_child(room_layer)

	objects = Node2D.new()
	objects.y_sort_enabled = true
	add_child(objects)

	player = PlayerScript.new()
	player.y_sort_enabled = true
	objects.add_child(player)

	var fog_layer := CanvasLayer.new()
	fog_layer.layer = 10
	add_child(fog_layer)
	_fog = ColorRect.new()
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fog.color = Color(0.75, 0.8, 0.85, 0.0)
	fog_layer.add_child(_fog)

	var title_layer := CanvasLayer.new()
	title_layer.layer = 70
	add_child(title_layer)
	_title = Label.new()
	_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 38)
	_title.modulate.a = 0.0
	title_layer.add_child(_title)

	hud = HudScript.new()
	add_child(hud)
	_code_lock = CodeLockScript.new()
	add_child(_code_lock)
	add_child(AmbienceScript.new())

	var tween := create_tween().set_loops()
	tween.tween_property(_fog, "modulate:a", 0.6, 4.0)
	tween.tween_property(_fog, "modulate:a", 1.0, 4.0)

	ScreenFade.rect.modulate.a = 1.0
	load_room(GameState.current_room, GameState.current_spawn)
	await get_tree().process_frame
	await ScreenFade.fade_in(1.0)
	SceneManager.busy = false
	room_entered(GameState.current_room)


func load_room(room_id: String, spawn: String) -> void:
	for child in room_layer.get_children():
		child.queue_free()
	for child in objects.get_children():
		if child != player:
			child.queue_free()
	_triggers.clear()
	spawns.clear()

	# Every death makes the world darker, until only the flashlight is left.
	brightness = clampf(1.0 - 0.18 * GameState.deaths, 0.15, 1.0)
	var info := Rooms.build(self, room_id)
	var ambient: Color = info["ambient"]
	_darkness.color = Color(ambient.r * brightness, ambient.g * brightness, ambient.b * brightness)
	player.set_brightness(brightness)
	_add_corpse(room_id)
	_fog.color = Color(0.75 * brightness, 0.8 * brightness, 0.85 * brightness, info["fog"])
	player.global_position = spawns.get(spawn, Vector2(640, 500))
	player.reset_state()
	player.facing = Vector2.DOWN

	GameState.current_room = room_id
	GameState.current_spawn = spawn
	if info.get("checkpoint", false):
		GameState.respawn_room = room_id
		GameState.respawn_spawn = spawn


func room_entered(room_id: String) -> void:
	await Rooms.entered(self, room_id)
	if not GameState.has_flag("ending_started"):
		GameState.save_game()


# --- helpers used by Rooms --------------------------------------------------

func floor_rect(rect: Rect2, color: Color) -> void:
	var node := ColorRect.new()
	node.position = rect.position
	node.size = rect.size
	node.color = color
	room_layer.add_child(node)


# Draws floor and back wall, and adds invisible collision around the floor.
func box_room(floor_area: Rect2, floor_color: Color, wall_color: Color) -> void:
	floor_rect(Rect2(0, 0, 1280, 720), wall_color.darkened(0.6))
	floor_rect(Rect2(floor_area.position.x, floor_area.position.y - 110, floor_area.size.x, 110), wall_color)
	floor_rect(floor_area, floor_color)
	var edge := 60.0
	wall(Rect2(floor_area.position.x - edge, floor_area.position.y - edge, floor_area.size.x + edge * 2, edge))
	wall(Rect2(floor_area.position.x - edge, floor_area.end.y, floor_area.size.x + edge * 2, edge))
	wall(Rect2(floor_area.position.x - edge, floor_area.position.y, edge, floor_area.size.y))
	wall(Rect2(floor_area.end.x, floor_area.position.y, edge, floor_area.size.y))


func wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	room_layer.add_child(body)


func prop(pos: Vector2, size: Vector2, color: Color, solid := true) -> Thing:
	var thing := Thing.make(pos, size, color, solid)
	objects.add_child(thing)
	return thing


func examine(pos: Vector2, size: Vector2, color: Color, prompt: String, lines: Array) -> Thing:
	var thing := prop(pos, size, color)
	thing.set_action(prompt, func() -> void: Dialogue.say(lines))
	return thing


func note(pos: Vector2, id: String, title: String, text: String, size := Vector2(30, 18)) -> Thing:
	var thing := prop(pos, size, Color(0.75, 0.7, 0.55), false)
	thing.set_action("Read " + title, func() -> void: _collect_document(thing, id, title, text))
	thing.available = func() -> bool: return not GameState.has_document(id)
	thing.visible = thing.can_use()
	return thing


func _collect_document(thing: Thing, id: String, title: String, text: String) -> void:
	GameState.add_document(id, title, text)
	thing.visible = false
	hud.toast("Added to journal: " + title)
	await Dialogue.say(text.split("\n\n"))


func pickup(pos: Vector2, size: Vector2, color: Color, item_id: String, item_name: String, lines: Array, bonus_ammo := 0) -> Thing:
	var thing := prop(pos, size, color, false)
	thing.set_action("Take " + item_name, func() -> void:
		GameState.add_item(item_id, item_name)
		GameState.add_ammo(bonus_ammo)
		thing.visible = false
		hud.toast("Picked up: " + item_name)
		await Dialogue.say(lines))
	thing.available = func() -> bool: return not GameState.has_item(item_id)
	thing.visible = thing.can_use()
	return thing


# An empty id means the bullets are not remembered (used for boss drops).
func pickup_ammo(pos: Vector2, amount: int, id: String) -> void:
	if id != "" and GameState.has_flag(id):
		return
	var thing := prop(pos, Vector2(20, 12), Color(0.8, 0.65, 0.2), false)
	thing.set_action("Take bullets", func() -> void:
		if id != "":
			GameState.set_flag(id)
		GameState.add_ammo(amount)
		hud.toast("+%d bullets" % amount)
		thing.queue_free())


func door(pos: Vector2, size: Vector2, color: Color, prompt: String, target_room: String, target_spawn: String, check := Callable()) -> Thing:
	var thing := prop(pos, size, color, false)
	thing.set_action(prompt, func() -> void:
		if check.is_valid():
			var allowed: bool = await check.call()
			if not allowed:
				return
		SceneManager.go(target_room, target_spawn))
	return thing


func trigger(rect: Rect2, flag: String, callback: Callable) -> void:
	_triggers.append({"rect": rect, "flag": flag, "callback": callback})


func monster(a: Vector2, b: Vector2, kind := Monster.Kind.WALKER, id := "") -> void:
	if id != "" and GameState.has_flag("dead_" + id):
		return
	var enemy := Monster.new()
	enemy.kind = kind
	enemy.id = id
	enemy.point_a = a
	enemy.point_b = b
	enemy.position = a
	objects.add_child(enemy)


func light(pos: Vector2, color: Color, scale_factor := 3.0, energy := 1.0) -> void:
	var lamp := PointLight2D.new()
	var texture := GradientTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color.BLACK)
	texture.gradient = gradient
	lamp.texture = texture
	lamp.texture_scale = scale_factor
	lamp.color = color
	lamp.energy = energy * maxf(brightness, 0.35)
	lamp.position = pos
	room_layer.add_child(lamp)


func _add_corpse(room_id: String) -> void:
	if GameState.corpse_room != room_id:
		return
	var body := prop(GameState.corpse_pos, Vector2(46, 14), Color(0.3, 0.33, 0.4), false)
	body.set_action("Take back a heartbeat", func() -> void:
		GameState.health += 1
		GameState.corpse_room = ""
		GameState.health_changed.emit()
		hud.toast("+1 health")
		body.queue_free())
	body.available = func() -> bool: return GameState.health < GameState.MAX_HEALTH


func ask_code(correct: String) -> bool:
	return await _code_lock.ask(correct)


func chapter_title(text: String) -> void:
	_title.text = text
	var tween := create_tween()
	tween.tween_property(_title, "modulate:a", 1.0, 1.0)
	tween.tween_interval(2.0)
	tween.tween_property(_title, "modulate:a", 0.0, 1.5)
	await tween.finished


func _physics_process(_delta: float) -> void:
	if SceneManager.busy or GameState.ui_blocked():
		return
	for entry in _triggers:
		var rect: Rect2 = entry["rect"]
		var flag: String = entry["flag"]
		if rect.has_point(player.global_position) and (flag == "" or not GameState.has_flag(flag)):
			if flag != "":
				GameState.set_flag(flag)
			entry["callback"].call()
			return


func play_ending() -> void:
	GameState.set_flag("ending_started")
	GameState.freeze()
	await ScreenFade.fade_out(1.5)
	load_room("town_street", "forest")
	_fog.color.a = 0.45
	await get_tree().create_timer(0.5).timeout
	await ScreenFade.fade_in(2.0)
	await Dialogue.say(["Daniel: The road... it leads right back to where I started.", "The fog thickens, swallowing the street lights one by one."])
	await get_tree().create_timer(1.5).timeout
	await Dialogue.say(["Anna: Daniel."])
	await ScreenFade.fade_out(3.0)
	await get_tree().create_timer(1.5).timeout
	await chapter_title("THE CALLING")
	await get_tree().create_timer(1.0).timeout
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
