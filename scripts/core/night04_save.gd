extends RefCounted
## Independent Night 4 atomic offline save; never mutates Nights 1–3.
const PATH := "user://night04_save.json"
const SCHEMA := 4

static func write(model: RefCounted) -> bool:
	var primary := ProjectSettings.globalize_path(PATH)
	var temp := primary + ".tmp"
	var backup := primary + ".bak"
	var stream := FileAccess.open(temp,FileAccess.WRITE)
	if stream == null:
		return false
	stream.store_string(JSON.stringify({"schema":SCHEMA,"state":model.to_dict()}))
	stream.flush()
	stream.close()
	var has_old := FileAccess.file_exists(primary)
	if has_old:
		DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(primary,backup) != OK:
			DirAccess.remove_absolute(temp)
			return false
	if DirAccess.rename_absolute(temp,primary) != OK:
		if has_old:
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
	return typeof(parsed) == TYPE_DICTIONARY and int(parsed.get("schema",-1)) == SCHEMA and typeof(parsed.get("state")) == TYPE_DICTIONARY and model.from_dict(parsed["state"])

static func exists() -> bool:
	return FileAccess.file_exists(PATH) or FileAccess.file_exists(PATH+".bak")
