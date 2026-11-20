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
const EnvironmentPolish = preload("res://scripts/world/environment_polish.gd")
const IllustratedBarrio = preload("res://scripts/world/illustrated_barrio.gd")
const SoftwareWorldFallback = preload("res://scripts/visuals/software_world_fallback.gd")
const RendererPolicy = preload("res://scripts/visuals/android_renderer_policy.gd")
const SOIL_ART: Texture2D = preload("res://assets/world/soil_ground.svg")
const PATH_ART: Texture2D = preload("res://assets/world/earthen_path.svg")
const WATER_ART: Texture2D = preload("res://assets/world/tidal_water.svg")
const UI_PREPARE: Texture2D = preload("res://assets/ui/prepare.svg")
const UI_NOTEBOOK: Texture2D = preload("res://assets/ui/notebook.svg")
const UI_FOCUS: Texture2D = preload("res://assets/ui/focus.svg")
const UI_INTERACT: Texture2D = preload("res://assets/ui/interact.svg")
const UI_DAYNIGHT: Texture2D = preload("res://assets/ui/daynight.svg")
const Mangrove = preload("res://scripts/world/mangrove.gd")
const CinematicCamera = preload("res://scripts/visuals/cinematic_camera.gd")
const SharedHUD = preload("res://scripts/ui/shared_hud.gd")
const SharedOptions = preload("res://scripts/ui/shared_options.gd")
const SharedDialogueMotion = preload("res://scripts/ui/shared_dialogue_motion.gd")
const SharedAtmosphere = preload("res://scripts/visuals/shared_immersive_atmosphere.gd")
const BarrioLighting = preload("res://scripts/visuals/barrio_lighting.gd")
const NightWindows = preload("res://scripts/visuals/nighttime_windows.gd")
const RiverBanca = preload("res://scripts/world/river_banca.gd")
const PostgameBarrio = preload("res://scripts/world/postgame_barrio_3d.gd")
const PostgameDialogue = preload("res://scripts/narrative/postgame_dialogue.gd")
const BantayRoute = preload("res://scripts/ai/bantay_route.gd")
const BantayAwareness = preload("res://scripts/ai/bantay_awareness.gd")
const AimPad = preload("res://scripts/ui/aim_pad.gd")
const SaveService = preload("res://scripts/core/save_service.gd")
const Night02Scene = preload("res://scenes/night02.tscn")
const ConnectedWorld = preload("res://scripts/core/connected_world.gd")
const NorthGrove = preload("res://scripts/world/north_grove_layout.gd")
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
var save_main_menu_button: Button
var begin_night2_button: Button
var quit_game_button: Button
var main_menu_confirmation: ConfirmationDialog
var quit_game_confirmation: ConfirmationDialog
var navigation_error_dialog: AcceptDialog
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
var interaction_identity_tags: Dictionary = {}
var dog_warning_seconds := 0.0
var dog_waypoints := PackedVector3Array()
var dog_next_waypoint := 0
var dog_repath_timer := 0.0
var camera_director = CinematicCamera.new()
var camera: Camera3D
var software_world_fallback: Control
var atmosphere_fx
var lantern: SpotLight3D
var status_panel: PanelContainer
var status_stack: VBoxContainer
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
var focus_button: Button
var focus_feedback: Label
var focus_visual_state := -1
var manual_aim := Vector2.ZERO
var light_alarm := 0.0
var guide_was_complete := false
var lamp_heading := Vector3.FORWARD
var alarm_label: Label
var move_buttons: Dictionary = {}
var is_night := false
var daynight_button: Button
var talked_to_lola := false
var talked_to_dado := false
var encountered_light := false
var in_lola_hut := false
var santelmo
var ambient_walkers: Array[Node3D] = []
var postgame_barrio: Node3D
var elapsed := 0.0
var window_light_refresh := 0.0
var encounter_autosave_clock := 0.0


func _ready() -> void:
	# This must happen before any meshes, Sprite3D or 3D lights are created.
	# SwiftShader cannot link some Godot GLES3 spatial shader permutations.
	# Camera3D projection and collision stay active for the 2D fallback.
	var adapter := RenderingServer.get_video_adapter_name()
	if RendererPolicy.configure_viewport(get_viewport(),adapter):
		print("NIGHT1_QA_SOFTWARE_2D_VIEWPORT_ENABLED")
	preferences.load_from()
	_create_world()
	_create_ambient_walkers()
	_create_player()
	_create_bantay()
	_create_camera()
	_create_lighting()
	_create_audio()
	_create_software_world_fallback()
	_create_immersive_atmosphere()
	_create_ui()
	_build_world_interaction_tags()
	_apply_preferences()
	_restore_story()
	if _postgame_is_active():
		postgame_barrio = PostgameBarrio.ensure(self)
	if _postgame_is_active() and daynight_button != null:
		daynight_button.text = "AUTO CYCLE"
		daynight_button.disabled = true
		daynight_button.tooltip_text = "After the finale, day and night advance automatically."
		daynight_button.set_meta("postgame_clock", "automatic")
		# Do not use Night 1's manual time button during free roam.
	NightWindows.sync_barrio_3d(self,is_night,elapsed,preferences.reduced_motion)
	_apply_connected_world_arrival()
	if story.outcome == "" and not story.prologue_ready():
		_enter_lola_hut(true)
	_update_objective()
	# An observable *game scene* signal: a title/options screen must never
	# count as a passing Android gameplay smoke test again.
	print("NIGHT1_QA_GAMEPLAY_SCENE_READY")


