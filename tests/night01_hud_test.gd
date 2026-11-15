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
	check(game.notebook_panel.get_node_or_null("NotebookLayout/NotebookScroll") != null, "notebook supports overflowing clues")
	check(game.notebook_panel.anchor_right - game.notebook_panel.anchor_left >= 0.75, "notebook occupies wide readable viewport area")
	check(game.notebook_panel.anchor_bottom - game.notebook_panel.anchor_top >= 0.85, "notebook fills most of the phone height")
	check(game.notebook_panel.get_node("NotebookLayout/CloseNotebook").get_parent() != game.notebook_panel.get_node("NotebookLayout/NotebookScroll"), "notebook close stays outside evidence scroll")
	check(game.modal_backdrop.visible and not game.gameplay_hud.visible, "notebook dims the scene and hides all gameplay HUD")
	check(not game.choice_buttons[0].is_visible_in_tree(), "story choice buttons do not overlap notebook")
	check(game.notebook_panel.anchor_bottom > game.notebook_panel.anchor_top, "notebook scales vertically with viewport")
	game._set_button_axis("right", true)
	game._set_focus(true)
	game._open_settings()
	check(game._is_reading_ui(), "settings keeps gameplay input blocked")
	check(game.touch_axes == Vector2.ZERO and not game.focus_held, "opening modal releases held movement and Focus")
	check(not game.notebook_panel.visible, "only one readable modal")
	check(game.settings_panel.get_node_or_null("SettingsLayout/SettingsScroll") != null, "long settings menu is scrollable")
	check(game.settings_panel.get_node_or_null("SettingsLayout/CloseSettings") != null, "settings close button remains fixed outside scrolling options")
	check(game.modal_backdrop.visible and not game.gameplay_hud.visible, "settings hides movement controls")
	game._close_settings()
	game._open_prep()
	check(game.prep_panel.get_node_or_null("PreparationLayout/PreparationScroll") != null, "inventory readable with larger fonts")
	check(game.prep_panel.get_node_or_null("PreparationLayout/ClosePreparation") != null, "preparation close remains visible independent of scroll")
	game._close_prep()
	game._show_dialogue("A readable conversation with Lola Pasing.")
	check(game._is_reading_ui(), "dialogue blocks movement")
	check(game.dialogue.get_node_or_null("DialogueLayout/DialogueScroll") != null, "long dialogue can scroll without clipping")
	check(game.dialogue.get_node_or_null("DialogueLayout/CloseDialogue") != null, "dialogue has a touch-accessible close button")
	check(not game.gameplay_hud.visible, "interact and movement buttons hidden behind dialogue")
	game._set_button_axis("right", true)
	var before: Vector3 = game.player.global_position
	game._physics_process(0.25)
	check(game.player.global_position.distance_to(before) < 0.06, "touch movement remains blocked even when pressed while dialogue open")
	game._close_dialogue()
	check(not game._is_reading_ui(), "closing overlays restores movement")
	check(game.gameplay_hud.visible and not game.modal_backdrop.visible, "closing modal restores the ordinary gameplay HUD")
	game.preferences.text_scale = 1.4
	game._apply_preferences()
	check(game.dialogue_text.get_theme_font_size("font_size") >= 28, "large subtitle setting changes text")
	game.queue_free()
	print("Night 1 HUD usability checks: ", "PASS" if errors == 0 else str(errors) + " failures")
	quit(0 if errors == 0 else 1)
