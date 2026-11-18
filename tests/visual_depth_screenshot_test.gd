extends SceneTree
## Screenshot-regression logic: actor vs foreground depth and real 3D room.
## This intentionally checks the geometry behind the visual instead of
## treating a passing build or a sprite-import as "visual QA complete".
const Walk = preload("res://scripts/world/shared_walkability_2d.gd")
const Hut = preload("res://scripts/world/lola_hut_interior.gd")
const Night2Scene = preload("res://scenes/night02.tscn")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("World-depth screenshot regression: "+message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# These are the exact two roof/treetop failures reported from Android.
	check(Walk.scenery_covers_actor(2,Vector2(-595,320)),
		"an actor behind Safe Shelter must be painted before the roof")
	check(Walk.scenery_covers_actor(2,Vector2(245,-330)),
		"an actor behind the mango canopy must be painted before the leaves")
	check(not Walk.scenery_covers_actor(2,Vector2(245,80)),
		"an actor in front of the mango trunk remains on top of the scenery")
	check(not Walk.scenery_covers_actor(2,Vector2(-610,525)),
		"an actor in front of the shelter stays visible")
	check(Walk.is_blocked(2,Vector2(-610,410)),
		"shelter floor is physically solid, not only visually painted")
	check(Walk.is_blocked(2,Vector2(-600,-445)),
		"school footprint is physically solid")
	var repaired := Walk.repair_saved_position(2,Vector2(-610,410))
	check(not Walk.is_blocked(2,repaired) and repaired.distance_to(Vector2(-610,410))<330,
		"legacy save inside shelter recovers next to the same house")
	var tree_fix := Walk.repair_saved_position(2,Vector2(245,-120))
	check(not Walk.is_blocked(2,tree_fix),"legacy save inside mango trunk recovers")
	var start := Vector2(-800,400)
	var attempted := Walk.slide(2,start,Vector2(-610,410))
	check(not Walk.is_blocked(2,attempted),
		"continuous movement cannot tunnel through the shelter")
	check(not Walk.is_blocked(2,Vector2(-446,272)),
		"route safety clue still accessible on its actual footpath")
	var room_world := Node3D.new()
	root.add_child(room_world)
	Hut.build(room_world)
	var room := room_world.get_node("LolaHutInterior") as Node3D
	var backdrop := room.get_node("Hut surrounding earth") as MeshInstance3D
	check(backdrop != null and (backdrop.mesh as BoxMesh).size.x>100,
		"interior matte covers all portrait/landscape camera corners")
	check(room.get_node_or_null("Hut roof support beam 1") == null,
		"ceiling supports must no longer cross Lola and the central aisle")
	check(room.get_node_or_null("Perimeter roof support 0") != null,
		"roof beams moved to perimeter, keeping a believable structure")
	check(room.get_node_or_null("Hut exit safety gate collision") is StaticBody3D,
		"the door remains solid and requires INTERACT")
	room_world.queue_free()
	var game = Night2Scene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.options_panel.anchor_top >= .15 and game.options_panel.anchor_bottom<=.82,
		"Night 2 pause panel is compact without empty fullscreen filler")
	game.queue_free()
	print("Night 1-2 screenshot-derived world visual depth: ",
		"PASS" if failures==0 else str(failures)+" failures")
	quit(0 if failures==0 else 1)
