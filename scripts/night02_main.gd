extends Node2D
## Night 2 — THE GIANT IN THE MANGO TREE.
## A complete 2.5D CanvasItem scene; uses no GLES3 spatial shader and runs
## on both emulator SwiftShader and actual Android without a fake overlay.
## All coordinates are shared by the art and real interaction zones.
const Story = preload("res://scripts/narrative/night02_state.gd")
const Save = preload("res://scripts/core/night02_save.gd")
const Night1State = preload("res://scripts/narrative/night01_state.gd")
const Night1Save = preload("res://scripts/core/save_service.gd")
const Preferences = preload("res://scripts/core/preferences.gd")
const Night02Ambience = preload("res://scripts/audio/night02_ambience.gd")
const ConnectedWorld = preload("res://scripts/core/connected_world.gd")
const SharedHUD = preload("res://scripts/ui/shared_hud.gd")
const PostgameResidents = preload("res://scripts/world/postgame_residents.gd")
const SharedDialogueMotion = preload("res://scripts/ui/shared_dialogue_motion.gd")
const AimPad = preload("res://scripts/ui/aim_pad.gd")
const SpeakerPortrait = preload("res://scripts/ui/speaker_portrait.gd")
const SharedAtmosphere = preload("res://scripts/visuals/shared_immersive_atmosphere.gd")
const DimensionalArt = preload("res://scripts/visuals/layered_25d.gd")
const NightWindows = preload("res://scripts/visuals/nighttime_windows.gd")
const Landscape = preload("res://scripts/visuals/folklore_landscape_25d.gd")
const MANGO: Texture2D = preload("res://assets/night02/old_mango_tree.svg")
const KAPRE: Texture2D = preload("res://assets/night02/kapre_perched.svg")
const BARRIER: Texture2D = preload("res://assets/night02/closed_path_barrier.svg")
const HERO: Texture2D = preload("res://assets/characters/apprentice.svg")
const BANTAY: Texture2D = preload("res://assets/characters/bantay.svg")
const LOLA: Texture2D = preload("res://assets/characters/lola.svg")
const DADO: Texture2D = preload("res://assets/characters/dado.svg")
const MARA: Texture2D = preload("res://assets/characters/mara.svg")
const HOUSE: Texture2D = preload("res://assets/world/nipa_facade.svg")
const SCHOOL: Texture2D = preload("res://assets/world/school_facade.svg")
const WOVEN_WALL: Texture2D = preload("res://assets/world/lola_sawali_wall.svg")
const NIPA_THATCH: Texture2D = preload("res://assets/world/nipa_thatch_roof.svg")
const HIBISCUS: Texture2D = preload("res://assets/world/hibiscus_bush.svg")
const LANTERN: Texture2D = preload("res://assets/world/lantern_post.svg")
const SOIL: Texture2D = preload("res://assets/world/soil_ground.svg")
const NORTH_FOREST: Texture2D = preload("res://assets/world/north_forest_tree.svg")
const FOREST_UNDERSTORY: Texture2D = preload("res://assets/world/north_grove_understory.svg")

const TREE := Vector2(245, -120)
const OBSERVATION := Vector2(-25, -330)
const PLAYER_SPEED := 255.0
const MAP_LIMIT := Rect2(-950, -690, 1900, 1420)
const TARGETS := {
	"fallen_limb": Vector2(470, 82),
	"exposed_roots": Vector2(342, 250),
	"cigar_ash": Vector2(560, -216),
	"shelter_route": Vector2(-446, 272),
	"witness_accounts": Vector2(-545, -223),
	"west_approach": Vector2(-65, 154),
	"south_approach": Vector2(160, 302),
	"shelter_turn": Vector2(-360, 247)
}
const CLUE_TITLES := {
	"fallen_limb": "Broken mango branch",
	"exposed_roots": "Flood-washed roots",
	"cigar_ash": "Cigar ash by the bark",
	"shelter_route": "Old shelter shortcut",
	"witness_accounts": "Mara and Dado's accounts"
}
const STORY_TEXT := {
	"fallen_limb": "The old mango tree dropped a heavy branch across the route. It could seriously hurt a child. This is an observable hazard, not a curse.",
	"exposed_roots": "Erosion after the Great Flood has loosened the roots. The ground is soft and unsafe; a qualified tree assessment matters.",
	"cigar_ash": "Dry cigar ash and tobacco fragments lie near the roots. They suggest someone smoked here, but cannot prove who—or when.",
	"shelter_route": "During the Great Flood, this shortcut led families toward shelter. It is now too close to the unstable tree.",
	"witness_accounts": "Mara remembers the Great Flood; Dado remembers a rescue promise that was never kept. The Kapitan wants to cut the tree immediately."
}
const KEY_ORDER := ["fallen_limb", "exposed_roots", "cigar_ash", "shelter_route", "witness_accounts"]

var story = Story.new()
var prefs = Preferences.new()
var player_pos := Vector2(-510, 140)
var dog_pos := Vector2(-580, 192)
var motion := Vector2.ZERO
var look_direction := Vector2.ZERO
var held_moves: Dictionary = {}
var observe_held := false
var camera: Camera2D
var hud: CanvasLayer
var gameplay_controls: Control
var status_panel: PanelContainer
var status_stack: VBoxContainer
var objective: Label
var subtitle: Label
var danger: Label
var progress: ProgressBar
var interaction_hint: Label
var waypoint_label: Label
var action_buttons: Dictionary = {}
var dialogue: PanelContainer
var modal_backdrop: ColorRect
var dialogue_focus_point := Vector2.ZERO
var dialogue_focus_enabled := false
var dialogue_focus_blend := 0.0
var dialogue_name: Label
var dialogue_portrait: Control
var kapre_dialogue_portrait: TextureRect
var dialogue_line: Label
var dialogue_choices: VBoxContainer
var dialogue_continue: Button
var notebook: PanelContainer
var notebook_content: Label
var options_panel: PanelContainer
var menu_confirm: ConfirmationDialog
var quit_confirm: ConfirmationDialog
var save_error: AcceptDialog
var ending_panel: PanelContainer
var ambient_sound: Node
var atmosphere_fx
var debug_dusk_preview := false
var debug_night_reveal := false # QA only, never saved
var elapsed := 0.0
var particle_phase := 0.0
var walk_phase := 0.0
var walk_weight := 0.0
var last_target := ""
var movement_enabled := true
var travel_in_progress := false

# Folklore-aware stages: investigation by day, safety at dusk,
# ember-and-smoke observation at night, then a full nocturnal reveal.
func _light_stage() -> int:
	var free_roam_clock := get_node_or_null("/root/PostgameClock")
	if free_roam_clock != null and free_roam_clock.is_active():
		return free_roam_clock.light_stage()
	if debug_night_reveal:
		return 3
	if debug_dusk_preview:
		return 1
	if story.outcome != "" or story.phase == 4:
		return 0 # Morning aftermath.
	if story.phase == 0:
		return 0
	if story.phase == 1:
		return 1
	if story.phase == 2:
		return 2
	return 3

func _kapre_revealed() -> bool:
	return (story.phase == 3 and story.outcome == "") or debug_night_reveal

func _ready() -> void:
	name = "TabiTabiNight2"
	set_meta("dimensional_art", DimensionalArt.STYLE_ID)
	prefs.load_from()
	var previous := Night1State.new()
	if not Night1Save.read(previous).is_empty():
		story.night1_outcome = previous.outcome
	Save.read(story) # Distinct save, never rewrites Night 1.
	player_pos = story.player_position
	# One world: walk into the Kapre region from the Barrio Lawom trail.
	var arrived: Dictionary = ConnectedWorld.consume_arrival("old_mango")
	if str(arrived.get("from", "")) == "barrio_lawom":
		player_pos = ConnectedWorld.ARRIVAL_MANGO
		print("TABI_WORLD_ARRIVAL_MANGO_FROM_BARRIO")
	elif str(arrived.get("from", "")) == "night03":
		player_pos = ConnectedWorld.ARRIVAL_MANGO_RIDGE
		print("TABI_WORLD_ARRIVAL_MANGO_FROM_RIDGE")
	dog_pos = player_pos + Vector2(-52, 31)
	camera = Camera2D.new()
	camera.name = "Night2IsometricCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = not prefs.reduced_motion
	camera.position_smoothing_speed = 4.0
	camera.position = player_pos
	add_child(camera)
	ambient_sound = Night02Ambience.new()
	ambient_sound.name = "KapreAtmosphere"
	add_child(ambient_sound)
	ambient_sound.set_audio_level(prefs.audio_level)
	_build_ui()
	_rebuild_objective()
	var postgame_ready := get_node_or_null("/root/PostgameClock")
	if story.outcome != "" and not (postgame_ready != null and postgame_ready.is_active()):
		_show_ending()
	elif story.phase == 0 and story.clues.is_empty():
		_show_dialogue("LOLA PASING",
			"Night 2 — Ang Higante sa Daang Mangga.\n" +
			"Lola: Ang kahoy buhi na sa mga kasaysayan sa baryo. Pero naa nay nangatumpag nga sanga. Ayaw pagpatuyang. Tan-awa una ang peligro.",
			[{"label": "SABTON NAKO, LOLA", "action": "close"}])
	print("NIGHT2_QA_SCENE_READY")
	queue_redraw()

