extends Node3D
## G1 engine/input spike: an explorable prototype, NOT the completed Night 1.
## All primitive geometry is temporary and must be replaced by approved art.

const NightModel = preload("res://scripts/narrative/night01_state.gd")
const NightDialogue = preload("res://scripts/narrative/night01_dialogue.gd")
const NightJournal = preload("res://scripts/narrative/night01_journal.gd")
const MorningAftermath = preload("res://scripts/world/night01_aftermath.gd")
const LolaHut = preload("res://scripts/world/lola_hut_interior.gd")
const Nearby = preload("res://scripts/ui/nearby_interaction.gd")
const SantelmoActor = preload("res://scripts/encounters/santelmo_actor.gd")
const FolkActors = preload("res://scripts/visuals/folk_actors.gd")
const SpeakerPortrait = preload("res://scripts/ui/speaker_portrait.gd")
const ConversationPages = preload("res://scripts/narrative/conversation_pages.gd")
const BarrioDetails = preload("res://scripts/world/barrio_details.gd")
const CinematicCamera = preload("res://scripts/visuals/cinematic_camera.gd")
const BarrioLighting = preload("res://scripts/visuals/barrio_lighting.gd")
const RiverBanca = preload("res://scripts/world/river_banca.gd")
const BantayRoute = preload("res://scripts/ai/bantay_route.gd")
const BantayAwareness = preload("res://scripts/ai/bantay_awareness.gd")
const AimPad = preload("res://scripts/ui/aim_pad.gd")
const SaveService = preload("res://scripts/core/save_service.gd")
const Preferences = preload("res://scripts/core/preferences.gd")
const LivingSound = preload("res://scripts/audio/living_ambience.gd")
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
var preferences = Preferences.new()
var gameplay_hud: Control
var modal_backdrop: ColorRect
var settings_panel: PanelContainer
var pref_text_button: Button
var pref_motion_button: Button
var pref_contrast_button: Button
var pref_hint_button: Button
var pref_assist_button: Button
var pref_audio_button: Button
var living_sound: Node
var courage_label: Label
var prep_water_button: Button
var choice_buttons: Array[Button] = []
var stage_label: Label
var player: CharacterBody3D
var apprentice_visual: Node3D
var bantay_visual: Node3D
var sun: DirectionalLight3D
var river_surface: MeshInstance3D
var river_boat: Node3D
var bantay: CharacterBody3D
var dog_guide = BantayRoute.new()
var dog_awareness = BantayAwareness.new()
var dog_warning_label: Label
var interact_hint: Label
var interaction_nodes: Dictionary = {}
var dog_warning_seconds := 0.0
var dog_waypoints := PackedVector3Array()
var dog_next_waypoint := 0
var dog_repath_timer := 0.0
var camera_director = CinematicCamera.new()
var camera: Camera3D
var lantern: SpotLight3D
var info: Label
var objective: Label
var dialogue: PanelContainer
var dialogue_text: Label
var dialogue_portrait: Control
var dialogue_speaker: Label
var dialogue_next_button: Button
var dialogue_pages: Array[Dictionary] = []
var dialogue_page := 0
var prep_panel: PanelContainer
var prep_summary: Label
var prep_buttons: Dictionary = {}
var notebook_panel: PanelContainer
var notebook_body: Label
var notebook_guide: Button
var notebook_chase: Button
var evidence_heading: Label
var theory_heading: Label
var link_light_button: Button
var link_ledger_button: Button
var touch_axes := Vector2.ZERO
var focus_held := false
var manual_aim := Vector2.ZERO
var light_alarm := 0.0
var guide_was_complete := false
var lamp_heading := Vector3.FORWARD
var alarm_label: Label
var move_buttons: Dictionary = {}
var is_night := false
var talked_to_lola := false
var talked_to_dado := false
var encountered_light := false
var in_lola_hut := false
var santelmo
var ambient_walkers: Array[Node3D] = []
var elapsed := 0.0
var encounter_autosave_clock := 0.0


func _ready() -> void:
	preferences.load_from()
	_create_world()
	_create_ambient_walkers()
	_create_player()
	_create_bantay()
	_create_camera()
	_create_lighting()
	_create_audio()
	_create_ui()
	_apply_preferences()
	_restore_story()
	if story.outcome == "" and not story.prologue_ready():
		_enter_lola_hut(true)
	_update_objective()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var axis := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	axis += touch_axes
	if _is_reading_ui():
		axis = Vector2.ZERO
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
	_update_bantay(delta)
	_update_dog_warnings(delta)
	_update_interact_hint()
	FolkActors.animate_person(apprentice_visual, elapsed, desired.length() > 0.1)
	var speaking_role := ""
	if dialogue != null and dialogue.visible and not dialogue_pages.is_empty():
		speaking_role = str(dialogue_pages[dialogue_page].get("speaker", ""))
	FolkActors.animate_expression(apprentice_visual, elapsed, speaking_role == "APPRENTICE", preferences.reduced_motion)
	for i in range(4):
		var role: String = ["LOLA", "DADO", "SABEL", "MARA"][i]
		var marker: Node3D = interaction_nodes.get(role) as Node3D
		if marker != null:
			var witness: Node3D = marker.get_node_or_null(role) as Node3D
			if witness != null:
				FolkActors.animate_person(witness, elapsed * 0.48 + float(i) * 2.3, false)
				FolkActors.animate_expression(witness, elapsed, role == speaking_role, preferences.reduced_motion)
	if in_lola_hut:
		var elder := get_node_or_null(LolaHut.NODE_NAME + "/Lola seated") as Node3D
		FolkActors.animate_expression(elder, elapsed, speaking_role == "LOLA", preferences.reduced_motion)
	camera_director.tick(camera, player, delta, preferences.reduced_motion)
	RiverBanca.animate(river_boat, elapsed, preferences.reduced_motion)
	elapsed += delta
	if is_night and santelmo != null:
		light_alarm = santelmo.update_behavior(delta, player.global_position, lamp_heading, focus_held)
		story.alarm = light_alarm
		_advance_safe_guiding(delta)
		encounter_autosave_clock += delta
		if encounter_autosave_clock >= 10.0 and story.outcome == "" and story.phase >= 1:
			encounter_autosave_clock = 0.0
			_save_story_silent()
		if story.tick_courage(delta, preferences.story_assist):
			_show_dialogue("Bantay leads you back from the frightening light. You can RETRY the safe checkpoint or ACCEPT PARTIAL.")
			_refresh_choices()
			_update_objective()
		alarm_label.text = "Santelmo: %s  |  Strong Focus makes it retreat" % ("ALARMED: lower your light" if light_alarm > 0.65 else "watching" if light_alarm > 0.2 else "calm")
	if courage_label != null:
		courage_label.text = "COURAGE: %d / 100" % roundi(story.courage) if is_night and story.phase >= 1 and story.phase <= 3 else ""
	for i in range(ambient_walkers.size()):
		var villager := ambient_walkers[i]
		villager.visible = not is_night
		if not is_night:
			villager.position.z = -4.0 - 2.0 * float(i) + 1.65 * sin(elapsed * (0.35 + 0.06 * float(i)) + float(i) * 3.0)
			FolkActors.animate_person(villager, elapsed + float(i), true)
			villager.rotation.y = PI if cos(elapsed * (0.35 + 0.06 * float(i)) + float(i) * 3.0) > 0 else 0
	if river_surface != null and not preferences.reduced_motion:
		var river_mat := river_surface.material_override as StandardMaterial3D
		if river_mat != null:
			river_mat.albedo_color = COLORS.river.lerp(Color(0.12, 0.42, 0.52), 0.5 + 0.5 * sin(elapsed * 1.2))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_interact()
	if event.is_action_pressed("ui_focus_next"):
		focus_held = true
	if event.is_action_released("ui_focus_next"):
		focus_held = false
	if event.is_action_pressed("ui_cancel"):
		_close_dialogue()
		_close_notebook()
		_close_prep()
		_close_settings()


