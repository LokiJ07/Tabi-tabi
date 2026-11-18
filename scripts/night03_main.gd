extends Node2D
## Night 3 — TIKBALANG: THE FALSE TRAIL.
## One connected Barrio Lawom narrative. Original 2.5D ridge artwork, physical
## trail crossings, clues, route puzzles, safe observation and multiple endings.
## Android compatible: CanvasItem art, shared HUD, shared NPC cinematic system.
const Story = preload("res://scripts/narrative/night03_state.gd")
const Save = preload("res://scripts/core/night03_save.gd")
const Night02Save = preload("res://scripts/core/night02_save.gd")
const Night02State = preload("res://scripts/narrative/night02_state.gd")
const ConnectedWorld = preload("res://scripts/core/connected_world.gd")
const Preferences = preload("res://scripts/core/preferences.gd")
const SharedHUD = preload("res://scripts/ui/shared_hud.gd")
const PostgameResidents = preload("res://scripts/world/postgame_residents.gd")
const SharedMotion = preload("res://scripts/ui/shared_dialogue_motion.gd")
const SharedAtmosphere = preload("res://scripts/visuals/shared_immersive_atmosphere.gd")
const DimensionalArt = preload("res://scripts/visuals/layered_25d.gd")
const NightWindows = preload("res://scripts/visuals/nighttime_windows.gd")
const Landscape = preload("res://scripts/visuals/folklore_landscape_25d.gd")
const Sound = preload("res://scripts/audio/night02_ambience.gd")
const Portrait = preload("res://scripts/ui/speaker_portrait.gd")
const AimPad = preload("res://scripts/ui/aim_pad.gd")
const TIKBALANG: Texture2D = preload("res://assets/night03/tikbalang_ridge.svg")
const BAMBOO: Texture2D = preload("res://assets/night03/bamboo_ridge.svg")
const WATCHPOST: Texture2D = preload("res://assets/night03/flood_watchpost.svg")
const HERO: Texture2D = preload("res://assets/characters/apprentice.svg")
const BANTAY: Texture2D = preload("res://assets/characters/bantay.svg")
const SOIL: Texture2D = preload("res://assets/world/soil_ground.svg")
const FERNS: Texture2D = preload("res://assets/world/north_grove_understory.svg")
const PLANT: Texture2D = preload("res://assets/world/hibiscus_bush.svg")
const LANTERN: Texture2D = preload("res://assets/world/lantern_post.svg")
const MAP_BOUNDS := Rect2(-1030,-780,2100,1650)
const PLAYER_SPEED := 255.0
const SAFE_LOOKOUT := Vector2(-160,-295)
const FALSE_FORK := Vector2(220,50)
const RIDGE_GATE := Vector2(605,-350)
const CLUES_AT := {
	"washed_rope":Vector2(-530,138),
	"bridge_map":Vector2(-395,-378),
	"heel_marks":Vector2(120,245),
	"rescuer_note":Vector2(375,-425)
}
const MARKERS_AT := {
	"river_stones":Vector2(-555,-100),
	"old_watchpost":Vector2(-150,-245),
	"bamboo_diversion":Vector2(365,-135)
}
const CLUE_LABELS := {
	"washed_rope":"A frayed rescue rope",
	"bridge_map":"A water-stained shelter map",
	"heel_marks":"Boot and hoof-like imprints",
	"rescuer_note":"A missing rescuer's field note"
}
const CLUE_STORIES := {
	"washed_rope":"The rope was tied to the old bridge during the Great Flood. Its frayed end suggests emergency crossing, not proof that any creature attacked.",
	"bridge_map":"Mara's old shelter map marks THREE safe waypoints on the ridge: river stones, watchpost, and bamboo diversion. The new painted arrow is wrong.",
	"heel_marks":"Heavy imprints overlap an old boot track. Rain distorted their edges. Do not assume that every hoof-like print belongs to the same being.",
	"rescuer_note":"A folded page bears an unfinished rescue list. One line reads: 'I moved the sign to protect the little ones. I could not return for the others.'"
}

var story = Story.new()
var prefs = Preferences.new()
var player_pos := Story.START
var bantay_pos := Story.START + Vector2(-50,25)
var camera: Camera2D
var motion := Vector2.ZERO
var look_direction := Vector2.ZERO
var held_moves: Dictionary = {}
var observe_held := false
var travel_in_progress := false
var elapsed := 0.0
var particles := 0.0
var walk_phase := 0.0
var walk_weight := 0.0
var debug_night_preview := false
var hud: CanvasLayer
var gameplay_controls: Control
var modal_backdrop: ColorRect
var status_panel: PanelContainer
var status_stack: VBoxContainer
var objective: Label
var subtitle: Label
var courage: Label
var waypoint: Label
var interaction_hint: Label
var observation_bar: ProgressBar
var buttons: Dictionary = {}
var dialogue: PanelContainer
var dialogue_speaker: Label
var dialogue_text: Label
var dialogue_portrait: Control
var creature_portrait: TextureRect
var dialogue_choices: VBoxContainer
var dialogue_focus := false
var focus_point := Vector2.ZERO
var camera_blend := 0.0
var notebook: PanelContainer
var notebook_body: Label
var options_panel: PanelContainer
var ending_panel: PanelContainer
var save_error: AcceptDialog
var atmosphere
var ambient

func _ready() -> void:
	name = "TabiTabiNight3"
	set_meta("dimensional_art", DimensionalArt.STYLE_ID)
	prefs.load_from()
	var previous := Night02State.new()
	if Night02Save.read(previous):
		story.night02_outcome = previous.outcome
		story.night01_outcome = previous.night1_outcome
	Save.read(story)
	player_pos = story.player_position
	var arrival: Dictionary = ConnectedWorld.consume_arrival("night03")
	if str(arrival.get("from","")) == "old_mango":
		player_pos = ConnectedWorld.ARRIVAL_RIDGE
		print("TABI_WORLD_ARRIVAL_RIDGE_FROM_MANGO")
	elif str(arrival.get("from","")) == "night04":
		player_pos = ConnectedWorld.ARRIVAL_RIDGE_WAKE
		print("TABI_WORLD_ARRIVAL_RIDGE_FROM_WAKE")
	bantay_pos = player_pos + Vector2(-46,29)
	camera = Camera2D.new()
	camera.name = "Night03RidgeCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = not prefs.reduced_motion
	camera.position_smoothing_speed = 4.2
	camera.position = player_pos
	# Bring the traveler into frame without altering the touch HUD anchors.
	camera.zoom = Vector2(1.08,1.08)
	add_child(camera)
	ambient = Sound.new()
	ambient.name = "RidgeInsectsAndWind"
	add_child(ambient)
	ambient.set_audio_level(prefs.audio_level)
	_build_ui()
	_refresh_objective()
	var postgame_ready := get_node_or_null("/root/PostgameClock")
	if story.outcome != "" and not (postgame_ready != null and postgame_ready.is_active()):
		_show_ending()
	elif story.phase == 0 and story.clues.is_empty():
		_show_dialogue("LOLA PASING",
			"The old mango path leads to the high ridge. Dado never finished telling me who moved the rescue signs during the Great Flood.\n\nAyaw sunod-sunod sa mga suga. Ang makita nimo, isulat. Bantay will keep to the safest ground.",
			[{"label":"FOLLOW THE REAL RESCUE TRAIL","action":"close"}])
	print("NIGHT3_QA_SCENE_READY")

