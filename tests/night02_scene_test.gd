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
	check(game._light_stage() == 0, "daytime investigation starts with natural daylight")
	check(not game._kapre_revealed(), "Kapre body is NEVER visible in daylight")
	check(game.debug_dusk_preview == false and game.debug_night_reveal == false,
		"QA lighting previews are never set by ordinary gameplay")
	check(game.get_node_or_null("Night2HUD/Night2Screen") != null, "real mobile HUD")
	check(game.atmosphere_fx != null, "Night 2 shares the identical sensory effects renderer")
	if game.atmosphere_fx != null:
		check(game.atmosphere_fx.mouse_filter == Control.MOUSE_FILTER_IGNORE, "fog and darkness cannot block touchscreen")
		game.atmosphere_fx.configure(2,2,.75,true)
		check(is_equal_approx(game.atmosphere_fx.tension,.75) and game.atmosphere_fx.reduced_motion, "shared sensory FX accepts Night 2 story pressure")
	var n2_status := game.get_node_or_null("Night2HUD/Night2Screen/GameplayControls/ObjectiveCard") as PanelContainer
	check(n2_status != null and is_equal_approx(n2_status.anchor_right,.37), "Night 2 uses same compact status card as Night 1")
	check(game.KAPRE.get_width() >= 256 and game.KAPRE.resource_path.ends_with("kapre_perched.svg"), "nighttime encounter uses seated Kapre illustration")
	check(game.action_buttons.has("INTERACT"), "interaction control")
	check(game.action_buttons.has("HOLD OBSERVE"), "continuous observation control")
	check(game.action_buttons.has("FIELD NOTES"), "source-aware journal")
	check(game.action_buttons.has("OPTIONS"), "pause, save and quit controls")
	var move_up := game.get_node_or_null("Night2HUD/Night2Screen/GameplayControls/Move_up") as Button
	check(move_up != null, "shared bottom-left movement UI")
	if move_up != null:
		check(is_equal_approx(move_up.anchor_left, 0.0) and is_equal_approx(move_up.offset_left, 95.0), "Night 2 arrow exactly matches Night 1 thumb position")
	var act := game.action_buttons.get("INTERACT") as Button
	check(act != null and act.get_meta("shared_hud_version", 0) == 1, "interact uses common chapter HUD theme")
	if act != null:
		check(is_equal_approx(act.offset_left, -230.0) and is_equal_approx(act.offset_top, -155.0), "Night 2 interact matches Night 1 lower-right anchor")
	game._sync_gameplay_hud()
	check(not game.gameplay_controls.visible, "modal dialogue hides movement and actions")
	check(game.menu_confirm != null and game.quit_confirm != null, "explicit navigation confirmations")
	game._choose("close")
	game._sync_gameplay_hud()
	check(game.gameplay_controls.visible, "closing dialogue restores shared HUD")
	# Dialogue never damages courage while user reads at an unsafe location.
	game.player_pos = game.TREE+Vector2(-75,0)
	game._show_dialogue("NARRATOR","Reading must pause environmental tension.",[{"label":"OK","action":"close"}])
	var before_courage: float = game.story.courage
	game._process(8.0)
	check(is_equal_approx(game.story.courage,before_courage), "dialogue pauses all tree hazard pressure")
	game._choose("close")
	game.player_pos = Vector2(-510,140)
	for id in game.KEY_ORDER:
		game.player_pos = game.TARGETS[id]
		game._interact()
		check(game.story.clues.has(id), "art-world target interacts: " + id)
		game._choose("close")
	check(game.story.phase == 1, "actual evidence interactions unlock safety stage")
	check(game._light_stage() == 1 and not game._kapre_revealed(),
		"dusk safety stage preserves hidden resident")
	for id in game.Story.BARRIER_POSITIONS:
		game.player_pos = game.TARGETS[id]
		game._interact()
		check(game.story.barriers.has(id), "actual barrier object closes route: " + id)
		game._choose("close")
	check(game.story.phase == 2, "all safety markers unlock sheltered observation")
	check(game._light_stage() == 2 and not game._kapre_revealed(),
		"nighttime ember and smoke precede full Kapre body reveal")
	game.player_pos = game.OBSERVATION
	game.observe_held = true
	game._process(4.2)
	check(game.story.observation >= .999, "HOLD OBSERVE progresses in actual scene")
	game._choose("greet")
	check(game.story.phase == 3, "real greeting reaches negotiation")
	check(game._light_stage() == 3 and game._kapre_revealed(),
		"Kapre appears ONLY at night after observation and respectful greeting")
	game._choose("coffee")
	check(game.story.offered == "coffee", "respectful offering is recorded")
	game._choose("plan")
	check(game.story.commitment, "qualified expert and detour plan required")
	game._choose("resolve")
	check(game.story.outcome == "resolve", "actual scene resolves Kapre")
	check(game._light_stage() == 0 and not game._kapre_revealed(),
		"morning aftermath hides Kapre again without rewriting story save")
	check(game.ending_panel.visible, "after-morning outcome scene is visibly present")
	game.ending_panel.hide()
	game._open_notebook()
	check(game.notebook.visible, "field notes can be reopened")
	check(game.notebook_content.text.contains("Kapre") or game.notebook_content.text.contains("KAPRE"), "notes explain Chapter 2")
	check(game._auto_save(), "real scene saves without touching Night 1")
	var title = current_scene
	check(title == game, "game does not navigate unexpectedly")
	game.queue_free()
	await process_frame
	for path in [Night2Save.PATH,Night2Save.PATH+".bak",Night2Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Night 2 playable scene integration: ", "PASS" if failures == 0 else str(failures) + " failure(s)")
	quit(0 if failures == 0 else 1)
