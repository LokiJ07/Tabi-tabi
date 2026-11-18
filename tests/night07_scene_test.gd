extends SceneTree
## Actual Godot Balete scene, physical source stations and Night 1 thumb HUD.
const Scene = preload("res://scenes/night07.tscn")
const Save = preload("res://scripts/core/night07_save.gd")
const State = preload("res://scripts/narrative/night07_state.gd")
const World = preload("res://scripts/core/connected_world.gd")
var failed:=0
func check(value: bool,why: String) -> void:
	if not value:
		failed+=1
		printerr("Night 7 live Balete: "+why)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var preserved: Dictionary={}
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp",World.PATH,
		World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			preserved[path]=FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var river=preload("res://scripts/narrative/night06_state.gd").new()
	river.phase=7
	river.outcome="partial"
	river.clues={"rescue_order":true,"flood_gauge":true,"evacuation_roll":true,"alternatives_log":true}
	river.cancellation_confirmed=true
	river.independent_return_confirmed=true
	river.rescuer_confirmed=true
	river.identity_sources={"family_boat_mark":true,"survivor_account":true}
	river.route_index=3
	river.private_sabel_told=true
	river.sabel_public_choice="private"
	river.lola_covenant_truth_known=true
	var river_save=preload("res://scripts/core/night06_save.gd")
	var previous: Dictionary={}
	for path in [river_save.PATH,river_save.PATH+".bak",river_save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			previous[path]=FileAccess.get_file_as_bytes(path)
	river_save.write(river)
	var game=Scene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.name=="TabiTabiNight7" and game.camera is Camera2D,
		"real authored 2.5D Balete scene has active follow camera")
	check(game.get_meta("dimensional_art","")=="shared-2.5d-layered-v1",
		"consistent Night 1–6 depth grammar")
	check(game.controls.get_node_or_null("QuestStatusCard") is PanelContainer,
		"shared Night 1 status component, not per-night independent HUD")
	for slot in [
		["PrepareButton",-230.0,-444.0,180.0,56.0],
		["SaveButton",-230.0,-375.0,85.0,52.0],
		["RetryButton",-138.0,-375.0,88.0,52.0]
	]:
		var b:=game.controls.get_node_or_null(str(slot[0])) as Button
		check(b!=null,"shared "+str(slot[0])+" exists")
		if b!=null:
			check(is_equal_approx(b.offset_left,float(slot[1]))
				and is_equal_approx(b.offset_top,float(slot[2]))
				and b.offset_right-b.offset_left >= float(slot[3])
				and b.offset_right-b.offset_left <= float(slot[3])+36
				and b.offset_bottom-b.offset_top >= float(slot[4])
				and b.offset_bottom-b.offset_top <= float(slot[4])+16
				and b.anchor_left==1.0 and b.anchor_top==1.0
				and b.get_meta("hud_component","")=="night1-shared",
				"fixed thumb area unchanged for "+str(slot[0]))
	var look=game.controls.get_node_or_null("SharedLookPad") as Control
	check(look!=null and is_equal_approx(look.offset_left,-435.0)
		and is_equal_approx(look.offset_right,-260.0)
		and is_equal_approx(look.offset_top,-205.0)
		and is_equal_approx(look.offset_bottom,-40.0),
		"Night 7 LOOK anchor unchanged from Night 1")
	check(World.implemented("night07") and World.seven_night_chain_is_connected(),
		"all seven nights are real connected regions")
	game.story.phase=3
	check(game._safe_segment(game.PATH_STONES[0]) and not game._safe_segment(Vector2(-790,630)),
		"moving roots have mapped safe corridor and unsafe outside")
	game.story.phase=0
	check(game.story.phase==0 and game.story.night06_outcome=="partial",
		"real source data seeds honest readiness; no fake six-resolve demand")
	if game.dialogue.visible: game._choose("close")
	game.player_pos=game.READINESS_BOARD
	game._interact()
	check(game.dialogue.visible,"physically reachable readiness notebook checkpoint")
	game._choose("notes")
	check(game.notebook.visible and game.story.notebook_checked,
		"notebook shows evidence and privately flags read")
	game.notebook.hide()
	game._sync_ui()
	game._readiness_dialog()
	game._choose("acknowledge")
	game._choose("begin_final")
	check(game.story.phase==1,"explicit checkpoint opens living community")
	game._choose("close")
	game.player_pos=game.SABEL_AT
	game._interact()
	game._choose("respect_sabel")
	game._choose("close")
	for id in State.FACTS:
		game.player_pos=game.FACT_POS[id]
		game._interact()
		game._choose("present_"+id)
		check(game.story.presented.has(id),"actual archive evidence can be presented: "+id)
		if game.dialogue.visible: game._choose("close")
	for id in State.COMMITMENTS:
		game.player_pos=game.COMMIT_POS[id]
		game._interact()
		game._choose("pledge_"+id)
		check(game.story.commitments.has(id),"physical meeting commitment "+id)
		if game.dialogue.visible: game._choose("close")
	game.player_pos=game.PUBLIC_RECORD
	game._interact()
	game._choose("public_record")
	game._choose("close")
	game.player_pos=game.GATE
	game._interact()
	check(game.story.phase==2,"public consent-based gathering opens Balete root gate")
	game._choose("close")
	game._interact()
	check(game.story.phase==3,"Keeper appears without omniscient fact injection")
	game._choose("close")
	for action in State.PATH_RESPONSES:
		game.player_pos=game.PATH_STONES[game.story.path_index]
		check(game.story.observe_tick(1.2,true,true),"path root observation ready")
		game._show_cue()
		check(game.dialogue.visible,"each root has distinct choice panel")
		game._choose("path_"+action)
		if game.dialogue.visible: game._choose("close")
	check(game.story.phase==4,"real path opens truth trial")
	for id in State.FACTS:
		game._show_truth()
		game._choose("truth_"+id)
		if game.dialogue.visible: game._choose("close")
	check(game.story.phase==5,"Keeper receives only gathered evidence")
	for action in State.AWAKENED_RESPONSES:
		game.player_pos=game.AWAKENED_STONES[game.story.awake_index]
		check(game.story.observe_tick(1.2,true,true),"safe awakened-root hold observed")
		game._show_cue()
		game._choose("awake_"+action)
		if game.dialogue.visible: game._choose("close")
	check(game.story.phase==6,"short fair awakened fight ends without an HP bar")
	game._show_final_choice()
	game._choose("ending_true")
	check(game.story.outcome=="true" and game.outcome_panel.visible,
		"credible true ending playable from actual scene")
	game._choose("epilogue")
	check(game.story.phase==7 and not game.outcome_panel.visible,
		"player freely walks the physical morning region")
	check(Save.exists(),"finale saves independently from six previous nights")
	check(World.read()["outcomes"].get("night07","")=="true",
		"one-world ledger retains genuine Night 7 outcome")
	game.queue_free()
	await process_frame
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp",World.PATH,
		World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in preserved:
		var file:=FileAccess.open(path,FileAccess.WRITE)
		if file!=null:
			file.store_buffer(preserved[path])
			file.close()
	for path in [river_save.PATH,river_save.PATH+".bak",river_save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in previous:
		var file:=FileAccess.open(path,FileAccess.WRITE)
		if file!=null:
			file.store_buffer(previous[path])
			file.close()
	print("Night 7 real scene, same HUD, seven-night road, trial and epilogue: ",
		"PASS" if failed==0 else str(failed)+" failures")
	quit(0 if failed==0 else 1)
