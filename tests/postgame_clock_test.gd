extends SceneTree
## Post-game time starts only after a complete seven-night epilogue ledger.
## Tests use a synthetic completed save; Night 7 itself is not yet built.
const World = preload("res://scripts/core/connected_world.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("Postgame automatic daylight: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var old: Dictionary = {}
	for path in [World.PATH, World.PATH + ".bak", World.PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			old[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	PostgameClock.refresh()
	check(not PostgameClock.is_active(), "new story does not activate free-roam clock")
	check(not World.finish_epilogue(), "unbuilt Night 7 cannot end the story")
	var ledger := World.read()
	ledger["epilogue_complete"] = true
	ledger["outcomes"] = {"night01":"resolve"}
	check(World.write(ledger), "write incomplete test ledger")
	PostgameClock.refresh()
	check(not PostgameClock.is_active(), "single chapter result cannot unlock automatic cycle")

	var outcomes: Dictionary = {}
	for night in range(1, 8):
		outcomes["night%02d" % night] = "resolve"
	ledger["outcomes"] = outcomes
	ledger["postgame_time"] = 0.29
	check(World.write(ledger), "save synthetic completed epilogue ledger")
	PostgameClock.refresh()
	check(PostgameClock.is_active() and not PostgameClock.is_night(), "finalized seven-night ledger unlocks day")
	check(PostgameClock.light_stage() == 0, "postgame starts in daylight")
	PostgameClock._process(PostgameClock.FULL_DAY_SECONDS * 0.6)
	check(PostgameClock.is_night(), "clock advances from dawn into night automatically")
	check(PostgameClock.save_clock(), "shared world ledger stores current time")
	var stage_before: int = PostgameClock.light_stage()
	PostgameClock.refresh()
	check(PostgameClock.light_stage() == stage_before, "reloaded clock preserves day/night")
	PostgameClock._process(PostgameClock.FULL_DAY_SECONDS * 0.5)
	check(not PostgameClock.is_night(), "night returns to morning without player button")
	check(World.begin_travel("barrio_lawom","old_mango",""), "finished game permits old roads without replaying cases")
	check(World.consume_arrival("old_mango").get("from") == "barrio_lawom", "free-roam region streaming still works")

	for path in [World.PATH, World.PATH + ".bak", World.PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in old:
		var saved := FileAccess.open(path, FileAccess.WRITE)
		if saved != null:
			saved.store_buffer(old[path])
			saved.close()
	PostgameClock.refresh()
	print("Postgame time and save regression: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