func _create_world() -> void:
	_box("Ground", Vector3(0, -0.35, 0), Vector3(46, 0.65, 46), COLORS.earth, true)
	_box("Main footpath", Vector3(0, 0.015, 0), Vector3(5, 0.08, 38), COLORS.path, false)
	river_surface = _box("River", Vector3(-16, 0.02, 0), Vector3(12, 0.08, 46), COLORS.river, false) as MeshInstance3D
	for z in [4.0, 11.0, 18.0]:
		_box("Reed", Vector3(-9.1, 0.4, z), Vector3(0.13, 0.7, 0.11), Color(0.43, 0.53, 0.26), false)
	for z in [-16.0, -10.0, 0.0, 7.0, 15.0]:
		_box("River shimmer", Vector3(-15.0, 0.08, z), Vector3(4.3, 0.025, 0.12), Color(0.22, 0.59, 0.61), false)
	_box("River bank safety fence", Vector3(-9.7, 0.5, 0), Vector3(0.25, 1.0, 46), COLORS.wood, true)
	# Collision-only boundaries prevent accidental falls beyond the playable blockout.
	_boundary(Vector3(-23.0, 1.0, 0.0), Vector3(0.3, 3.0, 46.0))
	_boundary(Vector3(23.0, 1.0, 0.0), Vector3(0.3, 3.0, 46.0))
	_boundary(Vector3(0.0, 1.0, -23.0), Vector3(46.0, 3.0, 0.3))
	_boundary(Vector3(0.0, 1.0, 23.0), Vector3(46.0, 3.0, 0.3))
	_house(Vector3(6, 0, 5), "Lola's hut")
	_house(Vector3(7, 0, -8), "Sabel's store")
	_house(Vector3(-2, 0, -12), "School")
	_box("Landing", Vector3(-7, 0.1, 9), Vector3(4.1, 0.3, 3.2), COLORS.wood, false)
	for x in [-8.6, -7.0, -5.4]:
		_box("Landing plank", Vector3(x, 0.28, 9), Vector3(0.13, 0.06, 3.0), Color(0.58, 0.38, 0.23), false)
	river_boat = RiverBanca.build(self, Vector3(-8.6, 0.15, 4.4))
	for x in [-19.0, -13.0, 13.0, 19.0]:
		for z in [-18.0, -5.0, 14.0]:
			_tree(Vector3(x, 0, z))
	_marker("LOLA", Vector3(4, 0.1, 7), Color(0.9, 0.73, 0.44))
	_marker("DADO", Vector3(-5, 0.1, 7), Color(0.42, 0.68, 0.83))
	_marker("MOORING", Vector3(-7, 0.1, 13), Color(0.8, 0.76, 0.49))
	_marker("SABEL", Vector3(3, 0.1, -5), Color(0.75, 0.5, 0.8))
	_marker("MARA", Vector3(-2, 0.1, -8), Color(0.42, 0.82, 0.61))
	_box("Lola exterior doorstep", LolaHut.OUTSIDE_DOOR, Vector3(1.9, 0.16, 1.05), Color(0.52, 0.36, 0.21), false)
	var exterior_door := Node3D.new()
	exterior_door.name = "HUT_ENTRY"
	exterior_door.position = LolaHut.OUTSIDE_DOOR
	add_child(exterior_door)
	interaction_nodes["HUT_ENTRY"] = exterior_door
	var room_interactions: Dictionary = LolaHut.build(self)
	for key in room_interactions:
		interaction_nodes[key] = room_interactions[key]
	BarrioDetails.decorate(self)


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