func _process(delta: float) -> void:
	var village_clock := get_node_or_null("/root/PostgameClock")
	if village_clock != null and village_clock.is_active() and objective != null:
		var free_roam_status := "FREE ROAM • MANGO GROVE • PATHS & SCHOOL\n%s  |  %s" % [
			village_clock.clock_label(),
			"RESTORED" if village_clock.village_mood == "restored" else "REBUILDING"
		]
		if objective.text != free_roam_status:
			objective.text = free_roam_status
	elapsed += delta
	if not prefs.reduced_motion:
		particle_phase += delta
	var axis := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	axis += motion
	if dialogue.visible or notebook.visible or options_panel.visible or ending_panel.visible or menu_confirm.visible or quit_confirm.visible:
		axis = Vector2.ZERO
	if axis.length() > 1.0:
		axis = axis.normalized()
	# A stopped character must return both feet to the ground instead of
	# freezing halfway through a simulated walking stride.
	walk_weight = lerpf(walk_weight, 1.0 if axis.length() > .02 else 0.0,
		1.0 if prefs.reduced_motion else clampf(delta * 9.0,0.0,1.0))
	# Isometric movement matches the visible diagonally laid roads.
	var walk := Vector2(axis.x + axis.y * .42, axis.y * .75 - axis.x * .15).normalized()
	if axis.length() > .02:
		if not prefs.reduced_motion:
			walk_phase += delta * 8.5
		player_pos += walk * PLAYER_SPEED * delta
		player_pos.x = clampf(player_pos.x, MAP_LIMIT.position.x + 55, MAP_LIMIT.end.x - 55)
		player_pos.y = clampf(player_pos.y, MAP_LIMIT.position.y + 65, MAP_LIMIT.end.y - 65)
		# The main trunk is a real obstacle, not a walk-through tree picture.
		var tree_offset := player_pos - TREE
		if tree_offset.length() < 70:
			player_pos = TREE + tree_offset.normalized() * 70 if tree_offset.length() > .01 else TREE + Vector2(-70, 0)
		dog_pos = dog_pos.lerp(player_pos + Vector2(-48, 27), clampf(delta * 2.9, 0.0, 1.0))
	# The camera eases toward a nearby speaker without moving the player
	# or rushing across the grove to an off-screen witness.
	var desired_blend := 1.0 if dialogue_focus_enabled and dialogue.visible else 0.0
	dialogue_focus_blend = lerpf(dialogue_focus_blend, desired_blend,
		1.0 if prefs.reduced_motion else clampf(delta * 3.8,0.0,1.0))
	var focus_shift := (dialogue_focus_point-player_pos).limit_length(95.0)
	camera.position = player_pos + focus_shift * dialogue_focus_blend
	camera.offset = camera.offset.lerp(look_direction * 65.0, clampf(delta*9.0, 0.0, 1.0))
	if not travel_in_progress and player_pos.distance_to(ConnectedWorld.TRAIL_MANGO) < 53.0:
		_return_to_barrio()
	var sheltered := player_pos.distance_to(OBSERVATION) < 125
	var closed_zone: bool = player_pos.distance_to(TREE) < 115.0 and story.phase < 3
	# Reading/dialogue, options and the chapter outcome are fully paused.
	# Tension MUST NOT drain while the user reads long Filipino dialogue.
	if not dialogue.visible and not notebook.visible and not options_panel.visible and not ending_panel.visible:
		story.danger_tick(delta, closed_zone, sheltered, prefs.story_assist)
	if story.phase == 2 and observe_held and not dialogue.visible and sheltered:
		if story.observe_from_safety(delta, true, true):
			observe_held = false
			_show_dialogue("BANTAY",
				"Bantay does not bark. At night, a red cigar ember pulses high in the old mango tree. Smoke curls among the leaves and a heavy branch creaks. You cannot see the giant clearly yet. Greet the unseen resident respectfully.",
				[{"label": "TABİ-TABI PO — ASK PERMISSION", "action": "greet"}])
			_auto_save()
	if story.encounter_failed and not dialogue.visible and story.outcome == "":
		_show_dialogue("NARRATOR", "The old branches crack above. Bantay pulls you back. The safe route remains available; retry the checkpoint or withdraw.",
			[{"label": "SAFE RETRY", "action": "retry"}, {"label": "WITHDRAW", "action": "retreat"}])
	_update_hint()
	_update_waypoint()
	if progress != null:
		progress.visible = story.phase == 2
		progress.value = story.observation * 100.0
	danger.text = "COURAGE %d  •  TENSION %d%%" % [roundi(story.courage), roundi(story.alarm * 100.0)]
	if ambient_sound != null:
		ambient_sound.set_night_stage(_light_stage())
		ambient_sound.set_tension(story.alarm)
	if atmosphere_fx != null:
		var pressure := maxf(story.alarm,(100.0-story.courage)/100.0*.75)
		atmosphere_fx.configure(2,_light_stage(),pressure,prefs.reduced_motion)
	_sync_gameplay_hud()
	queue_redraw()

func _sync_gameplay_hud() -> void:
	if gameplay_controls == null:
		return
	var modal := dialogue.visible or notebook.visible or options_panel.visible or ending_panel.visible or menu_confirm.visible or quit_confirm.visible
	var was_visible := gameplay_controls.visible
	gameplay_controls.visible = not modal
	if modal and was_visible:
		SharedDialogueMotion.reset_gameplay(gameplay_controls)
	elif not modal and not was_visible:
		SharedDialogueMotion.restore_gameplay(gameplay_controls,prefs.reduced_motion)
	if modal_backdrop != null:
		modal_backdrop.visible = modal
		modal_backdrop.color = Color(.015,.035,.05,.30 if dialogue.visible else .76)
	if modal:
		# Hidden touch buttons must never keep moving the player.
		held_moves.clear()
		motion = Vector2.ZERO
		observe_held = false
		look_direction = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if dialogue.visible:
			# Keyboard/controller confirm reveals text without choosing an
			# arbitrary narrative option or skipping a safety decision.
			SharedDialogueMotion.finish_text(dialogue_line)
		else:
			_interact()
	if event.is_action_pressed("ui_cancel"):
		if dialogue.visible:
			_close_dialogue()
		elif notebook.visible:
			notebook.hide()
		elif options_panel.visible:
			options_panel.hide()
		else:
			_open_options()
	if OS.get_name() == "Android" and OS.has_feature("debug") and event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and [KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9].has(key.keycode):
			# Each screenshot uses the real interactive running scene, NEVER
			# a concept art canvas or a fake static title.
			_close_dialogue()
			notebook.hide()
			options_panel.hide()
			# Reset every prior QA lighting preview: screenshots must be distinct.
			debug_dusk_preview = false
			debug_night_reveal = false
			if key.keycode == KEY_F3:
				player_pos = Vector2(90,-270)
				print("NIGHT2_QA_MANGO_DAY_VIEW")
			elif key.keycode == KEY_F4:
				debug_night_reveal = true
				player_pos = Vector2(-595,405)
				print("NIGHT2_QA_SHELTER_NIGHT_VIEW")
			elif key.keycode == KEY_F5:
				player_pos = Vector2(-645, 455)
				print("NIGHT2_QA_RETURN_TRAIL_VIEW")
			elif key.keycode == KEY_F6:
				debug_dusk_preview = true
				player_pos = Vector2(90,-270)
				print("NIGHT2_QA_DUSK_VIEW")
			elif key.keycode == KEY_F7:
				player_pos = Vector2(-345,-315)
				print("NIGHT2_QA_WITNESS_VIEW")
			elif key.keycode == KEY_F8:
				player_pos = Vector2(-320,220)
				print("NIGHT2_QA_ROUTE_VIEW")
			else:
				debug_night_reveal = true
				player_pos = Vector2(90,-270)
				print("NIGHT2_QA_MANGO_VIEW")
			dog_pos = player_pos+Vector2(-42,25)
			camera.position = player_pos
			get_viewport().set_input_as_handled()

