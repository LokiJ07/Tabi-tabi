extends RefCounted
const FolkActors = preload("res://scripts/visuals/folk_actors.gd")
## Prototype player-controlled hut interior in a separate world pocket.
## All positions are authored. The exterior hut remains collidable and sealed.
## Transition uses interaction, never allows walking through walls.

const CENTER := Vector3(55.0, 0.0, 0.0)
const INSIDE_SPAWN := Vector3(55.0, 0.76, 1.3)
const OUTSIDE_SPAWN := Vector3(6.0, 0.76, 8.9)
const OUTSIDE_DOOR := Vector3(6.0, 0.15, 8.05)
const NODE_NAME := "LolaHutInterior"

static func build(world: Node3D) -> Dictionary:
	var existing := world.get_node_or_null(NODE_NAME) as Node3D
	if existing != null:
		return _targets(existing)
	var room := Node3D.new()
	room.name = NODE_NAME
	room.position = CENTER
	world.add_child(room)
	_box(room, "Bamboo floor", Vector3(0, -0.21, 0), Vector3(9, 0.4, 8), Color(0.49, 0.35, 0.23), true)
	_box(room, "Back woven wall", Vector3(0, 1.55, -4), Vector3(9, 3.1, 0.24), Color(0.63, 0.46, 0.28), true)
	_box(room, "Front woven wall", Vector3(0, 1.55, 4), Vector3(9, 3.1, 0.24), Color(0.55, 0.39, 0.25), true)
	_box(room, "Left woven wall", Vector3(-4.5, 1.55, 0), Vector3(0.24, 3.1, 8), Color(0.58, 0.43, 0.26), true)
	_box(room, "Right woven wall", Vector3(4.5, 1.55, 0), Vector3(0.24, 3.1, 8), Color(0.58, 0.43, 0.26), true)
	_box(room, "Woven rug", Vector3(0.0, 0.05, 0.1), Vector3(3.0, 0.07, 2.6), Color(0.62, 0.35, 0.23), false)
	_box(room, "Breakfast table", Vector3(1.25, 0.52, -0.65), Vector3(1.85, 0.22, 1.15), Color(0.30, 0.20, 0.13), false)
	_box(room, "Sleep mat", Vector3(-2.6, 0.15, 1.0), Vector3(1.8, 0.19, 2.5), Color(0.39, 0.30, 0.21), false)
	_box(room, "Blue cloth notebook", Vector3(-2.25, 0.42, -1.0), Vector3(0.65, 0.11, 0.49), Color(0.13, 0.33, 0.57), false)
	_box(room, "Warm pottery cup", Vector3(1.45, 0.75, -0.35), Vector3(0.3, 0.28, 0.3), Color(0.86, 0.71, 0.47), false)
	_box(room, "River family photograph", Vector3(2.75, 1.67, -3.75), Vector3(1.15, 0.88, 0.10), Color(0.47, 0.62, 0.61), false)
	_box(room, "Wooden exit door", Vector3(0, 1.20, 3.84), Vector3(1.7, 2.4, 0.18), Color(0.38, 0.23, 0.13), false)
	var light := OmniLight3D.new()
	light.name = "Warm morning lamp"
	light.position = Vector3(0, 2.75, 0)
	light.light_color = Color(1.0, 0.79, 0.54)
	light.light_energy = 1.25
	light.omni_range = 11.0
	room.add_child(light)
	var elder := FolkActors.person("Lola seated", Color(0.66, 0.47, 0.33), Color(0.32, 0.28, 0.31))
	elder.position = Vector3(-0.35, 0.0, -2.8)
	room.add_child(elder)
	_target(room, "LOLA_HOME", Vector3(-0.35, 0, -2.8))
	_target(room, "BLUE_NOTEBOOK", Vector3(-2.25, 0, -1.0))
	_target(room, "WARM_CUP", Vector3(1.45, 0, -0.35))
	_target(room, "RIVER_PHOTO", Vector3(2.75, 0, -3.0))
	_target(room, "HUT_EXIT", Vector3(0, 0, 3.1))
	return _targets(room)


static func _targets(room: Node3D) -> Dictionary:
	var output := {}
	for id in ["LOLA_HOME", "BLUE_NOTEBOOK", "WARM_CUP", "RIVER_PHOTO", "HUT_EXIT"]:
		output[id] = room.get_node(id)
	return output


static func _target(room: Node3D, id: String, at: Vector3) -> void:
	var node := Node3D.new()
	node.name = id
	node.position = at
	room.add_child(node)


static func _box(parent: Node3D, label: String, at: Vector3, dimensions: Vector3, color: Color, physical: bool) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var shape := BoxMesh.new()
	shape.size = dimensions
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	if physical:
		var body := StaticBody3D.new()
		body.name = label + " collision"
		body.position = at
		var collider := CollisionShape3D.new()
		var hitbox := BoxShape3D.new()
		hitbox.size = dimensions
		collider.shape = hitbox
		body.add_child(collider)
		parent.add_child(body)