func _boundary(at: Vector3, dimensions: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.name = "Playable boundary"
	wall.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	shape.shape = box
	wall.add_child(shape)
	add_child(wall)


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
	interaction_nodes[key] = node
	if key == "MOORING":
		var stump := MeshInstance3D.new()
		stump.name = "Old tied post"
		var wood := CylinderMesh.new()
		wood.top_radius = 0.24
		wood.bottom_radius = 0.32
		wood.height = 1.1
		stump.mesh = wood
		stump.position.y = 0.55
		var wood_mat := StandardMaterial3D.new()
		wood_mat.albedo_color = Color(0.43, 0.29, 0.17)
		stump.material_override = wood_mat
		node.add_child(stump)
	else:
		var villager := FolkActors.person(key, color, Color(0.28, 0.24, 0.20))
		villager.position.y = -0.1
		# Face toward the approaching apprentice / isometric camera so the
		# signature costume and eye details remain visible on small screens.
		villager.rotation.y = -2.35
		node.add_child(villager)


func _create_ambient_walkers() -> void:
	for i in range(3):
		var resident := FolkActors.person("Resident_%d" % i, Color(0.41 + 0.13 * i, 0.43, 0.39 + 0.06 * i), Color(0.29, 0.27 + 0.09 * i, 0.25))
		resident.position = Vector3(1.0 + float(i) * 1.5, 0.0, -4.0 - 2.0 * float(i))
		add_child(resident)
		ambient_walkers.append(resident)

func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Apprentice"
	player.position = Vector3(0, 0.75, 2)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.5
	shape.shape = capsule
	player.add_child(shape)
	apprentice_visual = FolkActors.person("Apprentice", Color(0.72, 0.50, 0.25), Color(0.26, 0.31, 0.34))
	apprentice_visual.position.y = -0.75
	player.add_child(apprentice_visual)
	add_child(player)


func _create_bantay() -> void:
	bantay = CharacterBody3D.new()
	bantay.name = "Bantay"
	bantay.position = Vector3(1.6, 0.45, 2.1)
	bantay.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 0.85
	collider.shape = capsule
	bantay.add_child(collider)
	bantay_visual = FolkActors.dog()
	bantay_visual.position.y = -0.45
	bantay.add_child(bantay_visual)
	add_child(bantay)


func _advance_safe_guiding(delta: float) -> void:
	if story.phase != 3 or story.outcome != "" or story.encounter_failed:
		return
	var to_landing: Vector3 = SantelmoActor.SAFE_LANDING - player.global_position
	to_landing.y = 0.0
	var close_enough: bool = to_landing.length() < 4.0
	var direction_correct: bool = to_landing.length() > 0.3 and lamp_heading.dot(to_landing.normalized()) > 0.65
	var was_ready: bool = story.guide_progress >= 0.999
	story.guide_to_landing(delta, close_enough, focus_held, direction_correct)
	if santelmo != null:
		santelmo.set_guide_progress(story.guide_progress)
	if story.guide_progress >= 0.999 and not was_ready:
		_save_story_silent()
		_refresh_choices()
		_update_objective()


func _update_dog_warnings(delta: float) -> void:
	var light_exists := is_night and santelmo != null
	var light_position: Vector3 = santelmo.global_position if light_exists else Vector3.ZERO
	var warning: String = dog_awareness.tick(delta, player.global_position, is_night, light_exists, light_position, light_alarm)
	if warning != "":
		dog_warning_label.text = warning
		dog_warning_seconds = 4.5
	elif dog_warning_seconds > 0.0:
		dog_warning_seconds = maxf(0.0, dog_warning_seconds - delta)
		if dog_warning_seconds <= 0.0:
			dog_warning_label.text = ""


func _update_bantay(delta: float) -> void:
	var distance := bantay.global_position.distance_to(player.global_position)
	dog_repath_timer -= delta
	if dog_repath_timer <= 0.0:
		dog_repath_timer = 0.45
		if distance > 2.35:
			dog_waypoints = dog_guide.route(bantay.global_position, player.global_position)
			dog_next_waypoint = 0
		else:
			dog_waypoints.clear()
	var motion := Vector3.ZERO
	if distance > 2.0 and dog_next_waypoint < dog_waypoints.size():
		var waypoint := dog_waypoints[dog_next_waypoint]
		var toward := waypoint - bantay.global_position
		toward.y = 0.0
		if toward.length() < 0.55:
			dog_next_waypoint += 1
		elif toward.length() > 0.01:
			motion = toward.normalized()
	bantay.velocity.x = motion.x * 3.2
	bantay.velocity.z = motion.z * 3.2
	bantay.velocity.y = -0.1 if bantay.is_on_floor() else bantay.velocity.y - 24.0 * delta
	bantay.move_and_slide()
	if motion.length() > 0.05:
		bantay.rotation.y = atan2(-motion.x, -motion.z)
	FolkActors.animate_dog(bantay_visual, elapsed, motion.length() > 0.1, is_night and player.global_position.x < -4.0)


func _create_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Isometric Camera"
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 16
	add_child(camera)


func _create_lighting() -> void:
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.1
	add_child(sun)
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
	BarrioLighting.apply(sun, environment, lantern, false)


func _is_reading_ui() -> bool:
	return (dialogue != null and dialogue.visible) or (notebook_panel != null and notebook_panel.visible) or (prep_panel != null and prep_panel.visible) or (settings_panel != null and settings_panel.visible)


func _clear_touch_input() -> void:
	focus_held = false
	manual_aim = Vector2.ZERO
	touch_axes = Vector2.ZERO
	move_buttons.clear()


func _create_audio() -> void:
	living_sound = LivingSound.new()
	living_sound.name = "Living Barrio Ambience"
	add_child(living_sound)
	living_sound.set_audio_level(preferences.audio_level)


func _style_modal(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.095, 0.13, 0.98)
	style.border_color = Color(0.56, 0.67, 0.69, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP


func _menu_style(fill: Color, outline: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


func _style_modal_button(button: Button, selected: bool = false, footer: bool = false) -> void:
	# The default Godot Button font and disabled palette were nearly invisible
	# on the user's landscape phone. Explicit styles cover every state.
	var edge := Color(0.43, 0.75, 0.65) if selected else Color(0.34, 0.48, 0.56)
	var background := Color(0.14, 0.25, 0.27) if selected else Color(0.14, 0.20, 0.26)
	button.add_theme_stylebox_override("normal", _menu_style(background, edge))
	button.add_theme_stylebox_override("hover", _menu_style(Color(0.22, 0.34, 0.39), Color(0.65, 0.83, 0.81)))
	button.add_theme_stylebox_override("pressed", _menu_style(Color(0.26, 0.40, 0.39), Color(0.90, 0.80, 0.49)))
	button.add_theme_stylebox_override("hover_pressed", _menu_style(Color(0.26, 0.40, 0.39), Color(0.90, 0.80, 0.49)))
	button.add_theme_stylebox_override("focus", _menu_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.98, 0.84, 0.46)))
	button.add_theme_stylebox_override("disabled", _menu_style(Color(0.11, 0.18, 0.21), edge.darkened(0.15)))
	button.add_theme_color_override("font_color", Color(0.96, 0.97, 0.96))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.91, 0.90))
	button.add_theme_font_size_override("font_size", roundi((25.0 if footer else 27.0) * preferences.text_scale))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER if footer else HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(button.custom_minimum_size.x, maxf(button.custom_minimum_size.y, 63.0))


func _sync_modal_ui() -> void:
	if gameplay_hud == null or modal_backdrop == null:
		return
	var active: bool = _is_reading_ui()
	gameplay_hud.visible = not active
	modal_backdrop.visible = active
	modal_backdrop.color = Color(0.015, 0.035, 0.05, 0.30 if dialogue != null and dialogue.visible else 0.76)


