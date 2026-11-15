extends Node3D
## G1 engine/input spike: an explorable prototype, NOT the completed Night 1.
## All primitive geometry is temporary and must be replaced by approved art.

const PLAYER_SPEED := 4.2
const COLORS := {
	"earth": Color(0.30, 0.33, 0.23),
	"river": Color(0.09, 0.35, 0.47),
	"path": Color(0.49, 0.39, 0.27),
	"wood": Color(0.46, 0.27, 0.15),
	"roof": Color(0.35, 0.15, 0.13),
	"leaf": Color(0.20, 0.36, 0.17),
}
var player: CharacterBody3D
var bantay: Node3D
var camera: Camera3D
var lantern: SpotLight3D
var info: Label
var objective: Label
var dialogue: PanelContainer
var dialogue_text: Label
var touch_axes := Vector2.ZERO
var move_buttons: Dictionary = {}
var is_night := false
var talked_to_lola := false
var talked_to_dado := false
var encountered_light := false
var santelmo: Node3D
var elapsed := 0.0


func _ready() -> void:
	_create_world()
	_create_player()
	_create_bantay()
	_create_camera()
	_create_lighting()
	_create_ui()
	_update_objective()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var axis := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	axis += touch_axes
	axis = axis.limit_length()
	var forward := Vector3(-1, 0, -1).normalized()
	var right := Vector3(1, 0, -1).normalized()
	var desired := (right * axis.x + forward * -axis.y).normalized()
	player.velocity.x = desired.x * PLAYER_SPEED
	player.velocity.z = desired.z * PLAYER_SPEED
	if not player.is_on_floor():
		player.velocity.y -= 24.0 * delta
	else:
		player.velocity.y = -0.1
	player.move_and_slide()
	if desired.length() > 0.05:
		player.rotation.y = atan2(desired.x, desired.z)
		lantern.rotation.y = -player.rotation.y
	# A simple follow/stop behavior for the prototype. Navigation is a later gate.
	var offset := player.global_position - bantay.global_position
	offset.y = 0.0
	if offset.length() > 2.3:
		bantay.global_position += offset.normalized() * minf(delta * 3.5, offset.length() - 2.0)
	if offset.length() > 0.1:
		bantay.rotation.y = atan2(offset.x, offset.z)
	camera.global_position = camera.global_position.lerp(player.global_position + Vector3(12, 17, 12), minf(1.0, delta * 4.0))
	camera.look_at(player.global_position + Vector3(0, 0.7, 0))
	elapsed += delta
	if is_night and santelmo != null:
		santelmo.position.y = 1.7 + 0.23 * sin(elapsed * 2.7)
		var child_light := santelmo.get_node_or_null("Glow") as OmniLight3D
		if child_light != null:
			child_light.light_energy = 1.7 + 0.5 * sin(elapsed * 4.8)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_interact()
	if event.is_action_pressed("ui_cancel"):
		_close_dialogue()


func _create_world() -> void:
	_box("Ground", Vector3(0, -0.35, 0), Vector3(46, 0.65, 46), COLORS.earth, true)
	_box("Main footpath", Vector3(0, 0.015, 0), Vector3(5, 0.08, 38), COLORS.path, false)
	_box("River", Vector3(-16, 0.02, 0), Vector3(12, 0.08, 46), COLORS.river, false)
	_box("River bank safety fence", Vector3(-9.7, 0.5, 0), Vector3(0.25, 1.0, 35), COLORS.wood, true)
	_house(Vector3(6, 0, 5), "Lola's hut")
	_house(Vector3(7, 0, -8), "Sabel's store")
	_house(Vector3(-2, 0, -12), "School")
	_box("Landing", Vector3(-7, 0.1, 9), Vector3(4.1, 0.3, 3.2), COLORS.wood, false)
	for x in [-19.0, -13.0, 13.0, 19.0]:
		for z in [-18.0, -5.0, 14.0]:
			_tree(Vector3(x, 0, z))
	_marker("LOLA", Vector3(4, 0.1, 7), Color(0.9, 0.73, 0.44))
	_marker("DADO", Vector3(-5, 0.1, 7), Color(0.42, 0.68, 0.83))
	_marker("MOORING", Vector3(-7, 0.1, 13), Color(0.8, 0.76, 0.49))


