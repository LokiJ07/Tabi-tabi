extends RefCounted
## Actual imported 2.5D environment illustrations in the playable 3D village.
## Every placement is authored around safe traversal; art does not alter collisions.
const ROOT_NAME := "Night1IllustratedWorld"
const ROOTS: Texture2D = preload("res://assets/world/mangrove_illustrated.svg")
const FLOWERS: Texture2D = preload("res://assets/world/hibiscus_bush.svg")
const BANANA: Texture2D = preload("res://assets/world/banana_plant.svg")
const NORTH_FOREST: Texture2D = preload("res://assets/world/north_forest_tree.svg")
const LANTERN: Texture2D = preload("res://assets/world/lantern_post.svg")
const NIPA: Texture2D = preload("res://assets/world/nipa_facade.svg")
const SCHOOL: Texture2D = preload("res://assets/world/school_facade.svg")
const MARKET: Texture2D = preload("res://assets/world/market_facade.svg")
const PATH_TEXTURE: Texture2D = preload("res://assets/world/earthen_path.svg")

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

	# Shape the old rectangular flat road into a winding, textured dirt track.
	# This is a new visual mesh; ground collisions and original road node survive.
	_build_organic_footpath(root)
	_build_tidal_shore(root)
	_build_stilt_rope_fence(root)

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

	# The northern forest connector must not end in empty colored space.
	# Tidal trees stay west of the path; inland banana and flowers frame the
	# old mango grove entrance without obstructing player collision.
	for i in range(7):
		var north_z := -24.3 - float(i) * 2.13
		_sprite(root, "Northern estuary mangrove %02d" % i, ROOTS,
			Vector3(-16.5 - float(i % 2) * 3.0, 2.38, north_z), 0.0071, true, i % 3 == 0)
	for i in range(8):
		var north_z := -23.1 - float(i) * 1.91
		_sprite(root, "Northern village foliage %02d" % i, BANANA,
			Vector3(9.0 + float(i % 3) * 2.7, 2.24, north_z),
			0.0078, true, i % 3 == 1)
	for i in range(7):
		var north_z := -23.5 - float(i) * 1.99
		_sprite(root, "Old Mango route wildflowers %02d" % i, FLOWERS,
			Vector3(4.7 + float(i % 3) * .5, .87, north_z),
			0.0051, true, i % 2 == 0)
	# The north-bound route opens into a real wooded upland, not empty
	# green terrain. These illustrated Visayan broadleaf silhouettes sit
	# BEYOND the safe trail, so they add depth without blocking collision.
	var upland: Array[Vector3] = [
		Vector3(9.5, 3.85, -30), Vector3(12.5, 3.72, -27),
		Vector3(15.5, 3.92, -25), Vector3(9.0, 3.68, -26),
		Vector3(13, 3.72, -34), Vector3(18, 3.85, -40),
		Vector3(23, 3.80, -35), Vector3(28, 4.10, -42),
		Vector3(33, 3.70, -34), Vector3(37, 4.20, -47),
		Vector3(16, 3.95, -48), Vector3(25, 4.00, -51),
		Vector3(9, 3.58, -45), Vector3(33, 4.00, -53)
	]
	for i in range(upland.size()):
		_sprite(root, "Northern wild broadleaf %02d" % i, NORTH_FOREST,
			upland[i], 0.0061 + float(i % 3) * .0008, true, i % 2 == 0)
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

static func _path_center(z: float) -> float:
	return 0.54 * sin(z * 0.20) + 0.23 * sin(z * 0.54)

static func _path_half_width(z: float) -> float:
	return 2.50 + 0.24 * sin(z * 0.36 + 1.1)