func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	gameplay_hud = Control.new()
	gameplay_hud.name = "GameplayControls"
	gameplay_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gameplay_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(gameplay_hud)
	info = Label.new()
	info.position = Vector2(25, 16)
	info.text = "TABI-TABI  •  BARRIO LAWOM"
	info.add_theme_font_size_override("font_size", 24)
	gameplay_hud.add_child(info)
	objective = Label.new()
	objective.position = Vector2(25, 56)
	objective.add_theme_font_size_override("font_size", 22)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.size = Vector2(760, 65)
	gameplay_hud.add_child(objective)
	_make_button(gameplay_hud, "◀", Vector2(20, 575), Vector2(70, 65), func(): _set_button_axis("left", true), func(): _set_button_axis("left", false))
	_make_button(gameplay_hud, "▶", Vector2(170, 575), Vector2(70, 65), func(): _set_button_axis("right", true), func(): _set_button_axis("right", false))
	_make_button(gameplay_hud, "▲", Vector2(95, 505), Vector2(70, 65), func(): _set_button_axis("up", true), func(): _set_button_axis("up", false))
	_make_button(gameplay_hud, "▼", Vector2(95, 645), Vector2(70, 65), func(): _set_button_axis("down", true), func(): _set_button_axis("down", false))
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
	gameplay_hud.add_child(aim_pad)
	_make_button(gameplay_hud, "FOCUS", Vector2(1050, 490), Vector2(180, 60), func(): _set_focus(true), func(): _set_focus(false))
	_make_button(gameplay_hud, "INTERACT", Vector2(1050, 565), Vector2(180, 60), _interact, func(): pass)
	_make_button(gameplay_hud, "DAY / NIGHT", Vector2(1050, 640), Vector2(180, 56), _toggle_night, func(): pass)
	_make_button(gameplay_hud, "NOTEBOOK", Vector2(1050, 415), Vector2(180, 56), _open_notebook, func(): pass)
	_make_button(gameplay_hud, "PREPARE", Vector2(1050, 276), Vector2(180, 56), _open_prep, func(): pass)
	_make_button(gameplay_hud, "SAVE", Vector2(1050, 345), Vector2(85, 52), _save_story, func(): pass)
	_make_button(gameplay_hud, "RETRY", Vector2(1142, 345), Vector2(88, 52), _retry_story, func(): pass)
	interact_hint = Label.new()
	interact_hint.anchor_left = 0.30
	interact_hint.anchor_right = 0.70
	interact_hint.anchor_top = 0.0
	interact_hint.anchor_bottom = 0.0
	interact_hint.offset_top = 8
	interact_hint.offset_bottom = 46
	interact_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_hint.add_theme_font_size_override("font_size", 21)
	interact_hint.add_theme_color_override("font_color", Color(0.98, 0.86, 0.60))
	gameplay_hud.add_child(interact_hint)
	courage_label = Label.new()
	courage_label.position = Vector2(25, 196)
	courage_label.add_theme_font_size_override("font_size", 20)
	courage_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.61))
	gameplay_hud.add_child(courage_label)
	dog_warning_label = Label.new()
	dog_warning_label.position = Vector2(25, 160)
	dog_warning_label.add_theme_font_size_override("font_size", 18)
	dog_warning_label.add_theme_color_override("font_color", Color(0.95, 0.76, 0.42))
	gameplay_hud.add_child(dog_warning_label)
	stage_label = Label.new()
	stage_label.position = Vector2(25, 125)
	stage_label.add_theme_font_size_override("font_size", 20)
	gameplay_hud.add_child(stage_label)
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
		gameplay_hud.add_child(action)
		choice_buttons.append(action)
	_refresh_choices()
	alarm_label = Label.new()
	alarm_label.position = Vector2(25, 95)
	alarm_label.add_theme_font_size_override("font_size", 18)
	gameplay_hud.add_child(alarm_label)
	modal_backdrop = ColorRect.new()
	modal_backdrop.name = "ModalDimmer"
	modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_backdrop.color = Color(0.015, 0.035, 0.05, 0.76)
	modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(modal_backdrop)
	modal_backdrop.hide()
	dialogue = PanelContainer.new()
	dialogue.name = "DialoguePanel"
	dialogue.anchor_left = 0.08
	dialogue.anchor_right = 0.92
	dialogue.anchor_top = 0.44
	dialogue.anchor_bottom = 0.955
	_style_modal(dialogue)
	root.add_child(dialogue)
	var dialogue_layout := VBoxContainer.new()
	dialogue_layout.name = "DialogueLayout"
	dialogue_layout.add_theme_constant_override("separation", 12)
	dialogue.add_child(dialogue_layout)
	dialogue_speaker = Label.new()
	dialogue_speaker.name = "CurrentSpeaker"
	dialogue_speaker.text = "BARRIO LAWOM"
	dialogue_speaker.add_theme_color_override("font_color", Color("#e8d3a4"))
	dialogue_speaker.add_theme_font_size_override("font_size", 28)
	dialogue_layout.add_child(dialogue_speaker)
	var dialogue_scroll := ScrollContainer.new()
	dialogue_scroll.name = "DialogueScroll"
	dialogue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialogue_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_scroll.follow_focus = true
	dialogue_layout.add_child(dialogue_scroll)
	var portrait_row := HBoxContainer.new()
	portrait_row.name = "PortraitAndText"
	portrait_row.add_theme_constant_override("separation", 22)
	portrait_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_scroll.add_child(portrait_row)
	dialogue_portrait = SpeakerPortrait.new()
	dialogue_portrait.name = "SpeakerBustPortrait"
	dialogue_portrait.custom_minimum_size = Vector2(225, 215)
	dialogue_portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_row.add_child(dialogue_portrait)
	dialogue_text = Label.new()
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_size_override("font_size", 25)
	dialogue_text.custom_minimum_size = Vector2(390, 180)
	dialogue_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_row.add_child(dialogue_text)
	var dialogue_close := Button.new()
	dialogue_close.name = "CloseDialogue"
	dialogue_close.text = "CONTINUE"
	dialogue_close.custom_minimum_size = Vector2(240, 52)
	dialogue_close.pressed.connect(_advance_dialogue)
	_style_modal_button(dialogue_close, false, true)
	dialogue_next_button = dialogue_close
	dialogue_layout.add_child(dialogue_close)
	dialogue.hide()
	notebook_panel = PanelContainer.new()
	notebook_panel.name = "NotebookPanel"
	notebook_panel.anchor_left = 0.10
	notebook_panel.anchor_right = 0.90
	notebook_panel.anchor_top = 0.055
	notebook_panel.anchor_bottom = 0.945
	_style_modal(notebook_panel)
	root.add_child(notebook_panel)
	var notebook_layout := VBoxContainer.new()
	notebook_layout.name = "NotebookLayout"
	notebook_layout.add_theme_constant_override("separation", 12)
	notebook_panel.add_child(notebook_layout)
	var title := Label.new()
	title.name = "NotebookHeading"
	title.text = "FIELD NOTEBOOK  |  NIGHT 1"
	title.add_theme_font_size_override("font_size", 25)
	notebook_layout.add_child(title)
	var notebook_scroll := ScrollContainer.new()
	notebook_scroll.name = "NotebookScroll"
	notebook_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	notebook_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notebook_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notebook_scroll.follow_focus = true
	notebook_layout.add_child(notebook_scroll)
	var stack := VBoxContainer.new()
	stack.name = "EvidenceContent"
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 12)
	notebook_scroll.add_child(stack)
	notebook_body = Label.new()
	notebook_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notebook_body.add_theme_font_size_override("font_size", 27)
	notebook_body.add_theme_constant_override("line_spacing", 6)
	notebook_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(notebook_body)
	evidence_heading = Label.new()
	evidence_heading.text = "CONNECT EVIDENCE"
	evidence_heading.name = "EvidenceHeading"
	evidence_heading.add_theme_font_size_override("font_size", 25)
	stack.add_child(evidence_heading)
	link_light_button = Button.new()
	link_light_button.text = "LINK: DADO + MOORING"
	link_light_button.custom_minimum_size = Vector2(260, 45)
	link_light_button.pressed.connect(func(): _link_clues("light_mooring"))
	_style_modal_button(link_light_button)
	stack.add_child(link_light_button)
	link_ledger_button = Button.new()
	link_ledger_button.text = "LINK: MOORING + MARA"
	link_ledger_button.custom_minimum_size = Vector2(270, 45)
	link_ledger_button.pressed.connect(func(): _link_clues("ledger_mooring"))
	_style_modal_button(link_ledger_button)
	stack.add_child(link_ledger_button)
	theory_heading = Label.new()
	theory_heading.name = "TheoryHeading"
	theory_heading.text = "PRIVATE THEORY  |  NOT VERIFIED"
	theory_heading.add_theme_font_size_override("font_size", 25)
	stack.add_child(theory_heading)
	var theory_row := HBoxContainer.new()
	theory_row.add_theme_constant_override("separation", 10)
	stack.add_child(theory_row)
	notebook_guide = Button.new()
	notebook_guide.text = "GUIDE GENTLY"
	notebook_guide.custom_minimum_size = Vector2(170, 48)
	notebook_guide.pressed.connect(func(): _select_theory("guide"))
	_style_modal_button(notebook_guide)
	theory_row.add_child(notebook_guide)
	notebook_chase = Button.new()
	notebook_chase.text = "CHASE AWAY"
	notebook_chase.custom_minimum_size = Vector2(170, 48)
	notebook_chase.pressed.connect(func(): _select_theory("chase"))
	_style_modal_button(notebook_chase)
	theory_row.add_child(notebook_chase)
	var close_button := Button.new()
	close_button.text = "CLOSE NOTEBOOK"
	close_button.custom_minimum_size = Vector2(200, 48)
	close_button.pressed.connect(_close_notebook)
	close_button.name = "CloseNotebook"
	_style_modal_button(close_button, false, true)
	notebook_layout.add_child(close_button)
	notebook_panel.hide()
	# Four active equipment slots, persisted with Night 1 state.
	prep_panel = PanelContainer.new()
	prep_panel.name = "PreparationPanel"
	prep_panel.anchor_left = 0.10
	prep_panel.anchor_right = 0.90
	prep_panel.anchor_top = 0.055
	prep_panel.anchor_bottom = 0.945
	_style_modal(prep_panel)
	root.add_child(prep_panel)
	var prep_layout := VBoxContainer.new()
	prep_layout.name = "PreparationLayout"
	prep_layout.add_theme_constant_override("separation", 10)
	prep_panel.add_child(prep_layout)
	var kit_scroll := ScrollContainer.new()
	kit_scroll.name = "PreparationScroll"
	kit_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kit_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kit_scroll.follow_focus = true
	prep_layout.add_child(kit_scroll)
	var kit_stack := VBoxContainer.new()
	kit_stack.name = "EquipmentContent"
	kit_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit_stack.add_theme_constant_override("separation", 10)
	kit_scroll.add_child(kit_stack)
	var kit_title := Label.new()
	kit_title.name = "PreparationHeading"
	kit_title.text = "RIVER PREPARATION | CHOOSE FOUR"
	kit_title.add_theme_font_size_override("font_size", 24)
	kit_stack.add_child(kit_title)
	prep_summary = Label.new()
	prep_summary.add_theme_font_size_override("font_size", 26)
	kit_stack.add_child(prep_summary)
	for item in story.kit.ITEMS:
		var item_id: String = item
		var item_button := Button.new()
		item_button.custom_minimum_size = Vector2(360, 49)
		item_button.pressed.connect(func(): _toggle_kit_item(item_id))
		_style_modal_button(item_button, story.kit.has(item_id))
		prep_buttons[item_id] = item_button
		kit_stack.add_child(item_button)
	prep_water_button = Button.new()
	prep_water_button.custom_minimum_size = Vector2(360, 49)
	prep_water_button.text = "USE WATER FLASK (NIGHT)"
	prep_water_button.pressed.connect(_use_water)
	_style_modal_button(prep_water_button)
	kit_stack.add_child(prep_water_button)
	var kit_close := Button.new()
	kit_close.text = "CLOSE PREPARATION"
	kit_close.custom_minimum_size = Vector2(260, 48)
	kit_close.pressed.connect(_close_prep)
	kit_close.name = "ClosePreparation"
	_style_modal_button(kit_close, false, true)
	prep_layout.add_child(kit_close)
	prep_panel.hide()
	# Persistent accessibility options; deliberately not a second gameplay save.
	var options_button := Button.new()
	options_button.text = "OPTIONS"
	options_button.anchor_left = 1.0
	options_button.anchor_right = 1.0
	options_button.offset_left = -171
	options_button.offset_right = -20
	options_button.offset_top = 14
	options_button.offset_bottom = 60
	options_button.pressed.connect(_open_settings)
	gameplay_hud.add_child(options_button)
	settings_panel = PanelContainer.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.anchor_left = 0.10
	settings_panel.anchor_right = 0.90
	settings_panel.anchor_top = 0.055
	settings_panel.anchor_bottom = 0.945
	_style_modal(settings_panel)
	root.add_child(settings_panel)
	var settings_layout := VBoxContainer.new()
	settings_layout.name = "SettingsLayout"
	settings_layout.add_theme_constant_override("separation", 10)
	settings_panel.add_child(settings_layout)
	var settings_scroll := ScrollContainer.new()
	settings_scroll.name = "SettingsScroll"
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scroll.follow_focus = true
	settings_layout.add_child(settings_scroll)
	var options_stack := VBoxContainer.new()
	options_stack.name = "OptionsContent"
	options_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_stack.add_theme_constant_override("separation", 13)
	settings_scroll.add_child(options_stack)
	var options_heading := Label.new()
	options_heading.name = "OptionsHeading"
	options_heading.text = "ACCESSIBILITY / GAME OPTIONS"
	options_heading.add_theme_font_size_override("font_size", 23)
	options_stack.add_child(options_heading)
	pref_text_button = Button.new()
	pref_text_button.custom_minimum_size = Vector2(360, 50)
	pref_text_button.pressed.connect(_cycle_text_size)
	_style_modal_button(pref_text_button)
	options_stack.add_child(pref_text_button)
	pref_motion_button = Button.new()
	pref_motion_button.custom_minimum_size = Vector2(360, 50)
	pref_motion_button.pressed.connect(_toggle_reduced_motion)
	_style_modal_button(pref_motion_button)
	options_stack.add_child(pref_motion_button)
	pref_contrast_button = Button.new()
	pref_contrast_button.custom_minimum_size = Vector2(360, 50)
	pref_contrast_button.pressed.connect(_toggle_contrast)
	_style_modal_button(pref_contrast_button)
	options_stack.add_child(pref_contrast_button)
	pref_hint_button = Button.new()
	pref_hint_button.custom_minimum_size = Vector2(360, 50)
	pref_hint_button.pressed.connect(_cycle_hint_level)
	_style_modal_button(pref_hint_button)
	options_stack.add_child(pref_hint_button)
	pref_assist_button = Button.new()
	pref_assist_button.custom_minimum_size = Vector2(360, 50)
	pref_assist_button.pressed.connect(_toggle_story_assist)
	_style_modal_button(pref_assist_button)
	options_stack.add_child(pref_assist_button)
	pref_audio_button = Button.new()
	pref_audio_button.custom_minimum_size = Vector2(360, 50)
	pref_audio_button.pressed.connect(_cycle_audio_level)
	_style_modal_button(pref_audio_button)
	options_stack.add_child(pref_audio_button)
	var exit_options := Button.new()
	exit_options.text = "CLOSE OPTIONS"
	exit_options.custom_minimum_size = Vector2(360, 50)
	exit_options.pressed.connect(_close_settings)
	exit_options.name = "CloseSettings"
	_style_modal_button(exit_options, false, true)
	settings_layout.add_child(exit_options)
	settings_panel.hide()
	_sync_modal_ui()


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


