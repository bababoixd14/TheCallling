extends Node

var busy := false
var world: Node2D


func go(room_id: String, spawn: String) -> void:
	if busy:
		return
	busy = true
	await ScreenFade.fade_out(0.4)
	world.load_room(room_id, spawn)
	await get_tree().process_frame
	await ScreenFade.fade_in(0.4)
	busy = false
	world.room_entered(room_id)


func respawn() -> void:
	if busy:
		return
	busy = true
	GameState.deaths += 1
	GameState.corpse_room = GameState.current_room
	GameState.corpse_pos = world.player.global_position
	await ScreenFade.fade_out(1.0)
	GameState.health = GameState.MAX_HEALTH
	GameState.health_changed.emit()
	world.load_room(GameState.respawn_room, GameState.respawn_spawn)
	await get_tree().process_frame
	# Drop the fade below the dialogue layer so the lines show on black.
	ScreenFade.layer = 80
	await Dialogue.say(_respawn_lines())
	ScreenFade.layer = 100
	await ScreenFade.fade_in(1.5)
	world.player.invulnerable_time = 3.0
	busy = false


func _respawn_lines() -> Array:
	match GameState.deaths:
		1:
			return ["I was dead...", "I still have to find my wife."]
		2:
			return ["Again...", "I was dead. I know I was dead.", "The dark feels thicker.", "I still have to find my wife."]
		3:
			return ["How many times is this now?", "Why does the dying never last?", "I still have to find my wife."]
		_:
			return ["I keep waking up.", "Maybe I never stopped being dead.", "...I still have to find my wife."]
