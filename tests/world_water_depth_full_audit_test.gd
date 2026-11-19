extends SceneTree
## Regression for real Android reports: black silhouettes, actors walking through
## floods, and disconnected / apparently flat river-crossing geometry.
const Walk = preload("res://scripts/world/shared_walkability_2d.gd")
const FolkActors = preload("res://scripts/visuals/folk_actors.gd")
const Depth = preload("res://scripts/visuals/layered_25d.gd")
const Landscape = preload("res://scripts/visuals/folklore_landscape_25d.gd")
const Residents = preload("res://scripts/world/postgame_residents.gd")
var failures := 0

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("World physics & depth audit: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Night 1 native 3D's dark duplicate plane must be BEHIND the faces,
	# not in front of them from the (+x,+z) isometric camera.
	var person := FolkActors.person("Apprentice",Color.WHITE,Color.WHITE)
	var art := person.get_node("IllustratedSprite") as Sprite3D
	var backing := person.get_node("DimensionalBackPlane") as Sprite3D
	var contact := person.get_node("GroundContactShadow") as MeshInstance3D
	check(backing.position.x < art.position.x and backing.position.z < art.position.z,
		"Night 1 dark 3D backing cannot occlude player/NPC faces")
	check(contact.position.y < art.position.y,
		"Night 1 contact shadow remains at floor, not across torso")
	person.free()

	# Night 3: the depicted water really is water, even after the finale.
	check(Walk.river_blocked(3,Vector2(0,430)),
		"Night 3 deep washout is impassable")
	check(Walk.river_blocked(3,Vector2(-60,580)),
		"Night 3 lower ravine is impassable")
	for dry in [Vector2(-530,138),Vector2(-395,-378),Vector2(120,245),
			Vector2(375,-425),Vector2(220,50),Vector2(-160,-295)]:
		check(not Walk.river_blocked(3,dry),
			"Night 3 evidence, lookout and false-fork remain on authored raised paths: "+str(dry))
	check(Walk.safe_river_crossing(3,Vector2(120,245)),
		"Night 3 heel-mark clue has a dry stone route")

	# Night 6: bank and deep water boundaries persist in every story phase
	# and free roam; only the three stones / restored landing stay walkable.
	check(Walk.river_blocked(6,Vector2(-800,500)),
		"Night 6 unmarked river is solid non-walkable terrain")
	check(Walk.river_blocked(6,Vector2(-800,245),23.0),
		"rising flood also updates physical shore, not just painted shore")
	for dry in [Vector2(-705,-85),Vector2(180,175),Vector2(-382,-260),
			Vector2(-310,50),Vector2(-425,80),
			Vector2(270,275),Vector2(475,363),Vector2(690,458),
			Vector2(1020,610)]:
		check(not Walk.river_blocked(6,dry,23.0),
			"Night 6 critical clue or stone landing stays reachable: "+str(dry))
	check(Walk.slide(6,Vector2(-800,80),Vector2(-800,560),23.0).y < 242.0,
		"held joystick cannot tunnel across Night 6 river at low FPS")
	check(not Walk.river_blocked(6,Vector2(1010,395)),
		"Night 7 to Night 6 connected arrival remains on dry elevated hill road")
	check(not Walk.river_blocked(6,Vector2(1088,375)),
		"Night 6 Balete transition is never isolated by its river mask")
	check(Walk.river_blocked(7,Vector2(-1000,750)),
		"Night 7 flood channel has collision")
	check(not Walk.river_blocked(7,Vector2(-785,416)),
		"Night 7 connected road stays traversable")
	check(not Walk.is_blocked(7,Vector2(210,220)),
		"Night 7 ancient trial still accessible")
	for region in ["old_mango","night03","night04","night05","night06","night07"]:
		var chapter := int({
			"old_mango":2,"night03":3,"night04":4,
			"night05":5,"night06":6,"night07":7
		}[region])
		for worker in Residents.ACTORS[region]:
			var safe := Residents.grounded_activity(region,worker,"morning")
			check(not Walk.is_blocked(chapter,safe),
				"postgame " + str(worker["id"]) + " cannot stand in water, trees or house")
	check(Depth.STYLE_ID == "shared-2.5d-layered-v1",
		"all story chapters retain the same authored actor style")
	check(Landscape.PASS_ID == "nights1-3-landscape-depth-v2",
		"raised trail painter remains aligned with original world visual language")
	print("Water collision, 2.5D actor depth, story crossroads and all-night safety: ",
		"PASS" if failures == 0 else "%d failures" % failures)
	quit(0 if failures == 0 else 1)