func _nearby_target() -> String:
	var locations: Dictionary = {}
	for key in interaction_nodes:
		var actor: Node3D = interaction_nodes[key]
		locations[key] = actor.global_position
	return Nearby.closest(player.global_position, locations)


func _update_interact_hint() -> void:
	if interact_hint == null:
		return
	if dialogue.visible or notebook_panel.visible or prep_panel.visible or settings_panel.visible:
		interact_hint.text = ""
		return
	interact_hint.text = Nearby.caption(_nearby_target())


func _interact() -> void:
	if settings_panel.visible:
		_close_settings()
		return
	if prep_panel.visible:
		_close_prep()
		return
	if notebook_panel.visible:
		_close_notebook()
		return
	if dialogue.visible:
		_advance_dialogue()
		return
	var closest: String = _nearby_target()
	if ["LOLA_HOME", "BLUE_NOTEBOOK", "WARM_CUP", "RIVER_PHOTO", "HUT_EXIT", "HUT_ENTRY"].has(closest):
		_interact_lola_hut(closest)
		return
	if closest == "":
		_show_dialogue("Move close to a resident or the old mooring to interact.")
		return
	var dialogue_line: String = NightDialogue.response(closest, story, is_night)
	match closest:
		"LOLA":
			talked_to_lola = true
			story.seen_people["lola"] = true
		"DADO":
			story.observe_clue("light_retreat")
			talked_to_dado = true
			story.seen_people["dado"] = true
		"SABEL":
			story.seen_people["sabel"] = true
			# Protect private family details; notebook stores only the fact that privacy was respected.
			story.seen_people["privacy_agreed"] = true
		"MARA":
			if story.clues.has("old_mooring"):
				story.observe_clue("boatman_name")
			story.seen_people["mara"] = true
		"MOORING":
			story.observe_clue("old_mooring")
			if story.seen_people.has("mara"):
				story.observe_clue("boatman_name")
			if is_night:
				encountered_light = true
	_show_dialogue(dialogue_line)
	_save_story_silent()
	_refresh_choices()
	_update_objective()


func _enter_lola_hut(first_visit: bool = false) -> void:
	if is_night:
		_show_dialogue("Return to Lola's home in the daylight. The river needs your attention tonight.")
		return
	in_lola_hut = true
	_teleport_with_bantay(LolaHut.INSIDE_SPAWN)
	_refresh_choices()
	_update_objective()
	if first_visit:
		_show_dialogue("LOLA: Sayu lagi ka nakamata. Bantay naghulat na.\nTan-awa ang BLUE NOTEBOOK ug WARM CUP una mogawas.")


