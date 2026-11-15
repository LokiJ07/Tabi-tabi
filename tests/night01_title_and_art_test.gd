extends SceneTree
## Title is a functional offline scene, not a marketing illustration.
const TitleScene = preload("res://scenes/title.tscn")
const GameScene = preload("res://scenes/main.tscn")
const Polish = preload("res://scripts/world/environment_polish.gd")
var failures := 0

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("Night 1 actual art / title: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var title = TitleScene.instantiate()
	root.add_child(title)
	await process_frame
	check(title.get_node_or_null("MainMenu") != null, "title has real tappable main menu")
	check(title.get_node_or_null("TitleWordmark") != null, "title wordmark in scene")
	for detail in ["MangroveAtDusk", "SchoolhouseAtDusk", "MarketAtDusk", "ApprenticeAtDusk", "BantayAtDusk"]:
		var art := title.get_node_or_null("IllustratedTitleScene/" + detail) as TextureRect
		check(art != null and art.texture != null, "main menu uses same imported game art: " + detail)
	check(title.get_node_or_null("LoadingScreen") != null, "scene has a blocking loading state")
	check(title.continue_button.disabled == not title._has_save(), "continue enabled only for existing save")
	title._open_settings()
	check(title.settings_backdrop.visible, "settings opens from title")
	var old_scale: float = title.prefs.text_scale
	title.prefs.next_text_scale()
	title._refresh_settings()
	check(title.font_button.text.contains("%d%%" % roundi(title.prefs.text_scale * 100.0)), "font setting changes title options label")
	title.prefs.text_scale = old_scale
	title.settings_backdrop.hide()
	title.queue_free()
	await process_frame

	var world := Node3D.new()
	root.add_child(world)
	var dressed: Node3D = Polish.decorate(world)
	check(dressed.get_node_or_null("Batched footpath stones") != null, "batched gravel appears on path")
	check(dressed.get_node_or_null("Batched tidal reeds") != null, "tidal reeds follow river margin")
	check(dressed.get_node_or_null("Batched village fallen leaves") != null, "foliage adds life around houses")
	var rocks := dressed.get_node("Batched footpath stones") as MultiMeshInstance3D
	check(rocks.multimesh.instance_count >= 80, "decorative stones are GPU-batched")
	check(Polish.decorate(world) == dressed, "visual polish safely reuses root")
	world.queue_free()
	var game = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	game._close_dialogue()
	game._refresh_choices()
	await process_frame
	check(game.get_node_or_null("BarrioLawomArtPolish") != null, "real gameplay scene contains art dressing")
	check(game.get_node_or_null("LolaHutInterior/Hut surrounding earth") != null, "interior no longer sits in empty sky")
	check(game.get_node_or_null("LolaHutInterior/Raised bamboo porch") != null, "real home gets walk-up context")
	check(game.choice_buttons[0].get_parent().name == "StoryActionsBar", "choices use responsive horizontal bar")
	if game.choice_buttons[0].visible and game.choice_buttons[1].visible:
		check(game.choice_buttons[0].get_global_rect().end.x <= game.choice_buttons[1].get_global_rect().position.x, "two opening responses do not overlap")
	game.preferences.text_scale = 1.4
	game._apply_preferences()
	await process_frame
	await process_frame
	check(game.status_panel.offset_bottom >= 145.0, "quest status reflows at large font")
	check(game.interact_hint.offset_bottom >= 89.0, "nearby hint has two-line room")
	game.queue_free()
	print("Night 1 actual art, title and accessibility checks: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