func _stage() -> int:
	var free_roam_clock := get_node_or_null("/root/PostgameClock")
	if free_roam_clock != null and free_roam_clock.is_active():
		return free_roam_clock.light_stage()
	if debug_night_preview:
		return 3
	if story.phase <= 0 or story.phase >= 5:
		return 0
	if story.phase == 1:
		return 1
	if story.phase == 2:
		return 2
	return 3

func _process(delta: float) -> void:
	var village_clock := get_node_or_null("/root/PostgameClock")
	if village_clock != null and village_clock.is_active() and objective != null:
		var free_roam_status := "FREE ROAM • FLOOD RIDGE • SAFE WAYMARKS\n%s  |  %s" % [
			village_clock.clock_label(),
			"RESTORED" if village_clock.village_mood == "restored" else "REBUILDING"
		]
		if objective.text != free_roam_status:
			objective.text = free_roam_status
	elapsed += delta
	if not prefs.reduced_motion:
		particles += delta
	var axis := Input.get_vector("ui_left","ui_right","ui_up","ui_down") + motion
	var blocked := _modal_open()
	if blocked:
		axis = Vector2.ZERO
	axis = axis.limit_length()
	walk_weight = lerpf(walk_weight, 1.0 if axis.length() > .02 else 0.0,
		1.0 if prefs.reduced_motion else clampf(delta * 9.0,0.0,1.0))
	if axis.length() > .02:
		if not prefs.reduced_motion:
			walk_phase += delta * 8.5
		var heading := Vector2(axis.x + axis.y*.43, axis.y*.79 - axis.x*.16).normalized()
		var moved := player_pos + heading*PLAYER_SPEED*delta
		moved.x = clampf(moved.x,MAP_BOUNDS.position.x+45.0,MAP_BOUNDS.end.x-45.0)
		moved.y = clampf(moved.y,MAP_BOUNDS.position.y+45.0,MAP_BOUNDS.end.y-45.0)
		# The ravine is real collision: the traveler must use the stone ford.
		if _in_unsafe_ravine(moved):
			moved = player_pos
		player_pos = moved
	bantay_pos = bantay_pos.lerp(player_pos + Vector2(-49,29),clampf(delta*3.5,0.0,1.0))
	var goal_blend := 1.0 if dialogue_focus and dialogue.visible else 0.0
	camera_blend = lerpf(camera_blend,goal_blend,1.0 if prefs.reduced_motion else clampf(delta*3.8,0.0,1.0))
	# The Tikbalang is tall enough that tracking the player's feet alone
	# crops off its face. Only after a legitimate reveal (or QA preview),
	# draw the camera toward the witness as the player approaches the gate.
	var witness_visible: bool = (story.phase == 4 and story.outcome == "") or debug_night_preview
	var witness_pull := Vector2.ZERO
	if witness_visible:
		var distance_to_witness := player_pos.distance_to(RIDGE_GATE)
		var reveal_weight := 1.0-clampf((distance_to_witness-240.0)/260.0,0.0,1.0)
		witness_pull = (RIDGE_GATE+Vector2(-12,-258)-player_pos).limit_length(278.0)*reveal_weight
	camera.position = player_pos + (focus_point-player_pos).limit_length(85.0)*camera_blend + witness_pull
	camera.offset = camera.offset.lerp(look_direction*61.0,clampf(delta*8.0,0.0,1.0))
	# An intentional, gentle push-in when the ridge becomes threatening.
	# Reduced Motion disables the animated interpolation entirely.
	var ridge_zoom := 1.08 if _stage() < 2 else 1.15
	if dialogue_focus and dialogue.visible:
		ridge_zoom += .035
	camera.zoom = camera.zoom.lerp(Vector2.ONE*ridge_zoom,
		1.0 if prefs.reduced_motion else clampf(delta*2.0,0.0,1.0))
	if not blocked and not travel_in_progress and player_pos.distance_to(ConnectedWorld.TRAIL_RIDGE) < 54.0:
		_return_to_mango()
		return
	if not blocked:
		story.danger_tick(delta,player_pos.distance_to(FALSE_FORK)<135.0 and story.phase>=2,
			player_pos.distance_to(SAFE_LOOKOUT)<125.0,prefs.story_assist)
		if story.encounter_failed and story.outcome == "":
			_show_dialogue("BANTAY","The false lights have turned you around. Bantay leads you to the last safe marker; you can retry without losing the clues you've already recorded.",
				[{"label":"RETRY SAFE MARKER","action":"retry"},{"label":"WITHDRAW SAFELY","action":"retreat"}])
	if story.phase == 2 and observe_held and not blocked:
		if story.observe(delta,player_pos.distance_to(SAFE_LOOKOUT)<130.0,true):
			observe_held = false
			_auto_save()
			_show_dialogue("BANTAY","From shelter the lights split into three. Only the river-stone trail matches the flood map, actual rope marks and human footprints. Check the sign at the fork, then decide.",
				[{"label":"VERIFY THE REAL TRAIL","action":"close"}])
	if observation_bar != null:
		observation_bar.visible = story.phase == 2
		observation_bar.value = story.observation*100.0
	if courage != null:
		courage.text = "COURAGE %d  •  TENSION %d%%" % [roundi(story.courage),roundi(story.tension*100.0)]
	if atmosphere != null:
		atmosphere.configure(3,_stage(),story.tension,prefs.reduced_motion)
	if ambient != null:
		ambient.set_night_stage(_stage())
		ambient.set_tension(story.tension)
	_refresh_hint()
	queue_redraw()

func _in_unsafe_ravine(at: Vector2) -> bool:
	# Two steep washout banks block passage except the actual stone ford.
	if at.x > -80.0 and at.x < 65.0 and at.y > 300.0 and at.y < 620.0:
		return true
	return false

func _modal_open() -> bool:
	return (dialogue != null and dialogue.visible) or (notebook != null and notebook.visible) or (options_panel != null and options_panel.visible) or (ending_panel != null and ending_panel.visible)

