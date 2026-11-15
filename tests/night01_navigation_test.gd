extends SceneTree
## Night 1 navigation is functional and save-safe, not just painted controls.
const GameScene = preload("res://scenes/main.tscn")
const SaveService = preload("res://scripts/core/save_service.gd")
var failures := 0

func check(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		printerr("Night 1 navigation: " + reason)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = GameScene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(game.settings_panel.get_node_or_null("SettingsLayout/SaveAndMainMenu") != null, "Save & Main Menu is a fixed, real gameplay button")
	check(game.settings_panel.get_node_or_null("SettingsLayout/QuitGame") != null, "Quit Game is a fixed, real gameplay button")
	check(game.main_menu_confirmation != null and game.quit_game_confirmation != null, "both routes have confirmation")
	check(game.navigation_error_dialog != null, "save failures block navigation instead of losing progress")
	game._close_dialogue()
	game._open_settings()
	check(game.settings_panel.visible, "options visible after tapping gameplay settings")
	game.save_main_menu_button.pressed.emit()
	check(game.main_menu_confirmation.visible, "save and menu asks for explicit confirmation")
	check(current_scene == game, "pressing Save & Main Menu does not immediately leave game")
	game.main_menu_confirmation.hide()
	game.quit_game_button.pressed.emit()
	check(game.quit_game_confirmation.visible, "Quit asks for explicit confirmation")
	check(current_scene == game, "pressing Quit does not immediately terminate")
	game.quit_game_confirmation.hide()
	game.story.observe_clue("navigation_test_marker")
	check(game._save_before_navigation(), "game state saved successfully before navigation")
	var record: Dictionary = SaveService.read(game.story)
	check(not record.is_empty(), "written save file can be read back")
	# This checks real scene switching, not just UI text or a signal connection.
	game._save_and_return_to_menu()
	await process_frame
	await process_frame
	check(current_scene != null and current_scene.name == "TitleScreen", "Save & Main Menu returns to real landing page")
	if current_scene != null and current_scene.name == "TitleScreen":
		check(not current_scene.continue_button.disabled, "Continue available after returning with a save")
	print("Night 1 save, quit confirmation and menu navigation: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
