class_name Monster
extends CharacterBody2D

enum Kind { WALKER, CRAWLER }
enum State { PATROL, CHASE, STUNNED }

var kind := Kind.WALKER
var id := ""
var point_a := Vector2.ZERO
var point_b := Vector2.ZERO
var state := State.PATROL
var health := 4
var patrol_speed := 60.0
var chase_speed := 100.0
var sight := 220.0

var _target_is_b := true
var _stun_time := 0.0
var _flash := 0.0
var _player: Node2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	y_sort_enabled = true
	if kind == Kind.CRAWLER:
		health = 2
		patrol_speed = 80.0
		chase_speed = 165.0
		sight = 260.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 14) if kind == Kind.WALKER else Vector2(30, 14)
	shape.shape = rect
	shape.position = Vector2(0, -7)
	add_child(shape)
	_player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	if not _player or GameState.ui_blocked():
		velocity = Vector2.ZERO
		return

	var to_player := _player.global_position - global_position
	var distance := to_player.length()

	match state:
		State.PATROL:
			var target := point_b if _target_is_b else point_a
			if global_position.distance_to(target) < 8.0:
				_target_is_b = not _target_is_b
			velocity = (target - global_position).normalized() * patrol_speed
			if distance < _sight_range():
				state = State.CHASE
		State.CHASE:
			velocity = to_player.normalized() * chase_speed
			if kind == Kind.CRAWLER:
				velocity += to_player.orthogonal().normalized() * sin(Time.get_ticks_msec() / 90.0) * 60.0
			if distance > (750.0 if _player.flashlight_on else 480.0):
				state = State.PATROL
			elif distance < 32.0:
				_player.take_damage()
				state = State.STUNNED
				_stun_time = 1.5
		State.STUNNED:
			velocity = -to_player.normalized() * 40.0
			_stun_time -= delta
			if _stun_time <= 0.0:
				state = State.CHASE

	move_and_slide()
	queue_redraw()


func take_hit() -> void:
	health -= 1
	_flash = 0.12
	if health <= 0:
		if id != "":
			GameState.set_flag("dead_" + id)
		queue_free()
		return
	state = State.STUNNED
	_stun_time = 0.5


func _sight_range() -> float:
	if _player.flashlight_on:
		return sight + 300.0
	if Input.is_action_pressed("run"):
		return sight + 80.0
	return sight


func _draw() -> void:
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 18, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var tint := Color(0.05, 0.04, 0.05) if state != State.STUNNED else Color(0.2, 0.05, 0.05)
	if _flash > 0.0:
		tint = Color(0.9, 0.9, 0.9)
	if kind == Kind.WALKER:
		_draw_walker(tint)
	else:
		_draw_crawler(tint)


func _draw_walker(tint: Color) -> void:
	var sway := sin(Time.get_ticks_msec() / 220.0) * 3.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, 0), Vector2(12, 0), Vector2(9 + sway, -62), Vector2(-9 + sway, -62)
	]), tint)
	draw_rect(Rect2(-24 + sway, -56, 8, 40), tint)
	draw_rect(Rect2(16 + sway, -56, 8, 40), tint)
	draw_circle(Vector2(sway, -68), 9, tint)
	draw_circle(Vector2(-3 + sway, -69), 1.8, Color(0.9, 0.1, 0.1))
	draw_circle(Vector2(3 + sway, -69), 1.8, Color(0.9, 0.1, 0.1))


func _draw_crawler(tint: Color) -> void:
	var skin := Color(0.45, 0.47, 0.42) if _flash <= 0.0 else tint
	var scuttle := sin(Time.get_ticks_msec() / 70.0) * 5.0
	for side in [-1.0, 1.0]:
		for leg in 3:
			var base := Vector2(side * 8.0, -9.0 + leg * 3.0)
			var tip := Vector2(side * (26.0 + leg * 3.0), -2.0 + scuttle * side * (leg - 1) * 0.4)
			draw_line(base, tip, skin.darkened(0.4), 2.0)
	draw_set_transform(Vector2(0, -10), 0.0, Vector2(1.5, 0.8))
	draw_circle(Vector2.ZERO, 12, skin)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(-4, -14), 2.2, Color(0.9, 0.1, 0.1))
	draw_circle(Vector2(4, -14), 2.2, Color(0.9, 0.1, 0.1))
