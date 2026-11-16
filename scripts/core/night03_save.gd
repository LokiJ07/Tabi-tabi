extends RefCounted
## Independent v3 atomic save, with backup fallback; never mutates Night 1/2.
const PATH := "user://night03_save.json"

static func write(model: RefCounted) -> bool:
	var raw: Dictionary = {"schema":3,"state":model.to_dict()}
	var primary := ProjectSettings.globalize_path(PATH)
	var temp := primary + ".tmp"
	var backup := primary + ".bak"
	var file := FileAccess.open(temp,FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(raw))
	file.flush()
	file.close()
	var had_previous := FileAccess.file_exists(primary)
	if had_previous:
		DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(primary,backup) != OK:
			DirAccess.remove_absolute(temp)
			return false
	if DirAccess.rename_absolute(temp,primary) != OK:
		if had_previous:
			DirAccess.rename_absolute(backup,primary)
		return false
	return true

static func read(model: RefCounted) -> bool:
	return _load(PATH,model) or _load(PATH+".bak",model)

static func _load(path: String,model: RefCounted) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return typeof(parsed) == TYPE_DICTIONARY and int(parsed.get("schema",-1)) == 3 and typeof(parsed.get("state")) == TYPE_DICTIONARY and model.from_dict(parsed["state"])

static func exists() -> bool:
	return FileAccess.file_exists(PATH) or FileAccess.file_exists(PATH+".bak")
