extends RefCounted
## NIGHT 2 — The Giant in the Mango Tree. Canonical: safety FIRST,
## observation SECOND, respectful negotiation THIRD; no supernatural "proof"
## replaces a real expert assessment of the endangered public route.
const REQUIRED_CLUES := ["fallen_limb", "exposed_roots", "cigar_ash", "shelter_route", "witness_accounts"]
const RESULTS := ["resolve", "partial", "retreat"]
const BARRIER_POSITIONS := ["west_approach", "south_approach", "shelter_turn"]

var night1_outcome := ""
var player_position := Vector2(-510, 140)
var clues: Dictionary = {}
var warnings: Dictionary = {}
var barriers: Dictionary = {}
var seen: Dictionary = {}
var phase := 0 # 0 inspect, 1 secure, 2 observe, 3 negotiate, 4 aftermath
var observation := 0.0
var alarm := 0.0
var courage := 100.0
var respectful := false
var offered := ""
var commitment := false
var outcome := ""
var incident_count := 0
var bestiary: Dictionary = {}
var committed_events: Dictionary = {}
var checkpoint: Dictionary = {}
var encounter_failed := false

func observe(id: String) -> bool:
	if phase != 0 or not REQUIRED_CLUES.has(id) or clues.has(id):
		return false
	clues[id] = true
	return true

func complete_evidence() -> bool:
	for key in REQUIRED_CLUES:
		if not clues.has(key):
			return false
	return true

func begin_safety() -> bool:
	if phase != 0 or not complete_evidence():
		return false
	phase = 1
	checkpoint = _snapshot()
	return true

func close_route(id: String) -> bool:
	if phase != 1 or not BARRIER_POSITIONS.has(id) or barriers.has(id):
		return false
	barriers[id] = true
	return true

func safe_route() -> bool:
	for id in BARRIER_POSITIONS:
		if not barriers.has(id):
			return false
	return true

func begin_observation() -> bool:
	if phase != 1 or not safe_route():
		return false
	phase = 2
	checkpoint = _snapshot()
	return true

func observe_from_safety(delta: float, sheltered: bool, steady: bool) -> bool:
	if phase != 2 or encounter_failed:
		return false
	if sheltered and steady:
		observation = minf(1.0, observation + maxf(delta, 0.0) / 4.0)
		alarm = maxf(0.0, alarm - delta * 0.09)
	else:
		observation = maxf(0.0, observation - delta * 0.055)
	return observation >= .999

func greet_respectfully() -> bool:
	if phase != 2 or observation < .999 or encounter_failed:
		return false
	respectful = true
	phase = 3
	checkpoint = _snapshot()
	return true

func choose_offering(item: String) -> bool:
	if phase != 3 or offered != "":
		return false
	if item not in ["coffee", "tobacco"]:
		alarm = minf(1.0, alarm + .27)
		incident_count += 1
		return false
	offered = item
	alarm = maxf(0.0, alarm - .12)
	return true

func propose_preservation(expert_assessment: bool, alternative_route: bool) -> bool:
	# Dialogue ALONE can never resolve an unsafe tree. The community must
	# consult an expert and redirect the route first.
	if phase != 3 or not respectful or offered == "" or not safe_route() or not complete_evidence():
		return false
	if not expert_assessment or not alternative_route:
		alarm = minf(1.0, alarm + .14)
		return false
	commitment = true
	return true

func danger_tick(delta: float, in_closed_zone: bool, sheltered: bool, assisted: bool = false) -> void:
	if phase >= 4 or encounter_failed:
		return
	if in_closed_zone:
		alarm = minf(1.0, alarm + delta * (.10 if phase < 2 else .16))
		courage = maxf(0.0, courage - delta * 10.0)
	elif sheltered:
		alarm = maxf(0.0, alarm - delta * .055)
		courage = minf(100.0, courage + delta * 3.0)
	if assisted:
		courage = maxf(25.0, courage)
	if courage <= 0.0 or alarm >= 0.99:
		encounter_failed = true

