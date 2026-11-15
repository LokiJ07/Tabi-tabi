extends RefCounted
## Night 1 authored character identities. Procedural mobile-friendly meshes are
## interchangeable stand-ins until final rigged art is approved.

static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.86
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


static func role_id(role: String) -> String:
	var name := role.to_upper()
	if name.contains("LOLA"):
		return "LOLA"
	if name.contains("DADO"):
		return "DADO"
	if name.contains("MARA"):
		return "MARA"
	if name.contains("SABEL"):
		return "SABEL"
	if name.contains("APPRENTICE"):
		return "APPRENTICE"
	return "RESIDENT"


static func identity(role: String) -> Dictionary:
	match role_id(role):
		"LOLA":
			return {"name": "Lola Pasing", "shirt": Color("#8d654c"), "pants": Color("#4f4544"), "skin": Color("#bb8a67"), "hair": Color("#bdada0"), "accent": Color("#d3b98b")}
		"DADO":
			return {"name": "Tatay Dado", "shirt": Color("#547987"), "pants": Color("#46453b"), "skin": Color("#a97550"), "hair": Color("#37302b"), "accent": Color("#d3a768")}
		"MARA":
			return {"name": "Teacher Mara", "shirt": Color("#4e806e"), "pants": Color("#3f5055"), "skin": Color("#bd8e6b"), "hair": Color("#302721"), "accent": Color("#d1c29a")}
		"SABEL":
			return {"name": "Aling Sabel", "shirt": Color("#76506f"), "pants": Color("#41394d"), "skin": Color("#b78464"), "hair": Color("#28282c"), "accent": Color("#c8957c")}
		"APPRENTICE":
			return {"name": "Apprentice", "shirt": Color("#b28952"), "pants": Color("#3e5058"), "skin": Color("#c28c61"), "hair": Color("#292622"), "accent": Color("#d6ae6d")}
	return {"name": "Villager", "shirt": Color("#657464"), "pants": Color("#48483b"), "skin": Color("#ad805e"), "hair": Color("#39312b"), "accent": Color("#a5b38c")}