func _physics_process(delta: float) -> void:
	# The complete seven-night epilogue replaces the old time switch with
	# one shared continuous clock; unfinished chapters stay story-controlled.
	if _postgame_is_active():
		var world_night: bool = get_node("/root/PostgameClock").is_night()
		if is_night != world_night:
			is_night = world_night
			living_sound.set_night(is_night)
			BarrioLighting.apply(sun, get_node_or_null("Environment") as WorldEnvironment, lantern, is_night)
			NightWindows.sync_barrio_3d(self,is_night,elapsed,preferences.reduced_motion)
			if santelmo != null:
				santelmo.visible = false
	if postgame_barrio != null:
		var village_clock := get_node_or_null("/root/PostgameClock")
		if village_clock != null and village_clock.is_active():
			PostgameBarrio.update(postgame_barrio,village_clock.fraction(),elapsed,preferences.reduced_motion,village_clock.village_mood)
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
	_sync_postgame_named_witnesses()
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
				# Visuals go indoors after dark. The original named interaction
				# markers and story dialogue remain intact for progression.
				witness.visible = NightWindows.outdoor_actor_visible(1,2 if is_night else 0,role)
	if in_lola_hut:
		var elder := get_node_or_null(LolaHut.NODE_NAME + "/Lola seated") as Node3D
		FolkActors.animate_expression(elder, elapsed, speaking_role == "LOLA", preferences.reduced_motion)
	camera_director.tick(camera, player, delta, preferences.reduced_motion)
	# Lola's cutaway is a single 9x8m interior. During free exploration,
	# anchor the view to the room (not every player step) so furniture, exit,
	# and 2 rear walls stay composed. Story close-ups are unaffected.
	if in_lola_hut and not camera_director.is_framing():
		var room_center: Vector3 = LolaHut.CENTER + Vector3(0, 0.65, 0)
		var room_camera: Vector3 = room_center + Vector3(8.0, 11.5, 8.0)
		var smooth: float = 1.0 if preferences.reduced_motion else clampf(delta * 4.5, 0.0, 1.0)
		camera.global_position = camera.global_position.lerp(room_camera, smooth)
		camera.look_at(room_center)
		camera.size = lerpf(camera.size, 7.9, smooth)
	RiverBanca.animate(river_boat, elapsed, preferences.reduced_motion)
	elapsed += delta
	window_light_refresh += delta
	if window_light_refresh >= .38:
		window_light_refresh = 0.0
		NightWindows.sync_barrio_3d(self,is_night,elapsed,preferences.reduced_motion)
		if _postgame_is_active():
			_update_objective()
	if is_night and santelmo != null and story.outcome == "":
		# Keep world and encounter animations progressing in the background,
		# but never drain courage while the player is reading a modal.
		light_alarm = santelmo.update_behavior(delta, player.global_position, lamp_heading, focus_held)
		story.alarm = light_alarm
		_advance_safe_guiding(delta)
		encounter_autosave_clock += delta
		if encounter_autosave_clock >= 10.0 and story.outcome == "" and story.phase >= 1:
			encounter_autosave_clock = 0.0
			_save_story_silent()
		if not _is_reading_ui() and story.tick_courage(delta, preferences.story_assist):
			_show_dialogue("Bantay leads you back from the frightening light. You can RETRY the safe checkpoint or ACCEPT PARTIAL.")
			_refresh_choices()
			_update_objective()
		alarm_label.text = "SANTELMO • %s" % ("ALARMED — lower Focus" if light_alarm > 0.65 else "WATCHING — avoid direct Focus" if light_alarm > 0.2 else "CALM — avoid aiming at it")
	if courage_label != null:
		courage_label.text = "COURAGE %d / 100" % roundi(story.courage) if is_night and story.phase >= 1 and story.phase <= 3 else ""
		courage_label.visible = courage_label.text != ""
	if alarm_label != null:
		alarm_label.visible = is_night and story.phase >= 1 and story.phase <= 3
	if dog_warning_label != null:
		dog_warning_label.visible = dog_warning_label.text != ""
	_update_focus_ui()
	# Peripheral cues and a low-frequency sound pulse respond to actual
	# encounter danger. No scripted jumpscares, no forced camera shakes.
	var fear := maxf(light_alarm, (100.0-story.courage)/100.0*.70)
	if living_sound != null:
		living_sound.set_pressure(fear if is_night and not in_lola_hut else 0.0)
	if atmosphere_fx != null:
		atmosphere_fx.configure(1, 2 if is_night and not in_lola_hut else 0, fear, preferences.reduced_motion)
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
			river_mat.albedo_color = Color.WHITE.lerp(Color("#cde1d6"), 0.12 + 0.08 * sin(elapsed * 1.2))


func _unhandled_input(event: InputEvent) -> void:
	# Internal QA camera tour for ACTUAL Android screenshots, not a mockup.
	# F6/F7/F8 are inaccessible from ordinary touch gameplay and exist only
	# in debug APKs; they do not save or change canonical story decisions.
	if OS.get_name() == "Android" and OS.has_feature("debug") and event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			match key.keycode:
				KEY_F5:
					_qa_show_world_view(Vector3(1.0, 0.75, -31.1), false, "NORTH_TRAIL")
					get_viewport().set_input_as_handled()
					return
				KEY_F6:
					_qa_show_world_view(Vector3(2.0, 0.75, -4.0), false, "VILLAGE")
					get_viewport().set_input_as_handled()
					return
				KEY_F7:
					_qa_show_world_view(Vector3(-6.0, 0.75, 9.0), false, "SHORE")
					get_viewport().set_input_as_handled()
					return
				KEY_F8:
					_qa_show_world_view(Vector3(-7.0, 0.75, 12.0), true, "NIGHT")
					get_viewport().set_input_as_handled()
					return
	if event.is_action_pressed("ui_accept"):
		if dialogue != null and dialogue.visible:
			_on_dialogue_continue_pressed()
		else:
			_interact()
	if event.is_action_pressed("ui_focus_next"):
		_set_focus(true)
	if event.is_action_released("ui_focus_next"):
		_set_focus(false)
	if event.is_action_pressed("ui_cancel"):
		_close_dialogue()
		_close_notebook()
		_close_prep()
		_close_settings()


func _qa_show_world_view(destination: Vector3, night_view: bool, label: String) -> void:
	# QA-only inspection changes no save file or canonical investigation state.
	_close_dialogue()
	_close_notebook()
	_close_prep()
	_close_settings()
	in_lola_hut = false
	_teleport_with_bantay(destination)
	is_night = night_view
	living_sound.set_night(night_view)
	BarrioLighting.apply(sun, get_node_or_null("Environment") as WorldEnvironment, lantern, night_view)
	NightWindows.sync_barrio_3d(self,is_night,elapsed,preferences.reduced_motion)
	if night_view and santelmo == null:
		santelmo = SantelmoActor.new()
		add_child(santelmo)
	if santelmo != null:
		santelmo.visible = night_view
		santelmo.set_encounter_phase(story.phase)
	_refresh_choices()
	_update_objective()
	print("NIGHT1_QA_VIEW_" + label)


