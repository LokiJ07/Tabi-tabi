extends RefCounted
## Night 7 — The Ancient Keeper's Trial. Final evidence, accountable action,
## three fair environmental phases and four distinct non-lethal endings.
## The Keeper is an original fictional being with limited knowledge and reach.
const START := Vector2(-905,337)
const FACTS := ["cancelled_rescue","returning_boat","limited_refuge"]
const COMMITMENTS := ["correct_archive","protect_witnesses","family_memorial"]
const PATH_CUES := ["lantern_in_fog","bantay_tracks","stable_root"]
const PATH_RESPONSES := ["raise_lantern","follow_bantay","cross_root"]
const TRUTH_RESPONSES := ["real_danger_unequal_choice","independent_rescue","high_refuge_only"]
const AWAKENED_CUES := ["root_surge","falling_canopy","village_boundary"]
const AWAKENED_RESPONSES := ["anchor_rope","raise_lantern","shield_neighbors"]
const ENDINGS := ["true","good","bittersweet","dark"]
const ALLY_OUTCOMES := {
	"night01":["resolve","guide","contain"],
	"night02":["resolve","negotiate"],
	"night03":["resolve","guide"],
	"night04":["resolve","drive_away"],
	"night05":["resolve","safe_rescue"],
	"night06":["resolve","contain"]
}
var night01_outcome := ""
var night02_outcome := ""
var night03_outcome := ""
var night04_outcome := ""
var night05_outcome := ""
var night06_outcome := ""
var sabel_privacy := "private"
var lola_is_living := true # Do not infer her death from the finale's ending.
var previous_facts: Dictionary = {}
var player_position := START
var phase := 0 # readiness, gathering, keeper, path, truth, awakened, choice, epilogue
var notebook_checked := false
var acknowledged_uncertainty := false
var ready_confirmed := false
var presented: Dictionary = {}
var commitments: Dictionary = {}
var public_acknowledged := false
var sabel_choice_respected := false
var lola_reflected := false
var meeting_complete := false
var keeper_seen := false
var path_index := 0
var truth_index := 0
var awake_index := 0
var observation := 0.0
var warning_ready := false
var danger := 0.0
var encounter_failed := false
var mistakes := 0
var denial_warning_seen := false
var community_fractured := false
var outcome := ""
var ending_record: Dictionary = {}
var epilogue_spoken: Dictionary = {}
var finished := false

func prior_outcomes() -> Dictionary:
	return {"night01":night01_outcome,"night02":night02_outcome,
		"night03":night03_outcome,"night04":night04_outcome,
		"night05":night05_outcome,"night06":night06_outcome}

func previous_fact_verified(id: String) -> bool:
	return FACTS.has(id) and previous_facts.get(id,false) == true

func readiness_missing() -> Array[String]:
	var missing: Array[String] = []
	if night06_outcome == "":
		missing.append("Complete or safely retreat from the Night 6 river case.")
	for id in FACTS:
		if not previous_fact_verified(id):
			missing.append("Historical source not yet independently verified: "+id.replace("_"," "))
	if not notebook_checked: missing.append("Review the final notebook.")
	if not acknowledged_uncertainty: missing.append("Review uncertainty and witness confidentiality.")
	return missing

func review_notebook() -> void:
	notebook_checked = true

func acknowledge_privacy() -> void:
	acknowledged_uncertainty = true

func begin_final_trial() -> bool:
	# Missing side clues never become a hidden ending count. Required is only
	# an actual completed Night 6 record + explicit informed player consent.
	if phase != 0 or night06_outcome == "" or not notebook_checked or not acknowledged_uncertainty:
		return false
	ready_confirmed = true
	phase = 1
	return true

func recover_fact(id: String, source: String) -> bool:
	if phase != 1 or not FACTS.has(id) or previous_fact_verified(id):
		return false
	# Only an existing, clearly identified record can restore a missing fact.
	# The community cannot just select a magic 'make history true' dialogue.
	if source != "archive_corrob":
		return false
	previous_facts[id] = true
	return true

