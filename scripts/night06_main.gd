extends Node2D
## Tabi-tabi • Night 6 / What the Water Took.
## Authored connected river chapter. Historical reconstructions are source-backed
## hypotheses; environmental memory neither summons souls nor reveals facts.
const Story = preload("res://scripts/narrative/night06_state.gd")
const Save = preload("res://scripts/core/night06_save.gd")
const Night05State = preload("res://scripts/narrative/night05_state.gd")
const Night05Save = preload("res://scripts/core/night05_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
const Prefs = preload("res://scripts/core/preferences.gd")
const RiverSound = preload("res://scripts/audio/night06_ambience.gd")
const SharedHUD = preload("res://scripts/ui/shared_hud.gd")
const SharedOptions = preload("res://scripts/ui/shared_options.gd")
const Walkability = preload("res://scripts/world/shared_walkability_2d.gd")
const PostgameResidents = preload("res://scripts/world/postgame_residents.gd")
const PostgameDialogue = preload("res://scripts/narrative/postgame_dialogue.gd")
const DialogueMotion = preload("res://scripts/ui/shared_dialogue_motion.gd")
const Depth = preload("res://scripts/visuals/layered_25d.gd")
const Landscape = preload("res://scripts/visuals/folklore_landscape_25d.gd")
const Windows = preload("res://scripts/visuals/nighttime_windows.gd")
const AimPad = preload("res://scripts/ui/aim_pad.gd")
const HERO: Texture2D = preload("res://assets/characters/apprentice.svg")
const BANTAY: Texture2D = preload("res://assets/characters/bantay.svg")
const MARA: Texture2D = preload("res://assets/characters/mara.svg")
const DADO: Texture2D = preload("res://assets/characters/dado.svg")
const SABEL: Texture2D = preload("res://assets/characters/sabel.svg")
const LOLA: Texture2D = preload("res://assets/characters/lola.svg")
const TREE: Texture2D = preload("res://assets/world/mangrove_illustrated.svg")
const BANANA: Texture2D = preload("res://assets/world/banana_plant.svg")
const LANTERN: Texture2D = preload("res://assets/world/lantern_post.svg")
const WATER: Texture2D = preload("res://assets/world/tidal_water.svg")
const ROOF: Texture2D = preload("res://assets/world/nipa_thatch_roof.svg")
const SOIL: Texture2D = preload("res://assets/world/soil_ground.svg")
const MAP := Rect2(-1160,-815,2470,1630)
const RETURN_FARM := Vector2(-1040,-480)
const ARCHIVE := Vector2(-580,-277)
const TABLE := Vector2(-170,-90)
const MARA_AT := Vector2(-628,-255)
const DADO_AT := Vector2(-475,175)
const SABEL_AT := Vector2(362,-258)
const LOLA_AT := Vector2(-160,-312)
const CLUE_POS := {
	"rescue_order":Vector2(-705,-85),"flood_gauge":Vector2(180,175),
	"evacuation_roll":Vector2(-382,-260),"alternatives_log":Vector2(-310,50)
}
const ROUTE_POS := {
	"official_dock":Vector2(-425,80),"far_bank":Vector2(-162,104),
	"shelter_return":Vector2(85,115)
}
const IDENTITY_POS := {
	"family_boat_mark":Vector2(258,-175),"survivor_account":Vector2(-540,192)
}
const PREP_POS := {
	"rope_anchor":Vector2(-40,182),"lantern_beacon":Vector2(266,186),
	"safe_stones":Vector2(488,224)
}
const STEPS := [
	Vector2(270,275),Vector2(475,363),Vector2(690,458)
]
const PLAYER_SPEED := 245.0
const SCENE_STYLE := "shared-2.5d-layered-v1"
var story = Story.new()
var prefs = Prefs.new()
var player_pos := Story.START
var bantay_pos := Story.START+Vector2(-47,26)
var camera: Camera2D
var ambient
var indoor_seconds := 0.0
var hud: CanvasLayer
var controls: Control
var status_panel: PanelContainer
var status_stack: VBoxContainer
var objective: Label
var subtitle: Label
var pressure: Label
var waypoint: Label
var interaction_hint: Label
var dialogue: PanelContainer
var dialogue_speaker: Label
var dialogue_body: Label
var choices: VBoxContainer
var notes: PanelContainer
var notes_text: Label
var options: PanelContainer
var ending: PanelContainer
var backdrop: ColorRect
var meter: ProgressBar
var save_error: AcceptDialog
var move_axis := Vector2.ZERO
var held: Dictionary = {}
var aim := Vector2.ZERO
var observe_held := false
var walk_time := 0.0
var walk_weight := 0.0
var clock := 0.0
var travel_in_progress := false
var qa_river_preview := false
var unsafe_notice_cooldown := 0.0

func _ready() -> void:
	name = "TabiTabiNight6"
	set_meta("dimensional_art",SCENE_STYLE)
	set_meta("canon","what-the-water-took-v1")
	prefs.load_from()
	var prev = Night05State.new()
	if Night05Save.read(prev):
		story.night01_outcome = prev.night01_outcome
		story.night02_outcome = prev.night02_outcome
		story.night03_outcome = prev.night03_outcome
		story.night04_outcome = prev.night04_outcome
		story.night05_outcome = prev.outcome
	Save.read(story)
	player_pos = story.player_position
	var arrival: Dictionary = World.consume_arrival("night06")
	if str(arrival.get("from","")) == "night05":
		player_pos = Story.START
	elif str(arrival.get("from","")) == "night07":
		player_pos = World.ARRIVAL_RIVER_BALETE
		print("TABI_WORLD_ARRIVAL_RIVER_FROM_BALETE")
	# Recover legacy saves from inside decorative walls and trunks.
	player_pos = Walkability.repair_saved_position(6,player_pos,_flood_rise())
	camera = Camera2D.new()
	camera.name = "Night06RiverCamera"
	camera.position = player_pos
	camera.enabled = true
	camera.position_smoothing_enabled = not prefs.reduced_motion
	camera.position_smoothing_speed = 4.5
	camera.zoom = Vector2(1.02,1.02)
	add_child(camera)
	indoor_seconds = 3.3 if _stage() >= 2 else 0.0
	ambient = RiverSound.new()
	ambient.name = "UnfinishedRiverAndRopeSound"
	add_child(ambient)
	ambient.set_audio_level(prefs.audio_level)
	_build_ui()
	_refresh()
	var postgame_ready := get_node_or_null("/root/PostgameClock")
	if story.outcome != "" and not (postgame_ready != null and postgame_ready.is_active()):
		_show_ending()
	elif story.phase == 0 and story.clues.is_empty():
		_talk("MARA • THE RIVER WITHOUT RAIN",
			"The old crossing is rising without rainfall. Twenty-eight years ago, the records of a second rescue stopped making sense. We will read the physical sources before judging anyone.",
			[{"label":"FOLLOW THE ARCHIVE ROAD","action":"close"}])
	print("NIGHT6_QA_SCENE_READY")

func _stage() -> int:
	var free_roam_clock := get_node_or_null("/root/PostgameClock")
	if free_roam_clock != null and free_roam_clock.is_active():
		return free_roam_clock.light_stage()
	if qa_river_preview or story.phase in [5,6]: return 3
	if story.phase == 7: return 0
	return 1 if story.phase in [3,4] else 0

func _modal() -> bool:
	return dialogue.visible or notes.visible or options.visible or ending.visible

func _safe_corridor(p: Vector2) -> bool:
	# Dry land or the drawn stone route only. No story-phase water shortcut.
	return not Walkability.river_blocked(6,p,_flood_rise())

func _process(delta: float) -> void:
	var village_clock := get_node_or_null("/root/PostgameClock")
	if village_clock != null and village_clock.is_active() and objective != null:
		var free_roam_status := "FREE ROAM • RIVER CROSSING • FISHING & REPAIRS\n%s  |  %s" % [
			village_clock.clock_label(),
			"RESTORED" if village_clock.village_mood == "restored" else "REBUILDING"
		]
		if objective.text != free_roam_status:
			objective.text = free_roam_status
	clock += delta if not prefs.reduced_motion else 0.0
	if _stage() >= 2:
		indoor_seconds = minf(3.3,indoor_seconds+delta)
	else:
		indoor_seconds = 0.0
	if ambient != null:
		ambient.set_stage(_stage())
		ambient.set_risk(story.tension)
	unsafe_notice_cooldown = maxf(0.0,unsafe_notice_cooldown-delta)
	var axis := (Input.get_vector("ui_left","ui_right","ui_up","ui_down")+move_axis).limit_length()
	if _modal() or travel_in_progress: axis = Vector2.ZERO
	walk_weight = lerpf(walk_weight,1.0 if axis.length()>.05 else 0.0,
		1.0 if prefs.reduced_motion else clampf(delta*8.0,0.0,1.0))
	if axis.length() > .05:
		if not prefs.reduced_motion: walk_time += delta*9.0
		var foot := player_pos
		var world_axis := Vector2(axis.x+axis.y*.42,axis.y*.78-axis.x*.15).normalized()
		var candidate := player_pos+world_axis*PLAYER_SPEED*delta
		candidate.x = clampf(candidate.x,MAP.position.x+55,MAP.end.x-55)
		candidate.y = clampf(candidate.y,MAP.position.y+70,MAP.end.y-55)
		# Actual adjacent Night 7 is now a walkable road. The crossing remains
		# gated until a genuine Night 6 outcome is saved (never by fake UI).
		if story.outcome == "" and not _postgame_active():
			if candidate.x > 890 and candidate.y > 318 and candidate.y < 570:
				candidate.x = minf(candidate.x,887.0)
		if candidate.y > 240 and story.phase < 6:
			candidate.y = 238.0
		if story.phase == 6 and candidate.y > 240:
			var max_y: float = STEPS[story.step_index].y+88.0
			if not _safe_corridor(candidate) or candidate.y > max_y:
				candidate = foot
				if unsafe_notice_cooldown <= 0:
					story.unsafe_current()
					unsafe_notice_cooldown = 1.5
					_refresh()
		elif story.phase == 7 and story.outcome == "" and candidate.y > 575:
			candidate.y = 575
		var resolved := Walkability.slide(6,foot,candidate,_flood_rise())
		if story.phase == 6 and candidate.distance_to(resolved)>8.0 \
				and Walkability.river_blocked(6,candidate,_flood_rise()) \
				and unsafe_notice_cooldown <= 0.0:
			story.unsafe_current()
			unsafe_notice_cooldown = 1.5
			_refresh()
		player_pos = resolved
	var dog_goal := bantay_pos.lerp(player_pos+Vector2(-53,28),clampf(delta*3.5,0.0,1.0))
	bantay_pos = Walkability.slide(6,bantay_pos,dog_goal,_flood_rise())
	var target := player_pos+aim*48.0
	if story.phase == 6 or qa_river_preview:
		target = player_pos.lerp(Vector2(475,300),.16)+aim*34.0
	camera.position = camera.position.lerp(target,1.0 if prefs.reduced_motion else clampf(delta*4.6,0,1))
	var target_zoom := Vector2(.84,.84) if story.phase == 6 or qa_river_preview else Vector2(1.02,1.02)
	camera.zoom = camera.zoom.lerp(target_zoom,1.0 if prefs.reduced_motion else clampf(delta*3.4,0,1))
	if not _modal() and player_pos.distance_to(RETURN_FARM)<64:
		_return_farm()
		return
	if story.phase == 6 and not _modal():
		if story.observe_tick(delta,player_pos.distance_to(STEPS[story.step_index])<117,
				observe_held,prefs.story_assist):
			observe_held = false
			_save_story()
			_show_current_choices()
		elif story.encounter_failed:
			observe_held = false
			_talk("BANTAY • HIGH WATER",
				"The river surged. We are still safe on the marked stones; nobody was lost. Retry this one crossing step, or leave with a partial report.",
				[{"label":"RETRY THIS SAFE STONE","action":"retry_current"},
				{"label":"RETREAT WITH THE RECORD","action":"retreat"}])
	if meter != null:
		meter.visible = story.phase == 6 and not story.current_ready
		meter.value = story.observation*100.0
	if pressure != null:
		pressure.text = "RIVER CURRENT %d%%  •  SOURCES %d/4  •  SAFE STEPS %d/3" % [
			roundi(story.tension*100.0),story.clues.size(),story.step_index]
	_refresh_hint()
	queue_redraw()

func _draw_house(foot: Vector2,width: float,night: bool,lit: bool) -> void:
	var w := width
	# Three real projected wall/roof planes; foot, door and shadow align.
	# Buildings cast a thin ground footprint, never an enormous circular
	# black disk behind actors and windows during daytime.
	Depth.paint_contact_shadow(self,foot+Vector2(10,5),w*1.5,.23)
	draw_colored_polygon(PackedVector2Array([
		foot+Vector2(-w*.48,-w*.30),foot+Vector2(0,-w*.53),
		foot+Vector2(0,-w*1.07),foot+Vector2(-w*.48,-w*.82)]),Color("#8a816b"))
	draw_colored_polygon(PackedVector2Array([
		foot+Vector2(0,-w*.53),foot+Vector2(w*.49,-w*.78),
		foot+Vector2(w*.49,-w*1.27),foot+Vector2(0,-w*1.07)]),Color("#5d625b"))
	draw_colored_polygon(PackedVector2Array([
		foot+Vector2(-w*.57,-w*.83),foot+Vector2(-w*.06,-w*1.37),
		foot+Vector2(w*.55,-w*1.20),foot+Vector2(0,-w*.88)]),Color("#4e564b"))
	draw_colored_polygon(PackedVector2Array([
		foot+Vector2(-w*.60,-w*.86),foot+Vector2(-w*.05,-w*1.40),
		foot+Vector2(w*.03,-w*1.24),foot+Vector2(-w*.48,-w*.77)]),Color("#9b8563"))
	draw_line(foot+Vector2(-w*.55,-w*.84),foot+Vector2(-w*.06,-w*1.37),
		Color("#c2a37b"),4.0,true)
	draw_rect(Rect2(foot+Vector2(-w*.23,-w*.72),Vector2(w*.19,w*.42)),Color("#493e34"))
	draw_rect(Rect2(foot+Vector2(-w*.28,-w*.27),Vector2(w*.36,7)),Color("#b5a589"))
	# Bamboo-lath and braced side-wall detail follows the wall's angle.
	for i in range(5):
		var layer := float(i)
		draw_line(foot+Vector2(-w*.44,-w*(.72-layer*.072)),
			foot+Vector2(-w*.06,-w*(.95-layer*.072)),
			Color(.86,.75,.56,.48),2.0,true)
	draw_line(foot+Vector2(w*.06,-w*.60),foot+Vector2(w*.45,-w*.83),
		Color("#a6a08a"),3.0,true)
	draw_line(foot+Vector2(w*.17,-w*.55),foot+Vector2(w*.17,-w*1.02),
		Color("#868674"),3.0,true)
	Windows.paint_window(self,foot+Vector2(w*.27,-w*.84),
		Vector2(w*.20,w*.20),0 if lit else 2,night,clock,prefs.reduced_motion)

func _nearest_evidence() -> Vector2:
	# Exactly one nearby plaque can open in the world, even when documented
	# sources stand close together. Distant landmarks remain small pins.
	var sites: Array[Vector2] = []
	if story.phase <= 1:
		for id in Story.CLUES: sites.append(CLUE_POS[id])
	elif story.phase == 2:
		for id in Story.ROUTE: sites.append(ROUTE_POS[id])
	elif story.phase == 3:
		for id in Story.IDENTITY: sites.append(IDENTITY_POS[id])
	var nearest := Vector2(INF,INF)
	var best := 216.0
	for at in sites:
		var distance: float = player_pos.distance_to(at)
		if distance < best:
			best = distance
			nearest = at
	return nearest

func _paint_evidence(at: Vector2,name: String,read: bool) -> void:
	# Real nearby inspection marker, never a wall of floating text over
	# walkways or the Night 1 HUD. Distant sources remain identifiable by compass.
	draw_circle(at+Vector2(0,5),28,Color(.02,.06,.06,.22))
	draw_circle(at-Vector2(0,20),20,
		Color("#759e87") if read else Color("#e6ce8c"))
	draw_circle(at-Vector2(0,20),9,Color("#263f47"))
	if player_pos.distance_to(at) > 215.0 or at != _nearest_evidence():
		return
	var plaque_width: float = clampf(float(name.length())*8.5+22,100.0,198.0)
	var plate := Rect2(at+Vector2(-plaque_width*.5,10),Vector2(plaque_width,27))
	draw_rect(plate,Color(.055,.15,.17,.90))
	draw_rect(plate,Color("#c8a36b"),false,1.5)
	draw_string(ThemeDB.fallback_font,plate.position+Vector2(9,19),
		name,HORIZONTAL_ALIGNMENT_LEFT,plaque_width-18,14,Color("#f7e6bd"))

func _paint_old_rescue_banca(foot: Vector2) -> void:
	# Abandoned rescue boat grounded by a real contact shadow, angled hull,
	# visible ribs, tied outrigger and dry planks. NOT a floating prop.
	draw_colored_polygon(PackedVector2Array([
		foot+Vector2(-121,17),foot+Vector2(-72,37),
		foot+Vector2(91,34),foot+Vector2(125,-10),
		foot+Vector2(52,-40),foot+Vector2(-84,-37)]),Color("#544335"))
	draw_colored_polygon(PackedVector2Array([
		foot+Vector2(-118,4),foot+Vector2(-69,22),
		foot+Vector2(84,21),foot+Vector2(115,-14),
		foot+Vector2(49,-43),foot+Vector2(-84,-40)]),Color("#aa865c"))
	draw_colored_polygon(PackedVector2Array([
		foot+Vector2(-80,-30),foot+Vector2(50,-34),
		foot+Vector2(88,-10),foot+Vector2(-60,-4)]),Color("#6b5946"))
	for i in range(5):
		var x := float(i)*28.0-56.0
		draw_line(foot+Vector2(x,-27),foot+Vector2(x+15,1),
			Color("#bd9d71"),4,true)
	for side in [-1.0,1.0]:
		draw_line(foot+Vector2(-64,side*20),foot+Vector2(93,side*41),
			Color("#6d5945"),6,true)
		draw_line(foot+Vector2(-78,side*52),foot+Vector2(110,side*59),
			Color("#aa8a61"),5,true)
	draw_line(foot+Vector2(-4,-22),foot+Vector2(20,-90),
		Color("#907355"),5.0,true)
	draw_line(foot+Vector2(20,-90),foot+Vector2(90,-30),
		Color(.84,.81,.67,.32),2.0,true)


func _flood_rise() -> float:
	# Source-backed danger becomes visible before any confrontation. It rises
	# despite a dry sky, then recedes at dawn; never randomizes navigation.
	if qa_river_preview: return 23.0
	if story.phase <= 1: return 2.0
	if story.phase == 2: return 8.0
	if story.phase == 3: return 12.0
	if story.phase == 4: return 16.0
	if story.phase in [5,6]: return 23.0
	return 5.0

func _paint_archive_props() -> void:
	# Each investigation source has a distinct, physical-scale object, not
	# four indistinguishable floating beacons. Draw only in relevant phases.
	for id in Story.CLUES:
		var at: Vector2 = CLUE_POS[id]
		var wood := Color("#826649")
		if id == "flood_gauge":
			# Real marked gauge on the bank; the moving waterline can be read.
			draw_rect(Rect2(at+Vector2(-13,-136),Vector2(24,139)),Color("#3d453c"))
			draw_rect(Rect2(at+Vector2(-8,-130),Vector2(14,130)),Color("#d7c4a1"))
			for tick in range(9):
				var ty: float = at.y-116.0+float(tick)*13.2
				draw_line(Vector2(at.x-6,ty),Vector2(at.x+4 if tick%2 else at.x+9,ty),
					Color("#58675b"),2.0,true)
			var rising := clampf(_flood_rise()/26.0,0,1)
			draw_rect(Rect2(at+Vector2(-7,-rising*90.0),
				Vector2(13,rising*90.0)),Color(.19,.54,.62,.42))
		elif id == "rescue_order":
			draw_rect(Rect2(at+Vector2(-32,-89),Vector2(64,74)),wood)
			draw_rect(Rect2(at+Vector2(-25,-83),Vector2(52,59)),Color("#ddd0a7"))
			for line in range(4):
				draw_line(at+Vector2(-18,-72+float(line)*12),
					at+Vector2(18,-72+float(line)*12),Color("#8a7a60"),2.0,true)
			draw_circle(at+Vector2(9,-32),7,Color("#9d5447"))
		elif id == "evacuation_roll":
			draw_colored_polygon(PackedVector2Array([
				at+Vector2(-32,-26),at+Vector2(21,-43),
				at+Vector2(47,-20),at+Vector2(-9,-4)]),wood)
			draw_colored_polygon(PackedVector2Array([
				at+Vector2(-27,-31),at+Vector2(18,-46),
				at+Vector2(38,-36),at+Vector2(-10,-15)]),Color("#e2cfa1"))
			for line in range(3):
				draw_line(at+Vector2(-18,-29+float(line)*5),
					at+Vector2(11,-36+float(line)*5),Color("#847457"),1.8,true)
		else:
			# Alternative-route board on its own stake, facing the path.
			draw_line(at+Vector2(-4,4),at+Vector2(-4,-78),wood,8,true)
			draw_colored_polygon(PackedVector2Array([
				at+Vector2(-46,-85),at+Vector2(40,-91),
				at+Vector2(45,-40),at+Vector2(-42,-34)]),Color("#a68b68"))
			draw_line(at+Vector2(-35,-69),at+Vector2(10,-51),Color("#4c7270"),5,true)
			draw_circle(at+Vector2(20,-53),6,Color("#e2cfa0"))

func _paint_river_landmarks(night: bool) -> void:
	# Original weathered rescue pier and snapped mooring posts establish scale.
	# These posts are on the wet bank, not invisible walls over the road.
	for post in [
		Vector2(-837,259),Vector2(-765,272),Vector2(-682,277),
		Vector2(36,256),Vector2(126,265),Vector2(795,350)
	]:
		draw_circle(post+Vector2(7,11),22,Color(.02,.06,.07,.26))
		draw_colored_polygon(PackedVector2Array([
			post+Vector2(-10,-37),post+Vector2(2,-43),
			post+Vector2(16,-29),post+Vector2(16,7),
			post+Vector2(0,13),post+Vector2(-10,3)]),Color("#695944"))
		draw_line(post+Vector2(-8,-34),post+Vector2(1,-40),
			Color("#b3a17f"),3,true)
	# Off-road low stone flood berm. It preserves the whole walkable return
	# road and makes the watercourse's edge physically legible.
	for i in range(12):
		var n := float(i)
		var at := Vector2(-1050.0+n*152.0,186.0+sin(n*.74)*17.0)
		if at.distance_to(Vector2(180,185)) < 135:
			continue
		Landscape.rock(self,at,20.0+float(i%4)*5.0,not night)
	# Tangled flood timber follows the current instead of becoming a boss.
	for at in [Vector2(-970,459),Vector2(-412,505),Vector2(105,615),Vector2(845,670)]:
		draw_line(at,at+Vector2(86,-16),Color("#6b6853"),7.0,true)
		draw_line(at+Vector2(39,-8),at+Vector2(69,-29),Color("#a09b79"),3.5,true)

func _paint_hill_checkpoint(night: bool) -> void:
	# Readable physical continuation toward Balete Grounds (Night 7). The
	# locked rope is a genuine threshold, never an apparently cut-off road.
	var trail := PackedVector2Array([
		Vector2(735,470),Vector2(883,442),
		Vector2(1019,405),Vector2(1215,286)])
	Landscape.raised_trail(self,trail,74.0,Color("#34463c"),Color("#a48e6c"))
	for at in [Vector2(884,420),Vector2(1001,397)]:
		draw_circle(at+Vector2(5,8),21,Color(.03,.04,.03,.26))
		draw_line(at,at+Vector2(-1,-72),Color("#81684b"),12,true)
		draw_circle(at+Vector2(-1,-75),10,Color("#bca17a"))
	if story.outcome == "" and not _postgame_active():
		draw_line(Vector2(884,354),Vector2(1000,332),Color("#b8a37c"),5.0,true)
		draw_line(Vector2(884,359),Vector2(1000,337),
			Color("#655346"),2.5,true)
	if story.outcome != "":
		draw_rect(Rect2(942,257,202,54),Color(.09,.20,.20,.90))
		draw_rect(Rect2(942,257,202,54),Color("#bfa87c"),false,2)
		draw_string(ThemeDB.fallback_font,Vector2(953,278),
			"BALETE GROUNDS",HORIZONTAL_ALIGNMENT_LEFT,185,15,Color("#f0e4bd"))
		draw_string(ThemeDB.fallback_font,Vector2(953,297),
			"NIGHT 7 • OPEN",HORIZONTAL_ALIGNMENT_LEFT,185,13,Color("#e1b99b"))
	if night:
		draw_circle(Vector2(980,350),37,Color(.90,.68,.36,.04))

func _draw() -> void:
	var night := _stage()>=2
	draw_rect(MAP.grow(220),Color("#233e3a"))
	Landscape.parallax_ridges(self,MAP.grow(200),camera.position,6,_stage())
	# River terraces have gentle elevation and clay color; do not paint a
	# completely uniform green field in front of the mountain skyline.
	for strip in range(22):
		var t: float = float(strip)/21.0
		var ground := Color("#3c5b52").lerp(Color("#66755b"),t)
		draw_rect(Rect2(-2460,-720+float(strip)*45,4970,47),ground)
	draw_texture_rect(SOIL,Rect2(-2250,-735,4600,1590),false,Color(1,1,1,.25))
	# Terrain relief and river-cut gullies, never fake square biome borders.
	for i in range(17):
		var n := float(i)
		var earth := Vector2(-1130+n*153.0,-540+sin(n*1.71)*54.0)
		draw_colored_polygon(PackedVector2Array([
			earth+Vector2(-70,12),earth+Vector2(-24,-18),
			earth+Vector2(49,-13),earth+Vector2(100,18),
			earth+Vector2(34,29)]),Color(.18,.27,.22,.14))
	var road := PackedVector2Array([
		RETURN_FARM,Vector2(-875,-370),Vector2(-675,-178),
		Vector2(-425,-65),Vector2(-115,88),Vector2(180,185)])
	Landscape.raised_trail(self,road,82.0,Color("#334740"),Color("#ad9977"))
	Landscape.trail_stones(self,RETURN_FARM,Vector2(-425,-65),17,80,night)
	# Low river terrace: actual water surface is downriver of the safe bank.
	var raised: float = _flood_rise()
	var shore := PackedVector2Array([
		Vector2(-1200,231-raised),Vector2(-785,220-raised),
		Vector2(-375,238-raised),Vector2(60,220-raised),
		Vector2(310,235-raised),Vector2(530,270-raised),
		Vector2(835,308-raised),Vector2(1340,285-raised)])
	var water_region := PackedVector2Array([
		shore[0],shore[1],shore[2],shore[3],shore[4],shore[5],shore[6],shore[7],
		Vector2(1350,835),Vector2(-1250,835)])
	draw_colored_polygon(water_region,Color("#1d4f59") if night else Color("#3b7778"))
	draw_texture_rect(WATER,Rect2(-1160,250-raised,2500,560+raised),
		false,Color(1,1,1,.21))
	Landscape.riverbank_relief(self,shore,night)
	# Short drifting water-ripple clusters keep the stream visibly alive,
	# instead of parallel full-screen ruler lines.
	for i in range(105):
		var n := float(i)
		var xx := -1145.0+float(i%15)*169.0+sin(n*1.71)*37.0
		var yy := 310.0+float(i/15)*69.0+cos(n*2.13)*17.0
		var drift := 0.0 if prefs.reduced_motion else sin(clock*.76+n)*11.0
		draw_line(Vector2(xx+drift,yy),Vector2(xx+drift+40.0+float(i%3)*13.0,yy-4.0),
			Color(.72,.89,.83,.08+(float(i%3)*.018)),2.0,true)
	_paint_river_landmarks(night)
	# Reeds, river stones and wet-bank shadows stay OFF the walkable road.
	for i in range(18):
		var n := float(i)
		var bank_foot := Vector2(-1090+n*135.0,212.0+sin(n*.81)*22.0)
		if i % 3 != 0:
			Landscape.reeds(self,bank_foot,49.0,clock*.27+n,night)
		else:
			Landscape.rock(self,bank_foot,21.0,not night)
	# The raised opposite bank is visible beyond the crossing, not a void.
	draw_colored_polygon(PackedVector2Array([
		Vector2(790,520),Vector2(1110,485),Vector2(1330,550),
		Vector2(1360,820),Vector2(780,830)]),Color("#536b58"))
	_paint_chapter_people(true)
	for foot in [Vector2(-1020,-245),Vector2(-880,-550),Vector2(1020,-340),Vector2(1150,180)]:
		Depth.paint_grounded(self,TREE,foot,Vector2(233,268),Color("#c0c6a8"),.20)
	for foot in [Vector2(-790,-270),Vector2(940,-130)]:
		Depth.paint_grounded(self,BANANA,foot,Vector2(125,188),Color("#c6cda9"),.18)
	_draw_house(ARCHIVE+Vector2(0,-24),225,night,false)
	_draw_house(SABEL_AT+Vector2(17,-20),172,night,true)
	_draw_house(LOLA_AT+Vector2(40,-28),172,night,true)
	_paint_archive_props()
	# Old rescue equipment survives at the lower public-bank landing.
	_paint_old_rescue_banca(Vector2(-566,311))
	for at in [Vector2(-750,258),Vector2(-700,270),Vector2(-337,265)]:
		draw_colored_polygon(PackedVector2Array([
			at+Vector2(-17,-28),at+Vector2(6,-36),
			at+Vector2(23,-23),at+Vector2(0,-16)]),Color("#b08b61"))
		draw_colored_polygon(PackedVector2Array([
			at+Vector2(-17,-28),at+Vector2(0,-16),
			at+Vector2(0,12),at+Vector2(-17,-1)]),Color("#665644"))
		draw_colored_polygon(PackedVector2Array([
			at+Vector2(0,-16),at+Vector2(23,-23),
			at+Vector2(23,4),at+Vector2(0,12)]),Color("#7b654c"))
	# Historians' board is a physical model beside the public path: not time travel.
	draw_colored_polygon(PackedVector2Array([
		TABLE+Vector2(-135,-62),TABLE+Vector2(-20,-104),
		TABLE+Vector2(140,-60),TABLE+Vector2(13,-13)]),Color("#af9470"))
	draw_colored_polygon(PackedVector2Array([
		TABLE+Vector2(-135,-62),TABLE+Vector2(13,-13),
		TABLE+Vector2(13,26),TABLE+Vector2(-135,-25)]),Color("#715a45"))
	draw_line(TABLE+Vector2(-109,-48),TABLE+Vector2(111,-57),Color("#d4c2a0"),4,true)
	draw_line(TABLE+Vector2(-45,-86),TABLE+Vector2(32,-34),Color("#547c80"),7,true)
	# Display only the CURRENT reconstruction's markers. Historical route
	# pins must not overlap present-day source clues before their chapter.
	if story.phase == 2:
		for id in Story.ROUTE:
			var dot: Vector2 = ROUTE_POS[id]
			_paint_evidence(dot,id.replace("_"," ").to_upper(),
				story.route_index>Story.ROUTE.find(id))
	if story.phase <= 1:
		for id in Story.CLUES:
			var clue_at: Vector2 = CLUE_POS[id]
			_paint_evidence(clue_at,id.replace("_"," ").to_upper(),story.clues.has(id))
	for id in Story.IDENTITY:
		if story.phase == 3:
			_paint_evidence(IDENTITY_POS[id],id.replace("_"," ").to_upper(),
				story.identity_sources.has(id))
	# Three physical stepping-stone sites have actual support and a clear route.
	var stone_path := PackedVector2Array([Vector2(170,177),STEPS[0],STEPS[1],STEPS[2]])
	# Thin submerged guide rope and short timber spans communicate a crossing,
	# not a giant paved highway through floodwater.
	draw_polyline(stone_path,Color(.18,.36,.37,.74),15.0,true)
	for i in range(stone_path.size()-1):
		var start: Vector2 = stone_path[i]
		var finish: Vector2 = stone_path[i+1]
		var direction: Vector2 = (finish-start).normalized()
		var tangent := Vector2(-direction.y,direction.x)
		for board in range(3):
			var pos: Vector2 = start.lerp(finish,(float(board)+1.0)/4.0)
			draw_colored_polygon(PackedVector2Array([
				pos-tangent*17-direction*9,pos+tangent*17-direction*9,
				pos+tangent*17+direction*9,pos-tangent*17+direction*9]),
				Color("#79857a"))
			draw_line(pos-tangent*16,pos+tangent*16,Color("#b1ad86"),2.2,true)
	for i in range(STEPS.size()):
		var at: Vector2 = STEPS[i]
		Landscape.rock(self,at,74,not night)
		draw_circle(at+Vector2(0,-14),13,
			Color("#e5cf90") if story.phase >= 6 and i <= story.step_index else Color("#86ada7"))
		var label: String = "SAFE STONE %d" % [i+1]
		if player_pos.distance_to(at)<240.0 or story.phase == 6:
			draw_string(ThemeDB.fallback_font,at+Vector2(-72,65),label,
				HORIZONTAL_ALIGNMENT_LEFT,145,15,Color("#eee0b9"))
	for id in Story.PREPARATIONS:
		if story.phase >= 5:
			var pos: Vector2 = PREP_POS[id]
			if id == "lantern_beacon":
				Depth.lantern(self,LANTERN,pos,Vector2(95,142),story.preparations.has(id))
			else:
				draw_circle(pos,32,Color("#edd398") if story.preparations.has(id) else Color("#667d83"))
				draw_circle(pos,16,Color("#324d4e"))
				draw_string(ThemeDB.fallback_font,pos+Vector2(-95,-37),
					id.replace("_"," ").to_upper(),HORIZONTAL_ALIGNMENT_CENTER,190,16,Color("#e9ddba"))
	_paint_hill_checkpoint(night)
	# Blue-grey environmental presence rises from current and river timber.
	# Not ghosts, victims, personal names or an omniscient historian.
	if night:
		draw_rect(MAP.grow(220),Color(.014,.032,.085,.39))
		Landscape.mist(self,Vector2(520,325),740,clock,
			not prefs.reduced_motion,true)
		for i in range(5):
			var j := float(i)
			var crest := Vector2(570+j*52,368+j*21)
			var drift := 0.0 if prefs.reduced_motion else sin(clock*.66+j)*10
			draw_arc(crest+Vector2(drift,0),52+j*14,
				PI*.85,PI*1.88,18,Color(.62,.86,.84,.14),4.0,true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(440,442),Vector2(480,284),Vector2(535,202),
			Vector2(602,252),Vector2(634,430),Vector2(688,486)]),
			Color(.43,.69,.73,.15))
		for pos in [LOLA_AT+Vector2(23,-108),SABEL_AT+Vector2(36,-105)]:
			Windows.paint_window(self,pos,Vector2(30,29),0,night,clock,prefs.reduced_motion)
	if story.phase == 7:
		draw_rect(MAP.grow(220),Color(.48,.59,.61,.08))
	# Nightly villagers actually withdraw indoors instead of staying in the
	# empty street when the river becomes dangerous. Last few frames fade at
	# their own doorway, while warm house windows remain visibly inhabited.
	_paint_chapter_people(false)
	PostgameResidents.paint(self,"night06",clock,prefs.reduced_motion,player_pos)
	# Nearby ground signs are concise and contextual, never overlaid across
	# the touchscreen or blocking the player during exploration.
	if player_pos.distance_to(RETURN_FARM)<270:
		draw_string(ThemeDB.fallback_font,RETURN_FARM+Vector2(-75,-68),
			"FARM RETURN",HORIZONTAL_ALIGNMENT_LEFT,180,16,Color("#f1d8ad"))
	if player_pos.distance_to(TABLE)<245 and story.phase in [1,3]:
		draw_string(ThemeDB.fallback_font,TABLE+Vector2(-62,-117),
			"FLOOD RECORD",HORIZONTAL_ALIGNMENT_LEFT,160,16,Color("#f1e0bb"))
	if story.phase >= 5 and player_pos.distance_to(Vector2(190,210))<170:
		draw_string(ThemeDB.fallback_font,Vector2(80,128),
			"OLD CROSSING",HORIZONTAL_ALIGNMENT_LEFT,220,16,Color("#f3e6be"))
	if story.outcome != "" and player_pos.distance_to(Vector2(800,530))<280:
		draw_string(ThemeDB.fallback_font,Vector2(825,476),
			"NIGHT 7 • BALETE TRAIL OPEN" if World.implemented("night07") and story.outcome != "" else "NIGHT 7 • FINISH RIVER FIRST",HORIZONTAL_ALIGNMENT_LEFT,365,15,Color("#f2d89e"))

