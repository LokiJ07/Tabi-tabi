extends RefCounted
## Hand-positioned riverside details for a richer Barrio Lawom silhouette.
## Visual-only props intentionally do not alter tested player collision/nav.
const ROOT_NAME := "BarrioEnvironmentDetails"


static func decorate(world: Node3D) -> Node3D:
	var old := world.get_node_or_null(ROOT_NAME) as Node3D
	if old != null:
		return old
	var root := Node3D.new()
	root.name = ROOT_NAME
	world.add_child(root)
	# Different silhouettes make Lola's home, Mara's school and Sabel's store
	# recognizable without a floating billboard or stretched text.
	_building(root, "Lola woven home", Vector3(6, 0, 5), Color("#b29463"), Color("#67513c"), 0)
	_building(root, "Sabel riverside store", Vector3(7, 0, -8), Color("#a88780"), Color("#83575a"), 1)
	_building(root, "Mara schoolhouse", Vector3(-2, 0, -12), Color("#b2a17c"), Color("#486e72"), 2)
	# Specific riverside objects tell the old-landing story without requiring a label.
	_box(root, "Old rope coil", Vector3(-7.7, 0.24, 12.8), Vector3(0.64, 0.11, 0.59), Color("#c1a279"))
	_box(root, "Mooring weathered plank", Vector3(-8.1, 0.23, 13.45), Vector3(1.20, 0.12, 0.21), Color("#654331"))
	for i in range(3):
		_box(root, "Landing rope rail %d" % i, Vector3(-8.88 + i * 0.95, 0.52, 10.35), Vector3(0.13, 0.72, 0.13), Color("#7f6345"))
	_barrel(root, Vector3(-5.6, 0.15, 6.1), "Fishing basket")
	_barrel(root, Vector3(-6.35, 0.15, 5.3), "Creel")
	_box(root, "Dado fishing pole", Vector3(-6.5, 0.75, 6.25), Vector3(0.065, 1.9, 0.065), Color("#96714e"))
	_box(root, "Mara document stand", Vector3(-1.25, 0.42, -9.85), Vector3(0.84, 0.68, 0.55), Color("#5f5549"))
	_box(root, "Mara ledger sign", Vector3(-1.25, 0.82, -9.56), Vector3(0.58, 0.36, 0.055), Color("#e0d2ac"))
	_barrel(root, Vector3(9.8, 0.15, -6.3), "Store goods basket")
	_barrel(root, Vector3(9.7, 0.15, -7.5), "Store woven basket")
	_box(root, "Store market tray", Vector3(9.6, 0.57, -8.7), Vector3(1.65, 0.11, 0.78), Color("#806348"))
	for i in range(5):
		var leaf_color := Color("#bb9b4d") if i % 2 == 0 else Color("#a76e45")
		_sphere(root, "Market produce %d" % i, Vector3(9.0 + float(i % 3) * 0.45, 0.70, -8.9 + float(i / 3) * 0.45), Vector3(0.28, 0.20, 0.26), leaf_color)
	# A little weathering, cloth, and bamboo around the living village.
	for i in range(6):
		var x: float = 11.0 + float(i % 3) * 1.35
		var z: float = -15.0 + float(i / 3) * 13.0
		_plant(root, Vector3(x, 0, z), i)
	for i in range(9):
		var z := -17.0 + float(i) * 4.1
		_plant(root, Vector3(-10.4 - float(i % 2) * 0.55, 0, z), i + 10)
	# Amber path lamps have very small light ranges to protect older Android GPUs.
	_lantern(root, Vector3(-4.0, 0, 9.0), "Riverside lantern", true)
	_lantern(root, Vector3(2.8, 0, -2.0), "Village lantern", false)
	return root