func _leave_lola_hut() -> void:
	if not story.prologue_ready():
		_show_dialogue("LOLA: Ayaw pagdali. Dad-a ang imong asul nga notebook ug pag-inom sa usa ka tasa una.")
		return
	in_lola_hut = false
	_teleport_with_bantay(LolaHut.OUTSIDE_SPAWN)
	_refresh_choices()
	_update_objective()
	_show_dialogue("LOLA: Ayaw una isulat ang imong gituohan. Paminaw sa, dayon pangita og pamatuod. Duola si Tatay Dado sa suba.")


func _teleport_with_bantay(destination: Vector3) -> void:
	player.global_position = destination
	player.velocity = Vector3.ZERO
	bantay.global_position = destination + Vector3(1.0, -0.31, 0.55)
	bantay.velocity = Vector3.ZERO
	dog_waypoints.clear()
	dog_repath_timer = 0.0
	camera_director.reset()
	camera.size = CinematicCamera.WORLD_SIZE
	camera.global_position = player.global_position + CinematicCamera.DEFAULT_OFFSET
	camera.look_at(player.global_position + Vector3(0, 0.7, 0))


func _interact_lola_hut(id: String) -> void:
	match id:
		"LOLA_HOME":
			_show_dialogue("LOLA PASING: Sayu lagi ka nakamata. Ayaw pagdali sa suba; unsa may nakita, ug unsay nadungog lang? Ang tinuod dili kinahanglan ipugos.")
		"HUT_ENTRY":
			_enter_lola_hut()
			return
		"HUT_EXIT":
			_leave_lola_hut()
			return
		"BLUE_NOTEBOOK":
			story.inspect_prologue("blue_notebook")
			_show_dialogue("Your blue notebook is ready. Lola's words stay with you: write what you OBSERVE before believing every rumor.")
		"WARM_CUP":
			story.inspect_prologue("warm_cup")
			_show_dialogue("LOLA: Kaon sa. Ang tawo nga walay pamahaw dali ra mahadlok. Bantay rests at your feet.")
		"RIVER_PHOTO":
			story.inspect_prologue("river_photo")
			_show_dialogue("An old photo shows the river before your time. Lola smiles, but isn't ready to explain the missing names.")
	_save_story_silent()
	_refresh_choices()
	_update_objective()


func _show_dialogue(value: String) -> void:
	_clear_touch_input()
	_close_notebook()
	_close_prep()
	_close_settings()
	dialogue_pages = ConversationPages.parse(value)
	dialogue_page = 0
	dialogue.show()
	_render_dialogue_page()
	_sync_modal_ui()
	if not preferences.reduced_motion:
		dialogue.modulate.a = 0.0
		var fade := create_tween()
		fade.tween_property(dialogue, "modulate:a", 1.0, 0.22)
	else:
		dialogue.modulate.a = 1.0


func _render_dialogue_page() -> void:
	if dialogue_pages.is_empty():
		return
	var item: Dictionary = dialogue_pages[dialogue_page]
	var role: String = str(item.get("speaker", "NARRATOR"))
	dialogue_speaker.text = "%s   |   %d / %d" % [
		ConversationPages.display_name(role), dialogue_page + 1, dialogue_pages.size()
	]
	dialogue_text.text = str(item.get("text", ""))
	dialogue_portrait.call("set_speaker", role)
	dialogue_portrait.set_process(not preferences.reduced_motion)
	_frame_cinematic_speaker(role)
	var color: Color = FolkActors.identity(role)["accent"] if role != "NARRATOR" else Color("#d7c69c")
	dialogue_speaker.add_theme_color_override("font_color", color.lightened(0.15))
	dialogue_next_button.text = "NEXT SPEAKER  >" if dialogue_page + 1 < dialogue_pages.size() else "CONTINUE / CLOSE"
	var scroller := dialogue.get_node("DialogueLayout/DialogueScroll") as ScrollContainer
	scroller.scroll_vertical = 0


func _frame_cinematic_speaker(role: String) -> void:
	# Frame the physical source rather than only swapping a portrait sprite.
	# Story overlays still show the world above them.
	var target: Node3D = null
	if role == "LOLA" and in_lola_hut:
		target = get_node_or_null(LolaHut.NODE_NAME + "/Lola seated") as Node3D
	elif ["LOLA", "DADO", "MARA", "SABEL"].has(role):
		target = interaction_nodes.get(role) as Node3D
	elif role == "APPRENTICE" or role == "BANTAY":
		target = player if role == "APPRENTICE" else bantay
	elif role == "SANTELMO" and santelmo != null:
		target = santelmo as Node3D
	elif role == "NARRATOR" and is_night and santelmo != null:
		target = santelmo as Node3D
	else:
		target = player
	camera_director.focus_on(target, role)


func _advance_dialogue() -> void:
	if dialogue == null or not dialogue.visible:
		return
	if dialogue_page + 1 >= dialogue_pages.size():
		_close_dialogue()
		return
	dialogue_page += 1
	_render_dialogue_page()


func _close_dialogue() -> void:
	camera_director.release()
	if dialogue != null:
		dialogue.hide()
		dialogue.modulate.a = 1.0
	dialogue_pages.clear()
	dialogue_page = 0
	_clear_touch_input()
	_sync_modal_ui()


func _toggle_night() -> void:
	if in_lola_hut:
		_show_dialogue("Finish breakfast and use Lola's door to return outside before starting the night.")
		return
	if is_night and story.phase >= 1 and story.phase <= 3:
		_show_dialogue("The encounter has begun. Use RETREAT or the safe checkpoint, not the day/night switch.")
		return
	if not is_night and not story.kit.is_ready():
		_open_prep()
		return
	_close_prep()
	if story.outcome != "":
		_show_dialogue("The next morning has begun. Your outcome is already committed; no repeat rewards.")
		return
	is_night = not is_night
	living_sound.set_night(is_night)
	BarrioLighting.apply(sun, get_node_or_null("Environment") as WorldEnvironment, lantern, is_night)
	dog_awareness.reset()
	dog_warning_label.text = ""
	dog_warning_seconds = 0.0
	focus_held = false
	light_alarm = 0.0
	alarm_label.text = ""
	if is_night and santelmo == null:
		santelmo = SantelmoActor.new()
		add_child(santelmo)
	if santelmo != null:
		santelmo.visible = is_night
		santelmo.set_encounter_phase(story.phase)
	_refresh_choices()
	_update_objective()


func _update_objective() -> void:
	if in_lola_hut:
		if not story.prologue_flags.has("blue_notebook"):
			objective.text = "MORNING: Find your BLUE NOTEBOOK on the desk."
		elif not story.prologue_flags.has("warm_cup"):
			objective.text = "MORNING: Drink the WARM CUP at Lola's table."
		else:
			objective.text = "MORNING: Explore the photo or use HUT EXIT to begin investigating."
	elif not talked_to_lola:
		objective.text = "OBJECTIVE: Speak to Lola Pasing near her hut."
	elif not talked_to_dado:
		objective.text = "OBJECTIVE: Meet Tatay Dado by the safe river landing."
	elif story.outcome != "":
		objective.text = "MORNING AFTER: " + story.outcome.to_upper() + " — state saved."
	elif not is_night:
		objective.text = "Meet Mara, prepare four items, then choose the night."
	elif story.encounter_failed:
		objective.text = "Bantay found safe ground. RETRY checkpoint or ACCEPT PARTIAL."
	elif story.phase == 0:
		objective.text = "Collect 3 clues, link evidence pairs in NOTEBOOK, then BEGIN."
	elif story.phase == 1:
		objective.text = "Stage 1: Study the light; let its alarm settle, then OBSERVE."
	elif story.phase == 2:
		objective.text = "Stage 2: Walk to a reflected light, then INSPECT; the real one follows the slow current."
	elif story.phase == 3:
		objective.text = "Stage 3: Stand near the GREEN landing ring; hold FOCUS toward the shore until the light follows." if story.guide_progress < 0.999 else "The light has reached the safe landing. Remember Mang Celso, defend, or retreat."
	else:
		objective.text = "Night 1 completed."


