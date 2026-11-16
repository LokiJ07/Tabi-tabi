extends SceneTree
## Night 2 is canonical AFTER Night 1; debug APK has a clearly-labelled
## testing-only bypass so a freshly installed preview is immediately playable.
const Title = preload("res://scenes/title.tscn")
const Night1 = preload("res://scripts/narrative/night01_state.gd")
const Save = preload("res://scripts/core/save_service.gd")
var failed := 0

func check(ok: bool, title: String) -> void:
	if not ok:
		failed += 1
		printerr("Night 2 unlock: " + title)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var file_list := [Save.PATH, Save.PATH + ".bak", Save.PATH + ".tmp"]
	var old: Dictionary = {}
	for item in file_list:
		if FileAccess.file_exists(item):
			old[item] = FileAccess.get_file_as_bytes(item)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(item))
	var title = Title.instantiate()
	root.add_child(title)
	await process_frame
	check(not title._night2_unlocked(), "no canonical Night 1 outcome means story lock")
	if OS.has_feature("debug"):
		check(not title.night2_button.disabled, "QA preview can test Night 2 on a clean install")
		check(title.night2_button.text.contains("(QA)"), "debug bypass is honestly labelled QA")
	else:
		check(title.night2_button.disabled, "production release cannot skip Night 1")

	var complete = Night1.new()
	var data := complete.to_dict()
	data["phase"] = 4
	data["outcome"] = "partial"
	check(complete.from_dict(data), "valid committed Night 1 save fixture")
	check(Save.write(complete, false), "persist canonical Night 1 outcome")
	check(title._night2_unlocked(), "Night 1 partial/retreat-style outcome unlocks Kapre")
	title.queue_free()
	await process_frame
	var new_title = Title.instantiate()
	root.add_child(new_title)
	await process_frame
	check(not new_title.night2_button.disabled, "Night 2 chapter appears unlocked in actual title UI")
	new_title.queue_free()
	await process_frame
	for item in file_list:
		if FileAccess.file_exists(item):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(item))
	for key in old:
		var output := FileAccess.open(key, FileAccess.WRITE)
		if output != null:
			output.store_buffer(old[key])
			output.close()
	print("Night 2 title save gate and QA-access regression: ", "PASS" if failed == 0 else str(failed)+" failure(s)")
	quit(0 if failed == 0 else 1)
