extends SceneTree
const S = preload("res://scripts/narrative/night04_state.gd")
const Save = preload("res://scripts/core/night04_save.gd")
var failures := 0

func verify(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("Night4 model: "+description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var original: Dictionary = {}
	for p in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]:
		if FileAccess.file_exists(p):
			original[p] = FileAccess.get_file_as_bytes(p)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	var model = S.new()
	verify(not model.deduce_target("nena"),"cannot jump past witness evidence")
	for id in S.CLUES:
		verify(model.inspect(id),"physical clue recorded "+id)
	verify(model.phase == 1,"all independent evidence opens private hypothesis")
	verify(not model.deduce_target("mourner"),"false hypothesis does not identify random mourner")
	verify(model.trust == 58,"private revision is not a public allegation")
	verify(model.accuse_guest() and model.trust == 46,"public allegation hurts Barrio Trust")
	verify(model.deduce_target("nena"),"Aling Nena is a target, not the predator")
	verify(model.phase == 2,"prepare coordinated defense after deducing target")
	for id in S.DEFENSES:
		verify(model.prepare(id),"prepared independent defensive station "+id)
	verify(model.begin_siege(),"well-prepared wake initiates telegraphed danger")
	verify(model.current_warning() == "roofline","first danger visibly approaches from roof")
	verify(not model.respond("ring_bell"),"cannot solve attack before watching its tells")
	for i in range(3):
		verify(model.observation_tick(1.5,true,true),"holding observation reveals an actionable tell")
		verify(model.respond(S.CORRECT_ACTIONS[i]),"correct group-defense response works "+str(i))
	verify(model.phase == 4 and model.protected_count == 3,"all three approaches protected without HP combat")
	verify(not model.commit("retreat"),"cannot abandon community after complete protection")
	verify(model.commit("resolve"),"all prepared defenses resolve the threat humanely")
	verify(not model.commit("resolve"),"cannot double-commit aftermath")
	verify(Save.write(model),"independent Night 4 save written")
	var reloaded = S.new()
	verify(Save.read(reloaded),"save loads on fresh state object")
	verify(reloaded.outcome == "resolve" and reloaded.trust == model.trust,"result and trust survive save")
	verify(reloaded.bestiary.has("manananggal"),"independent creature entry persists")
	var bad := reloaded.to_dict()
	bad["phase"] = 4
	bad["attack_index"] = 0
	verify(not S.new().from_dict(bad),"corrupt phase cannot bypass true three-response gameplay")
	var risky = S.new()
	for id in S.CLUES:
		risky.inspect(id)
	risky.deduce_target("nena")
	for id in S.DEFENSES.slice(0,3):
		risky.prepare(id)
	verify(risky.begin_siege(),"three defenses can protect without a forced perfect setup")
	risky.observation_tick(50.0,false,false)
	verify(risky.encounter_failed,"unmanaged warning raises recoverable danger")
	verify(risky.retry_checkpoint(),"nonfatal retry available before predatory approach")
	verify(risky.clues.size() == 4 and risky.defenses.size() == 3,"retry preserves clues and prior preparation")
	for id in S.DEFENSES:
		if not risky.defenses.has(id):
			verify(not risky.prepare(id),"active siege does not silently rewrite earlier station choices")
	for i in range(3):
		risky.observation_tick(1.5,true,true)
		risky.respond(S.CORRECT_ACTIONS[i])
	verify(not risky.commit("resolve"),"missing fourth defense prevents perfect resolve but not survival")
	verify(risky.commit("drive_away"),"surviving guests can achieve drive-away outcome")
	var safe = S.new()
	verify(safe.commit("retreat"),"withdrawal remains nonfatal and records unresolved community concern")
	for p in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	for p in original:
		var out := FileAccess.open(p,FileAccess.WRITE)
		if out != null:
			out.store_buffer(original[p])
			out.close()
	print("Night 4 Manananggal wake state and safe retries: ", "PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