func _sync_hud() -> void:
	if gameplay_controls == null:
		return
	var modal := _modal_open()
	var was_open := gameplay_controls.visible
	gameplay_controls.visible = not modal
	if modal and was_open:
		SharedMotion.reset_gameplay(gameplay_controls)
	elif not modal and not was_open:
		SharedMotion.restore_gameplay(gameplay_controls,prefs.reduced_motion)
	modal_backdrop.visible = modal
	modal_backdrop.color = Color(.015,.035,.05,.30 if dialogue.visible else .76)
	if modal:
		held_moves.clear()
		motion = Vector2.ZERO
		look_direction = Vector2.ZERO
		observe_held = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if dialogue.visible:
			SharedMotion.finish_text(dialogue_text)
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
		if key.pressed and not key.echo and key.keycode in [KEY_F3,KEY_F5,KEY_F6,KEY_F7,KEY_F9]:
			_close_dialogue()
			notebook.hide()
			options_panel.hide()
			debug_night_preview = key.keycode in [KEY_F7,KEY_F9]
			match key.keycode:
				KEY_F3:
					player_pos = Vector2(-260,-320)
					print("NIGHT3_QA_RIDGE_DAY")
				KEY_F5:
					player_pos = ConnectedWorld.ARRIVAL_RIDGE
					print("NIGHT3_QA_BACK_TRAIL")
				KEY_F6:
					player_pos = SAFE_LOOKOUT
					print("NIGHT3_QA_WATCHPOST")
				KEY_F7:
					player_pos = SAFE_LOOKOUT + Vector2(90,100)
					print("NIGHT3_QA_LOOKOUT_NIGHT")
				KEY_F9:
					player_pos = RIDGE_GATE + Vector2(-125,80)
					print("NIGHT3_QA_TIKBALANG_NIGHT")
			bantay_pos = player_pos+Vector2(-52,31)
			camera.position = player_pos
			get_viewport().set_input_as_handled()

func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points),color)

func _path(points: Array, edge: Color, fill: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points),edge,width+24.0,true)
	draw_polyline(PackedVector2Array(points),fill,width,true)

