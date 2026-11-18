extends RefCounted
## Offline accessibility preferences independent of canonical story saves.
const PATH := "user://tabitabi_preferences.json"
const TEXT_SCALES := [1.0, 1.2, 1.4]
const HINT_LEVELS := ["STANDARD", "GUIDED", "FULL"]
var text_scale := 1.0
var reduced_motion := false
var high_contrast := false
var story_assist := false
var audio_level := 1
var hint_level := 1
var joystick_x := .195
var joystick_y := .78

func next_text_scale() -> void:
	var idx := TEXT_SCALES.find(text_scale)
	text_scale = TEXT_SCALES[(idx + 1) % TEXT_SCALES.size()]

func next_audio_level() -> void:
	audio_level = (audio_level + 1) % 3


func next_hint_level() -> void:
	hint_level = (hint_level + 1) % HINT_LEVELS.size()

func to_dict() -> Dictionary:
	return {"schema": 1, "text_scale": text_scale, "reduced_motion": reduced_motion, "high_contrast": high_contrast, "story_assist": story_assist, "audio_level": audio_level, "hint_level": hint_level, "joystick_x": joystick_x, "joystick_y": joystick_y}

func from_dict(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or int(data.get("schema", -1)) != 1:
		return false
	var size: float = float(data.get("text_scale", 1.0))
	text_scale = minf(1.4, maxf(1.0, size))
	reduced_motion = bool(data.get("reduced_motion", false))
	high_contrast = bool(data.get("high_contrast", false))
	story_assist = bool(data.get("story_assist", false))
	audio_level = clampi(int(data.get("audio_level", 1)), 0, 2)
	hint_level = clampi(int(data.get("hint_level", 1)), 0, 2)
	joystick_x = clampf(float(data.get("joystick_x", .195)), .13, .45)
	joystick_y = clampf(float(data.get("joystick_y", .78)), .50, .83)
	return true

func save_to(path: String = PATH) -> bool:
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dict()))
	file.flush()
	file.close()
	var abs_path := ProjectSettings.globalize_path(path)
	var old_path := abs_path + ".bak"
	if FileAccess.file_exists(abs_path):
		DirAccess.remove_absolute(old_path)
		if DirAccess.rename_absolute(abs_path, old_path) != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), abs_path) != OK:
		if FileAccess.file_exists(old_path):
			DirAccess.rename_absolute(old_path, abs_path)
		return false
	return true

func load_from(path: String = PATH) -> bool:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var file := FileAccess.open(candidate, FileAccess.READ)
		if file == null:
			continue
		var data: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if from_dict(data):
			return true
	return false
