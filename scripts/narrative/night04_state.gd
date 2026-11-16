extends RefCounted
## Night 4: THE WAKE. A living community defense mystery, not an enemy HP bar.
## Canon: Aling Nena is a vulnerable caretaker and helper, never the monster.
const CLUES := ["caretaker_schedule","rear_window","rooftop_marks","mourners_accounts"]
const DEFENSES := ["rear_bell","courtyard_lantern","rear_shutter","mara_lookout"]
const WARNINGS := ["roofline","rear_window","courtyard"]
const CORRECT_ACTIONS := ["ring_bell","raise_lantern","escort_group"]
const RESULTS := ["resolve","drive_away","partial","retreat"]
const START := Vector2(-720,330)

var night01_outcome := ""
var night02_outcome := ""
var night03_outcome := ""
var player_position := START
var clues: Dictionary = {}
var defenses: Dictionary = {}
var seen: Dictionary = {}
var phase := 0 # investigate / deduce / prepare / protect / aftermath
var target_verified := false
var coffee_served := false
var trust := 58
var tension := 0.0
var attack_index := 0
var warning_progress := 0.0
var warning_ready := false
var protected_count := 0
var mistaken_hypotheses := 0
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

func serve_coffee() -> bool:
	if coffee_served or phase > 1:
		return false
	coffee_served = true
	trust = mini(100,trust+3)
	return true

func deduce_target(id: String) -> bool:
	if phase != 1 or outcome != "":
		return false
	if id != "nena":
		mistaken_hypotheses += 1
		tension = minf(.65,tension+.06)
		return false
	target_verified = true
	phase = 2
	return true

func accuse_guest() -> bool:
	# A public false allegation damages Barrio Trust. No accusation is needed
	# to identify Nena's actual risk: isolation at the rear supply entrance.
	if phase != 1 or outcome != "":
		return false
	trust = maxi(0,trust-12)
	return true

func prepare(id: String) -> bool:
	if phase != 2 or not DEFENSES.has(id) or defenses.has(id):
		return false
	defenses[id] = true
	return true

func begin_siege() -> bool:
	if phase != 2 or not target_verified or defenses.size() < 3:
		return false
	phase = 3
	attack_index = 0
	warning_progress = 0.0
	warning_ready = false
	encounter_failed = false
	tension = minf(tension,.25)
	checkpoint = _snapshot()
	return true

func current_warning() -> String:
	if phase != 3 or attack_index >= WARNINGS.size():
		return ""
	return str(WARNINGS[attack_index])

func observation_tick(delta: float, protected_position: bool, focused: bool, assisted: bool = false) -> bool:
	if phase != 3 or encounter_failed or outcome != "" or warning_ready:
		return false
	if protected_position and focused:
		warning_progress = minf(1.0,warning_progress+maxf(delta,0.0)/1.4)
		tension = maxf(0.0,tension-delta*.025)
	else:
		tension = minf(.99,tension+delta*(.028 if assisted else .045))
	if warning_progress >= .999:
		warning_ready = true
		return true
	if tension >= .98:
		encounter_failed = true # All villagers survive; retry from safe checkpoint.
	return false

func respond(action: String) -> bool:
	if phase != 3 or encounter_failed or not warning_ready:
		return false
	if action != CORRECT_ACTIONS[attack_index]:
		tension = minf(.98,tension+.14)
		return false
	# Villagers reposition; the predator's approach is interrupted. No death.
	protected_count += 1
	attack_index += 1
	warning_ready = false
	warning_progress = 0.0
	tension = maxf(.0,tension-.18)
	if attack_index == WARNINGS.size():
		phase = 4
		checkpoint = {}
	return true

func retry_checkpoint() -> bool:
	if outcome != "" or phase != 3 or not encounter_failed:
		return false
	# Never erase evidence, previous preparations or positive witness records.
	attack_index = 0
	protected_count = 0
	warning_progress = 0.0
	warning_ready = false
	encounter_failed = false
	tension = .20
	return true

