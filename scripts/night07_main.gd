extends Node2D
## TABI-TABI Night 7 — Balete Grounds: The Promise of Remembrance.
## One continuous river-to-Balete route, evidence-led Ancient Keeper trial,
## meaningful endings and a PLAYABLE epilogue. No gore or punitive death.
const Story = preload("res://scripts/narrative/night07_state.gd")
const Save = preload("res://scripts/core/night07_save.gd")
const RiverStory = preload("res://scripts/narrative/night06_state.gd")
const RiverSave = preload("res://scripts/core/night06_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
const Prefs = preload("res://scripts/core/preferences.gd")
const SharedHUD = preload("res://scripts/ui/shared_hud.gd")
const Depth = preload("res://scripts/visuals/layered_25d.gd")
const Landscape = preload("res://scripts/visuals/folklore_landscape_25d.gd")
const AimPad = preload("res://scripts/ui/aim_pad.gd")
const PostgameResidents = preload("res://scripts/world/postgame_residents.gd")
const HERO: Texture2D = preload("res://assets/characters/apprentice.svg")
const BANTAY: Texture2D = preload("res://assets/characters/bantay.svg")
const MARA: Texture2D = preload("res://assets/characters/mara.svg")
const LOLA: Texture2D = preload("res://assets/characters/lola.svg")
const TREE: Texture2D = preload("res://assets/night07/ancient_balete.svg")
const SMALL_TREE: Texture2D = preload("res://assets/world/north_forest_tree.svg")
const LANTERN: Texture2D = preload("res://assets/world/lantern_post.svg")
const SOIL: Texture2D = preload("res://assets/world/soil_ground.svg")
const MAP := Rect2(-1100,-790,2350,1610)
const ENTRY := Vector2(-970,490)
const KEEPER := Vector2(565,-280)
const VERDICT := Vector2(525,-60)
const MEMORIAL := Vector2(190,-175)
const CLUE_POS := {
	"broken_waymark":Vector2(-725,270),
	"keeper_roots":Vector2(260,-85),
	"rescue_memorial":MEMORIAL,
	"flood_oath":Vector2(-270,145)
}
const PREP_POS := {
	"safe_footpath":Vector2(160,252),
	"witness_consent":Vector2(-125,-120),
	"remembrance_offering":Vector2(660,5)
}
const TRIAL_POS := [Vector2(210,220),Vector2(490,130),Vector2(720,-165)]
const CLUE_TEXT := {
	"broken_waymark":"A washed-out rescue marker still points uphill. The route was moved by people in fear, not by a monster. Its position matches the documented flood map.",
	"keeper_roots":"The Balete roots protected the high shelter but never crossed the river. The Keeper cannot rewrite the choices humans made in the flood.",
	"rescue_memorial":"A weathered family offering honours those who returned for others. Do not publicly name Sabel's husband without her consent.",
	"flood_oath":"Lola promised the displaced that their memory would be protected. Keeping private names safe became silence about an unequal evacuation."
}
const SCENE_STYLE := "shared-2.5d-layered-v1"
const SPEED := 247.0

var story = Story.new()
var prefs = Prefs.new()
var player_pos := Story.START
var bantay_pos := Story.START + Vector2(-46,28)
var camera: Camera2D
var hud: CanvasLayer
var controls: Control
var status_panel: PanelContainer
var status_stack: VBoxContainer
var objective: Label
var subtitle: Label
var pressure: Label
var waypoint: Label
var interaction_hint: Label
var backdrop: ColorRect
var dialogue: PanelContainer
var dialogue_speaker: Label
var dialogue_body: Label
var choices: VBoxContainer
var notes: PanelContainer
var notes_text: Label
var options: PanelContainer
var ending: PanelContainer
var save_error: AcceptDialog
var meter: ProgressBar
var motion := Vector2.ZERO
var look := Vector2.ZERO
var held: Dictionary = {}
var observe_held := false
var elapsed := 0.0
var walking := 0.0
var travel_in_progress := false
var qa_visual_stage_override := -1 # Android debug-only camera scenes; never saved.

func _ready() -> void:
	name = "TabiTabiNight7"
	set_meta("dimensional_art",SCENE_STYLE)
	set_meta("canon","promise-of-remembrance-v1")
	prefs.load_from()
	var river := RiverStory.new()
	var has_river := RiverSave.read(river)
	if not Save.read(story):
		if has_river:
			story.configure_from_river(river,World.read())
	player_pos = story.player_position
	var arrival: Dictionary = World.consume_arrival("night07")
	if str(arrival.get("from","")) == "night06":
		player_pos = Story.START
		print("TABI_WORLD_ARRIVAL_BALETE_FROM_RIVER")
	bantay_pos = player_pos + Vector2(-48,28)
	camera = Camera2D.new()
	camera.name = "Night07BaleteCamera"
	camera.position = player_pos
	camera.zoom = Vector2(1.02,1.02)
	camera.enabled = true
	camera.position_smoothing_enabled = not prefs.reduced_motion
	camera.position_smoothing_speed = 4.1
	add_child(camera)
	_build_ui()
	_refresh()
	if story.outcome != "" and not _postgame_active():
		_show_ending()
	elif story.phase == 0 and story.clues.is_empty():
		_talk("LOLA PASING • BALETE GROUNDS",
			"The flood records brought us to the oldest tree. The Keeper saved only the high refuge; it did not command the evacuation or rescue the far bank. We have to face the truth together without taking away anyone's right to privacy.",
			[{"label":"FOLLOW THE REAL OLD TRAIL","action":"close"}])
	print("NIGHT7_QA_SCENE_READY")

func _postgame_active() -> bool:
	var shared_clock := get_node_or_null("/root/PostgameClock")
	return shared_clock != null and shared_clock.is_active()

func _stage() -> int:
	if _postgame_active():
		return get_node("/root/PostgameClock").light_stage()
	if OS.has_feature("debug") and qa_visual_stage_override >= 0:
		return qa_visual_stage_override
	if story.phase <= 1:
		return 1
	if story.phase in [2,3,4]:
		return 3
	return 0

func _modal() -> bool:
	return dialogue.visible or notes.visible or options.visible or ending.visible

func _process(delta: float) -> void:
	elapsed += delta
	var axis := (Input.get_vector("ui_left","ui_right","ui_up","ui_down")+motion).limit_length()
	if _modal() or travel_in_progress:
		axis = Vector2.ZERO
	if axis.length() > .04:
		if not prefs.reduced_motion:
			walking += delta * 9.0
		var direction := Vector2(axis.x + axis.y * .40,axis.y * .76 - axis.x * .16).normalized()
		var candidate := player_pos + direction * SPEED * delta
		candidate.x = clampf(candidate.x,MAP.position.x+65,MAP.end.x-65)
		candidate.y = clampf(candidate.y,MAP.position.y+70,MAP.end.y-70)
		# Exposed roots and old flood drop-offs are visibly marked. The road
		# around the Balete is always wide enough to reach all quest stations.
		if candidate.y > 595 and candidate.x > -650:
			candidate.y = 595.0
		player_pos = candidate
	bantay_pos = bantay_pos.lerp(player_pos + Vector2(-51,32),clampf(delta*3.1,0,1))
	camera.position = camera.position.lerp(player_pos + look*32.0,
		1.0 if prefs.reduced_motion else clampf(delta*4.1,0,1))
	if story.phase == 3 and not _modal() and not _postgame_active():
		var site: Vector2 = TRIAL_POS[mini(story.trial_index,2)]
		if story.observe_tick(delta,player_pos.distance_to(site)<130.0,
			observe_held,prefs.story_assist):
			observe_held = false
			_save_story()
			_trial_choices()
		elif story.trial_failed:
			observe_held = false
			_talk("BANTAY • BACK TO SAFE ROOTS",
				"The tree's roots shake, but you are safe at the marked path. Your observations were not lost. Retry this step without rushing.",
				[{"label":"RETRY CURRENT TRIAL STEP","action":"retry_trial"},
				 {"label":"RETURN TO THE RIVER TRAIL","action":"retreat"}])
	if meter != null:
		meter.visible = story.phase == 3 and not story.current_ready and not story.trial_failed
		meter.value = story.observation*100.0
	if pressure != null:
		pressure.text = "KEEPER PRESSURE %d%%  •  TRIAL %d/3  •  NOTES %d/4" % [
			roundi(story.tension*100.0),story.trial_index,story.clues.size()]
	_refresh_hint()
	queue_redraw()

func _draw() -> void:
	var night := _stage() >= 2
	var late: bool = story.phase >= 5 or _postgame_active()
	draw_rect(MAP.grow(260), Color("#152e35") if night else Color("#355a59"))
	Landscape.parallax_ridges(self,MAP.grow(190),camera.position,7,_stage())
	for i in range(26):
		var t: float = float(i)/25.0
		var shade := Color("#254744").lerp(Color("#70866b"),t)
		if night:
			shade = Color("#1c3037").lerp(Color("#3f5351"),t)
		draw_rect(Rect2(-1620,-760+float(i)*62.0,3600,64),shade)
	draw_texture_rect(SOIL,Rect2(-1400,-780,3150,1710),false,Color(1,1,1,.19))
	# Continuous raised path physically joins the Night 6 hill crossing.
	var road := PackedVector2Array([
		ENTRY,Vector2(-785,416),Vector2(-595,286),
		Vector2(-362,173),Vector2(-125,110),Vector2(160,185),
		Vector2(390,105),Vector2(600,-64),Vector2(724,-260)])
	draw_polyline(road,Color("#203d39"),127,true)
	draw_polyline(road,Color("#a48c6b"),90,true)
	for i in range(road.size()-1):
		Landscape.trail_stones(self,road[i],road[i+1],8,93,night)
	# Leftover high-water channel: below the road, never a fake disconnected void.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-1460,565),Vector2(-1040,590),Vector2(-780,705),
		Vector2(-400,805),Vector2(-1460,1070)]),
		Color("#254e57") if night else Color("#427679"))
	draw_polyline(PackedVector2Array([Vector2(-1410,566),Vector2(-1040,592),
		Vector2(-780,708),Vector2(-440,801)]),Color("#b8ad8c"),8,true)
	for i in range(20):
		var n := float(i)
		var at := Vector2(-1020+n*116,-540+sin(n*.61)*45)
		if at.distance_to(KEEPER)<470:
			continue
		Landscape.rock(self,at,16.0+float(i%3)*8,not night)
	for at in [Vector2(-880,-220),Vector2(-520,-420),Vector2(25,-430),
		Vector2(1160,-180),Vector2(1010,480)]:
		Depth.paint_grounded(self,SMALL_TREE,at,Vector2(250,290),Color("#c6d3b5"),.25)
	# Physical safe path and ancestral tree occupy the same world coordinates.
	Depth.paint_grounded(self,TREE,KEEPER+Vector2(-50,38),
		Vector2(790,760),Color("#bac6b3") if night else Color.WHITE,.55)
	# A second translucent canopy pass creates distant spiritual light without
	# a monster-jump-scare or full-screen overlay.
	if night and story.phase in [2,3,4]:
		for ring in range(5,0,-1):
			draw_circle(KEEPER + Vector2(-85,-455),
				110.0+float(ring)*55,Color(.79,.71,.48,.006+float(6-ring)*.003))
	if late:
		draw_circle(MEMORIAL+Vector2(10,-22),48,Color(.96,.80,.49,.08))
	# The memorial is a stone plinth beside the path; it names no private witness.
	Landscape.rock(self,MEMORIAL,87.0,not night)
	draw_rect(Rect2(MEMORIAL+Vector2(-39,-42),Vector2(85,9)),Color("#c7b28a"))
	draw_string(ThemeDB.fallback_font,MEMORIAL+Vector2(-86,70),
		"MEMORY STONE",HORIZONTAL_ALIGNMENT_LEFT,180,18,Color("#eee0ac"))
	for key in Story.CLUES:
		if story.phase <= 1 or _postgame_active():
			_mark_station(CLUE_POS[key],key.replace("_"," ").to_upper(),
				story.clues.has(key),night)
	for key in Story.PREPARATIONS:
		if story.phase == 2:
			_mark_station(PREP_POS[key],key.replace("_"," ").to_upper(),
				story.preparations.has(key),night)
	if (story.phase >= 3 and story.phase <= 4) or qa_visual_stage_override == 3:
		for i in range(TRIAL_POS.size()):
			var foot: Vector2 = TRIAL_POS[i]
			var active: bool = i == story.trial_index
			Landscape.rock(self,foot,91.0,not night)
			draw_circle(foot+Vector2(0,-34),31.0,
				Color(.95,.77,.42,.30 if active else .07))
			draw_string(ThemeDB.fallback_font,foot+Vector2(-74,73),
				"TRIAL STONE %d" % (i+1),HORIZONTAL_ALIGNMENT_LEFT,190,17,
				Color("#f0daac") if active else Color("#a8a995"))
	_mark_station(VERDICT,"KEEPER'S PACT",story.outcome!="",night)
	Landscape.mist(self,KEEPER+Vector2(-80,60),730,elapsed,
		not prefs.reduced_motion,night)
	for at in [Vector2(-575,-5),Vector2(53,272),Vector2(780,110)]:
		Depth.lantern(self,LANTERN,at,Vector2(95,165),night)
	# People are NOT visible in outdoor routes at night unless story requires
	# their participation. The safe finale keeps Lola and Mara near the path.
	if story.phase <= 2 and story.outcome == "":
		Depth.paint_grounded(self,LOLA,Vector2(-228,-4),Vector2(97,135),Color.WHITE,.3)
		Depth.paint_grounded(self,MARA,Vector2(-135,50),Vector2(99,140),Color.WHITE,.3)
	if story.phase >= 4 and story.phase <= 5:
		Depth.paint_grounded(self,MARA,Vector2(290,30),Vector2(103,145),Color.WHITE,.3)
		Depth.paint_grounded(self,LOLA,Vector2(220,80),Vector2(103,140),Color.WHITE,.3)
	var bob := 0.0 if prefs.reduced_motion else absf(sin(walking))*2.9
	Depth.paint_grounded(self,BANTAY,bantay_pos+Vector2(0,18),
		Vector2(100,106),Color.WHITE,.31,bob)
	Depth.paint_grounded(self,HERO,player_pos+Vector2(0,9),
		Vector2(108,143),Color.WHITE,.40,bob)
	PostgameResidents.paint(self,"night07",elapsed,prefs.reduced_motion,player_pos)
	draw_string(ThemeDB.fallback_font,ENTRY+Vector2(15,-113),
		"RIVER TRAIL • RETURN",HORIZONTAL_ALIGNMENT_LEFT,365,20,Color("#efdda9"))
	draw_string(ThemeDB.fallback_font,KEEPER+Vector2(-270,-820),
		"THE ANCIENT BALETE",HORIZONTAL_ALIGNMENT_LEFT,520,27,Color("#e9ddb1"))

