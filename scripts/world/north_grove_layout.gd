extends RefCounted
## Shared north-grove composition for native 3D and Android's Canvas fallback.
## All objects are visual-only and lie east of the 3m-wide walkable route.
const FLOOR_TEXTURE = preload("res://assets/world/north_grove_understory.svg")
const FLOOR_PATCHES := [
	{"center": Vector3(12.0, 0.105, -25.4), "size": Vector2(13.0, 14.0)},
	{"center": Vector3(24.0, 0.106, -31.1), "size": Vector2(17.0, 17.0)},
	{"center": Vector3(14.0, 0.107, -37.8), "size": Vector2(15.0, 15.0)},
	{"center": Vector3(29.0, 0.105, -44.5), "size": Vector2(18.0, 18.0)},
	{"center": Vector3(16.5, 0.108, -50.0), "size": Vector2(15.0, 15.0)}
]

static func decorate(world: Node3D) -> Node3D:
	var previous := world.get_node_or_null("NorthernGroveUnderstory") as Node3D
	if previous != null:
		return previous
	var root := Node3D.new()
	root.name = "NorthernGroveUnderstory"
	world.add_child(root)
	for i in range(FLOOR_PATCHES.size()):
		var layout: Dictionary = FLOOR_PATCHES[i]
		var node := MeshInstance3D.new()
		node.name = "North grove floor painting %02d" % i
		var plane := PlaneMesh.new()
		plane.size = layout["size"]
		node.mesh = plane
		node.position = layout["center"]
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = FLOOR_TEXTURE
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 1.0
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		node.material_override = mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(node)
	root.set_meta("visual_only", true)
	return root
