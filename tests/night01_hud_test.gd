extends SceneTree
const GameScene = preload("res://scenes/main.tscn")
var errors := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if not value:
		errors += 1
		printerr("Night1 HUD integration: " + label)

func _run() -> void:
	var game = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	game._close_dialogue()
	game._open_notebook()
	check(game._is_reading_ui(), "notebook pauses walking")
	check(game.notebook_panel.get_node_or_null("NotebookScroll") != null, "notebook supports overflowing clues")
	check(game.notebook_panel.anchor_bottom > game.notebook_panel.anchor_top, "notebook scales vertically with viewport")
	game._set_button_axis("right", true)
	game._set_focus(true)
	game._open_settings()
	check(game._is_reading_ui(), "settings keeps gameplay input blocked")
	check(game.touch_axes == Vector2.ZERO and not game.focus_held, "opening modal releases held movement and Focus")
	check(not game.notebook_panel.visible, "only one readable modal")
	check(game.settings_panel.get_node_or_null("SettingsScroll") != null, "long settings menu is scrollable")
	game._close_settings()
	game._open_prep()
	check(game.prep_panel.get_node_or_null("PreparationScroll") != null, "inventory readable with larger fonts")
	game._close_prep()
	game._show_dialogue("A readable conversation with Lola Pasing.")
	check(game._is_reading_ui(), "dialogue blocks movement")
	game._close_dialogue()
	check(not game._is_reading_ui(), "closing overlays restores movement")
	game.preferences.text_scale = 1.4
	game._apply_preferences()
	check(game.dialogue_text.get_theme_font_size("font_size") >= 28, "large subtitle setting changes text")
	game.queue_free()
	print("Night 1 HUD usability checks: ", "PASS" if errors == 0 else str(errors) + " failures")
	quit(0 if errors == 0 else 1)