func _create_world() -> void:
	# The backdrop must extend past the walkable north trail. Earlier the soil
	# stopped at z=-23 so the route ended in a cyan void on Android.
	_box("Ground", Vector3(0, -0.35, -10), Vector3(88, 0.65, 90), COLORS.earth, true)
	var blockout_road := _box("Main footpath", Vector3(0, 0.015, 0), Vector3(5, 0.08, 38), COLORS.path, false)
	blockout_road.visible = false  # the winding illustrated footpath now replaces this rectangle
	river_surface = _box("River", Vector3(-16, 0.02, -9), Vector3(12, 0.08, 66), COLORS.river, false) as MeshInstance3D
	for z in [4.0, 11.0, 18.0]:
		_box("Reed", Vector3(-9.1, 0.4, z), Vector3(0.13, 0.7, 0.11), Color(0.43, 0.53, 0.26), false)
	for z in [-16.0, -10.0, 0.0, 7.0, 15.0]:
		_box("River shimmer", Vector3(-15.0, 0.08, z), Vector3(4.3, 0.025, 0.12), Color(0.22, 0.59, 0.61), false)
	var old_barrier := _box("River bank safety fence", Vector3(-9.7, 0.5, -7), Vector3(0.25, 1.0, 66), COLORS.wood, true)
	old_barrier.visible = false  # invisible solid boundary; visible art uses woven ropes and posts
	# Collision-only boundaries prevent accidental falls beyond the playable blockout.
	_boundary(Vector3(-23.0, 1.0, -7.0), Vector3(0.3, 3.0, 65.0))
	_boundary(Vector3(23.0, 1.0, -7.0), Vector3(0.3, 3.0, 65.0))
	# The only travel portal is the marked forest trail near z=-32;
	# the invisible perimeter remains beyond it for safe Android physics.
	_boundary(Vector3(0.0, 1.0, -39.0), Vector3(46.0, 3.0, 0.3))
	_boundary(Vector3(0.0, 1.0, 25.0), Vector3(46.0, 3.0, 0.3))
	_house(Vector3(6, 0, 5), "Lola's hut")
	_house(Vector3(7, 0, -8), "Sabel's store")
	_house(Vector3(-2, 0, -12), "School")
	# One continuous landing: shore access -> mud bank -> floating river end.
	# Timber supports sit BELOW the walkway. They are visual-only and
	# never change the tested Dado/Mooring clue interaction coordinates.
	_box("Landing", Vector3(-8.55, 0.10, 9), Vector3(7.0, 0.28, 3.05), COLORS.wood, false)
	for x in [-11.65, -10.92, -10.19, -9.46, -8.73, -8.00, -7.27, -6.54, -5.81]:
		_box("Landing plank", Vector3(x, 0.28, 9), Vector3(0.10, 0.055, 2.96), Color("#be9562"), false)
	for x in [-11.35, -8.50, -5.88]:
		for z in [7.65, 10.36]:
			_box("Dock stilt", Vector3(x, -0.28, z), Vector3(.18, 1.18, .18), Color("#6b4b34"), false)
	_box("Dock side rail north", Vector3(-8.55, 0.36, 7.52), Vector3(7.06, .11, .14), Color("#79583d"), false)
	_box("Dock side rail south", Vector3(-8.55, 0.36, 10.49), Vector3(7.06, .11, .14), Color("#79583d"), false)
	# The banca must float in the river, not sit on the village dirt/road.
	# Far enough west that both outriggers are inside the water boundary.
	river_boat = RiverBanca.build(self, Vector3(-13.0, 0.15, 9.0))
	var mangrove_index := 0
	for x in [-19.0, -13.0, 13.0, 19.0]:
		for z in [-18.0, -5.0, 14.0]:
			if x < 0.0:
				Mangrove.build(self, Vector3(x, -0.04, z), mangrove_index)
				mangrove_index += 1
			else:
				# Inland tree spheres retired: authored banana and garden cutouts
				# in IllustratedBarrio now cover these spots without path obstacles.
				pass
	for z in [-12.0, 1.0]:
		Mangrove.build(self, Vector3(-11.75, -0.04, z), mangrove_index)
		mangrove_index += 1
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
	EnvironmentPolish.decorate(self)
	IllustratedBarrio.decorate(self)
	NorthGrove.decorate(self)
	_build_mango_tree_trail()


func _build_mango_tree_trail() -> void:
	# One walkable in-world north trail exits Barrio Lawom toward the old
	# mango tree. Separate Godot scenes are streamed regions of ONE map.
	var at: Vector3 = ConnectedWorld.TRAIL_BARRIO
	var gate := Node3D.new()
	gate.name = "MANGO_TRAIL"
	gate.position = at
	add_child(gate)
	interaction_nodes["MANGO_TRAIL"] = gate
	# Clear bamboo trail guide: worn timber sleepers lead right to the map
	# boundary, not a disconnected level-select button.
	for i in range(23):
		var z := -15.15 - float(i) * .74
		_box("Old Mango Trail sleeper %02d" % i,
			Vector3(1.0, 0.085, z), Vector3(2.80, .10, .17),
			Color("#aa855c") if i % 2 == 0 else Color("#836345"), false)
	for x in [-0.65, 2.65]:
		_box("Mango Trail bamboo marker", Vector3(x, .88, -32.28),
			Vector3(.13, 1.76, .14), Color("#886a46"), false)
	_box("Mango Trail signboard", Vector3(1.0, 1.73, -32.28),
		Vector3(3.57, .52, .14), Color("#c6a474"), false)
	_box("Mango Trail bamboo roof", Vector3(1.0, 2.04, -32.25),
		Vector3(4.1, .17, .53), Color("#75563b"), false)
	var sign := Label3D.new()
	sign.name = "North Trail sign lettering"
	sign.text = "OLD MANGO GROVE  •  NORTH"
	sign.font_size = 42
	sign.pixel_size = .0043
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.modulate = Color("#f8e5b5")
	sign.position = Vector3(1.0, 1.68, -32.1)
	add_child(sign)
	# Actual target coordinates remain within the existing village boundary.


