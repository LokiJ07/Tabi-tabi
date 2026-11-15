extends Node3D
## G1 engine/input spike: an explorable prototype, NOT the completed Night 1.
## All primitive geometry is temporary and must be replaced by approved art.

const NightModel = preload("res://scripts/narrative/night01_state.gd")
const SantelmoActor = preload("res://scripts/encounters/santelmo_actor.gd")
const AimPad = preload("res://scripts/ui/aim_pad.gd")
const SaveService = preload("res://scripts/core/save_service.gd")
const PLAYER_SPEED := 4.2
const COLORS := {
	"earth": Color(0.30, 0.33, 0.23),
	"river": Color(0.09, 0.35, 0.47),
	"path": Color(0.49, 0.39, 0.27),
	"wood": Color(0.46, 0.27, 0.15),
	"roof": Color(0.35, 0.15, 0.13),
	"leaf": Color(0.20, 0.36, 0.17),
}
var story = NightModel.new()
var choice_buttons: Array[Button] = []
var stage_label: Label
var player: CharacterBody3D
var bantay: Node3D
var camera: Camera3D
var lantern: SpotLight3D
var info: Label
var objective: Label
var dialogue: PanelContainer
var dialogue_text: Label
var touch_axes := Vector2.ZERO
var focus_held := false
var manual_aim := Vector2.ZERO
var light_alarm := 0.0
var lamp_heading := Vector3.FORWARD
var alarm_label: Label
var move_buttons: Dictionary = {}
var is_night := false
var talked_to_lola := false
var talked_to_dado := false
var encountered_light := false
var santelmo
var ambient_walkers: Array[Node3D] = []
var elapsed := 0.0