func _draw() -> void:
	# Ground: layered ridge contours, flooded terrace, textured forest floor.
	draw_rect(Rect2(-1250,-1100,2600,2400),Color("#223e36"))
	Landscape.parallax_ridges(self,Rect2(-1250,-1100,2600,2400),camera.position,3,_stage())
	for i in range(34):
		var yy := -925.0+float(i)*58.0
		var tint := Color("#30483a").lerp(Color("#566448"),float(i)/33.0)
		draw_rect(Rect2(-1150,yy,2380,59),tint)
	draw_texture_rect(SOIL,Rect2(-1090,-830,2240,1710),false,Color(1,1,1,.19))
	# Raised north ridge and shaded ravine run diagonally across the valley.
	_poly([Vector2(-1040,-620),Vector2(1010,-750),Vector2(1030,-240),
		Vector2(-1020,300)],Color("#44543c"))
	_poly([Vector2(-1000,-575),Vector2(1010,-710),Vector2(990,-285),
		Vector2(-1015,260)],Color("#647255"))
	_poly([Vector2(-220,740),Vector2(155,740),Vector2(310,-600),
		Vector2(100,-710),Vector2(-40,20)],Color("#283f43"))
	_poly([Vector2(-170,740),Vector2(45,740),Vector2(198,-560),
		Vector2(120,-620)],Color("#47716d"))
	for i in range(19):
		var sy := -475.0+float(i)*67.0
		draw_line(Vector2(-95+sin(float(i))*35.0,sy),Vector2(54+sin(float(i))*27.0,sy-55),
			Color(.72,.86,.82,.23),2.0,true)
	# Three connected walkable ridge footpaths + actual return trail.
	_path([Vector2(-910,405),Vector2(-720,310),Vector2(-505,155),
		Vector2(-305,-70),Vector2(-154,-293),Vector2(105,-118),
		Vector2(385,-125),Vector2(640,-357)],Color("#526247"),Color("#b59e79"),70.0)
	_path([Vector2(-330,-80),Vector2(-396,-335),Vector2(28,-488),
		Vector2(380,-450),Vector2(640,-357)],Color("#53664b"),Color("#9d896c"),56.0)
	_path([Vector2(-520,145),Vector2(-170,245),Vector2(126,260),
		Vector2(220,50)],Color("#5c5a47"),Color("#9e8060"),59.0)
	# Broken shoulder stones follow the rising ridge and do not replace the
	# existing walkable trail, real ravine collision or clue interactions.
	Landscape.trail_stones(self,Vector2(-910,405),Vector2(-305,-70),29,70,_stage()>=2)
	Landscape.trail_stones(self,Vector2(105,-118),Vector2(640,-357),22,70,_stage()>=2)
	# The physical ford is made of stones, NOT walk-through empty water.
	for i in range(7):
		var xx := -148.0+float(i)*38.0
		var yy := 118.0+float(i%3)*14.0
		_poly([Vector2(xx-21,yy+9),Vector2(xx-14,yy-11),
			Vector2(xx+15,yy-15),Vector2(xx+27,yy+3),
			Vector2(xx+12,yy+15)],Color("#7a7667"))
		draw_line(Vector2(xx-7,yy-7),Vector2(xx+13,yy-9),Color("#d1bd91"),2,true)
	for cliff_rock in [Vector2(-215,362),Vector2(180,514),Vector2(-65,655),
		Vector2(345,-565),Vector2(515,-510),Vector2(720,-270)]:
		Landscape.rock(self,cliff_rock,64.0,_stage()<2)
	for pos in [Vector2(-890,-430),Vector2(-755,-630),Vector2(-520,-650),
		Vector2(-20,-610),Vector2(410,-640),Vector2(760,-570),
		Vector2(870,35),Vector2(690,520),Vector2(-420,625),
		Vector2(-835,665),Vector2(850,620),Vector2(575,50)]:
		draw_texture_rect(FERNS,Rect2(pos-Vector2(180,145),Vector2(360,290)),false,Color.WHITE)
	for data in [
		[Vector2(-845,-385),.95],[Vector2(-755,-570),1.10],
		[Vector2(-540,-575),.75],[Vector2(-20,-555),.88],
		[Vector2(425,-545),1.12],[Vector2(820,-625),.95],
		[Vector2(875,150),.85],[Vector2(760,570),1.08],
		[Vector2(-700,675),.98],[Vector2(-480,520),.78]
	]:
		var p: Vector2 = data[0]
		var scale_bamboo: float = data[1]
		DimensionalArt.paint_grounded(self, BAMBOO,
			p + Vector2(0,36*scale_bamboo),
			Vector2(284*scale_bamboo,380*scale_bamboo), Color.WHITE, .26)
	# Old flood watchpost is a roofed, three-dimensional landmark.
	DimensionalArt.paint_grounded(self, WATCHPOST,
		Vector2(-145,-230), Vector2(410,330), Color.WHITE, .38)
	DimensionalArt.lantern(self, LANTERN,
		Vector2(-224,-321), Vector2(56,127), _stage() >= 1)
	# Meaningful clue props, four unique physical silhouettes.
	for id in Story.CLUES:
		var clue: Vector2 = CLUES_AT[id]
		if id == "washed_rope":
			for i in range(9):
				var bend := Vector2(sin(float(i)*.8)*16.0,float(i)*11.0)
				draw_line(clue+bend,clue+bend+Vector2(31,-17),Color("#c9b391"),4,true)
			draw_line(clue+Vector2(-18,-14),clue+Vector2(35,19),Color("#6d523c"),13,true)
		elif id == "bridge_map":
			_poly([clue+Vector2(-48,-42),clue+Vector2(41,-45),clue+Vector2(50,34),
				clue+Vector2(-37,41)],Color("#c9b388"))
			draw_polyline(PackedVector2Array([
				clue+Vector2(-26,21),clue+Vector2(-7,-12),
				clue+Vector2(13,8),clue+Vector2(31,-31)]),Color("#638273"),4,true)
		elif id == "heel_marks":
			for i in range(4):
				var step: Vector2 = clue+Vector2(-56+float(i)*31,-35+float(i)*21)
				draw_arc(step,13,.1,PI*1.82,12,Color("#312d2a"),5,true)
				draw_line(step+Vector2(-6,6),step+Vector2(6,13),Color("#4d4336"),6)
		else:
			_poly([clue+Vector2(-41,-38),clue+Vector2(43,-42),
				clue+Vector2(37,43),clue+Vector2(-43,36)],Color("#cfb38d"))
			for i in range(5):
				draw_line(clue+Vector2(-27,-24+float(i)*12),
					clue+Vector2(26,-21+float(i)*12),Color("#6e5d4b"),2)
		if story.clues.has(id):
			draw_circle(clue+Vector2(37,-39),10,Color("#8fa988"))
		else:
			draw_arc(clue,47,0,TAU,32,Color("#e6c686",.35),2.0)
	for id in Story.MARKERS:
		var mark: Vector2 = MARKERS_AT[id]
		var marked: bool = story.markers.has(id)
		draw_line(mark+Vector2(0,36),mark+Vector2(0,-92),Color("#59462f"),10,true)
		draw_line(mark+Vector2(-8,-86),mark+Vector2(64,-73),Color("#9d8153"),15,true)
		draw_line(mark+Vector2(-7,-88),mark+Vector2(64,-75),Color("#d4b482"),3)
		if marked:
			_poly([mark+Vector2(53,-72),mark+Vector2(92,-56),mark+Vector2(53,-39)],Color("#a4c9a4"))
	# False lights mimic rescue lanterns but stay visually separate from the
	# authentic stone-route evidence and never obscure its interaction area.
	if _stage() >= 2:
		for i in range(9):
			var false_light := FALSE_FORK + Vector2(85+float(i)*47.0,
				-42+sin(float(i)*2.1)*70.0)
			var sway := sin(particles*1.2+float(i))*7.0 if not prefs.reduced_motion else 0.0
			var point := false_light+Vector2(0,sway)
			draw_circle(point,40,Color(1.0,.52,.19,.018))
			draw_circle(point,21,Color(1.0,.54,.15,.06))
			draw_circle(point,7,Color("#efbb72",.28))
			draw_circle(point,3,Color("#ffdf9a",.90))
	# The flood-damaged ridge darkens the WORLD first; actors and the
	# actual witness are then rendered above that pass for mobile readability.
	if _stage() == 1:
		draw_rect(Rect2(-1250,-1100,2600,2400),Color(.20,.09,.04,.16))
	elif _stage() >= 2:
		draw_rect(Rect2(-1250,-1100,2600,2400),Color(.02,.045,.09,.42))
		for ring in range(4,0,-1):
			var r := 65.0+float(ring)*32.0
			draw_circle(player_pos+Vector2(0,-49),r,
				Color(1.0,.70,.32,.010+float(5-ring)*.009))
		draw_circle(SAFE_LOOKOUT+Vector2(-66,-74),160,Color(1.0,.64,.24,.075))
	# The ravine has its own horizontal mist plane, projected behind all
	# characters; it never hides a route-puzzle control or clue marker.
	if _stage() >= 1:
		Landscape.mist(self,Vector2(-65,430),560.0,particles,
			not prefs.reduced_motion,_stage()>=2)
	# Flood-watchpost is an isolated shelter, not a crowded house. Its
	# small window glows after dusk without adding a phantom outdoor NPC.
	if _stage() >= 2:
		NightWindows.paint_window(self,SAFE_LOOKOUT+Vector2(-38,-114),
			Vector2(36,40),3,true,particles,prefs.reduced_motion)
	# Full creature appears ONLY after the verified route; no day spoiler.
	if (story.phase == 4 and story.outcome == "") or debug_night_preview:
		var shift := sin(particles*.75)*4.0 if not prefs.reduced_motion else 0.0
		var witness := RIDGE_GATE+Vector2(-4,-255)
		for ring in range(4,0,-1):
			draw_circle(witness,75.0+float(ring)*36.0,
				Color(.68,.34,.16,.009+float(5-ring)*.006))
		# Maintain the original horse-human proportions while keeping both
		# horn tips in the landscape viewport at the closest QA camera pose.
		DimensionalArt.paint_grounded(self, TIKBALANG,
			RIDGE_GATE+Vector2(0,1+shift), Vector2(318,450),
			Color("#e0d6c6"), .50)
	# Keep original shared protagonists readable against darkness. Their
	# draw order is world-depth based and HUD/cinematic layers stay untouched.
	var actors := [
		{"at":bantay_pos+Vector2(0,19),"tex":BANTAY,"size":Vector2(95,104)},
		{"at":player_pos+Vector2(0,8),"tex":HERO,"size":Vector2(106,141)}
	]
	actors.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		return (a["at"] as Vector2).y < (b["at"] as Vector2).y)
	for actor in actors:
		var where: Vector2 = actor["at"]
		var dimensions: Vector2 = actor["size"]
		var is_player: bool = actor["tex"] == HERO
		var is_dog: bool = actor["tex"] == BANTAY
		var lift := 0.0
		if not prefs.reduced_motion and (is_player or is_dog):
			lift = absf(sin(walk_phase * (1.12 if is_dog else 1.0))) * (3.0 if is_player else 2.1) * walk_weight
		DimensionalArt.paint_grounded(self, actor["tex"], where, dimensions,
			Color.WHITE, .43, lift)
	PostgameResidents.paint(self,"night03",particles,prefs.reduced_motion,player_pos)
	# In-world wayfinding signs are small, correctly oriented and non-obstructive.
	var font := ThemeDB.fallback_font
	draw_string(font,ConnectedWorld.TRAIL_RIDGE+Vector2(-125,90),
		"OLD MANGO GROVE  /  RETURN",HORIZONTAL_ALIGNMENT_LEFT,410,18,Color("#e7d5a8"))
	draw_string(font,SAFE_LOOKOUT+Vector2(-120,138),
		"FLOOD WATCHPOST",HORIZONTAL_ALIGNMENT_LEFT,320,19,Color("#f1d89e"))
	draw_string(font,FALSE_FORK+Vector2(-108,107),
		"CHANGED WAYMARKS",HORIZONTAL_ALIGNMENT_LEFT,320,18,Color("#e3c592"))
	# Actual east-ridge footpath connects to the wake when Night 3 ends.
	# It remains physically gated during the first three story phases.
	draw_line(Vector2(890,-525),Vector2(890,-390),Color("#674e35"),12,true)
	draw_line(Vector2(848,-490),Vector2(946,-476),Color("#baa078"),14,true)
	draw_string(font,Vector2(745,-342),
		"THE WAKE • EAST TRAIL" if story.outcome != "" else "WAKE TRAIL • FINISH RIDGE FIRST",
		HORIZONTAL_ALIGNMENT_LEFT,445,17,Color("#e1bd86"))

