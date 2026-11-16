extends SceneTree
## Production requires BOTH earlier chapters. Debug mode labels bypass honestly.
const Title = preload("res://scenes/title.tscn")
const Night1 = preload("res://scripts/narrative/night01_state.gd")
const Night1Save = preload("res://scripts/core/save_service.gd")
const Night2 = preload("res://scripts/narrative/night02_state.gd")
const Night2Save = preload("res://scripts/core/night02_save.gd")
var failures := 0

func check(ok: bool,description: String) -> void:
	if not ok:
		failures += 1
		printerr("Night 3 title unlock: "+description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var paths := [
		Night1Save.PATH,Night1Save.PATH+".bak",Night1Save.PATH+".tmp",
		Night2Save.PATH,Night2Save.PATH+".bak",Night2Save.PATH+".tmp"
	]
	var old: Dictionary = {}
	for path in paths:
		if FileAccess.file_exists(path):
			old[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var title = Title.instantiate()
	root.add_child(title)
	await process_frame
	check(not title._night3_unlocked(), "Night 3 production gate locked on clean install")
	if OS.has_feature("debug"):
		check(title.night3_button.text.contains("(QA)"), "debug preview clearly labelled QA, not canonical unlock")
		check(not title.night3_button.disabled, "direct scene preview available ONLY in debug")
	else:
		check(title.night3_button.disabled, "production cannot skip Nights 1 and 2")
	var first = Night1.new()
	var dict: Dictionary = first.to_dict()
	dict["phase"] = 4
	dict["outcome"] = "partial"
	check(first.from_dict(dict), "canonical completed Night 1 save fixture")
	check(Night1Save.write(first,false), "write Night 1 without mutation")
	check(not title._night3_unlocked(), "Night 1 completion alone never opens Night 3")
	var second = Night2.new()
	second.night1_outcome = "partial"
	for id in Night2.REQUIRED_CLUES:
		second.observe(id)
	second.begin_safety()
	for id in Night2.BARRIER_POSITIONS:
		second.close_route(id)
	check(second.commit("partial"), "Night 2 partial ending is canonical")
	check(Night2Save.write(second), "Night 2 independent save written")
	check(title._night3_unlocked(), "two completed nights open Tikbalang ridge")
	title.queue_free()
	await process_frame
	var loaded = Title.instantiate()
	root.add_child(loaded)
	await process_frame
	check(not loaded.night3_button.disabled, "real title Night 3 button becomes enabled after case outcomes")
	check(not loaded.night3_button.text.contains("(QA)"), "completed players see canonical Night 3 title")
	loaded.queue_free()
	await process_frame
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in old:
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file != null:
			file.store_buffer(old[path])
			file.close()
	print("Night 3 locked title, clean preview and save unlock: ",
		"PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