func present_fact(id: String) -> bool:
	if phase != 1 or not previous_fact_verified(id) or presented.has(id): return false
	presented[id] = true
	return true

func confirm_commitment(id: String) -> bool:
	if phase != 1 or not COMMITMENTS.has(id) or commitments.has(id): return false
	if id == "family_memorial" and not sabel_choice_respected:
		return false
	commitments[id] = true
	return true

func respect_sabel() -> bool:
	if phase != 1 or sabel_choice_respected: return false
	sabel_choice_respected = true
	return true

func reflect_with_lola() -> bool:
	if phase != 1 or lola_reflected: return false
	lola_reflected = true
	return true

func acknowledge_public_record() -> bool:
	# A truthful public record may anonymize witnesses and does not require
	# Sabel's appearance. Respect her private remembrance even in True ending.
	if phase != 1 or presented.is_empty() or not sabel_choice_respected:
		return false
	public_acknowledged = true
	return true

func conclude_gathering() -> bool:
	if phase != 1 or not sabel_choice_respected or presented.is_empty() or not public_acknowledged:
		return false
	meeting_complete = true
	phase = 2
	return true

func reveal_keeper() -> bool:
	if phase != 2 or not meeting_complete: return false
	keeper_seen = true
	phase = 3
	observation = 0.0
	danger = .1
	warning_ready = false
	return true

func observe_tick(delta: float, safe: bool, held: bool, assist: bool = false) -> bool:
	if (phase != 3 and phase != 5) or outcome != "" or encounter_failed or warning_ready:
		return false
	if safe and held:
		observation = minf(1.0,observation+maxf(0.0,delta)/1.1)
		danger = maxf(0.0,danger-maxf(0.0,delta)*.025)
	else:
		danger = minf(.99,danger+maxf(0.0,delta)*(.019 if assist else .034))
	if observation >= .999:
		warning_ready = true
		return true
	if danger >= .98: encounter_failed = true
	return false

func unsafe_step() -> void:
	if phase in [3,5] and not encounter_failed:
		danger = minf(.99,danger+.09)
		if danger >= .98: encounter_failed = true

func retry_checkpoint() -> bool:
	if phase not in [3,5] or not encounter_failed or outcome != "": return false
	encounter_failed = false
	warning_ready = false
	observation = 0.0
	danger = .22
	return true

func respond_path(id: String) -> bool:
	if phase != 3 or encounter_failed or not warning_ready or path_index >= 3: return false
	if id != PATH_RESPONSES[path_index]:
		mistakes += 1
		danger = minf(.98,danger+.09)
		return false
	path_index += 1
	warning_ready = false
	observation = 0.0
	danger = maxf(0.0,danger-.18)
	if path_index == 3:
		phase = 4
	return true

func present_truth(id: String) -> bool:
	if phase != 4 or truth_index >= FACTS.size(): return false
	if id != FACTS[truth_index] or not presented.has(id):
		mistakes += 1
		return false
	truth_index += 1
	if truth_index == FACTS.size():
		phase = 5
		awake_index = 0
		observation = 0.0
		danger = .16
	return true

func admit_truth_gap() -> bool:
	# Missing optional corroboration cannot permanently strand the player.
	# Keeper hears *uncertainty*, not an invented factual answer.
	if phase != 4 or truth_index >= FACTS.size():
		return false
	var id: String = FACTS[truth_index]
	if presented.has(id): return false
	truth_index += 1
	if truth_index == 3:
		phase = 5
		awake_index = 0
		observation = 0.0
		danger = .16
	return true

func respond_awakened(id: String) -> bool:
	if phase != 5 or not warning_ready or encounter_failed or awake_index >= 3: return false
	if id != AWAKENED_RESPONSES[awake_index]:
		mistakes += 1
		danger = minf(.98,danger+.11)
		return false
	awake_index += 1
	warning_ready = false
	observation = 0.0
	danger = maxf(0.0,danger-.24)
	if awake_index == 3:
		phase = 6
	return true

