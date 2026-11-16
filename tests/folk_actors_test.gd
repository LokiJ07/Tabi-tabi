extends SceneTree
const Actors = preload("res://scripts/visuals/folk_actors.gd")
var errors := 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, message: String) -> void:
	if not ok:
		errors += 1
		printerr("Character visual test: " + message)

func _run() -> void:
	var human: Node3D = Actors.person("Apprentice", Color(0.8, 0.5, 0.2), Color(0.2, 0.3, 0.4))
	root.add_child(human)
	_expect(human.get_node_or_null("SalakotBrim") != null, "player salakot silhouette")
	_expect(human.get_node_or_null("DimensionalBackPlane") is Sprite3D,
		"Apprentice has a real second 3D silhouette plane")
	_expect(human.get_node_or_null("GroundContactShadow") is MeshInstance3D,
		"Apprentice's contact shadow has genuine horizontal 3D geometry")
	_expect(human.get_node_or_null("LegLeft") != null, "articulated left leg")
	_expect(human.get_node_or_null("LegRight") != null, "articulated right leg")
	Actors.animate_person(human, 0.25, true)
	var left_leg := human.get_node_or_null("LegLeft") as Node3D
	_expect(left_leg != null and absf(left_leg.rotation.x) > 0.01, "leg responds to movement")
	var quiet: Node3D = Actors.person("Villager", Color(0.4, 0.4, 0.3), Color(0.3, 0.3, 0.3))
	root.add_child(quiet)
	_expect(quiet.get_node_or_null("SalakotBrim") == null, "civilian variation without player hat")
	var expected := {
		"LOLA": ["WovenShawl", "SilverBun", "LongSkirt"],
		"DADO": ["FishingHatBrim", "FisherVest", "Moustache"],
		"MARA": ["GlassesLeft", "Ledger", "TeacherCollarLeft"],
		"SABEL": ["IndigoHeadWrap", "MarketApron", "ApronPocket"]
	}
	var visible_shirts := {}
	for role in expected:
		var character: Node3D = Actors.person(role, Color.BLACK, Color.BLACK)
		root.add_child(character)
		_expect(character.get_meta("character_id") == role, "distinct character id " + role)
		for prop in expected[role]:
			_expect(character.get_node_or_null(prop) != null, role + " signature prop " + prop)
		var torso := character.get_node_or_null("Torso") as MeshInstance3D
		var color: Color = (torso.material_override as StandardMaterial3D).albedo_color
		_expect(not visible_shirts.has(color.to_html()), "distinct costume color " + role)
		visible_shirts[color.to_html()] = true
		character.queue_free()
	_expect(Actors.role_id("Lola seated") == "LOLA", "indoor Lola matches outside identity")
	_expect(Actors.identity("DADO")["name"] != Actors.identity("MARA")["name"], "speaker names remain distinct")
	var bantay: Node3D = Actors.dog()
	root.add_child(bantay)
	_expect(bantay.get_node_or_null("Tail") != null, "tail present")
	_expect(bantay.get_node_or_null("GroundContactShadow") is MeshInstance3D,
		"Bantay has grounded 3D contact shadow")
	_expect(bantay.get_node_or_null("Nose") != null, "face features present")
	Actors.animate_dog(bantay, 0.4, true, true)
	_expect(absf(bantay.get_node("Tail").rotation.y) > 0.01, "tail animation")
	human.queue_free()
	quiet.queue_free()
	bantay.queue_free()
	print("Character stand-in tests: ", "PASS" if errors == 0 else str(errors) + " failures")
	quit(0 if errors == 0 else 1)
