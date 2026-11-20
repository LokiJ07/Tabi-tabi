extends Node2D
## Playable Night 4: Manananggal — The Wake.
## Entire night is grounded 2.5D art, canonical social deduction + group
## protection (not an HP fight). One connected Barrio Lawom world.
const Story = preload("res://scripts/narrative/night04_state.gd")
const Save = preload("res://scripts/core/night04_save.gd")
const Night03State = preload("res://scripts/narrative/night03_state.gd")
const Night03Save = preload("res://scripts/core/night03_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
const Preferences = preload("res://scripts/core/preferences.gd")
const SharedHUD = preload("res://scripts/ui/shared_hud.gd")
const SharedOptions = preload("res://scripts/ui/shared_options.gd")
const Walkability = preload("res://scripts/world/shared_walkability_2d.gd")
const SharedDialogueMotion = preload("res://scripts/ui/shared_dialogue_motion.gd")
const PostgameResidents = preload("res://scripts/world/postgame_residents.gd")
const DimensionalArt = preload("res://scripts/visuals/layered_25d.gd")
const NightWindows = preload("res://scripts/visuals/nighttime_windows.gd")
const WakeVigil = preload("res://scripts/visuals/night04_vigil_art.gd")
const ActorMotion = preload("res://scripts/visuals/night04_character_motion.gd")
const Landscape = preload("res://scripts/visuals/folklore_landscape_25d.gd")
const Atmosphere = preload("res://scripts/visuals/shared_immersive_atmosphere.gd")
const Ambient = preload("res://scripts/audio/night04_ambience.gd")
const AimPad = preload("res://scripts/ui/aim_pad.gd")
const HERO: Texture2D = preload("res://assets/characters/apprentice.svg")
const BANTAY: Texture2D = preload("res://assets/characters/bantay.svg")
const MARA: Texture2D = preload("res://assets/characters/mara.svg")
const SABEL: Texture2D = preload("res://assets/characters/sabel.svg")
const NENA: Texture2D = preload("res://assets/night04/nena_caretaker.svg")
const MANANANGGAL: Texture2D = preload("res://assets/night04/manananggal_wake.svg")
const MANANANGGAL_LEFT: Texture2D = preload("res://assets/night04/manananggal_wing_left.svg")
const MANANANGGAL_RIGHT: Texture2D = preload("res://assets/night04/manananggal_wing_right.svg")
const NIPA: Texture2D = preload("res://assets/world/nipa_thatch_roof.svg")
const WEAVE: Texture2D = preload("res://assets/world/lola_sawali_wall.svg")
const LEAVES: Texture2D = preload("res://assets/world/north_forest_tree.svg")
const LANTERN: Texture2D = preload("res://assets/world/lantern_post.svg")
const SOIL: Texture2D = preload("res://assets/world/soil_ground.svg")
const MAP := Rect2(-980,-740,1980,1480)
const RETURN_RIDGE := Vector2(-880,420)
const FARM_TRAIL := Vector2(815,-185)
const WAKE_HOUSE := Vector2(75,-190)
const SAFE_COURT := Vector2(125,205)
const PLAYER_SPEED := 250.0
const CLUE_POS := {
	"caretaker_schedule":Vector2(-420,-255),
	"rear_window":Vector2(433,-205),
	"rooftop_marks":Vector2(40,-570),
	"mourners_accounts":Vector2(-515,148)
}
const DEFENSE_POS := {
	"rear_bell":Vector2(444,-90),
	"courtyard_lantern":Vector2(235,190),
	"rear_shutter":Vector2(427,-319),
	"mara_lookout":Vector2(-295,115)
}
const CLUE_NAMES := {
	"caretaker_schedule":"Nena's repeating supply runs",
	"rear_window":"Rear-window scratch marks",
	"rooftop_marks":"Roof-slate disturbance",
	"mourners_accounts":"Independent witness accounts"
}
const CLUE_TEXT := {
	"caretaker_schedule":"Aling Nena has repeatedly fetched supplies alone. Her exhaustion and route are visible, but this is NOT evidence she is the creature.",
	"rear_window":"A damaged rear latch and high scratches face inward. They do not match the feet of mourners who came through the front.",
	"rooftop_marks":"Roof dust and an unusually broad wing shadow align with the back courtyard. The wake itself is not the cause of danger.",
	"mourners_accounts":"Mara compares two independent accounts: a heavy landing followed each late supply trip, but neither witness saw a human guest transform."
}
var story = Story.new()
var prefs = Preferences.new()
var player_pos := Story.START
var bantay_pos := Story.START+Vector2(-50,35)
var camera: Camera2D
var ambient
var atmosphere
var elapsed := 0.0
var indoor_transition_seconds := 0.0
var previous_light_stage := 0
var walk_phase := 0.0
var walk_weight := 0.0
var motion := Vector2.ZERO
var aim := Vector2.ZERO
var held: Dictionary = {}
var observe_held := false
var debug_wake_preview := false
var travel_in_progress := false
var hud: CanvasLayer
var controls: Control
var objective: Label
var status_panel: PanelContainer
var status_stack: VBoxContainer
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
var save_error: AcceptDialog
var modal_backdrop: ColorRect
var observation_meter: ProgressBar

func _ready() -> void:
	name = "TabiTabiNight4"
	set_meta("dimensional_art",DimensionalArt.STYLE_ID)
	prefs.load_from()
	var before = Night03State.new()
	if Night03Save.read(before):
		story.night03_outcome = before.outcome
		story.night02_outcome = before.night02_outcome
		story.night01_outcome = before.night01_outcome
	Save.read(story)
	previous_light_stage = _stage()
	# Reloading an active encounter cannot bring the mourners back outdoors.
	indoor_transition_seconds = ActorMotion.INDOOR_DURATION if previous_light_stage >= 2 else 0.0
	player_pos = story.player_position
	var arrival := World.consume_arrival("night04")
	if str(arrival.get("from","")) == "night03":
		player_pos = Vector2(-715,280)
		print("TABI_WORLD_ARRIVAL_WAKE_FROM_RIDGE")
	elif str(arrival.get("from","")) == "night05":
		player_pos = FARM_TRAIL+Vector2(-80,90)
		print("TABI_WORLD_ARRIVAL_WAKE_FROM_FARM")
	# Recover legacy saves from inside decorative walls and trunks.
	player_pos = Walkability.repair_saved_position(4,player_pos)
	bantay_pos = player_pos+Vector2(-44,29)
	camera = Camera2D.new()
	camera.name = "Night04WakeCamera"
	camera.position = player_pos
	camera.enabled = true
	camera.position_smoothing_enabled = not prefs.reduced_motion
	camera.position_smoothing_speed = 4.0
	camera.zoom = Vector2(1.03,1.03)
	add_child(camera)
	ambient = Ambient.new()
	ambient.name = "WakeWindAndQuietPrayer"
	add_child(ambient)
	ambient.set_audio_level(prefs.audio_level)
	_build_ui()
	_refresh()
	var postgame_ready := get_node_or_null("/root/PostgameClock")
	if story.outcome != "" and not (postgame_ready != null and postgame_ready.is_active()):
		_show_ending()
	elif story.phase == 0 and story.clues.is_empty():
		_talk("LOLA PASING","Night 4 — The Wake. Ang kasubo sa pamilya dili ebidensya sa dautan. Attend the mourners, listen before judging, and protect the people who are left alone.",
			[{"label":"MANGITA SA TINUOD NGA EBIDENSYA","action":"close"}])
	print("NIGHT4_QA_SCENE_READY")

func _stage() -> int:
	var free_roam_clock := get_node_or_null("/root/PostgameClock")
	if free_roam_clock != null and free_roam_clock.is_active():
		return free_roam_clock.light_stage()
	if debug_wake_preview:
		return 3
	if story.phase <= 0 or story.phase == 5:
		return 0
	if story.phase == 1:
		return 1
	return 3 if story.phase >= 3 else 2

func _modal() -> bool:
	return dialogue.visible or notes.visible or options.visible or ending.visible

func _manananggal_approach() -> Vector2:
	match story.current_warning():
		"rear_window": return Vector2(485,-263)
		"courtyard": return Vector2(260,-155)
	return Vector2(270,-335) # threat descends from roofline toward lit wake

func _process(delta: float) -> void:
	var village_clock := get_node_or_null("/root/PostgameClock")
	if village_clock != null and village_clock.is_active() and objective != null:
		var free_roam_status := "FREE ROAM • WAKE HOUSE • COMMUNITY CARE\n%s  |  %s" % [
			village_clock.clock_label(),
			"RESTORED" if village_clock.village_mood == "restored" else "REBUILDING"
		]
		if objective.text != free_roam_status:
			objective.text = free_roam_status
	elapsed += delta if not prefs.reduced_motion else 0.0
	var stage_now := _stage()
	if stage_now >= 2:
		if previous_light_stage < 2:
			# Dialogue can finish before people begin entering the house.
			indoor_transition_seconds = ActorMotion.INDOOR_DURATION if prefs.reduced_motion else 0.0
		elif not _modal():
			indoor_transition_seconds = minf(ActorMotion.INDOOR_DURATION,
				indoor_transition_seconds + maxf(delta,0.0))
	else:
		indoor_transition_seconds = 0.0
	previous_light_stage = stage_now
	var axis := Input.get_vector("ui_left","ui_right","ui_up","ui_down")+motion
	if _modal():
		axis = Vector2.ZERO
	axis = axis.limit_length()
	walk_weight = lerpf(walk_weight,1.0 if axis.length()>.02 else 0.0,
		1.0 if prefs.reduced_motion else clampf(delta*8.0,0,1))
	if axis.length()>.02:
		if not prefs.reduced_motion:
			walk_phase += delta*9.0
		var walk := Vector2(axis.x+axis.y*.42,axis.y*.78-axis.x*.15).normalized()
		var candidate := player_pos+walk*PLAYER_SPEED*delta
		candidate.x = clampf(candidate.x,MAP.position.x+65,MAP.end.x-65)
		candidate.y = clampf(candidate.y,MAP.position.y+75,MAP.end.y-75)
		player_pos = Walkability.slide(4,player_pos,candidate)
	var dog_goal := bantay_pos.lerp(player_pos+Vector2(-49,29),clampf(delta*3.2,0,1))
	bantay_pos = Walkability.slide(4,bantay_pos,dog_goal)
	# A tall, airborne Manananggal must be framed together with the
	# apprentice during a real attack, not cropped at the top of the phone.
	# This is the world camera only; Night 1 shared touch HUD never moves.
	var framing_target := player_pos + aim*64.0
	var close_encounter: bool = story.phase == 3 or debug_wake_preview
	var target_zoom: float = 1.03
	if close_encounter:
		# Fit both the wing tip and the player in Godot's actual logical
		# canvas (1280x720 on a typical phone), NOT Android hardware pixels.
		var approach: Vector2 = _manananggal_approach()
		var fit: Dictionary = ActorMotion.camera_fit(player_pos,approach,
			get_viewport_rect().size,aim)
		framing_target = fit["center"]
		target_zoom = fit["zoom"]
	var zoom_target := Vector2(target_zoom,target_zoom)
	camera.zoom = camera.zoom.lerp(zoom_target,
		1.0 if prefs.reduced_motion else clampf(delta*4.2,0.0,1.0))
	camera.position = camera.position.lerp(framing_target,
		1.0 if prefs.reduced_motion else clampf(delta*4.5,0,1))
	if not _modal() and not travel_in_progress and player_pos.distance_to(RETURN_RIDGE)<56:
		_return_to_ridge()
		return
	if story.phase == 3 and not _modal():
		if story.observation_tick(delta,player_pos.distance_to(SAFE_COURT)<215,
				observe_held,prefs.story_assist):
			observe_held = false
			_auto_save()
			_show_attack_warning()
		elif story.encounter_failed:
			observe_held = false
			_talk("BANTAY","The wingbeats are too close. Everyone has withdrawn behind the doors. No one has died. Return to the last safe checkpoint or accept a partial retreat.",
				[{"label":"RETRY FROM SAFE COURTYARD","action":"retry"},
				 {"label":"WITHDRAW AND REPORT","action":"retreat"}])
	if ambient != null:
		ambient.set_night_stage(_stage())
		ambient.set_tension(story.tension)
	if atmosphere != null:
		atmosphere.configure(4,_stage(),story.tension,prefs.reduced_motion)
	if pressure != null:
		pressure.text = "BARRIO TRUST %d  •  TENSION %d%%" % [story.trust,roundi(story.tension*100)]
	if observation_meter != null:
		observation_meter.visible = story.phase == 3 and not story.warning_ready
		observation_meter.value = story.warning_progress*100.0
	_refresh_hint()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if dialogue.visible:
			_close_dialogue()
		else:
			_interact()
	if event.is_action_pressed("ui_cancel"):
		if dialogue.visible:
			_close_dialogue()
		elif notes.visible:
			notes.hide()
		elif options.visible:
			options.hide()
		else:
			_open_options()
	if OS.get_name() == "Android" and OS.has_feature("debug") and event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode in [KEY_F3,KEY_F5,KEY_F6,KEY_F9]:
			_close_dialogue()
			notes.hide()
			options.hide()
			debug_wake_preview = key.keycode == KEY_F9
			match key.keycode:
				KEY_F3:
					player_pos = Vector2(-235,-220)
					print("NIGHT4_QA_WAKE_DAY")
				KEY_F5:
					player_pos = RETURN_RIDGE+Vector2(140,-75)
					print("NIGHT4_QA_RIDGE_RETURN")
				KEY_F6:
					player_pos = SAFE_COURT
					print("NIGHT4_QA_COURTYARD")
				KEY_F9:
					player_pos = SAFE_COURT
					# This is a debug-only view of DEEP NIGHT, after the three
					# mourners have finished entering; normal story transitions stay.
					indoor_transition_seconds = ActorMotion.INDOOR_DURATION
					previous_light_stage = 3
					print("NIGHT4_QA_MANANANGGAL_NIGHT")
			bantay_pos = player_pos+Vector2(-49,29)
			camera.position = player_pos
			if debug_wake_preview and subtitle != null:
				subtitle.text = "QA NIGHT REVEAL • NORMAL STORY REQUIRES INVESTIGATION + DEFENSE"
			else:
				_refresh()
			get_viewport().set_input_as_handled()

func _house() -> void:
	# Four projected wall faces, raised porch and paired pitched roof planes.
	# Every element is real in-world art and follows camera parallax.
	var fl := WAKE_HOUSE+Vector2(-290,110)
	var fr := WAKE_HOUSE+Vector2(220,160)
	var br := WAKE_HOUSE+Vector2(330,-130)
	var bl := WAKE_HOUSE+Vector2(-180,-185)
	var up := Vector2(0,-265)
	draw_colored_polygon(PackedVector2Array([fl+Vector2(-40,20),fr+Vector2(30,23),
		br+Vector2(45,26),bl+Vector2(-30,24)]),Color(.02,.03,.04,.30))
	draw_colored_polygon(PackedVector2Array([fr,br,br+up,fr+up]),Color("#766856"))
	draw_colored_polygon(PackedVector2Array([fl,fr,fr+up,fl+up]),Color("#b4a07e"))
	for i in range(13):
		var x := fl.lerp(fr,float(i)/12.0)
		draw_line(x,x+up,Color("#705f50",.48),2.0,true)
	for j in range(5):
		var h := float(j+1)/6.0
		draw_line(fl.lerp(fl+up,h),fr.lerp(fr+up,h),Color("#d5c297",.28),2.0,true)
	var roof_fl := fl+up+Vector2(-45,-15)
	var roof_fr := fr+up+Vector2(38,-13)
	var roof_bl := bl+up+Vector2(-38,-17)
	var roof_br := br+up+Vector2(44,-17)
	var r_front := WAKE_HOUSE+Vector2(-13,-355)
	var r_back := WAKE_HOUSE+Vector2(100,-645)
	draw_colored_polygon(PackedVector2Array([roof_fl,r_front,r_back,roof_bl]),Color("#745849"))
	draw_colored_polygon(PackedVector2Array([r_front,roof_fr,roof_br,r_back]),Color("#443c3b"))
	# Imported nipa-thatch texture follows BOTH real sloping roof planes.
	# Flat colour planes made the lamay house look like a cardboard cutout,
	# especially in daylight. The eave, door and collider remain untouched.
	var thatch_size := NIPA.get_size()
	var roof_uv := PackedVector2Array([
		Vector2(0,thatch_size.y),Vector2(thatch_size.x,thatch_size.y),
		Vector2(thatch_size.x,0),Vector2(0,0)])
	var lit_ink := Color(.84,.71,.59,.54)
	var shade_ink := Color(.65,.63,.62,.43)
	draw_polygon(PackedVector2Array([roof_fl,r_front,r_back,roof_bl]),
		PackedColorArray([lit_ink,lit_ink,lit_ink,lit_ink]),roof_uv,NIPA)
	draw_polygon(PackedVector2Array([r_front,roof_fr,roof_br,r_back]),
		PackedColorArray([shade_ink,shade_ink,shade_ink,shade_ink]),roof_uv,NIPA)
	for i in range(8):
		var q := float(i+1)/9.0
		draw_line(roof_fl.lerp(r_front,q),roof_bl.lerp(r_back,q),Color("#bd9871",.52),3.0,true)
		draw_line(r_front.lerp(roof_fr,q),r_back.lerp(roof_br,q),Color("#9b7b67",.49),3.0,true)
	draw_line(r_front,r_back,Color("#d6b486"),5.0,true)
	var door := fl.lerp(fr,.43)
	draw_colored_polygon(PackedVector2Array([door+Vector2(-31,0),door+Vector2(51,0),
		door+Vector2(51,-179),door+Vector2(-31,-179)]),Color("#342c2c"))
	draw_line(door+Vector2(-30,-179),door+Vector2(52,-179),Color("#e0c18a"),6)
	# Actual lit wake windows and different wall-facing perspective.
	var glow := Color("#444b49") if _stage() < 2 else Color("#4d4643")
	# Illumination is painted AFTER nighttime darkness, not baked into day walls.
	for shift in [Vector2(-145,-141),Vector2(152,-141)]:
		draw_rect(Rect2(door+shift,Vector2(80,77)),glow)
		draw_rect(Rect2(door+shift,Vector2(80,77)),Color("#503d31"),false,5)
		draw_line(door+shift+Vector2(40,0),door+shift+Vector2(40,77),Color("#705a45"),3)
		draw_line(door+shift+Vector2(0,38),door+shift+Vector2(80,38),Color("#705a45"),3)
	var side := fr.lerp(br,.50)+Vector2(-2,-45) # below eave on the real wall, not on the roof
	draw_colored_polygon(PackedVector2Array([side+Vector2(-34,-44),side+Vector2(43,-33),
		side+Vector2(43,38),side+Vector2(-34,28)]),Color("#192a2a"))
	draw_line(side+Vector2(-34,-44),side+Vector2(43,-33),Color("#e3b879"),6.0)
	# Raised porch stairs are below the door footprint and remain walkable.
	for i in range(4):
		var at := door+Vector2(-63-float(i)*9,23+float(i)*20)
		draw_line(at,at+Vector2(134+float(i)*17,12),Color("#8c6846"),10.0,true)

func _draw() -> void:
	draw_rect(MAP.grow(220),Color("#1d3331"))
	Landscape.parallax_ridges(self,MAP.grow(170),camera.position,2,_stage())
	for i in range(28):
		var y := MAP.position.y + float(i)*60.0
		draw_rect(Rect2(MAP.position.x,y,MAP.size.x,60),Color("#334a3e").lerp(Color("#586a51"),float(i)/27.0))
	draw_texture_rect(SOIL,Rect2(-960,-700,1910,1370),false,Color(1,1,1,.18))
	# All paths lead into the one wake compound, not separate chapter rooms.
	Landscape.raised_trail(self,PackedVector2Array([
		RETURN_RIDGE,Vector2(-680,310),Vector2(-365,222),
		SAFE_COURT,Vector2(400,260)]),83.0,Color("#4d5746"),Color("#af9875"))
	Landscape.trail_stones(self,RETURN_RIDGE,Vector2(-400,235),18,90,_stage()>=2)
	_paint_chapter_people(true)
	for at in [Vector2(-800,-400),Vector2(-850,-140),Vector2(-680,-595),
		Vector2(690,-510),Vector2(800,-145),Vector2(812,500)]:
		DimensionalArt.paint_grounded(self,LEAVES,at+Vector2(0,27),
			Vector2(225,310),Color("#8da48b"),.31)
	for rock_at in [Vector2(-670,90),Vector2(515,360),Vector2(760,290),Vector2(-395,380)]:
		Landscape.rock(self,rock_at,36,_stage()<2)
	_house()
	WakeVigil.paint_wake_furniture(self)
	# Quiet vigil: raised candle table and coffee beside the gathering.
	draw_colored_polygon(PackedVector2Array([Vector2(-350,80),Vector2(-130,101),
		Vector2(-99,135),Vector2(-335,114)]),Color("#896447"))
	for p in [Vector2(-292,47),Vector2(-220,57),Vector2(-174,62)]:
		draw_line(p+Vector2(0,32),p+Vector2(0,-18),Color("#e6dbc4"),6,true)
		draw_circle(p+Vector2(0,-20),7,Color("#efbd67"))
		if _stage() >= 1:
			draw_circle(p+Vector2(0,-22),26,Color(1,.67,.32,.07))
	for sign in [Vector2(-450,30),Vector2(470,70)]:
		draw_line(sign+Vector2(0,40),sign+Vector2(0,-63),Color("#674b32"),8)
		draw_line(sign+Vector2(-21,-60),sign+Vector2(51,-60),Color("#c5a578"),8)
	# Real prop silhouettes, marked for interaction, but not generic rings.
	for id in Story.CLUES:
		var p: Vector2 = CLUE_POS[id]
		if story.clues.has(id):
			draw_circle(p+Vector2(24,-53),7,Color("#9cd0b2"))
		else:
			draw_arc(p+Vector2(0,-22),37,0,TAU,24,Color("#c8b184",.28),2,true)
		if id == "rear_window":
			draw_line(p+Vector2(-24,-62),p+Vector2(45,-17),Color("#8e6f59"),5)
			draw_line(p+Vector2(34,-63),p+Vector2(-17,-8),Color("#b3916e"),3)
		elif id == "rooftop_marks":
			for i in range(4):
				draw_line(p+Vector2(float(i)*14-25,11),p+Vector2(float(i)*14-41,-24),Color("#4b4644"),5)
		elif id == "caretaker_schedule":
			draw_rect(Rect2(p+Vector2(-43,-43),Vector2(75,80)),Color("#e0c9a4"))
			for i in range(4):
				draw_line(p+Vector2(-31,-24+float(i)*14),p+Vector2(18,-24+float(i)*14),Color("#947d61"),2)
		else:
			draw_line(p+Vector2(-35,0),p+Vector2(32,-9),Color("#dfbd85"),8)
	for id in Story.DEFENSES:
		var pos: Vector2 = DEFENSE_POS[id]
		var active: bool = story.defenses.has(id)
		var hue := Color("#c9ab68") if active else Color("#715844")
		draw_line(pos+Vector2(0,26),pos+Vector2(0,-70),hue,8)
		if id == "rear_bell":
			draw_circle(pos+Vector2(0,-75),14,Color("#dcb46a") if active else Color("#816d52"))
		elif id == "courtyard_lantern":
			DimensionalArt.lantern(self,LANTERN,pos+Vector2(0,24),Vector2(58,114),active)
		elif id == "rear_shutter":
			draw_rect(Rect2(pos+Vector2(-38,-93),Vector2(78,48)),hue)
		else:
			draw_line(pos+Vector2(-35,-72),pos+Vector2(32,-65),hue,8)
	if _stage() == 1:
		draw_rect(MAP.grow(220),Color(.28,.13,.06,.15))
	elif _stage() >= 2:
		draw_rect(MAP.grow(220),Color(.015,.035,.08,.37))
		Landscape.mist(self,Vector2(120,285),700.0,elapsed,not prefs.reduced_motion,true)
		for point in [Vector2(-290,20),Vector2(260,5),Vector2(455,-95)]:
			draw_circle(point,132,Color(1,.65,.30,.05))
	# Physical world-space tells help players identify which approach to watch
	# before the correct group-defense dialogue becomes available.
	var warning_route: String = story.current_warning()
	if warning_route == "" and debug_wake_preview:
		warning_route = "roofline" # QA render only; never changes narrative state
	WakeVigil.paint_warning_tell(self,warning_route,_stage(),elapsed,
		story.tension,prefs.reduced_motion)
	# The wake is brightly attended INSIDE at night, not a crowd of idle
	# daytime NPC sprites frozen outside. Windows and curtains convey their
	# safe presence behind the walls during the defensive encounter.
	if _stage() >= 2:
		var door := (WAKE_HOUSE+Vector2(-290,110)).lerp(WAKE_HOUSE+Vector2(220,160),.43)
		for i in range(2):
			var shift := Vector2(-145,-141) if i == 0 else Vector2(152,-141)
			NightWindows.paint_window(self,door+shift+Vector2(40,38),
				Vector2(80,77),1 if i == 0 else 0,true,elapsed,prefs.reduced_motion)
		# Rear entrance remains a danger cue: mostly dark, not a safe exit.
		NightWindows.paint_window(self,Vector2(365,-225),Vector2(53,51),
			2,true,elapsed,prefs.reduced_motion,false)
	WakeVigil.paint_inner_lights(self,_stage(),elapsed,prefs.reduced_motion)
	# A real three-plane winged creature: independent shoulders, then body.
	# Paint AFTER the darkness grade for visibility but BEHIND people and HUD.
	if story.phase == 3 or debug_wake_preview:
		var from: Vector2 = _manananggal_approach()
		var drift := Vector2(sin(elapsed*.81)*16,cos(elapsed*.71)*8) if not prefs.reduced_motion else Vector2.ZERO
		for i in range(4,0,-1):
			draw_circle(from+drift,60.0+float(i)*31.0,Color(.29,.41,.48,.009))
		ActorMotion.paint_flight_air(self,from+drift+Vector2(0,153),elapsed,
			prefs.reduced_motion,story.tension)
		ActorMotion.paint_flying(self,MANANANGGAL,MANANANGGAL_LEFT,MANANANGGAL_RIGHT,
			from+drift+Vector2(-5,110),elapsed,prefs.reduced_motion,Color("#d1d5cb"))
	# Human cast is rendered above the warmth. Story dialogue and evidence
	# still work when residents have moved inside, not been deleted.
	_paint_chapter_people(false)
	PostgameResidents.paint(self,"night04",elapsed,prefs.reduced_motion,player_pos)
	var font := ThemeDB.fallback_font
	draw_string(font,RETURN_RIDGE+Vector2(25,-90),"FLOOD RIDGE • RETURN",HORIZONTAL_ALIGNMENT_LEFT,320,18,Color("#e8cb94"))
	draw_string(font,WAKE_HOUSE+Vector2(-160,206),"THE WAKE • LAMAY",HORIZONTAL_ALIGNMENT_LEFT,350,20,Color("#f7d79d"))
	draw_string(font,Vector2(630,-140),"THE FARM TRAIL • "+("OPEN" if story.outcome != "" else "LOCKED"),HORIZONTAL_ALIGNMENT_LEFT,355,18,Color("#e3ca97"))

func _paint_chapter_people(behind: bool) -> void:
	var people: Array[Dictionary] = []
	var civilians: Array[Dictionary] = [
		{"role":"NENA","at":Vector2(-420,-180),"tex":NENA,"size":Vector2(107,140)},
		{"role":"SABEL","at":Vector2(-515,145),"tex":SABEL,"size":Vector2(91,125)},
		{"role":"MARA","at":Vector2(-265,100),"tex":MARA,"size":Vector2(95,130)}
	]
	for civilian in civilians:
		var role: String = civilian["role"]
		if NightWindows.outdoor_actor_visible(4,_stage(),role):
			people.append(civilian)
		elif _stage() >= 2 and indoor_transition_seconds < ActorMotion.INDOOR_DURATION:
			var heading_inside: Dictionary = civilian.duplicate()
			heading_inside["at"] = ActorMotion.indoor_position(role,civilian["at"],indoor_transition_seconds)
			heading_inside["alpha"] = ActorMotion.indoor_alpha(indoor_transition_seconds)
			people.append(heading_inside)
	people.append({"at":bantay_pos+Vector2(0,19),"tex":BANTAY,"size":Vector2(96,104)})
	people.append({"at":player_pos+Vector2(0,8),"tex":HERO,"size":Vector2(108,142)})
	people.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		return (a["at"] as Vector2).y < (b["at"] as Vector2).y)
	for actor in people:
		var foot: Vector2 = actor["at"]
		if Walkability.scenery_covers_actor(4,foot) == behind:
			var alpha: float = float(actor.get("alpha",1.0))
			DimensionalArt.paint_contact_shadow(self,foot,(actor["size"] as Vector2).x,.38*alpha)
	for actor in people:
		var p: Vector2 = actor["at"]
		if Walkability.scenery_covers_actor(4,p) != behind:
			continue
		var size2: Vector2 = actor["size"]
		var is_hero: bool = actor["tex"] == HERO
		var is_dog: bool = actor["tex"] == BANTAY
		var transparency: float = float(actor.get("alpha",1.0))
		if transparency > .005:
			if is_hero or is_dog:
				DimensionalArt.paint_animated_actor(self,actor["tex"],p,
					size2,walk_phase,walk_weight,prefs.reduced_motion,
					Color(1,1,1,transparency),.38*transparency,is_dog,false)
			else:
				DimensionalArt.paint_living_npc(self,actor["tex"],p,size2,
					elapsed,prefs.reduced_motion,
					Color(1,1,1,transparency),.38*transparency,false)

