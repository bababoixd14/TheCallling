class_name RoomsTown
extends RefCounted

const FLOOR := Rect2(60, 220, 1160, 440)
const HOSPITAL_CODE := "1403"


static func build(w: World, id: String) -> Dictionary:
	match id:
		"town_street":
			return _street(w)
		"motel":
			return _motel(w)
		"police":
			return _police(w)
		"hospital":
			return _hospital(w)
		"accident":
			return _accident(w)
	push_error("Unknown room: " + id)
	return {"ambient": Color.BLACK, "fog": 0.0}


static func _exit_door(w: World, target_spawn: String) -> void:
	var exit_door := w.prop(Vector2(640, 662), Vector2(100, 14), Color(0.2, 0.15, 0.1), false)
	exit_door.set_action("Leave", func() -> void: SceneManager.go("town_street", target_spawn))


static func _building_door(w: World, x: float, caption: String, color: Color, target: String, check := Callable()) -> void:
	var building := w.prop(Vector2(x, 220), Vector2(150, 150), color.darkened(0.3), false)
	building.caption = caption
	var entrance := w.door(Vector2(x, 222), Vector2(54, 84), color, "Enter " + caption.to_lower(), target, "door", check)
	entrance.reach = 90.0


static func _street(w: World) -> Dictionary:
	w.box_room(FLOOR, Color(0.17, 0.17, 0.18), Color(0.12, 0.12, 0.14))
	w.spawns = {
		"forest": Vector2(140, 480), "motel_out": Vector2(300, 290),
		"police_out": Vector2(640, 290), "hospital_out": Vector2(980, 290),
	}
	w.light(Vector2(400, 330), Color(0.9, 0.85, 0.6), 3.0, 0.7)
	w.light(Vector2(850, 330), Color(0.9, 0.85, 0.6), 3.0, 0.5)

	_building_door(w, 300, "MOTEL", Color(0.3, 0.2, 0.2), "motel")
	_building_door(w, 640, "POLICE", Color(0.2, 0.25, 0.35), "police", func() -> bool:
		if GameState.has_item("police_key") or GameState.has_flag("police_open"):
			GameState.set_flag("police_open")
			return true
		await Dialogue.say(["The station door is locked tight.", "Daniel: There must be a key somewhere in town."])
		return false)
	_building_door(w, 980, "HOSPITAL", Color(0.25, 0.32, 0.3), "hospital", func() -> bool:
		if GameState.has_flag("hospital_open"):
			return true
		if not GameState.has_flag("code_entered"):
			await Dialogue.say(["A keypad glows beside the staff entrance.", "Four digits."])
			if not await w.ask_code(HOSPITAL_CODE):
				await Dialogue.say(["Wrong code. The keypad lets out a low, flat tone."])
				return false
			GameState.set_flag("code_entered")
			await Dialogue.say(["The keypad beeps. A green light.", "The door doesn't budge. The bolt has rusted solid."])
		if not GameState.has_item("gun"):
			await Dialogue.say(["Daniel: I need something to break this lock off."])
			return false
		if GameState.ammo <= 0:
			await Dialogue.say(["The revolver is empty.", "Daniel: There must be bullets lying around somewhere."])
			return false
		await Dialogue.say(["Daniel: Stand back."])
		GameState.add_ammo(-1)
		GameState.set_flag("hospital_open")
		await Dialogue.say(["BANG.", "The lock blows off the door. Something inside the hospital stirs."])
		return true)

	var grocery := w.examine(Vector2(1160, 240), Vector2(130, 110), Color(0.22, 0.25, 0.2), "Look at the grocery store", [
		"The grocery store window is full of rotted fruit and empty shelves.", "A shopping list is taped to the glass in Anna's handwriting: milk, bread, tea, \"something for Daniel's birthday\"."])
	grocery.caption = "GROCERY"
	w.examine(Vector2(470, 520), Vector2(140, 50), Color(0.2, 0.22, 0.25), "Look at the car", [
		"A rusted sedan. Its windscreen is cracked from the inside.", "Daniel: Why do I recognise the cracks?"])
	w.examine(Vector2(820, 560), Vector2(130, 50), Color(0.25, 0.2, 0.2), "Look at the wreck", [
		"The seat belts are still buckled. Both of them."])
	w.monster(Vector2(520, 380), Vector2(1050, 380), Monster.Kind.WALKER, "street_walker")
	w.monster(Vector2(1100, 600), Vector2(560, 600), Monster.Kind.CRAWLER, "street_crawler")
	w.pickup_ammo(Vector2(230, 610), 3, "ammo_street_a")
	w.pickup_ammo(Vector2(720, 310), 2, "ammo_street_b")
	w.pickup_ammo(Vector2(1100, 500), 2, "ammo_street_c")

	w.trigger(Rect2(60, 340, 40, 240), "", func() -> void: SceneManager.go("forest_3", "east"))
	if GameState.has_flag("remembered") and not GameState.has_flag("ending_started"):
		w.trigger(Rect2(1180, 340, 40, 240), "", func() -> void: w.play_ending())
	else:
		w.trigger(Rect2(1180, 340, 40, 240), "east_hint", func() -> void:
			await Dialogue.say(["The road east vanishes into thick fog.", "Daniel: Not yet. There's something here I still haven't understood."]))
	return {"ambient": Color(0.09, 0.1, 0.14), "fog": 0.3, "checkpoint": true}


