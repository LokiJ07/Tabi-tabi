extends RefCounted
## Night 3 / The False Trail: the Great Flood rescue-route mystery continues.
## Never mistake a supernatural account for physical proof. Guide people home
## by preserving evidence, marking safe crossings, and checking the real map.
const CLUES := ["washed_rope","bridge_map","heel_marks","rescuer_note"]
const MARKERS := ["river_stones","old_watchpost","bamboo_diversion"]
const RESULTS := ["resolve","partial","retreat"]
const CORRECT_ROUTE := "river_stones"
const START := Vector2(-730,310)

var night01_outcome := ""
var night02_outcome := ""
var player_position := START
var clues: Dictionary = {}
var markers: Dictionary = {}
var seen: Dictionary = {}
var phase := 0 # evidence -> path safety -> night observation -> route -> witness -> aftermath
var observation := 0.0
var false_turns := 0
var tension := 0.0
var courage := 100.0
var route_verified := false
var respectful := false
var truth_recorded := false
var outcome := ""
var checkpoint: Dictionary = {}
var encounter_failed := false
var bestiary: Dictionary = {}
var committed_events: Dictionary = {}

func inspect(id: String) -> bool:
	if phase != 0 or not CLUES.has(id) or clues.has(id):
		return false
	clues[id] = true
	if all_clues():
		phase = 1
		checkpoint = _snapshot()
	return true

func all_clues() -> bool:
	for id in CLUES:
		if not clues.has(id):
			return false
	return true

func mark_route(id: String) -> bool:
	if phase != 1 or not MARKERS.has(id) or markers.has(id):
		return false
	# A route marked out of order can lead rescuers into unconfirmed terrain.
	var needed: String = MARKERS[markers.size()]
	if needed != id:
		false_turns += 1
		tension = minf(0.92,tension+.11)
		return false
	markers[id] = true
	if markers.size() == MARKERS.size():
		phase = 2
		checkpoint = _snapshot()
	return true

func route_safe() -> bool:
	for id in MARKERS:
		if not markers.has(id):
			return false
	return true

func observe(delta: float, sheltered: bool, steady: bool) -> bool:
	if phase != 2 or encounter_failed:
		return false
	if sheltered and steady:
		observation = minf(1.0,observation+maxf(0.0,delta)/3.2)
		tension = maxf(0.0,tension-delta*.075)
	else:
		observation = maxf(0.0,observation-delta*.065)
	if observation >= .999:
		phase = 3
		checkpoint = _snapshot()
		return true
	return false

func decide_route(value: String) -> bool:
	if phase != 3 or encounter_failed or value not in ["river_stones","blue_lanterns","hoofprints"]:
		return false
	if value != CORRECT_ROUTE:
		false_turns += 1
		tension = minf(0.95,tension+.16)
		courage = maxf(25.0,courage-12.0)
		return false
	if not all_clues() or not route_safe():
		return false
	route_verified = true
	phase = 4
	checkpoint = _snapshot()
	return true

func greet() -> bool:
	if phase != 4 or encounter_failed or not route_verified:
		return false
	respectful = true
	return true

func record_truth() -> bool:
	if phase != 4 or not respectful or not route_verified:
		return false
	truth_recorded = true
	tension = maxf(0.0,tension-.24)
	return true

func danger_tick(delta: float, false_path: bool, sheltered: bool, assisted: bool = false) -> void:
	if phase >= 5 or encounter_failed:
		return
	if false_path and phase > 0:
		tension = minf(1.0,tension+delta*.085)
		courage = maxf(0.0,courage-delta*6.0)
	elif sheltered:
		tension = maxf(0.0,tension-delta*.07)
		courage = minf(100.0,courage+delta*2.5)
	if assisted:
		courage = maxf(22.0,courage)
	if courage <= 0.0 or tension >= .99:
		encounter_failed = true

func commit(value: String) -> bool:
	if outcome != "" or not RESULTS.has(value):
		return false
	if value == "resolve":
		if phase != 4 or not respectful or not truth_recorded or not route_verified or encounter_failed:
			return false
	elif value == "partial":
		if not route_safe() or not route_verified or phase < 4:
			return false
	else:
		if phase == 5:
			return false
	outcome = value
	phase = 5
	encounter_failed = false
	committed_events["n3_tikbalang_"+value] = true
	bestiary["tikbalang"] = {
		"result":value,
		"route":CORRECT_ROUTE if route_verified else "unverified",
		"observed":["washed_rope","bridge_map","heel_marks","rescuer_note"],
		"certainty":"False signs and flood scars are observable. The ridge guardian's origin remains a witness account.",
		"truth_recorded":truth_recorded
	}
	return true

