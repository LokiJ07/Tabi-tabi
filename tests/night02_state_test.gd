extends SceneTree
## Night 2 canonical progression: no dialogue shortcut can resolve an unsafe
## public tree, all three outcomes canonical, and saved checkpoints recover.
const Model = preload("res://scripts/narrative/night02_state.gd")
const Save = preload("res://scripts/core/night02_save.gd")
var errors := 0

func check(condition: bool, label: String) -> void:
	if not condition:
		errors += 1
		printerr("Night 2 model: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _ready_clues(m) -> void:
	for id in Model.REQUIRED_CLUES:
		check(m.observe(id), "can inspect distinct evidence " + id)

func _ready_route(m) -> void:
	check(m.begin_safety(), "full evidence unlocks route safety")
	for id in Model.BARRIER_POSITIONS:
		check(m.close_route(id), "can secure each approach " + id)

func _run() -> void:
	var m = Model.new()
	m.night1_outcome = "resolve"
	check(not m.begin_safety(), "no approach to Kapre before evidence")
	check(not m.greet_respectfully(), "no premature greeting")
	check(not m.commit("resolve"), "cannot resolve by dialogue alone")
	check(m.observe("fallen_limb"), "first fallen limb observation")
	check(not m.observe("fallen_limb"), "no duplicate clue")
	check(not m.observe("kapre_is_mang_celso"), "no rumor-as-clue")
	for id in Model.REQUIRED_CLUES:
		if id != "fallen_limb":
			check(m.observe(id), "observe "+id)
	check(m.complete_evidence(), "all 5 clues")
	_ready_route(m)
	check(m.safe_route(), "all public approaches closed")
	check(not m.commit("resolve"), "route closure alone does not resolve")
	check(m.begin_observation(), "safe route allows observation")
	check(not m.greet_respectfully(), "cannot greet without watching")
	check(not m.observe_from_safety(6.0, false, true), "observation outside sheltered position is rejected")
	check(not m.observe_from_safety(3.0, true, true), "partial observation is not enough")
	check(m.observe_from_safety(1.2, true, true), "four seconds continuous observation")
	check(m.greet_respectfully(), "respectful 'tabi-tabi po' unlocks negotiation")
	check(not m.choose_offering("stones"), "wrong/offensive offering rejected")
	check(m.choose_offering("coffee"), "Kapre accepts respectful coffee")
	check(not m.propose_preservation(false,true), "no promised preservation without expert assessment")
	check(m.propose_preservation(true,true), "route diversion + qualified expert assessment")
	check(m.commit("resolve"), "negotiated safety resolution")
	check(not m.commit("resolve"), "cannot duplicate final event")
	check(m.committed_events.size() == 1 and m.bestiary.has("kapre"), "one Kapre record")
	check(m.bestiary["kapre"]["promise"] == true, "bestiary notes actual promise")
	check(Save.write(m), "independent atomic Night 2 save")
	var restored = Model.new()
	check(Save.read(restored), "Night 2 can load saved file")
	check(restored.outcome == "resolve" and restored.night1_outcome == "resolve", "outcome and inherited N1 context survive")
	check(restored.clues.size() == 5 and restored.barriers.size() == 3, "all clues/barriers survive")

	var partial = Model.new()
	_ready_clues(partial)
	_ready_route(partial)
	check(partial.commit("partial"), "secured route can end with partial agreement")
	check(partial.outcome == "partial", "correct partial outcome")
	var retreat = Model.new()
	check(retreat.commit("retreat"), "safe withdrawal always possible")
	check(retreat.outcome == "retreat", "correct retreat outcome")
	check(retreat.committed_events.size() == 1, "one retreat event")
	var early = Model.new()
	early.danger_tick(12.0, true, false)
	check(early.encounter_failed, "early unstable-tree approach triggers warning")
	check(early.safe_retry(), "phase-zero safe retry exists without checkpoint")
	check(not early.encounter_failed and early.courage >= 55.0, "early retry removes softlock")
	var danger = Model.new()
	_ready_clues(danger)
	_ready_route(danger)
	check(danger.begin_observation(), "danger test observation starts")
	danger.danger_tick(12.0, true, false)
	check(danger.encounter_failed, "unsafe tree proximity raises danger")
	check(danger.safe_retry(), "checkpoint restores safe state")
	check(not danger.encounter_failed, "retry clears failed encounter")
	var malformed := m.to_dict()
	malformed["phase"] = 8
	check(not Model.new().from_dict(malformed), "reject invalid save phase")
	for path in [Save.PATH, Save.PATH+".bak", Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Night 2 state & safety negotiation: ", "PASS" if errors == 0 else str(errors)+" failure(s)")
	quit(0 if errors == 0 else 1)
