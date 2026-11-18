extends SceneTree
## A new playthrough can never inherit completed seven-night free-roam time.
const Title = preload("res://scenes/title.tscn")
const World = preload("res://scripts/core/connected_world.gd")
const Saves = [
	preload("res://scripts/core/save_service.gd"),
	preload("res://scripts/core/night02_save.gd"),
	preload("res://scripts/core/night03_save.gd"),
	preload("res://scripts/core/night04_save.gd"),
	preload("res://scripts/core/night05_save.gd"),
	preload("res://scripts/core/night06_save.gd"),
	preload("res://scripts/core/night07_save.gd")
]
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("New campaign reset: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var paths: Array[String] = []
	for helper in Saves:
		var base: String = helper.PATH
		for suffix in ["",".bak",".tmp"]:
			paths.append(base+suffix)
	for suffix in ["",".bak",".tmp"]:
		paths.append(World.PATH+suffix)
	var old: Dictionary = {}
	for path in paths:
		if FileAccess.file_exists(path):
			old[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var outcomes: Dictionary = {}
	for n in range(1,8):
		outcomes["night%02d" % n] = "resolve"
	var ledger := World.read()
	ledger["outcomes"] = outcomes
	ledger["epilogue_complete"] = true
	check(World.write(ledger),"synthetic postgame world fixture persists")
	# Save stubs are sufficient to check cleanup; this is NOT a fabricated
	# gameplay unlock and the data are not used by character logic.
	for helper in Saves:
		var f := FileAccess.open(helper.PATH,FileAccess.WRITE)
		if f != null:
			f.store_string("new campaign cleanup sentinel")
			f.close()
	var clock := root.get_node_or_null("PostgameClock")
	if clock != null:
		clock.refresh()
		check(clock.is_active(),"completed world initially has automatic clock")
	var title = Title.instantiate()
	root.add_child(title)
	await process_frame
	check(title._has_any_story_progress(),"new-game confirmation sees older chapter saves")
	check(title._campaign_save_paths().size() == 8,"all seven saves plus connected ledger are included")
	check(title.new_game_dialog.dialog_text.contains("all seven chapter saves"),
		"clear user confirmation warns about complete reset")
	title._clear_campaign_saves()
	check(not World.is_postgame(),"new campaign cannot inherit old epilogue")
	if clock != null:
		check(not clock.is_active(),"automatic clock immediately deactivated")
	for path in paths:
		check(not FileAccess.file_exists(path),"campaign file cleared: "+path)
	title.queue_free()
	await process_frame
	for path in old:
		var f := FileAccess.open(path,FileAccess.WRITE)
		if f != null:
			f.store_buffer(old[path])
			f.close()
	if clock != null:
		clock.refresh()
	print("Seven-night new campaign / postgame reset: ","PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
