extends SceneTree
## Canonical Sigbin: no kills, shadow connectivity, safe animals, atomic save.
const State = preload("res://scripts/narrative/night05_state.gd")
const Save = preload("res://scripts/core/night05_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
var errors := 0

func check(ok: bool,reason: String) -> void:
	if not ok:
		errors += 1
		printerr("Sigbin Night 5 state: "+reason)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model = State.new()
	check(model.phase == 0 and model.clues.is_empty()
		and model.outcome == "","safe investigation from zero")
	check(not model.deduce("guardian"),"no guessing the guardian before evidence")
	for id in State.CLUES:
		check(model.inspect(id),"physical clue "+id+" can be found")
	check(model.phase == 1 and model.clues.size() == 4,
		"all four physical observations open evidence-based deduction")
	check(not model.deduce("predator") and model.mistakes == 1,
		"wrong accusation is rejected without making Sigbin a generic enemy")
	check(model.deduce("guardian"),"misguided guardian recognized without violence")
	check(not model.begin_rescue(),"unprepared rescue cannot bypass unstable barn")
	check(not model.enter_unstable_barn() and model.unsafe_entry_attempts == 1,
		"unstable barn entry never rewarded")
	for id in State.PREPARATIONS:
		check(model.prepare(id),"safe prep "+id)
	check(model.can_begin_rescue() and model.begin_rescue(),
		"three lanterns plus gate and stable perimeter required")
	check(not model.respond("lantern_west"),"shadow response must be observed first")
	for i in range(3):
		check(model.current_shadow() == State.SHADOW_ROUTES[i],
			"genuine connected shadow route "+str(i))
		check(model.observe_tick(1.25,true,true),"focused safe observation identifies real shadow")
		var rescue_index: int = model.rescued_groups
		var wrong: String = State.CORRECT_LIGHTS[(i+1)%3]
		check(not model.respond(wrong) and model.rescued_groups == rescue_index,
			"wrong lamp never rescues an animal automatically")
		check(model.respond(State.CORRECT_LIGHTS[i]),"correct lamp safely opens route")
		check(model.rescued_groups == i+1,"exactly one rescued group per route")
	check(model.phase == 4 and model.rescued_groups == 3,"two goats and chickens rescued alive")
	check(not model.commit("resolve"),"perfect territory ending requires no wrong guesses")
	check(model.commit("safe_rescue"),"fair safe-rescue outcome reflects actual mistakes")
	check(model.outcome == "safe_rescue" and model.bestiary.has("sigbin"),
		"original guardian behavior and physical facts documented")
	var restored = State.new()
	check(restored.from_dict(model.to_dict())
		and restored.outcome == "safe_rescue"
		and restored.rescued_groups == 3,
		"schema v5 save round-trip keeps group rescue and old bond")
	var early = State.new()
	check(early.commit("retreat"),"nonfatal withdrawal available without fabricated clues")
	var early_copy = State.new()
	check(early_copy.from_dict(early.to_dict()) and early_copy.outcome == "retreat",
		"early safe retreat can actually reload (not stuck at title)")
	var clean = State.new()
	for id in State.CLUES:
		clean.inspect(id)
	clean.deduce("guardian")
	for id in State.PREPARATIONS:
		clean.prepare(id)
	clean.begin_rescue()
	for i in range(3):
		clean.observe_tick(1.3,true,true)
		clean.respond(State.CORRECT_LIGHTS[i])
	check(clean.commit("resolve"),"full rescue and respect earns safe territory ending")
	var originals: Dictionary = {}
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			originals[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(Save.write(clean),"Night 5 independent atomic save written")
	var saved = State.new()
	check(Save.read(saved) and saved.outcome == "resolve",
		"Night 5 saved and reloaded with actual outcome")
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in originals:
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file != null:
			file.store_buffer(originals[path])
			file.close()
	print("Night 5 Sigbin state / shadow rescue / persistence: ",
		"PASS" if errors == 0 else str(errors)+" failures")
	quit(0 if errors == 0 else 1)
