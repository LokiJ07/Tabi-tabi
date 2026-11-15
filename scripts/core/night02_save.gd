extends RefCounted
## Night 2 is an independent atomic save; do not overwrite Night 1 canonical state.
const PATH := "user://night02_save.json"

static func write(model: RefCounted) -> bool:
	var absolute := ProjectSettings.globalize_path(PATH)
	var tmp := absolute + ".tmp"
	var bak := absolute + ".bak"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"schema": 2, "state": model.to_dict()}))
	file.flush()
	file.close()
	var old := FileAccess.file_exists(absolute)
	if old:
		DirAccess.remove_absolute(bak)
		if DirAccess.rename_absolute(absolute, bak) != OK:
			DirAccess.remove_absolute(tmp)
			return false
	if DirAccess.rename_absolute(tmp, absolute) != OK:
		if old:
			DirAccess.rename_absolute(bak, absolute)
		return false
	return true

static func read(model: RefCounted) -> bool:
	return _load(PATH, model) or _load(PATH + ".bak", model)

static func _load(path: String, model: RefCounted) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var value = JSON.parse_string(file.get_as_text())
	file.close()
	return typeof(value) == TYPE_DICTIONARY and int(value.get("schema", -1)) == 2 and typeof(value.get("state")) == TYPE_DICTIONARY and model.from_dict(value["state"])

static func exists() -> bool:
	return FileAccess.file_exists(PATH) or FileAccess.file_exists(PATH + ".bak")
