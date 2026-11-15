extends RefCounted
## Night 1 equipment selection. Four active slots; no RNG, purchase or account.
const CAPACITY := 4
const ITEMS := ["cloth_wrap", "signal_bell", "water_flask", "rope", "spare_wick", "dog_treat"]
const NAMES := {
	"cloth_wrap": "Cloth wrap  |  soften lantern Focus",
	"signal_bell": "Signal bell  |  warn residents / drive away",
	"water_flask": "Water flask  |  take a safe pause",
	"rope": "Dry rope  |  prepare the landing",
	"spare_wick": "Spare wick  |  lantern maintenance",
	"dog_treat": "Bantay snack  |  companion comfort"
}
var selected: Array[String] = ["cloth_wrap", "signal_bell", "water_flask", "rope"]
var used: Dictionary = {}

func is_ready() -> bool:
	return selected.size() == CAPACITY

func has(id: String) -> bool:
	return selected.has(id)

func toggle(id: String) -> bool:
	if not ITEMS.has(id):
		return false
	if selected.has(id):
		selected.erase(id)
		used.erase(id)
		return true
	if selected.size() >= CAPACITY:
		return false
	selected.append(id)
	return true

func consume(id: String) -> bool:
	if not has(id) or used.has(id):
		return false
	used[id] = true
	return true

func is_used(id: String) -> bool:
	return used.has(id)

func to_dict() -> Dictionary:
	return {"selected": selected.duplicate(), "used": used.duplicate(true)}

func from_dict(raw: Variant) -> bool:
	if typeof(raw) != TYPE_DICTIONARY:
		return false
	var raw_selected: Variant = raw.get("selected", [])
	if typeof(raw_selected) != TYPE_ARRAY:
		return false
	var clean: Array[String] = []
	for item in raw_selected:
		if typeof(item) != TYPE_STRING or not ITEMS.has(item) or clean.has(item):
			continue
		if clean.size() >= CAPACITY:
			break
		clean.append(item)
	selected = clean
	used = {}
	var previous: Variant = raw.get("used", {})
	if typeof(previous) == TYPE_DICTIONARY:
		for id in selected:
			if previous.get(id, false) == true:
				used[id] = true
	return true
