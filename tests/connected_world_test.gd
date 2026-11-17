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
	check(World.implemented("night03") and World.implemented("night04") and World.implemented("night05") and World.implemented("night06") and not World.implemented("night07"), "Nights 1–6 now playable, Night 7 still locked")
	check(World.scene_for("night03") == "res://scenes/night03.tscn", "Tikbalang ridge is an actual playable scene")
	check(World.scene_for("night04") == "res://scenes/night04.tscn", "Wake has an authentic playable scene")
	check(World.scene_for("night05") == "res://scenes/night05.tscn", "Sigbin abandoned farm has a real playable scene")
	check(not World.begin_travel("night04","night05","resolve"), "farm is locked without completed Night 4 ledger")
	check(World.implemented("night06"),"Night 6 is a real connected scene")
	check(World.TRAIL_FARM_NIGHT06 == Vector2(955.0,-470.0)
		and World.adjacent("night05","night06")
		and World.adjacent("night06","night05")
		and World.scene_for("night06") == "res://scenes/night06.tscn",
		"Night 6 path streams into real river territory")
	check(not World.begin_travel("night03","night04","resolve"), "wake remains locked without a saved ridge outcome")
	check(not World.begin_travel("barrio_lawom","old_mango",""), "no shortcut past Night 1")
	check(not World.begin_travel("old_mango","night03","resolve"), "Night 3 remains locked before an actual saved Kapre outcome")
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
	check(not World.begin_travel("old_mango","night03","partial"), "wrong completion string cannot forge ridge unlock")
	check(World.begin_travel("old_mango","night03","resolve"), "Kapre conclusion opens real physical ridge")
	check(World.consume_arrival("night03").get("from") == "old_mango", "night 3 remembers mango entry")
	check(World.begin_travel("night03","old_mango",""), "the same ridge trail returns to old mango")
	check(World.consume_arrival("old_mango").get("from") == "night03", "return to mango remembers ridge origin")
	check(World.note_outcome(3,"partial"), "Tikbalang outcome records as a third canonical event")
	check(not World.begin_travel("night03","night04","resolve"), "wrong ridge ending cannot forge a wake unlock")
	check(World.begin_travel("night03","night04","partial"), "saved ridge ending opens the real lamay trail")
	check(World.consume_arrival("night04").get("from") == "night03", "Night 4 remembers the physical ridge entry")
	check(World.begin_travel("night04","night03",""), "wake can return to ridge with active case")
	check(World.consume_arrival("night03").get("from") == "night04", "ridge remembers the return trail")
	check(World.note_outcome(4,"drive_away"),"record canonical wake outcome in one-world ledger")
	check(not World.begin_travel("night04","night05","resolve"),"wrong wake outcome cannot forge Sigbin farm entry")
	check(World.begin_travel("night04","night05","drive_away"),"completed wake opens physical old-farm trail")
	check(World.consume_arrival("night05").get("from") == "night04","farm remembers real wake origin")
	check(World.begin_travel("night05","night04",""),"farmer's path returns to the same wake neighborhood")
	check(World.consume_arrival("night04").get("from") == "night05","wake remembers farm return")
	check(not World.begin_travel("night05","night06","resolve"),"cannot enter Night 6 without matching farm ledger")
	check(World.note_outcome(5,"safe_rescue"),"record genuine Night 5 result")
	check(not World.begin_travel("night05","night06","resolve"),"wrong outcome cannot forge farm exit")
	check(World.begin_travel("night05","night06","safe_rescue"),"completed Sigbin farm opens River")
	check(World.consume_arrival("night06").get("from") == "night05","river remembers farm arrival")
	check(World.begin_travel("night06","night05",""),"river has continuous return to farm")
	check(World.consume_arrival("night05").get("from") == "night06","farm remembers river return")
	check(World.note_outcome(6,"partial"),"Night 6 partial saved separately in canonical ledger")
	var all_three := World.read()
	check(all_three["outcomes"].get("night01") == "partial" and all_three["outcomes"].get("night02") == "resolve" and all_three["outcomes"].get("night03") == "partial", "three chapter outcomes coexist without overwriting saves")
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
