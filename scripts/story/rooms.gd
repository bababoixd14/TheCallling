class_name Rooms
extends RefCounted

# Builds each room. Every build returns {ambient, fog, checkpoint?}.

const FLOOR := Rect2(60, 220, 1160, 440)


static func build(w: World, id: String) -> Dictionary:
	match id:
		"cabin":
			return _cabin(w)
		"forest_1":
			return _forest_1(w)
		"forest_2":
			return _forest_2(w)
		"forest_3":
			return _forest_3(w)
		_:
			return RoomsTown.build(w, id)


static func entered(w: World, id: String) -> void:
	match id:
		"cabin":
			if not GameState.has_flag("intro_done"):
				GameState.set_flag("intro_done")
				await w.chapter_title("PROLOGUE — THE CABIN")
				await Dialogue.say(["Daniel: ...", "Something is scratching at the glass.", "Anna's side of the bed is empty. Maybe she's in the kitchen. I should look out the window."])
			elif GameState.has_flag("returned") and not GameState.has_flag("missing_seen"):
				GameState.set_flag("missing_seen")
				await Dialogue.say(["The front door is hanging open. Cold air pours in.", "Daniel: Anna?", "Daniel: Anna!", "The bed hasn't been slept in. Her coat is still on the hook.", "Daniel: She wouldn't go out without her coat. Something has happened to her."])
		"forest_2":
			if not GameState.has_flag("ch1"):
				GameState.set_flag("ch1")
				await w.chapter_title("CHAPTER 1 — THE FOREST")
				await Dialogue.say(["Daniel: I'll find you, Anna. I'll find you.", "[F] toggles the flashlight. Hold Shift to run. Monsters notice noise and light."])
		"town_street":
			if not GameState.has_flag("ch2"):
				GameState.set_flag("ch2")
				await w.chapter_title("CHAPTER 2 — THE TOWN")
				await Dialogue.say(["Daniel: There's no town on any map I've seen.", "Every window is dark. Something shifts behind the fog."])
			elif GameState.has_flag("remembered") and not GameState.has_flag("ch5"):
				GameState.set_flag("ch5")
				await w.chapter_title("CHAPTER 5 — THE ENDING")
				await Dialogue.say(["Daniel: I have to leave this place.", "The road east is the only way out."])
		"police":
			if not GameState.has_flag("ch3"):
				GameState.set_flag("ch3")
				await w.chapter_title("CHAPTER 3 — THE PAST")
		"accident":
			if not GameState.has_flag("ch4"):
				GameState.set_flag("ch4")
				await w.chapter_title("CHAPTER 4 — THE TRUTH")
				await Dialogue.say(["Rain on broken glass. A car folded around a tree.", "I know this place."])


static func _cabin(w: World) -> Dictionary:
	w.box_room(FLOOR, Color(0.32, 0.22, 0.15), Color(0.28, 0.2, 0.15))
	w.spawns = {"start": Vector2(400, 480), "from_forest": Vector2(1080, 330)}
	w.light(Vector2(900, 320), Color(1.0, 0.8, 0.5), 3.5, 0.9)
	w.light(Vector2(300, 300), Color(0.6, 0.7, 1.0), 2.5, 0.5)

	w.examine(Vector2(250, 350), Vector2(200, 80), Color(0.42, 0.3, 0.28), "Look at the bed", [
		"The sheets are tangled. Anna's pillow is still dented." if not GameState.has_flag("returned") else "The sheets are cold. Anna's pillow hasn't moved."])
	w.note(Vector2(120, 330), "photo_cabin", "Photograph on the nightstand",
		"A framed photograph. Daniel and Anna in front of this cabin, the first week they moved in. Anna is laughing.\n\nBehind the glass, tucked in the frame, a second photograph: the two of them, not looking at each other.")
	var window := w.examine(Vector2(640, 220), Vector2(130, 90), Color(0.12, 0.18, 0.3), "Look out the window", ["Nothing but trees."])
	window.set_action("Look out the window", func() -> void:
		if GameState.has_flag("saw_figure"):
			await Dialogue.say(["Nothing out there now. Only trees."])
			return
		GameState.set_flag("saw_figure")
		await Dialogue.say(["A pale figure stands between the trees. Perfectly still.", "It is looking at the cabin. It is looking at me.", "Daniel: The woods are calling me.", "My feet are already moving toward the door."]))

	w.examine(Vector2(1000, 400), Vector2(150, 60), Color(0.35, 0.25, 0.18), "Look at the table", [
		"Two cups. One still holds a little cold tea, the other has never been used.", "Daniel: Anna always set out two cups. Even on the bad nights."])
	w.examine(Vector2(1150, 300), Vector2(30, 60), Color(0.2, 0.25, 0.3), "Look at the coat", [
		"Anna's green coat hangs on its hook.", "Daniel: She wouldn't go outside in this cold without it."])
	var wall_calendar := w.examine(Vector2(500, 220), Vector2(60, 70), Color(0.7, 0.65, 0.5), "Look at the calendar", [
		"A wall calendar. Every day is crossed off in black ink, except one in March. It has been circled so hard the paper has torn."])
	wall_calendar.reach = 120.0
	w.pickup(Vector2(780, 560), Vector2(40, 24), Color(0.2, 0.2, 0.2), "flashlight", "Flashlight", [
		"A heavy flashlight, left in the kitchen drawer.", "Daniel: Good. Now I can see. [F] to switch it on."])
	var anna_note := w.note(Vector2(1000, 370), "anna_note", "Anna's note",
		"Daniel,\n\nI can't keep doing this. Every night the same argument, the same silence afterwards. I think we both know what's happened to us.\n\nI'm going to tell you tonight, in the car, before I lose my nerve. Please don't turn away from me again.\n\n— A.", Vector2(26, 16))
	anna_note.available = func() -> bool: return GameState.has_flag("returned") and not GameState.has_document("anna_note")
	anna_note.visible = anna_note.can_use()

	var front_door := w.prop(Vector2(1080, 220), Vector2(80, 120), Color(0.25, 0.16, 0.1), false)
	front_door.set_action("Go outside", func() -> void:
		if not GameState.has_flag("saw_figure"):
			await Dialogue.say(["It's the middle of the night. There's no reason to go outside.", "Something made that noise, though. Maybe the window..."])
			return
		if not GameState.has_flag("returned"):
			SceneManager.go("forest_1", "cabin")
			return
		if not GameState.has_item("flashlight"):
			await Dialogue.say(["I can't search the woods in the dark.", "There's a flashlight in the kitchen drawer."])
			return
		SceneManager.go("forest_2", "cabin"))
	return {"ambient": Color(0.35, 0.3, 0.33), "fog": 0.0, "checkpoint": true}


