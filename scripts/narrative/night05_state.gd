extends RefCounted
## Tabi-tabi Night 5 — Sigbin: The Abandoned Farm.
## A once-familiar guardian, not a violent boss. Fear comes from misreading
## connected shadows, a decaying barn and animals trapped by an old promise.
const CLUES := ["backward_tracks","unbroken_fence","caretaker_photo","broken_barn"]
const PREPARATIONS := ["stable_perimeter","safe_gate","lantern_west","lantern_north","lantern_east"]
const SHADOW_ROUTES := ["barn_eave","missing_wall","livestock_pen"]
const CORRECT_LIGHTS := ["lantern_west","lantern_north","lantern_east"]
const RESULTS := ["resolve","safe_rescue","partial","retreat"]
const START := Vector2(-810,340)
const ANIMAL_GROUPS := ["goats_one","goats_two","chickens"]

var night01_outcome := ""
var night02_outcome := ""
var night03_outcome := ""
var night04_outcome := ""
var player_position := START
var clues: Dictionary = {}
var preparations: Dictionary = {}
var seen: Dictionary = {}
var phase := 0 # 0 investigate, 1 interpret, 2 prepare, 3 rescue, 4 aftermath, 5 recorded
var guardian_verified := false
var respect := 55
var fear := .0
var shadow_index := 0
var observation_progress := .0
var shadow_identified := false
var rescued_groups := 0
var mistakes := 0
var unsafe_entry_attempts := 0
var encounter_failed := false
var outcome := ""
var bestiary: Dictionary = {}
var checkpoint: Dictionary = {}

func inspect(id: String) -> bool:
	if phase != 0 or not CLUES.has(id) or clues.has(id):
		return false
	clues[id] = true
	if clues.size() == CLUES.size():
		phase = 1
	return true

func deduce(answer: String) -> bool:
	if phase != 1 or outcome != "":
		return false
	if answer != "guardian":
		mistakes += 1
		fear = minf(.80,fear+.08)
		respect = maxi(0,respect-4)
		return false
	guardian_verified = true
	phase = 2
	return true

func prepare(id: String) -> bool:
	if phase != 2 or not PREPARATIONS.has(id) or preparations.has(id):
		return false
	preparations[id] = true
	return true

func can_begin_rescue() -> bool:
	if phase != 2 or not guardian_verified:
		return false
	for id in PREPARATIONS:
		if not preparations.has(id):
			return false
	return true

func enter_unstable_barn() -> bool:
	# Always refuse. The old supports and missing planks are genuinely unsafe;
	# it is never rewarded by a clue, a shortcut, a goat, or a better ending.
	unsafe_entry_attempts += 1
	return false

func begin_rescue() -> bool:
	if not can_begin_rescue():
		return false
	phase = 3
	shadow_index = 0
	observation_progress = .0
	shadow_identified = false
	encounter_failed = false
	fear = minf(fear,.25)
	checkpoint = to_dict()
	checkpoint["checkpoint"] = {}
	return true

func current_shadow() -> String:
	if phase != 3 or shadow_index >= SHADOW_ROUTES.size():
		return ""
	return str(SHADOW_ROUTES[shadow_index])

func observe_tick(delta: float,safe_position: bool,focused: bool,assist: bool = false) -> bool:
	if phase != 3 or outcome != "" or encounter_failed or shadow_identified:
		return false
	if safe_position and focused:
		observation_progress = minf(1.0,observation_progress+maxf(delta,0.0)/1.20)
		fear = maxf(.0,fear-maxf(delta,0.0)*.020)
	else:
		fear = minf(.99,fear+maxf(delta,0.0)*(.021 if assist else .038))
	# The same 1.2-second safe observation now confirms three distinct
	# folktale-inspired clues. It does not require grinding or extra buttons.
	if observation_progress >= .24:
		seen["sigbin_odor"] = true
	if observation_progress >= .53:
		seen["sigbin_ear_clap"] = true
	if observation_progress >= .80:
		seen["sigbin_reverse_steps"] = true
	if observation_progress >= .999 and sigbin_signs_confirmed():
		shadow_identified = true
		return true
	if fear >= .98:
		encounter_failed = true # Nonfatal, recoverable from perimeter.
	return false

func sigbin_signs_confirmed() -> bool:
	return seen.has("sigbin_odor") and seen.has("sigbin_ear_clap") and seen.has("sigbin_reverse_steps")

func respond(light_id: String) -> bool:
	if phase != 3 or encounter_failed or not shadow_identified:
		return false
	if shadow_index >= CORRECT_LIGHTS.size():
		return false
	if light_id != CORRECT_LIGHTS[shadow_index]:
		mistakes += 1
		fear = minf(.98,fear+.13)
		return false
	# Lamp changes the connection of the shadow; the Sigbin moves away from
	# the animal path. Rescue one group, not an instant all-animals teleport.
	rescued_groups += 1
	shadow_index += 1
	shadow_identified = false
	observation_progress = 0.0
	fear = maxf(.0,fear-.22)
	if shadow_index == SHADOW_ROUTES.size():
		phase = 4
		checkpoint = {}
	return true

