extends RefCounted
const FinalState = preload("res://scripts/narrative/night07_state.gd")
const FinalSave = preload("res://scripts/core/night07_save.gd")
## Tabi-tabi is ONE seven-night story with connected regions.
## Regions are streamed as Godot scenes for memory/performance, not separate games.
## All seven nights are connected playable scenes with case-specific gates.
const PATH := "user://tabi_connected_world.json"
const REGIONS := [
	"barrio_lawom", "old_mango", "night03", "night04",
	"night05", "night06", "night07"
]
const SCENES := {
	"barrio_lawom": "res://scenes/main.tscn",
	"old_mango": "res://scenes/night02.tscn",
	"night03": "res://scenes/night03.tscn",
	"night04": "res://scenes/night04.tscn",
	"night05": "res://scenes/night05.tscn",
	"night06": "res://scenes/night06.tscn",
	"night07": "res://scenes/night07.tscn"
}
const CONNECTIONS := {
	"barrio_lawom": ["old_mango"],
	"old_mango": ["barrio_lawom", "night03"],
	"night03": ["old_mango", "night04"],
	"night04": ["night03", "night05"],
	"night05": ["night04", "night06"],
	"night06": ["night05", "night07"],
	"night07": ["night06"]
}
const TRAIL_BARRIO := Vector3(1.0, 0.20, -32.0)
const TRAIL_MANGO := Vector2(-765.0, 485.0)
const ARRIVAL_BARRIO := Vector3(1.0, 0.75, -29.1)
const ARRIVAL_MANGO := Vector2(-635.0, 385.0)
const TRAIL_MANGO_RIDGE := Vector2(800.0, -570.0)
const ARRIVAL_MANGO_RIDGE := Vector2(730.0, -505.0)
const TRAIL_RIDGE := Vector2(-880.0, 410.0)
const ARRIVAL_RIDGE := Vector2(-700.0, 290.0)
const TRAIL_RIDGE_WAKE := Vector2(890.0,-445.0)
const ARRIVAL_RIDGE_WAKE := Vector2(710.0,-485.0)
const TRAIL_WAKE_RIDGE := Vector2(-880.0,420.0)
const ARRIVAL_WAKE := Vector2(-715.0,280.0)
const TRAIL_WAKE_FARM := Vector2(815.0,-185.0)
const ARRIVAL_FARM := Vector2(-810.0,340.0)
const TRAIL_FARM_WAKE := Vector2(-990.0,410.0)
# Canonical physical continuation from the Sigbin farm to the next chapter.
# Canonical Night 5 completion opens the real Night 6 chapter scene.
# Night 7 becomes accessible only after a real Night 6 outcome.
const TRAIL_FARM_NIGHT06 := Vector2(955.0,-470.0)
const ARRIVAL_WAKE_FROM_FARM := Vector2(735.0,-95.0)
const TRAVEL_RANGE_3D := 3.35
const TRAVEL_RANGE_2D := 118.0

static func scene_for(region: String) -> String:
	return str(SCENES.get(region, ""))

static func implemented(region: String) -> bool:
	return SCENES.has(region)

static func adjacent(origin: String, destination: String) -> bool:
	return CONNECTIONS.has(origin) and CONNECTIONS[origin].has(destination)

static func read() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return _fresh()
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return _fresh()
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("schema", -1)) != 1:
		return _fresh()
	var saved: Dictionary = parsed
	if typeof(saved.get("outcomes")) != TYPE_DICTIONARY or typeof(saved.get("pending")) != TYPE_DICTIONARY:
		return _fresh()
	return saved

static func _fresh() -> Dictionary:
	return {"schema": 1, "outcomes": {}, "current": "barrio_lawom", "pending": {}, "visited": {"barrio_lawom": true}}

static func write(data: Dictionary) -> bool:
	if not REGIONS.has(str(data.get("current", ""))):
		return false
	var path := ProjectSettings.globalize_path(PATH)
	var tmp := path + ".tmp"
	var stream := FileAccess.open(tmp, FileAccess.WRITE)
	if stream == null:
		return false
	stream.store_string(JSON.stringify(data))
	stream.flush()
	stream.close()
	# Atomic swap where possible; recover an earlier copy if rename fails.
	var backup := path + ".bak"
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(path, backup) != OK:
			DirAccess.remove_absolute(tmp)
			return false
	if DirAccess.rename_absolute(tmp, path) != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, path)
		return false
	return true

static func free_roam_unlocked() -> bool:
	# The world flag alone is insufficient: a real completed Night 7 save
	# must still exist, with the same ending recorded in the world ledger.
	var record: Dictionary = read()
	if record.get("free_roam",false) != true: return false
	var ending := FinalState.new()
	if not FinalSave.read(ending) or not ending.finished or ending.outcome == "":
		return false
	var outcomes: Dictionary = record.get("outcomes",{})
	return str(outcomes.get("night07","")) == ending.outcome