static func _trees(w: World, count: int, seed_value: int, avoid: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var placed := 0
	while placed < count:
		var pos := Vector2(rng.randf_range(100, 1180), rng.randf_range(260, 650))
		if avoid.has_point(pos):
			continue
		var tall := rng.randf_range(120, 200)
		w.prop(pos, Vector2(rng.randf_range(28, 40), tall), Color(0.1, 0.14, 0.1))
		placed += 1


static func _forest_1(w: World) -> Dictionary:
	w.box_room(FLOOR, Color(0.12, 0.16, 0.1), Color(0.06, 0.09, 0.07))
	w.spawns = {"cabin": Vector2(140, 440)}
	_trees(w, 14, 11, Rect2(60, 330, 1160, 220))
	w.light(Vector2(640, 100), Color(0.5, 0.6, 1.0), 6.0, 0.35)
	w.trigger(Rect2(520, 300, 120, 300), "forest_whisper", func() -> void:
		await Dialogue.say(["A shape of white between the trees, always just ahead.", "Daniel: Wait... who are you?"]))
	w.trigger(Rect2(1060, 300, 160, 300), "forest_lost", func() -> void:
		await Dialogue.say(["Daniel: ...Where am I?", "I don't remember walking this far.", "The figure is gone. The cabin light is gone too.", "Daniel: I have to go back."])
		GameState.set_flag("returned")
		SceneManager.go("cabin", "from_forest"))
	return {"ambient": Color(0.14, 0.16, 0.22), "fog": 0.12}


static func _forest_2(w: World) -> Dictionary:
	w.box_room(FLOOR, Color(0.1, 0.14, 0.09), Color(0.05, 0.08, 0.06))
	w.spawns = {"cabin": Vector2(140, 440), "east": Vector2(1140, 440)}
	_trees(w, 16, 23, Rect2(60, 360, 1160, 140))
	w.light(Vector2(640, 100), Color(0.5, 0.6, 1.0), 6.0, 0.3)
	w.note(Vector2(520, 450), "forest_photo", "Muddy photograph",
		"A photograph half buried in the mud. Daniel and Anna on a pier at sunset.\n\nOn the back, in Anna's handwriting: \"Our first summer. We were happy. Weren't we?\"")
	w.monster(Vector2(700, 300), Vector2(1000, 600), Monster.Kind.WALKER, "forest2_walker")
	w.pickup_ammo(Vector2(300, 540), 2, "ammo_forest2_a")
	w.pickup_ammo(Vector2(880, 580), 2, "ammo_forest2_b")
	w.trigger(Rect2(60, 340, 40, 240), "", func() -> void: SceneManager.go("cabin", "from_forest"))
	w.trigger(Rect2(1180, 340, 40, 240), "", func() -> void: SceneManager.go("forest_3", "west"))
	return {"ambient": Color(0.07, 0.08, 0.12), "fog": 0.18}


static func _forest_3(w: World) -> Dictionary:
	w.box_room(FLOOR, Color(0.1, 0.12, 0.09), Color(0.05, 0.07, 0.06))
	w.spawns = {"west": Vector2(140, 440), "east": Vector2(1140, 440)}
	_trees(w, 12, 37, Rect2(60, 360, 1160, 140))
	w.light(Vector2(640, 100), Color(0.5, 0.6, 1.0), 6.0, 0.25)
	w.examine(Vector2(560, 380), Vector2(220, 150), Color(0.25, 0.2, 0.15), "Look at the shed", [
		"A rotting shed. Inside, a child's bicycle, and a radio that crackles with something like a voice."])
	w.note(Vector2(640, 500), "torn_page", "Torn journal page",
		"...she stopped talking to me weeks ago. I keep saying I'll fix it. I keep driving instead of listening.\n\nIf I tell her about the job, she'll say I never told her. If I don't, she'll say I never tell her anything. There is no right way to be in this house.\n\nThe road is the only place we don't fight. Maybe that's why I like it.")
	w.monster(Vector2(300, 320), Vector2(900, 600), Monster.Kind.CRAWLER, "forest3_crawler")
	w.pickup_ammo(Vector2(420, 580), 2, "ammo_forest3_a")
	w.pickup_ammo(Vector2(1050, 300), 2, "ammo_forest3_b")
	w.trigger(Rect2(60, 340, 40, 240), "", func() -> void: SceneManager.go("forest_2", "east"))
	w.trigger(Rect2(1180, 340, 40, 240), "", func() -> void:
		if not GameState.has_flag("road_found"):
			GameState.set_flag("road_found")
			await Dialogue.say(["Daniel: A road. I've never seen it before.", "It leads to a town that was not here yesterday."])
		SceneManager.go("town_street", "forest"))
	return {"ambient": Color(0.07, 0.08, 0.11), "fog": 0.2}
