extends CanvasLayer

var rect: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.modulate.a = 0.0
	add_child(rect)


func fade_out(duration := 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, duration)
	await tween.finished


func fade_in(duration := 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	await tween.finished