func _apply_connected_world_arrival() -> void:
	var arrival: Dictionary = ConnectedWorld.consume_arrival("barrio_lawom")
	if arrival.is_empty():
		return
	if str(arrival.get("from", "")) != "old_mango":
		return
	player.global_position = ConnectedWorld.ARRIVAL_BARRIO
	bantay.global_position = ConnectedWorld.ARRIVAL_BARRIO + Vector3(1.1, -.27, .4)
	_clear_touch_input()
	print("TABI_WORLD_ARRIVAL_BARRIO_FROM_MANGO")


func _box(name: String, pos: Vector3, size: Vector3, color: Color, solid: bool) -> Node3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.93
	# Textured terrain is a deliberate art asset, not giant single-color boxes.
	# UV repeats keep ground details readable at the game's orthographic zoom.
	match name:
		"Ground":
			material.albedo_texture = SOIL_ART
			material.albedo_color = Color.WHITE
			material.uv1_scale = Vector3(9.0, 1.0, 9.0)
		"Main footpath":
			material.albedo_texture = PATH_ART
			material.albedo_color = Color.WHITE
			material.uv1_scale = Vector3(1.0, 1.0, 8.0)
		"River":
			material.albedo_texture = WATER_ART
			material.albedo_color = Color.WHITE
			material.metallic = 0.12
			material.uv1_scale = Vector3(2.0, 1.0, 8.0)
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
	# Retain the same authoritative building collision but NEVER render the
	# obsolete solid cube/flat roof underneath the authored nipa structures.
	# The earlier overlap produced broken facades and roofs in actual screenshots.
	var old_box := _box(name, pos + Vector3(0, 1.2, 0), Vector3(4, 2.4, 4), COLORS.wood, true)
	old_box.visible = false
	old_box.set_meta("collision_only_blockout", true)
	var old_roof := _box(name + " roof", pos + Vector3(0, 2.75, 0), Vector3(5.0, 0.5, 5.0), COLORS.roof, false)
	old_roof.visible = false
	old_roof.set_meta("retired_visual_blockout", true)


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
	var was_ready: bool = story.can_remember()
	story.guide_to_landing(delta, close_enough, focus_held, direction_correct)
	_update_focus_ui()
	if santelmo != null:
		santelmo.set_guide_progress(story.guide_progress)
	if story.can_remember() and not was_ready:
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
	_set_focus(false)
	touch_axes = Vector2.ZERO
	move_buttons.clear()


func _create_audio() -> void:
	living_sound = LivingSound.new()
	living_sound.name = "Living Barrio Ambience"
	add_child(living_sound)
	living_sound.set_audio_level(preferences.audio_level)


func _fit_status_card() -> void:
	# Let the status card grow when accessibility text or objectives wrap.
	# Avoid the fixed 250px card which clipped Stage 3 at 140% text size.
	if status_panel == null or status_stack == null or not is_inside_tree():
		return
	var needed: float = status_stack.get_combined_minimum_size().y + 30.0
	var available: float = get_viewport().get_visible_rect().size.y * 0.67
	status_panel.offset_bottom = clampf(needed, 145.0, available)


func _style_modal(panel: PanelContainer) -> void:
	SharedHUD.style_modal_panel(panel)

func _menu_style(fill: Color, outline: Color) -> StyleBoxFlat:
	return SharedHUD.modal_button_style(fill,outline)

func _style_game_button(button: Button, title: String, touch: bool = false) -> void:
	SharedHUD.style_game_button(button, 18 if touch and title.length() > 2 else 23, touch)

func _style_modal_button(button: Button, selected: bool = false, footer: bool = false) -> void:
	SharedHUD.style_modal_button(button,selected,footer,preferences.text_scale)

func _sync_modal_ui() -> void:
	if gameplay_hud == null or modal_backdrop == null:
		return
	var active: bool = _is_reading_ui()
	var was_visible := gameplay_hud.visible
	gameplay_hud.visible = not active
	if active and was_visible:
		SharedDialogueMotion.reset_gameplay(gameplay_hud)
	elif not active and not was_visible:
		SharedDialogueMotion.restore_gameplay(gameplay_hud,preferences.reduced_motion)
	modal_backdrop.visible = active
	modal_backdrop.color = Color(0.015, 0.035, 0.05, 0.30 if dialogue != null and dialogue.visible else 0.76)


func _create_software_world_fallback() -> void:
	var adapter_name := RenderingServer.get_video_adapter_name()
	if not SoftwareWorldFallback.needs_software_draw(adapter_name):
		return
	# Only software GL adapter family lacks the 3D spatial shaders required
	# by the normal world renderer. The interactive 3D simulation stays live.
	var canvas := CanvasLayer.new()
	canvas.name = "AndroidSoftwareWorldFallback"
	canvas.layer = 1
	add_child(canvas)
	software_world_fallback = SoftwareWorldFallback.new()
	canvas.add_child(software_world_fallback)
	software_world_fallback.bind_game(self, camera)
	print("Night 1: using LIVE 2.5D gameplay renderer on ", adapter_name)


