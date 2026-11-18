extends SceneTree
## All seven chapters are one spatially grounded world. Prevent recurrence of
## Night 2's "actor on roof/canopy" bug in the subsequent 2.5D scenes.
const Walk = preload("res://scripts/world/shared_walkability_2d.gd")
const N3 = preload("res://scenes/night03.tscn")
const N4 = preload("res://scenes/night04.tscn")
const N5 = preload("res://scenes/night05.tscn")
const N6 = preload("res://scenes/night06.tscn")
const N7 = preload("res://scenes/night07.tscn")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("Seven-night depth/collision: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Crucial: the same 2-pass painter must exist in every REAL scene,
	# not just be described in the README or a stand-alone test stub.
	var chapters: Array = [
		[3,N3,"_paint_chapter_actors"],
		[4,N4,"_paint_chapter_people"],
		[5,N5,"_paint_chapter_protagonists"],
		[6,N6,"_paint_chapter_people"],
		[7,N7,"_paint_chapter_protagonists"]
	]
	for item in chapters:
		var scene: Node = item[1].instantiate()
		check(scene.has_method(item[2]),"Night %d uses foreground/back depth painter" % item[0])
		scene.free()
	for chapter in range(3,8):
		var front: Vector2
		var rear: Vector2
		match chapter:
			3: rear=Vector2(-145,-410); front=Vector2(-145,25)
			4: rear=Vector2(75,-430); front=Vector2(125,205)
			5: rear=Vector2(165,-275); front=Vector2(135,295)
			6: rear=Vector2(-580,-465); front=Vector2(-580,10)
			7: rear=Vector2(515,-490); front=Vector2(515,125)
		check(Walk.scenery_covers_actor(chapter,rear),
			"Night %d keeps actors BEHIND the shelter/house/barn/tree" % chapter)
		check(not Walk.scenery_covers_actor(chapter,front),
			"Night %d draws actors IN FRONT on the adjacent path" % chapter)
		var out := Walk.repair_saved_position(chapter,rear)
		check(not Walk.is_blocked(chapter,out),
			"Night %d existing game save must not leave the player inside collider" % chapter)
	check(Walk.is_blocked(4,Vector2(75,-190)),
		"Night 4 wake house ground is solid at its real projected footprint")
	check(not Walk.is_blocked(4,Vector2(125,205)),
		"Night 4 vigil courtyard remains walkable")
	check(Walk.is_blocked(5,Vector2(-795,-200)),
		"Night 5 farmhouse floor is solid, not a walk-through drawing")
	check(Walk.is_blocked(5,Vector2(165,-200)),
		"Night 5 raised unsafe barn remains impassable")
	check(not Walk.is_blocked(5,Vector2(135,295)),
		"Night 5 evidence observation point remains reachable")
	check(Walk.is_blocked(6,Vector2(-580,-340)),
		"Night 6 archive is solid at its doorway feet")
	check(Walk.is_blocked(7,Vector2(530,-260)),
		"Night 7 Balete has a solid ancient root trunk")
	check(not Walk.is_blocked(7,Vector2(210,220)),
		"Night 7 trial stones remain reachable")
	var wake_walk := Walk.slide(4,Vector2(75,205),Vector2(75,-350))
	check(not Walk.is_blocked(4,wake_walk),
		"Night 4 no tunneling through front wall on a laggy Android frame")
	var barn_walk := Walk.slide(5,Vector2(165,295),Vector2(165,-300))
	check(not Walk.is_blocked(5,barn_walk),
		"Night 5 no teleport across unsafe barn footprint")
	print("Shared grounded 2.5D world (Nights 3-7): ",
		"PASS" if failures==0 else "%d failures" % failures)
	quit(0 if failures==0 else 1)
