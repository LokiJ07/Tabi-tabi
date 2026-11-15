extends RefCounted
## Prototype offline persistence with schema validation and atomic replacement.
const PATH := "user://night01_save.json"


static func write(model: RefCounted, world_night: bool) -> bool:
	var payload := {"schema": 1, "night": world_night, "state": model.to_dict()}
	var temp := PATH + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	# Keep the previous file until the replacement file was successfully written.
	var absolute := ProjectSettings.globalize_path(PATH)
	var absolute_temp := ProjectSettings.globalize_path(temp)
	if FileAccess.file_exists(PATH):
		var backup := absolute + ".bak"
		DirAccess.copy_absolute(absolute, backup)
		DirAccess.remove_absolute(absolute)
	if DirAccess.rename_absolute(absolute_temp, absolute) != OK:
		return false
	return true


static func read(model: RefCounted) -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	if int(parsed.get("schema", -1)) != 1:
		return {}
	var raw: Variant = parsed.get("state", {})
	if typeof(raw) != TYPE_DICTIONARY or not model.from_dict(raw):
		return {}
	return {"night": bool(parsed.get("night", false))}