func _create_immersive_atmosphere() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "SharedNightAtmosphere"
	canvas.layer = 1 # above Android fallback, strictly below HUD layer 2
	add_child(canvas)
	atmosphere_fx = SharedAtmosphere.new()
	canvas.add_child(atmosphere_fx)

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	# Separate from the compatibility rendering canvas, always above it.
	canvas.layer = 2
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
	# A vertical, wrapping status card prevents the objective, clue progress,
	# Santelmo alarm, companion alerts and courage from occupying fixed Y slots.
	var status := SharedHUD.create_status_card(gameplay_hud, "TABI-TABI  •  BARRIO LAWOM", preferences.text_scale)
	status_panel = status["panel"]
	status_stack = status["stack"]
	info = status["heading"]
	objective = status["objective"]
	status_stack.minimum_size_changed.connect(func(): call_deferred("_fit_status_card"))
	SharedHUD.create_movement_joystick(gameplay_hud,preferences,
		func(axis: Vector2): touch_axes = axis)
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
	focus_button = _make_button(gameplay_hud, "HOLD FOCUS", Vector2(1050, 490), Vector2(180, 60), func(): _set_focus(true), func(): _set_focus(false))
	focus_button.name = "FocusHoldButton"
	_update_focus_ui()
	_make_button(gameplay_hud, "INTERACT", Vector2(1050, 565), Vector2(180, 60), _interact, func(): pass)
	daynight_button = _make_button(gameplay_hud, "DAY / NIGHT", Vector2(1050, 640), Vector2(180, 56), _toggle_night, func(): pass)
	_make_button(gameplay_hud, "FIELD NOTES", Vector2(1050, 415), Vector2(180, 56), _open_notebook, func(): pass)
	_make_button(gameplay_hud, "PREPARE", Vector2(1050, 276), Vector2(180, 56), _open_prep, func(): pass)
	_make_button(gameplay_hud, "SAVE", Vector2(1050, 345), Vector2(85, 52), _save_story, func(): pass)
	_make_button(gameplay_hud, "RETRY", Vector2(1142, 345), Vector2(88, 52), _retry_story, func(): pass)
	interact_hint = SharedHUD.make_nearby_prompt(gameplay_hud, preferences.text_scale)
	courage_label = Label.new()
	courage_label.name = "CourageStatus"
	courage_label.add_theme_font_size_override("font_size", 20)
	courage_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.61))
	status_stack.add_child(courage_label)
	dog_warning_label = Label.new()
	dog_warning_label.name = "CompanionWarning"
	dog_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dog_warning_label.add_theme_font_size_override("font_size", 18)
	dog_warning_label.add_theme_color_override("font_color", Color(0.95, 0.76, 0.42))
	status_stack.add_child(dog_warning_label)
	stage_label = Label.new()
	stage_label.name = "ClueAndGuideProgress"
	stage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_label.add_theme_font_size_override("font_size", 20)
	status_stack.add_child(stage_label)
	focus_feedback = Label.new()
	focus_feedback.name = "FocusHoldFeedback"
	focus_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	focus_feedback.add_theme_font_size_override("font_size", 18)
	focus_feedback.add_theme_color_override("font_color", Color("#8ff5cc"))
	status_stack.add_child(focus_feedback)
	# Flexible centered choice row: no hard-coded adjacent labels or collision
	# with the edge-mounted controls, including on large text settings.
	var choice_bar := HBoxContainer.new()
	choice_bar.name = "StoryActionsBar"
	# Choices stay in the lower center clear of hut furniture and right HUD.
	choice_bar.anchor_left = 0.265
	choice_bar.anchor_right = 0.70
	choice_bar.anchor_top = 1.0
	choice_bar.anchor_bottom = 1.0
	choice_bar.offset_top = -168
	choice_bar.offset_bottom = -101
	choice_bar.add_theme_constant_override("separation", 12)
	choice_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	gameplay_hud.add_child(choice_bar)
	for i in range(3):
		var index := i
		var action := Button.new()
		action.name = "Choice %d" % i
		action.custom_minimum_size = Vector2(170, 65)
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.clip_text = true
		action.pressed.connect(func(): _choose_story_action(index))
		_style_game_button(action, "STORY ACTION")
		choice_bar.add_child(action)
		choice_buttons.append(action)
	_refresh_choices()
	alarm_label = Label.new()
	alarm_label.name = "SpiritAlert"
	alarm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alarm_label.add_theme_color_override("font_color", Color("#e7ba7b"))
	alarm_label.add_theme_font_size_override("font_size", 18)
	status_stack.add_child(alarm_label)
	# Keep the briefing order stable even though the labels were created
	# after the gameplay controls for backwards-compatible references.
	status_stack.move_child(stage_label, 2)
	status_stack.move_child(focus_feedback, 3)
	status_stack.move_child(alarm_label, 4)
	alarm_label.hide()
	courage_label.hide()
	dog_warning_label.hide()
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
	dialogue_text.custom_minimum_size = Vector2(260, 150)
	dialogue_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_row.add_child(dialogue_text)
	var dialogue_close := Button.new()
	dialogue_close.name = "CloseDialogue"
	dialogue_close.text = "CONTINUE"
	dialogue_close.custom_minimum_size = Vector2(240, 52)
	dialogue_close.pressed.connect(_on_dialogue_continue_pressed)
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
	SharedHUD.make_options_button(gameplay_hud, _open_settings, preferences.text_scale)
	var unified := SharedOptions.create(root,preferences,"NIGHT 1 • SANTELMO",{
		"save": func(): _close_settings(); _save_story(),
		"notes": func(): _close_settings(); _open_notebook(),
		"next": _begin_night2,
		"next_label": "NEXT CHAPTER: NIGHT 2 • KAPRE",
		"menu": _request_main_menu,
		"quit": _request_quit_game,
		"back": _close_settings
	},_apply_preferences,"SettingsPanel")
	settings_panel = unified["panel"]
	pref_text_button = unified["text"]
	pref_motion_button = unified["motion"]
	pref_contrast_button = unified["contrast"]
	pref_hint_button = unified["hint"]
	pref_assist_button = unified["assist"]
	pref_audio_button = unified["audio"]
	begin_night2_button = unified["next"]
	begin_night2_button.disabled = true
	save_main_menu_button = unified["menu"]
	quit_game_button = unified["quit"]
	settings_panel.hide()
	_build_navigation_confirmations(root)
	_sync_modal_ui()


func _make_button(parent: Control, title: String, pos: Vector2, size: Vector2, down: Callable, up: Callable) -> Button:
	return SharedHUD.make_gameplay_button(parent, title, pos, size, down, up, preferences.text_scale)


func _set_focus(active: bool) -> void:
	# The focus button is a HOLD action, not a toggle. Always reflect actual
	# button-down/keyboard state, including release after completing guidance.
	focus_held = active
	if not active:
		manual_aim = Vector2.ZERO
	_update_focus_ui()