func _draw() -> void:
	# Scene is drawn as 2.5D world-space polygons and detailed imported SVG art.
	# It renders on GLES compatibility and SwiftShader with no spatial shaders.
	draw_rect(Rect2(-1500, -1200, 3000, 2600), Color("#22392f"))
	Landscape.parallax_ridges(self,Rect2(-1500,-1200,3000,2600),camera.position,2,_light_stage())
	for i in range(30):
		var y := -820.0 + float(i) * 56.0
		var color := Color("#304a3b").lerp(Color("#557052"), float(i) / 29.0)
		draw_rect(Rect2(-1040, y, 2200, 57), color)
	draw_texture_rect(SOIL, Rect2(-925, -685, 1830, 1390), false, Color(1.0, 1.0, 1.0, .23))
	# Match Barrio Lawom's north grove: its hand-painted fern / moss texture
	# and the same original broadleaf tree illustrations continue into Kapre's
	# region. All trees are OUTSIDE the traversable road and clue hit areas.
	for patch_center in [
		Vector2(-818, 285), Vector2(-794, -55), Vector2(-605, 607),
		Vector2(-336, 555), Vector2(585, 485), Vector2(730, -180)
	]:
		draw_texture_rect(FOREST_UNDERSTORY,
			Rect2(patch_center - Vector2(250, 205), Vector2(500, 410)), false, Color.WHITE)
	for tree_data in [
		{"foot": Vector2(-898, 178), "scale": .90},
		{"foot": Vector2(-886, 582), "scale": 1.10},
		{"foot": Vector2(-595, 692), "scale": .87},
		{"foot": Vector2(-286, 667), "scale": 1.0},
		{"foot": Vector2(725, 590), "scale": 1.05},
		{"foot": Vector2(812, -84), "scale": .95}
	]:
		var foot: Vector2 = tree_data["foot"]
		var scale_factor: float = tree_data["scale"]
		var width := 225.0 * scale_factor
		var height := 300.0 * scale_factor
		DimensionalArt.paint_grounded(self, NORTH_FOREST, foot,
			Vector2(width, height), Color.WHITE, .27)
	# Great Flood washout — a continuous diagonal corridor with shallow
	# eroded banks and dried floodwater scars.
	_polygon([Vector2(-910,330),Vector2(810,-590),Vector2(950,-535),Vector2(-760,430)], Color("#5f5a45"))
	_polygon([Vector2(-900,350),Vector2(780,-560),Vector2(860,-510),Vector2(-720,410)], Color("#8b7758"))
	_polygon([Vector2(-900,373),Vector2(785,-540),Vector2(830,-502),Vector2(-720,438)], Color("#aa8d65"))
	for i in range(15):
		var x := -830 + float(i) * 116
		var y := 347 - float(i) * 64
		draw_line(Vector2(x, y), Vector2(x + 48, y - 26), Color(.90,.74,.54,.32), 2.0)
	# Real walkable path linking the existing refuge detour to Barrio Lawom.
	_polyline([Vector2(-765, 485), Vector2(-685, 460), Vector2(-570, 520),
		Vector2(-420, 280)], Color("#5c624a"), 69)
	_polyline([Vector2(-765, 485), Vector2(-685, 460), Vector2(-570, 520),
		Vector2(-420, 280)], Color("#b6a47b"), 45)
	# Dimensional stones follow both shoulders of the refuge trail, preserving
	# the original traversable centerline and interaction radii.
	Landscape.trail_stones(self,Vector2(-765,485),Vector2(-420,280),18,69,_light_stage()>=2)
	# The former shelter line marks the re-routed safe path, turning away
	# from the giant tree, rather than a flat danger-zone sticker.
	_polyline([Vector2(-570,520),Vector2(-420,280),Vector2(-440,70),Vector2(-650,-280)], Color("#67785a"), 64)
	_polyline([Vector2(-570,520),Vector2(-420,280),Vector2(-440,70),Vector2(-650,-280)], Color("#b8a37c"), 44)
	for i in range(23):
		var x := -850.0 + float((i * 277) % 1550)
		var y := -580.0 + float((i * 193) % 1170)
		if Vector2(x,y).distance_to(TREE) > 230:
			draw_texture_rect(HIBISCUS, Rect2(x-34, y-41, 74, 62), false, Color("#a1bd94"))
	# North-east passage is the actual continuation from the mango-grove
	# washout into Tikbalang's ridge; not a disconnected chapter selector.
	_polyline([Vector2(540,-330),Vector2(670,-448),
		ConnectedWorld.TRAIL_MANGO_RIDGE],Color("#526147"),70)
	_polyline([Vector2(540,-330),Vector2(670,-448),
		ConnectedWorld.TRAIL_MANGO_RIDGE],Color("#b6a17a"),46)
	var ridge_sign: Vector2 = ConnectedWorld.TRAIL_MANGO_RIDGE
	draw_line(ridge_sign+Vector2(-10,-73),ridge_sign+Vector2(-10,43),Color("#66492e"),10,true)
	draw_line(ridge_sign+Vector2(-50,-62),ridge_sign+Vector2(79,-55),Color("#c3a171"),17,true)
	draw_line(ridge_sign+Vector2(-50,-62),ridge_sign+Vector2(79,-55),Color("#e3c88e"),3,true)
	# The boundary crossing is part of the illustrated world, not a menu.
	var trail_marker: Vector2 = ConnectedWorld.TRAIL_MANGO
	draw_line(trail_marker+Vector2(-45,-24),trail_marker+Vector2(-45,46),Color("#6f5037"),8.0,true)
	draw_line(trail_marker+Vector2(48,-24),trail_marker+Vector2(48,46),Color("#6f5037"),8.0,true)
	_polygon([trail_marker+Vector2(-67,-54),trail_marker+Vector2(69,-54),
		trail_marker+Vector2(69,-15),trail_marker+Vector2(-67,-15)],Color("#bf9f6d"))
	draw_line(trail_marker+Vector2(-67,-54),trail_marker+Vector2(69,-54),Color("#e5c98e"),4)
	# A recognizable village refuge, and Mara's school with its own facade.
	_building_at(Vector2(-600, -445), SCHOOL, "MARA • SCHOOL")
	_building_at(Vector2(-610, 410), HOUSE, "SAFE SHELTER")
	# Woven screening at the observation post.
	_polygon([OBSERVATION+Vector2(-105,24), OBSERVATION+Vector2(100,24),
		OBSERVATION+Vector2(105,73), OBSERVATION+Vector2(-105,73)], Color("#685943"))
	for i in range(9):
		var wx := OBSERVATION.x-91 + float(i)*23
		draw_line(Vector2(wx,OBSERVATION.y+23),Vector2(wx,OBSERVATION.y+69),Color("#c5ab74"),3)
	DimensionalArt.lantern(self, LANTERN, OBSERVATION + Vector2(-108,13),
		Vector2(74,152), _light_stage() >= 1)
	# Unstable ground ring illustrates actual hazard zone before approaching.
	# Ground cracks telegraph unstable roots without an arcade-sized ring.
	for i in range(7):
		var crack_at := TREE + Vector2(-115.0 + float(i)*41.0,86.0 + sin(float(i)*2.7)*15.0)
		draw_line(crack_at,crack_at+Vector2(19,-8),Color("#503a2d",.64),2.4,true)
		draw_line(crack_at+Vector2(19,-8),crack_at+Vector2(32,1),Color("#6f4931",.53),1.7,true)
	# Separated foreground boulders anchor the mango roots to the earth.
	for stone in [Vector2(7,-33),Vector2(455,-35),Vector2(414,107),Vector2(40,130)]:
		Landscape.rock(self,stone,46.0,_light_stage()<2)
	# The ancestral mango stays visible by day; its resident does NOT.
	var canopy_sway := sin(particle_phase * .65) * (4.0 if not prefs.reduced_motion else 0.0)
	DimensionalArt.paint_grounded(self, MANGO, TREE + Vector2(canopy_sway,40),
		Vector2(700,600), Color.WHITE, .47)
	# Branch geometry anchors a perched giant ABOVE the villagers and ground.
	var perch_root := TREE + Vector2(14,-177)
	var perch_tip := TREE + Vector2(252,-190)
	draw_line(perch_root,perch_tip,Color("#402f26"),31.0,true)
	draw_line(perch_root+Vector2(0,-4),perch_tip+Vector2(0,-4),Color("#70513a"),8.0,true)
	draw_line(TREE+Vector2(156,-190),TREE+Vector2(192,-240),Color("#503b2d"),10.0,true)
	# Clue props each have a different silhouette; no generic quest circles.
	_draw_evidence()
	for id in Story.BARRIER_POSITIONS:
		var point: Vector2 = TARGETS[id]
		if story.barriers.has(id):
			draw_texture_rect(BARRIER, Rect2(point-Vector2(38,78), Vector2(76,100)), false)
		else:
			# Unsecured access shows a believable roadside bamboo hazard
			# stake with cloth warning, NOT a generic flat circle target.
			draw_line(point + Vector2(0,-38),point + Vector2(0,35),Color("#68472f"),6,true)
			draw_line(point + Vector2(-4,-33),point + Vector2(18,-34),Color("#c79f64"),3,true)
			draw_colored_polygon(PackedVector2Array([
				point + Vector2(3,-34),point+Vector2(48,-20),point+Vector2(3,-5)]),Color("#b16a47"))
			draw_line(point+Vector2(11,-26),point+Vector2(11,-13),Color("#f3d9a7"),2.4)
	# Time-of-day follows story stage, never an arbitrary realtime clock.
	# Keep paths and clue shapes readable for accessibility during darkness.
	var light_stage := _light_stage()
	if light_stage == 1:
		draw_rect(Rect2(-1500,-1200,3000,2600),Color(.27,.10,.04,.19))
	elif light_stage >= 2:
		draw_rect(Rect2(-1500,-1200,3000,2600),Color(.015,.032,.11,.48))
		draw_circle(OBSERVATION + Vector2(-92,-92),130,Color(1.0,.65,.23,.065))
		for i in range(19):
			var firefly_angle := float(i) * 2.39996
			var firefly_r := 85.0 + float(i % 7) * 24.0
			var firefly := TREE + Vector2(cos(firefly_angle)*firefly_r,
				sin(firefly_angle)*firefly_r*.70-120.0)
			if not prefs.reduced_motion:
				firefly += Vector2(sin(particle_phase*.64+float(i))*11.0,
					cos(particle_phase*.73+float(i)*1.6)*8.0)
			draw_circle(firefly,2.3,Color("#ffe6a1"))
			draw_circle(firefly,8.0,Color(1.0,.79,.38,.075))
		_draw_kapre_smoke()
	# The school is nearly shut while a home/refuge still has amber lanterns
	# behind curtains. Window positions follow the actual isometric side walls.
	if light_stage >= 2:
		for i in range(2):
			var house: Vector2 = Vector2(-600,-445) if i == 0 else Vector2(-610,410)
			var side_left := (house+Vector2(76,37)).lerp(house+Vector2(158,-21),.30)
			var side_right := (house+Vector2(76,37)).lerp(house+Vector2(158,-21),.72)
			var pane_center := side_left.lerp(side_right,.5)+Vector2(0,-86)
			NightWindows.paint_window(self,pane_center,Vector2(42,37),
				2 if i == 0 else 0,true,particle_phase,prefs.reduced_motion)
	# Low clearing fog moves behind the people and the guardian; Reduced
	# Motion freezes it without affecting its visibility.
	if _light_stage() >= 1:
		Landscape.mist(self,TREE+Vector2(-65,82),560.0,particle_phase,
			not prefs.reduced_motion,_light_stage()>=2)
	# Actors and guardian are drawn AFTER the environmental darkness grade,
	# so faces, limbs and quest silhouettes stay visible on real Android.
	if _kapre_revealed():
		DimensionalArt.paint_grounded(self, KAPRE, TREE + Vector2(147.5,-130),
			Vector2(215,330), Color("#d3c5b6"), .18)
		# Occluding branch remains in front of the knee, not behind the giant.
		draw_line(TREE+Vector2(78,-185),TREE+Vector2(243,-195),Color("#33261f",.82),11,true)
		draw_line(TREE+Vector2(87,-191),TREE+Vector2(241,-201),Color("#98714c",.44),3.5,true)
	var actors: Array[Dictionary] = []
	if NightWindows.outdoor_actor_visible(2,light_stage,"DADO"):
		actors.append({"at": Vector2(-661,-263), "texture": DADO, "width": 80.0, "height": 128.0})
	if NightWindows.outdoor_actor_visible(2,light_stage,"MARA"):
		actors.append({"at": Vector2(-461,-261), "texture": MARA, "width": 80.0, "height": 128.0})
	actors.append({"at": dog_pos+Vector2(0,29), "texture": BANTAY, "width": 90.0, "height": 96.0})
	actors.append({"at": player_pos+Vector2(0,8), "texture": HERO, "width": 92.0, "height": 124.0})
	actors.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		return (a["at"] as Vector2).y < (b["at"] as Vector2).y)
	for actor in actors:
		var foot: Vector2 = actor["at"]
		var width: float = actor["width"]
		var height: float = actor["height"]
		var is_player: bool = actor["texture"] == HERO
		var is_dog: bool = actor["texture"] == BANTAY
		if is_player or is_dog:
			DimensionalArt.paint_animated_actor(self,actor["texture"],foot,
				Vector2(width,height),walk_phase,walk_weight,prefs.reduced_motion,
				Color.WHITE,.43,is_dog)
		else:
			DimensionalArt.paint_grounded(self,actor["texture"],foot,
				Vector2(width,height),Color.WHITE,.43)
	PostgameResidents.paint(self,"old_mango",particle_phase,prefs.reduced_motion,player_pos)
	_draw_world_labels()
	if story.outcome == "resolve":
		draw_arc(TREE, 157, 0, TAU, 80, Color("#bcd79d",.58), 3.0)
	elif story.outcome == "partial":
		draw_arc(TREE, 157, 0, TAU, 80, Color("#e2b879",.58), 3.0)