func qualifies_true() -> bool:
	# Deliberately NOT a numeric Night 1–6 resolve counter.
	# All essential *claims* must be evidenced and honestly acknowledged;
	# community actions must actually be undertaken.
	return presented.size() == 3 and commitments.size() == 3 and public_acknowledged \
		and sabel_choice_respected and meeting_complete and truth_index == 3

func offer_outcomes() -> Array[String]:
	if phase != 6 or outcome != "": return []
	var choices: Array[String] = []
	if qualifies_true(): choices.append("true")
	choices.append("good")
	if public_acknowledged and presented.size() >= 2: choices.append("bittersweet")
	choices.append("dark") # Deliberate, separately confirmed only.
	return choices

func warn_denial() -> bool:
	if phase != 6: return false
	denial_warning_seen = true
	return true

func commit(result: String) -> bool:
	if phase != 6 or outcome != "" or not ENDINGS.has(result): return false
	if not offer_outcomes().has(result): return false
	if result == "dark" and not denial_warning_seen: return false
	outcome = result
	community_fractured = result == "bittersweet"
	phase = 7
	encounter_failed = false
	danger = 0.0
	ending_record = {
		"result":result,
		"verified":presented.duplicate(true),
		"committed":commitments.duplicate(true),
		"public_record":public_acknowledged,
		"privacy":sabel_privacy,
		"lola_living":lola_is_living,
		"lola_account":lola_reflected,
		"community_cooperation_fractured":community_fractured,
		"villagers_return_safely":true,
		"keeper_is_limited":true
	}
	return true

func earned_allies() -> Array[String]:
	var allies: Array[String] = []
	var past: Dictionary = prior_outcomes()
	for night in ["night01","night02","night03","night04","night05","night06"]:
		if ALLY_OUTCOMES[night].has(str(past.get(night,""))):
			allies.append(night)
	return allies

func speak_epilogue(id: String) -> bool:
	if phase != 7 or outcome == "" or not ["mara","sabel","dado","lola","river","memorial","bantay"].has(id):
		return false
	epilogue_spoken[id] = true
	return true

func finish_story() -> bool:
	if phase != 7 or outcome == "": return false
	finished = true
	return true

func to_dict() -> Dictionary:
	return {"schema":7,"night01_outcome":night01_outcome,"night02_outcome":night02_outcome,
		"night03_outcome":night03_outcome,"night04_outcome":night04_outcome,
		"night05_outcome":night05_outcome,"night06_outcome":night06_outcome,
		"sabel_privacy":sabel_privacy,"lola_is_living":lola_is_living,
		"previous_facts":previous_facts.duplicate(true),"player_position":[player_position.x,player_position.y],
		"phase":phase,"notebook_checked":notebook_checked,
		"acknowledged_uncertainty":acknowledged_uncertainty,"ready_confirmed":ready_confirmed,
		"presented":presented.duplicate(true),"commitments":commitments.duplicate(true),
		"public_acknowledged":public_acknowledged,"sabel_choice_respected":sabel_choice_respected,
		"lola_reflected":lola_reflected,"meeting_complete":meeting_complete,
		"keeper_seen":keeper_seen,"path_index":path_index,"truth_index":truth_index,
		"awake_index":awake_index,"observation":observation,"warning_ready":warning_ready,
		"danger":danger,"encounter_failed":encounter_failed,"mistakes":mistakes,
		"denial_warning_seen":denial_warning_seen,"community_fractured":community_fractured,
		"outcome":outcome,
		"ending_record":ending_record.duplicate(true),
		"epilogue_spoken":epilogue_spoken.duplicate(true),"finished":finished}

