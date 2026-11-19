extends SceneTree
## Regression for water, actor-shadow and raised-path complaints from Android.
## All coordinates are the actual drawn polygons/bridge routes of Night 3/6/7.
const Walk = preload("res://scripts/world/shared_walkability_2d.gd")
const Landscape = preload("res://scripts/visuals/folklore_landscape_25d.gd")
const Depth = preload("res://scripts/visuals/layered_25d.gd")
const N3 = preload("res://scenes/night03.tscn")
const N6 = preload("res://scenes/night06.tscn")
const N7 = preload("res://scenes/night07.tscn")
var failures := 0

func check(ok: bool,why: String) -> void:
	if not ok:
		failures += 1
		printerr("Seven-night water and depth: "+why)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	check(Depth.STYLE_ID == "shared-2.5d-layered-v1",
		"all chapters must retain the same actor rendering style")
	check(Landscape.has_method("paint_raised_trail") and
		Landscape.has_method("paint_timber_crossing"),
		"shared raised paths and footbridges must compile")
	# N3 ravine: formerly only the center 145px rectangle was solid.
	for at in [Vector2(-10,400),Vector2(65,550),Vector2(130,-340)]:
		check(Walk.is_water_blocked(3,at),
			"Night 3 unmarked blue ravine must block %s" % at)
	for at in [Vector2(0,130),Vector2(0,250),
			Vector2(105,-118),Vector2(200,-470)]:
		check(not Walk.is_water_blocked(3,at),
			"Night 3 visible ford/raised bridge must allow %s" % at)
	for at in [Vector2(-530,138),Vector2(-395,-378),
			Vector2(120,245),Vector2(375,-425)]:
		check(not Walk.is_blocked(3,at),
			"Night 3 story clue must remain reachable at %s" % at)
	# River 6: a solid water region from the drawn left bank to map edge.
	for at in [Vector2(-700,600),Vector2(90,490),Vector2(300,600)]:
		check(Walk.is_water_blocked(6,at),
			"Night 6 deep or unmarked floodwater must block %s" % at)
	for at in [Vector2(270,275),Vector2(475,363),Vector2(690,458),
			Vector2(488,224),Vector2(940,343)]:
		check(not Walk.is_water_blocked(6,at),
			"Night 6 safe stones/preparation and hill crossing must allow %s" % at)
	for at in [Vector2(-705,-85),Vector2(180,175),
			Vector2(-382,-260),Vector2(-310,50)]:
		check(not Walk.is_blocked(6,at),
			"Night 6 essential flood testimony stays reachable at %s" % at)
	# Night 7 high-water corner is not land, but the Night 6 route is.
	check(Walk.is_water_blocked(7,Vector2(-1100,650)),
		"Night 7 south-west flood channel must not be traversable")
	check(not Walk.is_water_blocked(7,Vector2(-970,490)) and
		not Walk.is_water_blocked(7,Vector2(210,220)),
		"Night 7 road arrival and Balete trial stones remain walkable")
	# Swept collision blocks rivers even at larger physics deltas.
	var entered := Walk.slide(3,Vector2(-310,420),Vector2(55,410))
	check(not Walk.is_water_blocked(3,entered),
		"swept Night 3 player cannot tunnel through the ravine")
	var entered6 := Walk.slide(6,Vector2(-700,100),Vector2(-700,580))
	check(not Walk.is_water_blocked(6,entered6),
		"swept Night 6 player cannot enter deep river")
	# Older saves may have their player standing IN the river.
	for chapter in [3,6,7]:
		var bad := Vector2(-10,400) if chapter==3 else (
			Vector2(-700,600) if chapter==6 else Vector2(-1100,650))
		var rescued := Walk.repair_saved_position(chapter,bad)
		check(not Walk.is_blocked(chapter,rescued),
			"saved player recovers onto nearby dry ground on Night %d" % chapter)
	# The existing playable Godot scenes must load with these boundaries.
	for packed in [N3,N6,N7]:
		var scene := packed.instantiate()
		check(scene != null and scene.has_method("_draw"),
			"actual chapter scene still loads and paints")
		if scene != null: scene.free()
	print("Seven-night river collision, path elevation and actor grounding: ",
		"PASS" if failures==0 else "%d failures" % failures)
	quit(0 if failures==0 else 1)