static func _build_organic_footpath(parent: Node3D) -> void:
	var trail := SurfaceTool.new()
	trail.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.albedo_texture = PATH_TEXTURE
	mat.roughness = 0.96
	trail.set_material(mat)
	for i in range(90):
		var z0 := -38.0 + float(i) * (58.5 / 90.0)
		var z1 := -38.0 + float(i + 1) * (58.5 / 90.0)
		var x0 := _path_center(z0)
		var x1 := _path_center(z1)
		var w0 := _path_half_width(z0)
		var w1 := _path_half_width(z1)
		var l0 := Vector3(x0 - w0, 0.071, z0)
		var r0 := Vector3(x0 + w0, 0.071, z0)
		var l1 := Vector3(x1 - w1, 0.071, z1)
		var r1 := Vector3(x1 + w1, 0.071, z1)
		for v in [l0, l1, r0, r0, l1, r1]:
			trail.set_normal(Vector3.UP)
			trail.set_uv(Vector2(v.x * 0.20, v.z * 0.23))
			trail.add_vertex(v)
	var mesh := MeshInstance3D.new()
	mesh.name = "Winding illustrated earthen path"
	mesh.mesh = trail.commit()
	parent.add_child(mesh)

## Shared shore profile. Only wet mud / stranded sand occupies this band.
## Unlike the original hard straight boundary, its lip bends with the tide.
static func _tidal_edge(z: float) -> float:
	return -10.07 + 0.34 * sin(z * 0.43) + 0.14 * sin(z * 1.16 + 0.7)


static func _build_tidal_shore(parent: Node3D) -> void:
	# Three low-poly textured strips are cheaper than hundreds of tiny decals.
	# Collision remains the original tested invisible river bank boundary.
	for strip in range(3):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var material := StandardMaterial3D.new()
		material.albedo_texture = PATH_TEXTURE
		material.albedo_color = [Color("#77735b"), Color("#80775b"), Color("#9b916d")][strip]
		material.roughness = 0.98
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		tool.set_material(material)
		for i in range(90):
			var za := -38.0 + float(i) * (60.0 / 90.0)
			var zb := -38.0 + float(i + 1) * (60.0 / 90.0)
			var xa := _tidal_edge(za)
			var xb := _tidal_edge(zb)
			var left_a := xa - 0.78 + float(strip) * 0.42
			var right_a := left_a + 0.54
			var left_b := xb - 0.78 + float(strip) * 0.42
			var right_b := left_b + 0.54
			var height := 0.105 + float(strip) * 0.007
			var a := Vector3(left_a, height, za)
			var b := Vector3(right_a, height, za)
			var c := Vector3(left_b, height, zb)
			var d := Vector3(right_b, height, zb)
			for v in [a, c, b, b, c, d]:
				tool.set_normal(Vector3.UP)
				tool.set_uv(Vector2(v.x * 0.28, v.z * 0.17))
				tool.add_vertex(v)
		var mesh := MeshInstance3D.new()
		mesh.name = ["Estuary wet mud margin", "Irregular tidal shelf", "Sandy riverbank lip"][strip]
		mesh.mesh = tool.commit()
		mesh.set_meta("non_collider", true)
		parent.add_child(mesh)


static func _build_stilt_rope_fence(parent: Node3D) -> void:
	# Safety collision remains unchanged; visible wall is replaced by spaced
	# hand-sized posts and narrow woven ropes along the estuary.
	for i in range(17):
		var z := -21.0 + 2.62 * float(i)
		var node := MeshInstance3D.new()
		node.name = "Tidal safety bamboo pole %02d" % i
		node.position = Vector3(-9.72, 0.55, z)
		var stem := CylinderMesh.new()
		stem.top_radius = 0.083
		stem.bottom_radius = 0.12
		stem.height = 1.28
		node.mesh = stem
		var bark := StandardMaterial3D.new()
		bark.albedo_color = Color("#8b6649")
		bark.roughness = 0.92
		node.material_override = bark
		parent.add_child(node)
	for level in range(2):
		for i in range(16):
			var rope := MeshInstance3D.new()
			rope.name = "Estuary woven rope %d_%02d" % [level, i]
			rope.position = Vector3(-9.72, 0.61 + level * 0.35, -19.69 + 2.62 * float(i))
			var rail := CylinderMesh.new()
			rail.top_radius = 0.028
			rail.bottom_radius = 0.028
			rail.height = 2.59
			rope.mesh = rail
			rope.rotation.x = PI * 0.5
			var fiber := StandardMaterial3D.new()
			fiber.albedo_color = Color("#c3a575")
			fiber.roughness = 0.98
			rope.material_override = fiber
			parent.add_child(rope)
