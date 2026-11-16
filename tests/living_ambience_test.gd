extends SceneTree
const Sound = preload("res://scripts/audio/living_ambience.gd")
const Prefs = preload("res://scripts/core/preferences.gd")
var failed := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("Living ambience test: " + label)
func _run() -> void:
	var day: AudioStreamWAV = Sound.create_loop(false)
	var night: AudioStreamWAV = Sound.create_loop(true)
	check(day != null and night != null, "both ambience sources generated offline")
	check(day.mix_rate == Sound.SAMPLE_RATE, "Android-friendly low-cost stream sample rate")
	check(day.data.size() == Sound.SAMPLE_COUNT * 2, "full day buffer, signed 16-bit mono")
	check(night.data.size() == Sound.SAMPLE_COUNT * 2, "full night buffer, signed 16-bit mono")
	check(day.loop_mode == AudioStreamWAV.LOOP_FORWARD, "continuous looping sound")
	check(day.data != night.data, "day sounds distinct from night")
	check(day.data == Sound.create_loop(false).data, "deterministic original audio synthesis")
	var nonzero := false
	for i in range(0, day.data.size(), 1000):
		if day.data.decode_s16(i) != 0:
			nonzero = true
			break
	check(nonzero, "generated wave is not silent")
	var prefs = Prefs.new()
	check(prefs.audio_level == 1, "quiet by default")
	prefs.next_audio_level()
	check(prefs.audio_level == 2, "normal volume selectable")
	prefs.next_audio_level()
	check(prefs.audio_level == 0, "audio off selectable for silent play")
	print("Living ambience tests: ", "PASS" if failed == 0 else str(failed) + " failures")
	quit(0 if failed == 0 else 1)
