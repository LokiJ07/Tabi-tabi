extends RefCounted
## Night 7 — The Ancient Keeper. One connected final chapter, not a new game.
## The Keeper is a guardian of place and witness to loss, NOT a supernatural
## replacement for documented flood history, survivor consent or human agency.
const START := Vector2(-915, 400)
const CLUES := ["broken_waymark","keeper_roots","rescue_memorial","flood_oath"]
const PREPARATIONS := ["safe_footpath","witness_consent","remembrance_offering"]
const TRIAL := ["remember_losses","protect_living","share_responsibility"]
const RESULTS := ["renewal","repair","guarded"]
const SCHEMA := 7

var phase := 0 # 0 clues,1 deduction,2 preparation,3 trial,4 verdict,5 epilogue,6 free roam
var player_position := START
var clues: Dictionary = {}
var preparations: Dictionary = {}
var route_answered := false
var trial_index := 0
var observation := 0.0
var current_ready := false
var tension := 0.15
var wrong_guesses := 0
var trial_failed := false
var river_outcome := ""
var sabel_consent := "private"
var dado_consent := "unasked"
var lola_truth_known := false
var prior_outcomes: Dictionary = {}
var choice_of_remembrance := "private"
var outcome := ""
var epilogue_complete := false

func configure_from_river(river: RefCounted, ledger: Dictionary) -> void:
	if phase != 0 or not clues.is_empty():
		return
	river_outcome = str(river.outcome)
	sabel_consent = str(river.sabel_public_choice)
	dado_consent = str(river.dado_choice)
	lola_truth_known = river.lola_covenant_truth_known
	prior_outcomes = (ledger.get("outcomes", {}) as Dictionary).duplicate(true)

func inspect(id: String) -> bool:
	if phase != 0 or not CLUES.has(id) or clues.has(id):
		return false
	clues[id] = true
	if clues.size() == CLUES.size():
		phase = 1
	return true

func deduce(answer: String) -> bool:
	if phase != 1 or clues.size() != CLUES.size():
		return false
	if answer != "records_and_witnesses":
		wrong_guesses += 1
		return false
	route_answered = true
	phase = 2
	return true

func prepare(id: String) -> bool:
	if phase != 2 or not PREPARATIONS.has(id) or preparations.has(id):
		return false
	preparations[id] = true
	return true

func choose_remembrance(value: String) -> bool:
	if phase != 2 or not ["private","consented"].has(value):
		return false
	# A family member's earlier choice cannot be overwritten by a finale UI.
	if value == "consented" and sabel_consent != "consent_public":
		return false
	choice_of_remembrance = value
	return true

func begin_trial() -> bool:
	if phase != 2 or not route_answered or preparations.size() != PREPARATIONS.size():
		return false
	phase = 3
	trial_index = 0
	observation = 0.0
	current_ready = false
	trial_failed = false
	tension = 0.16
	return true

func observe_tick(delta: float, safe: bool, held: bool, assist: bool = false) -> bool:
	if phase != 3 or current_ready or trial_failed or outcome != "":
		return false
	if safe and held:
		observation = minf(1.0, observation + maxf(delta, 0.0) / (0.95 if assist else 1.35))
		tension = maxf(0.0, tension - maxf(delta, 0.0) * 0.07)
	else:
		# A measured warning, not an instant nonconsensual jump-scare/death.
		tension = minf(1.0, tension + maxf(delta, 0.0) * (0.006 if assist else 0.014))
	if tension >= 0.99:
		trial_failed = true
	if observation >= 0.999:
		current_ready = true
		return true
	return false

func respond(id: String) -> bool:
	if phase != 3 or not current_ready or trial_failed:
		return false
	if trial_index >= TRIAL.size() or id != TRIAL[trial_index]:
		wrong_guesses += 1
		tension = minf(0.98,tension + 0.18)
		return false
	trial_index += 1
	current_ready = false
	observation = 0.0
	tension = maxf(0.06,tension - 0.15)
	if trial_index == TRIAL.size():
		phase = 4
	return true

func retry_trial() -> bool:
	if phase != 3 or outcome != "":
		return false
	trial_failed = false
	current_ready = false
	observation = 0.0
	tension = 0.20
	return true