func commit(result: String) -> bool:
	if outcome != "" or not RESULTS.has(result):
		return false
	if result == "resolve" and (phase != 4 or protected_count != 3 or defenses.size() != 4):
		return false
	if result == "drive_away" and (phase != 4 or protected_count < 2):
		return false
	if result == "partial" and (phase != 4 or protected_count < 1):
		return false
	if result == "retreat" and (phase == 4 or phase == 5):
		return false
	outcome = result
	phase = 5
	encounter_failed = false
	trust = clampi(trust+(8 if result == "resolve" else 2 if result == "drive_away" else -3),0,100)
	bestiary["manananggal"] = {
		"result": result,
		"target": "Aling Nena" if target_verified else "unverified",
		"certainty": "Physical entry marks and independent witnesses distinguish predator from mourners.",
		"protected": protected_count,
		"warning_routes": WARNINGS.duplicate()
	}
	return true

func _snapshot() -> Dictionary:
	var result := to_dict()
	result["checkpoint"] = {}
	return result

func to_dict() -> Dictionary:
	return {"schema":4,"night01_outcome":night01_outcome,
		"night02_outcome":night02_outcome,"night03_outcome":night03_outcome,
		"player_position":[player_position.x,player_position.y],
		"clues":clues.duplicate(true),"defenses":defenses.duplicate(true),
		"seen":seen.duplicate(true),"phase":phase,"target_verified":target_verified,
		"coffee_served":coffee_served,"trust":trust,"tension":tension,
		"attack_index":attack_index,"warning_progress":warning_progress,
		"warning_ready":warning_ready,"protected_count":protected_count,
		"mistaken_hypotheses":mistaken_hypotheses,
		"encounter_failed":encounter_failed,"outcome":outcome,
		"bestiary":bestiary.duplicate(true),"checkpoint":checkpoint.duplicate(true)}

func from_dict(data: Dictionary) -> bool:
	if int(data.get("schema",-1)) != 4:
		return false
	var next_phase := int(data.get("phase",-1))
	var next_outcome := str(data.get("outcome",""))
	if next_phase < 0 or next_phase > 5 or (next_outcome != "" and not RESULTS.has(next_outcome)):
		return false
	if (next_phase == 5) != (next_outcome != ""):
		return false
	for key in ["clues","defenses","seen","bestiary","checkpoint"]:
		if typeof(data.get(key)) != TYPE_DICTIONARY:
			return false
	var valid_clues: Dictionary = {}
	for id in CLUES:
		if data["clues"].get(id,false) == true:
			valid_clues[id] = true
	var valid_defenses: Dictionary = {}
	for id in DEFENSES:
		if data["defenses"].get(id,false) == true:
			valid_defenses[id] = true
	if next_phase >= 1 and valid_clues.size() != CLUES.size():
		return false
	if next_phase >= 2 and not bool(data.get("target_verified",false)):
		return false
	if next_phase in [3,4] and valid_defenses.size() < 3:
		return false
	var ai := clampi(int(data.get("attack_index",0)),0,WARNINGS.size())
	var count := clampi(int(data.get("protected_count",0)),0,WARNINGS.size())
	if next_phase == 4 and (ai != WARNINGS.size() or count != 3):
		return false
	if next_phase == 3 and ai >= WARNINGS.size():
		return false
	clues = valid_clues
	defenses = valid_defenses
	seen = data["seen"].duplicate(true)
	phase = next_phase
	target_verified = bool(data.get("target_verified",false))
	coffee_served = bool(data.get("coffee_served",false))
	trust = clampi(int(data.get("trust",58)),0,100)
	tension = clampf(float(data.get("tension",0.0)),0.0,.99)
	attack_index = ai
	protected_count = count
	warning_progress = clampf(float(data.get("warning_progress",0.0)),0.0,1.0)
	warning_ready = bool(data.get("warning_ready",false))
	mistaken_hypotheses = clampi(int(data.get("mistaken_hypotheses",0)),0,999)
	encounter_failed = bool(data.get("encounter_failed",false)) if next_phase == 3 else false
	outcome = next_outcome
	night01_outcome = str(data.get("night01_outcome",""))
	night02_outcome = str(data.get("night02_outcome",""))
	night03_outcome = str(data.get("night03_outcome",""))
	bestiary = data["bestiary"].duplicate(true) if outcome != "" else {}
	checkpoint = data["checkpoint"].duplicate(true) if next_phase == 3 else {}
	var pos = data.get("player_position",[START.x,START.y])
	player_position = START
	if typeof(pos) == TYPE_ARRAY and pos.size() == 2:
		var p := Vector2(float(pos[0]),float(pos[1]))
		if p.is_finite() and absf(p.x) < 1300.0 and absf(p.y) < 1000.0:
			player_position = p
	return true