func _draw_kapre_smoke() -> void:
	# First nighttime manifestation: a cigar ember and drifting smoke.
	# The body remains hidden until the player's respectful greeting.
	var cigar_tip := TREE + Vector2(235,-340)
	var pulse := .86 + .14 * sin(particle_phase * 4.2)
	draw_circle(cigar_tip,26.0 * pulse,Color(1.0,.35,.08,.065))
	draw_circle(cigar_tip,11.0 * pulse,Color(1.0,.45,.13,.16))
	draw_circle(cigar_tip,4.5,Color("#ffbd57"))
	draw_circle(cigar_tip,2.4,Color("#fff0bc"))
	for i in range(13):
		var drift := fposmod(particle_phase*.14 + float(i)/13.0,1.0)
		var bend := sin(drift * TAU * 1.3 + float(i) * .65)
		var center := cigar_tip + Vector2(bend * 28.0 + drift*20.0,-drift*177.0)
		var opacity := (1.0-drift) * (.15 if _kapre_revealed() else .20)
		draw_circle(center,10.0 + drift*19.0,Color(.76,.81,.77,opacity*.38))
		draw_arc(center,11.0+drift*19.0,PI*.18,PI*1.47,
			12,Color(.78,.84,.79,opacity),2.4,true)

func _polyline(points: Array[Vector2], color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), color, width, true)

func _polygon(points: Array[Vector2], color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _textured_quad(corners: Array[Vector2], texture: Texture2D, tint: Color) -> void:
	# UVs are tied to each isometric wall or roof face, never to a screen-aligned
	# sticker. This keeps woven bamboo and thatch attached to real geometry.
	var tex_size := texture.get_size()
	var uv := PackedVector2Array([
		Vector2(0, tex_size.y), Vector2(tex_size.x,tex_size.y),
		Vector2(tex_size.x,0), Vector2(0,0)])
	draw_polygon(PackedVector2Array(corners),
		PackedColorArray([tint, tint, tint, tint]),uv,texture)

func _building_at(at: Vector2, texture: Texture2D, name_text: String) -> void:
	# Hand-built 2.5D isometric architecture, NOT a stretched 2D facade.
	# A footprint, four real corners, two roof planes and raised porch share
	# one projected origin, so the house sits ON the ground rather than hovering.
	var school := texture == SCHOOL
	var wall_front := Color("#c1ac85") if school else Color("#bd9b70")
	var wall_side := Color("#8b7963") if school else Color("#826b52")
	var roof_lit := Color("#65817d") if school else Color("#ac8056")
	var roof_shadow := Color("#405a5b") if school else Color("#725239")
	var front_l := at + Vector2(-106, -5)
	var front_r := at + Vector2(76, 37)
	var back_r := at + Vector2(158, -21)
	var back_l := at + Vector2(-24, -63)
	var rise := Vector2(0, -132)
	var roof_front_l := front_l + rise + Vector2(-12, -8)
	var roof_front_r := front_r + rise + Vector2(12, -8)
	var roof_back_l := back_l + rise + Vector2(-12, -8)
	var roof_back_r := back_r + rise + Vector2(12, -8)
	var ridge_front := at + Vector2(-15, -232)
	var ridge_back := at + Vector2(67, -290)
	# Shadow/raised floor: projecting the same footprint grounds the stilts.
	_polygon([front_l+Vector2(-20,13),front_r+Vector2(15,14),
		back_r+Vector2(17,15),back_l+Vector2(-15,13)],Color(0.08,0.12,0.11,.37))
	_polygon([front_l,front_r,back_r,back_l], Color("#624d39"))
	for foot in [front_l, front_r, back_r]:
		draw_line(foot + Vector2(0, -11), foot + Vector2(0, 29), Color("#6f5239"), 12, true)
		draw_line(foot + Vector2(0, -11), foot + Vector2(0, 29), Color("#ae8b61"), 3, true)
	# Rear-facing side darkens naturally; front wall remains visually distinct.
	_textured_quad([front_r,back_r,back_r+rise,front_r+rise], WOVEN_WALL,wall_side.lightened(.35))
	_textured_quad([front_l,front_r,front_r+rise,front_l+rise],WOVEN_WALL,wall_front.lightened(.25))
	# Individual bamboo battens follow the front wall's perspective exactly.
	for i in range(11):
		var p := front_l.lerp(front_r, float(i)/10.0)
		draw_line(p+Vector2(0,-1), p+rise+Vector2(0,4),
			Color("#916e4d") if i % 2 == 0 else Color("#d7bd90"), 2.6, true)
	for j in range(4):
		var h := float(j+1)/5.0
		draw_line(front_l.lerp(front_l+rise,h),front_r.lerp(front_r+rise,h),
			Color("#937656"), 2.0, true)
	# The entrance is part of the wall, not painted across the whole building.
	var door_l := front_l.lerp(front_r,.32)
	var door_r := front_l.lerp(front_r,.58)
	_polygon([door_l,door_r,door_r+Vector2(0,-90),door_l+Vector2(0,-90)],
		Color("#46372e"))
	draw_line(door_l+Vector2(0,-92),door_r+Vector2(0,-92),Color("#e2c392"),6)
	draw_circle(door_r.lerp(door_l,.18)+Vector2(0,-43),3,Color("#e7c178"))
	# Side window bends with the right wall's own perspective.
	var window_l := front_r.lerp(back_r,.30)+Vector2(0,-69)
	var window_r := front_r.lerp(back_r,.72)+Vector2(0,-69)
	_polygon([window_l,window_r,window_r+Vector2(0,-35),window_l+Vector2(0,-35)],
		Color("#203d40"))
	draw_line(window_l.lerp(window_r,.5),window_l.lerp(window_r,.5)+Vector2(0,-35),
		Color("#e2c493"),3)
	draw_line(window_l+Vector2(0,-17),window_r+Vector2(0,-17),Color("#d4ae78"),3)
	# A gable and TWO separate roof surfaces with visible eave thickness.
	_polygon([roof_front_l,ridge_front,roof_front_r],roof_shadow)
	_textured_quad([roof_front_l,ridge_front,ridge_back,roof_back_l],NIPA_THATCH,roof_lit.lightened(.35))
	_textured_quad([ridge_front,roof_front_r,roof_back_r,ridge_back],NIPA_THATCH,roof_shadow.lightened(.25))
	draw_line(ridge_front,ridge_back,Color("#ead3a2"),5,true)
	for i in range(1,7):
		var t := float(i)/7.0
		draw_line(roof_front_l.lerp(ridge_front,t),roof_back_l.lerp(ridge_back,t),
			Color("#e0bb82") if i % 2 == 0 else Color("#85613c"),2,true)
		draw_line(ridge_front.lerp(roof_front_r,t),ridge_back.lerp(roof_back_r,t),
			Color("#9d7e59"),2,true)
	draw_line(roof_front_l,roof_front_r,Color("#59452f"),6,true)
	draw_line(roof_front_r,roof_back_r,Color("#463b33"),5,true)
	# Raised porch and short stairs connect the door visually to the terrain.
	var porch_l := front_l + Vector2(-4,5)
	var porch_r := front_r + Vector2(2,5)
	_polygon([porch_l,porch_r,porch_r+Vector2(-35,27),porch_l+Vector2(-35,27)],
		Color("#9b7851"))
	for i in range(5):
		var line_start := porch_l.lerp(porch_r,float(i+1)/6.0)
		draw_line(line_start,line_start+Vector2(-35,27),Color("#624934"),2)
	for i in range(3):
		var step_at := door_l.lerp(door_r,.5)+Vector2(-23-float(i)*5,13+float(i)*13)
		draw_line(step_at,step_at+Vector2(76+float(i)*7,13),
			Color("#6f5035"),8,true)
	if school:
		# School-specific timber plaque fixed to the side wall.
		var sign_at := front_r.lerp(back_r,.55)+Vector2(0,-104)
		draw_line(sign_at+Vector2(-21,0),sign_at+Vector2(24,10),Color("#ead29b"),9,true)
	else:
		# Home-specific hanging lamp anchored to the eave support.
		draw_line(roof_front_l+Vector2(17,7),roof_front_l+Vector2(17,36),Color("#7a5638"),2)
		draw_circle(roof_front_l+Vector2(17,39),7,Color("#e2b968",.85))
	# Small world text remains BELOW the footprint, clear of player and roofs.
	var font := ThemeDB.fallback_font
	draw_string(font,at+Vector2(-80,77),name_text,
		HORIZONTAL_ALIGNMENT_LEFT,185,18,Color("#f0dbaa"))

func _draw_evidence() -> void:
	for id in KEY_ORDER:
		var pos: Vector2 = TARGETS[id]
		var done: bool = story.clues.has(id)
		if id == "fallen_limb":
			draw_line(pos+Vector2(-85,26),pos+Vector2(60,-20),Color("#59422e"),18,true)
			for i in range(7):
				draw_line(pos+Vector2(-52+i*17,11-i*5),
					pos+Vector2(-70+i*17,-19-i*6),Color("#7a5437"),4,true)
		elif id == "exposed_roots":
			for i in range(7):
				draw_line(pos+Vector2(-46+i*15,-18),pos+Vector2(-68+i*19,56),
					Color("#5f4730"),6.0,true)
			draw_arc(pos,57,0,PI,40,Color("#b2a48a"),4)
		elif id == "cigar_ash":
			for i in range(13):
				var dx := sin(float(i)*2.39)*42
				var dy := cos(float(i)*2.39)*33
				draw_circle(pos+Vector2(dx,dy),3.1 if i%3 else 5.5,Color("#b6a99e"))
			draw_circle(pos+Vector2(14,-8),6,Color("#e7a76b",.65))
		elif id == "shelter_route":
			draw_colored_polygon(PackedVector2Array([pos+Vector2(-29,35),pos+Vector2(29,35),
				pos+Vector2(29,-43),pos+Vector2(0,-57),pos+Vector2(-29,-43)]),Color("#ac8a60"))
			draw_line(pos+Vector2(-15,-4),pos+Vector2(15,-4),Color("#e6d9aa"),5)
		elif id == "witness_accounts":
			draw_colored_polygon(PackedVector2Array([pos+Vector2(-38,-45),pos+Vector2(33,-45),
				pos+Vector2(38,33),pos+Vector2(-33,33)]),Color("#c9b58a"))
			for i in range(5):
				draw_line(pos+Vector2(-23,-28+i*12),pos+Vector2(21,-28+i*12),Color("#6f685e"),2)
		if not done and story.phase == 0:
			draw_arc(pos,39+sin(particle_phase*2)*2,0,TAU,36,Color("#cba96d",.43),1.8)
		elif done:
			draw_circle(pos+Vector2(45,-48),12,Color("#7ba787"))
			draw_line(pos+Vector2(39,-48),pos+Vector2(43,-43),Color.WHITE,3)
			draw_line(pos+Vector2(43,-43),pos+Vector2(52,-57),Color.WHITE,3)

func _draw_world_labels() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font,TREE+Vector2(-173,105),"OLD MANGO • KEEP DISTANCE",HORIZONTAL_ALIGNMENT_LEFT,420,21,Color("#e6d8b2"))
	var trail: Vector2 = ConnectedWorld.TRAIL_MANGO
	draw_string(font,trail+Vector2(-145,76),"← BARRIO LAWOM • TRAIL",
		HORIZONTAL_ALIGNMENT_LEFT,350,24,Color("#ffe0a4"))
	draw_string(font,ConnectedWorld.TRAIL_MANGO_RIDGE+Vector2(-235,98),
		"NORTH RIDGE • TIKBALANG  →",HORIZONTAL_ALIGNMENT_LEFT,410,19,Color("#f0d6a2"))
	if story.phase == 2:
		draw_string(font,OBSERVATION+Vector2(-138,100),"SAFE LOOKOUT • HOLD OBSERVE",HORIZONTAL_ALIGNMENT_LEFT,360,19,Color("#ffe1a2"))
	if story.phase >= 1 and story.phase <= 2:
		draw_string(font,Vector2(-440,378),"SHELTER DETOUR",HORIZONTAL_ALIGNMENT_LEFT,240,20,Color("#e5d2a4"))


