extends RefCounted
## G6 visual-only estuary dressing: batched ground detail and safe, localized props.
## Never changes collisions, navigation, story clues, or save payloads.
const ROOT_NAME := "BarrioLawomArtPolish"

static func decorate(world: Node3D) -> Node3D:
	var existing := world.get_node_or_null(ROOT_NAME) as Node3D
	if existing != null:
		return existing
	var root := Node3D.new()
	root.name = ROOT_NAME
	world.add_child(root)
	# Shoreline changes from a hard teal rectangle into an irregular tidal edge.
	# All the detail is non-colliding, including near Santelmo's landing.
	for i in range(21):
		var z := -19.1 + float(i) * 1.86
		var x := -9.65 + 0.42 * sin(float(i) * 1.43)
		_rock(root, "Tidal stone %02d" % i, Vector3(x, 0.06, z),
			Vector3(0.63 + 0.23 * float(i % 3), 0.16, 0.39 + 0.12 * float(i % 2)),
			Color("#8a8061") if i % 3 == 0 else Color("#77785d"))
	# One MultiMesh per detail type keeps phone draw-call costs predictable.
	_scattered_gravel(root)
	_tidal_reeds(root)
	_path_leaves(root)
	# Fisherman's landing and shop get small readable visual storytelling pieces.
	for i in range(7):
		_wood(root, "Landing board grain %d" % i,
			Vector3(-8.62 + float(i) * 0.49, 0.321, 9.0),
			Vector3(0.025, 0.018, 2.72),
			Color("#bf9161") if i % 2 == 0 else Color("#734a35"))
	for i in range(5):
		_wood(root, "Woven fish drying rack %d" % i,
			Vector3(5.0 + float(i) * 0.36, 1.05, 0.85),
			Vector3(0.25, 0.30, 0.045),
			Color("#9c8f6d") if i % 2 == 0 else Color("#b7a588"))
	_wood(root, "Fish drying rack crossbar", Vector3(5.72, 1.28, 0.85), Vector3(2.2, 0.09, 0.10), Color("#79573f"))
	_wood(root, "Fish drying rack stand left", Vector3(4.8, 0.72, 0.84), Vector3(0.10, 1.20, 0.10), Color("#806044"))
	_wood(root, "Fish drying rack stand right", Vector3(6.68, 0.72, 0.84), Vector3(0.10, 1.20, 0.10), Color("#806044"))
	root.set_meta("art_only", true)
	return root

static func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.94
	return mat

static func _wood(parent: Node3D, tag: String, at: Vector3, dimensions: Vector3, color: Color) -> void:
	var piece := MeshInstance3D.new()
	piece.name = tag
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	piece.mesh = mesh
	piece.material_override = _material(color)
	piece.position = at
	parent.add_child(piece)

static func _rock(parent: Node3D, tag: String, at: Vector3, size3: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = tag
	var stone := SphereMesh.new()
	stone.radial_segments = 7
	stone.rings = 4
	instance.mesh = stone
	instance.scale = size3
	instance.position = at
	instance.material_override = _material(color)
	parent.add_child(instance)

static func _scatter(parent: Node3D, tag: String, mesh: Mesh, positions: Array[Vector3], dimensions: Array[Vector3], colors: Array[Color]) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = positions.size()
	for i in range(positions.size()):
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(dimensions[i]), positions[i]))
		multi.set_instance_color(i, colors[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = tag
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.96
	instance.material_override = mat
	instance.multimesh = multi
	parent.add_child(instance)

static func _scattered_gravel(parent: Node3D) -> void:
	var places: Array[Vector3] = []
	var sizes: Array[Vector3] = []
	var shades: Array[Color] = []
	for i in range(92):
		var z := -17.8 + float(i) * 0.38
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * (2.85 + float(i % 7) * 0.27)
		places.append(Vector3(x, 0.075, z))
		sizes.append(Vector3(0.22 + float(i % 3) * 0.09, 0.065, 0.22 + float(i % 4) * 0.07))
		shades.append(Color("#987e5a") if i % 3 == 0 else Color("#b49c72"))
	_scatter(parent, "Batched footpath stones", SphereMesh.new(), places, sizes, shades)

static func _tidal_reeds(parent: Node3D) -> void:
	var places: Array[Vector3] = []
	var sizes: Array[Vector3] = []
	var shades: Array[Color] = []
	for i in range(85):
		var z := -20.1 + float(i) * 0.49
		var x := -10.1 - float(i % 4) * 0.22
		places.append(Vector3(x, 0.28, z))
		sizes.append(Vector3(0.045, 0.45 + 0.12 * float(i % 3), 0.055))
		shades.append(Color("#66834f") if i % 2 == 0 else Color("#859456"))
	_scatter(parent, "Batched tidal reeds", CylinderMesh.new(), places, sizes, shades)

static func _path_leaves(parent: Node3D) -> void:
	var places: Array[Vector3] = []
	var sizes: Array[Vector3] = []
	var shades: Array[Color] = []
	for i in range(45):
		var z := -18.0 + float(i) * 0.83
		var x := 4.4 + float(i % 6) * 0.24
		places.append(Vector3(x, 0.066, z))
		sizes.append(Vector3(0.16 + 0.03 * float(i % 3), 0.025, 0.25))
		shades.append(Color("#6d8a47") if i % 2 == 0 else Color("#b49b4f"))
	_scatter(parent, "Batched village fallen leaves", SphereMesh.new(), places, sizes, shades)
