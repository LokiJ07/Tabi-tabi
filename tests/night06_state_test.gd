extends SceneTree
## Night 6 canon, evidence revision, nonfatal survival and save persistence.
const State = preload("res://scripts/narrative/night06_state.gd")
const Save = preload("res://scripts/core/night06_save.gd")
var errors := 0
func check(value: bool,why: String) -> void:
	if not value:
		errors += 1
		printerr("Night 6 flood state: "+why)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var old: Dictionary = {}
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			old[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var state = State.new()
	check(not state.reconstruct_cancellation("real_danger_unequal_choice"),
		"cannot invent a cancellation before documented evidence")
	check(state.record_dado("decline") and not state.record_dado("private"),
		"voluntary Dado testimony is never required")
	for id in State.CLUES:
		check(state.inspect(id),"distinct physical source "+id)
	check(state.phase == 1 and state.clues.size() == 4,"four independent sources precede inference")
	check(not state.reconstruct_cancellation("all_safe") and state.phase == 1,
		"wrong all-safe hypothesis can be revised")
	check(state.reconstruct_cancellation("real_danger_unequal_choice"),
		"historical order is risk + unequal protection, not claim of safe official passage")
	check(not state.plot_route("far_bank") and state.route_index == 0,
		"historical map route order cannot be guessed out of sequence")
	for id in State.ROUTE:
		check(state.plot_route(id),"map reconstruction step "+id)
	check(state.independent_return_confirmed and state.phase == 3,
		"independent boat journey established but identity still unknown")
	check(not state.reconstruct_sacrifice("sabel_husband"),
		"rescuer identity not granted without two sources")
	for id in State.IDENTITY:
		check(state.inspect_identity(id),"independent source "+id)
	check(not state.reconstruct_sacrifice("celso") and not state.rescuer_confirmed,
		"Santelmo boatman not falsely merged with Sabel's husband")
	check(state.reconstruct_sacrifice("sabel_husband"),"third reconstruction corroborates rescuer")
	check(not state.open_river(),"no forced shortcut past human disclosure and accountability")
	check(state.tell_sabel("private"),"consensual private revelation allowed")
	check(state.confess_lola() and state.open_river(),
		"Lola acknowledges withheld records and limited Keeper refuge")
	check(not state.commit("resolve"),"no full result without river route")
	for id in State.PREPARATIONS:
		check(state.prepare(id),"separate physical crossing safeguard "+id)
	check(state.begin_crossing(),"three preparations unlock the real current")
	check(not state.observe_tick(1.2,false,true),"unsafe position cannot auto-identify current")
	check(state.observe_tick(1.3,true,true),"steady marked-stone observation is enough")
	check(not state.respond("speak_names") and state.step_index == 0,
		"first surge rejects incorrect tool without fatality")
	check(state.respond("hold_lantern"),"first surge follows lantern cue")
	state.tension = .97
	state.unsafe_current()
	check(state.encounter_failed and state.step_index == 1,"bad footing is nonfatal")
	check(state.retry_current() and state.step_index == 1 and state.clues.size() == 4,
		"safe retry preserves past steps and historical evidence")
	check(state.observe_tick(1.2,true,true) and state.respond("secure_rope"),"second surge uses tied mooring line")
	check(state.observe_tick(1.2,true,true) and state.respond("speak_names"),"final surge uses confirmed names")
	check(state.phase == 7 and state.step_index == 3,"three separate real challenges finish at dawn")
	check(state.commit("resolve"),"verified full resolution is reachable")
	check(state.sabel_public_choice == "private","perfect resolution never forces public appearance")
	check(Save.write(state),"save independent Night 6 record")
	var loaded = State.new()
	check(Save.read(loaded) and loaded.outcome == "resolve" and loaded.step_index == 3,
		"offline reload keeps completed river result")
	check(loaded.night05_outcome == "","prior outcomes not fabricated")
	var corrupt := loaded.to_dict()
	corrupt["route_index"] = 9
	check(not State.new().from_dict(corrupt),"out-of-range corrupted route rejected")
	var alternate = State.new()
	for id in State.CLUES: alternate.inspect(id)
	alternate.reconstruct_cancellation("real_danger_unequal_choice")
	for id in State.ROUTE: alternate.plot_route(id)
	for id in State.IDENTITY: alternate.inspect_identity(id)
	alternate.reconstruct_sacrifice("sabel_husband")
	alternate.tell_sabel("written")
	alternate.confess_lola()
	alternate.open_river()
	check(alternate.commit("partial") and alternate.sabel_public_choice == "written",
		"recoverable partial ending with written remembrance permitted")
	check(State.new().from_dict(alternate.to_dict()),"partial retreat save remains reloadable")
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in old:
		var stream := FileAccess.open(path,FileAccess.WRITE)
		if stream != null:
			stream.store_buffer(old[path])
			stream.close()
	print("Night 6 historical canon, three reconstructions, privacy, river & save: ",
		"PASS" if errors == 0 else str(errors)+" failures")
	quit(0 if errors == 0 else 1)