func _mark_station(foot: Vector2,word: String,checked: bool,dark: bool) -> void:
	var ink := Color("#a0cbb1") if checked else Color("#e6c88f")
	draw_circle(foot+Vector2(0,-27),12,ink)
	draw_circle(foot+Vector2(0,-27),25,Color(ink.r,ink.g,ink.b,.12))
	draw_string(ThemeDB.fallback_font,foot+Vector2(-101,40),
		word,HORIZONTAL_ALIGNMENT_LEFT,265,16,
		Color("#c4d4c8") if checked else Color("#f5dfab"))

func _build_ui() -> void:
	hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	controls = Control.new()
	controls.name = "SharedGameplayHUD"
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(controls)
	var card: Dictionary = SharedHUD.create_status_card(
		controls,"TABI-TABI  •  NIGHT 7 / BALETE",prefs.text_scale)
	status_panel = card["panel"]
	status_stack = card["stack"]
	objective = card["objective"]
	status_stack.minimum_size_changed.connect(func(): call_deferred("_fit_status_card"))
	subtitle = _label(status_stack,"",18,Color("#b9d9cc"))
	pressure = _label(status_stack,"",17,Color("#e2d2a5"))
	waypoint = _label(status_stack,"",17,Color("#c3d5be"))
	interaction_hint = SharedHUD.make_nearby_prompt(controls,prefs.text_scale)
	for dir in SharedHUD.MOVE_POSITIONS:
		var at: Vector2 = SharedHUD.MOVE_POSITIONS[dir]
		var symbol: String = str({"up":"▲","left":"◀","right":"▶","down":"▼"}.get(dir))
		var move := SharedHUD.make_gameplay_button(controls,symbol,at,Vector2(70,65),
			func():_hold_move(dir,true),func():_hold_move(dir,false),prefs.text_scale)
		move.name = "Move_"+dir
		move.mouse_exited.connect(func():_hold_move(dir,false))
	for action in SharedHUD.ACTION_POSITIONS:
		var at: Vector2 = SharedHUD.ACTION_POSITIONS[action]
		match action:
			"FIELD NOTES":
				SharedHUD.make_gameplay_button(controls,action,at,Vector2(180,60),
					_open_notes,func():pass,prefs.text_scale)
			"HOLD OBSERVE":
				var btn := SharedHUD.make_gameplay_button(controls,action,at,Vector2(180,60),
					func():observe_held=true,func():observe_held=false,prefs.text_scale)
				btn.mouse_exited.connect(func():observe_held=false)
			"INTERACT":
				SharedHUD.make_gameplay_button(controls,action,at,Vector2(180,60),
					_interact,func():pass,prefs.text_scale)
			"SAFE RETREAT":
				SharedHUD.make_gameplay_button(controls,action,at,Vector2(180,60),
					_return_river,func():pass,prefs.text_scale)
	var prep := SharedHUD.make_gameplay_button(controls,"PREPARE",
		Vector2(1050,276),Vector2(180,56),_open_preparation,func():pass,prefs.text_scale)
	prep.name = "PrepareButton"
	var save_btn := SharedHUD.make_gameplay_button(controls,"SAVE",
		Vector2(1050,345),Vector2(85,52),_save_feedback,func():pass,prefs.text_scale)
	save_btn.name = "SaveButton"
	var retry := SharedHUD.make_gameplay_button(controls,"RETRY",
		Vector2(1142,345),Vector2(88,52),_retry_saved,func():pass,prefs.text_scale)
	retry.name = "RetryButton"
	SharedHUD.make_options_button(controls,_open_options,prefs.text_scale)
	var pad := AimPad.new()
	pad.name = "SharedLookPad"
	pad.prompt_text = "LOOK AROUND"
	pad.anchor_left = 1.0
	pad.anchor_right = 1.0
	pad.anchor_top = 1.0
	pad.anchor_bottom = 1.0
	pad.offset_left = -435
	pad.offset_right = -260
	pad.offset_top = -205
	pad.offset_bottom = -40
	pad.aim_changed.connect(func(value: Vector2): look=value)
	pad.aim_released.connect(func():look=Vector2.ZERO)
	controls.add_child(pad)
	meter = ProgressBar.new()
	meter.anchor_left = .33
	meter.anchor_right = .68
	meter.anchor_top = 0
	meter.anchor_bottom = 0
	meter.offset_top = 74
	meter.offset_bottom = 98
	meter.max_value = 100
	meter.show_percentage = false
	controls.add_child(meter)
	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0,0,0,.62)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(backdrop)
	dialogue = _panel(backdrop,"Night7Dialogue",Vector4(.15,.11,.85,.89))
	var ds := _stack(dialogue)
	dialogue_speaker = _label(ds,"",26,Color("#efd69e"))
	dialogue_body = _label(ds,"",23,Color("#e9eadf"))
	dialogue_body.custom_minimum_size.y = 88
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation",6)
	ds.add_child(choices)
	notes = _panel(backdrop,"Night7FieldNotes",Vector4(.12,.07,.88,.93))
	var ns := _stack(notes)
	_label(ns,"THE PROMISE OF REMEMBRANCE • NOTEBOOK",28,Color("#e5cea1"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ns.add_child(scroll)
	notes_text = _label(scroll,"",21,Color("#e4e8d9"))
	notes_text.custom_minimum_size.x = 600
	_button(ns,"RETURN TO BALETE GROUNDS",func():notes.hide();_sync_ui())
	options = _panel(backdrop,"Night7Options",Vector4(.22,.14,.78,.86))
	var os := _stack(options)
	_label(os,"PAUSE • NIGHT 7",30,Color("#f0daa8"))
	_button(os,"SAVE OFFLINE",_save_feedback)
	_button(os,"FIELD NOTES",_open_notes)
	_button(os,"SAVE & MAIN MENU",_save_menu)
	_button(os,"CLOSE",func():options.hide();_sync_ui())
	ending = _panel(backdrop,"Night7Epilogue",Vector4(.13,.10,.87,.90))
	save_error = AcceptDialog.new()
	save_error.dialog_text = "Unable to save offline. Please check available storage."
	hud.add_child(save_error)
	dialogue.hide()
	notes.hide()
	options.hide()
	ending.hide()
	backdrop.hide()
	_sync_ui()

func _fit_status_card() -> void:
	if status_panel == null or status_stack == null or not is_inside_tree():
		return
	var needed := status_stack.get_combined_minimum_size().y+30.0
	status_panel.offset_bottom = clampf(needed,145.0,
		get_viewport().get_visible_rect().size.y*.68)

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

func _label(parent: Node,value: String,font_size: int,tint: Color) -> Label:
	var l := Label.new()
	l.text = value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",roundi(font_size*prefs.text_scale))
	l.add_theme_color_override("font_color",tint)
	parent.add_child(l)
	return l

func _button(parent: Node,label: String,callback: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.clip_text = true
	SharedHUD.style_modal_button(b,false,true,prefs.text_scale)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _hold_move(dir: String,on: bool) -> void:
	held[dir] = on
	motion = Vector2(float(int(held.get("right",false))-int(held.get("left",false))),
		float(int(held.get("down",false))-int(held.get("up",false)))).limit_length()

func _nearby() -> String:
	if player_pos.distance_to(ENTRY)<145:
		return "return_river"
	if _postgame_active():
		return PostgameResidents.nearby(self,"night07",player_pos)
	match story.phase:
		0:
			for id in Story.CLUES:
				if not story.clues.has(id) and player_pos.distance_to(CLUE_POS[id])<140:
					return id
		1:
			if player_pos.distance_to(VERDICT)<175:
				return "deduce"
		2:
			for id in Story.PREPARATIONS:
				if not story.preparations.has(id) and player_pos.distance_to(PREP_POS[id])<140:
					return id
			if player_pos.distance_to(VERDICT)<190:
				return "begin_trial"
		3:
			if player_pos.distance_to(TRIAL_POS[mini(story.trial_index,2)])<155:
				return "observe"
		4:
			if player_pos.distance_to(VERDICT)<190:
				return "verdict"
		5:
			if player_pos.distance_to(MEMORIAL)<175:
				return "epilogue"
	return ""

func _interact() -> void:
	if _modal() or travel_in_progress:
		return
	var key := _nearby()
	if key == "return_river":
		_return_river()
		return
	if key.begins_with("postgame:"):
		_talk(PostgameResidents.speaker(key),PostgameResidents.talk(self,key),
			[{"label":"CONTINUE WALKING","action":"close"}])
		return
	if story.phase == 0 and Story.CLUES.has(key):
		if story.inspect(key):
			_save_story()
			_talk("FIELD EVIDENCE • "+key.replace("_"," ").to_upper(),
				str(CLUE_TEXT[key]),[{"label":"RECORD IN NOTEBOOK","action":"close"}])
	elif key == "deduce":
		_talk("LOLA & MARA • WHO REMEMBERS THE FLOOD?",
			"Was the Ancient Keeper responsible for choosing whom to evacuate? The records confirm a dangerous current, unequal protection, and an independent rescuer. What do we conclude?",
			[{"label":"HUMAN CHOICES • DOCUMENTED WITNESSES","action":"deduce_true"},
			 {"label":"THE TREE ORDERED THE EVACUATION","action":"deduce_false"}])
	elif story.phase == 2 and Story.PREPARATIONS.has(key):
		if story.prepare(key):
			_save_story()
			var evidence := {
				"safe_footpath":"Bantay and the neighbours clear the safe roots and mark the path. We do not damage the tree or disguise unstable ground.",
				"witness_consent":"Dado's voluntary testimony stays protected. No public name is required and a refusal remains valid.",
				"remembrance_offering":"The community lays woven cloth and a repaired lantern by the memorial, without claiming that the spirit replaces survivors."
			}
			_talk("PREPARATION • "+key.replace("_"," ").to_upper(),
				str(evidence[key]),[{"label":"CONTINUE","action":"close"}])
	elif key == "begin_trial":
		_talk("LOLA PASING • THE FINAL COVENANT",
			"The Keeper's three tests are to remember the missing, protect those alive, and share responsibility. Sabel alone decides whether her husband's name is public.",
			[{"label":"KEEP THE FAMILY REMEMBRANCE PRIVATE","action":"prepare_private"},
			 {"label":"PUBLIC REMEMBRANCE ONLY WITH CONSENT","action":"prepare_public"}])
	elif key == "observe":
		if story.current_ready:
			_trial_choices()
		else:
			_talk("BANTAY • SAFE TRIAL STONE",
				"Stand beside the visible stone and HOLD OBSERVE until the pressure settles. Then answer the Keeper from the documented truth.",
				[{"label":"I WILL OBSERVE FIRST","action":"close"}])
	elif key == "verdict":
		_verdict_choices()
	elif key == "epilogue":
		_show_ending()
	else:
		_talk("BANTAY • FOLLOW THE GROUNDED TRAIL",
			"Use the compass and your Field Notes. Each marked station is reachable from the old river road.",
			[{"label":"CONTINUE","action":"close"}])
	_refresh()

func _trial_choices() -> void:
	if story.phase != 3 or not story.current_ready:
		return
	var captions := [
		"First memory: the flood erased voices, but records still show who was left behind. What deserves remembrance?",
		"Second memory: neighbours are alive but still vulnerable. How do we honour those who choose silence?",
		"Third memory: a Keeper cannot repair a village by itself. Who must keep the paths and public records safe?"
	]
	_talk("ANCIENT KEEPER • TRIAL %d/3" % [story.trial_index+1],
		captions[story.trial_index],
		[{"label":"REMEMBER THE UNACCOUNTED FOR","action":"remember_losses"},
		 {"label":"PROTECT LIVING SURVIVORS","action":"protect_living"},
		 {"label":"SHARE RESPONSIBILITY IN THE BARRIO","action":"share_responsibility"}])

func _verdict_choices() -> void:
	if story.phase != 4:
		return
	var actions: Array[Dictionary] = []
	if story.available_results().has("renewal"):
		actions.append({"label":"RENEWAL • OPEN THE ROADS WITH CARE","action":"ending_renewal"})
	actions.append({"label":"REPAIR • KEEP REBUILDING TOGETHER","action":"ending_repair"})
	actions.append({"label":"GUARDED • PROTECT THE THREATENED PLACES","action":"ending_guarded"})
	_talk("THE ANCIENT KEEPER • ONE FINAL PROMISE",
		"The truth is known. No power can undo the missing or force forgiveness. How will the people of Barrio Lawom carry remembrance into tomorrow?",
		actions)

func _choice(value: String) -> void:
	if value == "close":
		_close_dialogue()
		return
	if value == "reload":
		get_tree().call_deferred("reload_current_scene")
		return
	if value in ["deduce_true","deduce_false"]:
		if story.deduce("records_and_witnesses" if value=="deduce_true" else "spirit_blamed"):
			_save_story()
			_talk("LOLA PASING • NO MORE SILENCE",
				"The Keeper could shelter one ridge. The evacuation choices, the independent sacrifice, and our long silence belonged to human beings. We will not blame the dead or erase their consent.",
				[{"label":"PREPARE THE REMEMBRANCE","action":"close"}])
		else:
			_talk("MARA • CHECK THE SOURCES",
				"The rescue order and flood gauge were human records. The Keeper did not direct the abandoned boats. Try again with the independent evidence.",
				[{"label":"REVISIT THE EVIDENCE","action":"close"}])
	elif value in ["prepare_private","prepare_public"]:
		if not story.choose_remembrance("private" if value=="prepare_private" else "consented"):
			_talk("LOLA • SABEL MUST CHOOSE",
				"Sabel did not consent to a public memorial. Her husband's courage can be remembered without publishing her private grief.",
				[{"label":"RESPECT THE FAMILY'S CHOICE","action":"close"}])
		elif story.begin_trial():
			_save_story()
			_talk("ANCIENT KEEPER • THREE ROOTS",
				"The tree trembles but will not attack the innocent. Follow three separate safe stones. At each one HOLD OBSERVE, then answer from evidence.",
				[{"label":"BEGIN THE FINAL TRIAL","action":"close"}])
		else:
			_talk("BANTAY • NOT READY",
				"Prepare the safe path, witness privacy and remembrance offering before approaching the roots.",
				[{"label":"FINISH PREPARATIONS","action":"close"}])
	elif Story.TRIAL.has(value):
		if story.respond(value):
			_save_story()
			if story.phase == 4:
				_talk("KEEPER • THE PROMISE REMAINS",
					"The roots ease. The flood cannot be undone, and those we lost remain part of the barrio. The living may choose their responsibilities without repeating a false story.",
					[{"label":"MAKE THE FINAL COVENANT","action":"close"}])
			else:
				_talk("BANTAY • SAFE GROUND",
					"The light settles. Walk to the next marked stone; the trail is still open.",
					[{"label":"FOLLOW THE NEXT ROOT","action":"close"}])
		else:
			_talk("KEEPER • THE QUESTION IS NOT FINISHED",
				"That response belongs to another memory. Return to the same stone, observe, and answer what this one asks.",
				[{"label":"TRY THE SAME STONE","action":"close"}])
	elif value == "retry_trial":
		if story.retry_trial():
			_save_story()
			player_pos = TRIAL_POS[mini(story.trial_index,2)]+Vector2(-74,32)
			_close_dialogue()
	elif value.begins_with("ending_"):
		var desired := value.trim_prefix("ending_")
		if story.commit_result(desired):
			if _save_story():
				_show_ending()
			else:
				save_error.popup_centered(Vector2i(600,175))
	elif value == "complete_epilogue":
		_finish_epilogue()
	elif value == "retreat":
		_return_river()
	_refresh()

func _talk(speaker: String,line: String,actions: Array[Dictionary]) -> void:
	ending.hide()
	options.hide()
	notes.hide()
	dialogue.show()
	dialogue_speaker.text = speaker
	dialogue_body.text = line
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	for option in actions:
		var choice_id: String = str(option["action"])
		_button(choices,str(option["label"]),func():_choice(choice_id))
	_sync_ui()

func _close_dialogue() -> void:
	dialogue.hide()
	_sync_ui()

func _sync_ui() -> void:
	if backdrop == null:
		return
	var blocked := _modal()
	backdrop.visible = blocked
	controls.visible = not blocked
	if blocked:
		motion = Vector2.ZERO
		held.clear()
		observe_held = false

func _refresh() -> void:
	if objective == null:
		return
	match story.phase:
		0:
			objective.text = "INVESTIGATE THE BALETE • Sources %d/4" % story.clues.size()
			subtitle.text = "DUSK • THE OLD FLOOD PATH"
		1:
			objective.text = "COMPARE THE EVIDENCE • Speak at the Keeper's Pact marker"
			subtitle.text = "EVENING • HUMAN RECORDS, NOT SPIRIT BLAME"
		2:
			objective.text = "PREPARE THREE ACTS OF REMEMBRANCE • %d/3" % story.preparations.size()
			subtitle.text = "NIGHT • SAFETY, CONSENT AND MEMORIAL"
		3:
			objective.text = "THREE SAFE TRIAL STONES • %d/3 • HOLD OBSERVE" % story.trial_index
			subtitle.text = "MIDNIGHT • NO ONE LEFT WITHOUT A CHOICE"
		4:
			objective.text = "RETURN TO THE KEEPER • CHOOSE THE COMMUNITY'S FUTURE"
			subtitle.text = "BEFORE DAWN • THE ANCIENT COVENANT"
		5:
			objective.text = "FINAL EPILOGUE • HONOUR THE PROMISE AT THE MEMORY STONE"
			subtitle.text = "DAWN • THE VILLAGE REMAINS"
		6:
			if _postgame_active():
				var time_node := get_node("/root/PostgameClock")
				objective.text = "BALETE GROUNDS • FREE ROAM  %s" % time_node.clock_label()
			else:
				objective.text = "EPILOGUE RECORD • COMPLETE THE SAVED ENDING"
			subtitle.text = "PEACEFUL AFTERMATH • RETURN TO ALL SEVEN REGIONS"
	_refresh_hint()

func _refresh_hint() -> void:
	if interaction_hint == null:
		return
	var target := _nearby()
	interaction_hint.text = "FOLLOW THE VISIBLE PATH" if target == "" else "INTERACT • " + target.replace("_"," ").replace("postgame:","").to_upper()
	var dest := ENTRY
	var title := "RIVER ROAD • RETURN"
	match story.phase:
		0:
			for id in Story.CLUES:
				if not story.clues.has(id):
					dest = CLUE_POS[id]
					title = id.replace("_"," ").to_upper()
					break
		1:
			dest = VERDICT
			title = "FINAL EVIDENCE DEDUCTION"
		2:
			dest = VERDICT
			title = "ANCIENT KEEPER PREPARATION"
			for id in Story.PREPARATIONS:
				if not story.preparations.has(id):
					dest = PREP_POS[id]
					title = id.replace("_"," ").to_upper()
					break
		3:
			dest = TRIAL_POS[mini(story.trial_index,2)]
			title = "TRIAL STONE • HOLD OBSERVE"
		4:
			dest = VERDICT
			title = "FINAL VERDICT"
		5:
			dest = MEMORIAL
			title = "EPILOGUE MEMORY STONE"
		6:
			dest = ENTRY
			title = "RETURN TO THE RIVER"
	waypoint.text = "%s • %d STEPS" % [title,roundi(player_pos.distance_to(dest)/12.0)]

func _open_notes() -> void:
	if _modal() and not options.visible and not ending.visible:
		return
	options.hide()
	ending.hide()
	notes.show()
	notes_text.text = "BALETE GROUNDS • THE PROMISE OF REMEMBRANCE\n\n"
	for id in Story.CLUES:
		notes_text.text += ("[OBSERVED] " if story.clues.has(id) else "[MISSING] ")+id.replace("_"," ")+"\n"
	notes_text.text += "\nThe Ancient Keeper guarded the HIGH refuge only. The rescue cancellation was a human decision. A separate rescuer crossed to the far bank. These facts come from records and independent witnesses, not from spectral visions.\n"
	notes_text.text += "\nDADO'S CONSENT: %s  •  SABEL'S CONSENT: %s\n" % [story.dado_consent,story.sabel_consent]
	notes_text.text += "No public memorial without a family's permission.\n"
	for id in Story.PREPARATIONS:
		notes_text.text += ("[READY] " if story.preparations.has(id) else "[PENDING] ")+id.replace("_"," ")+"\n"
	notes_text.text += "\nTRIAL %d/3  •  PRESSURE %d%%  •  SAFE RETRY AVAILABLE\n" % [story.trial_index,roundi(story.tension*100)]
	var ledger: Dictionary = World.read()
	var records: Dictionary = ledger.get("outcomes", {})
	for night in range(1,8):
		notes_text.text += "NIGHT %d: %s\n" % [night,str(records.get("night%02d" % night,"UNRESOLVED"))]
	notes_text.text += "\nThe future is not an instant happy reset; workers, children and survivors rebuild with the consequences of their choices.\n"
	_sync_ui()

func _open_preparation() -> void:
	if _modal():
		return
	_talk("THE KEEPER'S SAFE TRIAL",
		"Observe first. Avoid unstable roots and damaged waymarks. Record what the documents actually prove, respect Sabel and Dado's right to privacy, and hold OBSERVE at each marked stone.",
		[{"label":"RETURN TO THE PATH","action":"close"}])

func _open_options() -> void:
	if dialogue.visible or ending.visible:
		return
	options.show()
	_sync_ui()

func _retry_saved() -> void:
	if _modal():
		return
	_talk("RETRY • SAVED NIGHT 7 CHECKPOINT",
		"Reload your last offline checkpoint? Earlier six chapter records are not erased.",
		[{"label":"RELOAD LAST SAVED STEP","action":"reload"},
		 {"label":"KEEP PLAYING","action":"close"}])

func _save_story() -> bool:
	story.player_position = player_pos
	if not Save.write(story):
		return false
	if story.outcome != "":
		return World.note_outcome(7,story.outcome)
	return true

func _save_feedback() -> void:
	if not _save_story():
		save_error.popup_centered(Vector2i(600,175))
		return
	options.hide()
	_talk("OFFLINE RECORD SAVED","Night 7 checkpoint saved. All earlier chapters remain intact.",
		[{"label":"CONTINUE","action":"close"}])

func _save_menu() -> void:
	if not _save_story():
		save_error.popup_centered(Vector2i(600,175))
		return
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func _return_river() -> void:
	if travel_in_progress:
		return
	if not _save_story() or not World.begin_travel("night07","night06",story.outcome):
		save_error.popup_centered(Vector2i(600,175))
		return
	travel_in_progress = true
	motion = Vector2.ZERO
	observe_held = false
	print("TABI_WORLD_TRAVEL_BALETE_TO_RIVER")
	get_tree().change_scene_to_file(World.scene_for("night06"))

func _show_ending() -> void:
	dialogue.hide()
	notes.hide()
	options.hide()
	ending.show()
	for child in ending.get_children():
		ending.remove_child(child)
		child.queue_free()
	var box := _stack(ending)
	_label(box,"NIGHT 7 • THE PROMISE OF REMEMBRANCE",27,Color("#eddaad"))
	var summary := {
		"renewal":"The valley is peaceful but not unscarred. The truth is documented, families guide their own remembrance, and roads and fishing livelihoods reopen with care.",
		"repair":"The ancient covenant eases; the village rebuilds slowly. Some dangers and wounds remain, but neighbours work together rather than blame the lost.",
		"guarded":"The Keeper still shelters fragile places. Safe roads remain connected, but protected boundaries and patient community repairs matter more than a festival."
	}
	_label(box,str(summary.get(story.outcome,"The truth and its consequences remain.")),
		22,Color("#e8ebdc"))
	_label(box,"SABEL'S PUBLIC REMEMBRANCE: %s • DADO: %s" %
		[story.sabel_consent.to_upper(),story.dado_consent.to_upper()],
		18,Color("#c6d7bb"))
	_label(box,"The missing cannot return. The community can remember and choose how to live from this morning onward.",20,Color("#e0d5b4"))
	if not _postgame_active():
		_button(box,"COMPLETE EPILOGUE • ENTER LIVING WORLD",func():_choice("complete_epilogue"))
	else:
		_button(box,"CONTINUE FREE ROAM",func():ending.hide();_sync_ui())
	_button(box,"REVIEW FINAL NOTEBOOK",_open_notes)
	_button(box,"SAVE & MAIN MENU",_save_menu)
	_sync_ui()

func _finish_epilogue() -> void:
	# No finale bypass: commit the authored ending, persist the seventh result,
	# then let the world ledger verify ALL seven outcomes before starting time.
	if story.phase == 5:
		if not story.finish_epilogue():
			return
	if not _save_story() or not World.finish_epilogue():
		save_error.popup_centered(Vector2i(600,175))
		return
	var clock := get_node_or_null("/root/PostgameClock")
	if clock != null:
		clock.refresh()
	ending.hide()
	_sync_ui()
	_refresh()
	_talk("EPILOGUE • THE FIRST ORDINARY MORNING",
		"The lanterns go out at sunrise. Fisherfolk return to their boats when the water is safe; farmers check their pens, the school reopens, and the remembered names stay protected. Every connected trail remains walkable. The sun now rises and sets without your command.",
		[{"label":"WALK THE LIVING BARRIO","action":"close"}])
	print("NIGHT7_EPILOGUE_COMPLETE_AUTOCYCLE")

func _unhandled_input(event: InputEvent) -> void:
	# Android debug APK screenshot QA only; never mutates story or saves.
	if OS.get_name() == "Android" and OS.has_feature("debug") and event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode in [KEY_F3,KEY_F6,KEY_F9,KEY_F11]:
			if dialogue.visible:
				_close_dialogue()
			notes.hide()
			options.hide()
			ending.hide()
			match key.keycode:
				KEY_F3:
					player_pos = Vector2(-605,265)
					qa_visual_stage_override = 1
					print("NIGHT7_QA_ROAD_DUSK")
				KEY_F6:
					player_pos = VERDICT+Vector2(-45,130)
					qa_visual_stage_override = 0
					print("NIGHT7_QA_BALETE_DAY")
				KEY_F9:
					player_pos = TRIAL_POS[1]
					qa_visual_stage_override = 3
					print("NIGHT7_QA_KEEPER_NIGHT")
				KEY_F11:
					player_pos = MEMORIAL+Vector2(0,145)
					qa_visual_stage_override = 0
					print("NIGHT7_QA_MEMORIAL_DAWN")
			bantay_pos = player_pos+Vector2(-46,28)
			camera.position = player_pos
			_sync_ui()
			_refresh()
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_accept"):
		if dialogue.visible:
			_choice("close")
		else:
			_interact()
	if event.is_action_pressed("ui_cancel"):
		if dialogue.visible:
			_choice("close")
		elif notes.visible:
			notes.hide()
			_sync_ui()
		elif options.visible:
			options.hide()
			_sync_ui()
		else:
			_open_options()
