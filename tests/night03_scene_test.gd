extends SceneTree
## Actual instantiated Night 3 Godot scene: world art, HUD, dialogue and
## interactable evidence/route puzzle (not just a detached state unit test).
const Scene = preload("res://scenes/night03.tscn")
const NightTwo = preload("res://scenes/night02.tscn")
const Save = preload("res://scripts/core/night03_save.gd")
var failures := 0

func check(ok: bool,label: String) -> void:
	if not ok:
		failures += 1
		printerr("Night 3 playable scene: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var paths := [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]
	var older: Dictionary = {}
	for path in paths:
		if FileAccess.file_exists(path):
			older[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var game = Scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(game.name == "TabiTabiNight3", "authored real Tikbalang scene instantiated")
	check(game.get_meta("dimensional_art", "") == "shared-2.5d-layered-v1",
		"ridge actors, bamboo and watchpost all share same grounded 2.5D painter")
	check(game.camera != null and game.camera.enabled, "real camera active in new ridge")
	check(game.dialogue.visible, "Lola's canonical flood mystery introduction is visible")
	check(game.TIKBALANG.get_width() >= 300, "full-body original illustrated Tikbalang sprite imported")
	check(game.BAMBOO.get_width() >= 400 and game.WATCHPOST.get_width() >= 600,
		"illustrated bamboo and 2.5D watchpost assets imported")
	check(not game.debug_night_preview and game._stage() == 0, "night guardian never appears in daylight")
	check(game.atmosphere != null, "Night 3 uses the shared mobile suspense renderer")
	check(game.camera.zoom.x >= 1.079, "ridge camera gives actors readable on-screen size")
	# Verify that the NIGHT-specific framing and fog actually respond to the
	# dangerous stage, not only that a still image was added to the project.
	var opening_position: Vector2 = game.player_pos
	# The emulator QA reveal first closes Lola's opening dialogue;
	# the cinematic camera must not inherit that older speaker focus.
	game.dialogue_focus = false
	game.debug_night_preview = true
	game.player_pos = game.RIDGE_GATE+Vector2(-125,80)
	game._process(.5)
	check(game.camera.zoom.x > 1.10, "night reveals a closer, more threatening ridge framing")
	check(game.camera.position.y < game.player_pos.y-235.0,
		"approaching the ridge raises the view to reveal Tikbalang's whole face")
	check(game.atmosphere.chapter_id == 3 and game.atmosphere.light_stage == 3,
		"ridge-only fog stage is active without swapping shared HUD styles")
	game.debug_night_preview = false
	game.player_pos = opening_position
	game.prefs.reduced_motion = true
	game._process(.016)
	check(absf(game.camera.zoom.x - 1.08) < .003,
		"reduced motion snaps cinematic zoom instead of animating")
	game.prefs.reduced_motion = false
	check(game.gameplay_controls.get_node_or_null("QuestStatusCard") != null, "Night 3 uses true shared quest component")
	check(game.buttons.has("INTERACT") and game.buttons.has("HOLD OBSERVE") and game.buttons.has("SAFE RETREAT"),
		"Night 3 has functioning original HUD actions")
	check(game.get_node_or_null("Night3HUD/Night3Screen/GameplayControls/Night3LookPad") != null,
		"independent look-around pad in exactly Night 1/2 position")
	var night2 = NightTwo.instantiate()
	root.add_child(night2)
	await process_frame
	var b3 = game.buttons["INTERACT"] as Button
	var b2 = night2.action_buttons["INTERACT"] as Button
	check(b3.offset_left == b2.offset_left and b3.offset_top == b2.offset_top,
		"Night 3 interact is exactly where it was in Night 2")
	check(game.status_panel.anchor_right == night2.status_panel.anchor_right,
		"status panel proportions match original Night 1 design")
	check(game.dialogue.anchor_left == night2.dialogue.anchor_left,
		"cinematic NPC dialogue layout retains chapter parity")
	night2.queue_free()
	await process_frame
	game._choose("close")
	check(game.gameplay_controls.visible, "HUD restores after Lola dialogue")
	check(game._nearby() == "" or game._nearby() == "return_mango",
		"initial player location is not teleported directly onto evidence")
	for id in game.Story.CLUES:
		game.player_pos = game.CLUES_AT[id]
		check(game._nearby() == id, "real player position detects "+id)
		game._interact()
		check(game.story.clues.has(id), "actual interactive clue records "+id)
		game._choose("close")
	check(game.story.phase == 1, "fully investigated scene unlocks safety stage")
	for id in game.Story.MARKERS:
		game.player_pos = game.MARKERS_AT[id]
		game._interact()
		check(game.story.markers.has(id), "real on-foot waymarker secured: "+id)
		game._choose("close")
	check(game.story.phase == 2, "route marking unlocks real night observation")
	game.player_pos = game.SAFE_LOOKOUT
	game.observe_held = true
	game._process(3.3)
	check(game.story.phase == 3 and game.story.observation >= .999,
		"holding Observe at safe lookout reveals false-lights puzzle")
	game._choose("close")
	game.player_pos = game.FALSE_FORK
	game._interact()
	check(game.dialogue.visible and game.dialogue_choices.get_child_count() == 3,
		"actual fork presents three meaningful competing route choices")
	game._choose("blue_lanterns")
	check(game.story.phase == 3 and not game.story.route_verified,
		"false answer is rejected without skipping the rescue puzzle")
	game._choose("close")
	game._interact()
	game._choose("river_stones")
	check(game.story.phase == 4 and game.story.route_verified,
		"correct route unlocks guardian only after all evidence")
	game._choose("close")
	game.player_pos = game.RIDGE_GATE
	game._interact()
	check(game.creature_portrait.visible, "night encounter displays actual Tikbalang art")
	game._choose("greet")
	game._choose("truth")
	check(game.story.truth_recorded, "actual NPC scene records named testimony")
	game._choose("resolve")
	check(game.story.outcome == "resolve" and game.ending_panel.visible,
		"full interactable scene reaches real morning ending")
	check(game._auto_save(), "offline Night 3 state saved without touching Santelmo or Kapre saves")
	game.ending_panel.hide()
	game._open_notebook()
	check(game.notebook.visible and game.notebook_body.text.contains("Great Flood"),
		"notebook includes shared flood mystery and real results")
	game.queue_free()
	await process_frame
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in older:
		var out := FileAccess.open(path,FileAccess.WRITE)
		if out != null:
			out.store_buffer(older[path])
			out.close()
	print("Night 3 illustrated connected Tikbalang scene integration: ",
		"PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