func _fit_status_card() -> void:
	# Same dynamic status height as Night 1–3: objectives must never overflow.
	if status_panel == null or status_stack == null or not is_inside_tree():
		return
	var needed: float = status_stack.get_combined_minimum_size().y + 30.0
	var available: float = get_viewport().get_visible_rect().size.y * 0.67
	status_panel.offset_bottom = clampf(needed, 145.0, available)


func _build_ui() -> void:
	var atmosphere_layer := CanvasLayer.new()
	atmosphere_layer.layer = 3
	add_child(atmosphere_layer)
	atmosphere = Atmosphere.new()
	atmosphere_layer.add_child(atmosphere)
	hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	controls = Control.new()
	controls.name = "SharedGameplayHUD"
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(controls)
	var status: Dictionary = SharedHUD.create_status_card(controls,"TABI-TABI  •  NIGHT 4 / THE WAKE",prefs.text_scale)
	objective = status["objective"]
	status_panel = status["panel"]
	status_stack = status["stack"]
	status_stack.minimum_size_changed.connect(func(): call_deferred("_fit_status_card"))
	var stack: VBoxContainer = status_stack
	subtitle = Label.new()
	subtitle.add_theme_font_size_override("font_size",17)
	subtitle.add_theme_color_override("font_color",Color("#c6dccd"))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(subtitle)
	pressure = Label.new()
	pressure.add_theme_font_size_override("font_size",17)
	pressure.add_theme_color_override("font_color",Color("#e9d6a0"))
	stack.add_child(pressure)
	waypoint = Label.new()
	waypoint.add_theme_font_size_override("font_size",18)
	waypoint.add_theme_color_override("font_color",Color("#b5d5cb"))
	stack.add_child(waypoint)
	interaction_hint = SharedHUD.make_nearby_prompt(controls,prefs.text_scale)
	SharedHUD.create_movement_joystick(controls,prefs,
		func(axis: Vector2): motion = axis)
	for title in SharedHUD.ACTION_POSITIONS:
		var at: Vector2 = SharedHUD.ACTION_POSITIONS[title]
		var size2 := Vector2(180,60)
		match title:
			"FIELD NOTES":
				SharedHUD.make_gameplay_button(controls,title,at,size2,
					_open_notes,func():pass,prefs.text_scale)
			"HOLD OBSERVE":
				SharedHUD.make_gameplay_button(controls,title,at,size2,
					func(): observe_held = true,func(): observe_held = false,prefs.text_scale)
			"INTERACT":
				SharedHUD.make_gameplay_button(controls,title,at,size2,
					_interact,func():pass,prefs.text_scale)
			"SAFE RETREAT":
				SharedHUD.make_gameplay_button(controls,title,at,size2,
					_confirm_retreat,func():pass,prefs.text_scale)
	# Match the exact Night 1–3 top action slots (and make each control real).
	var prep_button := SharedHUD.make_gameplay_button(controls,"PREPARE",
		Vector2(1050,276),Vector2(180,56),_open_preparation_briefing,func():pass,prefs.text_scale)
	prep_button.name = "PrepareButton"
	var save_button := SharedHUD.make_gameplay_button(controls,"SAVE",
		Vector2(1050,345),Vector2(85,52),_save_feedback,func():pass,prefs.text_scale)
	save_button.name = "SaveButton"
	var retry_button := SharedHUD.make_gameplay_button(controls,"RETRY",
		Vector2(1142,345),Vector2(88,52),_retry_from_saved_checkpoint,func():pass,prefs.text_scale)
	retry_button.name = "RetryButton"
	SharedHUD.make_options_button(controls,_open_options,prefs.text_scale)
	var pad := AimPad.new()
	pad.name = "SharedLookPad"
	pad.prompt_text = "LOOK AROUND"
	pad.anchor_left = 1.0
	pad.anchor_right = 1.0
	pad.anchor_top = 1.0
	pad.anchor_bottom = 1.0
	pad.offset_left = -435.0
	pad.offset_right = -260.0
	pad.offset_top = -205.0
	pad.offset_bottom = -40.0
	pad.aim_changed.connect(func(d: Vector2): aim = d)
	pad.aim_released.connect(func(): aim = Vector2.ZERO)
	controls.add_child(pad)
	observation_meter = ProgressBar.new()
	observation_meter.anchor_left = .32
	observation_meter.anchor_right = .68
	observation_meter.anchor_top = 0
	observation_meter.anchor_bottom = 0
	observation_meter.offset_top = 75
	observation_meter.offset_bottom = 98
	observation_meter.max_value = 100
	observation_meter.show_percentage = false
	controls.add_child(observation_meter)
	modal_backdrop = ColorRect.new()
	modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_backdrop.color = Color(0,0,0,.61)
	modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(modal_backdrop)
	dialogue = _panel(modal_backdrop,"WakeDialogue",Vector4(.15,.12,.85,.88))
	var dstack := _stack(dialogue)
	dialogue_speaker = _label(dstack,"",27,Color("#eed39c"))
	dialogue_body = _label(dstack,"",24,Color("#f0ebdb"))
	dialogue_body.custom_minimum_size.y = 95
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation",6)
	dstack.add_child(choices)
	notes = _panel(modal_backdrop,"WakeNotebook",Vector4(.14,.10,.86,.90))
	var nstack := _stack(notes)
	_label(nstack,"FIELD NOTES • NIGHT 4",29,Color("#e8cb95"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nstack.add_child(scroll)
	notes_text = _label(scroll,"",21,Color("#dfebe1"))
	notes_text.custom_minimum_size.x = 580
	_button(nstack,"RETURN TO WAKE",func():notes.hide())
	var unified := SharedOptions.create(modal_backdrop,prefs,"NIGHT 4 • THE WAKE",{
		"save": _save_feedback,
		"notes": func(): options.hide(); _open_notes(); _sync_ui(),
		"menu": _save_menu,
		"quit": _quit_with_save,
		"back": func(): options.hide(); _sync_ui(),
		"confirm_navigation": true
	},_apply_shared_settings,"WakeOptions")
	options = unified["panel"]
	ending = _panel(modal_backdrop,"WakeAftermath",Vector4(.16,.12,.84,.88))
	save_error = AcceptDialog.new()
	save_error.dialog_text = "The offline record could not be saved. Check device storage."
	hud.add_child(save_error)
	dialogue.hide()
	notes.hide()
	options.hide()
	ending.hide()
	modal_backdrop.hide()
	_sync_ui()

func _panel(parent: Control, title: String, bounds: Vector4) -> PanelContainer:
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
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation",9)
	parent.add_child(v)
	return v

func _label(parent: Node,text: String,size2: int,color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",roundi(float(size2)*prefs.text_scale))
	l.add_theme_color_override("font_color",color)
	parent.add_child(l)
	return l

func _button(parent: Node,text: String,action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.clip_text = true
	SharedHUD.style_modal_button(b,false,true,prefs.text_scale)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _hold_move(dir: String,on: bool) -> void:
	held[dir] = on
	motion = Vector2(float(int(held.get("right",false))-int(held.get("left",false))),
		float(int(held.get("down",false))-int(held.get("up",false)))).limit_length()

func _nearby() -> String:
	if player_pos.distance_to(RETURN_RIDGE)<115:
		return "return_ridge"
	if player_pos.distance_to(FARM_TRAIL)<135:
		return "farm_trail" if story.outcome != "" else "farm_locked"
	if story.phase == 0:
		for id in Story.CLUES:
			if not story.clues.has(id) and player_pos.distance_to(CLUE_POS[id])<115:
				return id
		if not story.coffee_served and player_pos.distance_to(Vector2(-230,97))<105:
			return "coffee"
	elif story.phase == 1:
		if player_pos.distance_to(SAFE_COURT)<260:
			return "deduce"
	elif story.phase == 2:
		for id in Story.DEFENSES:
			if not story.defenses.has(id) and player_pos.distance_to(DEFENSE_POS[id])<120:
				return id
		if player_pos.distance_to(SAFE_COURT)<210:
			return "begin_siege"
	elif story.phase == 3:
		if player_pos.distance_to(SAFE_COURT)<225:
			return "watch"
	var postgame_neighbor := PostgameResidents.nearby(self,"night04",player_pos)
	if postgame_neighbor != "":
		return postgame_neighbor
	return ""

func _interact() -> void:
	if _modal() or travel_in_progress:
		return
	var id := _nearby()
	if id.begins_with("postgame:"):
		_talk(PostgameResidents.speaker(id),
			PostgameResidents.talk(self,id),
			[{"label":"SALAMAT • CONTINUE","action":"close"}])
		return
	if id == "return_ridge":
		_return_to_ridge()
	elif id == "farm_trail":
		_travel_to_farm()
	elif id == "farm_locked":
		_talk("BANTAY • FINISH THE WAKE",
			"We cannot leave the family during the crisis. Record a safe Night 4 outcome, then the connected farm road will open.",
			[{"label":"RETURN TO THE WAKE","action":"close"}])
	elif id == "coffee":
		if story.serve_coffee():
			_auto_save()
			_talk("ALING NENA","Salamat sa kape. Apan naa pa koy kuhaon sa likod. Please help me carry the supplies inside.",
				[{"label":"WE WILL HELP","action":"close"}])
	elif story.phase == 0 and Story.CLUES.has(id):
		if story.inspect(id):
			_auto_save()
			_talk("FIELD OBSERVATION",str(CLUE_TEXT[id])+
				("\n\nFour observations agree. Decide who is at risk — do not accuse a grieving guest." if story.phase==1 else ""),
				[{"label":"RECORD IN NOTES","action":"close"}])
	elif story.phase == 1:
		_talk("MARA • PRIVATE HYPOTHESIS",
			"Whose repeated exposure to the rear supply route makes them vulnerable? An exhausted helper is NOT automatically the predator.",
			[{"label":"PROTECT ALING NENA","action":"nena"},
			 {"label":"SUSPECT A RANDOM MOURNER","action":"mourner"},
			 {"label":"ACCUSE A GUEST PUBLICLY (TRUST LOSS)","action":"accuse_guest"},
			 {"label":"REVIEW THE EVIDENCE","action":"close"}])
	elif story.phase == 2 and Story.DEFENSES.has(id):
		if story.prepare(id):
			_auto_save()
			_talk("PREPARE THE WAKE","Prepared "+id.replace("_"," ")+". The gathering helps; no one should patrol a dark entrance alone.",
				[{"label":"CONTINUE","action":"close"}])
	elif story.phase == 2 and id == "begin_siege":
		if story.begin_siege():
			_auto_save()
			_talk("ALING NENA","The bells are ready. I will warn the guests. Mara watches the courtyard and Bantay listens by the roof.",
				[{"label":"STAY TOGETHER","action":"close"}])
		else:
			_talk("MARA","Prepare at least THREE independent safeguards first. Re-check the bell, shutter, lantern and lookout.",
				[{"label":"CHECK THE HOUSE","action":"close"}])
	elif story.phase == 3:
		if story.warning_ready:
			_show_attack_warning()
		else:
			_talk("BANTAY","From the safe courtyard, HOLD OBSERVE until a visible wing or wind pattern identifies the active approach.",
				[{"label":"WATCH THE ROOF","action":"close"}])
	elif id == "":
		_talk("BANTAY","Follow the next waypoint and listen to real people before making a conclusion.",
			[{"label":"CONTINUE","action":"close"}])
	_refresh()

func _show_attack_warning() -> void:
	var route := story.current_warning().replace("_"," ").to_upper()
	_talk("BANTAY • WARNING: "+route,
		"Something large passes over the roof. A heavy wingbeat, moving shade and shaken leaves reveal the approach. Coordinate the correct response; never leave Nena alone.",
		[{"label":"RING THE WARNING BELL","action":"ring_bell"},
		 {"label":"RAISE THE COURTYARD LANTERN","action":"raise_lantern"},
		 {"label":"ESCORT THE GUESTS INSIDE","action":"escort_group"}])

func _choose(value: String) -> void:
	if value == "reload_saved":
		get_tree().call_deferred("reload_current_scene")
		return
	if value == "close":
		_close_dialogue()
		return
	if value == "retry":
		if story.retry_checkpoint():
			player_pos = SAFE_COURT
			_auto_save()
			_talk("BANTAY","Everyone is safe. Begin the warning sequence again from the courtyard.",
				[{"label":"CONTINUE","action":"close"}])
		return
	if value == "retreat":
		if story.commit("retreat"):
			_auto_save()
			_show_ending()
		return
	if value == "accuse_guest":
		story.accuse_guest()
		_auto_save()
		_talk("MARA","You hurt the trust of a mourning family. A name is not evidence. Reconsider privately and focus on the actual risk.",
			[{"label":"RECONSIDER THE EVIDENCE","action":"close"}])
		return
	if story.phase == 1:
		if story.deduce_target(value):
			_auto_save()
			_talk("ALING NENA","You noticed I was alone at the back. Thank you. Let us bring the supplies indoors and ask the others to guard the entrances.",
				[{"label":"PREPARE THE HOUSE","action":"close"}])
		else:
			_talk("MARA","That remains an unproven theory. Compare the rooftop marks, window damage, schedule and independent voices again.",
				[{"label":"REVISE MY PRIVATE HYPOTHESIS","action":"close"}])
	elif story.phase == 3:
		if story.respond(value):
			_auto_save()
			if story.phase == 4:
				_talk("ALING NENA","Buntag na. Wala nay nangawala nga tawo. We protected each other because the warning signs were listened to.",
					[{"label":"RECORD THE OUTCOME","action":"outcomes"}])
			else:
				_talk("BANTAY","The group is safe for now. Another approach is coming; return to the courtyard and listen before moving.",
					[{"label":"CONTINUE DEFENSE","action":"close"}])
		else:
			_talk("MARA","That was not the sign we observed. Watch the approaching wing shadow and choose the response that matches this position.",
				[{"label":"LOOK AGAIN","action":"close"}])
	elif value == "outcomes":
		_talk("MORNING • COMMUNITY CONSEQUENCES","Nena and the mourners survive. Your level of preparation determines how safely the wake returns to normal.",
			[{"label":"RESOLVE • FULL HOUSE PROTECTION","action":"resolve"},
			 {"label":"DRIVE AWAY • THE THREAT WITHDRAWS","action":"drive_away"},
			 {"label":"PARTIAL • RECOVERY FOLLOW-UP","action":"partial"}])
	elif story.phase == 4 and Story.RESULTS.has(value):
		if story.commit(value):
			_auto_save()
			_show_ending()
		else:
			_talk("FIELD RECORD","That result requires a stronger preparation record. You may still protect everyone through the drive-away or recovery outcome.",
				[{"label":"REVIEW AVAILABLE ENDINGS","action":"outcomes"}])
	_refresh()

func _talk(who: String,message: String,actions: Array) -> void:
	notes.hide()
	options.hide()
	ending.hide()
	modal_backdrop.show()
	dialogue.show()
	dialogue_speaker.text = who
	dialogue_body.text = message
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	for action in actions:
		var id := str(action["action"])
		_button(choices,str(action["label"]),func():_press_dialogue_choice(id))
	SharedDialogueMotion.reveal(dialogue,prefs.reduced_motion)
	SharedDialogueMotion.reveal_text(dialogue_body,prefs.reduced_motion)
	_sync_ui()

func _press_dialogue_choice(action: String) -> void:
	# Identical to Nights 1–3: a quick touch finishes the current speaker
	# line rather than accidentally advancing a consequence.
	if SharedDialogueMotion.finish_text(dialogue_body):
		return
	_choose(action)

func _close_dialogue() -> void:
	SharedDialogueMotion.conceal(dialogue,prefs.reduced_motion)
	_sync_ui()
	SharedDialogueMotion.restore_gameplay(controls,prefs.reduced_motion)

func _sync_ui() -> void:
	if modal_backdrop != null:
		modal_backdrop.visible = dialogue.visible or notes.visible or options.visible or ending.visible
	if controls != null:
		controls.visible = not (dialogue.visible or notes.visible or options.visible or ending.visible)
	if not controls.visible:
		motion = Vector2.ZERO
		observe_held = false
		held.clear()

func _refresh() -> void:
	if objective == null:
		return
	var tasks := ["DAY  /  INVESTIGATE","DUSK  /  DEDUCE","EVENING  /  PREPARE",
		"MIDNIGHT  /  DEFEND","DAWN  /  AFTERMATH","MORNING  /  RECORDED"]
	subtitle.text = "%s  •  EVIDENCE %d/4  •  DEFENSE %d/4" % [
		tasks[clampi(story.phase,0,5)],story.clues.size(),story.defenses.size()]
	match story.phase:
		0: objective.text = "Serve coffee, talk to mourners and inspect FOUR physical/witness clues."
		1: objective.text = "Deduce who is at risk. Do NOT accuse a mourner without evidence."
		2: objective.text = "Prepare bell, lantern, shutter and lookout; coordinate at least THREE."
		3: objective.text = "Stay in the safe courtyard, HOLD OBSERVE and respond to THREE wing warnings."
		4: objective.text = "Record how the wake was protected and what the families need at dawn."
		5: objective.text = "NIGHT 4 RECORDED • %s" % story.outcome.to_upper()
	_refresh_hint()

func _refresh_hint() -> void:
	if interaction_hint == null:
		return
	var target := _nearby()
	SharedHUD.set_nearby_prompt_text(interaction_hint, "FOLLOW WAYPOINT • INVESTIGATE" if target == "" else "INTERACT • "+target.replace("_"," ").to_upper())
	var goal := RETURN_RIDGE
	var title := "RETURN TO FLOOD RIDGE"
	if story.phase == 0:
		for id in Story.CLUES:
			if not story.clues.has(id):
				goal = CLUE_POS[id]
				title = CLUE_NAMES[id].to_upper()
				break
	elif story.phase == 1:
		goal = SAFE_COURT
		title = "PRIVATE WITNESS DEDUCTION"
	elif story.phase == 2:
		goal = SAFE_COURT
		title = "COORDINATE DEFENSE"
		for id in Story.DEFENSES:
			if not story.defenses.has(id):
				goal = DEFENSE_POS[id]
				title = id.replace("_"," ").to_upper()
				break
	elif story.phase == 3:
		goal = SAFE_COURT
		title = "WATCH AND PROTECT MOURNERS"
	var diff := goal-player_pos
	waypoint.text = "%s  •  %d STEPS" % [title,roundi(diff.length()/12.0)]

func _open_notes() -> void:
	if _modal() and not options.visible:
		return
	options.hide()
	modal_backdrop.show()
	notes.show()
	notes_text.text = "THE WAKE  /  CASE NOTES\n\n"
	for id in Story.CLUES:
		notes_text.text += ("[OBSERVED] " if story.clues.has(id) else "[NOT FOUND] ")+str(CLUE_NAMES[id])+"\n"
	notes_text.text += "\nAling Nena is a caretaker and a target, NOT a monster. Never expose the family's private grief or identify mourners by rumor.\n\n"
	for id in Story.DEFENSES:
		notes_text.text += ("[READY] " if story.defenses.has(id) else "[UNPREPARED] ")+id.replace("_"," ")+"\n"
	notes_text.text += "\nWARNING %d/3  •  BARRIO TRUST %d\n" % [story.attack_index,story.trust]
	notes_text.text += "\nPrevious records: Santelmo %s; Kapre %s; Tikbalang %s." % [
		story.night01_outcome,story.night02_outcome,story.night03_outcome]
	_sync_ui()

func _open_preparation_briefing() -> void:
	if _modal():
		return
	_talk("WAKE SAFETY PREPARATION",
		"Defense ready: %d/4. Use INTERACT at the rear bell, courtyard lantern, rear shutter and Mara lookout. Protect the mourners as a group; do not approach the roof alone." % story.defenses.size(),
		[{"label":"RETURN TO THE WAKE","action":"close"}])


func _retry_from_saved_checkpoint() -> void:
	if _modal() or travel_in_progress:
		return
	_talk("RETRY • LAST SAVED CHECKPOINT",
		"Reload the last offline checkpoint for this Night? Unsaved actions will be lost; previous chapter records remain intact.",
		[{"label":"RETRY LAST SAVED CHECKPOINT","action":"reload_saved"},
		 {"label":"KEEP PLAYING","action":"close"}])


func _apply_shared_settings() -> void:
	camera.position_smoothing_enabled = not prefs.reduced_motion
	if ambient != null:
		ambient.set_audio_level(prefs.audio_level)
	_sync_ui()

func _open_options() -> void:
	if dialogue.visible or ending.visible:
		return
	modal_backdrop.show()
	options.show()
	_sync_ui()
	print("NIGHT4_QA_OPTIONS_OPEN")

func _confirm_retreat() -> void:
	if _modal() or story.outcome != "":
		return
	_talk("SAFETY CHOICE","You may withdraw safely. The villagers stay alive, but the threat remains unresolved and the family may need another night of support.",
		[{"label":"RETURN TO SAFETY • PARTIAL RECORD","action":"retreat"},
		 {"label":"CONTINUE PROTECTING THE WAKE","action":"close"}])

func _auto_save() -> bool:
	story.player_position = player_pos
	var result := Save.write(story)
	if result and story.outcome != "":
		World.note_outcome(4,story.outcome)
	return result

func _save_feedback() -> void:
	if not _auto_save():
		save_error.popup_centered(Vector2i(600,180))
		return
	options.hide()
	_talk("FIELD RECORD","Night 4 saved offline. All three earlier chapter records remain intact.",
		[{"label":"CONTINUE","action":"close"}])

func _quit_with_save() -> void:
	if not _auto_save():
		save_error.popup_centered(Vector2i(600,190))
		return
	get_tree().quit()

func _save_menu() -> void:
	if not _auto_save():
		save_error.popup_centered(Vector2i(600,180))
		return
	get_node("/root/SceneTransit").call("change_to_file", "res://scenes/title.tscn")

func _travel_to_farm() -> void:
	if travel_in_progress or story.outcome == "":
		return
	if not _auto_save() or not World.begin_travel("night04","night05",story.outcome):
		save_error.popup_centered(Vector2i(600,180))
		return
	travel_in_progress = true
	motion = Vector2.ZERO
	observe_held = false
	print("TABI_WORLD_TRAVEL_WAKE_TO_FARM")
	get_node("/root/SceneTransit").call("change_to_file", World.scene_for("night05"))

func _return_to_ridge() -> void:
	if travel_in_progress:
		return
	if not _auto_save() or not World.begin_travel("night04","night03",story.outcome):
		save_error.popup_centered(Vector2i(600,180))
		return
	travel_in_progress = true
	motion = Vector2.ZERO
	observe_held = false
	print("TABI_WORLD_TRAVEL_WAKE_TO_RIDGE")
	get_node("/root/SceneTransit").call("change_to_file", World.scene_for("night03"))

func _show_ending() -> void:
	dialogue.hide()
	notes.hide()
	options.hide()
	ending.show()
	modal_backdrop.show()
	for child in ending.get_children():
		ending.remove_child(child)
		child.queue_free()
	var stack := _stack(ending)
	_label(stack,"NIGHT 4 • THE WAKE AFTERMATH",30,Color("#ebcf9c"))
	var after := ""
	match story.outcome:
		"resolve":
			after = "Every entry was watched. Aling Nena and the guests stayed together; the predator withdrew. The mourning family is safe, and the villagers choose to keep helping instead of blaming."
		"drive_away":
			after = "The winged threat fled before dawn. The wake survived, but a damaged window and frightened guests need repairs, reassurance and rest."
		"partial":
			after = "No one is lost. The family needs another protected vigil and follow-up care. The evidence remains available for a later return."
		_:
			after = "The apprentice withdrew safely. Residents remain alive, but the wake needs a return visit with coordinated protection."
	_label(stack,after,25,Color("#f3e6d0"))
	_label(stack,"COMMUNITY TRUST %d  •  THREE NIGHTS PRESERVED" % story.trust,
		20,Color("#a6d0b3"))
	_button(stack,"REVIEW FIELD NOTES",func():
		ending.hide()
		_open_notes()
	)
	_button(stack,"ENTER THE ABANDONED FARM (SAVE)",_travel_to_farm)
	_button(stack,"RETURN TO FLOOD RIDGE (SAVE)",_return_to_ridge)
	_button(stack,"SAVE & MAIN MENU",_save_menu)
	_sync_ui()