func _refresh_choices() -> void:
	if stage_label == null:
		return
	var names: Array[String] = []
	if not is_night:
		if in_lola_hut and not story.seen_people.has("morning_question"):
			names = ["BANTAY WOKE ME", "LOLA, ARE YOU RESTED?", ""]
		else:
			names = ["", "", ""]
	elif story.encounter_failed:
		names = ["RETRY", "ACCEPT PARTIAL", ""]
	elif story.phase == 0:
		names = ["BEGIN" if story.can_begin() else "OPEN NOTEBOOK", "", ""]
	elif story.phase == 1:
		names = ["OBSERVE", "SHADE LAMP" if story.kit.has("cloth_wrap") and not story.kit.is_used("cloth_wrap") else "", "RETREAT"]
	elif story.phase == 2:
		names = ["INSPECT LIGHT", "HINT", "RETREAT"]
	elif story.phase == 3:
		names = ["REMEMBER" if story.guide_progress >= 0.999 else "GUIDE TO SHORE", "DRIVE AWAY" if story.kit.has("signal_bell") else "NEED BELL", "RETREAT"]
	else:
		names = ["", "", ""]
	for i in range(choice_buttons.size()):
		choice_buttons[i].text = names[i]
		choice_buttons[i].visible = names[i] != ""
	stage_label.text = MorningAftermath.morning_label(story.outcome) if story.outcome != "" else "CLUES: %d/3  •  PHASE: %d  •  GUIDE: %d%%" % [story.clues.size(), story.phase, roundi(story.guide_progress * 100.0)] if story.phase == 3 else "CLUES: %d/3  •  PHASE: %d  •  OUTCOME: pending" % [story.clues.size(), story.phase]


func _choose_story_action(index: int) -> void:
	if not is_night and in_lola_hut and not story.seen_people.has("morning_question"):
		if index == 0:
			story.seen_people["morning_question"] = "lighthearted"
			_show_dialogue("APPRENTICE: Mas una man gud nagmata si Bantay.\nLOLA: Kung siya pa lang ang mag-alarm sa buntag, wala na untay kinahanglan nga manok.")
		elif index == 1:
			story.seen_people["morning_question"] = "concerned"
			_show_dialogue("APPRENTICE: Lola, nakapahulay ra ka?\nLOLA: Makahulay ra ko. Ikaw, kaon sa. Ang uban nga kasakit dili madaog sa pagdali.")
		_save_story_silent()
		_refresh_choices()
		return
	if not is_night or story.outcome != "":
		return
	if story.encounter_failed:
		if index == 0:
			_retry_story()
		elif index == 1:
			_commit_night("partial")
		return
	if story.phase == 0:
		if index == 0:
			if story.begin():
				_save_story_silent()
				_show_dialogue("The first light rises above the old bank. Watch its response, and do not chase it into the river.")
			else:
				_open_notebook()
	elif story.phase == 1:
		if index == 2:
			_commit_night("partial")
		elif index == 1 and story.shade_lantern():
			if santelmo != null:
				santelmo.alarm = story.alarm
			_show_dialogue("Cloth softens the lantern beam. The light settles. One cloth wrap used.")
			_save_story_silent()
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
			if preferences.hint_level == 0:
				_show_dialogue("Compare the glows as the water moves. What did Dado observe?")
			elif preferences.hint_level == 1:
				_show_dialogue("One reflection moves with the slow current; the other jitters.")
			else:
				_show_dialogue("Full hint: the golden marker near the old mooring follows the slow current. Approach and INSPECT.")
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
			if story.guide_progress >= 0.999:
				_commit_night("resolve")
			else:
				_show_dialogue("Gently GUIDE the light in the world first. Stand by the GREEN landing ring, hold Focus and aim toward shore, away from the spirit. Then remember Mang Celso.")
		elif index == 1:
			if story.kit.has("signal_bell"):
				_commit_night("drive_away")
			else:
				_show_dialogue("No warning bell is prepared. Choose remembrance or return safely.")
		elif index == 2:
			_commit_night("partial")
	if santelmo != null:
		santelmo.set_encounter_phase(story.phase)
		santelmo.set_guide_progress(story.guide_progress)
	_refresh_choices()
	_update_objective()


func _commit_night(result: String) -> void:
	if result == "partial":
		if not story.accept_partial():
			return
	elif not story.commit_result(result):
		return
	is_night = false
	living_sound.set_night(false)
	BarrioLighting.apply(sun, get_node_or_null("Environment") as WorldEnvironment, lantern, false)
	MorningAftermath.ensure(self, story.outcome)
	if santelmo != null:
		santelmo.visible = false
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


func _open_settings() -> void:
	_clear_touch_input()
	_close_dialogue()
	_close_notebook()
	_close_prep()
	settings_panel.show()
	_refresh_options()
	_sync_modal_ui()


func _close_settings() -> void:
	if settings_panel != null:
		settings_panel.hide()
	_clear_touch_input()
	_sync_modal_ui()


func _refresh_options() -> void:
	pref_text_button.text = "TEXT SIZE: %d%%" % roundi(preferences.text_scale * 100.0)
	pref_motion_button.text = "REDUCED MOTION: %s" % ("ON" if preferences.reduced_motion else "OFF")
	pref_contrast_button.text = "HIGH-CONTRAST TEXT: %s" % ("ON" if preferences.high_contrast else "OFF")
	pref_hint_button.text = "PUZZLE HINTS: " + str(preferences.HINT_LEVELS[preferences.hint_level])
	pref_assist_button.text = "STORY ASSIST / NO-FAIL: " + ("ON" if preferences.story_assist else "OFF")
	pref_audio_button.text = "AMBIENCE: " + (["OFF", "QUIET", "NORMAL"][preferences.audio_level])


