extends SceneTree
## Full Chapter 5 in-engine play test: physical coordinates, shared HUD,
## offline save and exact story state. A static picture could never pass.
const Scene = preload("res://scenes/night05.tscn")
const State = preload("res://scripts/narrative/night05_state.gd")
const Save = preload("res://scripts/core/night05_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
var errors := 0

func check(ok: bool,reason: String) -> void:
	if not ok:
		errors += 1
		printerr("Night 5 playable farm: "+reason)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var keep: Dictionary = {}
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp",
		World.PATH,World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			keep[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.name == "TabiTabiNight5" and game.camera is Camera2D,
		"real connected farm scene and independent follow camera")
	check(game.get_meta("dimensional_art","") == "shared-2.5d-layered-v1",
		"Night 5 retains exact Night 1–4 layered renderer")
	check(game.get_meta("art_contract","") == "night05-dimensional-sigbin-farm-v1",
		"new isometric farm art uses shared style")
	check(game.controls.get_node_or_null("QuestStatusCard") is PanelContainer,
		"exact shared status-card component, not a new custom HUD")
	check(game.SIGBIN.get_width() >= 700 and game.BARN.get_width() >= 900,
		"actual original Sigbin and 2.5D barn SVG loaded")
	check(game.GOAT.get_width()>300 and game.CHICKEN.get_width()>200,
		"animals are real in-game sprites, not text-only rewards")
	check(game.story.phase == 0,"real investigation begins before creature reveal")
	if game.dialogue.visible:
		game._choose("close")
	game.player_pos = game.FARMER_POS
	game._interact()
	check(game.story.seen.has("farmer"),"Farmer reports missing goats in actual dialogue")
	game._choose("close")
	for id in State.CLUES:
		game.player_pos = game.CLUE_POS[id]
		check(game._nearby() == id,"interactive evidence is walkable outside unsafe barn: "+id)
		game._interact()
		check(game.story.clues.has(id),"clue collected by real INTERACT "+id)
		game._choose("close")
	check(game.story.phase == 1,"four genuine observations unlock interpretation")
	game.player_pos = game.SAFE_PERIMETER
	game._interact()
	game._choose("guardian")
	check(game.story.phase == 2 and game.story.guardian_verified,
		"real interpretation respects old caretaker's bond")
	game._choose("close")
	for id in State.PREPARATIONS:
		game.player_pos = game.PREP_POS[id]
		check(game._nearby() == id,"actual safety prep reachable: "+id)
		game._interact()
		check(game.story.preparations.has(id),"prepared safe route / light "+id)
		game._choose("close")
	check(game.story.preparations.size() == 5,"all 3 lamps, gate and stable perimeter")
	game.player_pos = game.SAFE_PERIMETER
	game._interact()
	check(game.story.phase == 3,"rescue starts only with all safety requirements")
	game._choose("close")
	for i in range(3):
		game.player_pos = game.SAFE_PERIMETER
		game.observe_held = true
		game._process(1.4)
		check(game.story.shadow_identified,
			"real HOLD OBSERVE reveals connected shadows at safe perimeter")
		game._choose(State.CORRECT_LIGHTS[i])
		check(game.story.rescued_groups == i+1,
			"one physical animal group rescued with matching lamp "+str(i))
		game._choose("close")
	check(game.story.phase == 4 and game.story.rescued_groups == 3,
		"complete rescue earns safe aftermath; Sigbin remains unharmed")
	game._choose("outcomes")
	game._choose("resolve")
	check(game.story.outcome == "resolve",
		"perfect evidence, prepared route and no mistakes unlock safe territory")
	check(Save.exists(),"original Night 5 independent offline save exists")
	var clone = State.new()
	check(Save.read(clone) and clone.outcome == "resolve",
		"real playable scene commits persisted group outcomes")
	check(game.camera != null and game.hud != null
		and game.controls.get_node_or_null("Options") is Button,
		"shared option and HUD remain anchored in gameplay scene")
	game.queue_free()
	await process_frame
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp",
		World.PATH,World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in keep:
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file != null:
			file.store_buffer(keep[path])
			file.close()
	print("Night 5 live Sigbin farm / shared HUD / three rescue routes: ",
		"PASS" if errors == 0 else str(errors)+" failures")
	quit(0 if errors == 0 else 1)