func _build_ui() -> void:
	var atmosphere_layer := CanvasLayer.new()
	atmosphere_layer.layer = 5
	atmosphere_layer.name = "RidgeAtmosphere"
	add_child(atmosphere_layer)
	atmosphere = SharedAtmosphere.new()
	atmosphere_layer.add_child(atmosphere)
	hud = CanvasLayer.new()
	hud.name = "Night3HUD"
	hud.layer = 6
	add_child(hud)
	var layout := Control.new()
	layout.name = "Night3Screen"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(layout)
	gameplay_controls = Control.new()
	gameplay_controls.name = "GameplayControls"
	gameplay_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gameplay_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(gameplay_controls)
	var card: Dictionary = SharedHUD.create_status_card(gameplay_controls,"TABI-TABI  •  NIGHT 3 / TIKBALANG",prefs.text_scale)
	status_panel = card["panel"]
	status_stack = card["stack"]
	objective = card["objective"]
	status_stack.minimum_size_changed.connect(func(): call_deferred("_fit_card"))
	subtitle = Label.new()
	subtitle.name = "RidgeProgress"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size",roundi(18.0*prefs.text_scale))
	subtitle.add_theme_color_override("font_color",Color("#e8d3a4"))
	status_stack.add_child(subtitle)
	courage = Label.new()
	courage.name = "CourageStatus"
	courage.add_theme_font_size_override("font_size",roundi(18.0*prefs.text_scale))
	courage.add_theme_color_override("font_color",Color("#e0b785"))
	status_stack.add_child(courage)
	waypoint = Label.new()
	waypoint.name = "RouteCompass"
	waypoint.anchor_left = .42
	waypoint.anchor_right = .66
	waypoint.anchor_top = 0.02
	waypoint.anchor_bottom = .17
	waypoint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	waypoint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waypoint.add_theme_font_size_override("font_size",20)
	waypoint.add_theme_color_override("font_color",Color("#e1cc95"))
	gameplay_controls.add_child(waypoint)
	interaction_hint = SharedHUD.make_nearby_prompt(gameplay_controls,prefs.text_scale)
	observation_bar = ProgressBar.new()
	observation_bar.name = "WatchForFalseLights"
	observation_bar.anchor_left = .43
	observation_bar.anchor_right = .65
	observation_bar.anchor_top = .93
	observation_bar.anchor_bottom = .96
	observation_bar.show_percentage = false
	observation_bar.visible = false
	gameplay_controls.add_child(observation_bar)
	for entry in [
		["left","◀",Vector2(20,575)],["right","▶",Vector2(170,575)],
		["up","▲",Vector2(95,505)],["down","▼",Vector2(95,645)]
	]:
		var key: String = str(entry[0])
		var b := SharedHUD.make_gameplay_button(gameplay_controls,str(entry[1]),entry[2],
			Vector2(70,65),func(): _hold_move(key,true),func(): _hold_move(key,false),prefs.text_scale)
		b.name = "Move_"+key
		b.mouse_exited.connect(func(): _hold_move(key,false))
	var look := AimPad.new()
	look.name = "Night3LookPad"
	look.prompt_text = "LOOK AROUND"
	look.anchor_left = 1.0
	look.anchor_right = 1.0
	look.anchor_top = 1.0
	look.anchor_bottom = 1.0
	look.offset_left = -435.0
	look.offset_right = -260.0
	look.offset_top = -205.0
	look.offset_bottom = -40.0
	look.aim_changed.connect(func(direction: Vector2): look_direction=direction)
	look.aim_released.connect(func(): look_direction=Vector2.ZERO)
	gameplay_controls.add_child(look)
	var watch := _game_button("HOLD OBSERVE",Vector2(1050,490),Vector2(180,60),func(): pass)
	watch.button_down.connect(func(): observe_held=true)
	watch.button_up.connect(func(): observe_held=false)
	watch.mouse_exited.connect(func(): observe_held=false)
	_game_button("INTERACT",Vector2(1050,565),Vector2(180,60),_interact)
	_game_button("SAFE RETREAT",Vector2(1050,640),Vector2(180,56),_request_retreat)
	_game_button("FIELD NOTES",Vector2(1050,415),Vector2(180,56),_open_notebook)
	_game_button("PREPARE",Vector2(1050,276),Vector2(180,56),_open_safety_briefing)
	_game_button("SAVE",Vector2(1050,345),Vector2(85,52),_save_feedback)
	_game_button("RETRY",Vector2(1142,345),Vector2(88,52),_retry)
	buttons["OPTIONS"] = SharedHUD.make_options_button(gameplay_controls,_open_options,prefs.text_scale)
	modal_backdrop = ColorRect.new()
	modal_backdrop.name = "ModalDimmer"
	modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(modal_backdrop)
	modal_backdrop.hide()
	dialogue = PanelContainer.new()
	dialogue.name = "Night3Dialogue"
	dialogue.anchor_left = .08
	dialogue.anchor_right = .92
	dialogue.anchor_top = .44
	dialogue.anchor_bottom = .955
	SharedHUD.style_modal_panel(dialogue)
	layout.add_child(dialogue)
	var talk := VBoxContainer.new()
	talk.name = "Conversation"
	talk.add_theme_constant_override("separation",8)
	dialogue.add_child(talk)
	dialogue_speaker = Label.new()
	dialogue_speaker.name = "SpeakerName"
	dialogue_speaker.add_theme_color_override("font_color",Color("#f1cf92"))
	dialogue_speaker.add_theme_font_size_override("font_size",25)
	talk.add_child(dialogue_speaker)
	var scroll := ScrollContainer.new()
	scroll.name = "DialogueScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	talk.add_child(scroll)
	var row := HBoxContainer.new()
	row.name = "PortraitAndText"
	row.add_theme_constant_override("separation",20)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)
	dialogue_portrait = Portrait.new()
	dialogue_portrait.name = "SpeakerBustPortrait"
	dialogue_portrait.custom_minimum_size = Vector2(215,210)
	row.add_child(dialogue_portrait)
	creature_portrait = TextureRect.new()
	creature_portrait.name = "TikbalangPortrait"
	creature_portrait.texture = TIKBALANG
	creature_portrait.custom_minimum_size = Vector2(200,210)
	creature_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	creature_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(creature_portrait)
	dialogue_text = Label.new()
	dialogue_text.name = "DialogueText"
	dialogue_text.custom_minimum_size = Vector2(250,140)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_text.add_theme_font_size_override("font_size",roundi(25.0*prefs.text_scale))
	row.add_child(dialogue_text)
	dialogue_choices = VBoxContainer.new()
	dialogue_choices.name = "ChoiceButtons"
	dialogue_choices.add_theme_constant_override("separation",5)
	talk.add_child(dialogue_choices)
	dialogue.hide()
	notebook = PanelContainer.new()
	notebook.name = "Night3FieldNotes"
	notebook.anchor_left = .10
	notebook.anchor_right = .90
	notebook.anchor_top = .055
	notebook.anchor_bottom = .945
	SharedHUD.style_modal_panel(notebook)
	layout.add_child(notebook)
	var notes := VBoxContainer.new()
	notebook.add_child(notes)
	_label(notes,"FIELD NOTEBOOK  /  NIGHT 3",27,Color("#f1cf92"))
	var notes_scroll := ScrollContainer.new()
	notes_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notes.add_child(notes_scroll)
	notebook_body = Label.new()
	notebook_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notebook_body.custom_minimum_size = Vector2(620,500)
	notebook_body.add_theme_font_size_override("font_size",roundi(25.0*prefs.text_scale))
	notes_scroll.add_child(notebook_body)
	_modal_button(notes,"CLOSE NOTEBOOK",func(): _close_notebook())
	notebook.hide()
	options_panel = PanelContainer.new()
	options_panel.name = "Night3Options"
	options_panel.anchor_left = .18
	options_panel.anchor_right = .82
	options_panel.anchor_top = .15
	options_panel.anchor_bottom = .84
	SharedHUD.style_modal_panel(options_panel)
	layout.add_child(options_panel)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation",12)
	options_panel.add_child(menu)
	_label(menu,"NIGHT 3  /  PAUSE & OPTIONS",29,Color("#f2d6a4"))
	_modal_button(menu,"SAVE PROGRESS",_save_feedback)
	_modal_button(menu,"RETURN TO OLD MANGO (SAVE)",_return_to_mango)
	_modal_button(menu,"SAVE & MAIN MENU",_save_menu)
	_modal_button(menu,"BACK TO GAME",_close_options)
	options_panel.hide()
	ending_panel = PanelContainer.new()
	ending_panel.name = "Night3Aftermath"
	ending_panel.anchor_left = .20
	ending_panel.anchor_right = .80
	ending_panel.anchor_top = .13
	ending_panel.anchor_bottom = .86
	SharedHUD.style_modal_panel(ending_panel)
	layout.add_child(ending_panel)
	ending_panel.hide()
	save_error = AcceptDialog.new()
	save_error.title = "Save was not completed"
	save_error.dialog_text = "The offline record could not be written. Your story has NOT been switched."
	add_child(save_error)

