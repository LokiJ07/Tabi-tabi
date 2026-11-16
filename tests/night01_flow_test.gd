extends SceneTree
## Full Night 1 wiring smoke: scene -> witnesses -> notebook -> night -> outcome -> save.
## This supplements, but cannot replace, physical Android playtesting.

const Scene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/narrative/night01_state.gd")
const Save = preload("res://scripts/core/save_service.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func assert_true(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("Night 1 integration: " + message)

func _wipe_test_save() -> void:
	for path in [Save.PATH, Save.PATH + ".bak", Save.PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _meet(game: Variant, id: String) -> void:
	var actor := game.interaction_nodes[id] as Node3D
	game.player.global_position = actor.global_position + Vector3(0, 0.65, 0)
	game._interact()
	game._close_dialogue()

func _setup_prologue(game: Variant) -> void:
	assert_true(game.in_lola_hut, "fresh new game begins in Lola hut")
	game._close_dialogue()
	_meet(game, "BLUE_NOTEBOOK")
	_meet(game, "WARM_CUP")
	assert_true(game.story.prologue_ready(), "notebook and breakfast unlocked")
	_meet(game, "HUT_EXIT")
	assert_true(not game.in_lola_hut, "door returns safely to village")


func _setup_evidence(game: Variant) -> void:
	_meet(game, "LOLA")
	_meet(game, "DADO")
	_meet(game, "MOORING")
	_meet(game, "MARA")
	game._open_notebook()
	game._link_clues("light_mooring")
	game._link_clues("ledger_mooring")
	game._close_notebook()
	assert_true(game.story.can_begin(), "all three witnesses and both links unlock night")

func _run_one(result: String) -> void:
	_wipe_test_save()
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	_setup_prologue(game)
	_setup_evidence(game)
	game._toggle_night()
	assert_true(game.is_night, "night starts with valid four-slot equipment")
	game._choose_story_action(0)
	assert_true(game.story.phase == 1, "first encounter phase")
	game._close_dialogue()
	if result != "partial":
		game._choose_story_action(0)
		assert_true(game.story.phase == 2, "calm observation reveals puzzle")
		game._close_dialogue()
		game.player.global_position = Vector3(-8.0, 0.75, 15.5)
		game._choose_story_action(0)
		assert_true(game.story.phase == 3, "near the correct river reflection advances")
		game._close_dialogue()
		if result == "resolve":
			game.player.global_position = Vector3(-7.0, 0.75, 12.0)
			var toward_shore: Vector3 = game.SantelmoActor.SAFE_LANDING - game.player.global_position
			toward_shore.y = 0.0
			game.lamp_heading = toward_shore.normalized()
			game.focus_held = true
			game._advance_safe_guiding(3.3)
			game._set_focus(false)
			game._advance_safe_guiding(1.25)
			assert_true(game.story.can_remember(), "released Focus still allows REMEMBER action")
			assert_true(game.choice_buttons[0].text == "REMEMBER", "button label matches actual ready outcome")
		game._choose_story_action(0 if result == "resolve" else 1)
	else:
		game._choose_story_action(2)
	assert_true(game.story.outcome == result, "selected outcome committed once: " + result)
	assert_true(game.get_node_or_null("Night01MorningAftermath") != null, "outcome visible in the world")
	assert_true(game.story.committed_events.size() == 1, "single canonical event")
	assert_true(game.story.bestiary.size() == 1, "single canonical bestiary record")
	var loaded = State.new()
	var read: Dictionary = Save.read(loaded)
	assert_true(not read.is_empty(), "offline save reloads")
	assert_true(loaded.outcome == result, "reloaded outcome matches current game")
	assert_true(loaded.committed_events.size() == 1, "no duplicate outcome after reload")
	assert_true(loaded.bestiary.size() == 1 and loaded.bestiary.has("santelmo"), "bestiary preserved exactly once")
	game.queue_free()
	await process_frame

func _run() -> void:
	# Run each complete outcome in its own process on CI. Godot's headless
	# dummy renderer can exhaust native mesh resources after repeatedly
	# constructing the entire 3D Barrio in one process. The default CLI
	# behavior still runs all three outcomes for local/regression use.
	var scenarios: Array[String] = ["resolve", "drive_away", "partial"]
	var requested: PackedStringArray = OS.get_cmdline_user_args()
	if not requested.is_empty():
		var chosen := requested[0]
		if not scenarios.has(chosen):
			printerr("Unknown Night 1 full-flow scenario: ", chosen)
			quit(2)
			return
		scenarios = [chosen]
	for scenario in scenarios:
		await _run_one(scenario)
	_wipe_test_save()
	print("Full Night 1 scene flow (%s): " % ",".join(scenarios),
		"PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