func _box(name: String, pos: Vector3, size: Vector3, color: Color, solid: bool) -> Node3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	mesh.position = pos
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.name = name + " collision"
		var collider := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		collider.shape = box
		body.position = pos
		body.add_child(collider)
		add_child(body)
	return mesh


func _house(pos: Vector3, name: String) -> void:
	_box(name, pos + Vector3(0, 1.2, 0), Vector3(4, 2.4, 4), COLORS.wood, true)
	_box(name + " roof", pos + Vector3(0, 2.75, 0), Vector3(5.0, 0.5, 5.0), COLORS.roof, false)


func _tree(pos: Vector3) -> void:
	_box("Trunk", pos + Vector3(0, 1.15, 0), Vector3(0.6, 2.3, 0.6), COLORS.wood, true)
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.7
	sphere.height = 3.1
	crown.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLORS.leaf
	crown.material_override = mat
	crown.position = pos + Vector3(0, 3.3, 0)
	add_child(crown)


func _marker(key: String, pos: Vector3, color: Color) -> void:
	var node := Node3D.new()
	node.name = key
	node.position = pos
	add_child(node)
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.42
	sphere.height = 0.84
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	mesh.position.y = 0.7
	node.add_child(mesh)


func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Apprentice"
	player.position = Vector3(0, 0.45, 2)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.5
	shape.shape = capsule
	player.add_child(shape)
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.5
	body.mesh = mesh
	body.position.y = 0.35
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.73, 0.42)
	body.material_override = mat
	player.add_child(body)
	add_child(player)


func _create_bantay() -> void:
	bantay = Node3D.new()
	bantay.name = "Bantay (prototype)"
	bantay.position = Vector3(1.6, 0.55, 2.1)
	var dog := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.27
	mesh.height = 0.9
	dog.mesh = mesh
	dog.rotation.x = PI / 2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.51, 0.28)
	dog.material_override = mat
	bantay.add_child(dog)
	add_child(bantay)


func _create_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Isometric Camera"
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 16
	add_child(camera)


func _create_lighting() -> void:
	var sunlight := DirectionalLight3D.new()
	sunlight.name = "Sun"
	sunlight.rotation_degrees = Vector3(-55, -25, 0)
	sunlight.light_energy = 1.1
	add_child(sunlight)
	lantern = SpotLight3D.new()
	lantern.name = "Lantern prototype"
	lantern.position = Vector3(0.3, 1.4, -0.4)
	lantern.light_color = Color(1.0, 0.68, 0.32)
	lantern.light_energy = 0.0
	lantern.spot_range = 11
	lantern.spot_angle = 55
	player.add_child(lantern)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.48, 0.68, 0.72)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.74, 0.79)
	env.ambient_light_energy = 0.65
	environment.environment = env
	environment.name = "Environment"
	add_child(environment)


func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	info = Label.new()
	info.position = Vector2(25, 16)
	info.text = "TABI-TABI  •  NIGHT 1 FOUNDATION"
	info.add_theme_font_size_override("font_size", 24)
	root.add_child(info)
	objective = Label.new()
	objective.position = Vector2(25, 56)
	objective.add_theme_font_size_override("font_size", 18)
	root.add_child(objective)
	_make_button(root, "◀", Vector2(20, 575), Vector2(70, 65), func(): _set_button_axis("left", true), func(): _set_button_axis("left", false))
	_make_button(root, "▶", Vector2(170, 575), Vector2(70, 65), func(): _set_button_axis("right", true), func(): _set_button_axis("right", false))
	_make_button(root, "▲", Vector2(95, 505), Vector2(70, 65), func(): _set_button_axis("up", true), func(): _set_button_axis("up", false))
	_make_button(root, "▼", Vector2(95, 645), Vector2(70, 65), func(): _set_button_axis("down", true), func(): _set_button_axis("down", false))
	_make_button(root, "INTERACT", Vector2(1050, 565), Vector2(180, 60), _interact, func(): pass)
	_make_button(root, "DAY / NIGHT", Vector2(1050, 640), Vector2(180, 56), _toggle_night, func(): pass)
	dialogue = PanelContainer.new()
	dialogue.position = Vector2(320, 510)
	dialogue.custom_minimum_size = Vector2(700, 145)
	root.add_child(dialogue)
	dialogue_text = Label.new()
	dialogue_text.custom_minimum_size = Vector2(680, 125)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_size_override("font_size", 23)
	dialogue.add_child(dialogue_text)
	dialogue.hide()


