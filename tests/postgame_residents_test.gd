extends SceneTree
## Story-gated daily work, distinct NPC presence and live postgame settlement art.
const World = preload("res://scripts/core/connected_world.gd")
const Clock = preload("res://scripts/core/postgame_clock.gd")
const Workers = preload("res://scripts/world/postgame_residents.gd")
const Barrio = preload("res://scripts/world/postgame_barrio_3d.gd")
var failures := 0

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		printerr("Living village regression: " + description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var old: Dictionary = {}
	for path in [World.PATH, World.PATH + ".bak", World.PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			old[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var avatar := Node2D.new()
	avatar.name = "VillageProbe"
	root.add_child(avatar)
	var clock := root.get_node_or_null("PostgameClock")
	var created_clock := clock == null
	if created_clock:
		clock = Clock.new()
		clock.name = "PostgameClock"
		root.add_child(clock)
	clock.refresh()
	check(Workers.nearby(avatar,"night06",Vector2(-350,188)) == "", "uncompleted story has no postgame residents")
	var outcomes: Dictionary = {}
	for i in range(1,8):
		outcomes["night%02d" % i] = "resolve"
	var ledger := World.read()
	ledger["outcomes"] = outcomes
	ledger["epilogue_complete"] = true
	ledger["postgame_time"] = 0.34
	check(World.write(ledger),"write synthetic completed story ledger")
	clock.refresh()
	check(clock.is_active(), "postgame schedule unlocked only for completed finale")
	check(clock.village_mood == "restored", "all resolved outcomes permit river livelihoods")
	check(Workers.schedule(clock) == "morning", "morning workers start jobs")
	for region in ["old_mango","night03","night04","night05","night06"]:
		var cast: Array = Workers.ACTORS[region]
		check(cast.size() >= 2, region + " has varied resident work routines")
		var actor: Dictionary = cast[0]
		var at: Vector2 = Workers.activity_position(actor,"morning")
		var nearby: String = Workers.nearby(avatar,region,at)
		check(nearby.begins_with("postgame:"), region + " resident physically interactable")
		check(Workers.talk(avatar, nearby) != "", region + " has nonempty occupation dialogue")
	clock._fraction = .92
	check(Workers.schedule(clock) == "sleep", "sleeping people go inside after dark")
	check(Workers.nearby(avatar,"night06",Vector2(-350,188)) == "", "no phantom outdoor fisher overnight")
	clock._fraction = .36
	outcomes["night06"] = "partial"
	ledger["outcomes"] = outcomes
	check(World.write(ledger),"save unresolved earlier flood testimony")
	clock.refresh()
	check(clock.village_mood == "healing", "partial rescue still changes ending-dependent work")
	check(Workers.talk(avatar,"postgame:river_fisher").contains("mend"), "unsafe river remains cautious")
	var village := Node3D.new()
	root.add_child(village)
	var built := Barrio.ensure(village)
	check(built != null and built.get_child_count() > 9,"Barrio adds jobs, real market, nets and boat")
	check(Barrio.ensure(village) == built,"postgame world art does not duplicate on reload")
	for person in ["dock_fisher","market_vendor","garden_farmer","trail_caretaker"]:
		check(built.get_node_or_null(person) != null, person + " is a placed character, not text-only")
	Barrio.update(built,.35,5.0,true,"healing")
	check((built.get_node("dock_fisher") as Node3D).visible, "fish work appears during safe daytime")
	Barrio.update(built,.9,5.0,true,"healing")
	check(not (built.get_node("dock_fisher") as Node3D).visible, "NPC retreats indoors at night")
	village.queue_free()
	avatar.queue_free()
	if created_clock:
		clock.queue_free()
	for path in [World.PATH, World.PATH + ".bak", World.PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in old:
		var saved := FileAccess.open(path,FileAccess.WRITE)
		if saved != null:
			saved.store_buffer(old[path])
			saved.close()
	if not created_clock:
		clock.refresh()
	print("Living village and five-region occupations: ","PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