func _ready() -> void:
	_create_world()
	_create_ambient_walkers()
	_create_player()
	_create_bantay()
	_create_camera()
	_create_lighting()
	_create_ui()
	_restore_story()
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
		if not focus_held:
			lamp_heading = desired
	# Manual right-thumb stick direction is independent from walking.
	if focus_held and manual_aim.length() > 0.15:
		lamp_heading = (right * manual_aim.x + forward * -manual_aim.y).normalized()
	if lamp_heading.length() > 0.1:
		lantern.global_rotation.y = atan2(-lamp_heading.x, -lamp_heading.z)
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
		light_alarm = santelmo.update_behavior(delta, player.global_position, lamp_heading, focus_held)
		story.alarm = light_alarm
		alarm_label.text = "Santelmo: %s  |  Strong Focus makes it retreat" % ("ALARMED: lower your light" if light_alarm > 0.65 else "watching" if light_alarm > 0.2 else "calm")
	for i in range(ambient_walkers.size()):
		var villager := ambient_walkers[i]
		villager.visible = not is_night
		if not is_night:
			villager.position.z = -4.0 + 0.7 * sin(elapsed * (0.4 + 0.13 * float(i)) + float(i) * 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_interact()
	if event.is_action_pressed("ui_focus_next"):
		focus_held = true
	if event.is_action_released("ui_focus_next"):
		focus_held = false
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
	_marker("SABEL", Vector3(3, 0.1, -5), Color(0.75, 0.5, 0.8))
	_marker("MARA", Vector3(-2, 0.1, -8), Color(0.42, 0.82, 0.61))


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


func _create_ambient_walkers() -> void:
	# Low-cost sample NPC routines. These remain temporary geometry.
	for i in range(2):
		var villager := Node3D.new()
		villager.name = "AmbientResident_%d" % i
		villager.position = Vector3(1.0 + float(i) * 2.0, 0.65, -4.0)
		var mesh := MeshInstance3D.new()
		var shape := CapsuleMesh.new()
		shape.radius = 0.25
		shape.height = 1.25
		mesh.mesh = shape
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.64 + 0.13 * i, 0.52, 0.37 + 0.12 * i)
		mesh.material_override = mat
		villager.add_child(mesh)
		add_child(villager)
		ambient_walkers.append(villager)


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
	var aim_pad := AimPad.new()
	aim_pad.anchor_left = 1.0
	aim_pad.anchor_right = 1.0
	aim_pad.anchor_top = 1.0
	aim_pad.anchor_bottom = 1.0
	aim_pad.offset_left = -435
	aim_pad.offset_right = -260
	aim_pad.offset_top = -205
	aim_pad.offset_bottom = -40
	aim_pad.aim_changed.connect(_on_aim_changed)
	aim_pad.aim_released.connect(_on_aim_released)
	root.add_child(aim_pad)
	_make_button(root, "FOCUS", Vector2(1050, 490), Vector2(180, 60), func(): _set_focus(true), func(): _set_focus(false))
	_make_button(root, "INTERACT", Vector2(1050, 565), Vector2(180, 60), _interact, func(): pass)
	_make_button(root, "DAY / NIGHT", Vector2(1050, 640), Vector2(180, 56), _toggle_night, func(): pass)
	_make_button(root, "NOTEBOOK", Vector2(1050, 415), Vector2(180, 56), _open_notebook, func(): pass)
	_make_button(root, "SAVE", Vector2(1050, 345), Vector2(85, 52), _save_story, func(): pass)
	_make_button(root, "RETRY", Vector2(1142, 345), Vector2(88, 52), _retry_story, func(): pass)
	stage_label = Label.new()
	stage_label.position = Vector2(25, 125)
	stage_label.add_theme_font_size_override("font_size", 19)
	root.add_child(stage_label)
	for i in range(3):
		var index := i
		var action := Button.new()
		action.name = "Choice %d" % i
		action.anchor_left = 0.5
		action.anchor_right = 0.5
		action.anchor_top = 1.0
		action.anchor_bottom = 1.0
		action.offset_left = -300 + i * 205
		action.offset_right = action.offset_left + 200
		action.offset_top = -255
		action.offset_bottom = -200
		action.pressed.connect(func(): _choose_story_action(index))
		root.add_child(action)
		choice_buttons.append(action)
	_refresh_choices()
	alarm_label = Label.new()
	alarm_label.position = Vector2(25, 95)
	alarm_label.add_theme_font_size_override("font_size", 18)
	root.add_child(alarm_label)
	dialogue = PanelContainer.new()
	dialogue.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue.offset_left = -350
	dialogue.offset_right = 350
	dialogue.offset_top = -180
	dialogue.offset_bottom = -35
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
	# Anchor controls to bottom corners so they remain reachable on wider phones.
	button.anchor_left = 1.0 if pos.x > 900 else 0.0
	button.anchor_right = button.anchor_left
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = pos.x - (1280.0 if pos.x > 900 else 0.0)
	button.offset_top = pos.y - 720.0
	button.offset_right = button.offset_left + size.x
	button.offset_bottom = button.offset_top + size.y
	button.custom_minimum_size = size
	button.size = size
	button.button_down.connect(down)
	button.button_up.connect(up)
	parent.add_child(button)


func _set_focus(active: bool) -> void:
	focus_held = active
	if not active:
		manual_aim = Vector2.ZERO


func _on_aim_changed(value: Vector2) -> void:
	manual_aim = value
	focus_held = true


func _on_aim_released() -> void:
	manual_aim = Vector2.ZERO
	focus_held = false


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
	for key in ["LOLA", "DADO", "MOORING", "SABEL", "MARA"]:
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
			story.seen_people["lola"] = true
			_show_dialogue("LOLA PASING: Ayaw una isulat ang imong gituohan. Paminaw sa, dayon pangita og pamatuod.")
		"DADO":
			talked_to_dado = true
			story.seen_people["dado"] = true
			story.observe_clue("light_retreat")
			_show_dialogue("TATAY DADO: Gamay nga kahayag. Kung akong tutokan, mosibog. Kung molingi ko, murag naghulat.")
		"SABEL":
			story.seen_people["sabel"] = true
			_show_dialogue("ALING SABEL: Si Mang Celso usa ka karaang boatman. Ayaw pagsagol sa iyang ngalan sa uban nga nawala.")
		"MARA":
			story.seen_people["mara"] = true
			if story.clues.has("old_mooring"):
				story.observe_clue("boatman_name")
				_show_dialogue("TEACHER MARA: Ang ledger nagtawag kang Mang Celso. I-compare nato ang testimonya ug lugar.")
			else:
				_show_dialogue("TEACHER MARA: Tan-awa ang karaang mooring una. Ang testimonya kinahanglan ikumpara.")
		"MOORING":
			story.observe_clue("old_mooring")
			if story.seen_people.has("mara"):
				story.observe_clue("boatman_name")
			if is_night:
				encountered_light = true
				_show_dialogue("The light waits by the mooring. Observe gently, compare reflections, and honor the forgotten name.")
			else:
				_show_dialogue("A weathered mooring by the river. An older name seems to be missing from the record.")
		_:
			_show_dialogue("Move close to Lola, Dado, or the old mooring to interact.")
	_refresh_choices()
	_update_objective()


