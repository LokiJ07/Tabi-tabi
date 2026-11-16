extends SceneTree

const State = preload("res://scripts/narrative/night01_state.gd")
const Save = preload("res://scripts/core/save_service.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func verify(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("Offline-save recovery: " + label)

func _clean() -> void:
	for relative in [Save.PATH, Save.PATH + ".bak", Save.PATH + ".tmp"]:
		if FileAccess.file_exists(relative):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(relative))

func _corrupt(text_value: String) -> void:
	var file := FileAccess.open(Save.PATH, FileAccess.WRITE)
	if file == null:
		verify(false, "corrupt-save fixture can open a file")
		return
	file.store_string(text_value)
	file.close()

func _recover_from_previous() -> void:
	var loaded = State.new()
	var metadata: Dictionary = Save.read(loaded)
	verify(not metadata.is_empty(), "fallback to valid previous save")
	verify(not metadata.get("night", true), "fallback preserves prior day state")
	verify(loaded.prologue_ready(), "old notebook and cup survive recovery")
	verify(not loaded.clues.has("old_mooring"), "corrupted latest clue cannot fabricate progress")

func _run() -> void:
	_clean()
	var model = State.new()
	model.inspect_prologue("blue_notebook")
	model.inspect_prologue("warm_cup")
	verify(Save.write(model, false), "first valid local save")
	model.observe_clue("old_mooring")
	verify(Save.write(model, true), "second save creates backup")
	verify(FileAccess.file_exists(Save.PATH + ".bak"), "previous copy exists")
	_corrupt("{bad_json")
	_recover_from_previous()
	_corrupt(JSON.stringify({"schema":1, "night":true, "state":{"schema":1, "clues":["bad"], "seen_people":{}, "phase":0,"outcome":""}}))
	_recover_from_previous()
	_corrupt(JSON.stringify({"schema":1, "night":true, "state":{"schema":1, "clues":{}, "seen_people":["bad"], "phase":0,"outcome":""}}))
	_recover_from_previous()
	_clean()
	verify(not FileAccess.file_exists(Save.PATH), "test files removed")
	print("Offline-save fallback tests: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
