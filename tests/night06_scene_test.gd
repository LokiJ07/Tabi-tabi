extends SceneTree
## Instantiate the real scene, test in-world targets and Night 1 HUD parity.
const Scene = preload("res://scenes/night06.tscn")
const Story = preload("res://scripts/narrative/night06_state.gd")
const Save = preload("res://scripts/core/night06_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
var errors := 0
func check(value: bool,why: String) -> void:
	if not value:
		errors += 1
		printerr("Night 6 playable river: "+why)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var backups: Dictionary = {}
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp",
		World.PATH,World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			backups[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.name == "TabiTabiNight6" and game.camera is Camera2D,
		"real Godot chapter scene follows apprentice")
	check(game.get_meta("dimensional_art","") == "shared-2.5d-layered-v1",
		"same authored 2.5D material grammar")
	check(game.controls.get_node_or_null("QuestStatusCard") is PanelContainer,
		"Night 1 shared mobile status component")
	check(game.objective != null and game.dialogue != null and game.notes != null,
		"real interactable quest, dialogue and evidence notebook")
	for name in ["PrepareButton","SaveButton","RetryButton","Options","SharedLookPad"]:
		check(game.controls.get_node_or_null(name) != null,
			"Night 1 HUD action must exist: "+name)
	# Strict Night 1 thumb-control parity: same screen corners and touch rectangles.
	for slot in [
		["PrepareButton",-230.0,-444.0,180.0,56.0],
		["SaveButton",-230.0,-375.0,85.0,52.0],
		["RetryButton",-138.0,-375.0,88.0,52.0]
	]:
		var button := game.controls.get_node_or_null(str(slot[0])) as Button
		check(button != null,"Night 1 fixed control is present: "+str(slot[0]))
		if button != null:
			check(is_equal_approx(button.offset_left,float(slot[1]))
				and is_equal_approx(button.offset_top,float(slot[2]))
				and button.offset_right-button.offset_left >= float(slot[3])
				and button.offset_right-button.offset_left <= float(slot[3])+36.0
				and button.offset_bottom-button.offset_top >= float(slot[4])
				and button.offset_bottom-button.offset_top <= float(slot[4])+16.0
				and button.anchor_left == 1.0 and button.anchor_top == 1.0
				and button.get_meta("hud_component","") == "night1-shared",
				"HUD placement or factory deviates from approved Night 1 "+str(slot[0]))
	var look = game.controls.get_node_or_null("SharedLookPad") as Control
	check(look != null and is_equal_approx(look.offset_left,-435.0) and
		is_equal_approx(look.offset_right,-260.0) and
		is_equal_approx(look.offset_top,-205.0) and
		is_equal_approx(look.offset_bottom,-40.0),
		"Night 6 LOOK touch area exactly matches Nights 1–5")
	check(World.implemented("night06") and World.implemented("night07"),
		"real River scene implemented but Balete remains locked")
	check(is_equal_approx(game._flood_rise(),2.0),
		"river starts high but substantially below the midnight surge")
	game.story.phase = 2
	check(is_equal_approx(game._flood_rise(),8.0),"evidence reconstruction reveals rising water")
	game.story.phase = 6
	check(is_equal_approx(game._flood_rise(),23.0),"river rises without rain by the encounter")
	game.story.phase = 7
	check(is_equal_approx(game._flood_rise(),5.0),"river calms after the third challenge")
	game.qa_river_preview = true
	check(is_equal_approx(game._flood_rise(),23.0),"Android night preview reflects actual high water")
	game.qa_river_preview = false
	game.story.phase = 0
	game.player_pos = game.CLUE_POS["rescue_order"]
	check(game._nearest_evidence() == game.CLUE_POS["rescue_order"],
		"only nearest documented source should reveal a full plaque")
	check(game._safe_corridor(game.STEPS[0]) and
		not game._safe_corridor(Vector2(-700,620)),
		"three visible stones are safe, unmarked floodwater is not")
	if game.dialogue.visible: game._choice("close")
	check(game.story.phase == 0,"actual playable chapter starts from source investigation")
	for id in Story.CLUES:
		game.player_pos = game.CLUE_POS[id]
		game._interact()
		check(game.story.clues.has(id),"live INTERACT collects physical evidence "+id)
		if game.dialogue.visible: game._choice("close")
	check(game.story.phase == 1,"four physical clues unlock first reconstruction")
	game.player_pos = game.TABLE
	game._interact()
	check(game.dialogue.visible,"first reconstruction uses actual source-backed dialogue")
	game._choice("cancel_false")
	check(game.story.phase == 1,"bad hypothesis does not destroy trust or skip truth")
	game._choice("close")
	game._interact()
	game._choice("cancel_true")
	check(game.story.phase == 2,"official cancellation evidence established")
	game._choice("close")
	for id in Story.ROUTE:
		game.player_pos = game.ROUTE_POS[id]
		game._interact()
		check(game.story.route_index > Story.ROUTE.find(id),"physical route model progressed")
		if game.dialogue.visible: game._choice("close")
	check(game.story.phase == 3,"second historical reconstruction complete")
	for id in Story.IDENTITY:
		game.player_pos = game.IDENTITY_POS[id]
		game._interact()
		check(game.story.identity_sources.has(id),"independent rescue source accessible "+id)
		if game.dialogue.visible: game._choice("close")
	game.player_pos = game.TABLE
	game._interact()
	game._choice("identity_true")
	check(game.story.phase == 4,"confirmed rescuer revealed only after both sources")
	game._choice("close")
	game.player_pos = game.SABEL_AT
	game._interact()
	check(game.dialogue.visible and game.dialogue_speaker.text.contains("SABEL"),
		"Sabel's revelation is private and consent based")
	game._choice("sabel_private")
	game._choice("close")
	game.player_pos = game.LOLA_AT
	game._interact()
	game._choice("lola_truth")
	game._choice("close")
	game.player_pos = game.TABLE
	game._interact()
	game._choice("close")
	check(game.story.phase == 5,"Lola's evidence and Sabel's choice unlock river safety preparation")
	for id in Story.PREPARATIONS:
		game.player_pos = game.PREP_POS[id]
		game._interact()
		check(game.story.preparations.has(id),"real safety equipment prepared "+id)
		game._choice("close")
	game.player_pos = game.PREP_POS["lantern_beacon"]
	game._interact()
	game._choice("close")
	check(game.story.phase == 6,"full in-world crossing begins after preparations")
	for id in Story.RIVER_ACTIONS:
		game.player_pos = game.STEPS[game.story.step_index]
		check(game.story.observe_tick(1.2,true,true),"real safe-stone watch becomes ready")
		game._show_current_choices()
		check(game.dialogue.visible,"each water surge has an authored decision")
		game._choice(id)
		if game.dialogue.visible: game._choice("close")
	check(game.story.phase == 7,"all three physical surge responses completed")
	game._choice("outcomes")
	game._choice("resolve")
	check(game.story.outcome == "resolve" and game.ending.visible,
		"real scene reaches river dawn and saved outcome")
	check(Save.exists(),"offline Night 6 save produced in live scene")
	check(World.read()["outcomes"].get("night06","") == "resolve",
		"same-world narrative ledger stores Night 6 without overwriting other chapters")
	game.queue_free()
	await process_frame
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp",
		World.PATH,World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in backups:
		var stream := FileAccess.open(path,FileAccess.WRITE)
		if stream != null:
			stream.store_buffer(backups[path])
			stream.close()
	print("Night 6 real 2.5D river, continuous storyline and matching HUD: ",
		"PASS" if errors == 0 else str(errors)+" failures")
	quit(0 if errors == 0 else 1)