func _make_button(parent: Control, title: String, pos: Vector2, size: Vector2, down: Callable, up: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.position = pos
	button.custom_minimum_size = size
	button.size = size
	button.button_down.connect(down)
	button.button_up.connect(up)
	parent.add_child(button)


func _set_button_axis(direction: String, active: bool) -> void:
	move_buttons[direction] = active
	touch_axes = Vector2(
		float(move_buttons.get("right", false)) - float(move_buttons.get("left", false)),
		float(move_buttons.get("down", false)) - float(move_buttons.get("up", false))
	)


func _interact() -> void:
	if dialogue.visible:
		_close_dialogue()
		return
	var closest := ""
	var distance := 3.4
	for key in ["LOLA", "DADO", "MOORING"]:
		var mark := get_node_or_null(key) as Node3D
		if mark == null:
			continue
		var d := player.global_position.distance_to(mark.global_position)
		if d < distance:
			closest = key
			distance = d
	match closest:
		"LOLA":
			talked_to_lola = true
			_show_dialogue("LOLA PASING: Ayaw una isulat ang imong gituohan. Paminaw sa, dayon pangita og pamatuod.")
		"DADO":
			talked_to_dado = true
			_show_dialogue("TATAY DADO: Gamay nga kahayag. Kung akong tutokan, mosibog. Kung molingi ko, murag naghulat.")
		"MOORING":
			if is_night:
				encountered_light = true
				_show_dialogue("The river light flickers near the old mooring. This is a preview only; the Santelmo puzzle is not implemented yet.")
			else:
				_show_dialogue("A weathered mooring by the river. An older name seems to be missing from the record.")
		_:
			_show_dialogue("Move close to Lola, Dado, or the old mooring to interact.")
	_update_objective()


func _show_dialogue(value: String) -> void:
	dialogue_text.text = value + "\n\n[INTERACT or ENTER to close]"
	dialogue.show()


func _close_dialogue() -> void:
	dialogue.hide()


func _toggle_night() -> void:
	is_night = not is_night
	lantern.light_energy = 4.5 if is_night else 0.0
	var env_node := get_node_or_null("Environment") as WorldEnvironment
	if env_node != null:
		env_node.environment.background_color = Color(0.04, 0.10, 0.22) if is_night else Color(0.48, 0.68, 0.72)
	if is_night and santelmo == null:
		santelmo = Node3D.new()
		santelmo.name = "Santelmo (visual preview)"
		santelmo.position = Vector3(-7.0, 1.7, 13.0)
		var body := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.36
		sphere.height = 0.72
		body.mesh = sphere
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.95, 0.78, 0.29)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		body.material_override = material
		santelmo.add_child(body)
		var glow := OmniLight3D.new()
		glow.name = "Glow"
		glow.light_color = Color(1.0, 0.7, 0.25)
		glow.omni_range = 5.0
		santelmo.add_child(glow)
		add_child(santelmo)
	if santelmo != null:
		santelmo.visible = is_night
	_update_objective()


func _update_objective() -> void:
	if not talked_to_lola:
		objective.text = "OBJECTIVE: Speak to Lola Pasing (gold marker)."
	elif not talked_to_dado:
		objective.text = "OBJECTIVE: Meet Tatay Dado by the river (blue marker)."
	elif not is_night:
		objective.text = "OBJECTIVE: Inspect the old mooring, then tap DAY / NIGHT."
	elif not encountered_light:
		objective.text = "OBJECTIVE: Visit the old mooring at night."
	else:
		objective.text = "FOUNDATION PREVIEW COMPLETE: Santelmo encounter gameplay is next."
