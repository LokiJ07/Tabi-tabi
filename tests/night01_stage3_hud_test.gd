extends SceneTree
## Regresses the exact phone screenshot: Stage 3 instructions previously
## overlapped phase, alarm, nearby interaction prompt and courage text.
const GameScene = preload("res://scenes/main.tscn")
const Santelmo = preload("res://scripts/encounters/santelmo_actor.gd")
var failures := 0

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("Stage 3 HUD: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	game._close_dialogue()
	game.in_lola_hut = false
	game.talked_to_lola = true
	game.talked_to_dado = true
	game.is_night = true
	game.story.phase = 3
	game.story.guide_progress = 0.0
	game._refresh_choices()
	game._update_objective()
	game.interact_hint.text = "INTERACT • OLD MOORING"
	game.alarm_label.text = "SANTELMO • CALM"
	game.alarm_label.show()
	game.courage_label.text = "COURAGE 100 / 100"
	game.courage_label.show()
	await process_frame
	await process_frame

	check(game.status_panel.name == "QuestStatusCard", "quest gets one dedicated dark status card")
	check(game.info.get_parent() == game.status_stack, "heading belongs in vertical status stack")
	check(game.objective.get_parent() == game.status_stack, "wrapping objective belongs in vertical status stack")
	check(game.stage_label.get_parent() == game.status_stack, "stage progress belongs in vertical status stack")
	check(game.alarm_label.get_parent() == game.status_stack, "Santelmo warning belongs in vertical status stack")
	check(game.courage_label.get_parent() == game.status_stack, "courage belongs in vertical status stack")
	check(game.objective.autowrap_mode != TextServer.AUTOWRAP_OFF, "objective wraps for narrow landscape screens")
	check(game.status_stack.get_child(1) == game.objective and game.status_stack.get_child(2) == game.stage_label, "objective followed by progress, not fixed overlapping coordinates")
	check(game.objective.text.contains("GREEN") and game.objective.text.contains("SHORE"), "stage 3 guidance includes landing and safe direction")
	check(game.choice_buttons[0].text == "HOW TO GUIDE", "stage 3 button no longer misleadingly promises immediate resolution")
	check(game.interact_hint.anchor_left > game.status_panel.anchor_right, "nearby prompt on separate side of screen")
	check(game.santelmo == null or game.santelmo.landing_marker != null, "existing Santelmo encounter is retained")

	game.preferences.text_scale = 1.4
	game._apply_preferences()
	await process_frame
	await process_frame
	check(game.objective.get_theme_font_size("font_size") >= 30, "objective remains accessible at 140 percent")
	check(game.status_panel.get_child(0) == game.status_stack, "status stack remains within card after scaling")

	var creature = Santelmo.new()
	root.add_child(creature)
	creature.set_encounter_phase(3)
	check(creature.landing_marker.visible, "landing ring is visible only for Stage 3")
	check(creature.landing_marker.get_node_or_null("SafeLandingBeacon") != null, "green guidance marker extends above scenery")
	check(creature.landing_marker.get_node_or_null("SafeGreenSpill") != null, "marker has localized green light")
	var disc := creature.landing_marker.get_child(0) as MeshInstance3D
	check((disc.mesh as CylinderMesh).top_radius >= 0.9, "green landing ring enlarged for small phones")
	creature.set_encounter_phase(2)
	check(not creature.landing_marker.visible, "landing marker hidden before stage 3")
	creature.queue_free()
	game.queue_free()
	print("Stage 3 phone HUD and guidance visibility: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