func _update_focus_ui() -> void:
	if focus_button != null:
		var active := focus_held and not _is_reading_ui()
		var state: int = 1 if active else 0
		if focus_visual_state != state:
			focus_visual_state = state
			focus_button.text = "FOCUS HELD" if active else "HOLD FOCUS"
			var style := StyleBoxFlat.new()
			style.bg_color = Color("#665123") if active else Color("#082b37")
			style.border_color = Color("#ffda70") if active else Color("#c69b55")
			style.set_border_width_all(3 if active else 2)
			style.set_corner_radius_all(8)
			focus_button.add_theme_stylebox_override("normal", style)
			focus_button.add_theme_stylebox_override("pressed", style)
			focus_button.add_theme_stylebox_override("hover_pressed", style)
			focus_button.add_theme_color_override("font_color", Color.WHITE)
		# The full-width FOCUS status stays readable without colliding with its 30px icon.
		focus_button.add_theme_font_size_override("font_size", roundi(minf(20.0, 18.0 * preferences.text_scale)) if focus_button.icon != null else roundi(23.0 * preferences.text_scale))
	if focus_feedback == null:
		return
	focus_feedback.visible = is_night and story.phase >= 1 and story.phase <= 3
	if not focus_feedback.visible:
		return
	if story.can_remember():
		focus_feedback.text = "GUIDE COMPLETE  •  TAP REMEMBER"
	elif focus_held:
		var to_landing: Vector3 = SantelmoActor.SAFE_LANDING - player.global_position
		to_landing.y = 0.0
		if story.phase == 3 and to_landing.length() >= 4.0:
			focus_feedback.text = "FOCUS HELD  •  MOVE CLOSER TO GREEN RING"
		elif story.phase == 3 and to_landing.length() > 0.3 and lamp_heading.dot(to_landing.normalized()) <= 0.65:
			focus_feedback.text = "FOCUS HELD  •  AIM TOWARD SHORE"
		else:
			focus_feedback.text = "FOCUS HELD  •  STEADY"
	else:
		focus_feedback.text = "FOCUS RELEASED  •  HOLD BUTTON"


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
		# Residents are indoors at night in postgame, never invisible talk targets.
		if _postgame_is_active() and is_night and key in ["LOLA","DADO","SABEL","MARA"]:
			continue
		var actor: Node3D = interaction_nodes[key]
		locations[key] = actor.global_position
	if postgame_barrio != null and not is_night:
		for id in ["dock_fisher","market_vendor","garden_farmer","trail_caretaker"]:
			var worker := postgame_barrio.get_node_or_null(id) as Node3D
			if worker != null and worker.visible:
				locations["POSTGAME_" + id.to_upper()] = worker.global_position
	return Nearby.closest(player.global_position, locations)


func _build_world_interaction_tags() -> void:
	# Night 1 used to set text on a shared prompt that was still invisible,
	# causing nearby Lola/Dado, notebooks and river clues to have no cue.
	# Attach small nameboards to the ORIGINAL interaction transforms; never
	# create another collision body or an additional gameplay target.
	for id in interaction_nodes:
		var at: Node3D = interaction_nodes[id]
		if at == null or not is_instance_valid(at):
			continue
		var tag := Label3D.new()
		tag.name = "NearbyIdentity_" + str(id)
		tag.text = str(id).replace("_"," ").to_upper()
		tag.font_size = 39
		tag.pixel_size = .004
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.modulate = Color("#f4ddaa")
		tag.outline_modulate = Color("#16333a")
		tag.outline_size = 8
		tag.position = Vector3(0,1.9,0)
		tag.visible = false
		at.add_child(tag)
		interaction_identity_tags[id] = tag

func _update_interact_hint() -> void:
	if interact_hint == null:
		return
	var hidden := dialogue.visible or notebook_panel.visible or prep_panel.visible or settings_panel.visible
	var closest_target := "" if hidden else _nearby_target()
	var text := ""
	if closest_target.begins_with("POSTGAME_"):
		text = "INTERACT • " + closest_target.trim_prefix("POSTGAME_").replace("_"," ")
	elif not closest_target.is_empty():
		text = Nearby.caption(closest_target)
	# This shared factory intentionally starts hidden; text alone never made
	# the Night 1 prompt visible. Use the same setter as Nights 2–7.
	SharedHUD.set_nearby_prompt_text(interact_hint,text)
	for id in interaction_identity_tags:
		var tag: Label3D = interaction_identity_tags[id]
		if tag != null and is_instance_valid(tag):
			tag.visible = str(id) == closest_target


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
	if closest.begins_with("POSTGAME_"):
		var role: String = closest.trim_prefix("POSTGAME_")
		var lines := {
			"DOCK_FISHER":"I bring the banca out again at dawn. The river still demands care, but we can earn our living.",
			"MARKET_VENDOR":"Fresh vegetables and fish are back in our market. Some families still need help rebuilding.",
			"GARDEN_FARMER":"We plant again, and the children can safely follow the village path.",
			"TRAIL_CARETAKER":"The mango trail is connected and properly marked. I check the road before sunset."
		}
		if role == "DOCK_FISHER" and _postgame_is_active() and get_node("/root/PostgameClock").village_mood == "healing":
			_show_dialogue("The river remains under watch. We mend the nets and keep the banca close until the crossing is safer.")
		else:
			_show_dialogue(str(lines.get(role,"The village is changing, a day at a time.")))
		return
	if closest == "MANGO_TRAIL":
		_enter_mango_trail()
		return
	if ["LOLA_HOME", "BLUE_NOTEBOOK", "WARM_CUP", "RIVER_PHOTO", "HUT_EXIT", "HUT_ENTRY"].has(closest):
		_interact_lola_hut(closest)
		return
	if closest == "":
		_show_dialogue("Move close to a resident or the old mooring to interact.")
		return
	if _postgame_is_active() and closest in ["LOLA","DADO","SABEL","MARA"]:
		_show_dialogue(PostgameDialogue.conversation(closest,get_node("/root/PostgameClock").village_mood))
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
	_show_dialogue(dialogue_line, closest)
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
			_show_dialogue("NARRATOR: The blue notebook rests on the writing desk beside the wall. Lola's words stay with you: write what you OBSERVE before believing a rumor.")
		"WARM_CUP":
			story.inspect_prologue("warm_cup")
			_show_dialogue("LOLA: Kaon sa. Ang tawo nga walay pamahaw dali ra mahadlok. Bantay rests at your feet.")
		"RIVER_PHOTO":
			story.inspect_prologue("river_photo")
			_show_dialogue("NARRATOR: An old framed photograph hangs along the back wall. The river looks different; Lola isn't ready to explain the missing names.")
	_save_story_silent()
	_refresh_choices()
	_update_objective()


