extends RefCounted
const PATH := "user://night01_save.json"

static func write(model: RefCounted, world_night: bool) -> bool:
	var payload := {"schema": 1, "night": world_night, "state": model.to_dict()}
	var absolute := ProjectSettings.globalize_path(PATH)
	var temp := absolute + ".tmp"
	var backup := absolute + ".bak"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	var had_previous := FileAccess.file_exists(absolute)
	if had_previous:
		DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(absolute, backup) != OK:
			DirAccess.remove_absolute(temp)
			return false
	if DirAccess.rename_absolute(temp, absolute) != OK:
		if had_previous:
			DirAccess.rename_absolute(backup, absolute)
		return false
	return true

static func read(model: RefCounted) -> Dictionary:
	var primary := _read_file(PATH, model)
	if not primary.is_empty():
		return primary
	return _read_file(PATH + ".bak", model)

static func _read_file(path: String, model: RefCounted) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("schema", -1)) != 1:
		return {}
	var raw: Variant = parsed.get("state", {})
	if typeof(raw) != TYPE_DICTIONARY or not model.from_dict(raw):
		return {}
	return {"night": bool(parsed.get("night", false))}
