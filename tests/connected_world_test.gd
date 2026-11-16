extends SceneTree
## One canon: seven connected nights. Only built regions may be entered.
## Save-safe round trips between Barrio Lawom and Kapre grove.
const World = preload("res://scripts/core/connected_world.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("Tabi seven-night world: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var old: Dictionary = {}
	for path in [World.PATH,World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			old[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(World.REGIONS.size() == 7, "seven canonical world regions")
	check(World.seven_night_chain_is_connected(), "seven-night geography is ONE traversable graph")
	check(World.adjacent("barrio_lawom","old_mango"), "path from Barrio to mango")
	check(World.adjacent("old_mango","barrio_lawom"), "return path from mango to Barrio")
	check(not World.adjacent("barrio_lawom","night07"), "no skipping to the finale")
	check(World.scene_for("barrio_lawom") == "res://scenes/main.tscn", "Barrio uses real original game scene")
	check(World.scene_for("old_mango") == "res://scenes/night02.tscn", "Kapre uses real chapter scene")
	check(not World.implemented("night03") and not World.implemented("night07"), "unfinished areas remain locked, never fake content")
	check(not World.begin_travel("barrio_lawom","old_mango",""), "no shortcut past Night 1")
	check(not World.begin_travel("old_mango","night03","resolve"), "no travel to unimplemented Night 3")
	check(World.begin_travel("barrio_lawom","old_mango","partial"), "Night 1 partial conclusion opens real north trail")
	var pending := World.read()
	check(pending["current"] == "old_mango", "world position persists after scene streaming")
	check(pending["outcomes"].get("night01","") == "partial", "Night 1 consequence remains canonical")
	var arrived := World.consume_arrival("old_mango")
	check(arrived.get("from") == "barrio_lawom", "Kapre entry remembers actual Barrio origin")
	check(World.consume_arrival("old_mango").is_empty(), "arrival is consumed once")
	check(World.begin_travel("old_mango","barrio_lawom","partial"), "player may return while Kapre case is open")
	check(World.consume_arrival("barrio_lawom").get("from") == "old_mango", "return arrival remembers mango grove")
	check(World.note_outcome(2,"resolve"), "record Kapre result in same seven-night world ledger")
	var ledger := World.read()
	check(ledger["outcomes"].get("night01") == "partial", "Kapre never overwrites Santelmo ending")
	check(ledger["outcomes"].get("night02") == "resolve", "Kapre outcome persists beside Santelmo")
	for path in [World.PATH,World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in old:
		var saved := FileAccess.open(path,FileAccess.WRITE)
		if saved != null:
			saved.store_buffer(old[path])
			saved.close()
	print("Seven-night connected world + cross-region save continuity: ","PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