static func _motel(w: World) -> Dictionary:
	w.box_room(FLOOR, Color(0.25, 0.18, 0.15), Color(0.2, 0.16, 0.14))
	w.spawns = {"door": Vector2(640, 600)}
	w.light(Vector2(640, 330), Color(1.0, 0.75, 0.45), 3.5, 0.8)
	_exit_door(w, "motel_out")

	w.examine(Vector2(640, 400), Vector2(280, 70), Color(0.3, 0.2, 0.14), "Look at the desk", ["A reception desk. A bell sits on it, covered in dust."])
	w.note(Vector2(560, 360), "motel_register", "Guest register",
		"Room 6 — \"D. and A.\" — 3 nights.\n\nA line has been added underneath, in a different hand: \"Wife checked out early. Left alone, crying. Husband stayed. Wouldn't speak to anyone.\"")
	w.examine(Vector2(240, 420), Vector2(190, 70), Color(0.35, 0.22, 0.2), "Look at the bed", ["A motel bed, neatly made. One side is pressed down as if someone is lying there right now."])
	w.note(Vector2(240, 380), "anna_letter", "Unsent letter",
		"Daniel,\n\nI don't know who we've become. I looked at you across the dinner table tonight and you were a stranger.\n\nI keep thinking that if I leave, you'll finally have to notice. I'm sorry that's what it has come to.\n\nI'll tell you in the morning. I'll tell you in the car.")
	w.pickup_ammo(Vector2(880, 580), 2, "ammo_motel")
	w.pickup(Vector2(960, 300), Vector2(26, 22), Color(0.7, 0.6, 0.2), "police_key", "Police station key", [
		"A brass key on a numbered tag. The tag reads: \"POLICE — MAIN\".", "Daniel: The station. Maybe they know where she is."])
	return {"ambient": Color(0.14, 0.12, 0.12), "fog": 0.0}


static func _police(w: World) -> Dictionary:
	w.box_room(FLOOR, Color(0.18, 0.2, 0.22), Color(0.15, 0.17, 0.2))
	w.spawns = {"door": Vector2(640, 600)}
	w.light(Vector2(640, 330), Color(0.8, 0.9, 1.0), 3.5, 0.7)
	_exit_door(w, "police_out")

	w.examine(Vector2(400, 420), Vector2(220, 70), Color(0.22, 0.22, 0.25), "Look at the desk", ["A desk with a cold cup of coffee. The calendar above it is stuck on March."])
	w.pickup(Vector2(400, 380), Vector2(30, 14), Color(0.12, 0.12, 0.14), "gun", "Revolver", [
		"A revolver, left in the desk drawer. Two rounds in the cylinder.",
		"Daniel: It's heavy. Whoever left it here wasn't coming back.",
		"Press Space or click to fire. Bullets are scarce, so make them count."], 2)
	w.pickup_ammo(Vector2(200, 580), 2, "ammo_police")
	w.examine(Vector2(1000, 400), Vector2(180, 120), Color(0.15, 0.15, 0.18), "Look at the cell", ["The cell is empty. A blanket is folded neatly on the cot.", "Daniel: I feel like I've been held somewhere like this."])
	w.note(Vector2(640, 300), "police_report", "Police report",
		"INCIDENT REPORT\n\nDate of incident: 14 March (14/03).\nTime: 23:40. Location: Route 9, mile 12.\n\nSingle-vehicle collision. Driver (D.) survived with minor injuries. Passenger (A.) died at the scene. A witness heard the couple arguing before the car left the road.\n\nNOTE: The hospital staff-door code was reset to the incident date: day first, then month. Four digits.")
	w.note(Vector2(520, 340), "clipping", "Newspaper clipping",
		"LOCAL WOMAN KILLED IN CRASH\n\nA woman died on Route 9 on Friday night when the car she was travelling in left the road. Her husband survived. Neighbours describe a quiet couple who \"kept to themselves\".\n\nHer name is withheld pending family notification.")
	return {"ambient": Color(0.1, 0.11, 0.14), "fog": 0.0}


