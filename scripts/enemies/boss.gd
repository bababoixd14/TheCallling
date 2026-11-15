class_name Boss
extends CharacterBody2D

# "Daniel": the giant that Daniel has been carrying since the crash.

signal defeated

enum State { CHASE, WINDUP, LUNGE, RECOVER }

const MAX_HEALTH := 16
const AMMO_DROP_HEALTH := [12, 8, 4]
const ARENA := Rect2(130, 270, 1020, 370)

var health := MAX_HEALTH
var state := State.CHASE
var drop_ammo := Callable()

var _timer := 1.5
var _lunge_direction := Vector2.ZERO
var _flash := 0.0
var _player: Node2D
var _bar: Node2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	y_sort_enabled = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80, 36)
	shape.shape = rect
	shape.position = Vector2(0, -18)
	add_child(shape)
	_player = get_tree().get_first_node_in_group("player")

	# The health bar lives on its own canvas layer so the darkness does not dim it.
	var bar_layer := CanvasLayer.new()
	bar_layer.layer = 55
	_bar = Node2D.new()
	_bar.draw.connect(_draw_bar)
	bar_layer.add_child(_bar)
	add_child(bar_layer)


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	if not _player or GameState.ui_blocked():
		velocity = Vector2.ZERO
		return

	var to_player := _player.global_position - global_position
	_timer -= delta

	match state:
		State.CHASE:
			velocity = to_player.normalized() * 55.0
			if to_player.length() < 300.0 and _timer <= 0.0:
				state = State.WINDUP
				_timer = 0.9
		State.WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				state = State.LUNGE
				_timer = 0.6
				_lunge_direction = to_player.normalized()
		State.LUNGE:
			velocity = _lunge_direction * 290.0
			if _timer <= 0.0:
				state = State.RECOVER
				_timer = 1.2
		State.RECOVER:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				state = State.CHASE
				_timer = 1.5

	move_and_slide()
	global_position = global_position.clamp(ARENA.position, ARENA.end)
	_bar.queue_redraw()
	if to_player.length() < 70.0:
		_player.take_damage()
	queue_redraw()


func take_hit() -> void:
	health -= 1
	_flash = 0.1
	if health in AMMO_DROP_HEALTH and drop_ammo.is_valid():
		drop_ammo.call(Vector2(randf_range(180, 1100), randf_range(320, 620)))
	if health <= 0:
		set_physics_process(false)
		defeated.emit()
		queue_free()


func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 60, Color(0, 0, 0, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2.6, 2.6))
	var body := Color(0.06, 0.03, 0.04)
	if state == State.WINDUP and int(_timer * 12.0) % 2 == 0:
		body = Color(0.45, 0.05, 0.05)
	if _flash > 0.0:
		body = Color(0.9, 0.9, 0.9)
	var sway := sin(Time.get_ticks_msec() / 400.0) * 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, 0), Vector2(12, 0), Vector2(9 + sway, -62), Vector2(-9 + sway, -62)
	]), body)
	draw_rect(Rect2(-26 + sway, -58, 9, 52), body)
	draw_rect(Rect2(17 + sway, -58, 9, 52), body)
	draw_circle(Vector2(sway, -68), 10, Color(0.75, 0.68, 0.62))
	draw_circle(Vector2(-3.5 + sway, -69), 2.4, Color.BLACK)
	draw_circle(Vector2(3.5 + sway, -69), 2.4, Color.BLACK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_bar() -> void:
	var font := ThemeDB.fallback_font
	_bar.draw_string(font, Vector2(440, 40), "DANIEL", HORIZONTAL_ALIGNMENT_CENTER, 400, 24, Color(0.85, 0.3, 0.3))
	_bar.draw_rect(Rect2(440, 48, 400, 10), Color(0.15, 0.05, 0.05))
	_bar.draw_rect(Rect2(440, 48, 400.0 * health / MAX_HEALTH, 10), Color(0.75, 0.15, 0.15))