static func person(role: String, shirt: Color, trousers: Color) -> Node3D:
	var key := role_id(role)
	var profile := identity(role)
	if key != "RESIDENT":
		shirt = profile["shirt"]
		trousers = profile["pants"]
	var skin: Color = profile["skin"]
	var hair: Color = profile["hair"]
	var accent: Color = profile["accent"]
	var actor := Node3D.new()
	actor.name = role
	actor.set_meta("character_id", key)
	var broad := 0.62 if key == "DADO" else 0.43 if key == "MARA" else 0.50
	part(actor, "Torso", "box", Vector3(0, 0.94, 0), Vector3(broad, 0.68, 0.34), shirt)
	part(actor, "Neck", "cylinder", Vector3(0, 1.32, 0), Vector3(0.14, 0.18, 0.15), skin)
	part(actor, "Head", "sphere", Vector3(0, 1.59, 0), Vector3(0.25, 0.28, 0.23), skin)
	part(actor, "Hair", "sphere", Vector3(0, 1.79, 0.025), Vector3(0.264, 0.13, 0.235), hair)
	part(actor, "Nose", "sphere", Vector3(0, 1.55, -0.235), Vector3(0.062, 0.084, 0.09), skin.darkened(0.11))
	for side in [-1, 1]:
		var label := "Left" if side < 0 else "Right"
		part(actor, "Eye" + label, "sphere", Vector3(0.104 * side, 1.64, -0.217), Vector3(0.039, 0.04, 0.025), Color("#25221f"))
		part(actor, "Brow" + label, "box", Vector3(0.104 * side, 1.705, -0.216), Vector3(0.105, 0.025, 0.024), hair)
		var limb := Node3D.new()
		limb.name = "ArmLeft" if side < 0 else "ArmRight"
		limb.position = Vector3((broad * 0.61 + 0.08) * side, 1.24, 0)
		actor.add_child(limb)
		part(limb, "Sleeve", "box", Vector3(0, -0.24, 0), Vector3(0.18, 0.49, 0.2), shirt)
		part(limb, "Hand", "sphere", Vector3(0, -0.52, 0), Vector3(0.105, 0.12, 0.11), skin)
		var leg := Node3D.new()
		leg.name = "LegLeft" if side < 0 else "LegRight"
		leg.position = Vector3(0.16 * side, 0.64, 0)
		actor.add_child(leg)
		part(leg, "Pants", "box", Vector3(0, -0.28, 0), Vector3(0.2, 0.54, 0.22), trousers)
		part(leg, "Foot", "box", Vector3(0, -0.56, -0.08), Vector3(0.24, 0.15, 0.38), Color("#382b24"))
	match key:
		"LOLA":
			actor.scale = Vector3(0.96, 0.94, 1.0)
			part(actor, "WovenShawl", "box", Vector3(0, 1.23, 0.08), Vector3(0.70, 0.25, 0.41), accent)
			part(actor, "ShawlHem", "box", Vector3(0, 1.11, -0.197), Vector3(0.59, 0.055, 0.06), Color("#7f4542"))
			part(actor, "LongSkirt", "cylinder", Vector3(0, 0.52, 0), Vector3(0.61, 0.76, 0.52), trousers)
			part(actor, "SilverBun", "sphere", Vector3(0, 1.73, 0.20), Vector3(0.21, 0.20, 0.20), hair)
			part(actor, "ForeheadCrease", "box", Vector3(0, 1.735, -0.205), Vector3(0.27, 0.015, 0.02), Color("#947660"))
		"DADO":
			part(actor, "FishingHatCrown", "cylinder", Vector3(0, 1.88, 0), Vector3(0.34, 0.21, 0.34), accent.darkened(0.23))
			part(actor, "FishingHatBrim", "cylinder", Vector3(0, 1.80, 0), Vector3(0.62, 0.035, 0.56), accent)
			part(actor, "FisherVest", "box", Vector3(0, 1.01, -0.19), Vector3(0.44, 0.54, 0.07), Color("#65634a"))
			part(actor, "ShoulderRope", "box", Vector3(-0.20, 1.17, -0.24), Vector3(0.055, 0.55, 0.052), Color("#d1b28a"))
			part(actor, "Moustache", "box", Vector3(0, 1.49, -0.243), Vector3(0.19, 0.032, 0.035), hair)
		"MARA":
			part(actor, "TeacherCollarLeft", "box", Vector3(-0.14, 1.22, -0.21), Vector3(0.21, 0.14, 0.07), accent)
			part(actor, "TeacherCollarRight", "box", Vector3(0.14, 1.22, -0.21), Vector3(0.21, 0.14, 0.07), accent)
			part(actor, "TiedHair", "sphere", Vector3(0, 1.72, 0.21), Vector3(0.18, 0.22, 0.14), hair)
			part(actor, "Ledger", "box", Vector3(0.41, 0.79, -0.24), Vector3(0.35, 0.46, 0.09), Color("#7c5745"))
			part(actor, "LedgerPages", "box", Vector3(0.41, 0.79, -0.30), Vector3(0.30, 0.41, 0.025), accent)
			for side in [-1, 1]:
				part(actor, "Glasses" + ("Left" if side < 0 else "Right"), "box", Vector3(side * 0.10, 1.645, -0.247), Vector3(0.17, 0.10, 0.022), Color("#cbb486"))
		"SABEL":
			part(actor, "IndigoHeadWrap", "sphere", Vector3(0, 1.81, 0.03), Vector3(0.29, 0.13, 0.24), Color("#6e526d"))
			part(actor, "HeadWrapKnot", "sphere", Vector3(0.21, 1.87, 0.06), Vector3(0.12, 0.13, 0.11), Color("#b88c93"))
			part(actor, "MarketApron", "box", Vector3(0, 0.90, -0.197), Vector3(0.42, 0.62, 0.066), accent)
			part(actor, "ApronPocket", "box", Vector3(0, 0.73, -0.243), Vector3(0.24, 0.14, 0.027), Color("#815c5a"))
			part(actor, "Bangles", "cylinder", Vector3(0.43, 0.73, 0), Vector3(0.15, 0.09, 0.15), Color("#d6af76"))
		"APPRENTICE":
			part(actor, "SalakotCrown", "sphere", Vector3(0, 1.95, 0), Vector3(0.32, 0.16, 0.32), Color("#ad8954"))
			part(actor, "SalakotBrim", "cylinder", Vector3(0, 1.87, 0), Vector3(0.51, 0.055, 0.51), accent)
			part(actor, "NotebookSatchel", "box", Vector3(0.34, 0.80, -0.02), Vector3(0.21, 0.36, 0.32), Color("#72503a"))
			part(actor, "BagStrap", "box", Vector3(0.1, 1.13, -0.2), Vector3(0.065, 0.68, 0.04), Color("#523d30"))
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