func _paint_chapter_people(behind: bool) -> void:
	var people: Array[Dictionary] = []
	var night := _stage() >= 2
	var fade: float = clampf(indoor_seconds/3.3,0.0,1.0) if night else 0.0
	if fade < 1.0:
		for resident in [
			[MARA,MARA_AT,Vector2(98,153),ARCHIVE+Vector2(-28,-70)],
			[DADO,DADO_AT,Vector2(101,159),ARCHIVE+Vector2(14,-70)],
			[SABEL,SABEL_AT,Vector2(99,157),SABEL_AT+Vector2(40,-60)],
			[LOLA,LOLA_AT,Vector2(103,155),LOLA_AT+Vector2(53,-65)]
		]:
			people.append({
				"tex":resident[0],"at":(resident[1] as Vector2).lerp(resident[3],fade),
				"size":resident[2],"alpha":1.0-smoothstep(.77,1.0,fade),
				"dog":false,"moving":false,"shadow":.23
			})
	people.append({"tex":BANTAY,"at":bantay_pos,"size":Vector2(95,102),
		"alpha":1.0,"dog":true,"moving":true,"shadow":.31})
	people.append({"tex":HERO,"at":player_pos,"size":Vector2(108,142),
		"alpha":1.0,"dog":false,"moving":true,"shadow":.37})
	people.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		return (a["at"] as Vector2).y < (b["at"] as Vector2).y)
	# Unified foot sorting and TWO passes prevent Bantay/NPC shadows from
	# painting over the protagonist and reduce sprite silhouette artifacts.
	for actor in people:
		var foot: Vector2 = actor["at"]
		if Walkability.scenery_covers_actor(6,foot) == behind:
			Depth.paint_contact_shadow(self,foot,(actor["size"] as Vector2).x,
				float(actor["shadow"])*float(actor["alpha"]))
	for actor in people:
		var foot: Vector2 = actor["at"]
		if Walkability.scenery_covers_actor(6,foot) != behind:
			continue
		var ink := Color(1,1,1,float(actor["alpha"]))
		if actor["moving"]:
			Depth.paint_animated_actor(self,actor["tex"],foot,actor["size"],
				walk_time,walk_weight,prefs.reduced_motion,ink,
				float(actor["shadow"]),bool(actor["dog"]),false)
		else:
			Depth.paint_grounded(self,actor["tex"],foot,actor["size"],ink,
				float(actor["shadow"]),0.0,false)