func retry_safe_perimeter() -> bool:
	if phase != 3 or not encounter_failed or outcome != "":
		return false
	# Keep earned evidence, safe preparations and the groups already moved.
	# Retry only the *current* shadow node, not the whole night.
	encounter_failed = false
	shadow_identified = false
	observation_progress = 0.0
	fear = .19
	return true

func commit(result: String) -> bool:
	if outcome != "" or not RESULTS.has(result):
		return false
	if result == "resolve" and (phase != 4 or rescued_groups != 3 or mistakes > 0):
		return false
	if result == "safe_rescue" and (phase != 4 or rescued_groups != 3):
		return false
	if result == "partial" and (phase != 4 or rescued_groups < 2):
		return false
	if result == "retreat" and phase == 5:
		return false
	outcome = result
	phase = 5
	fear = 0.0
	encounter_failed = false
	respect = clampi(respect+(12 if result == "resolve" else 6 if result == "safe_rescue" else -2),0,100)
	bestiary["sigbin"] = {
		"result":result,
		"interpretation":"A once-familiar family protector, not a livestock killer.",
		"rescue_groups":rescued_groups,
		"shadows":SHADOW_ROUTES.duplicate(),
		"safe_perimeter":true,
		"old_bond":"The absent caretaker left a promise without a safe place to keep it.",
		"observed_signs":["odor","ear_clap","backward_tracks"],
		"folklore_note":"Visayan and Mindanao tellings vary by locality."
	}
	return true

func to_dict() -> Dictionary:
	return {"schema":5,"night01_outcome":night01_outcome,
		"night02_outcome":night02_outcome,"night03_outcome":night03_outcome,
		"night04_outcome":night04_outcome,
		"player_position":[player_position.x,player_position.y],
		"clues":clues.duplicate(true),"preparations":preparations.duplicate(true),
		"seen":seen.duplicate(true),"phase":phase,"guardian_verified":guardian_verified,
		"respect":respect,"fear":fear,"shadow_index":shadow_index,
		"observation_progress":observation_progress,"shadow_identified":shadow_identified,
		"rescued_groups":rescued_groups,"mistakes":mistakes,
		"unsafe_entry_attempts":unsafe_entry_attempts,
		"encounter_failed":encounter_failed,"outcome":outcome,
		"bestiary":bestiary.duplicate(true),"checkpoint":checkpoint.duplicate(true)}

func from_dict(data: Dictionary) -> bool:
	if int(data.get("schema",-1)) != 5:
		return false
	var p := int(data.get("phase",-1))
	var result := str(data.get("outcome",""))
	if p < 0 or p > 5 or (result != "" and not RESULTS.has(result)):
		return false
	if (p == 5) != (result != ""):
		return false
	for key in ["clues","preparations","seen","bestiary","checkpoint"]:
		if typeof(data.get(key)) != TYPE_DICTIONARY:
			return false
	var imported_clues: Dictionary = {}
	for id in CLUES:
		if data["clues"].get(id,false) == true:
			imported_clues[id] = true
	var imported_prep: Dictionary = {}
	for id in PREPARATIONS:
		if data["preparations"].get(id,false) == true:
			imported_prep[id] = true
	if p >= 1 and result != "retreat" and imported_clues.size() != CLUES.size():
		return false
	if p >= 2 and result != "retreat" and not bool(data.get("guardian_verified",false)):
		return false
	if p in [3,4,5] and result != "retreat" and imported_prep.size() != PREPARATIONS.size():
		return false
	var n := int(data.get("shadow_index",0))
	var count := int(data.get("rescued_groups",0))
	if n < 0 or n > 3 or count < 0 or count > 3 or n != count:
		return false
	if p == 4 and n != 3:
		return false
	if p == 3 and n >= 3:
		return false
	clues = imported_clues
	preparations = imported_prep
	seen = data["seen"].duplicate(true)
	phase = p
	guardian_verified = bool(data.get("guardian_verified",false))
	respect = clampi(int(data.get("respect",55)),0,100)
	fear = clampf(float(data.get("fear",0.0)),0.0,.99)
	shadow_index = n
	rescued_groups = count
	observation_progress = clampf(float(data.get("observation_progress",0.0)),0.0,1.0)
	shadow_identified = bool(data.get("shadow_identified",false)) if p == 3 else false
	mistakes = clampi(int(data.get("mistakes",0)),0,999)
	unsafe_entry_attempts = maxi(0,int(data.get("unsafe_entry_attempts",0)))
	encounter_failed = bool(data.get("encounter_failed",false)) if p == 3 else false
	outcome = result
	night01_outcome = str(data.get("night01_outcome",""))
	night02_outcome = str(data.get("night02_outcome",""))
	night03_outcome = str(data.get("night03_outcome",""))
	night04_outcome = str(data.get("night04_outcome",""))
	bestiary = data["bestiary"].duplicate(true) if result != "" else {}
	checkpoint = data["checkpoint"].duplicate(true) if p == 3 else {}
	player_position = START
	var raw_position = data.get("player_position",[START.x,START.y])
	if typeof(raw_position) == TYPE_ARRAY and raw_position.size() == 2:
		var pos := Vector2(float(raw_position[0]),float(raw_position[1]))
		if pos.is_finite() and absf(pos.x) < 1500.0 and absf(pos.y) < 1100.0:
			player_position = pos
	return true
