extends CharacterBody2D

const WALK_SPEED := 120.0
const RUN_SPEED := 190.0
const LIGHT_SIZE := 256

static var cone_texture: ImageTexture

var facing := Vector2.DOWN
var flashlight_on := false
var invulnerable_time := 0.0
var nearest: Thing = null
var shot_cooldown := 0.0
var glow_energy := 0.55

var _flashlight: PointLight2D
var _glow: PointLight2D
var _drawn_facing := Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 14)
	shape.shape = rect
	shape.position = Vector2(0, -7)
	add_child(shape)

	_glow = PointLight2D.new()
	var glow_texture := GradientTexture2D.new()
	glow_texture.width = 256
	glow_texture.height = 256
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(1.0, 0.5)
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color.BLACK)
	glow_texture.gradient = gradient
	_glow.texture = glow_texture
	_glow.energy = 0.55
	_glow.position = Vector2(0, -30)
	add_child(_glow)

	_flashlight = PointLight2D.new()
	_flashlight.texture = _get_cone_texture()
	_flashlight.texture_scale = 3.2
	_flashlight.energy = 1.3
	_flashlight.position = Vector2(0, -30)
	_flashlight.enabled = false
	add_child(_flashlight)


func _get_cone_texture() -> ImageTexture:
	if cone_texture:
		return cone_texture
	var image := Image.create(LIGHT_SIZE, LIGHT_SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(LIGHT_SIZE / 2.0, LIGHT_SIZE / 2.0)
	for y in LIGHT_SIZE:
		for x in LIGHT_SIZE:
			var offset := Vector2(x, y) - center
			var distance := offset.length() / (LIGHT_SIZE / 2.0)
			var spread := clampf(1.0 - absf(offset.angle()) / 0.6, 0.0, 1.0)
			var strength := clampf(1.0 - distance, 0.0, 1.0) * smoothstep(0.0, 0.45, spread)
			strength = maxf(strength, clampf(1.0 - distance / 0.3, 0.0, 1.0) * 0.5)
			image.set_pixel(x, y, Color(strength, strength, strength, 1.0))
	cone_texture = ImageTexture.create_from_image(image)
	return cone_texture


func _physics_process(delta: float) -> void:
	invulnerable_time = maxf(invulnerable_time - delta, 0.0)
	shot_cooldown = maxf(shot_cooldown - delta, 0.0)

	if GameState.ui_blocked():
		velocity = Vector2.ZERO
		move_and_slide()
		_update_prompt(false)
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	velocity = direction * speed
	move_and_slide()

	if direction != Vector2.ZERO:
		facing = direction.normalized()
		_flashlight.rotation = facing.angle()
	_update_prompt(true)


func _process(_delta: float) -> void:
	var cardinal := facing.snapped(Vector2(1, 1))
	if absf(facing.x) > absf(facing.y):
		cardinal = Vector2(signf(facing.x), 0)
	else:
		cardinal = Vector2(0, signf(facing.y))
	if cardinal != _drawn_facing:
		_drawn_facing = cardinal
		queue_redraw()
	modulate.a = 0.5 if invulnerable_time > 0.0 and int(invulnerable_time * 10) % 2 == 0 else 1.0


func _draw() -> void:
	draw_ellipse_shadow()
	draw_rect(Rect2(-9, -34, 18, 26), Color(0.25, 0.3, 0.38))
	draw_rect(Rect2(-7, -10, 5, 10), Color(0.12, 0.12, 0.16))
	draw_rect(Rect2(2, -10, 5, 10), Color(0.12, 0.12, 0.16))
	draw_circle(Vector2(0, -42), 8, Color(0.8, 0.68, 0.58))
	draw_circle(Vector2(_drawn_facing.x * 5, -42 + _drawn_facing.y * 3), 2.5, Color(0.1, 0.1, 0.1))


func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, 0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _update_prompt(allowed: bool) -> void:
	nearest = null
	if allowed:
		var best := INF
		for node in get_tree().get_nodes_in_group("interactable"):
			var thing := node as Thing
			if thing and thing.can_use():
				var distance := thing.distance_to_player(global_position)
				if distance < thing.reach and distance < best:
					best = distance
					nearest = thing
	GameState.set_prompt("[E] " + nearest.prompt if nearest else "")


func _unhandled_input(event: InputEvent) -> void:
	if GameState.ui_blocked():
		return
	if event.is_action_pressed("interact") and nearest:
		nearest.use()
	elif event.is_action_pressed("flashlight") and GameState.has_item("flashlight"):
		flashlight_on = not flashlight_on
		_flashlight.enabled = flashlight_on
	elif event.is_action_pressed("shoot"):
		_shoot()


func _shoot() -> void:
	if not GameState.has_item("gun") or shot_cooldown > 0.0:
		return
	if GameState.ammo <= 0:
		shot_cooldown = 0.4
		GameState.message.emit("Click. No bullets.")
		return
	GameState.add_ammo(-1)
	shot_cooldown = 0.4

	var start := global_position + Vector2(0, -7)
	var query := PhysicsRayQueryParameters2D.create(start, start + facing * 520.0, 5)
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	var end: Vector2 = hit["position"] if hit else start + facing * 520.0
	if hit and hit["collider"].has_method("take_hit"):
		hit["collider"].take_hit()
	_show_shot(end)


func _show_shot(end: Vector2) -> void:
	var tracer := Line2D.new()
	tracer.width = 2.0
	tracer.default_color = Color(1.0, 0.9, 0.6)
	tracer.add_point(Vector2(0, -7))
	tracer.add_point(to_local(end))
	add_child(tracer)
	var tween := create_tween()
	tween.tween_property(tracer, "modulate:a", 0.0, 0.1)
	tween.tween_callback(tracer.queue_free)
	_glow.energy = 2.5
	create_tween().tween_property(_glow, "energy", glow_energy, 0.2)


func set_brightness(brightness: float) -> void:
	glow_energy = 0.55 * brightness
	_glow.energy = glow_energy


func take_damage() -> void:
	if invulnerable_time > 0.0 or SceneManager.busy:
		return
	GameState.health -= 1
	GameState.health_changed.emit()
	invulnerable_time = 1.5
	if GameState.health <= 0:
		SceneManager.respawn()


func reset_state() -> void:
	invulnerable_time = 0.0
	velocity = Vector2.ZERO