func _fit_status_card() -> void:
	if status_panel == null or status_stack == null or not is_inside_tree(): return
	var needed: float = status_stack.get_combined_minimum_size().y+30.0
	status_panel.offset_bottom = clampf(needed,145.0,
		get_viewport().get_visible_rect().size.y*.67)

func _build_ui() -> void:
	hud = CanvasLayer.new()
	hud.name = "Night06HUD"
	hud.layer = 5
	add_child(hud)
	controls = Control.new()
	controls.name = "SharedGameplayHUD"
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(controls)
	var card: Dictionary = SharedHUD.create_status_card(controls,
		"TABI-TABI  •  NIGHT 6 / RIVER'S GRIEF",prefs.text_scale)
	status_panel = card["panel"]
	status_stack = card["stack"]
	objective = card["objective"]
	status_stack.minimum_size_changed.connect(func():call_deferred("_fit_status_card"))
	subtitle = Label.new()
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size",18)
	subtitle.add_theme_color_override("font_color",Color("#cfdecf"))
	status_stack.add_child(subtitle)
	pressure = Label.new()
	pressure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pressure.add_theme_font_size_override("font_size",17)
	pressure.add_theme_color_override("font_color",Color("#ebd4a0"))
	status_stack.add_child(pressure)
	waypoint = Label.new()
	waypoint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	waypoint.add_theme_font_size_override("font_size",17)
	waypoint.add_theme_color_override("font_color",Color("#b9d6c9"))
	status_stack.add_child(waypoint)
	interaction_hint = SharedHUD.make_nearby_prompt(controls,prefs.text_scale)
	SharedHUD.create_movement_joystick(controls,prefs,
		func(axis: Vector2): move_axis = axis)
	for title in SharedHUD.ACTION_POSITIONS:
		var at: Vector2 = SharedHUD.ACTION_POSITIONS[title]
		match title:
			"FIELD NOTES":
				SharedHUD.make_gameplay_button(controls,title,at,Vector2(180,60),
					_open_notes,func():pass,prefs.text_scale)
			"HOLD OBSERVE":
				var btn := SharedHUD.make_gameplay_button(controls,title,at,Vector2(180,60),
					func():observe_held=true,func():observe_held=false,prefs.text_scale)
				btn.mouse_exited.connect(func():observe_held=false)
			"INTERACT":
				SharedHUD.make_gameplay_button(controls,title,at,Vector2(180,60),
					_interact,func():pass,prefs.text_scale)
			"SAFE RETREAT":
				SharedHUD.make_gameplay_button(controls,title,at,Vector2(180,60),
					_confirm_retreat,func():pass,prefs.text_scale)
	var prep := SharedHUD.make_gameplay_button(controls,"PREPARE",Vector2(1050,276),
		Vector2(180,56),_open_preparation,func():pass,prefs.text_scale)
	prep.name = "PrepareButton"
	var save_btn := SharedHUD.make_gameplay_button(controls,"SAVE",Vector2(1050,345),
		Vector2(85,52),_save_feedback,func():pass,prefs.text_scale)
	save_btn.name = "SaveButton"
	var retry := SharedHUD.make_gameplay_button(controls,"RETRY",Vector2(1142,345),
		Vector2(88,52),_retry_from_save,func():pass,prefs.text_scale)
	retry.name = "RetryButton"
	SharedHUD.make_options_button(controls,_open_options,prefs.text_scale)
	var look := AimPad.new()
	look.name = "SharedLookPad"
	look.prompt_text = "LOOK AROUND"
	look.anchor_left = 1.0
	look.anchor_right = 1.0
	look.anchor_top = 1.0
	look.anchor_bottom = 1.0
	look.offset_left = -435
	look.offset_right = -260
	look.offset_top = -205
	look.offset_bottom = -40
	look.aim_changed.connect(func(value: Vector2):aim=value)
	look.aim_released.connect(func():aim=Vector2.ZERO)
	controls.add_child(look)
	meter = ProgressBar.new()
	meter.anchor_left = .33
	meter.anchor_right = .68
	meter.anchor_top = 0
	meter.anchor_bottom = 0
	meter.offset_top = 74
	meter.offset_bottom = 95
	meter.max_value = 100
	meter.show_percentage = false
	meter.visible = false
	controls.add_child(meter)
	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(.0,.0,.01,.62)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(backdrop)
	dialogue = _panel(backdrop,"RiverDialogue",Vector4(.15,.11,.85,.89))
	var ds := _stack(dialogue)
	dialogue_speaker = _label(ds,"",26,Color("#f0d89d"))
	dialogue_body = _label(ds,"",23,Color("#e9eadf"))
	dialogue_body.custom_minimum_size.y = 86
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation",6)
	ds.add_child(choices)
	notes = _panel(backdrop,"RiverNotebook",Vector4(.12,.07,.88,.93))
	var ns := _stack(notes)
	_label(ns,"THE GREAT FLOOD • FIELD RECORD",29,Color("#ead3a4"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ns.add_child(scroll)
	notes_text = _label(scroll,"",21,Color("#e5e7d8"))
	notes_text.custom_minimum_size.x = 600
	_button(ns,"RETURN TO RIVER",func():notes.hide();_sync_ui())
	var unified := SharedOptions.create(backdrop,prefs,"NIGHT 6 • RIVER",{
		"save": _save_feedback,
		"notes": func(): options.hide(); _open_notes(); _sync_ui(),
		"menu": _save_menu,
		"quit": _quit_with_save,
		"back": func(): options.hide(); _sync_ui(),
		"confirm_navigation": true
	},_apply_shared_settings,"RiverOptions")
	options = unified["panel"]
	ending = _panel(backdrop,"RiverAftermath",Vector4(.16,.10,.84,.90))
	save_error = AcceptDialog.new()
	save_error.dialog_text = "Offline save failed. Check storage before continuing."
	hud.add_child(save_error)
	dialogue.hide()
	notes.hide()
	options.hide()
	ending.hide()
	backdrop.hide()

func _panel(parent: Control,title: String,bounds: Vector4) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = title
	p.anchor_left = bounds.x
	p.anchor_top = bounds.y
	p.anchor_right = bounds.z
	p.anchor_bottom = bounds.w
	SharedHUD.style_modal_panel(p)
	parent.add_child(p)
	return p

func _stack(parent: Node) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",9)
	parent.add_child(box)
	return box

func _label(parent: Node,value: String,size2: int,color: Color) -> Label:
	var l := Label.new()
	l.text = value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",size2)
	l.add_theme_color_override("font_color",color)
	parent.add_child(l)
	return l

func _button(parent: Node,value: String,action: Callable) -> Button:
	var b := Button.new()
	b.text = value
	b.clip_text = true
	SharedHUD.style_modal_button(b,false,true,prefs.text_scale)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _hold_move(dir: String,on: bool) -> void:
	held[dir] = on
	move_axis = Vector2(float(int(held.get("right",false))-int(held.get("left",false))),
		float(int(held.get("down",false))-int(held.get("up",false)))).limit_length()

func _nearby() -> String:
	if player_pos.distance_to(RETURN_FARM)<125: return "return_farm"
	if player_pos.distance_to(World.TRAIL_RIVER_BALETE)<World.TRAVEL_RANGE_2D:
		return "balete_gate" if story.outcome != "" or _postgame_active() else "balete_locked"
	var living_clock := PostgameResidents._clock(self)
	if living_clock != null and living_clock.light_stage() < 2:
		var neighbours := {"MARA":MARA_AT,"DADO":DADO_AT,"SABEL":SABEL_AT,"LOLA":LOLA_AT}
		for person in neighbours:
			if player_pos.distance_to(neighbours[person]) < 122.0:
				return "postgame:witness_" + str(person).to_lower()
	if story.phase == 0:
		if story.dado_choice == "unasked" and player_pos.distance_to(DADO_AT)<130:
			return "dado"
		for id in Story.CLUES:
			if not story.clues.has(id) and player_pos.distance_to(CLUE_POS[id])<130: return id
	elif story.phase == 1 and player_pos.distance_to(TABLE)<260:
		return "reconstruct_one"
	elif story.phase == 2:
		for id in Story.ROUTE:
			if player_pos.distance_to(ROUTE_POS[id])<100: return "route_"+id
	elif story.phase == 3:
		for id in Story.IDENTITY:
			if not story.identity_sources.has(id) and player_pos.distance_to(IDENTITY_POS[id])<130: return id
		if player_pos.distance_to(TABLE)<215: return "reconstruct_three"
	elif story.phase == 4:
		if not story.private_sabel_told and player_pos.distance_to(SABEL_AT)<175: return "sabel"
		if not story.lola_covenant_truth_known and player_pos.distance_to(LOLA_AT)<175: return "lola"
		if player_pos.distance_to(TABLE)<240: return "open_river"
	elif story.phase == 5:
		for id in Story.PREPARATIONS:
			if not story.preparations.has(id) and player_pos.distance_to(PREP_POS[id])<150: return id
		if player_pos.distance_to(PREP_POS["lantern_beacon"])<195: return "begin_river"
	elif story.phase == 6 and player_pos.distance_to(STEPS[story.step_index])<130:
		return "watch"
	var postgame_neighbor := PostgameResidents.nearby(self,"night06",player_pos)
	if postgame_neighbor != "":
		return postgame_neighbor
	return ""

func _interact() -> void:
	if _modal() or travel_in_progress: return
	var id := _nearby()
	if id.begins_with("postgame:witness_"):
		var role := id.trim_prefix("postgame:witness_").to_upper()
		var free_clock := get_node("/root/PostgameClock")
		_talk(role,PostgameDialogue.conversation(role,free_clock.village_mood),
			[{"label":"SALAMAT • CONTINUE","action":"close"}])
		return
	if id.begins_with("postgame:"):
		_talk(PostgameResidents.speaker(id),
			PostgameResidents.talk(self,id),
			[{"label":"SALAMAT • CONTINUE","action":"close"}])
		return
	if id == "return_farm":
		_return_farm()
	elif id == "balete_gate":
		_travel_to_balete()
	elif id == "balete_locked":
		_talk("BANTAY • NIGHT 7 TRAIL",
			"The Balete Grounds are connected to this hill road. Finish and save the River's Unfinished Memory before entering the final trial.",
			[{"label":"RETURN TO THE RIVER RECORD","action":"close"}])
	elif id == "dado":
		_talk("TATAY DADO • WITNESS CONSENT",
			"I heard the order to stop the second rescue. I was afraid to speak; Mara was only a child then. Can you keep my name out of the public record?",
			[{"label":"KEEP HIS ACCOUNT PRIVATE","action":"dado_private"},
			{"label":"RESPECT HIS SILENCE","action":"dado_decline"}])
	elif story.phase == 0 and Story.CLUES.has(id):
		if story.inspect(id):
			_save_story()
			var summaries := {
				"rescue_order":"The order stopped the official second launch. Its date is legible; the reason section is partly withheld.",
				"flood_gauge":"A real high-water crest made the return dangerous. It does not explain whom the captain prioritised.",
				"evacuation_roll":"The first evacuation included priority households, but others on the far bank remained unlisted.",
				"alternatives_log":"A possible rope-and-upstream route was mentioned but never jointly evaluated. It might also have been dangerous."
			}
			_talk("DOCUMENTED FLOOD EVIDENCE",str(summaries[id]),
				[{"label":"KEEP THIS SOURCE","action":"close"}])
	elif id == "reconstruct_one":
		_talk("RECONSTRUCTION I • THE STOPPED SECOND RESCUE",
			"Compare the cancellation order, flood gauge and evacuation register. What does the record support? The rescue risk was real; later heroism alone cannot prove that the official launch was safe.",
			[{"label":"DANGER WAS REAL; DECISION WAS UNEQUAL","action":"cancel_true"},
			{"label":"THE RIVER WAS ALWAYS SAFE","action":"cancel_false"}])
	elif id.begins_with("route_"):
		var route_id := id.trim_prefix("route_")
		if story.plot_route(route_id):
			_save_story()
			_talk("RECONSTRUCTION II • THE RETURNING BOAT",
				"Mapped source %d/3. The independent boat went from the official dock toward the stranded far bank and delivered survivors to the shelter, outside the Keeper's limited refuge. This is an evidence-based route model, not time travel." % story.route_index,
				[{"label":"CONTINUE MAPPING","action":"close"}])
		else:
			_talk("MARA • REVISE THE BOAT ROUTE",
				"That is a plausible guess, not the next documented stop. Check the tide marks, the dock log and the survivor arrival time; you can revise without penalty.",
				[{"label":"RETURN TO MAP","action":"close"}])
	elif story.phase == 3 and Story.IDENTITY.has(id):
		if story.inspect_identity(id):
			_save_story()
			var evidence := "The family boat carried an unusual carved cross-beam; the material was repaired with Sabel's household cord." if id == "family_boat_mark" else "A survivor volunteered a private account: the returning rescuer used that same repaired boat and helped the last group board."
			_talk("INDEPENDENT CORROBORATION",evidence,
				[{"label":"RECORD WITH CARE","action":"close"}])
	elif id == "reconstruct_three":
		if story.identity_sources.size()<2:
			_talk("MARA • NOT YET CERTAIN",
				"We still need both the family boat mark and a separate survivor account. Unnamed silhouettes remain unverified.",
				[{"label":"COLLECT THE SECOND SOURCE","action":"close"}])
		else:
			_talk("RECONSTRUCTION III • THE FINAL SACRIFICE",
				"The returning boatman protected the departing passengers in the last surge. The survivors reached shore, but the rescuer did not. Which identity do the independent records corroborate?",
				[{"label":"ALING SABEL'S HUSBAND","action":"identity_true"},
				{"label":"MANG CELSO OF THE SANTELMO","action":"identity_false"}])
	elif id == "sabel":
		_talk("ALING SABEL • A PRIVATE QUESTION",
			"Aling Sabel, we have corroborated evidence about your husband. Would you like to hear it now? He returned for stranded neighbours; others survived because of him, but he did not reach the last bank. You decide if any remembrance becomes public.",
			[{"label":"TELL HER PRIVATELY; KEEP IT PRIVATE","action":"sabel_private"},
			{"label":"SHE CHOOSES A WRITTEN REMEMBRANCE","action":"sabel_written"},
			{"label":"SHE CONSENTS TO PUBLIC TESTIMONY","action":"sabel_public"}])
	elif id == "lola":
		_talk("LOLA PASING • RECORDS KEPT TOO LONG",
			"Lola kept witness records to protect Dado and young Mara from retaliation. For decades she delayed their release. She asked the Ancient Keeper only to shield the reachable high refuge, not to cross the river. She promised remembrance; fear prolonged her silence. The survivors' choices remain their own.",
			[{"label":"ACKNOWLEDGE THE FACTS WITHOUT FORCING FORGIVENESS","action":"lola_truth"}])
	elif id == "open_river":
		if story.open_river():
			_save_story()
			_talk("MARA • THE UNFINISHED MEMORY",
				"The evidence names the choices people made. The rising river is not a dead person's soul; it is an unstable environment carrying unfinished memories. Secure rope, lantern and stones before facing the surge.",
				[{"label":"PREPARE THE REAL CROSSING","action":"close"}])
		else:
			_talk("MARA • FIRST PROTECT THE WITNESSES",
				"Talk privately with Sabel and examine Lola's records. Neither needs to forgive publicly.",
				[{"label":"RETURN TO THEM","action":"close"}])
	elif story.phase == 5 and Story.PREPARATIONS.has(id):
		if story.prepare(id):
			_save_story()
			_talk("SAFE RIVER PREPARATION",
				"Prepared "+id.replace("_"," ")+". The route remains marked, the current is dangerous, and Bantay will warn before each step.",
				[{"label":"CONTINUE PREPARING","action":"close"}])
	elif id == "begin_river":
		if story.begin_crossing():
			_save_story()
			player_pos = Vector2(175,175)
			_talk("BANTAY • THREE RIVER SURGES",
				"Follow the visible safe stones. At each one HOLD OBSERVE to read the water, then choose the lantern, rope or words that match the evidence. No random button guessing or hidden death.",
				[{"label":"START FROM THE SAFE BANK","action":"close"}])
		else:
			_talk("MARA • CROSSING NOT READY",
				"Check the three separate preparations: rope anchor, lit beacon and stable stepping stones.",
				[{"label":"BACK TO SAFETY","action":"close"}])
	elif id == "watch":
		if story.current_ready: _show_current_choices()
		else:
			_talk("BANTAY • READ THE CURRENT",
				"Stand on the marked stone and HOLD OBSERVE for a moment. Do not rush through a rising current.",
				[{"label":"WATCH THE WATER","action":"close"}])
	else:
		_talk("BANTAY • THE WAY AHEAD",
			"The route marker and your Field Notes show the next source. Stay on the public path.",
			[{"label":"CONTINUE","action":"close"}])
	_refresh()

func _show_current_choices() -> void:
	if story.phase != 6 or not story.current_ready: return
	var caption: String = [
		"First surge: floating fragments obscure the lantern-lit stone. What makes the real edge visible?",
		"Second surge: the repaired mooring line can steady the next step. What will hold the route?",
		"Final surge: the source-backed order and names must be spoken without inventing a victim's voice. What do we do?"
	][story.step_index]
	_talk("THE RIVER'S UNFINISHED MEMORY • STEP %d/3" % [story.step_index+1],caption,
		[{"label":"STEADY THE LANTERN","action":"hold_lantern"},
		 {"label":"SECURE THE ROPE","action":"secure_rope"},
		 {"label":"SPEAK THE CONFIRMED NAMES","action":"speak_names"}])

func _choice(value: String) -> void:
	if value == "close":
		_close_dialogue()
		return
	if value == "reload":
		get_tree().call_deferred("reload_current_scene")
		return
	if value == "dado_private" or value == "dado_decline":
		story.record_dado("private" if value == "dado_private" else "decline")
		_save_story()
		_talk("DADO • RESPECTED",
			"His consent is respected. The physical records can still establish the historical truth.",
			[{"label":"CONTINUE THE EVIDENCE SEARCH","action":"close"}])
	elif value in ["cancel_true","cancel_false"]:
		if story.reconstruct_cancellation("real_danger_unequal_choice" if value == "cancel_true" else "all_safe"):
			_save_story()
			_talk("MARA • DOCUMENTED CANCELLATION",
				"The former captain faced real danger but unfairly prioritised some households. Other options were not fully examined. A later personal crossing does not prove the official route could safely continue.",
				[{"label":"TRACE THE UNOFFICIAL BOAT","action":"close"}])
		else:
			_talk("MARA • REVISE THE HYPOTHESIS",
				"The flood gauge confirms serious danger. The evacuation roll and alternatives log show unfairness; neither record cancels the other.",
				[{"label":"REVISIT THE BOARD","action":"close"}])
	elif value in ["identity_true","identity_false"]:
		if story.reconstruct_sacrifice("sabel_husband" if value == "identity_true" else "celso"):
			_save_story()
			_talk("MARA • TWO INDEPENDENT SOURCES",
				"Sabel's husband took the boat back independently. He saved others and did not survive the final crossing. Mang Celso is a different boatman; do not combine the two stories.",
				[{"label":"SPEAK WITH SABEL PRIVATELY","action":"close"}])
		else:
			_talk("MARA • A DIFFERENT BOATMAN",
				"Compare the family repair cord and the survivor's voluntary statement. Mang Celso belongs to an earlier separate river record.",
				[{"label":"RECHECK THE SOURCES","action":"close"}])
	elif value.begins_with("sabel_"):
		var choice := "private" if value == "sabel_private" else "written" if value == "sabel_written" else "consent_public"
		if story.tell_sabel(choice):
			_save_story()
			_talk("SABEL • THE EVERYDAY LIFE HE LEFT",
				"He always checked the oar bindings twice. For years I thought he had abandoned me. I will remember him in my own way; that is my choice.",
				[{"label":"RESPECT HER DECISION","action":"close"}])
	elif value == "lola_truth":
		if story.confess_lola():
			_save_story()
			_talk("LOLA PASING • AN UNFULFILLED PROMISE",
				"I feared exposing the rescued families. That fear became years of silence. The Keeper could hold only the high refuge; the people in the far bank were saved by human courage.",
				[{"label":"RECORD THE FACTS WITHOUT FORCED FORGIVENESS","action":"close"}])
	elif Story.RIVER_ACTIONS.has(value):
		if story.respond(value):
			_save_story()
			if story.phase == 7:
				_talk("MARA • THE RIVER QUIETS",
					"The crossing is safe for now. Documents and neighbours, not a creature's confession, tell us what happened. Record our responsibilities before Balete Grounds.",
					[{"label":"RECORD THE OUTCOME","action":"outcomes"}])
			else:
				_talk("BANTAY • SAFE GROUND",
					"The marked stone held. Follow the next real walkway and look again before choosing another tool.",
					[{"label":"CONTINUE TO THE NEXT STONE","action":"close"}])
		else:
			_talk("BANTAY • THAT WAS NOT THE CUE",
				"Look at the lantern reflection, tension in the rope and the confirmed names. The safer response is still available.",
				[{"label":"TRY AGAIN","action":"close"}])
	elif value == "retry_current":
		if story.retry_current():
			player_pos = Vector2(170,178) if story.step_index == 0 else STEPS[story.step_index-1]
			_save_story()
			_talk("BANTAY • SAFE RETRY",
				"The prior crossing steps and all witness evidence are preserved. We can observe the current again.",
				[{"label":"RESUME SAFELY","action":"close"}])
	elif value == "outcomes":
		_talk("THE RIVER • COMMUNITY RECORD",
			"Document the safest conclusion. The community still must address the unjust evacuation and honour survivor privacy in Night 7.",
			[{"label":"RESOLVE • DOCUMENTED TRUTH AND SAFE CROSSING","action":"resolve"},
			{"label":"CONTAIN • TEMPORARY SAFETY, MORE WORK","action":"contain"},
			{"label":"PARTIAL • KEEP THE EVIDENCE AND RETURN","action":"partial"}])
	elif Story.RESULTS.has(value):
		if story.commit(value):
			_save_story()
			_show_ending()
		else:
			_talk("FIELD RECORD • CHECK THE ROUTE",
				"Complete the three safe steps for a full ending; partial retreat is allowed if the current is too dangerous.",
				[{"label":"CONTINUE","action":"close"}])
	_refresh()

func _talk(who: String,message: String,actions: Array) -> void:
	notes.hide()
	options.hide()
	ending.hide()
	backdrop.show()
	dialogue.show()
	dialogue_speaker.text = who
	dialogue_body.text = message
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	for action in actions:
		var code: String = str(action["action"])
		_button(choices,str(action["label"]),func():_press_dialogue_choice(code))
	DialogueMotion.reveal(dialogue,prefs.reduced_motion)
	DialogueMotion.reveal_text(dialogue_body,prefs.reduced_motion)
	_sync_ui()

func _press_dialogue_choice(action: String) -> void:
	# Same tap-to-complete rule as the established Night 1 cinematic.
	# A fast choice tap reveals the current line before a consequence runs.
	if DialogueMotion.finish_text(dialogue_body):
		return
	_choice(action)

func _close_dialogue() -> void:
	DialogueMotion.conceal(dialogue,prefs.reduced_motion)
	_sync_ui()
	DialogueMotion.restore_gameplay(controls,prefs.reduced_motion)

func _sync_ui() -> void:
	backdrop.visible = dialogue.visible or notes.visible or options.visible or ending.visible
	controls.visible = not backdrop.visible
	if not controls.visible:
		move_axis = Vector2.ZERO
		held.clear()
		observe_held = false

func _refresh() -> void:
	if objective == null: return
	var steps := ["DAY / DOCUMENTS","DUSK / CANCELLATION","DUSK / BOAT ROUTE",
		"EVENING / SACRIFICE","EVENING / WITNESSES","NIGHT / PREPARE",
		"MIDNIGHT / SAFE CROSSING","DAWN / VERIFIED MEMORY"]
	subtitle.text = "%s  •  RECONSTRUCTION %d/3" % [
		steps[clampi(story.phase,0,7)],clampi(story.phase-1,0,3)]
	if qa_river_preview:
		subtitle.text = "MIDNIGHT RIVER • VISUAL QA PREVIEW"
	match story.phase:
		0: objective.text = "Inspect FOUR independent flood records. Dado may choose to share privately."
		1: objective.text = "At the archive table: compare the second rescue order, danger and unequal choices."
		2: objective.text = "Trace the BOAT MODEL in order: official dock, far bank, shelter return."
		3: objective.text = "Compare two sources, then link the unknown rescuer without guessing."
		4: objective.text = "Ask Sabel privately; hear Lola's explanation. Respect family choice."
		5: objective.text = "Secure rope, lantern and marked stones before entering the dangerous river."
		6: objective.text = "SAFE STONE %d/3: follow the marked route and HOLD OBSERVE." % [story.step_index+1]
		7: objective.text = "RIVER RECORD • %s • FOLLOW THE OPEN BALETE TRAIL" % story.outcome.to_upper() if story.outcome != "" else "Choose a recorded result to open the final Balete path."
	if qa_river_preview:
		objective.text = "RIVER ENVIRONMENT PREVIEW • Historical evidence remains unchanged."
	_refresh_hint()
	call_deferred("_fit_status_card")

func _refresh_hint() -> void:
	if interaction_hint == null: return
	var id := _nearby()
	SharedHUD.set_nearby_prompt_text(interaction_hint, ("INTERACT • "+id.replace("_"," ").to_upper()) if id != "" else "")
	var goal := TABLE
	var destination := "ARCHIVE TABLE"
	match story.phase:
		0:
			for id2 in Story.CLUES:
				if not story.clues.has(id2):
					goal = CLUE_POS[id2]
					destination = id2.replace("_"," ").to_upper()
					break
		1: goal = TABLE
		2:
			goal = ROUTE_POS[Story.ROUTE[story.route_index]]
			destination = "HISTORICAL BOAT MAP"
		3:
			goal = TABLE
			for id2 in Story.IDENTITY:
				if not story.identity_sources.has(id2):
					goal = IDENTITY_POS[id2]
					destination = "INDEPENDENT EVIDENCE"
					break
		4:
			goal = SABEL_AT if not story.private_sabel_told else LOLA_AT if not story.lola_covenant_truth_known else TABLE
			destination = "PRIVATE WITNESS / LOLA"
		5:
			goal = PREP_POS["lantern_beacon"]
			for id2 in Story.PREPARATIONS:
				if not story.preparations.has(id2):
					goal = PREP_POS[id2]
					break
			destination = "PREPARE THE SAFE ROUTE"
		6:
			goal = STEPS[story.step_index]
			destination = "SAFE STONE • HOLD OBSERVE"
		7:
			goal = RETURN_FARM
			destination = "FARM RETURN / FIELD RECORD"
	waypoint.text = "%s  •  %d STEPS" % [destination,roundi(player_pos.distance_to(goal)/12)]

func _open_notes() -> void:
	if _modal() and not options.visible and not ending.visible: return
	options.hide()
	ending.hide()
	notes.show()
	backdrop.show()
	notes_text.text = "NIGHT 6 • WHAT THE WATER TOOK\n\n"
	notes_text.text += "Official rescue records:\n"
	for id in Story.CLUES:
		notes_text.text += ("[VERIFIED] " if story.clues.has(id) else "[NOT FOUND] ")+id.replace("_"," ")+"\n"
	notes_text.text += "\nRECONSTRUCTION I: " + ("Unequal cancellation established." if story.cancellation_confirmed else "Unconfirmed; danger and choices must be compared.")+"\n"
	notes_text.text += "RECONSTRUCTION II: BOAT ROUTE %d/3.\n" % story.route_index
	notes_text.text += "RECONSTRUCTION III: RESCUER " + ("corroborated privately" if story.rescuer_confirmed else "unknown silhouette")+"\n\n"
	notes_text.text += "DADO CONSENT: %s. SABEL: %s. LOLA ACCOUNT: %s.\n" % [
		story.dado_choice,story.sabel_public_choice,
		"known" if story.lola_covenant_truth_known else "not recorded"]
	notes_text.text += "The Keeper shielded ONLY high refuge; it did not rescue the distant bank. The independent rescuer was not Mang Celso. Uncorroborated guesses can be revised.\n\n"
	notes_text.text += "CROSSING %d/3 • current %d%%. Always use marked stones, lantern and rope; nobody dies for a retry.\n\n" % [story.step_index,roundi(story.tension*100)]
	notes_text.text += "Earlier preserved cases: Santelmo %s; Kapre %s; Tikbalang %s; Wake %s; Farm %s.\n" % [
		story.night01_outcome,story.night02_outcome,story.night03_outcome,
		story.night04_outcome,story.night05_outcome]
	_sync_ui()

func _open_preparation() -> void:
	if _modal(): return
	_talk("NIGHT 6 • SAFE CROSSING BRIEFING",
		"Use the original Night 1 thumb controls. Investigation comes first. When the river rises, prepare the rope anchor, lantern beacon and stable stones. Remain on marked ground; hold OBSERVE to read three separate surges.",
		[{"label":"RETURN TO RIVER","action":"close"}])

func _apply_shared_settings() -> void:
	camera.position_smoothing_enabled = not prefs.reduced_motion
	if ambient != null:
		ambient.set_audio_level(prefs.audio_level)
	_sync_ui()

func _open_options() -> void:
	if dialogue.visible or ending.visible: return
	options.show()
	_sync_ui()
	print("NIGHT6_QA_OPTIONS_OPEN")

func _retry_from_save() -> void:
	if _modal(): return
	_talk("RETRY • LAST OFFLINE RECORD",
		"Reload your last saved Night 6 checkpoint? Earlier chapter saves are never erased, but unsaved actions here will be lost.",
		[{"label":"RELOAD NIGHT 6 CHECKPOINT","action":"reload"},
		 {"label":"KEEP PLAYING","action":"close"}])

func _confirm_retreat() -> void:
	if _modal() or story.outcome != "": return
	if story.phase < 5:
		_talk("MARA • FINISH THE EVIDENCE FIRST",
			"We can return to the farm without erasing this Night's incomplete notes. A recorded river retreat is available only after evidence and witness preparation.",
			[{"label":"RETURN TO SOURCES","action":"close"}])
		return
	_talk("BANTAY • SAFE RETREAT",
		"The current is real. Leave with a partial finding if you cannot safely cross; past night records and witnessed facts remain.",
		[{"label":"LEAVE WITH A PARTIAL RIVER RECORD","action":"retreat"},
		 {"label":"KEEP INVESTIGATING SAFELY","action":"close"}])

func _save_story() -> bool:
	story.player_position = player_pos
	var ok := Save.write(story)
	if ok and story.outcome != "": World.note_outcome(6,story.outcome)
	return ok

func _save_feedback() -> void:
	if not _save_story():
		save_error.popup_centered(Vector2i(600,175))
		return
	options.hide()
	_talk("FIELD RECORD","Night 6 saved offline. Nights 1–5 remain unchanged.",
		[{"label":"CONTINUE","action":"close"}])

func _quit_with_save() -> void:
	if not _save_story():
		save_error.popup_centered(Vector2i(600,190))
		return
	get_tree().quit()

func _save_menu() -> void:
	if not _save_story():
		save_error.popup_centered(Vector2i(600,175))
		return
	get_node("/root/SceneTransit").call("change_to_file", "res://scenes/title.tscn")

func _postgame_active() -> bool:
	var clock_node := get_node_or_null("/root/PostgameClock")
	return clock_node != null and clock_node.is_active()

func _travel_to_balete() -> void:
	if travel_in_progress or (story.outcome == "" and not _postgame_active()):
		return
	if not _save_story() or not World.begin_travel("night06","night07",story.outcome):
		save_error.popup_centered(Vector2i(600,175))
		return
	travel_in_progress = true
	observe_held = false
	move_axis = Vector2.ZERO
	print("TABI_WORLD_TRAVEL_RIVER_TO_BALETE")
	get_node("/root/SceneTransit").call("change_to_file", World.scene_for("night07"))

func _return_farm() -> void:
	if travel_in_progress: return
	if not _save_story() or not World.begin_travel("night06","night05",story.outcome):
		save_error.popup_centered(Vector2i(600,175))
		return
	travel_in_progress = true
	get_node("/root/SceneTransit").call("change_to_file", World.scene_for("night05"))

func _show_ending() -> void:
	dialogue.hide()
	notes.hide()
	options.hide()
	ending.show()
	for child in ending.get_children():
		ending.remove_child(child)
		child.queue_free()
	var box := _stack(ending)
	_label(box,"NIGHT 6 • THE RIVER'S UNFINISHED MEMORY",27,Color("#f0d4a1"))
	var summary := "The river crossing steadies. The official cancellation and the rescuer's independent courage are both recorded, without presenting the victims as monsters."
	if story.outcome == "contain":
		summary = "The river is contained for now. The community still needs to discuss the evacuation order and future safety measures."
	elif story.outcome in ["partial","retreat"]:
		summary = "The current remains dangerous. The documented truths and witness consent are preserved; retreating is not failure."
	_label(box,summary,23,Color("#ede9d7"))
	_label(box,"SABEL'S CHOICE: %s  •  FIVE PRIOR NIGHTS PRESERVED" % story.sabel_public_choice.to_upper(),20,Color("#b2d3c0"))
	_button(box,"REVIEW THE EVIDENCE",func():ending.hide();_open_notes())
	_button(box,"ENTER NIGHT 7 • BALETE GROUNDS (SAVE)",_travel_to_balete)
	_button(box,"RETURN TO SIGBIN FARM (SAVE)",_return_farm)
	_button(box,"SAVE & MAIN MENU",_save_menu)
	_sync_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if dialogue.visible:
			if not DialogueMotion.finish_text(dialogue_body): _close_dialogue()
		else: _interact()
	if event.is_action_pressed("ui_cancel"):
		if dialogue.visible: _close_dialogue()
		elif notes.visible: notes.hide();_sync_ui()
		elif options.visible: options.hide();_sync_ui()
		else: _open_options()
	# Android debug-only deterministic live screenshot positions; no save mutation.
	if OS.get_name() == "Android" and OS.has_feature("debug") and event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode in [KEY_F3,KEY_F6,KEY_F9,KEY_F11]:
			if dialogue.visible: _close_dialogue()
			notes.hide()
			options.hide()
			qa_river_preview = key.keycode == KEY_F9
			match key.keycode:
				KEY_F3:
					player_pos = ARCHIVE+Vector2(-140,125)
					print("NIGHT6_QA_ARCHIVE_DAY")
				KEY_F6:
					player_pos = TABLE+Vector2(160,82)
					print("NIGHT6_QA_RECONSTRUCTION_BOARD")
				KEY_F9:
					player_pos = STEPS[0]
					print("NIGHT6_QA_RIVER_MEMORY_NIGHT")
				KEY_F11:
					player_pos = RETURN_FARM+Vector2(130,55)
					print("NIGHT6_QA_FARM_RETURN_TRAIL")
			camera.position = player_pos
			_refresh()
			_sync_ui()
			get_viewport().set_input_as_handled()
