extends RefCounted
## Independent atomic Night 6 save; corrupt primary falls back to backup.
const PATH := "user://night06_save.json"
const SCHEMA := 6
static func write(model: RefCounted) -> bool:
	var path := ProjectSettings.globalize_path(PATH)
	var tmp := path+".tmp"
	var backup := path+".bak"
	var file := FileAccess.open(tmp,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"schema":SCHEMA,"state":model.to_dict()}))
	file.flush()
	file.close()
	var had := FileAccess.file_exists(path)
	if had:
		DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(path,backup) != OK:
			DirAccess.remove_absolute(tmp)
			return false
	if DirAccess.rename_absolute(tmp,path) != OK:
		if had: DirAccess.rename_absolute(backup,path)
		return false
	return true
static func read(model: RefCounted) -> bool:
	return _try(PATH,model) or _try(PATH+".bak",model)
static func _try(path: String,model: RefCounted) -> bool:
	if not FileAccess.file_exists(path): return false
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return typeof(parsed) == TYPE_DICTIONARY and int(parsed.get("schema",-1)) == SCHEMA and typeof(parsed.get("state")) == TYPE_DICTIONARY and model.from_dict(parsed["state"])
static func exists() -> bool:
	return FileAccess.file_exists(PATH) or FileAccess.file_exists(PATH+".bak")
