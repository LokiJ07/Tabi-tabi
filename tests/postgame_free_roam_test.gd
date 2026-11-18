extends SceneTree
## A completed, genuinely saved finale unlocks ALL seven adjacent on-foot maps.
## Earlier chapter saves/choices must survive round trips and title resumes.
const World = preload("res://scripts/core/connected_world.gd")
const Finale = preload("res://scripts/narrative/night07_state.gd")
const FinaleSave = preload("res://scripts/core/night07_save.gd")
const TitleScene = preload("res://scenes/title.tscn")
const Night02Scene = preload("res://scenes/night02.tscn")
const Night03Scene = preload("res://scenes/night03.tscn")
const Night04Scene = preload("res://scenes/night04.tscn")
const Night05Scene = preload("res://scenes/night05.tscn")
const Night06Scene = preload("res://scenes/night06.tscn")
const Night07Scene = preload("res://scenes/night07.tscn")
const Night01Save = preload("res://scripts/core/save_service.gd")
const Night02Save = preload("res://scripts/core/night02_save.gd")
const Night03Save = preload("res://scripts/core/night03_save.gd")
const Night04Save = preload("res://scripts/core/night04_save.gd")
const Night05Save = preload("res://scripts/core/night05_save.gd")
const Night06Save = preload("res://scripts/core/night06_save.gd")
var failed := 0
func check(ok: bool,what: String) -> void:
	if not ok:
		failed+=1
		printerr("Post-game seven-map free-roam: "+what)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var original: Dictionary = {}
	var paths: Array[String] = []
	for base in [
		World.PATH,FinaleSave.PATH,
		Night01Save.PATH,Night02Save.PATH,Night03Save.PATH,
		Night04Save.PATH,Night05Save.PATH,Night06Save.PATH
	]:
		for suffix in ["",".bak",".tmp"]:
			var path: String = base+suffix
			paths.append(path)
			if FileAccess.file_exists(path):
				original[path]=FileAccess.get_file_as_bytes(path)
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	check(not World.free_roam_unlocked(),"a new game is not secretly post-game")
	check(not World.unlock_free_roam(),"can't unlock without final save")
	check(not World.choose_free_roam_region("night05"),"title can't open future region from an uncompleted save")
	check(not World.begin_travel("barrio_lawom","old_mango",""),
		"original pre-ending trail remains gated")
	check(not World.begin_travel("night05","night06",""),
		"pre-ending Sigbin case must still be completed")

	var model=Finale.new()
	model.night06_outcome="partial"
	model.night01_outcome="partial"
	model.night02_outcome="partial"
	model.night03_outcome="partial"
	model.night04_outcome="drive_away"
	model.night05_outcome="safe_rescue"
	model.sabel_privacy="private"
	model.previous_facts={"cancelled_rescue":true,"returning_boat":true,"limited_refuge":true}
	model.review_notebook()
	model.acknowledge_privacy()
	check(model.begin_final_trial(),"final checkpoint actually entered")
	model.respect_sabel()
	for id in Finale.FACTS:
		check(model.present_fact(id),"authentic historical evidence presented: "+id)
	for id in Finale.COMMITMENTS:
		check(model.confirm_commitment(id),"practical community work recorded: "+id)
	check(model.acknowledge_public_record() and model.conclude_gathering(),
		"community acknowledged history with privacy")
	check(model.reveal_keeper(),"actual trial entrance")
	for response in Finale.PATH_RESPONSES:
		check(model.observe_tick(1.2,true,true) and model.respond_path(response),
			"observed and solved real marked root: "+response)
	for id in Finale.FACTS:
		check(model.present_truth(id),"Keeper explicitly hears corroborated record")
	for response in Finale.AWAKENED_RESPONSES:
		check(model.observe_tick(1.2,true,true) and model.respond_awakened(response),
			"survived original nonlethal root warning: "+response)
	check(model.commit("good"),"permitted postgame after temporary peace ending")
	check(FinaleSave.write(model),"record finale before voluntary conclusion")
	check(World.note_outcome(7,"good"),"same-world ending recorded")
	check(not World.unlock_free_roam(),"chosen ending alone does not unlock before completed epilogue")
	check(not World.free_roam_unlocked(),"map still follows story until Finish is selected")
	check(model.finish_story() and FinaleSave.write(model),"voluntary final completion and atomic save")
	check(World.unlock_free_roam() and World.free_roam_unlocked(),"finished save unlocks seven-map exploration")
	check(World.unlock_free_roam(),"unlocks idempotently for existing finished saves")
	check(not World.begin_travel("night07","barrio_lawom",""),
		"even completed player cannot warp between disconnected regions")

	check(World.choose_free_roam_region("night07"),"last visited region persisted from title")
	var backward: Array[String]=["night07","night06","night05","night04",
		"night03","old_mango","barrio_lawom"]
	for i in range(backward.size()-1):
		var origin: String=backward[i]
		var target: String=backward[i+1]
		check(World.begin_travel(origin,target,""),
			"on-foot exit open after ending: "+origin+" → "+target)
		check(World.consume_arrival(target).get("from","")==origin,
			"correct physical destination spawn for "+target)
	check(World.free_roam_resume_region()=="barrio_lawom",
		"return to Barrio Lawom is a persistent location not an ending replay")
	for i in range(backward.size()-1,0,-1):
		var origin: String=backward[i]
		var target: String=backward[i-1]
		check(World.begin_travel(origin,target,""),"walking forward again: "+origin+" → "+target)
		check(World.consume_arrival(target).get("from","")==origin,
			"return trip carries route origin: "+target)
	check(World.free_roam_resume_region()=="night07",
		"revisiting Keeper grounds resumes saved world position")
	check(World.choose_free_roam_region("night05") and World.free_roam_resume_region()=="night05",
		"postgame title may resume selected map without losing the whole world")

	var title=TitleScene.instantiate()
	root.add_child(title)
	await process_frame
	check(not title.continue_button.disabled and title.continue_button.text.begins_with("FREE ROAM"),
		"title invites Explore All 7 Maps instead of restarting Night 1")
	check(title._has_any_story_progress(),
		"new story must require explicit reset confirmation even if Night 1 is missing")
	check(title._resume_free_roam_at("night04") and World.free_roam_resume_region()=="night04",
		"direct chapter picker updates last-visited postgame region")
	title.queue_free()
	await process_frame

	# Instantiated Godot scenes, not only a pure graph: every real chapter
	# loads with the permanent postgame exploration flag, with no old
	# chapter-completion modal blocking movement and road interactions.
	for spec in [
		[Night02Scene,"old_mango","_nearby","ridge_gate"],
		[Night03Scene,"night03","_nearby","wake_gate"],
		[Night04Scene,"night04","_nearby","farm_trail"],
		[Night05Scene,"night05","_nearby","river_trail"],
		[Night06Scene,"night06","_nearby","balete_gate"],
		[Night07Scene,"night07","",""]
	]:
		var game = (spec[0] as PackedScene).instantiate()
		root.add_child(game)
		await process_frame
		# Positioning directly on a real scene exit triggers auto-streaming
		# during the next _process frame. Freeze movement only for this
		# read-only hitbox assertion; separately exercise travel through
		# the actual World.begin_travel() path above.
		game.set_process(false)
		if str(spec[1])=="night07":
			check(game.story.finished and not game.outcome_panel.visible,
				"revisiting the finale starts open world, not blocking final outcome")
			game.player_pos=game.POSTGAME_MARKER
			check(game._nearest()=="after_story","finale has in-world readable seven-night record")
			game._interact()
			check(game.notebook.visible and game.notebook_text.text.contains("NIGHT 7"),
				"keeper's morning board opens full evidence-based conclusion")
		else:
			var modal_open: bool = false
			if str(spec[1])=="old_mango":
				modal_open=game.dialogue.visible or game.notebook.visible 					or game.options_panel.visible or game.ending_panel.visible
			else:
				modal_open=bool(game.call("_modal_open")) if str(spec[1])=="night03" else bool(game.call("_modal"))
			check(game.free_roam_mode and not modal_open,
				"old ending screen no longer blocks walking: "+str(spec[1]))
			if str(spec[1])=="old_mango":
				game.player_pos=World.TRAIL_MANGO_RIDGE
			elif str(spec[1])=="night03":
				game.player_pos=World.TRAIL_RIDGE_WAKE
			elif str(spec[1])=="night04":
				game.player_pos=game.FARM_TRAIL
			elif str(spec[1])=="night05":
				game.player_pos=game.FUTURE_TRAIL
			elif str(spec[1])=="night06":
				game.player_pos=game.NIGHT07_GATE
			check(game._nearby()==str(spec[3]),
				"real scene exit is interactive in Free Roam: "+str(spec[1]))
			check(game.postgame_ending=="good" and game.POSTGAME_MARKER is Vector2,
				"every restored map adopts canonical GOOD community morning")
			game.player_pos=game.POSTGAME_MARKER
			check(game._nearby()=="after_story",
				"physical ending-specific remembrance board can be approached: "+str(spec[1]))
			game._interact()
			check(game.dialogue.visible,
				"seven-night local story plays in real scene interaction: "+str(spec[1]))
		game.queue_free()
		await process_frame

	var reloaded=Finale.new()
	check(FinaleSave.read(reloaded) and reloaded.finished and reloaded.outcome=="good",
		"saved ending, family consent and epilogue survive all map crossings")
	check(reloaded.sabel_privacy=="private" and reloaded.night01_outcome=="partial",
		"earlier chapter outcomes and private witnesses do not reset in Free Roam")
	check(World.read()["outcomes"].get("night07","")=="good",
		"final outcome remains canonical in world ledger")
	for base in [
		Night01Save.PATH,Night02Save.PATH,Night03Save.PATH,
		Night04Save.PATH,Night05Save.PATH,Night06Save.PATH
	]:
		check(not FileAccess.file_exists(base),
			"travel and exploration cannot invent or overwrite a prior chapter save: "+base)
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in original:
		var file:=FileAccess.open(path,FileAccess.WRITE)
		if file!=null:
			file.store_buffer(original[path])
			file.close()
	print("Post-story FREE ROAM all 7 physical maps / titles / saves: ",
		"PASS" if failed==0 else str(failed)+" failures")
	quit(0 if failed==0 else 1)