func retry_checkpoint() -> bool:
	if outcome != "":
		return false
	if not checkpoint.is_empty():
		var restored: Dictionary = checkpoint.duplicate(true)
		if not from_dict(restored):
			return false
	encounter_failed = false
	courage = maxf(courage,56.0)
	tension = minf(tension,.22)
	return true

func _snapshot() -> Dictionary:
	var snap := to_dict()
	snap["checkpoint"] = {}
	return snap

func to_dict() -> Dictionary:
	return {
		"schema":3,"night01_outcome":night01_outcome,"night02_outcome":night02_outcome,
		"player_position":[player_position.x,player_position.y],
		"clues":clues.duplicate(true),"markers":markers.duplicate(true),
		"seen":seen.duplicate(true),"phase":phase,"observation":observation,
		"false_turns":false_turns,"tension":tension,"courage":courage,
		"route_verified":route_verified,"respectful":respectful,
		"truth_recorded":truth_recorded,"outcome":outcome,
		"checkpoint":checkpoint.duplicate(true),"encounter_failed":encounter_failed,
		"bestiary":bestiary.duplicate(true),"committed_events":committed_events.duplicate(true)
	}

func from_dict(data: Dictionary) -> bool:
	if int(data.get("schema",-1)) != 3:
		return false
	var new_phase := int(data.get("phase",-1))
	var new_outcome := str(data.get("outcome",""))
	if new_phase < 0 or new_phase > 5 or (new_outcome != "" and (new_phase != 5 or not RESULTS.has(new_outcome))) or (new_phase == 5 and new_outcome == ""):
		return false
	for key in ["clues","markers","seen","bestiary","committed_events","checkpoint"]:
		if typeof(data.get(key)) != TYPE_DICTIONARY:
			return false
	var new_clues: Dictionary = {}
	var new_markers: Dictionary = {}
	for id in CLUES:
		if data["clues"].get(id,false) == true:
			new_clues[id] = true
	for id in MARKERS:
		if data["markers"].get(id,false) == true:
			new_markers[id] = true
	# Chapter phases may not be forged by a corrupt save.
	if new_phase >= 1 and new_clues.size() != CLUES.size():
		return false
	if new_phase >= 2 and new_markers.size() != MARKERS.size():
		return false
	if new_phase >= 3 and float(data.get("observation",0.0)) < .999:
		return false
	if new_phase >= 4 and not bool(data.get("route_verified",false)):
		return false
	var player_at := START
	var coords = data.get("player_position",[START.x,START.y])
	if typeof(coords) == TYPE_ARRAY and coords.size() == 2:
		player_at = Vector2(float(coords[0]),float(coords[1]))
		if not player_at.is_finite() or absf(player_at.x) > 1400.0 or absf(player_at.y) > 1150.0:
			player_at = START
	clues = new_clues
	markers = new_markers
	seen = data["seen"].duplicate(true)
	phase = new_phase
	outcome = new_outcome
	night01_outcome = str(data.get("night01_outcome",""))
	night02_outcome = str(data.get("night02_outcome",""))
	player_position = player_at
	observation = clampf(float(data.get("observation",0.0)),0.0,1.0)
	false_turns = clampi(int(data.get("false_turns",0)),0,999)
	tension = clampf(float(data.get("tension",0.0)),0.0,1.0)
	courage = clampf(float(data.get("courage",100.0)),0.0,100.0)
	route_verified = bool(data.get("route_verified",false))
	respectful = bool(data.get("respectful",false))
	truth_recorded = bool(data.get("truth_recorded",false))
	encounter_failed = bool(data.get("encounter_failed",false)) if new_outcome == "" else false
	committed_events = {"n3_tikbalang_"+new_outcome:true} if new_outcome != "" else {}
	bestiary = data["bestiary"].duplicate(true) if new_outcome != "" else {}
	checkpoint = {}
	if new_outcome == "" and int(data["checkpoint"].get("phase",-1)) in [1,2,3,4]:
		checkpoint = data["checkpoint"].duplicate(true)
	return true
