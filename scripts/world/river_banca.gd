extends RefCounted
## Original mobile-friendly banca: a tapered low-poly wooden riverboat mesh,
## outriggers, bamboo supports, fishing crossbars, seating and paddle.

const ROOT_NAME := "OldRiverBanca"


static func build(parent: Node3D, at: Vector3) -> Node3D:
	var existing := parent.get_node_or_null(ROOT_NAME) as Node3D
	if existing != null:
		return existing
	var boat := Node3D.new()
	boat.name = ROOT_NAME
	boat.position = at
	parent.add_child(boat)

	var body := MeshInstance3D.new()
	body.name = "Tapered hull"
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z_stations := [-1.85, -1.12, 0.0, 1.18, 1.84]
	var half_widths := [0.07, 0.61, 0.72, 0.55, 0.08]
	for i in range(z_stations.size() - 1):
		var za: float = z_stations[i]
		var zb: float = z_stations[i + 1]
		var wa: float = half_widths[i]
		var wb: float = half_widths[i + 1]
		for side in [-1.0, 1.0]:
			var a := Vector3(wa * side, 0.32, za)
			var b := Vector3(wb * side, 0.32, zb)
			var c := Vector3(wb * side * 0.34, 0.02, zb)
			var d := Vector3(wa * side * 0.34, 0.02, za)
			_triangle(tool, a, b, c)
			_triangle(tool, a, c, d)
			# A narrow lip thickens the open gunwale.
			_triangle(tool, a, b, b + Vector3(0, 0.075, 0))
			_triangle(tool, a, b + Vector3(0, 0.075, 0), a + Vector3(0, 0.075, 0))
		# Keel and bottom shell.
		_triangle(tool, Vector3(-wa * 0.34, 0.02, za), Vector3(-wb * 0.34, 0.02, zb), Vector3(wb * 0.34, 0.02, zb))
		_triangle(tool, Vector3(-wa * 0.34, 0.02, za), Vector3(wb * 0.34, 0.02, zb), Vector3(wa * 0.34, 0.02, za))
	tool.generate_normals()
	body.mesh = tool.commit()
	body.material_override = _wood(Color("#684632"))
	boat.add_child(body)

	for z in [-0.87, 0.20, 1.05]:
		_box(boat, "Interior seating plank", Vector3(0.0, 0.27, z), Vector3(1.12, 0.09, 0.25), Color("#a17d52"))
	# Slim outriggers and bamboo crossbars make it recognizable as a banca.
	for side in [-1.0, 1.0]:
		_box(boat, "Outrigger beam", Vector3(1.30 * side, 0.31, -0.43), Vector3(2.15, 0.08, 0.10), Color("#b29264"))
		_box(boat, "Rear outrigger beam", Vector3(1.28 * side, 0.29, 0.70), Vector3(2.10, 0.08, 0.10), Color("#b29264"))
		_box(boat, "Bamboo float", Vector3(2.20 * side, 0.06, 0.02), Vector3(0.20, 0.21, 3.10), Color("#9b865d"))
		_box(boat, "Float binding", Vector3(2.20 * side, 0.19, -0.72), Vector3(0.32, 0.06, 0.12), Color("#5d4434"))
		_box(boat, "Float binding", Vector3(2.20 * side, 0.19, 0.63), Vector3(0.32, 0.06, 0.12), Color("#5d4434"))
	_box(boat, "Painterly boat rib", Vector3(0.0, 0.22, -1.2), Vector3(0.68, 0.12, 0.13), Color("#ac8657"))
	_box(boat, "Boat paddle blade", Vector3(0.50, 0.38, 1.04), Vector3(0.22, 0.07, 0.64), Color("#aa8c63"))
	var paddle := _box(boat, "Boat paddle handle", Vector3(0.50, 0.39, 0.12), Vector3(0.06, 0.06, 1.25), Color("#c6a16f"))
	paddle.rotation.y = 0.15
	return boat


static func animate(boat: Node3D, time: float, reduced_motion: bool) -> void:
	if boat == null:
		return
	boat.rotation.z = 0.0 if reduced_motion else 0.012 * sin(time * 1.55)
	boat.rotation.x = 0.0 if reduced_motion else 0.009 * sin(time * 0.96)
	boat.scale = Vector3.ONE


static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)


static func _wood(shade: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = shade
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


static func _box(parent: Node3D, label: String, at: Vector3, size3: Vector3, shade: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.position = at
	var box := BoxMesh.new()
	box.size = size3
	instance.mesh = box
	instance.material_override = _wood(shade)
	parent.add_child(instance)
	return instance
