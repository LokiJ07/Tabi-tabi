extends RefCounted
## Night 7 independent safe final-chapter record. Existing six saves unchanged.
const PATH := "user://night07_save.json"
const SCHEMA := 7
static func write(model: RefCounted) -> bool:
	var dst := ProjectSettings.globalize_path(PATH)
	var tmp := dst+".tmp"
	var backup := dst+".bak"
	var f := FileAccess.open(tmp,FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify({"schema":SCHEMA,"state":model.to_dict()}))
	f.flush()
	f.close()
	var had := FileAccess.file_exists(dst)
	if had:
		DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(dst,backup) != OK:
			DirAccess.remove_absolute(tmp)
			return false
	if DirAccess.rename_absolute(tmp,dst) != OK:
		if had: DirAccess.rename_absolute(backup,dst)
		return false
	return true
static func read(model: RefCounted) -> bool:
	return _try(PATH,model) or _try(PATH+".bak",model)
static func _try(path: String,model: RefCounted) -> bool:
	if not FileAccess.file_exists(path): return false
	var f := FileAccess.open(path,FileAccess.READ)
	if f == null: return false
	var raw: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return typeof(raw) == TYPE_DICTIONARY and int(raw.get("schema",-1)) == SCHEMA \
		and typeof(raw.get("state")) == TYPE_DICTIONARY and model.from_dict(raw["state"])
static func exists() -> bool:
	return FileAccess.file_exists(PATH) or FileAccess.file_exists(PATH+".bak")
