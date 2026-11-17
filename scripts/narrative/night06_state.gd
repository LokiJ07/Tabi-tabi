extends RefCounted
## Night 6: evidence-driven flood truth and the River's Unfinished Memory.
## A nonfatal, revisable investigation—not a monster-HP battle.
const START := Vector2(-935,-425)
const CLUES := ["rescue_order","flood_gauge","evacuation_roll","alternatives_log"]
const ROUTE := ["official_dock","far_bank","shelter_return"]
const IDENTITY := ["family_boat_mark","survivor_account"]
const PREPARATIONS := ["rope_anchor","lantern_beacon","safe_stones"]
const RIVER_ACTIONS := ["hold_lantern","secure_rope","speak_names"]
const RESULTS := ["resolve","contain","partial","retreat"]
var night01_outcome := ""
var night02_outcome := ""
var night03_outcome := ""
var night04_outcome := ""
var night05_outcome := ""
var player_position := START
var phase := 0 # 0 evidence, 1 cancellation, 2 boat route, 3 rescuer, 4 family, 5 preparation, 6 crossing, 7 aftermath
var clues: Dictionary = {}
var route_index := 0
var identity_sources: Dictionary = {}
var cancellation_confirmed := false
var independent_return_confirmed := false
var rescuer_confirmed := false
var private_sabel_told := false
var sabel_public_choice := "private"
var lola_covenant_truth_known := false
var dado_choice := "unasked"
var preparations: Dictionary = {}
var step_index := 0
var observation := 0.0
var current_ready := false
var tension := 0.0
var encounter_failed := false
var wrong_hypotheses := 0
var outcome := ""
var findings: Dictionary = {}

func inspect(id: String) -> bool:
	if phase != 0 or not CLUES.has(id) or clues.has(id): return false
	clues[id] = true
	if clues.size() == CLUES.size(): phase = 1
	return true

func record_dado(choice: String) -> bool:
	if dado_choice != "unasked" or not ["private","decline"].has(choice): return false
	dado_choice = choice
	return true

func reconstruct_cancellation(answer: String) -> bool:
	if phase != 1 or clues.size() != CLUES.size(): return false
	if answer != "real_danger_unequal_choice":
		wrong_hypotheses += 1
		return false
	cancellation_confirmed = true
	phase = 2
	return true

func plot_route(id: String) -> bool:
	if phase != 2 or route_index >= ROUTE.size(): return false
	if id != ROUTE[route_index]:
		wrong_hypotheses += 1
		return false
	route_index += 1
	if route_index == ROUTE.size():
		independent_return_confirmed = true
		phase = 3
	return true

func inspect_identity(id: String) -> bool:
	if phase != 3 or not IDENTITY.has(id) or identity_sources.has(id): return false
	identity_sources[id] = true
	return true

func reconstruct_sacrifice(answer: String) -> bool:
	if phase != 3 or identity_sources.size() != IDENTITY.size(): return false
	if answer != "sabel_husband":
		wrong_hypotheses += 1
		return false
	rescuer_confirmed = true
	phase = 4
	return true

func tell_sabel(choice: String) -> bool:
	if phase != 4 or private_sabel_told or not ["private","written","consent_public"].has(choice): return false
	private_sabel_told = true
	sabel_public_choice = choice
	return true

func confess_lola() -> bool:
	if phase != 4 or lola_covenant_truth_known: return false
	lola_covenant_truth_known = true
	return true

func open_river() -> bool:
	if phase != 4 or not private_sabel_told or not lola_covenant_truth_known: return false
	phase = 5
	return true

func prepare(id: String) -> bool:
	if phase != 5 or not PREPARATIONS.has(id) or preparations.has(id): return false
	preparations[id] = true
	return true

func begin_crossing() -> bool:
	if phase != 5 or preparations.size() != PREPARATIONS.size(): return false
	phase = 6
	step_index = 0
	observation = 0.0
	current_ready = false
	encounter_failed = false
	tension = .15
	return true

func observe_tick(delta: float, safe: bool, held: bool, assist: bool = false) -> bool:
	if phase != 6 or outcome != "" or encounter_failed or current_ready: return false
	if safe and held:
		observation = minf(1.0,observation+maxf(delta,0.0)/1.15)
		tension = maxf(.0,tension-maxf(delta,0.0)*.03)
	else:
		tension = minf(.99,tension+maxf(delta,0.0)*(.018 if assist else .034))
	if observation >= .999:
		current_ready = true
		return true
	if tension >= .98: encounter_failed = true
	return false

func respond(id: String) -> bool:
	if phase != 6 or not current_ready or encounter_failed or step_index >= RIVER_ACTIONS.size(): return false
	if id != RIVER_ACTIONS[step_index]:
		tension = minf(.98,tension+.12)
		wrong_hypotheses += 1
		return false
	step_index += 1
	current_ready = false
	observation = 0.0
	tension = maxf(.0,tension-.24)
	if step_index == 3: phase = 7
	return true

func unsafe_current() -> void:
	if phase == 6:
		tension = minf(.99,tension+.09)
		if tension >= .98: encounter_failed = true

func retry_current() -> bool:
	if phase != 6 or not encounter_failed or outcome != "": return false
	encounter_failed = false
	current_ready = false
	observation = 0.0
	tension = .20
	return true