func _apply_preferences() -> void:
	var scale: float = preferences.text_scale
	var labels: Array[Label] = [info, objective, stage_label, alarm_label, interact_hint, dog_warning_label, dialogue_text, notebook_body, prep_summary, courage_label]
	var base_sizes: Array[int] = [24, 22, 20, 18, 21, 18, 25, 27, 26, 20]
	for i in range(labels.size()):
		var element: Label = labels[i]
		if element == null:
			continue
		element.add_theme_font_size_override("font_size", roundi(float(base_sizes[i]) * scale))
		if preferences.high_contrast:
			element.add_theme_color_override("font_color", Color.WHITE)
			element.add_theme_color_override("font_outline_color", Color.BLACK)
			element.add_theme_constant_override("outline_size", 3)
		else:
			element.remove_theme_color_override("font_color")
			element.remove_theme_color_override("font_outline_color")
			element.remove_theme_constant_override("outline_size")
	var headers: Array[Label] = [
		notebook_panel.get_node("NotebookLayout/NotebookHeading") as Label,
		evidence_heading,
		theory_heading,
		prep_panel.get_node("PreparationLayout/PreparationScroll/EquipmentContent/PreparationHeading") as Label,
		settings_panel.get_node("SettingsLayout/SettingsScroll/OptionsContent/OptionsHeading") as Label
	]
	if dialogue_speaker != null:
		dialogue_speaker.add_theme_font_size_override("font_size", roundi(30.0 * scale))
	if dialogue_portrait != null:
		dialogue_portrait.set_process(not preferences.reduced_motion)
	for heading in headers:
		heading.add_theme_font_size_override("font_size", roundi(30.0 * scale))
		heading.add_theme_color_override("font_color", Color(0.98, 0.89, 0.68))
	for button in [link_light_button, link_ledger_button, notebook_guide, notebook_chase]:
		_style_modal_button(button)
	for id in prep_buttons:
		_style_modal_button(prep_buttons[id] as Button, story.kit.has(id))
	for button in [prep_water_button, pref_text_button, pref_motion_button, pref_contrast_button, pref_hint_button, pref_assist_button, pref_audio_button]:
		_style_modal_button(button)
	for footer in [
		notebook_panel.get_node("NotebookLayout/CloseNotebook") as Button,
		prep_panel.get_node("PreparationLayout/ClosePreparation") as Button,
		settings_panel.get_node("SettingsLayout/CloseSettings") as Button,
		dialogue.get_node("DialogueLayout/CloseDialogue") as Button
	]:
		_style_modal_button(footer, false, true)
	if settings_panel != null:
		_refresh_options()


func _cycle_text_size() -> void:
	preferences.next_text_scale()
	preferences.save_to()
	_apply_preferences()


func _toggle_reduced_motion() -> void:
	preferences.reduced_motion = not preferences.reduced_motion
	preferences.save_to()
	_apply_preferences()


func _toggle_contrast() -> void:
	preferences.high_contrast = not preferences.high_contrast
	preferences.save_to()
	_apply_preferences()


func _cycle_audio_level() -> void:
	preferences.next_audio_level()
	living_sound.set_audio_level(preferences.audio_level)
	preferences.save_to()
	_apply_preferences()


func _cycle_hint_level() -> void:
	preferences.next_hint_level()
	preferences.save_to()
	_apply_preferences()


func _toggle_story_assist() -> void:
	preferences.story_assist = not preferences.story_assist
	preferences.save_to()
	_apply_preferences()


func _open_prep() -> void:
	_clear_touch_input()
	_close_dialogue()
	_close_notebook()
	_close_settings()
	prep_panel.show()
	_refresh_prep()
	_sync_modal_ui()


func _close_prep() -> void:
	if prep_panel != null:
		prep_panel.hide()
	_clear_touch_input()
	_sync_modal_ui()


func _refresh_prep() -> void:
	if story.outcome != "":
		prep_summary.text = "NIGHT 1 COMPLETE  |  EQUIPMENT LOCKED  |  %d / 4" % story.kit.selected.size()
	elif is_night or story.phase > 0:
		prep_summary.text = "NIGHT IN PROGRESS  |  EQUIPPED: %d / 4" % story.kit.selected.size()
	else:
		prep_summary.text = "TAP TO EQUIP / REMOVE  |  %d / 4  |  %s" % [story.kit.selected.size(), "READY" if story.kit.is_ready() else "SELECT FOUR"]
	for id in story.kit.ITEMS:
		var item_button: Button = prep_buttons[id]
		item_button.text = ("EQUIPPED   •   " if story.kit.has(id) else "AVAILABLE   •   ") + str(story.kit.NAMES[id])
		item_button.disabled = is_night or story.phase > 0 or story.outcome != ""
		_style_modal_button(item_button, story.kit.has(id))
	prep_water_button.visible = is_night and story.phase >= 1 and story.phase <= 3
	prep_water_button.disabled = not story.kit.has("water_flask") or story.kit.is_used("water_flask") or story.encounter_failed
	prep_water_button.text = "DRINK WATER (restores courage)" if not story.kit.is_used("water_flask") else "WATER USED"


func _use_water() -> void:
	if story.drink_water():
		light_alarm = story.alarm
		if santelmo != null:
			santelmo.alarm = story.alarm
		_save_story_silent()
		_show_dialogue("You pause on safe ground, drink water, and steady your breathing. Courage restored.")
	else:
		_refresh_prep()


func _toggle_kit_item(id: String) -> void:
	if is_night or story.phase > 0 or story.outcome != "":
		return
	if story.kit.toggle(id):
		_save_story_silent()
	_refresh_prep()


func _open_notebook() -> void:
	_clear_touch_input()
	_close_settings()
	_close_prep()
	if notebook_panel.visible:
		_close_notebook()
		return
	_close_dialogue()
	notebook_panel.show()
	_refresh_notebook()
	_sync_modal_ui()


func _refresh_notebook() -> void:
	notebook_body.text = "\n".join(NightJournal.lines(story))
	evidence_heading.visible = (story.clues.has("light_retreat") and story.clues.has("old_mooring")) or (story.clues.has("old_mooring") and story.clues.has("boatman_name"))
	link_light_button.visible = story.clues.has("light_retreat") and story.clues.has("old_mooring")
	link_light_button.disabled = story.phase > 0 or story.evidence_links.has("light_mooring")
	link_light_button.text = "LINKED: DADO + MOORING" if story.evidence_links.has("light_mooring") else "LINK: DADO + MOORING"
	_style_modal_button(link_light_button, story.evidence_links.has("light_mooring"))
	link_ledger_button.visible = story.clues.has("old_mooring") and story.clues.has("boatman_name")
	link_ledger_button.disabled = story.phase > 0 or story.evidence_links.has("ledger_mooring")
	link_ledger_button.text = "LINKED: MOORING + MARA" if story.evidence_links.has("ledger_mooring") else "LINK: MOORING + MARA"
	_style_modal_button(link_ledger_button, story.evidence_links.has("ledger_mooring"))
	notebook_guide.disabled = story.outcome != ""
	notebook_chase.disabled = story.outcome != ""
	_style_modal_button(notebook_guide, story.hypothesis == "guide")
	_style_modal_button(notebook_chase, story.hypothesis == "chase")


func _link_clues(id: String) -> void:
	if story.link_evidence(id):
		_save_story_silent()
		_refresh_choices()
		_update_objective()
	_refresh_notebook()


func _select_theory(value: String) -> void:
	if story.outcome != "":
		return
	story.choose_hypothesis(value)
	_save_story_silent()
	_refresh_notebook()


func _close_notebook() -> void:
	if notebook_panel != null:
		notebook_panel.hide()
	_clear_touch_input()
	_sync_modal_ui()


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
	if story.outcome != "":
		MorningAftermath.ensure(self, story.outcome)
	if bool(data.get("night", false)) and story.outcome == "":
		_toggle_night()
		light_alarm = story.alarm
		if santelmo != null:
			santelmo.alarm = story.alarm
			santelmo.set_encounter_phase(story.phase)
			santelmo.set_guide_progress(story.guide_progress)
	_refresh_choices()


func _retry_story() -> void:
	if story.retry_from_checkpoint():
		light_alarm = story.alarm
		if santelmo != null:
			santelmo.alarm = story.alarm
		_save_story_silent()
		if santelmo != null:
			santelmo.set_encounter_phase(story.phase)
			santelmo.set_guide_progress(story.guide_progress)
		_show_dialogue("Restored the safe encounter checkpoint; no permanent resources were duplicated.")
	else:
		_show_dialogue("No uncommitted encounter checkpoint is available.")
	_refresh_choices()
	_update_objective()