func from_dict(data: Dictionary) -> bool:
	if int(data.get("schema",-1)) != 7: return false
	var p := int(data.get("phase",-1))
	var ending := str(data.get("outcome",""))
	if p < 0 or p > 7 or (ending != "" and not ENDINGS.has(ending)): return false
	for key in ["previous_facts","presented","commitments","ending_record","epilogue_spoken"]:
		if typeof(data.get(key)) != TYPE_DICTIONARY: return false
	if p >= 1 and (not bool(data.get("ready_confirmed",false)) or str(data.get("night06_outcome","")) == ""):
		return false
	if p >= 2 and (not bool(data.get("meeting_complete",false)) or not bool(data.get("public_acknowledged",false))):
		return false
	if p >= 3 and not bool(data.get("keeper_seen",false)): return false
	var pi := int(data.get("path_index",0))
	var ti := int(data.get("truth_index",0))
	var ai := int(data.get("awake_index",0))
	if pi < 0 or pi > 3 or ti < 0 or ti > 3 or ai < 0 or ai > 3: return false
	if p >= 4 and pi != 3: return false
	if p >= 5 and ti != 3: return false
	if p >= 6 and ai != 3: return false
	if p == 7 and ending == "": return false
	if ending != "" and p != 7: return false
	var facts: Dictionary = {}
	for id in FACTS:
		if data["previous_facts"].get(id,false) == true: facts[id] = true
	var known: Dictionary = {}
	for id in FACTS:
		if data["presented"].get(id,false) == true:
			if not facts.has(id): return false
			known[id] = true
	var planned: Dictionary = {}
	for id in COMMITMENTS:
		if data["commitments"].get(id,false) == true:
			planned[id] = true
	if planned.has("family_memorial") and not bool(data.get("sabel_choice_respected",false)): return false
	if ending == "true" and (known.size() != 3 or planned.size() != 3): return false
	if ending == "dark" and not bool(data.get("denial_warning_seen",false)): return false
	if ending == "bittersweet" and (known.size() < 2 or not bool(data.get("community_fractured",false))): return false
	previous_facts = facts
	presented = known
	commitments = planned
	phase = p
	notebook_checked = bool(data.get("notebook_checked",false))
	acknowledged_uncertainty = bool(data.get("acknowledged_uncertainty",false))
	ready_confirmed = bool(data.get("ready_confirmed",false))
	public_acknowledged = bool(data.get("public_acknowledged",false))
	sabel_choice_respected = bool(data.get("sabel_choice_respected",false))
	lola_reflected = bool(data.get("lola_reflected",false))
	meeting_complete = bool(data.get("meeting_complete",false))
	keeper_seen = bool(data.get("keeper_seen",false))
	path_index = pi
	truth_index = ti
	awake_index = ai
	observation = clampf(float(data.get("observation",0.0)),0.0,1.0)
	warning_ready = bool(data.get("warning_ready",false)) if p in [3,5] else false
	danger = clampf(float(data.get("danger",0.0)),0.0,.99)
	encounter_failed = bool(data.get("encounter_failed",false)) if p in [3,5] else false
	mistakes = maxi(0,int(data.get("mistakes",0)))
	denial_warning_seen = bool(data.get("denial_warning_seen",false))
	community_fractured = bool(data.get("community_fractured",false))
	outcome = ending
	ending_record = data["ending_record"].duplicate(true)
	epilogue_spoken = data["epilogue_spoken"].duplicate(true)
	finished = bool(data.get("finished",false)) if p == 7 else false
	for night in ["night01","night02","night03","night04","night05","night06"]:
		set(night+"_outcome",str(data.get(night+"_outcome","")))
	sabel_privacy = str(data.get("sabel_privacy","private"))
	if not ["private","written","consent_public"].has(sabel_privacy):
		sabel_privacy = "private"
	lola_is_living = bool(data.get("lola_is_living",true))
	player_position = START
	var raw: Variant = data.get("player_position",[START.x,START.y])
	if typeof(raw) == TYPE_ARRAY and raw.size() == 2:
		var foot := Vector2(float(raw[0]),float(raw[1]))
		if foot.is_finite() and absf(foot.x)<1500 and absf(foot.y)<1200: player_position=foot
	return true
