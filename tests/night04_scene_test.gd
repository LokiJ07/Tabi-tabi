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
	# Visual parity gate: Night 4/5 must retain Night 1 slots, not just a shared color scheme.
	for slot in [
		["PrepareButton",-230.0,-444.0,180.0,56.0],
		["SaveButton",-230.0,-375.0,85.0,52.0],
		["RetryButton",-138.0,-375.0,88.0,52.0]
	]:
		var action_button := game.controls.get_node_or_null(str(slot[0])) as Button
		check(action_button != null,"shared HUD missing top action "+str(slot[0]))
		if action_button != null:
			check(is_equal_approx(action_button.offset_left,float(slot[1]))
				and is_equal_approx(action_button.offset_top,float(slot[2]))
				and is_equal_approx(action_button.offset_right-action_button.offset_left,float(slot[3]))
				and is_equal_approx(action_button.offset_bottom-action_button.offset_top,float(slot[4]))
				and action_button.anchor_left == 1.0 and action_button.anchor_top == 1.0
				and action_button.get_meta("hud_component","") == "night1-shared",
				"Night 1 physical touch slot changed: "+str(slot[0]))
	var look_pad := game.controls.get_node_or_null("SharedLookPad") as Control
	check(look_pad != null and is_equal_approx(look_pad.offset_left,-435.0)
		and is_equal_approx(look_pad.offset_right,-260.0)
		and is_equal_approx(look_pad.offset_top,-205.0)
		and is_equal_approx(look_pad.offset_bottom,-40.0),
		"LOOK touch region must match Nights 1–3")
	check(game.status_panel != null and game.status_stack != null,
		"shared status card must auto-resize to its content")
	if game.dialogue.visible:
		game._choose("close")
	game._open_preparation_briefing()
	check(game.dialogue.visible and game.dialogue_body.text.contains("PREPARATION"),
		"PREPARE button opens real chapter safety guidance")
	game._choose("close")
	game._retry_from_saved_checkpoint()
	check(game.dialogue.visible and game.dialogue_body.text.contains("last offline checkpoint"),
		"RETRY button asks for explicit confirmation before losing unsaved actions")
	game._choose("close")

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
	var expected_fit: Dictionary = game.ActorMotion.camera_fit(game.player_pos,
		Vector2(270,-335),root.get_visible_rect().size)
	check(game.ActorMotion.FULL_SIZE.y >= 310.0,
		"visibly larger winged creature while camera remains responsive")
	check(game.camera.zoom.x < .82 and game.camera.zoom.y < .82,
		"encounter zooms out to fit airborne wings and hero")
	check(game.camera.position.distance_to(expected_fit["center"]) < 5.0,
		"encounter camera centers the full monster-to-player vertical span")
	var visual_half_height: float = root.get_visible_rect().size.y * .5 / game.camera.zoom.y
	check(float(expected_fit["top"]) > game.camera.position.y - visual_half_height+45.0,
		"entire Manananggal stays below the screen top with safety margin")
	check(float(expected_fit["bottom"]) < game.camera.position.y + visual_half_height-45.0,
		"Bantay and hero remain inside the bottom screen boundary")
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
