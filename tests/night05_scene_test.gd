extends SceneTree
## Full Chapter 5 in-engine play test: physical coordinates, shared HUD,
## offline save and exact story state. A static picture could never pass.
const Scene = preload("res://scenes/night05.tscn")
const State = preload("res://scripts/narrative/night05_state.gd")
const Save = preload("res://scripts/core/night05_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
const SigbinPresence = preload("res://scripts/visuals/night05_sigbin_presence.gd")
const FarmArt = preload("res://scripts/visuals/night05_farm_art.gd")
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
	check(FarmArt.inside_livestock_pen(FarmArt.animal_pen_position(0))
		and FarmArt.inside_livestock_pen(FarmArt.animal_pen_position(1))
		and FarmArt.inside_livestock_pen(FarmArt.animal_pen_position(2)),
		"ALL three animal groups begin inside one real contiguous fenced pen")
	check(not FarmArt.inside_livestock_pen(game.SAFE_GATE)
		and not FarmArt.inside_livestock_pen(game.SAFE_PERIMETER)
		and not FarmArt.inside_livestock_pen(game.CLUE_POS["broken_barn"]),
		"animal gate, watch marker and evidence remain safely reachable OUTSIDE fences")
	var road_entry := Vector2(555,337)
	check(FarmArt.keep_player_outside_pen(road_entry,Vector2(555,268)) == road_entry,
		"player cannot phase through kural from safe road toward livestock")
	check(FarmArt.keep_player_outside_pen(Vector2(275,210),Vector2(320,210)).x <= 286.0,
		"western animal fence blocks unsafe approach while letting player slide")
	check(FarmArt.keep_player_outside_pen(Vector2(355,210),Vector2(355,220)).y
		> FarmArt.PEN.end.y,
		"an older save inside pen is relocated outside the safe gate boundary")
	check(game.SIGBIN_EAR_NEAR.get_width() >= 200 and game.SIGBIN_EAR_FAR.get_height() >= 120,
		"two independent original Sigbin ear sprites actually imported")
	check(SigbinPresence.visibility(0,false,false,0.0) == 0.0
		and SigbinPresence.visibility(3,true,false,1.0) == 1.0,
		"no unearned daylight creature and full identification at midnight")
	check(SigbinPresence.backward_foot(Vector2.ZERO,1.0,0,false).x < 0.0
		and SigbinPresence.backward_foot(Vector2.ZERO,2.0,0,true) == Vector2.ZERO,
		"backward retreat uses real world coordinates and reduced-motion option")
	check(SigbinPresence.backward_foot(Vector2.ZERO,5.0,0,false).x
		< SigbinPresence.backward_foot(Vector2.ZERO,1.0,0,false).x
		and SigbinPresence.retreating(5.0,0),
		"reverse walk advances backward over real time without foot teleporting")
	check(not is_equal_approx(SigbinPresence.stride(1.0,0.0,false),
		SigbinPresence.stride(1.3,0.0,false))
		and SigbinPresence.stride(1.0,0.0,true) == 0.0,
		"four-limb gait animates and respects Reduced Motion")
	check(SigbinPresence.hoof_lift(0.0,0.0,false) > 0.0
		and SigbinPresence.hoof_lift(0.0,0.0,true) == 0.0,
		"jointed feet lift and return to the earth")
	check(SigbinPresence.gait_strength(0.0,0,false) == 0.0
		and SigbinPresence.gait_strength(4.0,0,false) > .7
		and SigbinPresence.gait_strength(8.5,0,false) == 0.0,
		"Sigbin feet become planted at both ends of the backward patrol")
	check(SigbinPresence.gait_strength(4.0,0,true) == 0.0
		and SigbinPresence.body_weight_shift(4.0,0,true) == Vector2.ZERO,
		"Reduced Motion also freezes ribcage displacement and walking")
	check(SigbinPresence.body_weight_shift(4.0,0,false).length() > .1
		and SigbinPresence.body_weight_shift(4.3,0,false)
			!= SigbinPresence.body_weight_shift(4.0,0,false),
		"weight shifting follows genuine motion rather than a fixed floating pose")
	check(SigbinPresence.detect_warning(3,250.0,0.0,false).contains("ODOR")
		and SigbinPresence.detect_warning(3,250.0,4.5,false).contains("EAR-CLAPS")
		and SigbinPresence.detect_warning(3,250.0,8.5,false).contains("BACKWARD"),
		"three distinct proximity-based folklore signals visible in live HUD")
	for tick in [0.0,4.5,8.5]:
		var cue: String = SigbinPresence.detect_warning(3,250.0,tick,false)
		check(cue.length() <= 32,
			"folklore detector fits Night 1 shared mobile HUD without three-line overflow")
	check(SigbinPresence.detect_warning(3,250.0,1.0,true).length() <= 32,
		"confirmed Sigbin warning stays compact above the playfield")
	if game.dialogue.visible:
		game._choose("close")
	# Regression: the original midnight screenshot showed DAY / TRACKS and no
	# Sigbin because the distant eave was outside the vertical camera frame.
	# Test the actual live encounter camera as well as its preview stage label.
	game.debug_farm_preview = true
	game.player_pos = game.SAFE_PERIMETER
	game.camera.position = game.player_pos
	game._refresh() # Mirror the real F9 QA input which refreshes the HUD.
	game._process(1.0)
	check(game.interaction_hint.text.length() <= 32,
		"actual live Sigbin encounter does not cover the upper HUD with multiline warning")
	var live_foot := SigbinPresence.backward_foot(SigbinPresence.ground_anchor(0),
		game.elapsed,0,game.prefs.reduced_motion)
	var real_proximity := clampf(1.0-game.player_pos.distance_to(live_foot)/1100.0,0.0,1.0)
	check(absf(game.ambient.sigbin_proximity-real_proximity) < .0001,
		"ears and odor strength follow creature feet, never its old roof shadow")
	check(absf(game.ambient.sigbin_gait
		-SigbinPresence.gait_strength(game.elapsed,0,game.prefs.reduced_motion)) < .0001,
		"footstep sound is tied to actual Sigbin movement speed")
	game.ambient.set_sigbin_gait(-5.0)
	check(game.ambient.sigbin_gait == 0.0,
		"ground-scuff generator clamps negative gait and never sounds at rest")
	var sigbin_foot: Vector2 = SigbinPresence.ground_anchor(0)
	check(sigbin_foot.y > -80.0
		and SigbinPresence.ground_anchor(1).y > -80.0,
		"Sigbin hooves stand outside hazardous barn footprint, not on roof air")
	var half_view_height: float = 720.0 / (2.0 * game.camera.zoom.y)
	check(game._stage() == 3 and game.subtitle.text.begins_with("MIDNIGHT / SIGBIN"),
		"midnight QA capture is explicitly the Sigbin reveal, never DAY / TRACKS")
	check(absf((sigbin_foot.y - 206.0) - game.camera.position.y) < half_view_height - 18.0,
		"full first Sigbin silhouette fits the Android encounter camera height")
	check(absf(game.player_pos.y - game.camera.position.y) < half_view_height - 18.0,
		"player at safe perimeter remains in the same frame as Sigbin")
	game.debug_farm_preview = false
	game._refresh()
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
	check(not FarmArt.route_is_open(0,game.story.rescued_groups)
		and not FarmArt.route_is_open(1,game.story.rescued_groups),
		"all three connected shadows are blocked before the first safe rescue")
	check(FarmArt.animal_crossing_position(0,game.SAFE_GATE,false,.5)
		== FarmArt.animal_pen_position(0),
		"unrescued animal cannot move to the gate before the lantern is solved")
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
		check(FarmArt.route_is_open(i,game.story.rescued_groups)
			and not FarmArt.route_is_open(i+1,game.story.rescued_groups),
			"only the correctly shifted light opens the current shadow route "+str(i))
		if not game.prefs.reduced_motion:
			check(game.animal_rescue_motion.has(i)
				and float(game.animal_rescue_motion[i]) == 0.0,
				"rescued group begins physical crossing after lantern choice "+str(i))
		var midpoint: Vector2 = FarmArt.animal_crossing_position(i,
			game.SAFE_GATE,true,.5)
		check(midpoint.distance_to(FarmArt.animal_pen_position(i)) > 10.0
			and midpoint.distance_to(FarmArt.animal_gate_position(i,game.SAFE_GATE)) > 10.0
			and midpoint.y > 80.0,
			"animated livestock crosses open SOIL, never teleports through the collapsing barn")
		var threshold: Vector2 = FarmArt.animal_crossing_position(i,
			game.SAFE_GATE,true,.62)
		check(absf(threshold.x-game.SAFE_GATE.x) < 1.0
			and threshold.y > FarmArt.PEN.end.y,
			"every animal uses the SAME prepared gate gap rather than crossing a solid rail")
		check(FarmArt.GATE_LEFT < threshold.x
			and threshold.x < FarmArt.GATE_RIGHT,
			"single animal exit lies physically inside the real fence opening")
		check(FarmArt.animal_crossing_position(i,game.SAFE_GATE,true,1.0)
			== FarmArt.animal_gate_position(i,game.SAFE_GATE),
			"completed livestock path lands exactly at the safe gate")
		game._choose("close")
	check(game.story.phase == 4 and game.story.rescued_groups == 3,
		"complete rescue earns safe aftermath; Sigbin remains unharmed")
	check(game.objective.text.contains("safe holding")
		and FarmArt.animal_gate_position(0,game.SAFE_GATE).y > FarmArt.PEN.end.y,
		"player end-of-night instructions identify the fenced safe holding area")
	if not game.prefs.reduced_motion:
		var last_position: Vector2 = FarmArt.animal_crossing_position(2,game.SAFE_GATE,true,
			float(game.animal_rescue_motion.get(2,1.0)))
		game._process(1.0)
		var next_position: Vector2 = FarmArt.animal_crossing_position(2,game.SAFE_GATE,true,
			float(game.animal_rescue_motion.get(2,1.0)))
		check(next_position != last_position,
			"livestock continues a smooth in-world crossing while the story modal is visible")
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