func _show_dialogue(value: String, speaker_context: String = "NARRATOR") -> void:
	_clear_touch_input()
	_close_notebook()
	_close_prep()
	_close_settings()
	dialogue_pages = ConversationPages.parse(value, speaker_context)
	dialogue_page = 0
	SharedDialogueMotion.reveal(dialogue,preferences.reduced_motion)
	_render_dialogue_page()
	_sync_modal_ui()


func _render_dialogue_page() -> void:
	if dialogue_pages.is_empty():
		return
	var item: Dictionary = dialogue_pages[dialogue_page]
	var role: String = str(item.get("speaker", "NARRATOR"))
	dialogue_speaker.text = "%s   |   %d / %d" % [
		ConversationPages.display_name(role), dialogue_page + 1, dialogue_pages.size()
	]
	dialogue_text.text = str(item.get("text", ""))
	SharedDialogueMotion.reveal_text(dialogue_text,preferences.reduced_motion)
	dialogue_portrait.call("set_speaker", role)
	# Physical prop narration keeps the world visible instead of reusing
	# a misleading anonymous human portrait on every interaction.
	dialogue_portrait.visible = role != "NARRATOR"
	dialogue_portrait.set_process(not preferences.reduced_motion)
	_frame_cinematic_speaker(role)
	var color: Color = FolkActors.identity(role)["accent"] if role != "NARRATOR" else Color("#d7c69c")
	dialogue_speaker.add_theme_color_override("font_color", color.lightened(0.15))
	dialogue_next_button.text = "NEXT SPEAKER  >" if dialogue_page + 1 < dialogue_pages.size() else "CONTINUE / CLOSE"
	if dialogue_page > 0:
		SharedDialogueMotion.speaker_change([dialogue_speaker,dialogue_text,dialogue_portrait],preferences.reduced_motion)
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


func _on_dialogue_continue_pressed() -> void:
	# First tap reveals remaining text; second tap progresses the conversation.
	if SharedDialogueMotion.finish_text(dialogue_text):
		return
	_advance_dialogue()


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
		SharedDialogueMotion.conceal(dialogue,preferences.reduced_motion)
	dialogue_pages.clear()
	dialogue_page = 0
	_clear_touch_input()
	_sync_modal_ui()


func _sync_postgame_named_witnesses() -> void:
	# Dado returns to the actual dock, Sabel to her stall, Mara to school;
	# named witnesses keep their original identity and conversation records.
	# Changing the marker moves the visible character and interact point together.
	if not _postgame_is_active():
		return
	var shared_clock := get_node("/root/PostgameClock")
	var hour: float = shared_clock.fraction() * 24.0
	var locations := {
		"DADO": [Vector3(-6.6,.1,9.7),Vector3(-5.2,.1,6.8),Vector3(-6.0,.1,8.6)],
		"SABEL": [Vector3(9.0,.1,-5.6),Vector3(3.1,.1,-5.1),Vector3(8.5,.1,-5.1)],
		"MARA": [Vector3(-2.6,.1,-8.8),Vector3(-.5,.1,-6.7),Vector3(-2.2,.1,-8.1)],
		"LOLA": [Vector3(4.1,.1,7.0),Vector3(5.2,.1,6.1),Vector3(4.0,.1,7.0)]
	}
	for role in locations:
		var marker := interaction_nodes.get(role) as Node3D
		if marker == null:
			continue
		var phases: Array = locations[role]
		var destination: Vector3 = phases[0] if hour < 11.0 else phases[1] if hour < 14.0 else phases[2]
		if hour >= 18.5 or hour < 5.5:
			destination = phases[2]
		var easing := .32 if preferences.reduced_motion else .09
		marker.position = marker.position.lerp(destination, easing)


func _postgame_is_active() -> bool:
	var clock := get_node_or_null("/root/PostgameClock")
	return clock != null and clock.is_active()


func _toggle_night() -> void:
	if _postgame_is_active():
		return # Free-roam time is automatic and cannot be manually overridden.
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
	NightWindows.sync_barrio_3d(self,is_night,elapsed,preferences.reduced_motion)
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
	if _postgame_is_active() and objective != null:
		var village_clock := get_node("/root/PostgameClock")
		objective.text = "BARRIO LAWOM • FREE ROAM  %s\n%s • Villagers follow their daily work." % [
			village_clock.clock_label(),
			"THE VILLAGE REBUILDS" if village_clock.village_mood == "healing" else "A PEACEFUL VILLAGE"
		]
		return
	if in_lola_hut:
		if not story.prologue_flags.has("blue_notebook"):
			objective.text = "MORNING: Find the BLUE NOTEBOOK on Lola's writing desk."
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
		objective.text = "STAGE 1 • Let the Santelmo calm, then OBSERVE."
	elif story.phase == 2:
		objective.text = "STAGE 2 • Approach a reflection. INSPECT the one following the current."
	elif story.phase == 3:
		objective.text = "STAGE 3 • Stand by GREEN ring. HOLD FOCUS; aim toward SHORE." if story.guide_progress < 0.999 else "The light reached shore. Choose REMEMBER, DRIVE AWAY, or RETREAT."
	else:
		objective.text = "Night 1 completed."
	if begin_night2_button != null:
		begin_night2_button.disabled = story.outcome == ""


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
		names = ["REMEMBER" if story.can_remember() else "HOW TO GUIDE", "DRIVE AWAY" if story.kit.has("signal_bell") else "NEED BELL", "RETREAT"]
	else:
		names = ["", "", ""]
	for i in range(choice_buttons.size()):
		var action: Button = choice_buttons[i]
		action.text = names[i].replace("LOLA, ARE YOU RESTED?", "LOLA, ARE YOU\nRESTED?")
		action.visible = names[i] != ""
		# Deliberate two-line text beats accidental truncation in a narrow HUD.
		action.add_theme_font_size_override("font_size", 17 if names[i].length() > 17 else 21)
	stage_label.text = MorningAftermath.morning_label(story.outcome) if story.outcome != "" else "CLUES %d/3  •  GUIDE %d%%" % [story.clues.size(), roundi(story.guide_progress * 100.0)] if story.phase == 3 else "CLUES %d/3  •  STAGE %d" % [story.clues.size(), story.phase]
	_update_focus_ui()


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
			if story.can_remember():
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
	NightWindows.sync_barrio_3d(self,false,elapsed,preferences.reduced_motion)
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
	print("NIGHT1_QA_OPTIONS_OPEN")