static func unlock_free_roam() -> bool:
	# Only a genuinely saved, completed Night 7 can unlock the entire map.
	# Also migrates existing post-ending saves without deleting earlier saves.
	var ending := FinalState.new()
	if not FinalSave.read(ending) or not ending.finished or ending.outcome == "":
		return false
	var record: Dictionary = read()
	var outcomes: Dictionary = record.get("outcomes",{})
	# Reopening the title must not rewrite/back up the full world JSON on
	# every session when the unlock has already been safely persisted.
	if record.get("free_roam",false) == true 			and str(outcomes.get("night07","")) == ending.outcome:
		return true
	outcomes["night07"] = ending.outcome
	record["outcomes"] = outcomes
	record["free_roam"] = true
	var visited: Dictionary = record.get("visited",{})
	visited["night07"] = true
	record["visited"] = visited
	return write(record)

static func free_roam_resume_region() -> String:
	if not free_roam_unlocked(): return ""
	var region: String = str(read().get("current","night07"))
	return region if implemented(region) else "night07"

static func choose_free_roam_region(region: String) -> bool:
	# Title-screen chapter choice is optional fast resume. While walking,
	# only adjacent REAL physical paths can stream the next region.
	if not free_roam_unlocked() or not implemented(region):
		return false
	var record := read()
	record["current"] = region
	record["pending"] = {}
	var visited: Dictionary = record.get("visited",{})
	visited[region] = true
	record["visited"] = visited
	return write(record)

static func begin_travel(origin: String, destination: String, last_outcome: String) -> bool:
	# Prevent menu-skipping future chapters and travel between unrelated regions.
	if not adjacent(origin, destination) or not implemented(destination):
		return false
	var exploring: bool = free_roam_unlocked()
	if not exploring and origin == "barrio_lawom" and destination == "old_mango" and last_outcome == "":
		return false
	var data := read()
	# Do not let a player enter Tikbalang's ridge using an arbitrary string
	# or a preview-only scene. The completed Kapre outcome must already be
	# in the canonical one-world ledger and match the independent Night 2 save.
	if not exploring and origin == "old_mango" and destination == "night03":
		var ledger_outcomes: Dictionary = data.get("outcomes", {})
		if last_outcome == "" or str(ledger_outcomes.get("night02","")) != last_outcome:
			return false
	# The wake cannot be entered on a preview-only or forged Night 3 result.
	# Compare the current outcome with the shared connected-world case ledger.
	if not exploring and origin == "night03" and destination == "night04":
		var outcomes: Dictionary = data.get("outcomes", {})
		if last_outcome == "" or str(outcomes.get("night03","")) != last_outcome:
			return false
	# The Sigbin farm opens only from a canonically completed wake.
	# A QA-only scene launch cannot forge a Night 4 outcome in the ledger.
	if not exploring and origin == "night04" and destination == "night05":
		var outcomes: Dictionary = data.get("outcomes", {})
		if last_outcome == "" or str(outcomes.get("night04","")) != last_outcome:
			return false
	# The player cannot enter Night 6 by visiting the road early or forging
	# a result string. It must match the completed Night 5 world ledger.
	if not exploring and origin == "night05" and destination == "night06":
		var finished: Dictionary = data.get("outcomes",{})
		if last_outcome == "" or str(finished.get("night05","")) != last_outcome:
			return false
	# The Balete gate cannot accept a guessed outcome or QA-only preview.
	if not exploring and origin == "night06" and destination == "night07":
		var final_ledger: Dictionary = data.get("outcomes",{})
		if last_outcome == "" or str(final_ledger.get("night06","")) != last_outcome:
			return false
	data["current"] = destination
	data["pending"] = {"from": origin, "to": destination}
	var visited: Dictionary = data.get("visited", {})
	visited[destination] = true
	data["visited"] = visited
	if origin == "barrio_lawom" and last_outcome != "":
		var outcomes: Dictionary = data.get("outcomes", {})
		outcomes["night01"] = last_outcome
		data["outcomes"] = outcomes
	return write(data)

static func consume_arrival(region: String) -> Dictionary:
	var data := read()
	var pending: Dictionary = data["pending"]
	if str(pending.get("to", "")) != region:
		return {}
	var arrival := pending.duplicate(true)
	data["pending"] = {}
	write(data)
	return arrival

static func note_outcome(night_number: int, value: String) -> bool:
	if night_number < 1 or night_number > 7 or value == "":
		return false
	var data := read()
	var outcomes: Dictionary = data["outcomes"]
	outcomes["night%02d" % night_number] = value
	data["outcomes"] = outcomes
	return write(data)

static func seven_night_chain_is_connected() -> bool:
	# Pure graph check of the complete seven-night story route.
	var seen := {"barrio_lawom": true}
	var pending: Array[String] = ["barrio_lawom"]
	while not pending.is_empty():
		var at: String = pending.pop_front()
		for neighbor in CONNECTIONS.get(at, []):
			if not seen.has(neighbor):
				seen[neighbor] = true
				pending.append(neighbor)
	return seen.size() == REGIONS.size()
