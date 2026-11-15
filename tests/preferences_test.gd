extends SceneTree
const Prefs = preload("res://scripts/core/preferences.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func verify(ok: bool, name: String) -> void:
	if not ok:
		failures += 1
		printerr("Preferences regression: " + name)
func _run() -> void:
	var p = Prefs.new()
	verify(is_equal_approx(p.text_scale, 1.0), "default readable scale")
	p.next_text_scale()
	verify(is_equal_approx(p.text_scale, 1.2), "larger font cycle")
	p.next_text_scale()
	verify(is_equal_approx(p.text_scale, 1.4), "largest font cycle")
	p.next_text_scale()
	verify(is_equal_approx(p.text_scale, 1.0), "font cycle wraps")
	p.next_hint_level()
	verify(p.hint_level == 2, "guided hints can increase")
	p.high_contrast = true
	p.reduced_motion = true
	p.story_assist = true
	p.next_audio_level()
	var path := "user://test_tabitabi_preferences.json"
	verify(p.save_to(path), "save settings offline")
	var reload = Prefs.new()
	verify(reload.load_from(path), "load settings")
	verify(reload.high_contrast and reload.reduced_motion and reload.story_assist, "accessibility and story assist persist")
	verify(reload.hint_level == 2, "hint level persists")
	verify(reload.audio_level == 2, "quiet/normal/off setting survives save")
	verify(reload.from_dict({"schema": 1, "text_scale": 10.0, "hint_level": 42, "high_contrast": false, "reduced_motion": false}), "accept and clamp out-of-range settings")
	verify(reload.text_scale <= 1.4 and reload.hint_level == 2, "clamped values")
	verify(reload.audio_level == 1, "older settings safely default to quiet audio")
	verify(not reload.from_dict({"schema": 99}), "bad schema rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))
	print("Accessibility preferences tests: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