func _fit_status_card() -> void:
	if status_panel == null or status_stack == null or not is_inside_tree():
		return
	var needed: float = status_stack.get_combined_minimum_size().y + 30.0
	var available: float = get_viewport().get_visible_rect().size.y * .67
	status_panel.offset_bottom = clampf(needed,145.0,available)


func _build_ui() -> void:
	var fx_layer := CanvasLayer.new()
	fx_layer.name = "SharedNightAtmosphere"
	fx_layer.layer = 5 # below the chapter HUD and dialogue at layer 6
	add_child(fx_layer)
	atmosphere_fx = SharedAtmosphere.new()
	fx_layer.add_child(atmosphere_fx)
	hud = CanvasLayer.new()
	hud.name = "Night2HUD"
	hud.layer = 6
	add_child(hud)
	var layout := Control.new()
	layout.name = "Night2Screen"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(layout)
	gameplay_controls = Control.new()
	gameplay_controls.name = "GameplayControls"
	gameplay_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gameplay_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(gameplay_controls)
	# Night 1 factory: identical card width, padding, typography and order.
	var status_parts := SharedHUD.create_status_card(gameplay_controls, "TABI-TABI  •  NIGHT 2 / KAPRE", prefs.text_scale)
	status_panel = status_parts["panel"]
	status_stack = status_parts["stack"]
	objective = status_parts["objective"]
	status_stack.minimum_size_changed.connect(func(): call_deferred("_fit_status_card"))
	subtitle = Label.new()
	subtitle.name = "ClueAndGuideProgress"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", roundi(20.0*prefs.text_scale))
	subtitle.add_theme_color_override("font_color", Color("#e8d3a4"))
	status_stack.add_child(subtitle)
	danger = Label.new()
	danger.name = "CourageStatus"
	danger.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	danger.add_theme_font_size_override("font_size", roundi(20.0*prefs.text_scale))
	danger.add_theme_color_override("font_color", Color("#f4c99b"))
	status_stack.add_child(danger)
	waypoint_label = Label.new()
	waypoint_label.name = "NextLocationCompass"
	waypoint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	waypoint_label.add_theme_font_size_override("font_size", roundi(18.0*prefs.text_scale))
	waypoint_label.add_theme_color_override("font_color", Color("#f1d6a4"))
	status_stack.add_child(waypoint_label)
	progress = ProgressBar.new()
	progress.name = "ObserveProgress"
	progress.anchor_left = .29
	progress.anchor_right = .67
	progress.anchor_top = .88
	progress.anchor_bottom = .935
	progress.max_value = 100
	progress.show_percentage = false
	progress.visible = false
	gameplay_controls.add_child(progress)
	interaction_hint = SharedHUD.make_nearby_prompt(gameplay_controls, prefs.text_scale)
	# Exactly the same Night 1 physical layout, icons, input affordances,
	# and 1280x720 responsive anchors. Only the two chapter actions differ.
	for item in [
		["left","◀",Vector2(20,575)], ["right","▶",Vector2(170,575)],
		["up","▲",Vector2(95,505)], ["down","▼",Vector2(95,645)]
	]:
		var dir_name: String = item[0]
		var move := SharedHUD.make_gameplay_button(gameplay_controls,item[1],item[2],
			Vector2(70,65),func(): _press_move(dir_name,true),func(): _press_move(dir_name,false),prefs.text_scale)
		move.name = "Move_" + dir_name
		move.mouse_exited.connect(func(): _press_move(dir_name,false))
	var look := AimPad.new()
	look.name = "Night2LookPad"
	look.prompt_text = "LOOK AROUND"
	look.anchor_left = 1.0
	look.anchor_right = 1.0
	look.anchor_top = 1.0
	look.anchor_bottom = 1.0
	look.offset_left = -435.0
	look.offset_right = -260.0
	look.offset_top = -205.0
	look.offset_bottom = -40.0
	look.aim_changed.connect(func(direction: Vector2): look_direction = direction)
	look.aim_released.connect(func(): look_direction = Vector2.ZERO)
	gameplay_controls.add_child(look)
	var observe := _gameplay_button("HOLD OBSERVE", Vector2(1050,490),Vector2(180,60),func(): pass)
	observe.button_down.connect(func(): observe_held = true)
	observe.button_up.connect(func(): observe_held = false)
	observe.mouse_exited.connect(func(): observe_held = false)
	_gameplay_button("INTERACT",Vector2(1050,565),Vector2(180,60),_interact)
	_gameplay_button("SAFE RETREAT",Vector2(1050,640),Vector2(180,56),_request_retreat)
	_gameplay_button("FIELD NOTES",Vector2(1050,415),Vector2(180,56),_open_notebook)
	_gameplay_button("PREPARE",Vector2(1050,276),Vector2(180,56),_open_safety_preparation)
	_gameplay_button("SAVE",Vector2(1050,345),Vector2(85,52),_save_and_notify)
	_gameplay_button("RETRY",Vector2(1142,345),Vector2(88,52),_retry_night2)
	action_buttons["OPTIONS"] = SharedHUD.make_options_button(gameplay_controls,_open_options,prefs.text_scale)
	# Exact Night 1 modal backdrop: atmospheric world remains visible during
	# dialogue, and full note/options screens stay comfortably legible.
	modal_backdrop = ColorRect.new()
	modal_backdrop.name = "ModalDimmer"
	modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_backdrop.color = Color(.015,.035,.05,.30)
	modal_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(modal_backdrop)
	modal_backdrop.hide()

	dialogue = PanelContainer.new()
	dialogue.name = "Night2Dialogue"
	dialogue.anchor_left = .08
	dialogue.anchor_right = .92
	dialogue.anchor_top = .44
	dialogue.anchor_bottom = .955
	SharedHUD.style_modal_panel(dialogue)
	layout.add_child(dialogue)
	var dialogue_box := VBoxContainer.new()
	dialogue_box.name = "Conversation"
	dialogue_box.add_theme_constant_override("separation", 8)
	dialogue.add_child(dialogue_box)
	dialogue_name = Label.new()
	dialogue_name.add_theme_font_size_override("font_size", 25)
	dialogue_name.add_theme_color_override("font_color", Color("#f1cf92"))
	dialogue_box.add_child(dialogue_name)
	var words := ScrollContainer.new()
	words.name = "DialogueScroll"
	words.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	words.follow_focus = true
	words.size_flags_vertical = Control.SIZE_EXPAND_FILL
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_box.add_child(words)
	var portrait_row := HBoxContainer.new()
	portrait_row.name = "PortraitAndText"
	portrait_row.add_theme_constant_override("separation",22)
	portrait_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(portrait_row)
	dialogue_portrait = SpeakerPortrait.new()
	dialogue_portrait.name = "SpeakerBustPortrait"
	dialogue_portrait.custom_minimum_size = Vector2(225,215)
	portrait_row.add_child(dialogue_portrait)
	kapre_dialogue_portrait = TextureRect.new()
	kapre_dialogue_portrait.name = "KapreSpeakerBust"
	var bust_atlas := AtlasTexture.new()
	bust_atlas.atlas = KAPRE
	bust_atlas.region = Rect2(160,65,280,310)
	kapre_dialogue_portrait.texture = bust_atlas
	kapre_dialogue_portrait.custom_minimum_size = Vector2(225,215)
	kapre_dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kapre_dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_row.add_child(kapre_dialogue_portrait)
	kapre_dialogue_portrait.hide()
	dialogue_line = Label.new()
	dialogue_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_line.custom_minimum_size = Vector2(260,150)
	dialogue_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_line.add_theme_font_size_override("font_size",roundi(25.0*prefs.text_scale))
	portrait_row.add_child(dialogue_line)
	dialogue_choices = VBoxContainer.new()
	dialogue_choices.name = "ChoiceButtons"
	dialogue_choices.add_theme_constant_override("separation", 4)
	dialogue_box.add_child(dialogue_choices)
	dialogue.hide()

	notebook = PanelContainer.new()
	notebook.name = "Night2FieldNotes"
	notebook.anchor_left = .10
	notebook.anchor_right = .90
	notebook.anchor_top = .055
	notebook.anchor_bottom = .945
	SharedHUD.style_modal_panel(notebook)
	layout.add_child(notebook)
	var notebook_stack := VBoxContainer.new()
	notebook.add_child(notebook_stack)
	var notebook_title := Label.new()
	notebook_title.text = "FIELD NOTEBOOK  |  NIGHT 2"
	notebook_title.add_theme_font_size_override("font_size", 25)
	notebook_title.add_theme_color_override("font_color", Color("#f3d7a0"))
	notebook_stack.add_child(notebook_title)
	var scroller := ScrollContainer.new()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notebook_stack.add_child(scroller)
	notebook_content = Label.new()
	notebook_content.name = "NotebookEvidenceBody"
	notebook_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notebook_content.custom_minimum_size = Vector2(580,450)
	notebook_content.add_theme_font_size_override("font_size", roundi(27.0*prefs.text_scale))
	scroller.add_child(notebook_content)
	_action(notebook_stack, "CLOSE NOTEBOOK", func(): notebook.hide())
	notebook.hide()

	options_panel = PanelContainer.new()
	options_panel.name = "Night2Options"
	options_panel.anchor_left = .10
	options_panel.anchor_right = .90
	options_panel.anchor_top = .055
	options_panel.anchor_bottom = .945
	SharedHUD.style_modal_panel(options_panel)
	layout.add_child(options_panel)
	var opts := VBoxContainer.new()
	options_panel.add_child(opts)
	var oh := Label.new()
	oh.text = "NIGHT 2 • PAUSE AND OPTIONS"
	oh.add_theme_font_size_override("font_size", 28)
	opts.add_child(oh)
	_action(opts, "SAVE PROGRESS", func(): _save_and_notify())
	_action(opts, "SAVE & MAIN MENU", func(): menu_confirm.popup_centered(Vector2i(610, 210)))
	_action(opts, "SAVE & QUIT GAME", func(): quit_confirm.popup_centered(Vector2i(610, 210)))
	_action(opts, "BACK TO GAME", func(): options_panel.hide())
	options_panel.hide()

	ending_panel = PanelContainer.new()
	ending_panel.name = "Night2Aftermath"
	ending_panel.anchor_left = .205
	ending_panel.anchor_right = .79
	ending_panel.anchor_top = .15
	ending_panel.anchor_bottom = .86
	SharedHUD.style_modal_panel(ending_panel)
	layout.add_child(ending_panel)
	ending_panel.hide()

	menu_confirm = ConfirmationDialog.new()
	menu_confirm.title = "Save and return to main menu?"
	menu_confirm.dialog_text = "Your separate Night 2 story will be saved without replacing Night 1."
	menu_confirm.ok_button_text = "SAVE & RETURN"
	menu_confirm.confirmed.connect(_save_and_main_menu)
	add_child(menu_confirm)
	quit_confirm = ConfirmationDialog.new()
	quit_confirm.title = "Save and exit Tabi-tabi?"
	quit_confirm.dialog_text = "Keep your Night 2 checkpoint and close the app?"
	quit_confirm.ok_button_text = "SAVE & EXIT"
	quit_confirm.confirmed.connect(_save_and_quit)
	add_child(quit_confirm)
	save_error = AcceptDialog.new()
	save_error.title = "Night 2 save failed"
	save_error.dialog_text = "Progress could not be written. You will remain in the game."
	add_child(save_error)

