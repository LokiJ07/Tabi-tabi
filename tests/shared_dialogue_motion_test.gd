extends SceneTree
## Tests the actual reusable Godot transition helpers and both chapter scenes.
## The real dialogue state must change immediately even when art eases out.
const Motion = preload("res://scripts/ui/shared_dialogue_motion.gd")
const NightOne = preload("res://scenes/main.tscn")
const NightTwo = preload("res://scenes/night02.tscn")
var failed := 0

func check(value: bool, label: String) -> void:
	if not value:
		failed += 1
		printerr("Shared dialogue cinematic: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ui := Control.new()
	root.add_child(ui)
	var panel := PanelContainer.new()
	panel.name = "SampleConversation"
	panel.custom_minimum_size = Vector2(450,240)
	ui.add_child(panel)
	var actor := Label.new()
	actor.text = "LOLA PASING"
	panel.add_child(actor)
	await process_frame
	Motion.reveal(panel,false)
	check(panel.visible and panel.has_meta("cinematic_tween"), "open fade uses the shared tween")
	check(panel.modulate.a < 1.0, "actual panel begins translucent on open")
	Motion.speaker_change([actor],false)
	check(actor.modulate.a < 1.0, "speaker cross-dissolve begins without changing text")
	check(actor.text == "LOLA PASING", "animation never destroys a conversation line")
	Motion.conceal(panel,false)
	check(not panel.visible and panel.modulate.a == 1.0, "close is synchronous for story and input")
	check(ui.get_node_or_null("DialogueExitAfterimage") != null, "non-interactive exit image persists during fade")
	Motion.reveal(panel,false)
	check(panel.visible, "rapid new conversation cancels outgoing fade safely")
	await process_frame
	Motion.conceal(panel,true)
	check(not panel.visible and panel.modulate.a == 1.0, "reduced motion closes immediately")
	Motion.reveal(panel,true)
	check(panel.visible and is_equal_approx(panel.modulate.a,1.0)
		and panel.scale == Vector2.ONE, "reduced motion reveals with no scaling or delay")
	ui.queue_free()
	await process_frame

	var night1 = NightOne.instantiate()
	root.add_child(night1)
	await process_frame
	night1._close_dialogue()
	night1.preferences.reduced_motion = false
	night1._show_dialogue("APPRENTICE: Nakakita ka?\nLOLA: Hinay-hinay lang.")
	check(night1.dialogue.visible and night1.dialogue.has_meta("cinematic_tween"),
		"Night 1 uses shared cinematic open")
	night1._advance_dialogue()
	check(night1.dialogue_speaker.text.contains("LOLA") and
		night1.dialogue_text.has_meta("speaker_tween"), "Night 1 speaker change cross-fades")
	night1._close_dialogue()
	check(not night1.dialogue.visible and night1.gameplay_hud.visible,
		"Night 1 close returns HUD instantly while visual fade finishes")
	night1.preferences.reduced_motion = true
	night1._show_dialogue("NARRATOR: Reduced motion is readable.")
	check(night1.dialogue.modulate.a == 1.0 and night1.dialogue.scale == Vector2.ONE,
		"Night 1 reduced-motion scene transition is instant")
	night1._close_dialogue()
	night1.queue_free()
	await process_frame

	var night2 = NightTwo.instantiate()
	root.add_child(night2)
	await process_frame
	check(night2.dialogue.visible and night2.modal_backdrop.visible and
		night2.dialogue.has_meta("cinematic_tween"), "Night 2 intro shares Night 1 dialogue fade and world dimming")
	night2._choose("close")
	check(not night2.dialogue.visible and night2.gameplay_controls.visible,
		"Night 2 closes dialogue without holding movement or save state")
	night2.player_pos = night2.TREE + Vector2(-120.0,50.0)
	night2._show_dialogue("KAPRE","Ayaw og kahadlok sa kahoy.",
		[{"label":"CONTINUE","action":"close"}])
	check(night2.dialogue_focus_enabled and night2.kapre_dialogue_portrait.visible,
		"Kapre is cinematic focus with a dedicated portrait")
	night2._process(.15)
	check(night2.dialogue_focus_blend > 0.0 and night2.camera.position.distance_to(night2.player_pos) > 0.1,
		"Night 2 camera eases toward nearby speaking Kapre")
	night2._choose("close")
	night2._process(.15)
	check(not night2.dialogue_focus_enabled and night2.dialogue_focus_blend < 1.0,
		"Night 2 camera returns gently to gameplay framing")
	night2.prefs.reduced_motion = true
	night2._show_dialogue("BANTAY","Quiet.",[{"label":"OK","action":"close"}])
	check(is_equal_approx(night2.dialogue.modulate.a,1.0) and night2.dialogue.scale == Vector2.ONE,
		"Night 2 reduced-motion dialogue is instant")
	night2._choose("close")
	night2.queue_free()
	await process_frame
	print("Shared Night 1/2 dialogue cinematic transitions: ",
		"PASS" if failed == 0 else str(failed) + " failures")
	quit(0 if failed == 0 else 1)