func commit(value: String) -> bool:
	if outcome != "" or not RESULTS.has(value):
		return false
	if value == "resolve":
		if phase != 3 or not commitment or encounter_failed:
			return false
	elif value == "partial":
		if phase < 1 or not safe_route():
			return false
	else:
		# Safe withdrawal is always possible. If safety tape was placed,
		# the community can still benefit from the precaution.
		if phase == 4:
			return false
	outcome = value
	phase = 4
	encounter_failed = false
	committed_events["n2_kapre_" + value] = true
	bestiary["kapre"] = {
		"result": value,
		"observed": ["fallen_limb", "exposed_roots", "cigar_ash"],
		"interpretation": "A figure by the old mango tree. The roots and limbs pose a real public hazard; the giant's history remains a witness account.",
		"promise": commitment
	}
	return true

func safe_retry() -> bool:
	if checkpoint.is_empty() or outcome != "":
		return false
	var cp := checkpoint.duplicate(true)
	if not from_dict(cp):
		return false
	encounter_failed = false
	alarm = maxf(0.0, alarm - .22)
	courage = maxf(45.0, courage)
	return true

func _snapshot() -> Dictionary:
	var d := to_dict()
	d["checkpoint"] = {}
	return d

func to_dict() -> Dictionary:
	return {
		"schema": 2, "night1_outcome": night1_outcome,
		"player_position": [player_position.x, player_position.y],
		"clues": clues.duplicate(true), "warnings": warnings.duplicate(true),
		"barriers": barriers.duplicate(true), "seen": seen.duplicate(true),
		"phase": phase, "observation": observation, "alarm": alarm,
		"courage": courage, "respectful": respectful, "offered": offered,
		"commitment": commitment, "outcome": outcome,
		"incident_count": incident_count, "bestiary": bestiary.duplicate(true),
		"committed_events": committed_events.duplicate(true),
		"encounter_failed": encounter_failed, "checkpoint": checkpoint.duplicate(true)
	}

func from_dict(d: Dictionary) -> bool:
	if int(d.get("schema", -1)) != 2:
		return false
	var p := int(d.get("phase", -1))
	var result := str(d.get("outcome", ""))
	if p < 0 or p > 4 or (result != "" and (not RESULTS.has(result) or p != 4)):
		return false
	for field in ["clues", "warnings", "barriers", "seen", "bestiary", "committed_events"]:
		if typeof(d.get(field)) != TYPE_DICTIONARY:
			return false
	var raw_clues: Dictionary = d["clues"]
	var raw_barriers: Dictionary = d["barriers"]
	clues.clear()
	barriers.clear()
	for id in REQUIRED_CLUES:
		if raw_clues.get(id, false) == true:
			clues[id] = true
	for id in BARRIER_POSITIONS:
		if raw_barriers.get(id, false) == true:
			barriers[id] = true
	phase = p
	outcome = result
	night1_outcome = str(d.get("night1_outcome", ""))
	var pos_data = d.get("player_position", [-510.0, 140.0])
	if typeof(pos_data) == TYPE_ARRAY and pos_data.size() == 2:
		var pos := Vector2(float(pos_data[0]), float(pos_data[1]))
		if pos.is_finite() and absf(pos.x) <= 950.0 and absf(pos.y) <= 730.0:
			player_position = pos
	warnings = d["warnings"].duplicate(true)
	seen = d["seen"].duplicate(true)
	observation = clampf(float(d.get("observation", 0.0)), 0.0, 1.0)
	alarm = clampf(float(d.get("alarm", 0.0)), 0.0, 1.0)
	courage = clampf(float(d.get("courage", 100.0)), 0.0, 100.0)
	respectful = bool(d.get("respectful", false))
	offered = str(d.get("offered", ""))
	commitment = bool(d.get("commitment", false))
	incident_count = maxi(int(d.get("incident_count", 0)), 0)
	bestiary = d["bestiary"].duplicate(true) if result != "" else {}
	committed_events = {"n2_kapre_" + result: true} if result != "" else {}
	encounter_failed = bool(d.get("encounter_failed", false)) if result == "" else false
	checkpoint = {}
	var raw_cp = d.get("checkpoint", {})
	if result == "" and typeof(raw_cp) == TYPE_DICTIONARY and int(raw_cp.get("phase", -1)) in [1, 2, 3]:
		checkpoint = raw_cp.duplicate(true)
	return true