func _fit_card() -> void:
	if status_panel != null and status_stack != null and is_inside_tree():
		var needed: float = status_stack.get_combined_minimum_size().y+28.0
		status_panel.offset_bottom = clampf(needed,150.0,get_viewport().get_visible_rect().size.y*.66)

func _label(parent: Control,message: String,font_size: int,color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = message
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size",font_size)
	lbl.add_theme_color_override("font_color",color)
	parent.add_child(lbl)
	return lbl

func _modal_button(parent: Control,label: String,callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.custom_minimum_size = Vector2(360,52)
	SharedHUD.style_modal_button(btn,false,true,prefs.text_scale)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _game_button(title: String,at: Vector2,dimensions: Vector2,callback: Callable) -> Button:
	var btn := SharedHUD.make_gameplay_button(gameplay_controls,title,at,dimensions,
		func():pass,func():pass,prefs.text_scale)
	btn.name = "Action_"+title.replace(" ","")
	btn.pressed.connect(callback)
	buttons[title] = btn
	return btn

func _hold_move(key: String,pressed: bool) -> void:
	held_moves[key] = pressed
	motion = Vector2(
		float(int(held_moves.get("right",false))-int(held_moves.get("left",false))),
		float(int(held_moves.get("down",false))-int(held_moves.get("up",false))))
	if motion.length() > 1.0:
		motion = motion.normalized()

func _next_target() -> Dictionary:
	var keys: Array = []
	var locations: Dictionary = {}
	if story.phase == 0:
		keys = Story.CLUES
		locations = CLUES_AT
	elif story.phase == 1:
		keys = Story.MARKERS
		locations = MARKERS_AT
	elif story.phase == 2:
		return {"point":SAFE_LOOKOUT,"name":"SAFE WATCHPOST"}
	elif story.phase == 3:
		return {"point":FALSE_FORK,"name":"FALSE SIGNS"}
	elif story.phase == 4:
		return {"point":RIDGE_GATE,"name":"TIKBALANG RIDGE"}
	else:
		return {}
	var closest := INF
	var output: Dictionary = {}
	for id in keys:
		if story.phase == 0 and story.clues.has(id):
			continue
		if story.phase == 1 and story.markers.has(id):
			continue
		var point: Vector2 = locations[id]
		if player_pos.distance_to(point) < closest:
			closest = player_pos.distance_to(point)
			output = {"point":point,"name":str(CLUE_LABELS.get(id,id.replace("_"," "))).to_upper()}
	return output

func _refresh_objective() -> void:
	if objective == null:
		return
	var titles := ["DAY  /  INVESTIGATE","DUSK  /  MARK SAFE WAY",
		"NIGHT  /  OBSERVE","NIGHT  /  CHECK THE FORK",
		"NIGHT  /  CONFRONT MEMORY","MORNING  /  AFTERMATH"]
	subtitle.text = "%s   •   CLUES %d/4   •   MARKERS %d/3" % [
		titles[clampi(story.phase,0,5)],story.clues.size(),story.markers.size()]
	match story.phase:
		0: objective.text = "Study FOUR clues about the Great Flood, displaced waymarks and missing rescuer."
		1: objective.text = "Follow the old flood map. Mark THREE safety points IN ORDER."
		2: objective.text = "At the shelter lookout, HOLD OBSERVE to separate real route from false lights."
		3: objective.text = "At the old fork, use the evidence to identify the ORIGINAL rescue route."
		4: objective.text = "Find the ridge guardian. Ask respectfully what happened to the lost rescue team."
		5: objective.text = "NIGHT 3 RECORDED • %s. Your witness account is preserved." % story.outcome.to_upper()
	_fit_card()

func _refresh_hint() -> void:
	if interaction_hint == null:
		return
	var target := _nearby()
	interaction_hint.text = "FOLLOW TRAIL • INTERACT near marked evidence" if target == "" else \
		"INTERACT • "+str(CLUE_LABELS.get(target,target.replace("_"," ").to_upper()))
	var next: Dictionary = _next_target()
	if next.is_empty():
		waypoint.text = "NIGHT 3 • FIELD RECORD COMPLETE"
		return
	var difference: Vector2 = next["point"]-player_pos
	var angle := atan2(difference.y,difference.x)
	var octant := posmod(roundi((angle+PI)/(PI/4.0)),8)
	var compass: String = ["←","↖","↑","↗","→","↘","↓","↙"][octant]
	if difference.length() < 122.0:
		compass = "◆"
	waypoint.text = compass+"  "+str(next["name"])+"\n%d STEPS" % roundi(difference.length()/11.0)

func _nearby() -> String:
	if player_pos.distance_to(ConnectedWorld.TRAIL_RIDGE) < 110.0:
		return "return_mango"
	if player_pos.distance_to(ConnectedWorld.TRAIL_RIDGE_WAKE) < 115.0:
		return "wake_gate" if story.outcome != "" else "wake_gate_locked"
	if story.phase == 0:
		for id in Story.CLUES:
			if not story.clues.has(id) and player_pos.distance_to(CLUES_AT[id]) < 122.0:
				return id
	elif story.phase == 1:
		for id in Story.MARKERS:
			if not story.markers.has(id) and player_pos.distance_to(MARKERS_AT[id]) < 122.0:
				return id
	elif story.phase == 2:
		if player_pos.distance_to(SAFE_LOOKOUT) < 140.0:
			return "observe"
	elif story.phase == 3:
		if player_pos.distance_to(FALSE_FORK) < 170.0:
			return "check_fork"
	elif story.phase == 4:
		if player_pos.distance_to(RIDGE_GATE) < 255.0:
			return "tikbalang"
	var postgame_neighbor := PostgameResidents.nearby(self,"night03",player_pos)
	if postgame_neighbor != "":
		return postgame_neighbor
	return ""

func _interact() -> void:
	if _modal_open() or travel_in_progress:
		return
	var target := _nearby()
	if target.begins_with("postgame:"):
		_show_dialogue(PostgameResidents.speaker(target),
			PostgameResidents.talk(self,target),
			[{"label":"SALAMAT • CONTINUE","action":"close"}])
		return
	if target == "return_mango":
		_return_to_mango()
		return
	if target == "wake_gate":
		_to_wake()
		return
	if target == "wake_gate_locked":
		_show_dialogue("BANTAY","The east trail leads to the wake. We must finish the ridge account before leaving its rescue signs unresolved.",
			[{"label":"RETURN TO THE RIDGE","action":"close"}])
		return
	if target == "":
		_show_dialogue("BANTAY","The trail is wide. Follow the compass toward the next tangible clue, safety marker or shelter.",
			[{"label":"FOLLOW WAYPOINT","action":"close"}])
		return
	if story.phase == 0:
		if story.inspect(target):
			_auto_save()
			_show_dialogue("FIELD OBSERVATION",str(CLUE_STORIES[target])+
				("\n\nThe four pieces now agree. Follow the map and mark the safe route before the mist comes in." if story.phase == 1 else ""),
				[{"label":"RECORD IN NOTEBOOK","action":"close"}])
	elif story.phase == 1:
		if story.mark_route(target):
			_auto_save()
			_show_dialogue("APPRENTICE","Safety marker placed at "+target.replace("_"," ")+". "+
				("All three are verified. Watch the false lights from the covered lookout." if story.phase == 2 else "Next waypoint is marked on the old flood map."),
				[{"label":"CONTINUE","action":"close"}])
		else:
			_show_dialogue("BANTAY","Not that one yet. Dado's map fixes the order: RIVER STONES → OLD WATCHPOST → BAMBOO DIVERSION. Do not lead others through unverified ground.",
				[{"label":"CHECK THE MAP","action":"close"}])
	elif story.phase == 2:
		_show_dialogue("FIELD NOTES","Stay beside the roofed watchpost and HOLD OBSERVE until the misleading ridge lights separate from the original safe route.",
			[{"label":"WATCH FROM SAFETY","action":"close"}])
	elif story.phase == 3:
		_show_route_puzzle()
	elif story.phase == 4:
		_show_guardian()
	_refresh_objective()

func _show_route_puzzle() -> void:
	_show_dialogue("THE THREE FALSE SIGNS",
		"One arrow is new blue paint, one points into hoof-shaped mud, and the oldest follows stone steps back to the river. Which matches the dated rescue map and the rope evidence?",
		[{"label":"FOLLOW OLD RIVER STONES","action":"river_stones"},
		{"label":"FOLLOW BLUE LANTERNS","action":"blue_lanterns"},
		{"label":"FOLLOW HOOFPRINTS","action":"hoofprints"}])

func _show_guardian() -> void:
	if not story.respectful:
		_show_dialogue("TIKBALANG",
			"The horse-headed figure stands beneath bending bamboo. 'The sign was moved during the flood. I guard a road people forgot, not the story they invented.' Will you speak respectfully?",
			[{"label":"TABİ-TABI PO • LISTEN","action":"greet"},
			{"label":"LEAVE WITHOUT ACCUSATIONS","action":"partial"}])
	elif not story.truth_recorded:
		_show_dialogue("TIKBALANG",
			"'The messenger did not vanish because of me. He changed the sign so children would not enter the washout. The missing names should have been written down.'",
			[{"label":"RECORD THE RESCUER'S ACCOUNT","action":"truth"},
			{"label":"MARK THE ROUTE AND LEAVE","action":"partial"}])
	else:
		_show_dialogue("BANTAY",
			"The old flood map, Dado's unfinished promise, the rope and the note belong to one event. Bring the evidence back without accusing anyone who cannot answer.",
			[{"label":"RESOLVE • REOPEN SAFE PASSAGE","action":"resolve"},
			{"label":"PARTIAL • KEEP MARKERS ONLY","action":"partial"}])

func _choose(action: String) -> void:
	_close_dialogue()
	match action:
		"close":
			pass
		"river_stones","blue_lanterns","hoofprints":
			if story.decide_route(action):
				_auto_save()
				_show_dialogue("BANTAY",
					"The original stone ford is real. The changed sign was meant as a warning, but its message was lost. A tall figure waits at the safe north ridge, not on the false path.",
					[{"label":"FOLLOW THE TRUE RIDGE PATH","action":"close"}])
			else:
				_show_dialogue("BANTAY",
					"That route contradicts the dated map and rope. No one is harmed permanently; return to the fork and compare the physical clues again.",
					[{"label":"RECHECK EVIDENCE","action":"close"}])
		"greet":
			if story.greet():
				_auto_save()
				_show_guardian()
		"truth":
			if story.record_truth():
				_auto_save()
				_show_guardian()
		"resolve","partial","retreat":
			if story.commit(action):
				_auto_save()
				_show_ending()
		"retry":
			_retry()
	_refresh_objective()

func _show_dialogue(who: String,message: String,choices: Array) -> void:
	held_moves.clear()
	motion = Vector2.ZERO
	observe_held = false
	notebook.hide()
	options_panel.hide()
	dialogue_speaker.text = who
	dialogue_text.text = message
	var is_creature := who.to_upper().contains("TIKBALANG")
	var role := who.to_upper()
	dialogue_portrait.visible = role.contains("LOLA") or role.contains("DADO") or role.contains("APPRENTICE") or role.contains("BANTAY") or role.contains("MARA")
	creature_portrait.visible = is_creature
	if dialogue_portrait.visible:
		dialogue_portrait.call("set_speaker",who)
	for child in dialogue_choices.get_children():
		dialogue_choices.remove_child(child)
		child.queue_free()
	for option in choices:
		var action: String = str(option["action"])
		var btn := _modal_button(dialogue_choices,str(option["label"]),func(): _press_choice(action))
		btn.name = "Choice_"+action
		if choices.size() >= 3:
			# The route-verification puzzle has three real choices. Preserve
			# all three readable touch buttons above the bottom screen edge.
			btn.custom_minimum_size = Vector2(360,50)
			btn.add_theme_font_size_override("font_size",roundi(20.0*prefs.text_scale))
	dialogue.anchor_top = .34 if choices.size() >= 3 else .44
	if is_creature:
		focus_point = RIDGE_GATE
	elif role.contains("BANTAY"):
		focus_point = bantay_pos
	else:
		focus_point = player_pos
	dialogue_focus = true
	SharedMotion.reveal_text(dialogue_text,prefs.reduced_motion)
	SharedMotion.reveal(dialogue,prefs.reduced_motion)
	_sync_hud()

func _press_choice(action: String) -> void:
	if SharedMotion.finish_text(dialogue_text):
		return
	_choose(action)

func _close_dialogue() -> void:
	dialogue_focus = false
	if dialogue != null:
		SharedMotion.conceal(dialogue,prefs.reduced_motion)
	_sync_hud()

func _open_notebook() -> void:
	if dialogue.visible or ending_panel.visible:
		return
	var text_notes := "NIGHT 3  /  TIKBALANG — THE FALSE TRAIL\n"
	text_notes += "NIGHT 1: %s  /  NIGHT 2: %s\n\n" % [story.night01_outcome,story.night02_outcome]
	text_notes += "OBSERVED EVIDENCE (no rumors as facts):\n"
	for id in Story.CLUES:
		text_notes += ("[RECORDED] " if story.clues.has(id) else "[MISSING] ")+str(CLUE_LABELS[id])+"\n"
	text_notes += "\nSAFE MAP ORDER:\n"
	for id in Story.MARKERS:
		text_notes += ("[MARKED] " if story.markers.has(id) else "[OPEN] ")+id.replace("_"," ").to_upper()+"\n"
	text_notes += "\nRIVER-STONE ROUTE: "+("VERIFIED" if story.route_verified else "UNVERIFIED")+"\n"
	text_notes += "FALSE PATH ATTEMPTS: %d\n" % story.false_turns
	text_notes += "\nThe Great Flood connected the old mooring, Kapre's dangerous tree, and an altered rescue sign. The inked missing names are still unresolved; do not invent a culprit."
	if story.outcome != "":
		text_notes += "\n\nNIGHT 3 ENDING: "+story.outcome.to_upper()
	notebook_body.text = text_notes
	notebook.show()
	_sync_hud()

func _close_notebook() -> void:
	notebook.hide()
	_sync_hud()

func _open_options() -> void:
	if dialogue.visible or notebook.visible or ending_panel.visible:
		return
	options_panel.show()
	_sync_hud()

func _close_options() -> void:
	options_panel.hide()
	_sync_hud()

func _open_safety_briefing() -> void:
	_show_dialogue("PREPARE • RIDGE SAFETY",
		"The only safe plan is to compare the original flood map with the rope and footprints; mark real crossings in order; shelter before observing lights. No weapons, bait, or running into the ravine are required.",
		[{"label":"UNDERSTOOD","action":"close"}])

func _request_retreat() -> void:
	if story.outcome != "":
		_show_ending()
		return
	_show_dialogue("SAFE EXIT",
		"You may stop the encounter without attacking the guardian. Recorded evidence remains in your notebook; the rescue mystery continues for later chapters.",
		[{"label":"CONTINUE INVESTIGATING","action":"close"},
		{"label":"WITHDRAW SAFELY","action":"retreat"}])

func _retry() -> void:
	if story.retry_checkpoint():
		player_pos = SAFE_LOOKOUT if story.phase >= 2 else ConnectedWorld.ARRIVAL_RIDGE
		_auto_save()
		_show_dialogue("BANTAY","You are back on safe ground. Your notes and honest route markers are intact. Follow the verified map; there is no need to chase a light.",
			[{"label":"TRY AGAIN","action":"close"}])
	else:
		_show_dialogue("FIELD RECORD","This chapter already has an ending; reopen the notebook or return to the mango grove.",
			[{"label":"CONTINUE","action":"close"}])

func _auto_save() -> bool:
	story.player_position = player_pos
	var success := Save.write(story)
	if success and story.outcome != "":
		ConnectedWorld.note_outcome(3,story.outcome)
	return success

func _save_feedback() -> void:
	if _auto_save():
		_close_options()
		_show_dialogue("FIELD RECORD","Night 3 saved offline. Santelmo and Kapre records are untouched.",
			[{"label":"CONTINUE","action":"close"}])
	else:
		save_error.popup_centered(Vector2i(610,190))

func _save_menu() -> void:
	if not _auto_save():
		save_error.popup_centered(Vector2i(610,190))
		return
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func _to_wake() -> void:
	if travel_in_progress or story.outcome == "":
		return
	if not _auto_save() or not ConnectedWorld.begin_travel("night03","night04",story.outcome):
		save_error.popup_centered(Vector2i(610,190))
		return
	travel_in_progress = true
	motion = Vector2.ZERO
	observe_held = false
	print("TABI_WORLD_TRAVEL_RIDGE_TO_WAKE")
	get_tree().change_scene_to_file(ConnectedWorld.scene_for("night04"))

func _return_to_mango() -> void:
	if travel_in_progress:
		return
	if not _auto_save() or not ConnectedWorld.begin_travel("night03","old_mango",story.outcome):
		save_error.popup_centered(Vector2i(610,190))
		return
	travel_in_progress = true
	motion = Vector2.ZERO
	observe_held = false
	print("TABI_WORLD_TRAVEL_RIDGE_TO_MANGO")
	get_tree().change_scene_to_file(ConnectedWorld.scene_for("old_mango"))

func _show_ending() -> void:
	ending_panel.show()
	observe_held = false
	var area := ending_panel.get_node_or_null("AftermathContent") as VBoxContainer
	if area == null:
		area = VBoxContainer.new()
		area.name = "AftermathContent"
		area.add_theme_constant_override("separation",10)
		ending_panel.add_child(area)
	for item in area.get_children():
		area.remove_child(item)
		item.queue_free()
	_label(area,"NIGHT 3  /  WHAT THE RIDGE REMEMBERS",28,Color("#eacb95"))
	var message := ""
	match story.outcome:
		"resolve":
			message = "The river-stone route is mapped and the false sign removed. You listened without accusing the guardian. The lost rescuer's words are recorded, but the Great Flood's missing names demand further answers.\n\nThe ridge opens its safe passage for the families."
		"partial":
			message = "The original passage is now verified and marked, but the guardian's full account is not yet settled. The village can keep walkers away from the false lights while the rescue records are reviewed."
		_:
			message = "You withdrew without chasing the lights or risking the ravine. Honest notes remain, but the false route is still a concern for the community."
	_label(area,message,23,Color("#f0e4cf"))
	_label(area,"RECORDED • TIKBALANG BESTIARY • ONE CONNECTED STORY",19,Color("#a8c8aa"))
	_modal_button(area,"REVIEW FIELD NOTES",func():
		ending_panel.hide()
		_open_notebook()
	)
	_modal_button(area,"WALK THE EAST TRAIL TO NIGHT 4",func():
		ending_panel.hide()
		player_pos = ConnectedWorld.TRAIL_RIDGE_WAKE+Vector2(-195,30)
		camera.position = player_pos
		_sync_hud()
	)
	_modal_button(area,"RETURN TO OLD MANGO (SAVE)",_return_to_mango)
	_modal_button(area,"SAVE & MAIN MENU",_save_menu)
	_sync_hud()