static func _box(parent: Node3D, label: String, at: Vector3, dimensions: Vector3, shade: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = shade
	mat.roughness = 0.9
	instance.material_override = mat
	parent.add_child(instance)
	return instance


static func _sphere(parent: Node3D, label: String, at: Vector3, scale3: Vector3, shade: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = SphereMesh.new()
	instance.position = at
	instance.scale = scale3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = shade
	mat.roughness = 0.88
	instance.material_override = mat
	parent.add_child(instance)


static func _building(root: Node3D, tag: String, at: Vector3, wall: Color, accent: Color, kind: int) -> void:
	var structure := Node3D.new()
	structure.name = tag
	structure.position = at
	root.add_child(structure)
	_box(structure, "Woven wall stripe", Vector3(0, 1.25, 2.02), Vector3(3.7, 0.20, 0.06), wall)
	# Woven bamboo has a distinct rhythm/texture rather than one flat wall.
	for i in range(9):
		var x: float = -1.82 + float(i) * 0.43
		_box(structure, "Nipa facade bamboo strip %d" % i, Vector3(x, 1.46, 2.10), Vector3(0.043, 2.06, 0.045), Color("#c29c69") if i % 2 == 0 else Color("#876647"))
	for i in range(5):
		var y := 0.58 + float(i) * 0.40
		_box(structure, "Woven horizontal rib %d" % i, Vector3(0, y, 2.12), Vector3(3.77, 0.052, 0.043), Color("#9d794e"))
	_box(structure, "Nipa wall lower trim", Vector3(0, 0.35, 2.15), Vector3(3.9, 0.17, 0.12), Color("#654635"))
	_box(structure, "Front door", Vector3(-0.35, 0.89, 2.045), Vector3(1.15, 1.76, 0.06), accent.darkened(0.22))
	_box(structure, "Door frame lintel", Vector3(-0.35, 1.85, 2.11), Vector3(1.35, 0.13, 0.14), wall.lightened(0.2))
	_box(structure, "Windowsill", Vector3(1.10, 1.18, 2.09), Vector3(0.74, 0.10, 0.16), Color("#c1a17a"))
	_box(structure, "Dark window", Vector3(1.10, 1.53, 2.15), Vector3(0.64, 0.57, 0.04), Color("#1b343b"))
	_box(structure, "Open window shutter", Vector3(1.55, 1.53, 2.17), Vector3(0.30, 0.61, 0.08), accent)
	_box(structure, "Window cross brace", Vector3(1.10, 1.53, 2.18), Vector3(0.06, 0.59, 0.05), Color("#d2b383"))
	for side in [-1, 1]:
		var roof := _box(structure, "Layered roof %d" % side, Vector3(1.24 * side, 3.06, 0), Vector3(2.94, 0.15, 4.72), accent)
		roof.rotation.z = 0.19 * float(side)
		_box(structure, "Under eave %d" % side, Vector3(2.1 * side, 2.86, 0), Vector3(0.14, 0.18, 4.45), Color("#74533d"))
		for j in range(5):
			var thatch := _box(structure, "Layered roof cap %d_%d" % [side, j],
				Vector3(1.24 * side, 3.17, -1.75 + float(j) * 0.88),
				Vector3(3.04, 0.045, 0.43), Color("#957451") if j % 2 == 0 else Color("#71523e"))
			thatch.rotation.z = 0.19 * float(side)
	_box(structure, "Raised porch edge", Vector3(0, 0.18, 2.46), Vector3(3.2, 0.16, 0.76), Color("#72513c"))
	for j in range(6):
		_box(structure, "Porch floorboards %d" % j, Vector3(-1.37 + float(j) * 0.56, 0.28, 2.5),
			Vector3(0.46, 0.035, 0.76), Color("#9a7047") if j % 2 == 0 else Color("#b08a5b"))
	if kind == 0:
		_box(structure, "Lola woven mat", Vector3(1.16, 0.35, 2.52), Vector3(0.93, 0.06, 0.48), Color("#ba9563"))
		_box(structure, "Lola flower pot", Vector3(2.28, 0.33, 2.5), Vector3(0.4, 0.50, 0.38), Color("#8c5643"))
	elif kind == 1:
		_box(structure, "Store awning", Vector3(0.16, 2.42, 2.65), Vector3(3.4, 0.14, 1.42), Color("#98785f"))
		_box(structure, "Store counter", Vector3(1.4, 0.78, 2.67), Vector3(1.14, 0.45, 0.59), Color("#705344"))
	else:
		_box(structure, "School flag cloth", Vector3(-1.6, 2.1, 2.09), Vector3(0.45, 0.62, 0.04), Color("#62858f"))
		_box(structure, "School slate", Vector3(1.27, 1.58, 2.11), Vector3(0.85, 0.59, 0.07), Color("#354f4d"))


static func _barrel(parent: Node3D, at: Vector3, name: String) -> void:
	var c := MeshInstance3D.new()
	c.name = name
	var body := CylinderMesh.new()
	body.top_radius = 0.39
	body.bottom_radius = 0.32
	body.height = 0.61
	c.mesh = body
	c.position = at + Vector3(0, 0.30, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#846444")
	c.material_override = mat
	parent.add_child(c)


static func _plant(parent: Node3D, at: Vector3, seed: int) -> void:
	var palette := [Color("#627d48"), Color("#50733e"), Color("#819052"), Color("#667b4c")]
	for i in range(3):
		var shade: Color = palette[(seed + i) % palette.size()]
		var blade := _box(parent, "Riverbank grass %d_%d" % [seed, i], at + Vector3(0.14 * float(i - 1), 0.30 + 0.11 * float(i), 0.10 * float(i - 1)), Vector3(0.09, 0.65 + 0.1 * float(i), 0.12), shade)
		blade.rotation.z = 0.16 * float(i - 1)


static func _lantern(parent: Node3D, at: Vector3, name: String, lit: bool) -> void:
	var post := Node3D.new()
	post.name = name
	post.position = at
	parent.add_child(post)
	_box(post, "Bamboo post", Vector3(0, 1.1, 0), Vector3(0.16, 2.2, 0.16), Color("#7e6649"))
	_box(post, "Lantern roof", Vector3(0, 2.30, 0), Vector3(0.43, 0.13, 0.43), Color("#624938"))
	_box(post, "Amber glass", Vector3(0, 2.03, 0), Vector3(0.29, 0.38, 0.29), Color("#e2af62"))
	if lit:
		var lamp := OmniLight3D.new()
		lamp.name = "Safe walkway amber spill"
		lamp.position = Vector3(0, 2.05, 0)
		lamp.light_color = Color("#ffbd78")
		lamp.light_energy = 0.38
		lamp.omni_range = 3.5
		post.add_child(lamp)
