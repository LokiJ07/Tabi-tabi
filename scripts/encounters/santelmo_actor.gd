extends Node3D
## Authored Night 1 Santelmo encounter motion. Visual signals are readable without sound.
## The creature never crosses the dangerous river margin toward the player.

const HOME := Vector3(-8.0, 1.7, 13.0)
const RETREAT := Vector3(-8.5, 2.1, 17.0)
const SAFE_LANDING := Vector3(-6.7, 0.28, 9.0)
const GUIDED_LIGHT := Vector3(-7.15, 1.75, 10.2)
const CALM := Color(1.0, 0.77, 0.32)
const STARTLED := Color(1.0, 0.24, 0.17)

var alarm := 0.0
var time := 0.0
var light: OmniLight3D
var body: MeshInstance3D
var phase := 0
var false_reflection: Node3D
var true_reflection: Node3D
var landing_marker: Node3D
var guide_progress := 0.0


func _ready() -> void:
	name = "Santelmo"
	position = HOME
	body = MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.36
	ball.height = 0.72
	body.mesh = ball
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = CALM
	body.material_override = mat
	add_child(body)
	light = OmniLight3D.new()
	light.name = "Glow"
	light.omni_range = 5.0
	light.light_color = CALM
	add_child(light)
	true_reflection = _make_reflection("CURRENT_ALIGNED", Vector3(-8.0, 0.28, 15.5), CALM)
	false_reflection = _make_reflection("FALSE_MIRROR", Vector3(-5.0, 0.28, 15.5), Color(0.4, 0.8, 0.95))
	landing_marker = _make_reflection("SAFE_LANDING_GUIDE", SAFE_LANDING, Color(0.45, 0.95, 0.69))
	set_encounter_phase(0)


func _make_reflection(id: String, at: Vector3, tint: Color) -> Node3D:
	var node := Node3D.new()
	node.name = id
	node.position = at - HOME
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.55
	shape.bottom_radius = 0.55
	shape.height = 0.06
	mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = tint
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.70
	mesh.material_override = mat
	node.add_child(mesh)
	add_child(node)
	return node


func set_encounter_phase(value: int) -> void:
	phase = value
	if true_reflection != null:
		true_reflection.visible = phase == 2
	if false_reflection != null:
		false_reflection.visible = phase == 2
	if landing_marker != null:
		landing_marker.visible = phase == 3


func set_guide_progress(value: float) -> void:
	guide_progress = clampf(value, 0.0, 1.0)


func update_behavior(delta: float, player_position: Vector3, direction: Vector3, focusing: bool) -> float:
	time += delta
	var vector_to_light := global_position - player_position
	vector_to_light.y = 0.0
	var aligned := vector_to_light.length() < 10.0 and vector_to_light.length() > 0.1 and direction.dot(vector_to_light.normalized()) > 0.88
	var harsh_light := focusing and aligned
	alarm = clampf(alarm + (delta * 0.65 if harsh_light else -delta * 0.25), 0.0, 1.0)
	var retreat_amount := smoothstep(0.25, 0.85, alarm)
	var destination := HOME.lerp(RETREAT, retreat_amount)
	if phase == 3 and guide_progress > 0.0:
		destination = destination.lerp(GUIDED_LIGHT, guide_progress * (1.0 - 0.5 * retreat_amount))
	destination.y += 0.20 * sin(time * 2.6)
	position = position.lerp(destination, minf(1.0, delta * 3.0))
	light.light_color = CALM.lerp(STARTLED, retreat_amount).lerp(Color(1.0, 0.92, 0.62), guide_progress * 0.7)
	light.light_energy = 1.7 + 0.45 * sin(time * 4.6) + retreat_amount * 1.1
	var material := body.material_override as StandardMaterial3D
	material.albedo_color = CALM.lerp(STARTLED, retreat_amount).lerp(Color(1.0, 0.92, 0.62), guide_progress * 0.7)
	# Fixed world-space puzzle markers do not follow the hovering spirit.
	if true_reflection != null:
		true_reflection.global_position = Vector3(-8.0, 0.28, 15.5 + 0.22 * sin(time * 1.25))
	if false_reflection != null:
		false_reflection.global_position = Vector3(-5.0, 0.28, 15.5 + 0.55 * sin(time * 4.25))
	if landing_marker != null:
		landing_marker.global_position = SAFE_LANDING
		if landing_marker.visible:
			var marker_mesh := landing_marker.get_child(0) as MeshInstance3D
			var marker_material := marker_mesh.material_override as StandardMaterial3D
			marker_material.albedo_color.a = 0.56 + 0.18 * sin(time * 2.2)
	return alarm


func reflection_near(point: Vector3, max_distance: float = 1.7) -> String:
	if phase != 2:
		return ""
	for node in [true_reflection, false_reflection]:
		var diff: Vector3 = node.global_position - point
		diff.y = 0.0
		if diff.length() <= max_distance:
			return str(node.name)
	return ""