func _button_style(button: Button, font_size: int = 19) -> void:
	# Dialogue and in-world notebook choices use the exact Night 1 modal style.
	SharedHUD.style_modal_button(button,false,false,prefs.text_scale)

func _gameplay_button(label: String, at: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var b := SharedHUD.make_gameplay_button(gameplay_controls,label,at,dimensions,
		func(): pass,func(): pass,prefs.text_scale)
	b.name = label.replace(" ","").replace("/","")
	b.pressed.connect(callback)
	action_buttons[label] = b
	return b

func _open_safety_preparation() -> void:
	if dialogue.visible or ending_panel.visible or notebook.visible or options_panel.visible:
		return
	var route_done: int = story.barriers.size()
	_show_dialogue("SAFETY PREPARATION",
		"Check the fallen limbs, roots and approach routes before confronting the mango-tree resident.\n" +
		"Evidence: %d/5   •   Closed routes: %d/3\n" % [story.clues.size(),route_done] +
		"Only observe at night from the sheltered lookout. Bantay stays close.",
		[{"label":"UNDERSTOOD","action":"close"}])

func _retry_night2() -> void:
	if dialogue.visible or notebook.visible or options_panel.visible:
		return
	if story.outcome != "":
		_show_ending()
		return
	if not story.safe_retry():
		return
	player_pos = OBSERVATION + Vector2(-95,40) if story.phase >= 2 else Vector2(-510,140)
	dog_pos = player_pos + Vector2(-52,31)
	observe_held = false
	look_direction = Vector2.ZERO
	motion = Vector2.ZERO
	held_moves.clear()
	_auto_save()
	_show_dialogue("SAFE RETRY","Back at a safe position. Recorded clues remain available.",
		[{"label":"CONTINUE","action":"close"}])
	_rebuild_objective()

func _action(parent: Node, label: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.name = label.replace(" ", "").replace("&","And")
	b.custom_minimum_size = Vector2(0, 51)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	_button_style(b)
	b.pressed.connect(callback)
	parent.add_child(b)
	action_buttons[label] = b
	return b

func _press_move(direction: String, pressed: bool) -> void:
	held_moves[direction] = pressed
	motion = Vector2(float(held_moves.get("right", false))-float(held_moves.get("left", false)),
		float(held_moves.get("down", false))-float(held_moves.get("up", false)))

func _nearby() -> String:
	if player_pos.distance_to(ConnectedWorld.TRAIL_MANGO) < ConnectedWorld.TRAVEL_RANGE_2D:
		return "return_barrio"
	if player_pos.distance_to(ConnectedWorld.TRAIL_MANGO_RIDGE) < ConnectedWorld.TRAVEL_RANGE_2D:
		return "ridge_gate"
	if story.phase == 0:
		for id in KEY_ORDER:
			if not story.clues.has(id) and player_pos.distance_to(TARGETS[id]) < 105:
				return id
	elif story.phase == 1:
		for id in Story.BARRIER_POSITIONS:
			if not story.barriers.has(id) and player_pos.distance_to(TARGETS[id]) < 120:
				return id
	elif story.phase == 2:
		if player_pos.distance_to(OBSERVATION) < 125:
			return "observe"
	elif story.phase == 3:
		if player_pos.distance_to(TREE) < 315:
			return "kapre"
	var postgame_neighbor := PostgameResidents.nearby(self,"old_mango",player_pos)
	if postgame_neighbor != "":
		return postgame_neighbor
	return ""

func _next_target() -> Dictionary:
	var best_distance := INF
	var target_id := ""
	var target_at := Vector2.ZERO
	var ids: Array[String] = []
	if story.phase == 0:
		for id in KEY_ORDER:
			if not story.clues.has(id):
				ids.append(id)
	elif story.phase == 1:
		for id in Story.BARRIER_POSITIONS:
			if not story.barriers.has(id):
				ids.append(id)
	if ids.size() > 0:
		for id in ids:
			var distance := player_pos.distance_to(TARGETS[id])
			if distance < best_distance:
				best_distance = distance
				target_at = TARGETS[id]
				target_id = id
	elif story.phase == 2:
		target_at = OBSERVATION
		target_id = "SAFE LOOKOUT"
	elif story.phase == 3:
		target_at = TREE
		target_id = "OLD MANGO TREE"
	else:
		return {}
	return {"name": str(CLUE_TITLES.get(target_id,target_id.replace("_"," "))).to_upper(), "point": target_at}


func _update_waypoint() -> void:
	if waypoint_label == null:
		return
	var next := _next_target()
	if next.is_empty():
		waypoint_label.text = "CHAPTER COMPLETE"
		return
	var direction: Vector2 = next["point"] - player_pos
	var angle := atan2(direction.y,direction.x)
	var octant := posmod(roundi((angle+PI) / (PI/4.0)),8)
	var arrows := ["←","↖","↑","↗","→","↘","↓","↙"]
	var compass: String = arrows[octant]
	if direction.length() < 120.0:
		compass = "◆"
	waypoint_label.text = compass + "  " + str(next["name"]) + "\n" + ("%d STEPS" % roundi(direction.length()/11.0))


func _update_hint() -> void:
	var near := _nearby()
	if near == last_target and interaction_hint.text != "":
		return
	last_target = near
	if near == "return_barrio":
		interaction_hint.text = "BARRIO LAWOM • FOLLOW TRAIL TO RETURN"
	elif near == "ridge_gate":
		interaction_hint.text = "INTERACT • NORTH RIDGE / NIGHT 3" if story.outcome != "" else "NORTH RIDGE LOCKED • FINISH KAPRE CASE"
	elif near == "":
		interaction_hint.text = "EXPLORE • Follow the highlighted clue / safe route"
	elif near == "observe":
		interaction_hint.text = "SAFE LOOKOUT • HOLD OBSERVE to watch from shelter"
	elif near == "kapre":
		interaction_hint.text = "KAPRE • INTERACT respectfully"
	elif Story.BARRIER_POSITIONS.has(near):
		interaction_hint.text = "INTERACT • CLOSE THE DANGEROUS %s" % near.replace("_"," ").to_upper()
	else:
		interaction_hint.text = "INTERACT • " + str(CLUE_TITLES.get(near,near))

func _interact() -> void:
	if dialogue.visible:
		return
	if notebook.visible or options_panel.visible or ending_panel.visible:
		return
	var target := _nearby()
	if target.begins_with("postgame:"):
		_show_dialogue(PostgameResidents.speaker(target),
			PostgameResidents.talk(self,target),
			[{"label":"SALAMAT • CONTINUE","action":"close"}])
		return
	if target == "return_barrio":
		_return_to_barrio()
		return
	if target == "ridge_gate":
		_enter_ridge()
		return
	if target == "":
		_show_dialogue("BANTAY", "Bantay sniffs the wind. Move closer to the highlighted clue or safe route marker.", [{"label":"CONTINUE", "action":"close"}])
		return
	if story.phase == 0:
		if story.observe(target):
			_auto_save()
			if story.complete_evidence():
				story.begin_safety()
				_auto_save()
				_show_dialogue("MARA", str(STORY_TEXT[target]) +
					"\n\nFive pieces of evidence now agree: the route is dangerous. Close THREE approaches before talking to the giant.",
					[{"label":"MARK THE SAFE DETOUR", "action":"close"}])
			else:
				_show_dialogue("FIELD OBSERVATION", str(STORY_TEXT[target]), [{"label":"RECORD CLUE", "action":"close"}])
	elif story.phase == 1:
		if story.close_route(target):
			_auto_save()
			if story.safe_route():
				story.begin_observation()
				_auto_save()
				_show_dialogue("TATAY DADO", "The west approach, south approach, and shelter turn are closed. The children can use the detour. Watch the giant from the safe lookout—don't rush into his home.",
					[{"label":"GO TO SAFE LOOKOUT", "action":"close"}])
			else:
				_show_dialogue("ROUTE CLOSED", "You secured %s. Keep people away from falling limbs. %d of 3 danger points marked." %
					[target.replace("_"," "), story.barriers.size()], [{"label":"CONTINUE", "action":"close"}])
	elif story.phase == 2:
		if story.observation >= .999:
			_choose("greet")
		else:
			_show_dialogue("FIELD NOTES", "Stand behind the shelter screen and HOLD OBSERVE continuously for four seconds. Never approach the roots during the shaking.",
				[{"label":"UNDERSTOOD", "action":"close"}])
	elif story.phase == 3:
		_open_negotiation()
	_rebuild_objective()

func _rebuild_objective() -> void:
	var phase_name: String = ["INVESTIGATION", "ROUTE SAFETY", "WATCH QUIETLY", "NEGOTIATION", "AFTERMATH"][clampi(story.phase,0,4)]
	subtitle.text = "%s  •  EVIDENCE %d/5  •  BARRIERS %d/3" % [phase_name,story.clues.size(),story.barriers.size()]
	match story.phase:
		0: objective.text = "Inspect FIVE clues around the mango tree, school and old shelter route."
		1: objective.text = "Dusk: secure THREE unsafe approaches before nightfall."
		2: objective.text = "Night: watch the cigar ember and smoke from the safe lookout (HOLD OBSERVE)."
		3: objective.text = "Night: greet the Kapre in the mango branches; discuss a safe solution."
		4: objective.text = "NIGHT 2 RESOLVED: %s. Your record and community safety plan are saved." % story.outcome.to_upper()
	queue_redraw()

func _open_negotiation() -> void:
	if story.offered == "":
		_show_dialogue("KAPRE", "Dugay na kong nagpuyo dinhi... Nakadungog ko sa inyong saad sa baha, apan wala may mibalik. Ngano nga ania ka?",
			[{"label": "OFFER WARM COFFEE", "action": "coffee"},
			{"label": "OFFER TOBACCO", "action": "tobacco"},
			{"label": "LEAVE PEACEFULLY", "action":"retreat"}])
	elif not story.commitment:
		_show_dialogue("APPRENTICE", "Wala ko mianhi aron gub-on ang imong puy-anan.\nKabalo ko. Delikado na kini—sa imo ug sa mga tawo.",
			[{"label":"ASK EXPERT, KEEP TREE IF SAFE + REROUTE", "action":"plan"},
			{"label":"MAKE PROMISE WITHOUT ASSESSMENT", "action":"unsafe_plan"},
			{"label":"KEEP ROUTE CLOSED; LEAVE", "action":"partial"}])
	else:
		_show_dialogue("KAPITAN", "We cannot erase the Great Flood or that broken rescue promise. But we can keep children safe and commission the assessment before deciding the tree's future.",
			[{"label":"AGREE ON SAFE RESOLUTION", "action":"resolve"},
			{"label":"LEAVE WITH SAFETY BARRIERS", "action":"partial"}])

func _choose(action: String) -> void:
	_close_dialogue()
	match action:
		"close":
			pass
		"greet":
			if story.greet_respectfully():
				_auto_save()
				_show_dialogue("APPRENTICE",
					"Tabi-tabi po. Wala ko mianhi aron gub-on ang imong puy-anan. Kabalo ko nga delikado na kini—sa imo ug sa mga tawo.",
					[{"label":"LISTEN TO THE GIANT", "action":"negotiate"}])
		"negotiate":
			_open_negotiation()
		"coffee","tobacco":
			if story.choose_offering(action):
				_auto_save()
				_show_dialogue("KAPRE",
					"Ang inyong kape ug mahinay nga tingog lahi sa mga tawo nga nagsinggit og 'putla'. Paminawa ang akong nahinumdoman: sa Great Flood, wala naabot ang gisaarang tabang.",
					[{"label":"DISCUSS REAL SAFETY PLAN","action":"negotiate"}])
		"unsafe_plan":
			story.propose_preservation(false,false)
			_show_dialogue("BANTAY", "A promise without securing the dangerous branches is not enough. A qualified assessment and safer route must be part of the agreement.",
				[{"label":"REVISE THE PLAN","action":"negotiate"}])
		"plan":
			if story.propose_preservation(true,true):
				_auto_save()
				_show_dialogue("KAPRE",
					"Kabalo ko. Delikado na kini. Kon inyong bantayan ang mga bata ug dili dayon putlon ang kahoy nga walay pagsusi, dawaton ko ang inyong saad.",
					[{"label":"SPEAK WITH KAPITAN","action":"negotiate"}])
		"resolve","partial","retreat":
			if story.commit(action):
				_auto_save()
				_rebuild_objective()
				_show_ending()
		"retry":
			if story.safe_retry():
				player_pos = OBSERVATION + Vector2(-20,10)
				_auto_save()
				_show_dialogue("BANTAY", "You returned to the last safe checkpoint. Take your time and use the sheltered path.", [{"label":"CONTINUE","action":"close"}])
	_rebuild_objective()

func _request_retreat() -> void:
	if story.outcome != "":
		_show_ending()
	else:
		_show_dialogue("SAFE EXIT", "Withdrawing is always allowed; you will not be forced to harm the Kapre. You can also stay and finish the investigation.",
			[{"label":"CONTINUE INVESTIGATING","action":"close"},
			{"label":"WITHDRAW SAFELY","action":"retreat"}])

func _show_dialogue(who: String, message: String, options: Array) -> void:
	observe_held = false
	motion = Vector2.ZERO
	held_moves.clear()
	notebook.hide()
	options_panel.hide()
	dialogue_name.text = who
	dialogue_line.text = message
	SharedDialogueMotion.reveal_text(dialogue_line,prefs.reduced_motion)
	var role := who.to_upper()
	var creature_speaking := role.contains("KAPRE")
	var person_speaking := role.contains("LOLA") or role.contains("DADO") or role.contains("MARA") or role.contains("SABEL") or role.contains("APPRENTICE") or role.contains("BANTAY")
	kapre_dialogue_portrait.visible = creature_speaking
	dialogue_portrait.visible = person_speaking and not creature_speaking
	if dialogue_portrait.visible:
		dialogue_portrait.call("set_speaker",who)
	for child in dialogue_choices.get_children():
		dialogue_choices.remove_child(child)
		child.queue_free()
	for option in options:
		var choice := Button.new()
		choice.text = str(option["label"])
		choice.name = "Choice_" + str(option["action"])
		choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice.custom_minimum_size = Vector2(350, 47)
		_button_style(choice,18)
		var action_name := str(option["action"])
		choice.pressed.connect(func(): _on_dialogue_choice_pressed(action_name))
		dialogue_choices.add_child(choice)
	dialogue_focus_point = _cinematic_subject(who)
	dialogue_focus_enabled = true
	SharedDialogueMotion.reveal(dialogue,prefs.reduced_motion)
	_sync_gameplay_hud()

func _cinematic_subject(who: String) -> Vector2:
	var role := who.to_upper()
	var subject_at := player_pos
	if role.contains("KAPRE"):
		subject_at = TREE
	elif role.contains("DADO") or role.contains("MARA") or role.contains("LOLA"):
		subject_at = TARGETS["witness_accounts"]
	elif role.contains("BANTAY") or role.contains("APPRENTICE"):
		subject_at = dog_pos if role.contains("BANTAY") else player_pos
	# A distant witness or off-scene narration must never jerk the camera
	# across the whole map; ambient storytelling stays anchored at the player.
	if subject_at.distance_to(player_pos) > 370.0:
		return player_pos
	return subject_at

func _on_dialogue_choice_pressed(action: String) -> void:
	# Respect readability without changing canonical state-machine calls.
	if SharedDialogueMotion.finish_text(dialogue_line):
		return
	_choose(action)

func _close_dialogue() -> void:
	dialogue_focus_enabled = false
	SharedDialogueMotion.conceal(dialogue,prefs.reduced_motion)
	_sync_gameplay_hud()
	motion = Vector2.ZERO
	held_moves.clear()
	observe_held = false

func _open_notebook() -> void:
	if dialogue.visible or ending_panel.visible:
		return
	motion = Vector2.ZERO
	held_moves.clear()
	var lines := "NIGHT 2: KAPRE — THE GIANT IN THE MANGO TREE\n"
	lines += "Night 1 outcome: %s\n\n" % (story.night1_outcome if story.night1_outcome != "" else "unverified")
	lines += "OBSERVED EVIDENCE (do not confuse with rumors):\n"
	for id in KEY_ORDER:
		lines += ("[RECORDED] " if story.clues.has(id) else "[MISSING] ") + str(CLUE_TITLES[id]) + "\n"
	lines += "\nPUBLIC SAFETY: closed approaches\n"
	for id in Story.BARRIER_POSITIONS:
		lines += ("[SECURED] " if story.barriers.has(id) else "[OPEN] ") + id.replace("_", " ") + "\n"
	lines += "\nFIELD RULE: assess real environmental dangers first. Never approach unstable roots. Close the route before negotiating.\n"
	lines += "\nTHE GREAT FLOOD: villagers remember a rescue promise that went unfulfilled. Stories and observations have different certainty.\n"
	lines += "\nNEGOTIATION: \"Tabi-tabi po\"; offer coffee or tobacco; do not break branches; consult qualified arborists and seek a preservation option when safe.\n"
	if story.outcome != "":
		lines += "\nENDING: %s. The safety route remains part of the community record.\n" % story.outcome.to_upper()
	notebook_content.text = lines
	notebook.show()

func _open_options() -> void:
	if dialogue.visible or notebook.visible or ending_panel.visible:
		return
	observe_held = false
	motion = Vector2.ZERO
	held_moves.clear()
	options_panel.show()

func _auto_save() -> bool:
	story.player_position = player_pos
	var saved := Save.write(story)
	if saved and story.outcome != "":
		ConnectedWorld.note_outcome(2, story.outcome)
	return saved


func _enter_ridge() -> void:
	if travel_in_progress:
		return
	if story.outcome == "":
		_show_dialogue("BANTAY","Before the north ridge is safe to enter, finish the Kapre investigation and mark the dangerous mango approaches.",
			[{"label":"FINISH NIGHT 2","action":"close"}])
		return
	if not _auto_save():
		save_error.popup_centered(Vector2i(610,190))
		return
	if not ConnectedWorld.begin_travel("old_mango","night03",story.outcome):
		_show_dialogue("FIELD RECORD","The North Ridge needs a confirmed Night 2 completion in the shared story ledger. Save and finish the Kapre chapter first.",
			[{"label":"CHECK PROGRESS","action":"close"}])
		return
	travel_in_progress = true
	observe_held = false
	motion = Vector2.ZERO
	held_moves.clear()
	print("TABI_WORLD_TRAVEL_MANGO_TO_RIDGE")
	get_node("/root/SceneTransit").call("change_to_file", ConnectedWorld.scene_for("night03"))


func _return_to_barrio() -> void:
	if travel_in_progress:
		return
	if not _auto_save():
		save_error.popup_centered(Vector2i(610, 190))
		return
	if not ConnectedWorld.begin_travel("old_mango", "barrio_lawom", story.night1_outcome):
		save_error.popup_centered(Vector2i(610, 190))
		return
	travel_in_progress = true
	observe_held = false
	motion = Vector2.ZERO
	held_moves.clear()
	print("TABI_WORLD_TRAVEL_MANGO_TO_BARRIO")
	get_node("/root/SceneTransit").call("change_to_file", ConnectedWorld.scene_for("barrio_lawom"))

func _save_and_notify() -> void:
	if _auto_save():
		options_panel.hide()
		_show_dialogue("FIELD RECORD", "Night 2 saved offline. Night 1 remains untouched.", [{"label":"CONTINUE","action":"close"}])
	else:
		save_error.popup_centered(Vector2i(610,190))

func _save_and_main_menu() -> void:
	if not _auto_save():
		save_error.popup_centered(Vector2i(610,190))
		return
	get_node("/root/SceneTransit").call("change_to_file", "res://scenes/title.tscn")

func _save_and_quit() -> void:
	if not _auto_save():
		save_error.popup_centered(Vector2i(610,190))
		return
	get_tree().quit()

func _show_ending() -> void:
	ending_panel.show()
	observe_held = false
	var box := ending_panel.get_node_or_null("AftermathContent") as VBoxContainer
	if box == null:
		box = VBoxContainer.new()
		box.name = "AftermathContent"
		box.add_theme_constant_override("separation", 13)
		ending_panel.add_child(box)
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	var title := Label.new()
	title.text = "NIGHT 2  /  THE MANGO TREE REMEMBERS"
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("#eac689"))
	box.add_child(title)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(490,185)
	body.add_theme_font_size_override("font_size", 22)
	match story.outcome:
		"resolve":
			body.text = "RESOLVE — Kapre listened. The Kapitan keeps the dangerous route closed, requests an expert tree assessment and considers preservation without endangering the villagers.\n\nThe Great Flood's broken rescue promise cannot be undone, but the community begins to act with care."
		"partial":
			body.text = "PARTIAL — You secured the dangerous path and protected the children. A lasting agreement with the Kapre is not yet proven.\n\nThe tree will remain under review, and witnesses remember the unfinished promise."
		_:
			body.text = "SAFE RETREAT — You chose not to force an encounter. The village needs a safer route, an expert assessment and more listening before any permanent decision.\n\nNo one was sacrificed for a quick answer."
	box.add_child(body)
	var stamp := Label.new()
	stamp.text = "RECORDED • KAPRE BESTIARY ENTRY • NIGHT 2 COMPLETE"
	stamp.add_theme_font_size_override("font_size", 19)
	stamp.add_theme_color_override("font_color", Color("#b8d3b0"))
	box.add_child(stamp)
	_action(box, "REVIEW FIELD NOTES", func():
		ending_panel.hide()
		_open_notebook()
	)
	_action(box, "SAVE & MAIN MENU", _save_and_main_menu)
