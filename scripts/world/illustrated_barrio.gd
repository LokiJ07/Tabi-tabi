extends RefCounted
## Actual imported 2.5D environment illustrations in the playable 3D village.
## Every placement is authored around safe traversal; art does not alter collisions.
const ROOT_NAME := "Night1IllustratedWorld"
const ROOTS: Texture2D = preload("res://assets/world/mangrove_illustrated.svg")
const FLOWERS: Texture2D = preload("res://assets/world/hibiscus_bush.svg")
const BANANA: Texture2D = preload("res://assets/world/banana_plant.svg")
const LANTERN: Texture2D = preload("res://assets/world/lantern_post.svg")
const NIPA: Texture2D = preload("res://assets/world/nipa_facade.svg")
const SCHOOL: Texture2D = preload("res://assets/world/school_facade.svg")
const MARKET: Texture2D = preload("res://assets/world/market_facade.svg")

static func _sprite(parent: Node3D, title: String, texture: Texture2D, at: Vector3, pixel_size: float, face_camera: bool, flip: bool = false) -> Sprite3D:
	var art := Sprite3D.new()
	art.name = title
	art.texture = texture
	art.pixel_size = pixel_size
	art.position = at
	art.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if face_camera else BaseMaterial3D.BILLBOARD_DISABLED
	art.flip_h = flip
	art.shaded = false
	art.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	parent.add_child(art)
	return art

static func decorate(world: Node3D) -> Node3D:
	var old := world.get_node_or_null(ROOT_NAME) as Node3D
	if old != null:
		return old
	var root := Node3D.new()
	root.name = ROOT_NAME
	root.set_meta("decor_only", true)
	world.add_child(root)

	# Brackish tidal edge. Rooted mangroves sit in or next to shallow water,
	# NOT across the main dirt road or beside the far inland homes.
	var grove_positions := [
		Vector3(-19.3, 2.36, -18.1),
		Vector3(-14.0, 2.38, -13.1),
		Vector3(-18.7, 2.27, -4.9),
		Vector3(-14.2, 2.38, 1.7),
		Vector3(-18.4, 2.26, 9.0),
		Vector3(-13.9, 2.31, 16.3),
		Vector3(-11.4, 2.19, -15.3)
	]
	for i in range(grove_positions.size()):
		_sprite(root, "Painted estuary mangrove %02d" % i, ROOTS, grove_positions[i],
			0.0070 if i % 2 == 0 else 0.0063, true, i % 3 == 0)

	# Lush village silhouettes around the outside of the play path.
	# Still allows player interaction with Lola, Dado, Mara and Sabel.
	var banana_positions := [
		Vector3(14.5, 2.23, -19.3), Vector3(16.7, 2.12, -8.5),
		Vector3(14.8, 2.19, 3.8), Vector3(18.3, 2.20, 15.0),
		Vector3(11.2, 2.14, 17.9)
	]
	for i in range(banana_positions.size()):
		_sprite(root, "Illustrated banana clump %02d" % i, BANANA, banana_positions[i], 0.0082, true, i % 2 == 1)

	var flower_positions := [
		Vector3(9.0, 0.86, 10.8), Vector3(10.0, 0.86, 2.4),
		Vector3(9.7, 0.88, -4.4), Vector3(11.5, 0.86, -12.0),
		Vector3(-4.4, 0.91, -16.3), Vector3(-5.9, 0.89, -11.0),
		Vector3(-6.6, 0.92, 4.2), Vector3(-7.8, 0.88, 16.5)
	]
	for i in range(flower_positions.size()):
		_sprite(root, "Illustrated garden hibiscus %02d" % i, FLOWERS, flower_positions[i], 0.0050, true, i % 2 == 0)

	_sprite(root, "Painted river lamp", LANTERN, Vector3(-4.0, 1.63, 9.0), 0.0068, true)
	_sprite(root, "Painted marketplace lamp", LANTERN, Vector3(2.8, 1.63, -2.0), 0.0068, true)

	# Local facade overlays remain flush with each existing collidable house.
	# The established building nodes/porches are preserved, so story triggers
	# and player blocking don't change when the art replaces flat geometry.
	var village := world.get_node_or_null("BarrioEnvironmentDetails") as Node3D
	if village != null:
		_facade(village, "Lola woven home", NIPA, "Lola authored bamboo facade")
		_facade(village, "Sabel riverside store", MARKET, "Sabel illustrated market facade")
		_facade(village, "Mara schoolhouse", SCHOOL, "Mara illustrated school facade")
	return root

static func _facade(village: Node3D, house_name: String, texture: Texture2D, title: String) -> void:
	var house := village.get_node_or_null(house_name) as Node3D
	if house == null or house.get_node_or_null(title) != null:
		return
	_sprite(house, title, texture, Vector3(0, 1.49, 2.24), 0.00635, false)
