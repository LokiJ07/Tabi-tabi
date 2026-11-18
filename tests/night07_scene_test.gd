extends SceneTree
## Physical Night 7 scene, real HUD, clue interactions, trial, and free-roam gate.
const Scene = preload("res://scenes/night07.tscn")
const Story = preload("res://scripts/narrative/night07_state.gd")
const Save = preload("res://scripts/core/night07_save.gd")
const RiverSave = preload("res://scripts/core/night06_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
var failures := 0

func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		printerr("Night 7 Balete gameplay: " + why)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var backups: Dictionary = {}
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp",
		RiverSave.PATH,RiverSave.PATH+".bak",RiverSave.PATH+".tmp",
		World.PATH,World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			backups[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var outcomes: Dictionary = {}
	for night in range(1,7):
		outcomes["night%02d" % night] = "resolve"
	var ledger := World.read()
	ledger["outcomes"] = outcomes
	check(World.write(ledger),"six prior chapter results prepared for genuine final unlock")
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.name == "TabiTabiNight7" and game.camera is Camera2D,
		"actual loaded gameplay scene follows apprentice on continuous Balete road")
	check(game.get_meta("dimensional_art","") == "shared-2.5d-layered-v1",
		"Night 7 uses same 2.5D relief grammar as earlier nights")
	check(World.implemented("night07") and World.adjacent("night06","night07"),
		"Night 7 is real connected geography, not a menu concept")
	check(game.controls.get_node_or_null("QuestStatusCard") != null,
		"shared status HUD reused from Night 1")
	for name in ["PrepareButton","SaveButton","RetryButton","Options","SharedLookPad"]:
		check(game.controls.get_node_or_null(name) != null,"shared original HUD "+name)
	for slot in [
		["PrepareButton",-230.0,-444.0,180.0,56.0],
		["SaveButton",-230.0,-375.0,85.0,52.0],
		["RetryButton",-138.0,-375.0,88.0,52.0]
	]:
		var b := game.controls.get_node_or_null(str(slot[0])) as Button
		check(b != null,"original fixed action slot exists")
		if b != null:
			check(is_equal_approx(b.offset_left,float(slot[1]))
				and is_equal_approx(b.offset_top,float(slot[2]))
				and b.anchor_left == 1.0 and b.anchor_top == 1.0
				and b.offset_right-b.offset_left >= float(slot[3])
				and b.offset_bottom-b.offset_top >= float(slot[4])
				and b.get_meta("hud_component","") == "night1-shared",
				"approved Night 1 touch rect unchanged for "+str(slot[0]))
	var look := game.controls.get_node_or_null("SharedLookPad") as Control
	check(look != null and look.offset_left == -435.0 and
		look.offset_right == -260.0 and look.offset_top == -205.0
		and look.offset_bottom == -40.0,"right thumb look pad exactly matches previous chapters")
	check(game._stage() == 1,"arrival is authored dusk, not postgame auto time")
	check(not World.is_postgame(),"mere arrival cannot enable free-roam clock")
	if game.dialogue.visible: game._choice("close")
	game.story.river_outcome = "resolve"
	game.story.lola_truth_known = true
	game.story.sabel_consent = "private"
	game.story.dado_consent = "private"
	for id in Story.CLUES:
		game.player_pos = game.CLUE_POS[id]
		game._interact()
		check(game.story.clues.has(id),"interact with authored clue "+id)
		if game.dialogue.visible: game._choice("close")
	check(game.story.phase == 1,"four evidence stations open reconstruction")
	game.player_pos = game.VERDICT
	game._interact()
	check(game.dialogue.visible,"evidence deduction appears in dialogue")
	game._choice("deduce_false")
	check(game.story.phase == 1,"wrong attribution to spirit cannot bypass facts")
	game._choice("close")
	game._interact()
	game._choice("deduce_true")
	check(game.story.phase == 2,"evidence-led deduction unlocks community actions")
	game._choice("close")
	for id in Story.PREPARATIONS:
		game.player_pos = game.PREP_POS[id]
		game._interact()
		check(game.story.preparations.has(id),"in-world safety and witness preparation "+id)
		if game.dialogue.visible: game._choice("close")
	game.player_pos = game.VERDICT
	game._interact()
	game._choice("prepare_public")
	check(game.story.phase == 2,"Sabel family privacy cannot be overridden")
	game._choice("close")
	game._interact()
	game._choice("prepare_private")
	check(game.story.phase == 3,"actual trial begins after safety/consent actions")
	game._choice("close")
	for id in Story.TRIAL:
		game.player_pos = game.TRIAL_POS[game.story.trial_index]
		check(game.story.observe_tick(1.45,true,true),"HOLD OBSERVE at real stone")
		game._trial_choices()
		check(game.dialogue.visible,"in-world Ancient Keeper response choices visible")
		game._choice(id)
		if game.dialogue.visible: game._choice("close")
	check(game.story.phase == 4,"three guardian stones unlock verdict")
	game.player_pos = game.VERDICT
	game._interact()
	game._choice("ending_renewal")
	check(game.story.phase == 5 and game.story.outcome == "renewal",
		"real final verdict commits only after trial")
	check(not World.is_postgame(),"trial verdict alone must not activate live clock")
	check(game.ending.visible,"cinematic final epilogue card rendered")
	game._choice("complete_epilogue")
	check(game.story.epilogue_complete and game.story.phase == 6,
		"explicit playable epilogue unlocks continued exploration")
	check(World.is_postgame(),"all seven saved results and epilogue marker enable free roam")
	var autoload := root.get_node_or_null("PostgameClock")
	check(autoload != null and autoload.is_active(),"autoloaded 24-minute world clock starts")
	check(game._stage() == autoload.light_stage(),"Balete and all maps consume the same clock")
	check(World.begin_travel("night07","night06",""),"player may revisit river after ending")
	check(World.consume_arrival("night06").get("from") == "night07","Balete return keeps real path continuity")
	var saved = Story.new()
	check(Save.read(saved) and saved.epilogue_complete,"restarting does not erase final outcome")
	game.queue_free()
	await process_frame
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp",
		RiverSave.PATH,RiverSave.PATH+".bak",RiverSave.PATH+".tmp",
		World.PATH,World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in backups:
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file != null:
			file.store_buffer(backups[path])
			file.close()
	if autoload != null:
		autoload.refresh()
	print("Night 7 real trial and epilogue gameplay: ","PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
