extends RefCounted
## Tabi-tabi is ONE seven-night story with connected regions.
## Regions are streamed as Godot scenes for memory/performance, not separate games.
## Nights 1–5 are connected playable scenes; Nights 6–7 remain locked.
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
	"night05": "res://scenes/night05.tscn"
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

static func begin_travel(origin: String, destination: String, last_outcome: String) -> bool:
	# Prevent menu-skipping future chapters and travel between unrelated regions.
	if not adjacent(origin, destination) or not implemented(destination):
		return false
	if origin == "barrio_lawom" and destination == "old_mango" and last_outcome == "":
		return false
	var data := read()
	# Do not let a player enter Tikbalang's ridge using an arbitrary string
	# or a preview-only scene. The completed Kapre outcome must already be
	# in the canonical one-world ledger and match the independent Night 2 save.
	if origin == "old_mango" and destination == "night03":
		var ledger_outcomes: Dictionary = data.get("outcomes", {})
		if last_outcome == "" or str(ledger_outcomes.get("night02","")) != last_outcome:
			return false
	# The wake cannot be entered on a preview-only or forged Night 3 result.
	# Compare the current outcome with the shared connected-world case ledger.
	if origin == "night03" and destination == "night04":
		var outcomes: Dictionary = data.get("outcomes", {})
		if last_outcome == "" or str(outcomes.get("night03","")) != last_outcome:
			return false
	# The Sigbin farm opens only from a canonically completed wake.
	# A QA-only scene launch cannot forge a Night 4 outcome in the ledger.
	if origin == "night04" and destination == "night05":
		var outcomes: Dictionary = data.get("outcomes", {})
		if last_outcome == "" or str(outcomes.get("night04","")) != last_outcome:
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
	# Pure graph check; future destinations remain UNIMPLEMENTED until built.
	var seen := {"barrio_lawom": true}
	var pending: Array[String] = ["barrio_lawom"]
	while not pending.is_empty():
		var at: String = pending.pop_front()
		for neighbor in CONNECTIONS.get(at, []):
			if not seen.has(neighbor):
				seen[neighbor] = true
				pending.append(neighbor)
	return seen.size() == REGIONS.size()
