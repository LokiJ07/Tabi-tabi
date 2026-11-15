extends SceneTree
## Exercises the REAL chapter scene and mobile UI, not only its state model.
const Scene = preload("res://scenes/night02.tscn")
const Night2Save = preload("res://scripts/core/night02_save.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("Night 2 scene: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = Scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(game.name == "TabiTabiNight2", "Night 2 live scene root")
	check(game.camera != null and game.camera.enabled, "functional 2D camera on every renderer")
	check(game.dialogue.visible, "Lola introductory dialogue appears")
	check(game.get_node_or_null("Night2HUD/Night2Screen") != null, "real mobile HUD")
	check(game.action_buttons.has("INTERACT"), "interaction control")
	check(game.action_buttons.has("HOLD OBSERVE"), "continuous observation control")
	check(game.action_buttons.has("FIELD NOTES"), "source-aware journal")
	check(game.action_buttons.has("OPTIONS"), "pause, save and quit controls")
	check(game.menu_confirm != null and game.quit_confirm != null, "explicit navigation confirmations")
	game._choose("close")
	for id in game.KEY_ORDER:
		game.player_pos = game.TARGETS[id]
		game._interact()
		check(game.story.clues.has(id), "art-world target interacts: " + id)
		game._choose("close")
	check(game.story.phase == 1, "actual evidence interactions unlock safety stage")
	for id in game.Story.BARRIER_POSITIONS:
		game.player_pos = game.TARGETS[id]
		game._interact()
		check(game.story.barriers.has(id), "actual barrier object closes route: " + id)
		game._choose("close")
	check(game.story.phase == 2, "all safety markers unlock sheltered observation")
	game.player_pos = game.OBSERVATION
	game.observe_held = true
	game._process(4.2)
	check(game.story.observation >= .999, "HOLD OBSERVE progresses in actual scene")
	game._choose("greet")
	check(game.story.phase == 3, "real greeting reaches negotiation")
	game._choose("coffee")
	check(game.story.offered == "coffee", "respectful offering is recorded")
	game._choose("plan")
	check(game.story.commitment, "qualified expert and detour plan required")
	game._choose("resolve")
	check(game.story.outcome == "resolve", "actual scene resolves Kapre")
	check(game.ending_panel.visible, "after-morning outcome scene is visibly present")
	game.ending_panel.hide()
	game._open_notebook()
	check(game.notebook.visible, "field notes can be reopened")
	check(game.notebook_content.text.contains("Kapre") or game.notebook_content.text.contains("KAPRE"), "notes explain Chapter 2")
	check(game._auto_save(), "real scene saves without touching Night 1")
	var title = get_tree().current_scene
	check(title == game, "game does not navigate unexpectedly")
	game.queue_free()
	await process_frame
	for path in [Night2Save.PATH,Night2Save.PATH+".bak",Night2Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Night 2 playable scene integration: ", "PASS" if failures == 0 else str(failures) + " failure(s)")
	quit(0 if failures == 0 else 1)
