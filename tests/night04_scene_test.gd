extends SceneTree
## Night 4 is an actual live playable chapter, not a still/mock screenshot.
const Scene = preload("res://scenes/night04.tscn")
const Story = preload("res://scripts/narrative/night04_state.gd")
const World = preload("res://scripts/core/connected_world.gd")
const Save = preload("res://scripts/core/night04_save.gd")
const SharedHUD = preload("res://scripts/ui/shared_hud.gd")
var errors := 0

func check(ok: bool,detail: String) -> void:
	if not ok:
		errors += 1
		printerr("Night4 playable wake: "+detail)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var paths := [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp",
		World.PATH,World.PATH+".bak",World.PATH+".tmp"]
	var old: Dictionary = {}
	for path in paths:
		if FileAccess.file_exists(path):
			old[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.name == "TabiTabiNight4","actual playable chapter scene")
	check(game.get_meta("dimensional_art","") == "shared-2.5d-layered-v1",
		"approved 2.5D art and character identity")
	check(game.camera is Camera2D and game.camera.enabled,"working mobile follow camera")
	check(game.objective != null and game.dialogue != null and game.notes != null,
		"objective/dialogue/notebook exist inside live gameplay")
	check(game.get_node_or_null("Night04WakeCamera") is Camera2D,"same camera follows moving Apprentice")
	check(game.controls.get_node_or_null("QuestStatusCard") is PanelContainer,
		"Night 4 uses the shared Night 1–3 status-card grammar")
	check(game.NENA.get_width() > 200 and game.MANANANGGAL.get_width() > 500,
		"original vector art for caretaker and winged entity actually imported")
	check(not game.story.target_verified and game.story.phase == 0,
		"start with dignity and physical evidence, not identifying a random mourner")
	# Regression from the Android capture: a roof-level creature was clipped
	# above the phone viewport when the apprentice stood in the safe courtyard.
	game.player_pos = game.SAFE_COURT
	game.camera.position = game.player_pos
	game.debug_wake_preview = true
	game._process(.7)
	check(game.camera.position.y < game.player_pos.y-300.0,
		"full-size rooftop silhouette fits in the vertical Android frame")
	check(game.camera.zoom.x <= .90 and game.camera.zoom.y <= .90,
		"encounter zooms out without moving the shared HUD")
	var roof_top := Vector2(270,-465)+Vector2(-5,110)-Vector2(150,247)
	var vertical_room := root.get_visible_rect().size.y*.5/game.camera.zoom.y
	check(roof_top.y > game.camera.position.y-vertical_room,
		"animated Manananggal's head and wings stay within screen height")
	game.debug_wake_preview = false
	game.player_pos = Story.START
	game.camera.position = game.player_pos
	if game.dialogue.visible:
		game._choose("close")
	check(game._nearby() != "deduce","cannot bypass clues on arrival")
	for id in Story.CLUES:
		game.player_pos = game.CLUE_POS[id]
		game._interact()
		check(game.story.clues.has(id),"physical clue collected by real INTERACT at "+id)
		if game.dialogue.visible:
			game._choose("close")
	check(game.story.phase == 1,"all four observations open private deduction")
	game.player_pos = game.SAFE_COURT
	game._interact()
	check(game.dialogue.visible,"deduction appears as a playable dialogue decision")
	game._choose("nena")
	check(game.story.phase == 2 and game.story.target_verified,
		"correctly protects Nena without identifying her as a monster")
	game._choose("close")
	for id in Story.DEFENSES:
		game.player_pos = game.DEFENSE_POS[id]
		game._interact()
		check(game.story.defenses.has(id),"interactive prepared defense "+id)
		if game.dialogue.visible:
			game._choose("close")
	game.player_pos = game.SAFE_COURT
	game._interact()
	check(game.story.phase == 3,"real protection phase begins after physical setup")
	if game.dialogue.visible:
		game._choose("close")
	for id in Story.CORRECT_ACTIONS:
		game.observe_held = true
		game._process(1.5)
		check(game.story.warning_ready,"the wingbeat warning requires player observation")
		check(game.dialogue.visible,"a visible dialog prompts coordinated defense")
		game._choose(id)
		check(not game.story.encounter_failed,"correct action protects mourners safely")
		if game.dialogue.visible:
			game._choose("close")
	check(game.story.phase == 4,"three approaches complete without enemy HP bars")
	game._choose("outcomes")
	game._choose("resolve")
	check(game.story.outcome == "resolve","complete wake has a fully authored aftermath")
	check(World.read()["outcomes"].get("night04","") == "resolve",
		"Night4 outcome saved in the same connected seven-night ledger")
	check(Save.exists(),"independent Night4 save exists after resolution")
	check(not game.dialogue.visible and game.ending.visible,"completed wake shows real aftermath panel")
	game.queue_free()
	await process_frame
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in old:
		var out := FileAccess.open(path,FileAccess.WRITE)
		if out != null:
			out.store_buffer(old[path])
			out.close()
	print("Playable Manananggal wake + shared 2.5D HUD: ",
		"PASS" if errors == 0 else str(errors)+" failures")
	quit(0 if errors == 0 else 1)
