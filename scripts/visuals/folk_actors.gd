extends RefCounted
## Original procedural stand-ins for animated folk characters.
## Not final assets or motion-captured performances.

static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.87
	return m


static func part(parent: Node3D, label: String, kind: String, at: Vector3, scale3: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.position = at
	instance.scale = scale3
	if kind == "sphere":
		instance.mesh = SphereMesh.new()
	elif kind == "cylinder":
		instance.mesh = CylinderMesh.new()
	else:
		instance.mesh = BoxMesh.new()
	instance.material_override = material(color)
	parent.add_child(instance)
	return instance


static func person(role: String, shirt: Color, trousers: Color) -> Node3D:
	var actor := Node3D.new()
	actor.name = role
	part(actor, "Torso", "box", Vector3(0, 0.92, 0), Vector3(0.52, 0.69, 0.32), shirt)
	part(actor, "Neck", "cylinder", Vector3(0, 1.34, 0), Vector3(0.15, 0.18, 0.15), Color(0.66, 0.43, 0.29))
	part(actor, "Head", "sphere", Vector3(0, 1.61, 0), Vector3(0.25, 0.28, 0.23), Color(0.68, 0.45, 0.3))
	part(actor, "Hair", "sphere", Vector3(0, 1.77, -0.035), Vector3(0.26, 0.14, 0.24), Color(0.14, 0.10, 0.08))
	for side in [-1, 1]:
		var limb := Node3D.new()
		limb.name = "ArmLeft" if side < 0 else "ArmRight"
		limb.position = Vector3(0.34 * side, 1.24, 0)
		actor.add_child(limb)
		part(limb, "Sleeve", "box", Vector3(0, -0.24, 0), Vector3(0.18, 0.49, 0.2), shirt)
		part(limb, "Hand", "sphere", Vector3(0, -0.52, 0), Vector3(0.105, 0.12, 0.11), Color(0.68, 0.45, 0.3))
		var leg := Node3D.new()
		leg.name = "LegLeft" if side < 0 else "LegRight"
		leg.position = Vector3(0.16 * side, 0.64, 0)
		actor.add_child(leg)
		part(leg, "Pants", "box", Vector3(0, -0.28, 0), Vector3(0.2, 0.54, 0.22), trousers)
		part(leg, "Foot", "box", Vector3(0, -0.56, -0.08), Vector3(0.24, 0.15, 0.38), Color(0.20, 0.13, 0.09))
	if role == "Apprentice":
		part(actor, "SalakotCrown", "sphere", Vector3(0, 1.95, 0), Vector3(0.32, 0.16, 0.32), Color(0.65, 0.48, 0.24))
		part(actor, "SalakotBrim", "cylinder", Vector3(0, 1.87, 0), Vector3(0.51, 0.055, 0.51), Color(0.71, 0.54, 0.27))
	return actor


static func dog() -> Node3D:
	var actor := Node3D.new()
	actor.name = "BantayVisual"
	part(actor, "Body", "sphere", Vector3(0, 0.52, 0), Vector3(0.30, 0.32, 0.55), Color(0.66, 0.40, 0.23))
	part(actor, "Chest", "sphere", Vector3(0, 0.59, -0.29), Vector3(0.29, 0.28, 0.28), Color(0.85, 0.69, 0.46))
	part(actor, "Head", "sphere", Vector3(0, 0.90, -0.48), Vector3(0.29, 0.27, 0.3), Color(0.69, 0.42, 0.25))
	part(actor, "Muzzle", "sphere", Vector3(0, 0.79, -0.75), Vector3(0.17, 0.12, 0.21), Color(0.86, 0.68, 0.48))
	part(actor, "Nose", "sphere", Vector3(0, 0.84, -0.91), Vector3(0.085, 0.075, 0.08), Color(0.13, 0.12, 0.11))
	for side in [-1, 1]:
		part(actor, "EarLeft" if side < 0 else "EarRight", "box", Vector3(side * 0.22, 1.14, -0.46), Vector3(0.15, 0.28, 0.13), Color(0.42, 0.26, 0.16))
		for z in [-0.33, 0.32]:
			part(actor, "Paw", "cylinder", Vector3(side * 0.2, 0.23, z), Vector3(0.12, 0.39, 0.12), Color(0.63, 0.37, 0.21))
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.65, 0.53)
	actor.add_child(tail)
	var tail_mesh := part(tail, "TailShape", "cylinder", Vector3(0, 0.19, 0.18), Vector3(0.10, 0.49, 0.10), Color(0.63, 0.37, 0.21))
	tail_mesh.rotation.x = 0.8
	return actor


static func animate_person(actor: Node3D, time: float, moving: bool) -> void:
	var amount := 0.54 if moving else 0.04
	var swing := sin(time * 8.0) * amount
	var leg_l := actor.get_node_or_null("LegLeft") as Node3D
	var leg_r := actor.get_node_or_null("LegRight") as Node3D
	var arm_l := actor.get_node_or_null("ArmLeft") as Node3D
	var arm_r := actor.get_node_or_null("ArmRight") as Node3D
	if leg_l != null:
		leg_l.rotation.x = swing
	if leg_r != null:
		leg_r.rotation.x = -swing
	if arm_l != null:
		arm_l.rotation.x = -swing * 0.65
	if arm_r != null:
		arm_r.rotation.x = swing * 0.65


static func animate_dog(actor: Node3D, time: float, moving: bool, alert: bool) -> void:
	var tail := actor.get_node_or_null("Tail") as Node3D
	if tail != null:
		tail.rotation.y = sin(time * (11.0 if alert else 6.0)) * (0.50 if alert else 0.28)
	var body := actor.get_node_or_null("Body") as MeshInstance3D
	if body != null:
		body.position.y = 0.52 + (0.03 * sin(time * 11.0) if moving else 0.01 * sin(time * 2.0))
