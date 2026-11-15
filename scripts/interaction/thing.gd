class_name Thing
extends Node2D

# A prop in a room. Position is the bottom-centre of the object.
# If an action is set, the player can walk up and press E.

var prompt := "Examine"
var action := Callable()
var available := Callable()
var box_size := Vector2.ZERO
var color := Color(0.3, 0.25, 0.2)
var reach := 70.0
var caption := ""


static func make(pos: Vector2, size: Vector2, fill: Color, solid := true) -> Thing:
	var thing := Thing.new()
	thing.position = pos
	thing.box_size = size
	thing.color = fill
	thing.y_sort_enabled = true
	if solid and size != Vector2.ZERO:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(size.x, minf(size.y, 28.0))
		shape.shape = rect
		shape.position = Vector2(0, -rect.size.y / 2.0)
		body.add_child(shape)
		thing.add_child(body)
	return thing


func set_action(new_prompt: String, new_action: Callable) -> Thing:
	prompt = new_prompt
	action = new_action
	reach = maxf(70.0, box_size.x / 2.0 + 45.0)
	add_to_group("interactable")
	return self


func can_use() -> bool:
	return not available.is_valid() or available.call()


func use() -> void:
	if action.is_valid():
		action.call()


func distance_to_player(player_position: Vector2) -> float:
	var center := global_position + Vector2(0, -box_size.y / 2.0)
	return center.distance_to(player_position)


func _draw() -> void:
	if box_size == Vector2.ZERO:
		return
	var half := box_size.x / 2.0
	draw_rect(Rect2(-half, -box_size.y, box_size.x, box_size.y), color)
	var top_height := minf(10.0, box_size.y / 3.0)
	draw_rect(Rect2(-half, -box_size.y, box_size.x, top_height), color.lightened(0.15))
	draw_rect(Rect2(-half, -box_size.y, box_size.x, box_size.y), color.darkened(0.5), false, 2.0)
	if caption != "":
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-half, -box_size.y / 2.0), caption, HORIZONTAL_ALIGNMENT_CENTER, box_size.x, 16, Color(0.8, 0.75, 0.6))