func _show_dialogue(value: String) -> void:
	dialogue_text.text = value + "\n\n[INTERACT or ENTER to close]"
	dialogue.show()


func _close_dialogue() -> void:
	dialogue.hide()


func _toggle_night() -> void:
	if story.outcome != "":
		_show_dialogue("The next morning has begun. Your outcome is already committed; no repeat rewards.")
		return
	is_night = not is_night
	lantern.light_energy = 4.5 if is_night else 0.0
	focus_held = false
	light_alarm = 0.0
	alarm_label.text = ""
	var env_node := get_node_or_null("Environment") as WorldEnvironment
	if env_node != null:
		env_node.environment.background_color = Color(0.04, 0.10, 0.22) if is_night else Color(0.48, 0.68, 0.72)
	if is_night and santelmo == null:
		santelmo = SantelmoActor.new()
		add_child(santelmo)
	if santelmo != null:
		santelmo.visible = is_night
		santelmo.set_encounter_phase(story.phase)
	_refresh_choices()
	_update_objective()


func _update_objective() -> void:
	if not talked_to_lola:
		objective.text = "OBJECTIVE: Speak to Lola Pasing (gold marker)."
	elif not talked_to_dado:
		objective.text = "OBJECTIVE: Meet Tatay Dado by the river (blue marker)."
	elif story.outcome != "":
		objective.text = "MORNING AFTER: " + story.outcome.to_upper() + " — state saved."
	elif not is_night:
		objective.text = "Inspect mooring and speak to Mara, then begin night when ready."
	elif story.phase == 0:
		objective.text = "Find three clues (Dado, mooring, Mara), then BEGIN at the river."
	elif story.phase == 1:
		objective.text = "Stage 1: Study the light; let its alarm settle, then OBSERVE."
	elif story.phase == 2:
		objective.text = "Stage 2: Walk to a reflected light, then INSPECT; the real one follows the slow current."
	elif story.phase == 3:
		objective.text = "Stage 3: Choose remembrance, protection, or retreat."
	else:
		objective.text = "Night 1 completed."


func _refresh_choices() -> void:
	if stage_label == null:
		return
	var names: Array[String] = []
	if not is_night:
		names = ["", "", ""]
	elif story.phase == 0:
		names = ["BEGIN" if story.can_begin() else "Find clues", "", ""]
	elif story.phase == 1:
		names = ["OBSERVE", "", "RETREAT"]
	elif story.phase == 2:
		names = ["INSPECT LIGHT", "HINT", "RETREAT"]
	elif story.phase == 3:
		names = ["REMEMBER", "DRIVE AWAY", "RETREAT"]
	else:
		names = ["", "", ""]
	for i in range(choice_buttons.size()):
		choice_buttons[i].text = names[i]
		choice_buttons[i].visible = names[i] != ""
	stage_label.text = "CLUES: %d/3  •  PHASE: %d  •  OUTCOME: %s" % [story.clues.size(), story.phase, story.outcome if story.outcome != "" else "pending"]


