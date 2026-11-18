extends SceneTree
## Cinematic dialogue and modal-input transition parity across all late
## chapters. Night 5/6 now prevent rushed NPC dialogue choices too.
## No quest state changes, cross-region save data or synthetic ending required.
const Night04 = preload("res://scenes/night04.tscn")
const Night05 = preload("res://scenes/night05.tscn")
const Night06 = preload("res://scenes/night06.tscn")
const Night07 = preload("res://scenes/night07.tscn")

var failed := 0

func check(condition: bool, why: String) -> void:
	if not condition:
		failed += 1
		printerr("Nights 4–7 cinematic transition regression: "+why)

func _initialize() -> void:
	call_deferred("_run")

func _test_dialogue(game: Node2D, chapter: String) -> void:
	if game.dialogue.visible:
		game._close_dialogue()
	game.prefs.reduced_motion = false
	game._talk("BANTAY","The route is safe, but listen to the village witnesses before making a decision.",
		[{"label":"CONTINUE","action":"close"}])
	check(game.dialogue.visible and game.dialogue.has_meta("cinematic_tween"),
		chapter+" dialogue uses the canonical 220ms fade/scale")
	check(game.dialogue_body.visible_characters == 0,
		chapter+" smoothly reveals actual words, not a static popup")
	check(not game.controls.visible,
		chapter+" modal prevents accidental movement while NPC speaks")
	game._press_dialogue_choice("close")
	check(game.dialogue.visible and game.dialogue_body.visible_characters == -1,
		chapter+" first quick choice tap completes the text without skipping story")
	game._press_dialogue_choice("close")
	check(not game.dialogue.visible and game.controls.visible,
		chapter+" second tap closes immediately and restores real controls")
	check(game.controls.modulate.a < 1.0,
		chapter+" touch HUD returns with gentle consistent easing")
	# Rapidly chaining two speakers must never display a stale line.
	game._talk("MARA","First account.",[{"label":"NEXT","action":"close"}])
	game._talk("LOLA PASING","Second account is the only visible current line.",
		[{"label":"CLOSE","action":"close"}])
	check(game.dialogue_speaker.text == "LOLA PASING"
		and game.dialogue_body.text.begins_with("Second account"),
		chapter+" rapid speaker switch replaces the previous dialogue")
	game._close_dialogue()
	game.prefs.reduced_motion = true
	game._talk("MARA","Reduced Motion instantly displays every word.",
		[{"label":"CLOSE","action":"close"}])
	check(game.dialogue.modulate.a == 1.0 and game.dialogue.scale == Vector2.ONE
		and game.dialogue_body.visible_characters == -1,
		chapter+" Reduced Motion disables transition delays without hiding dialogue")
	game._press_dialogue_choice("close")
	check(not game.dialogue.visible and game.controls.visible,
		chapter+" Reduced Motion restores controls synchronously")

func _run() -> void:
	var wake = Night04.instantiate()
	root.add_child(wake)
	await process_frame
	_test_dialogue(wake,"Night 4 Wake")
	wake.queue_free()
	await process_frame
	var farm = Night05.instantiate()
	root.add_child(farm)
	await process_frame
	_test_dialogue(farm,"Night 5 Farm")
	farm.queue_free()
	await process_frame
	var river = Night06.instantiate()
	root.add_child(river)
	await process_frame
	_test_dialogue(river,"Night 6 River")
	river.queue_free()
	await process_frame
	var balete = Night07.instantiate()
	root.add_child(balete)
	await process_frame
	_test_dialogue(balete,"Night 7 Balete")
	balete.queue_free()
	await process_frame
	print("Nights 4–7 dialogue cinematic parity: ",
		"PASS" if failed == 0 else str(failed)+" failures")
	quit(0 if failed == 0 else 1)
