extends RefCounted
## Night 1's morning must visibly reflect the player's choice.
## Procedural placeholder art is deterministic and installed only once.

const NAME := "Night01MorningAftermath"
const RESULT_COLORS := {
	"resolve": Color(0.96, 0.72, 0.34),
	"drive_away": Color(0.29, 0.47, 0.66),
	"partial": Color(0.58, 0.51, 0.40)
}

static func ensure(world: Node3D, outcome: String) -> Node3D:
	if not RESULT_COLORS.has(outcome):
		return null
	var current := world.get_node_or_null(NAME) as Node3D
	if current != null:
		return current
	var visual := Node3D.new()
	visual.name = NAME
	visual.set_meta("night1_outcome", outcome)
	world.add_child(visual)
	var color: Color = RESULT_COLORS[outcome]
	var anchor := Vector3(-7.0, 0.18, 13.0)
	if outcome == "partial":
		anchor = Vector3(-4.6, 0.12, 9.0)
	# Ground marker is a readable clue to changed environment, not a magical ritual.
	var ring := MeshInstance3D.new()
	ring.name = "Aftermath ground marker"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.66
	cylinder.bottom_radius = 0.66
	cylinder.height = 0.07
	ring.mesh = cylinder
	ring.position = anchor
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	ring.material_override = mat
	visual.add_child(ring)
	var post := MeshInstance3D.new()
	post.name = "Aftermath cloth marker"
	var box := BoxMesh.new()
	box.size = Vector3(0.58, 0.12, 0.32)
	post.mesh = box
	post.position = anchor + Vector3(0, 0.43, 0)
	var fabric := StandardMaterial3D.new()
	fabric.albedo_color = color.darkened(0.10)
	post.material_override = fabric
	visual.add_child(post)
	if outcome == "resolve":
		var glow := OmniLight3D.new()
		glow.name = "Quiet remembered glow"
		glow.light_color = color
		glow.light_energy = 0.55
		glow.omni_range = 2.6
		glow.position = anchor + Vector3(0, 0.9, 0)
		visual.add_child(glow)
	return visual

static func morning_label(outcome: String) -> String:
	match outcome:
		"resolve":
			return "MORNING | THE BOATMAN REMEMBERED"
		"drive_away":
			return "MORNING | LANDING SAFE, MOORING UNEASY"
		"partial":
			return "MORNING | RETURNED SAFELY, QUESTIONS REMAIN"
	return ""