func available_results() -> Array[String]:
	var results: Array[String] = ["repair","guarded"]
	if river_outcome == "resolve" and route_answered and trial_index == TRIAL.size() and lola_truth_known:
		results.push_front("renewal")
	return results

func commit_result(value: String) -> bool:
	if phase != 4 or outcome != "" or not available_results().has(value):
		return false
	outcome = value
	phase = 5
	tension = 0.0
	return true

func finish_epilogue() -> bool:
	if phase != 5 or outcome == "":
		return false
	epilogue_complete = true
	phase = 6
	return true

func to_dict() -> Dictionary:
	return {
		"schema":SCHEMA,"phase":phase,"player_position":[player_position.x,player_position.y],
		"clues":clues.duplicate(true),"preparations":preparations.duplicate(true),
		"route_answered":route_answered,"trial_index":trial_index,
		"observation":observation,"current_ready":current_ready,
		"tension":tension,"wrong_guesses":wrong_guesses,"trial_failed":trial_failed,
		"river_outcome":river_outcome,"sabel_consent":sabel_consent,
		"dado_consent":dado_consent,"lola_truth_known":lola_truth_known,
		"prior_outcomes":prior_outcomes.duplicate(true),
		"choice_of_remembrance":choice_of_remembrance,
		"outcome":outcome,"epilogue_complete":epilogue_complete
	}

func from_dict(data: Dictionary) -> bool:
	if int(data.get("schema",-1)) != SCHEMA:
		return false
	var step := int(data.get("phase",-1))
	var trial_step := int(data.get("trial_index",-1))
	var ending := str(data.get("outcome",""))
	if step < 0 or step > 6 or trial_step < 0 or trial_step > TRIAL.size():
		return false
	if ending != "" and not RESULTS.has(ending):
		return false
	if step >= 5 and ending == "":
		return false
	if step == 6 and not bool(data.get("epilogue_complete",false)):
		return false
	for field in ["clues","preparations","prior_outcomes"]:
		if typeof(data.get(field)) != TYPE_DICTIONARY:
			return false
	var restored_clues: Dictionary = {}
	for id in CLUES:
		if data["clues"].get(id,false) == true:
			restored_clues[id] = true
	var restored_prep: Dictionary = {}
	for id in PREPARATIONS:
		if data["preparations"].get(id,false) == true:
			restored_prep[id] = true
	if step >= 1 and restored_clues.size() != CLUES.size():
		return false
	if step >= 2 and not bool(data.get("route_answered",false)):
		return false
	if step >= 3 and restored_prep.size() != PREPARATIONS.size():
		return false
	if step >= 4 and trial_step != TRIAL.size():
		return false
	var consent := str(data.get("sabel_consent","private"))
	if not ["private","written","consent_public"].has(consent):
		return false
	var remembrance := str(data.get("choice_of_remembrance","private"))
	if not ["private","consented"].has(remembrance):
		return false
	if remembrance == "consented" and consent != "consent_public":
		return false
	phase = step
	clues = restored_clues
	preparations = restored_prep
	route_answered = bool(data.get("route_answered",false))
	trial_index = trial_step
	observation = clampf(float(data.get("observation",0.0)),0.0,1.0)
	current_ready = bool(data.get("current_ready",false)) if phase == 3 else false
	tension = clampf(float(data.get("tension",0.15)),0.0,1.0)
	wrong_guesses = maxi(0,int(data.get("wrong_guesses",0)))
	trial_failed = bool(data.get("trial_failed",false)) if phase == 3 else false
	river_outcome = str(data.get("river_outcome",""))
	sabel_consent = consent
	dado_consent = str(data.get("dado_consent","unasked"))
	lola_truth_known = bool(data.get("lola_truth_known",false))
	prior_outcomes = (data["prior_outcomes"] as Dictionary).duplicate(true)
	choice_of_remembrance = remembrance
	outcome = ending
	epilogue_complete = bool(data.get("epilogue_complete",false))
	player_position = START
	var raw: Variant = data.get("player_position",[])
	if typeof(raw) == TYPE_ARRAY and raw.size() == 2:
		var p := Vector2(float(raw[0]),float(raw[1]))
		if p.is_finite() and absf(p.x) < 1450.0 and absf(p.y) < 1100.0:
			player_position = p
	return true