static func _hospital(w: World) -> Dictionary:
	w.box_room(FLOOR, Color(0.2, 0.25, 0.23), Color(0.17, 0.22, 0.2))
	w.spawns = {"door": Vector2(640, 600), "bay": Vector2(1100, 300)}
	w.light(Vector2(300, 330), Color(0.7, 1.0, 0.9), 3.0, 0.6)
	w.light(Vector2(900, 400), Color(0.7, 1.0, 0.9), 3.0, 0.4)
	_exit_door(w, "hospital_out")

	w.examine(Vector2(240, 420), Vector2(180, 70), Color(0.3, 0.32, 0.32), "Look at the bed", ["A hospital bed with the sheet pulled all the way over the pillow."])
	w.note(Vector2(240, 380), "chart_anna", "Patient chart: A.",
		"ADMITTED: 14 March, 23:58.\n\nFemale, 34. Brought in by ambulance from Route 9. Injuries incompatible with life. Pronounced dead on arrival.\n\nNext of kin: husband (D.), currently in treatment. Not yet informed.")
	w.examine(Vector2(560, 450), Vector2(180, 70), Color(0.3, 0.32, 0.32), "Look at the second bed", ["The sheets are damp. Someone lay here for a long time, whispering a name."])
	w.note(Vector2(560, 410), "chart_daniel", "Patient chart: D.",
		"Male, 36. Minor injuries, severe shock. Retrograde amnesia for the hours before the collision.\n\nPatient repeatedly asks where his wife is. Staff instructed not to correct him until he is ready.")
	w.monster(Vector2(300, 540), Vector2(950, 540), Monster.Kind.CRAWLER, "hospital_crawler")
	w.pickup_ammo(Vector2(900, 580), 3, "ammo_hospital_a")
	w.pickup_ammo(Vector2(200, 300), 2, "ammo_hospital_b")

	var bay := w.prop(Vector2(1100, 220), Vector2(90, 120), Color(0.15, 0.2, 0.18), false)
	bay.caption = "AMBULANCE BAY"
	bay.set_action("Open the ambulance bay", func() -> void:
		if not GameState.has_document("chart_anna"):
			await Dialogue.say(["The bay doors are chained shut.", "Daniel: I should look through the rooms first. Something here has my name on it."])
			return
		await Dialogue.say(["The chain falls away on its own.", "Beyond the doors, a long dark road."])
		SceneManager.go("accident", "start"))
	return {"ambient": Color(0.1, 0.12, 0.12), "fog": 0.05}


static func _accident(w: World) -> Dictionary:
	w.box_room(FLOOR, Color(0.1, 0.1, 0.11), Color(0.05, 0.06, 0.08))
	w.spawns = {"start": Vector2(140, 520)}
	w.light(Vector2(540, 430), Color(1.0, 0.9, 0.6), 3.0, 1.2)
	w.light(Vector2(640, 100), Color(0.5, 0.6, 1.0), 6.0, 0.25)

	w.examine(Vector2(300, 600), Vector2(160, 10), Color(0.04, 0.04, 0.04), "Look at the skid marks", [
		"Long black skid marks that end at a splintered tree."])
	w.examine(Vector2(900, 430), Vector2(70, 130), Color(0.12, 0.1, 0.08), "Look at the tree", ["The bark is torn open. Something once hit it very hard."])
	w.examine(Vector2(780, 540), Vector2(34, 16), Color(0.1, 0.35, 0.2), "Look at the scarf", ["Anna's green scarf, soaked through. She never took it off in the car."])

	var car := w.prop(Vector2(640, 440), Vector2(220, 90), Color(0.28, 0.1, 0.1))
	car.set_action("Look inside the car", func() -> void:
		if GameState.has_flag("boss_started"):
			return
		await Dialogue.say([
			"The driver's door is torn off. The steering wheel is bent.",
			"Daniel: We were arguing. About the job. About everything.",
			"Daniel: She said my name. I turned to look at her. Only for a second.",
			"The road bent. The tree did not move.",
			"Anna: Daniel, why are you still looking for me?",
			"The wreck groans. Something enormous drags itself out of the dark.",
			"It has my face."])
		GameState.set_flag("boss_started")
		GameState.respawn_room = "accident"
		GameState.respawn_spawn = "start"
		_spawn_boss(w))

	if GameState.has_flag("boss_started") and not GameState.has_flag("remembered"):
		_spawn_boss(w)
	else:
		w.pickup_ammo(Vector2(300, 320), 3, "ammo_accident")
	w.trigger(Rect2(60, 340, 40, 240), "", func() -> void: SceneManager.go("hospital", "bay"))
	return {"ambient": Color(0.05, 0.06, 0.09), "fog": 0.35}


static func _spawn_boss(w: World) -> void:
	GameState.ammo = maxi(GameState.ammo, 10)
	GameState.ammo_changed.emit()
	var boss := Boss.new()
	boss.position = Vector2(980, 330)
	boss.drop_ammo = func(pos: Vector2) -> void: w.pickup_ammo(pos, 4, "")
	boss.defeated.connect(func() -> void: _on_boss_defeated())
	w.objects.add_child(boss)


static func _on_boss_defeated() -> void:
	await Dialogue.say([
		"The giant kneels in the rain. Its face is mine.",
		"Daniel: It was never only guilt.",
		"Daniel: It was the part of me that wanted to die with you.",
		"Anna: Daniel... put it down.",
		"Daniel: I can't bring you back. And I can't follow you.",
		"The revolver slips from his hand and sinks into the wet road.",
		"Daniel: I remember now."])
	GameState.items.erase("gun")
	GameState.ammo = 0
	GameState.ammo_changed.emit()
	GameState.set_flag("remembered")
	SceneManager.go("town_street", "forest")