func _choose_story_action(index: int) -> void:
	if not is_night or story.outcome != "":
		return
	if story.phase == 0:
		if index == 0 and story.begin():
			_save_story_silent()
			_show_dialogue("The first light rises above the old bank. Watch its response, and do not chase it into the river.")
	elif story.phase == 1:
		if index == 2:
			_commit_night("partial")
		elif index == 0:
			if story.advance_observation():
				_save_story_silent()
				_show_dialogue("The light settles. Two reflected patterns appear; only one follows the current.")
			else:
				_show_dialogue("The glow flares under direct Focus. Release the lamp and let the light calm.")
	elif story.phase == 2:
		if index == 2:
			_commit_night("partial")
		elif index == 1:
			_show_dialogue("Watch the two reflected circles. The true light follows the slow current; the false one jitters.")
		elif index == 0:
			var choice: String = santelmo.reflection_near(player.global_position) if santelmo != null else ""
			if choice == "":
				_show_dialogue("Walk closer to a reflected circle on the safe bank, then inspect.")
			elif choice == "CURRENT_ALIGNED":
				if story.choose_reflection("current_aligned"):
					_save_story_silent()
					_show_dialogue("The quiet reflection follows the current. The light returns to Mang Celso's mooring.")
			else:
				story.choose_reflection("false_mirror")
				_show_dialogue("This restless reflection moves against the current. Try the other light.")
	elif story.phase == 3:
		if index == 0:
			_commit_night("resolve")
		elif index == 1:
			_commit_night("drive_away")
		elif index == 2:
			_commit_night("partial")
	if santelmo != null:
		santelmo.set_encounter_phase(story.phase)
	_refresh_choices()
	_update_objective()


func _commit_night(result: String) -> void:
	if result == "partial":
		if not story.accept_partial():
			return
	elif not story.commit_result(result):
		return
	is_night = false
	lantern.light_energy = 0
	if santelmo != null:
		santelmo.visible = false
	var env_node := get_node_or_null("Environment") as WorldEnvironment
	if env_node != null:
		env_node.environment.background_color = Color(0.48, 0.68, 0.72)
	var line := ""
	match result:
		"resolve":
			line = "Morning: Dado says the river has gone quiet. Mang Celso is remembered."
		"drive_away":
			line = "Morning: the light has left, but the old mooring feels uneasy."
		"partial":
			line = "Morning: Lola welcomes you home. Another way to learn from the river remains."
	_show_dialogue(line)
	_refresh_choices()
	_update_objective()
	_save_story_silent()


func _open_notebook() -> void:
	var found: Array[String] = []
	if story.clues.has("light_retreat"):
		found.append("Dado reports the light retreats when stared at.")
	if story.clues.has("old_mooring"):
		found.append("The light returns to an old safe mooring.")
	if story.clues.has("boatman_name"):
		found.append("Mara's records name boatman Mang Celso.")
	if found.is_empty():
		found.append("No established signs yet. Speak with the residents.")
	var hypothesis_line := "Guide gently" if story.hypothesis == "guide" else "Chase away" if story.hypothesis == "chase" else "Unknown"
	_show_dialogue("NOTEBOOK  •  " + "\n".join(found) + "\nPrivate theory: " + hypothesis_line + "\nTap NOTEBOOK again later to revise your theory.")
	# The theory is deliberately private and never changes social trust.
	if story.hypothesis == "":
		story.choose_hypothesis("chase")
	elif story.hypothesis == "chase":
		story.choose_hypothesis("guide")
	else:
		story.choose_hypothesis("chase")
	_refresh_choices()


func _save_story_silent() -> void:
	SaveService.write(story, is_night)


func _save_story() -> void:
	_show_dialogue("Offline story state saved." if SaveService.write(story, is_night) else "Could not write the save file.")


func _restore_story() -> void:
	var data: Dictionary = SaveService.read(story)
	if data.is_empty():
		return
	talked_to_lola = story.seen_people.has("lola")
	talked_to_dado = story.seen_people.has("dado")
	if bool(data.get("night", false)) and story.outcome == "":
		_toggle_night()
		light_alarm = story.alarm
		if santelmo != null:
			santelmo.set_encounter_phase(story.phase)
	_refresh_choices()


func _retry_story() -> void:
	if story.retry_from_checkpoint():
		light_alarm = story.alarm
		if santelmo != null:
			santelmo.set_encounter_phase(story.phase)
		_show_dialogue("Restored the safe encounter checkpoint; no permanent resources were duplicated.")
	else:
		_show_dialogue("No uncommitted encounter checkpoint is available.")
	_refresh_choices()
	_update_objective()
