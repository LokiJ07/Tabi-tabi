extends RefCounted
## Visually identifiable mangroves for the shallow Barrio Lawom estuary.
## Faceted canopies, forked trunks and stilt roots: no ordinary orchard trees in
## the brackish river. Visuals only; never obstruct the path or gameplay.
const ROOT_NAME := "Mangrove"

static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.94
	return m

static func _segment(parent: Node3D, name: String, a: Vector3, b: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.name = name
	var geo := CylinderMesh.new()
	geo.radial_segments = 6
	geo.rings = 1
	geo.height = a.distance_to(b)
	geo.top_radius = radius * 0.76
	geo.bottom_radius = radius
	piece.mesh = geo
	piece.position = (a + b) * 0.5
	piece.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	piece.material_override = material(color)
	parent.add_child(piece)
	return piece

static func _canopy(parent: Node3D, name: String, at: Vector3, scale3: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var shape := SphereMesh.new()
	shape.radial_segments = 9
	shape.rings = 5
	mesh.mesh = shape
	mesh.position = at
	mesh.scale = scale3
	mesh.material_override = material(color)
	parent.add_child(mesh)

static func build(parent: Node3D, at: Vector3, index: int = 0) -> Node3D:
	var tree := Node3D.new()
	tree.name = "Mangrove_%d" % index
	tree.position = at
	parent.add_child(tree)
	var trunk := Color("#70513e") if index % 2 == 0 else Color("#806146")
	var high := 2.9 + float(index % 3) * 0.18
	_segment(tree, "GnarledTrunk", Vector3(0, 0.25, 0), Vector3(0.12, high, 0.04), 0.23, trunk)
	# Separate splayed roots visibly enter the shallow water, unlike a normal
	# cylindrical tree trunk standing on an empty blue surface.
	for i in range(6):
		var angle := TAU * float(i) / 6.0 + float(index) * 0.23
		var reach := 1.12 + float(i % 3) * 0.22
		var edge := Vector3(cos(angle) * reach, -0.07, sin(angle) * reach)
		var bend := Vector3(cos(angle) * reach * 0.48, 0.78, sin(angle) * reach * 0.48)
		_segment(tree, "PropRoot_%02d_A" % i, Vector3(0.06, 1.55, 0), bend, 0.097, trunk.darkened(0.12))
		_segment(tree, "PropRoot_%02d_B" % i, bend, edge, 0.072, trunk.darkened(0.20))
	# Fine tapering rootlets give depth beneath the main six structural stilts.
	# They sit outside the walkable path and have no collision shapes.
	for i in range(6):
		var root_angle := TAU * (float(i) + 0.5) / 6.0 + float(index) * 0.23
		var offset := Vector3(cos(root_angle), 0, sin(root_angle))
		var root_start := Vector3(0.10, 1.17, 0.03) + offset * 0.20
		var root_tip := offset * (0.82 + float(i % 2) * 0.24) + Vector3(0, -0.07, 0)
		_segment(tree, "FineStiltRoot_%02d" % i, root_start, root_tip, 0.045, trunk.darkened(0.23))
	# Short branches hold a broad, asymmetrical estuarine crown.
	for i in range(4):
		var angle := TAU * float(i) / 4.0 + 0.4
		var endpoint := Vector3(cos(angle) * 1.23, high + 0.42, sin(angle) * 1.20)
		_segment(tree, "Branch_%d" % i, Vector3(0.12, high - 0.42, 0.04), endpoint, 0.12, trunk)
	var greens := [
		Color("#355b3b"), Color("#426c3e"), Color("#557844"),
		Color("#62834a"), Color("#729051"), Color("#42613f")
	]
	_canopy(tree, "MainMangroveCrown", Vector3(0.12, high + 0.62, 0.0), Vector3(1.48, 0.86, 1.38), greens[index % greens.size()])
	for i in range(5):
		var angle := TAU * float(i) / 5.0 + float(index) * 0.4
		_canopy(tree, "MangroveLeafCluster_%d" % i,
			Vector3(cos(angle) * 1.15, high + 0.48 + 0.17 * float(i % 2), sin(angle) * 1.05),
			Vector3(0.85, 0.56, 0.76), greens[(i + index) % greens.size()])
	# Mangrove propagules dangle under the crown; an identifiable estuary
	# detail that differentiates these trees from ordinary rounded foliage.
	for i in range(4):
		var angle := TAU * float(i) / 4.0 + 0.32
		var x := cos(angle) * 0.78
		var z := sin(angle) * 0.71
		_segment(tree, "HangingPropagule_%d" % i,
			Vector3(x, high + 0.26, z),
			Vector3(x + 0.08, high - 0.28, z + 0.04),
			0.045, Color("#89a65a"))
	tree.set_meta("shore_tree", "mangrove")
	return tree