func commit(result: String) -> bool:
	if outcome != "" or not RESULTS.has(result): return false
	if result in ["resolve","contain"] and (phase != 7 or step_index != 3): return false
	if result in ["partial","retreat"] and phase < 5: return false
	if result == "resolve" and not (cancellation_confirmed and independent_return_confirmed and rescuer_confirmed and lola_covenant_truth_known): return false
	outcome = result
	phase = 7
	tension = 0.0
	encounter_failed = false
	findings = {"cancellation":"Real danger, unequal protection and insufficient review of alternatives.",
		"route":ROUTE.duplicate(),"rescuer":"Sabel's husband confirmed by two independent sources.",
		"river":"Environmental unfinished memory, not victim spirits.",
		"privacy":sabel_public_choice,"lola_acknowledged":lola_covenant_truth_known}
	return true

func to_dict() -> Dictionary:
	return {"schema":6,"phase":phase,"player_position":[player_position.x,player_position.y],
		"night01_outcome":night01_outcome,"night02_outcome":night02_outcome,
		"night03_outcome":night03_outcome,"night04_outcome":night04_outcome,
		"night05_outcome":night05_outcome,"clues":clues.duplicate(true),
		"route_index":route_index,"identity_sources":identity_sources.duplicate(true),
		"cancellation_confirmed":cancellation_confirmed,
		"independent_return_confirmed":independent_return_confirmed,"rescuer_confirmed":rescuer_confirmed,
		"private_sabel_told":private_sabel_told,"sabel_public_choice":sabel_public_choice,
		"lola_covenant_truth_known":lola_covenant_truth_known,"dado_choice":dado_choice,
		"preparations":preparations.duplicate(true),"step_index":step_index,
		"observation":observation,"current_ready":current_ready,
		"tension":tension,"encounter_failed":encounter_failed,
		"wrong_hypotheses":wrong_hypotheses,"outcome":outcome,
		"findings":findings.duplicate(true)}

func from_dict(data: Dictionary) -> bool:
	if int(data.get("schema",-1)) != 6: return false
	var p := int(data.get("phase",-1))
	var ending := str(data.get("outcome",""))
	if p < 0 or p > 7 or (ending != "" and not RESULTS.has(ending)): return false
	for field in ["clues","identity_sources","preparations","findings"]:
		if typeof(data.get(field)) != TYPE_DICTIONARY: return false
	var restored_clues: Dictionary = {}
	for id in CLUES:
		if data["clues"].get(id,false) == true: restored_clues[id] = true
	var restored_identity: Dictionary = {}
	for id in IDENTITY:
		if data["identity_sources"].get(id,false) == true: restored_identity[id] = true
	var restored_prep: Dictionary = {}
	for id in PREPARATIONS:
		if data["preparations"].get(id,false) == true: restored_prep[id] = true
	var route := int(data.get("route_index",0))
	var step := int(data.get("step_index",0))
	if route < 0 or route > 3 or step < 0 or step > 3: return false
	if p >= 1 and restored_clues.size() != 4: return false
	if p >= 2 and not bool(data.get("cancellation_confirmed",false)): return false
	if p >= 3 and (route != 3 or not bool(data.get("independent_return_confirmed",false))): return false
	if p >= 4 and (restored_identity.size() != 2 or not bool(data.get("rescuer_confirmed",false))): return false
	if p >= 5 and (not bool(data.get("private_sabel_told",false)) or not bool(data.get("lola_covenant_truth_known",false))): return false
	if p >= 6 and restored_prep.size() != 3: return false
	if p == 6 and step >= 3: return false
	if p == 7 and ending == "" and step != 3: return false
	if ending in ["resolve","contain"] and step != 3: return false
	clues = restored_clues
	identity_sources = restored_identity
	preparations = restored_prep
	phase = p
	route_index = route
	step_index = step
	cancellation_confirmed = bool(data.get("cancellation_confirmed",false))
	independent_return_confirmed = bool(data.get("independent_return_confirmed",false))
	rescuer_confirmed = bool(data.get("rescuer_confirmed",false))
	private_sabel_told = bool(data.get("private_sabel_told",false))
	sabel_public_choice = str(data.get("sabel_public_choice","private"))
	if not ["private","written","consent_public"].has(sabel_public_choice): sabel_public_choice = "private"
	lola_covenant_truth_known = bool(data.get("lola_covenant_truth_known",false))
	dado_choice = str(data.get("dado_choice","unasked"))
	if not ["unasked","private","decline"].has(dado_choice): dado_choice = "unasked"
	observation = clampf(float(data.get("observation",0.0)),0,1)
	current_ready = bool(data.get("current_ready",false)) if p == 6 else false
	tension = clampf(float(data.get("tension",0.0)),0,.99)
	encounter_failed = bool(data.get("encounter_failed",false)) if p == 6 else false
	wrong_hypotheses = maxi(0,int(data.get("wrong_hypotheses",0)))
	outcome = ending
	findings = data["findings"].duplicate(true)
	night01_outcome = str(data.get("night01_outcome",""))
	night02_outcome = str(data.get("night02_outcome",""))
	night03_outcome = str(data.get("night03_outcome",""))
	night04_outcome = str(data.get("night04_outcome",""))
	night05_outcome = str(data.get("night05_outcome",""))
	player_position = START
	var raw: Variant = data.get("player_position",[START.x,START.y])
	if typeof(raw) == TYPE_ARRAY and raw.size() == 2:
		var position := Vector2(float(raw[0]),float(raw[1]))
		if position.is_finite() and absf(position.x)<1400 and absf(position.y)<1100: player_position = position
	return true