func _build_navigation_confirmations(parent: Control) -> void:
	main_menu_confirmation = ConfirmationDialog.new()
	main_menu_confirmation.name = "ReturnToMenuConfirmation"
	main_menu_confirmation.title = "Return to Main Menu?"
	main_menu_confirmation.dialog_text = "Your Night 1 progress will be saved before returning."
	main_menu_confirmation.ok_button_text = "SAVE & RETURN"
	main_menu_confirmation.confirmed.connect(_save_and_return_to_menu)
	parent.add_child(main_menu_confirmation)
	quit_game_confirmation = ConfirmationDialog.new()
	quit_game_confirmation.name = "QuitConfirmation"
	quit_game_confirmation.title = "Quit Tabi-tabi?"
	quit_game_confirmation.dialog_text = "Save Night 1 progress and close the game?"
	quit_game_confirmation.ok_button_text = "SAVE & QUIT"
	quit_game_confirmation.confirmed.connect(_save_and_quit_game)
	parent.add_child(quit_game_confirmation)
	navigation_error_dialog = AcceptDialog.new()
	navigation_error_dialog.name = "NavigationSaveError"
	navigation_error_dialog.title = "Save unsuccessful"
	navigation_error_dialog.dialog_text = "Could not save your progress. The game will remain open. Try again."
	parent.add_child(navigation_error_dialog)


func _request_main_menu() -> void:
	_clear_touch_input()
	main_menu_confirmation.popup_centered(Vector2i(600, 215))


func _request_quit_game() -> void:
	_clear_touch_input()
	quit_game_confirmation.popup_centered(Vector2i(600, 215))


func _save_before_navigation() -> bool:
	# Never silently discard story state, even if the save directory is
	# unavailable. Returning and quitting use exactly the same safe pathway.
	if not SaveService.write(story, is_night):
		navigation_error_dialog.popup_centered(Vector2i(600, 200))
		return false
	preferences.save_to()
	return true


func _enter_mango_trail() -> void:
	if story.outcome == "":
		_show_dialogue("The old mango trail is visible, but the Santelmo investigation is not complete. Finish Night 1 before heading north with Bantay.")
		return
	if not _save_before_navigation():
		return
	if not ConnectedWorld.begin_travel("barrio_lawom", "old_mango", story.outcome):
		navigation_error_dialog.dialog_text = "Could not record the journey. You remain in Barrio Lawom."
		navigation_error_dialog.popup_centered(Vector2i(620, 210))
		return
	_clear_touch_input()
	print("TABI_WORLD_TRAVEL_BARRIO_TO_MANGO")
	get_node("/root/SceneTransit").call("change_to_packed", Night02Scene)


func _begin_night2() -> void:
	if story.outcome == "":
		_show_dialogue("Complete Night 1 before entering the old mango tree.")
		return
	if not _save_before_navigation():
		return
	if not ConnectedWorld.begin_travel("barrio_lawom", "old_mango", story.outcome):
		navigation_error_dialog.popup_centered(Vector2i(620, 210))
		return
	get_node("/root/SceneTransit").call("change_to_packed", Night02Scene)


func _save_and_return_to_menu() -> void:
	if not _save_before_navigation():
		return
	get_node("/root/SceneTransit").call("change_to_file", "res://scenes/title.tscn")


func _save_and_quit_game() -> void:
	if not _save_before_navigation():
		return
	get_tree().quit()


func _close_settings() -> void:
	if settings_panel != null:
		settings_panel.hide()
	_clear_touch_input()
	_sync_modal_ui()


func _refresh_options() -> void:
	SharedOptions.refresh(settings_panel,preferences)


func _apply_preferences() -> void:
	# Shared Options toggles also need to affect the live Night 1 audio.
	if living_sound != null and living_sound.has_method("set_audio_level"):
		living_sound.set_audio_level(preferences.audio_level)
	var scale: float = preferences.text_scale
	var labels: Array[Label] = [info, objective, stage_label, alarm_label, interact_hint, dog_warning_label, dialogue_text, notebook_body, prep_summary, courage_label, focus_feedback]
	var base_sizes: Array[int] = [24, 22, 20, 18, 21, 18, 25, 27, 26, 20, 18]
	for i in range(labels.size()):
		var element: Label = labels[i]
		if element == null:
			continue
		element.add_theme_font_size_override("font_size", roundi(float(base_sizes[i]) * scale))
		if not element.has_meta("original_font_color"):
			element.set_meta("original_font_color", element.get_theme_color("font_color"))
		if preferences.high_contrast:
			element.add_theme_color_override("font_color", Color.WHITE)
			element.add_theme_color_override("font_outline_color", Color.BLACK)
			element.add_theme_constant_override("outline_size", 3)
		else:
			# Restore characterful original colors, not Godot's low-contrast default.
			element.add_theme_color_override("font_color", element.get_meta("original_font_color"))
			element.remove_theme_color_override("font_outline_color")
			element.remove_theme_constant_override("outline_size")
	var headers: Array[Label] = [
		notebook_panel.get_node("NotebookLayout/NotebookHeading") as Label,
		evidence_heading,
		theory_heading,
		prep_panel.get_node("PreparationLayout/PreparationScroll/EquipmentContent/PreparationHeading") as Label,
		settings_panel.get_node("SettingsLayout/Columns/SettingsScroll/OptionsContent/OptionsHeading") as Label
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
		settings_panel.get_node("SettingsLayout/Columns/ActionStack/CloseSettings") as Button,
		save_main_menu_button,
		begin_night2_button,
		quit_game_button,
		dialogue.get_node("DialogueLayout/CloseDialogue") as Button
	]:
		_style_modal_button(footer, false, true)
	if settings_panel != null:
		_refresh_options()
	_update_focus_ui()
	call_deferred("_fit_status_card")


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
