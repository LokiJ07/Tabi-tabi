extends Node2D
## Tabi-tabi Night 5: Sigbin of the Abandoned Farm.
## Continuous from Night 4, genuine investigation and nonviolent animal rescue.
const Story = preload("res://scripts/narrative/night05_state.gd")
const Save = preload("res://scripts/core/night05_save.gd")
const Night04State = preload("res://scripts/narrative/night04_state.gd")
const Night04Save = preload("res://scripts/core/night04_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
const Preferences = preload("res://scripts/core/preferences.gd")
const SharedHUD = preload("res://scripts/ui/shared_hud.gd")
const Walkability = preload("res://scripts/world/shared_walkability_2d.gd")
const PostgameResidents = preload("res://scripts/world/postgame_residents.gd")
const DialogueMotion = preload("res://scripts/ui/shared_dialogue_motion.gd")
const DimensionalArt = preload("res://scripts/visuals/layered_25d.gd")
const NightWindows = preload("res://scripts/visuals/nighttime_windows.gd")
const Landscape = preload("res://scripts/visuals/folklore_landscape_25d.gd")
const FarmArt = preload("res://scripts/visuals/night05_farm_art.gd")
const SigbinPresence = preload("res://scripts/visuals/night05_sigbin_presence.gd")
const Atmosphere = preload("res://scripts/visuals/shared_immersive_atmosphere.gd")
const Ambient = preload("res://scripts/audio/night05_ambience.gd")
const AimPad = preload("res://scripts/ui/aim_pad.gd")
const HERO: Texture2D = preload("res://assets/characters/apprentice.svg")
const BANTAY: Texture2D = preload("res://assets/characters/bantay.svg")
const FARMER: Texture2D = preload("res://assets/night05/farmer_witness.svg")
const SIGBIN: Texture2D = preload("res://assets/night05/sigbin_shadow_guardian.svg")
const SIGBIN_EAR_NEAR: Texture2D = preload("res://assets/night05/sigbin_ear_near.svg")
const SIGBIN_EAR_FAR: Texture2D = preload("res://assets/night05/sigbin_ear_far.svg")
const BARN: Texture2D = preload("res://assets/night05/abandoned_barn_25d.svg")
const GOAT: Texture2D = preload("res://assets/night05/rescued_goat.svg")
const CHICKEN: Texture2D = preload("res://assets/night05/rescued_chicken.svg")
const SOIL: Texture2D = preload("res://assets/world/soil_ground.svg")
const TREE: Texture2D = preload("res://assets/world/north_forest_tree.svg")
const BANANA: Texture2D = preload("res://assets/world/banana_plant.svg")
const LANTERN: Texture2D = preload("res://assets/world/lantern_post.svg")

const MAP := Rect2(-1120,-790,2240,1590)
const RETURN_WAKE := Vector2(-990,410)
const BARN_FOOT := Vector2(165,-73)
const FARMHOUSE := Vector2(-795,-220)
const FARM_DOOR := Vector2(-732,-110)
const FARMER_POS := Vector2(-525,235)
const SAFE_PERIMETER := Vector2(135,295)
const SAFE_GATE := Vector2(555,138)
const FUTURE_TRAIL := Vector2(955,-470)
const PLAYER_SPEED := 250.0
const CLUE_POS := {
	"backward_tracks":Vector2(-365,100),
	"unbroken_fence":Vector2(-600,225),
	"caretaker_photo":Vector2(-137,-15),
	"broken_barn":Vector2(615,-175)
}
const CLUE_NAMES := {
	"backward_tracks":"Backward tracks with no dragging",
	"unbroken_fence":"Unbroken pen fence and moonlit footprints",
	"caretaker_photo":"Old caretaker photo and promise",
	"broken_barn":"Missing barn planks and unsafe supports"
}
const CLUE_TEXT := {
	"backward_tracks":"Two trails overlap: hooves toward the barn, and strange long-hind-foot prints pointing back. Some Visayan accounts say a Sigbin retreats backwards, watching behind itself. Follow the dust, not the toe direction.",
	"unbroken_fence":"The old fence has no break-in marks. Tracks skirt the unstable barn and continue toward the far livestock pen. Something guided the animals there instead of dragging them.",
	"caretaker_photo":"The caretaker's promise remains beside an old clay pot. Some Cebuano accounts describe a sigbin tied to an owner or family. This is folklore, not evidence to accuse a living person.",
	"broken_barn":"The missing wall panels and weak posts are a real collapse hazard. No one, including the animals, may be rescued by walking through the barn."
}
const PREP_POS := {
	"stable_perimeter":Vector2(-277,303),
	"safe_gate":SAFE_GATE,
	"lantern_west":Vector2(-418,35),
	"lantern_north":Vector2(54,-132),
	"lantern_east":Vector2(573,-32)
}
const SHADOW_POS := [
	Vector2(-54,-362),Vector2(546,-194),Vector2(460,80)
]
const SHADOW_LABELS := [
	"Barn eave — long shadows connect to the goats",
	"Missing wall — a false silhouette without breathing",
	"Livestock pen — the last chicken group needs a clear route"
]
const GUARDIAN_START := Vector2(-124,-190)
var story = Story.new()
var prefs = Preferences.new()
var player_pos := Story.START
var bantay_pos := Story.START+Vector2(-50,35)
var camera: Camera2D
var ambient
var atmosphere
var elapsed := 0.0
var walk_phase := 0.0
var walk_weight := 0.0
var motion := Vector2.ZERO
var aim := Vector2.ZERO
var held: Dictionary = {}
var observe_held := false
var debug_farm_preview := false
var travel_in_progress := false
var farmer_retreat_seconds := 0.0
var previous_stage := 0
# Scene-only interpolation. Canonical rescued_groups is saved in Night05State;
# reloads place already-saved animals safely at the gate.
var animal_rescue_motion: Dictionary = {}
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
	name = "TabiTabiNight5"
	set_meta("dimensional_art",DimensionalArt.STYLE_ID)
	set_meta("art_contract",FarmArt.STYLE_ID)
	prefs.load_from()
	var previous = Night04State.new()
	if Night04Save.read(previous):
		story.night01_outcome = previous.night01_outcome
		story.night02_outcome = previous.night02_outcome
		story.night03_outcome = previous.night03_outcome
		story.night04_outcome = previous.outcome
	Save.read(story)
	player_pos = story.player_position
	# Older offline saves may place the player inside the formerly decorative
	# fence. Restore them to the safe road outside the now-physical pen.
	if FarmArt.inside_livestock_pen(player_pos):
		player_pos = Vector2(player_pos.x,FarmArt.PEN.end.y+27.0)
	previous_stage = _stage()
	farmer_retreat_seconds = 3.3 if previous_stage >= 2 else 0.0
	var arrival := World.consume_arrival("night05")
	if str(arrival.get("from","")) == "night04":
		player_pos = Story.START
	elif str(arrival.get("from","")) == "night06":
		player_pos = FUTURE_TRAIL+Vector2(-100,87)
		print("TABI_WORLD_ARRIVAL_FARM_FROM_RIVER")
		print("TABI_WORLD_ARRIVAL_FARM_FROM_WAKE")
	bantay_pos = player_pos+Vector2(-45,31)
	camera = Camera2D.new()
	camera.name = "Night05FarmCamera"
	camera.position = player_pos
	camera.enabled = true
	camera.position_smoothing_enabled = not prefs.reduced_motion
	camera.position_smoothing_speed = 4.0
	camera.zoom = Vector2(1.03,1.03)
	add_child(camera)
	ambient = Ambient.new()
	ambient.name = "FarmInsectsAndWind"
	add_child(ambient)
	ambient.set_audio_level(prefs.audio_level)
	_build_ui()
	_refresh()
	var postgame_ready := get_node_or_null("/root/PostgameClock")
	if story.outcome != "" and not (postgame_ready != null and postgame_ready.is_active()):
		_show_ending()
	elif story.phase == 0 and story.clues.is_empty():
		_talk("LOLA PASING • THE OLD PROMISE",
			"Night 5 — The Abandoned Farm. Two goats vanished, but nobody found blood or a broken fence. Ang saad nga wala mausab mahimo usab nga peligro. Look, then decide what truly happened.",
			[{"label":"INSPECT THE FARM SAFELY","action":"close"}])
	print("NIGHT5_QA_SCENE_READY")

func _stage() -> int:
	var free_roam_clock := get_node_or_null("/root/PostgameClock")
	if free_roam_clock != null and free_roam_clock.is_active():
		return free_roam_clock.light_stage()
	if debug_farm_preview:
		return 3
	if story.phase in [0,4,5]:
		return 0
	return story.phase

func _modal() -> bool:
	return dialogue.visible or notes.visible or options.visible or ending.visible

func _process(delta: float) -> void:
	var village_clock := get_node_or_null("/root/PostgameClock")
	if village_clock != null and village_clock.is_active() and objective != null:
		var free_roam_status := "FREE ROAM • OLD FARM • LIVESTOCK & CROPS\n%s  |  %s" % [
			village_clock.clock_label(),
			"RESTORED" if village_clock.village_mood == "restored" else "REBUILDING"
		]
		if objective.text != free_roam_status:
			objective.text = free_roam_status
	elapsed += delta if not prefs.reduced_motion else 0.0
	var stage_now := _stage()
	if stage_now >= 2:
		if previous_stage < 2:
			farmer_retreat_seconds = 3.3 if prefs.reduced_motion else 0.0
		elif not _modal():
			farmer_retreat_seconds = minf(3.3,farmer_retreat_seconds+maxf(delta,.0))
	else:
		farmer_retreat_seconds = .0
	previous_stage = stage_now
	var axis := Input.get_vector("ui_left","ui_right","ui_up","ui_down")+motion
	if _modal():
		axis = Vector2.ZERO
	axis = axis.limit_length()
	walk_weight = lerpf(walk_weight,1.0 if axis.length()>.02 else .0,
		1.0 if prefs.reduced_motion else clampf(delta*8.0,0,1))
	if axis.length()>.02:
		if not prefs.reduced_motion:
			walk_phase += delta*9.0
		var walk := Vector2(axis.x+axis.y*.42,axis.y*.78-axis.x*.15).normalized()
		var previous_foot := player_pos
		var candidate := player_pos+walk*PLAYER_SPEED*delta
		candidate.x = clampf(candidate.x,MAP.position.x+65,MAP.end.x-65)
		candidate.y = clampf(candidate.y,MAP.position.y+75,MAP.end.y-75)
		player_pos = Walkability.slide(5,previous_foot,candidate)
		# Player stays outside the actual kural. The gate is for livestock
		# rescue; preparing the gate never opens an unsafe player shortcut.
		player_pos = FarmArt.keep_player_outside_pen(previous_foot,player_pos)
		# The future chapter's marked checkpoint is locked while its
		# scene is absent; the road itself remains continuously visible.
		player_pos = FarmArt.keep_player_before_locked_trail(
			previous_foot,player_pos,FUTURE_TRAIL,not World.implemented("night06") or story.outcome == "")
	bantay_pos = bantay_pos.lerp(player_pos+Vector2(-49,28),clampf(delta*3.2,0,1))
	var framing_target := player_pos+aim*64.0
	if story.phase == 3 or debug_farm_preview:
		# Grounded Sigbin is the subject; the roof shadow is only a clue.
		# Keep the actual creature and player in the same Android frame.
		var sigbin_subject := SigbinPresence.ground_anchor(story.shadow_index)
		framing_target = player_pos.lerp(sigbin_subject+Vector2(0,-95),.49)+Vector2(0,-26)+aim*28.0
	var zoom_target := Vector2(.78,.78) if story.phase == 3 or debug_farm_preview else Vector2(1.03,1.03)
	camera.zoom = camera.zoom.lerp(zoom_target,
		1.0 if prefs.reduced_motion else clampf(delta*4.5,0,1))
	camera.position = camera.position.lerp(framing_target,
		1.0 if prefs.reduced_motion else clampf(delta*4.5,0,1))
	if not _modal() and not travel_in_progress and story.outcome != "" and player_pos.distance_to(FUTURE_TRAIL)<78:
		_travel_to_river()
		return
	if not _modal() and not travel_in_progress and player_pos.distance_to(RETURN_WAKE)<58:
		_return_to_wake()
		return
	if story.phase == 3 and not _modal():
		if story.observe_tick(delta,player_pos.distance_to(SAFE_PERIMETER)<230,
				observe_held,prefs.story_assist):
			observe_held = false
			_auto_save()
			_show_shadow_choices()
		elif story.encounter_failed:
			observe_held = false
			_talk("BANTAY • STAY OUTSIDE THE BARN",
				"The false silhouettes are too close. We still have the safe perimeter. No one has died. Retry this shadow or withdraw.",
				[{"label":"RETRY FROM THE STABLE PERIMETER","action":"retry"},
				 {"label":"WITHDRAW & LEAVE A FOLLOW-UP","action":"retreat"}])
	# Animate successfully rescued animals over the outside walkway,
	# independent of modal text so the world does not visually freeze.
	for rescued_id in animal_rescue_motion.keys():
		animal_rescue_motion[rescued_id] = minf(1.0,
			float(animal_rescue_motion[rescued_id])+maxf(delta,0.0)/2.65)
	if ambient != null:
		ambient.set_night_stage(_stage())
		ambient.set_tension(story.fear)
		# Sound strength must follow the moving animal on the ground, not
		# the remote eave-shadow clue. Otherwise hearing conflicts with sight.
		var sigbin_ground := SigbinPresence.backward_foot(
			SigbinPresence.ground_anchor(story.shadow_index),
			elapsed,story.shadow_index,prefs.reduced_motion)
		var proximity := clampf(1.0-player_pos.distance_to(sigbin_ground)/1100.0,0.0,1.0)
		ambient.set_sigbin_presence(proximity if _stage() >= 2 else 0.0)
		ambient.set_sigbin_gait(
			SigbinPresence.gait_strength(elapsed,story.shadow_index,prefs.reduced_motion)
			if _stage() >= 2 else 0.0)
	if atmosphere != null:
		atmosphere.configure(5,_stage(),story.fear,prefs.reduced_motion)
	if pressure != null:
		pressure.text = "FARM TRUST %d  •  FEAR %d%%" % [story.respect,roundi(story.fear*100)]
	if observation_meter != null:
		observation_meter.visible = story.phase == 3 and not story.shadow_identified
		observation_meter.value = story.observation_progress*100.0
	_refresh_hint()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if dialogue.visible:
			if not DialogueMotion.finish_text(dialogue_body):
				_close_dialogue()
		else:
			_interact()
	if event.is_action_pressed("ui_cancel"):
		if dialogue.visible:
			_close_dialogue()
		elif notes.visible:
			notes.hide()
			_sync_ui()
		elif options.visible:
			options.hide()
			_sync_ui()
		else:
			_open_options()
	if OS.get_name() == "Android" and OS.has_feature("debug") and event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode in [KEY_F3,KEY_F5,KEY_F6,KEY_F9,KEY_F10,KEY_F11]:
			_close_dialogue()
			notes.hide()
			options.hide()
			debug_farm_preview = key.keycode == KEY_F9
			match key.keycode:
				KEY_F3:
					player_pos = Vector2(-320,100)
					print("NIGHT5_QA_TRACKS_DAY")
				KEY_F5:
					player_pos = SAFE_GATE+Vector2(0,38)
					print("NIGHT5_QA_SAFE_GATE")
				KEY_F6:
					player_pos = SAFE_PERIMETER
					print("NIGHT5_QA_BARN_COURTYARD")
				KEY_F9:
					player_pos = SAFE_PERIMETER
					farmer_retreat_seconds = 3.3
					previous_stage = 3
					print("NIGHT5_QA_SIGBIN_NIGHT")
				KEY_F11:
					# QA shows the actual continuous farm road + Night 6 rope,
					# not a painted mockup or a disconnected title preview.
					player_pos = FUTURE_TRAIL+Vector2(-35,115)
					print("NIGHT5_QA_CONNECTED_NIGHT06_TRAIL")
				KEY_F10:
					# Android DEBUG CI only: exercise the real investigation,
					# preparation and correct first-lantern state transitions.
					# Do not modify the save; the QA emulator is disposable.
					if story.phase == 0:
						for clue_id in Story.CLUES:
							story.inspect(clue_id)
					if story.phase == 1:
						story.deduce("guardian")
					if story.phase == 2:
						for prep_id in Story.PREPARATIONS:
							story.prepare(prep_id)
						story.begin_rescue()
					if story.phase == 3 and story.shadow_index == 0:
						story.observe_tick(1.30,true,true)
						if story.respond("lantern_west"):
							animal_rescue_motion[0] = 0.0
					player_pos = SAFE_PERIMETER
					if story.phase == 3 and story.rescued_groups == 1:
						print("NIGHT5_QA_FIRST_RESCUE_ACTIVE")
			bantay_pos = player_pos+Vector2(-49,29)
			camera.position = player_pos
			_refresh()
			get_viewport().set_input_as_handled()

func _paint_farmhouse() -> void:
	# An adjacent farmhouse with the exact same inhabited-night grammar as
	# Nights 1–4. It is NOT the unsafe abandoned barn.
	var at := FARMHOUSE
	draw_colored_polygon(PackedVector2Array([
		at+Vector2(-117,-36),at+Vector2(126,-5),
		at+Vector2(132,120),at+Vector2(-117,88)]),Color("#a89b7c"))
	draw_colored_polygon(PackedVector2Array([
		at+Vector2(126,-5),at+Vector2(209,-83),
		at+Vector2(211,34),at+Vector2(132,120)]),Color("#697062"))
	draw_colored_polygon(PackedVector2Array([
		at+Vector2(-145,-60),at+Vector2(35,-197),
		at+Vector2(235,-91),at+Vector2(132,12)]),Color("#776852"))
	draw_colored_polygon(PackedVector2Array([
		at+Vector2(-145,-60),at+Vector2(126,10),
		at+Vector2(35,-197)]),Color("#a98d61"))
	draw_line(at+Vector2(-146,-60),at+Vector2(123,7),Color("#bd9e70"),9.0,true)
	for i in range(9):
		var x := -106.0+float(i)*27.0
		draw_line(at+Vector2(x,-42),at+Vector2(x,84),
			Color("#6e5d46",.52),3.0,true)
	draw_rect(Rect2(at+Vector2(6,-8),Vector2(58,95)),Color("#2f3833"))
	draw_rect(Rect2(at+Vector2(6,-8),Vector2(58,95)),Color("#765f47"),false,5.0)
	# Interior glow is drawn once AFTER the darkness grade in _draw().

func _draw() -> void:
	draw_rect(MAP.grow(190),Color("#253a32"))
	Landscape.parallax_ridges(self,MAP.grow(180),camera.position,4,_stage())
	for i in range(30):
		var y := MAP.position.y+float(i)*54.0
		draw_rect(Rect2(MAP.position.x,y,MAP.size.x,54),
			Color("#384c3d").lerp(Color("#6b7758"),float(i)/29.0))
	draw_texture_rect(SOIL,Rect2(-1110,-765,2210,1530),false,Color(1,1,1,.21))
	# The former "end" is a Y-junction, NOT a dead end. A continuous
	# public road heads east then uphill to the clearly marked Night 6 path.
	var path := FarmArt.main_road_route(RETURN_WAKE,SAFE_PERIMETER,FUTURE_TRAIL)
	draw_polyline(path,Color("#34443a"),116,true)
	draw_polyline(path,Color("#ae9570"),81,true)
	var gate_spur := FarmArt.gate_approach_route()
	draw_polyline(gate_spur,Color("#34443a"),50,true)
	draw_polyline(gate_spur,Color("#bba07d"),34,true)
	FarmArt.paint_ground_texture(self,_stage()>=2)
	FarmArt.paint_crop_rows(self,_stage()>=2)
	FarmArt.paint_squash_patch(self,Vector2(-650,140),_stage()>=2)
	Landscape.trail_stones(self,RETURN_WAKE,Vector2(-355,341),17,80,_stage()>=2)
	for at in [Vector2(-950,-445),Vector2(-835,-660),Vector2(775,-615),
		Vector2(670,-520),FarmArt.LOWER_TREE]:
		DimensionalArt.paint_grounded(self,TREE,at+Vector2(0,30),
			Vector2(235,294),Color("#91ab92"),.26)
	for at in [Vector2(-850,-80),Vector2(1030,190),FarmArt.LOWER_BANANA]:
		DimensionalArt.paint_grounded(self,BANANA,at,
			Vector2(145,210),Color("#8fa884"),.26)
	_paint_farmhouse()
	FarmArt.paint_barn_ground_shadow(self,BARN_FOOT,_stage()>=2)
	DimensionalArt.paint_grounded(self,BARN,BARN_FOOT,Vector2(780,574),
		Color("#d0c6aa"),.28)
	# The pen and the separate receiving paddock are complete enclosures,
	# not two disjoint rails that falsely implied goats were loose on the road.
	FarmArt.paint_safe_holding_area(self,story.rescued_groups,_stage()>=2)
	FarmArt.paint_livestock_enclosure(self,SAFE_GATE,
		story.preparations.has("safe_gate"),_stage()>=2)
	FarmArt.paint_observation_marker(self,SAFE_PERIMETER,_stage()>=2)
	# West evidence fence is unrelated to the fenced animal holding area.
	FarmArt.paint_fence(self,Vector2(-620,220),Vector2(-185,230),7,_stage()>=2)
	FarmArt.paint_tracks(self,CLUE_POS["backward_tracks"])
	# An old caretaker keepsake recovered at the SAFE outer wall, not
	# somewhere requiring a walk through the collapsing barn.
	var photo: Vector2 = CLUE_POS["caretaker_photo"]
	draw_rect(Rect2(photo+Vector2(-28,-90),Vector2(58,75)),Color("#aa936e"))
	draw_rect(Rect2(photo+Vector2(-22,-84),Vector2(45,61)),Color("#a9b2a3"))
	draw_circle(photo+Vector2(0,-66),11,Color("#655f58"))
	draw_line(photo+Vector2(-8,-44),photo+Vector2(12,-42),Color("#625c54"),13,true)
	FarmArt.paint_caretaker_jar(self,photo+Vector2(84,5),_stage()>=2)
	if story.phase == 2:
		for id in Story.PREPARATIONS:
			var pos: Vector2 = PREP_POS[id]
			if id.begins_with("lantern_"):
				FarmArt.paint_lantern(self,pos,story.preparations.has(id),elapsed,prefs.reduced_motion)
	# A solved shadow should NOT remain floating over the dawn/morning farm.
	if story.phase == 3 or debug_farm_preview:
		FarmArt.paint_shadow_links(self,SHADOW_POS,
			clampi(story.shadow_index,0,2),elapsed,prefs.reduced_motion,
			story.rescued_groups,[PREP_POS["lantern_west"],
				PREP_POS["lantern_north"],PREP_POS["lantern_east"]])
		for id in ["lantern_west","lantern_north","lantern_east"]:
			FarmArt.paint_lantern(self,PREP_POS[id],true,elapsed,prefs.reduced_motion)
	if _stage() == 1:
		draw_rect(MAP.grow(190),Color(.29,.17,.07,.11))
	elif _stage() >= 2:
		# Dark midnight blue, distinct from dusk; household windows and
		# farm lamps are re-lit above the grade, preserving safe routes.
		draw_rect(MAP.grow(190),Color(.012,.025,.060,
			.49 if _stage() >= 3 else .37))
		Landscape.mist(self,Vector2(130,330),730,elapsed,
			not prefs.reduced_motion,true)
		# Amber lamps get reflected on top of the world darkness.
		for id in ["lantern_west","lantern_north","lantern_east"]:
			var lantern_lit: bool = story.preparations.has(id) or debug_farm_preview
			FarmArt.paint_lantern_ground_pool(self,PREP_POS[id],
				lantern_lit,elapsed,prefs.reduced_motion)
			FarmArt.paint_lantern(self,PREP_POS[id],
				lantern_lit,elapsed,prefs.reduced_motion)
		# Household safe window glow is lighter than the abandoned barn.
		for i in range(2):
			NightWindows.paint_window(self,FARMHOUSE+Vector2(-69+float(i)*120,5),
				Vector2(49,47),i,true,elapsed,prefs.reduced_motion)
	# Safe-world wayfinding stays readable after the night grade. Signs
	# distinguish the livestock-only gate from the player observation point.
	FarmArt.paint_farm_sign(self,
		"LIVESTOCK PEN • NO ENTRY"
		if FarmArt.animals_revealed(story.phase,debug_farm_preview)
		else "MISSING HERD • FOLLOW TRACKS",
		Vector2(375,-93),286.0,_stage()>=2)
	FarmArt.paint_farm_sign(self,
		FarmArt.gate_label(story.phase,story.preparations.has("safe_gate")),
		Vector2(698,83),196.0,_stage()>=2)
	FarmArt.paint_farm_sign(self,"SAFE HOLDING → %d/3" % story.rescued_groups,
		FarmArt.HOLDING_SIGN_AT,227.0,_stage()>=2)
	if story.phase in [1,2,3]:
		FarmArt.paint_farm_sign(self,"OBSERVE HERE",
			SAFE_PERIMETER+Vector2(-250,-120),174.0,_stage()>=2)
	# The main road visibly continues beyond this chapter's actual exit.
	# A locked rope makes the missing next scene explicit, not a cut road.
	FarmArt.paint_night06_trail_checkpoint(self,FUTURE_TRAIL,
		not World.implemented("night06") or story.outcome == "",_stage()>=2)
	# Documented regional signs appear as an IN-WORLD animal rather than
	# a static enemy: backward steps, two hinged ears, and cautious concealment.
	if _stage() >= 2 or debug_farm_preview:
		# The eave casts the clue, but the Sigbin's hooves are on firm soil
		# beneath the barn, NOT hanging in front of its roof.
		var foot := SigbinPresence.backward_foot(
			SigbinPresence.ground_anchor(story.shadow_index),
			elapsed,story.shadow_index,prefs.reduced_motion)
		var opacity := SigbinPresence.visibility(_stage(),
			story.shadow_identified,debug_farm_preview,elapsed)
		# Draw contact shade and subdued hoof dust UNDER the moving four-leg
		# silhouette. This grounds the creature even on dark Android screens.
		SigbinPresence.paint_ground_contact(self,foot,
			elapsed,prefs.reduced_motion,opacity,story.shadow_index)
		SigbinPresence.paint_reverse_tracks(self,foot,opacity)
		if opacity > .01:
			# Ribcage follows the hindquarters; hooves settle between steps.
			# Ground contact stays in place, even when the torso breathes.
			var weight := SigbinPresence.body_weight_shift(
				elapsed,story.shadow_index,prefs.reduced_motion)
			SigbinPresence.paint_limb_pair(self,foot,
				elapsed,prefs.reduced_motion,opacity,true,story.shadow_index)
			DimensionalArt.paint_grounded(self,SIGBIN,
				foot+weight,Vector2(258,206),Color(.70,.76,.69,opacity),0.0)
			SigbinPresence.paint_limb_pair(self,foot,
				elapsed,prefs.reduced_motion,opacity,false,story.shadow_index)
			SigbinPresence.paint_clapping_ears(self,SIGBIN_EAR_NEAR,
				SIGBIN_EAR_FAR,foot+weight,elapsed,prefs.reduced_motion,opacity)
	# Livestock groups are physical sprites. Rescued ones are moved to the
	# safe gate, not deleted from the screen. None is shown hurt or bleeding.
	for i in range(3):
		# Missing animals remain hidden from the initial daylight clue hunt.
		# After deducing the guardian, they become visible in the far pen.
		if not FarmArt.animals_revealed(story.phase,debug_farm_preview):
			continue
		var safe: bool = story.rescued_groups > i
		var at := FarmArt.animal_crossing_position(i,SAFE_GATE,safe,
			float(animal_rescue_motion.get(i,1.0)))
		var moving: bool = safe and animal_rescue_motion.has(i) and float(
			animal_rescue_motion.get(i,1.0)) < 1.0
		var hoof_bob := 0.0 if prefs.reduced_motion or not moving else absf(
			sin(float(animal_rescue_motion[i])*TAU*3.0))*2.8
		DimensionalArt.paint_grounded(self,CHICKEN if i == 2 else GOAT,
			at,Vector2(70,71) if i == 2 else Vector2(102,95),
			Color.WHITE,.28,hoof_bob)
	# Story-only daytime Farmer walks home rather than popping out of scene.
	if _stage() < 2 or farmer_retreat_seconds < 3.3:
		var t := smoothstep(0.0,1.0,clampf(farmer_retreat_seconds/3.3,0,1))
		var at := FARMER_POS.lerp(FARM_DOOR,t) if _stage()>=2 else FARMER_POS
		DimensionalArt.paint_grounded(self,FARMER,at,
			Vector2(100,158),Color(1,1,1,1.0-smoothstep(.80,1.0,t)
				if _stage()>=2 else 1.0),.31)
	DimensionalArt.paint_animated_actor(self,BANTAY,bantay_pos+Vector2(0,18),
		Vector2(96,103),walk_phase,walk_weight,prefs.reduced_motion,Color.WHITE,.33,true)
	DimensionalArt.paint_animated_actor(self,HERO,player_pos+Vector2(0,7),
		Vector2(107,140),walk_phase,walk_weight,prefs.reduced_motion,Color.WHITE,.38)
	PostgameResidents.paint(self,"night05",elapsed,prefs.reduced_motion,player_pos)
	var font := ThemeDB.fallback_font
	draw_string(font,RETURN_WAKE+Vector2(26,-90),"WAKE TRAIL • RETURN",HORIZONTAL_ALIGNMENT_LEFT,335,18,Color("#f3d8a6"))
	draw_string(font,BARN_FOOT+Vector2(-141,62),"OLD BARN • UNSAFE TO ENTER",HORIZONTAL_ALIGNMENT_LEFT,430,18,Color("#efd8a3"))
	draw_string(font,FUTURE_TRAIL+Vector2(-200,-45),
		"HILL TRAIL • NIGHT 6 RIVER" if World.implemented("night06") and story.outcome != "" else "HILL TRAIL • FINISH FARM FIRST",
		HORIZONTAL_ALIGNMENT_LEFT,410,17,Color("#e0c58f"))

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
	var status: Dictionary = SharedHUD.create_status_card(controls,"TABI-TABI  •  NIGHT 5 / SIGBIN",prefs.text_scale)
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
	dialogue = _panel(modal_backdrop,"FarmDialogue",Vector4(.15,.12,.85,.88))
	var dstack := _stack(dialogue)
	dialogue_speaker = _label(dstack,"",27,Color("#eed39c"))
	dialogue_body = _label(dstack,"",24,Color("#f0ebdb"))
	dialogue_body.custom_minimum_size.y = 95
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation",6)
	dstack.add_child(choices)
	notes = _panel(modal_backdrop,"FarmNotebook",Vector4(.14,.10,.86,.90))
	var nstack := _stack(notes)
	_label(nstack,"FIELD NOTES • NIGHT 5",29,Color("#e8cb95"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nstack.add_child(scroll)
	notes_text = _label(scroll,"",21,Color("#dfebe1"))
	notes_text.custom_minimum_size.x = 580
	_button(nstack,"RETURN TO FARM",func():notes.hide())
	options = _panel(modal_backdrop,"FarmOptions",Vector4(.22,.15,.78,.85))
	var ostack := _stack(options)
	_label(ostack,"PAUSE • NIGHT 5",32,Color("#f7dfab"))
	_button(ostack,"SAVE OFFLINE",_save_feedback)
	_button(ostack,"FIELD NOTES",_open_notes)
	_button(ostack,"SAVE & MAIN MENU",_save_menu)
	_button(ostack,"CLOSE",func(): options.hide())
	ending = _panel(modal_backdrop,"FarmAftermath",Vector4(.16,.12,.84,.88))
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
	if player_pos.distance_to(RETURN_WAKE)<125:
		return "return_wake"
	if player_pos.distance_to(FUTURE_TRAIL)<125:
		return "trail_locked"
	if player_pos.distance_to(Vector2(350,-95))<110:
		return "unsafe_barn"
	if story.phase == 0:
		if not story.seen.has("farmer") and player_pos.distance_to(FARMER_POS)<145:
			return "farmer"
		for id in Story.CLUES:
			if not story.clues.has(id) and player_pos.distance_to(CLUE_POS[id])<125:
				return id
	elif story.phase == 1:
		if player_pos.distance_to(SAFE_PERIMETER)<250:
			return "deduce"
	elif story.phase == 2:
		for id in Story.PREPARATIONS:
			if not story.preparations.has(id) and player_pos.distance_to(PREP_POS[id])<135:
				return id
		if player_pos.distance_to(SAFE_PERIMETER)<230:
			return "begin_rescue"
	elif story.phase == 3:
		if player_pos.distance_to(SAFE_PERIMETER)<235:
			return "watch"
	var postgame_neighbor := PostgameResidents.nearby(self,"night05",player_pos)
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
	if id == "return_wake":
		_return_to_wake()
	elif id == "trail_locked":
		if story.outcome != "" and World.implemented("night06"):
			_travel_to_river()
		else:
			_talk("BANTAY • COMPLETE THE FARM FIRST",
				"This public road leads uphill to Night 6, but the farm case is not recorded yet. Save the goats and finish the Sigbin evidence before travelling.",
				[{"label":"RETURN TO THE FARM","action":"close"}])
	elif id == "unsafe_barn":
		story.enter_unstable_barn()
		_talk("FARMER • THE OLD POSTS",
			"Do not step through the missing panels. The raised barn can collapse. The goats must come OUT to us using the safe perimeter.",
			[{"label":"USE THE SAFE WALKWAY","action":"close"}])
	elif id == "farmer" and story.phase == 0:
		story.seen["farmer"] = true
		_auto_save()
		_talk("FARMER • TWO MISSING GOATS",
			"Two goats went missing this morning, and the chickens went quiet. The kural was intact. At dusk, a bitter smell came from the squash vines, then two sharp ear-claps near the unsafe barn. The hoofprints face the wrong way. Follow them; do not enter the barn.",
			[{"label":"INSPECT THE REAL TRACKS","action":"close"}])
	elif story.phase == 0 and Story.CLUES.has(id):
		if story.inspect(id):
			_auto_save()
			_talk("FIELD OBSERVATION",
				str(CLUE_TEXT[id])+
				("\n\nThe physical clues agree. Compare the evidence before calling the guardian a predator." if story.phase == 1 else ""),
				[{"label":"RECORD IN FIELD NOTES","action":"close"}])
	elif story.phase == 1 and id == "deduce":
		_talk("MARA • PRIVATE DEDUCTION",
			"Both goats walked through intact fencing. The barn is dangerous, but the animal has an old family bond. What intention best explains its path?",
			[{"label":"A MISGUIDED PROTECTOR","action":"guardian"},
			 {"label":"A LIVESTOCK KILLER","action":"predator"},
			 {"label":"RECHECK THE EVIDENCE","action":"close"}])
	elif story.phase == 2 and Story.PREPARATIONS.has(id):
		if story.prepare(id):
			_auto_save()
			_talk("SAFE FARM PREPARATION",
				"Prepared "+id.replace("_"," ")+". Keep the pathway outside unstable supports. Lanterns must interrupt connected shadow routes, not blind the livestock.",
				[{"label":"CONTINUE SAFELY","action":"close"}])
	elif story.phase == 2 and id == "begin_rescue":
		if story.begin_rescue():
			_auto_save()
			_talk("FARMER • GROUP RESCUE",
				"All three lamps, livestock-only gate and the marked stable perimeter are ready. Stay at OBSERVE HERE; animals will pass through the prepared gate into the fenced safe holding area.",
				[{"label":"KEEP EVERYONE OUTSIDE","action":"close"}])
		else:
			_talk("BANTAY",
				"Prepare the THREE separate lanterns, the gate, and the stable walkway before approaching any shadow. No unstable barn shortcuts.",
				[{"label":"CHECK THE SAFE ROUTE","action":"close"}])
	elif story.phase == 3:
		if story.shadow_identified:
			_show_shadow_choices()
		else:
			_talk("BANTAY • HOLD OBSERVE",
				"Stand at the stable perimeter and HOLD OBSERVE. Tracks, dust and breathing will identify which shadow is real.",
				[{"label":"WATCH THE LANTERN SHADOWS","action":"close"}])
	_refresh()

func _show_shadow_choices() -> void:
	if story.phase != 3 or not story.shadow_identified:
		return
	var route: String = str(SHADOW_LABELS[clampi(story.shadow_index,0,2)])
	_talk("BANTAY • SIGBIN SIGNS",
		route+"\nA shadow alone is not the creature. You sensed a pungent odor, heard paired ear-claps, and watched it step backwards. Shift ONE lamp to open the animal route without entering the barn.",
		[{"label":"SHIFT WEST LANTERN","action":"lantern_west"},
		 {"label":"SHIFT NORTH LANTERN","action":"lantern_north"},
		 {"label":"SHIFT EAST LANTERN","action":"lantern_east"},
		 {"label":"REVIEW FOOTPRINTS FIRST","action":"close"}])

func _choose(value: String) -> void:
	if value == "reload_saved":
		get_tree().call_deferred("reload_current_scene")
		return
	if value == "close":
		_close_dialogue()
	elif value == "guardian":
		if story.deduce("guardian"):
			_auto_save()
			_talk("ALING SABEL • WHAT WE WAIT FOR",
				"The tracks lead to the far pen: the missing goats and chickens are sheltered there. The barn is unstable. Prepare the animal-only gate and three lanterns, then guide them to the separate safe holding area. Do not enter the pen yourself.",
				[{"label":"PREPARE A SAFE ROUTE","action":"close"}])
	elif value == "predator":
		story.deduce("predator")
		_auto_save()
		_talk("MARA • LOOK AGAIN",
			"These tracks show guidance, not a kill. Do not punish the old guardian because we were frightened by the shadows.",
			[{"label":"RECONSIDER THE EVIDENCE","action":"close"}])
	elif value == "retry":
		if story.retry_safe_perimeter():
			_auto_save()
			_talk("BANTAY","Stay together. The safe route is ready; the animals already rescued remain at the gate. Observe this shadow again.",
				[{"label":"RETRY THIS SHADOW","action":"close"}])
	elif value in ["lantern_west","lantern_north","lantern_east"]:
		if story.respond(value):
			if not prefs.reduced_motion:
				animal_rescue_motion[story.rescued_groups-1] = 0.0
			_auto_save()
			if story.phase == 4:
				_talk("FARMER • ALL ANIMALS OUT",
					"Both goats and the chickens are safe. The Sigbin follows the unbroken boundary of light; its old duty can be given a safer place.",
					[{"label":"RECORD THE MORNING OUTCOME","action":"outcomes"}])
			else:
				_talk("BANTAY • GROUP SAVED",
					"One more group passed the open gate safely. The shadow shifted. Observe the next route without entering the barn.",
					[{"label":"CONTINUE THE RESCUE","action":"close"}])
		else:
			_talk("BANTAY • WRONG SHADOW",
				"That lamp did not break the connected path. Check the direction of the dust and listen for real breathing before choosing again.",
				[{"label":"OBSERVE AGAIN","action":"close"}])
	elif value == "outcomes":
		_talk("MORNING • NEW TERRITORY",
			"All three animal groups are safe. Record how we will honor the old guardian's bond without forcing it into an unsafe barn.",
			[{"label":"RESOLVE • SAFE TERRITORY & ALL ANIMALS","action":"resolve"},
			 {"label":"SAFE RESCUE • CONTINUE CARE","action":"safe_rescue"},
			 {"label":"PARTIAL • FARM SAFETY FOLLOW-UP","action":"partial"}])
	elif value in ["resolve","safe_rescue","partial","retreat"]:
		if story.commit(value):
			_auto_save()
			_show_ending()
		else:
			_talk("FIELD RECORD","That outcome is not supported by the physical rescue record. Save the actual result rather than inventing a perfect ending.",
				[{"label":"REVIEW THE RECORD","action":"outcomes"}])
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
	DialogueMotion.reveal(dialogue,prefs.reduced_motion)
	DialogueMotion.reveal_text(dialogue_body,prefs.reduced_motion)
	_sync_ui()

func _press_dialogue_choice(action: String) -> void:
	# Same tap-to-complete rule as the established Night 1 cinematic.
	# A fast choice tap reveals the current line before a consequence runs.
	if DialogueMotion.finish_text(dialogue_body):
		return
	_choose(action)

func _close_dialogue() -> void:
	DialogueMotion.conceal(dialogue,prefs.reduced_motion)
	_sync_ui()
	DialogueMotion.restore_gameplay(controls,prefs.reduced_motion)

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
	var tasks := ["DAY / TRACKS","DUSK / UNDERSTAND","EVENING / LANTERNS",
		"MIDNIGHT / RESCUE","DAWN / SAFETY","MORNING / RECORDED"]
	subtitle.text = "%s  •  CLUES %d/4  •  SAFETY %d/5" % [
		tasks[clampi(story.phase,0,5)],story.clues.size(),story.preparations.size()]
	if debug_farm_preview:
		# F9 is a developer-only live encounter preview; never label it DAY.
		subtitle.text = "MIDNIGHT / SIGBIN REVEAL  •  QA PREVIEW"
		objective.text = "Watch the Sigbin guardian and its connected shadow path from safety."
		_refresh_hint()
		return
	match story.phase:
		0: objective.text = "Talk to the farmer; inspect FOUR clues. Stay outside the kural and unsafe barn."
		1: objective.text = "At OBSERVE HERE, compare the tracks. Guardian or predator?"
		2: objective.text = "Prepare OBSERVE HERE, the animal GATE and THREE lanterns."
		3: objective.text = "%d/3 animal groups safe. Stand at OBSERVE HERE, HOLD OBSERVE, then shift one lantern." % story.rescued_groups
		4: objective.text = "All THREE groups are inside the safe holding area. Record the outcome."
		5: objective.text = "NIGHT 5 RECORDED • %s  •  FOLLOW ROAD TO NIGHT 6" % story.outcome.to_upper()
	_refresh_hint()

func _refresh_hint() -> void:
	if interaction_hint == null:
		return
	var id := _nearby()
	var farm_hint := "FOLLOW WAYPOINT • SAFE FARM ROUTE"
	if id == "" and story.outcome == "":
		var sigbin_ground := SigbinPresence.backward_foot(
			SigbinPresence.ground_anchor(story.shadow_index),
			elapsed,story.shadow_index,prefs.reduced_motion)
		farm_hint = SigbinPresence.detect_warning(_stage(),
			player_pos.distance_to(sigbin_ground),elapsed,story.shadow_identified)
	interaction_hint.text = farm_hint if id == "" else "INTERACT • "+id.replace("_"," ").to_upper()
	var goal := RETURN_WAKE
	var title := "RETURN TO THE WAKE"
	if story.phase == 0:
		for key in Story.CLUES:
			if not story.clues.has(key):
				goal = CLUE_POS[key]
				title = CLUE_NAMES[key].to_upper()
				break
	elif story.phase == 1:
		goal = SAFE_PERIMETER
		title = "DEDUCE WITH MARA"
	elif story.phase == 2:
		goal = SAFE_PERIMETER
		title = "SET UP SAFE RESCUE"
		for key in Story.PREPARATIONS:
			if not story.preparations.has(key):
				goal = PREP_POS[key]
				title = key.replace("_"," ").to_upper()
				break
	elif story.phase == 3:
		goal = SAFE_PERIMETER
		title = "OBSERVE HERE • SAFE ZONE"
	var diff := goal-player_pos
	waypoint.text = "%s  •  %d STEPS" % [title,roundi(diff.length()/12.0)]

func _open_notes() -> void:
	if _modal() and not options.visible:
		return
	options.hide()
	modal_backdrop.show()
	notes.show()
	notes_text.text = "THE SIGBIN OF THE ABANDONED FARM / FIELD NOTES\n\n"
	for id in Story.CLUES:
		notes_text.text += ("[OBSERVED] " if story.clues.has(id) else "[MISSING] ")+str(CLUE_NAMES[id])+"\n"
	notes_text.text += "\nFOLKLORE SIGNS (regional accounts vary): backward retreat, long hind legs, clapping ears, pungent odor, brief night sightings. These are traditional accounts, not proof of a supernatural animal.\n"
	for cue_id in ["sigbin_odor","sigbin_ear_clap","sigbin_reverse_steps"]:
		notes_text.text += ("[CONFIRMED] " if story.seen.has(cue_id) else "[UNCONFIRMED] ")+cue_id.replace("sigbin_","").replace("_"," ").to_upper()+"\n"
	notes_text.text += "\nA shadow is not evidence of harm; the caretaker's old bond and the goats' safety must be judged separately.\n\n"
	for id in Story.PREPARATIONS:
		notes_text.text += ("[READY] " if story.preparations.has(id) else "[UNPREPARED] ")+id.replace("_"," ")+"\n"
	notes_text.text += "\nANIMAL GROUPS SAFELY OUT %d/3  •  FEAR %d%%\n" % [story.rescued_groups,roundi(story.fear*100)]
	notes_text.text += "\nEarlier cases: Santelmo %s; Kapre %s; Tikbalang %s; The Wake %s.\n" % [
		story.night01_outcome,story.night02_outcome,story.night03_outcome,story.night04_outcome]
	_sync_ui()

func _open_preparation_briefing() -> void:
	if _modal():
		return
	_talk("FARM SAFETY PREPARATION",
		"Stations ready: %d/5. Prepare the outside observation point, animal-only gate and three lanterns using INTERACT. Keep the public road clear; never enter the collapsing barn or fenced pen." % story.preparations.size(),
		[{"label":"RETURN TO THE FARM","action":"close"}])


func _retry_from_saved_checkpoint() -> void:
	if _modal() or travel_in_progress:
		return
	_talk("RETRY • LAST SAVED CHECKPOINT",
		"Reload the last offline checkpoint for this Night? Unsaved actions will be lost; previous chapter records remain intact.",
		[{"label":"RETRY LAST SAVED CHECKPOINT","action":"reload_saved"},
		 {"label":"KEEP PLAYING","action":"close"}])


func _open_options() -> void:
	if dialogue.visible or ending.visible:
		return
	modal_backdrop.show()
	options.show()
	_sync_ui()

func _confirm_retreat() -> void:
	if _modal() or story.outcome != "":
		return
	_talk("SAFETY CHOICE",
		"You can leave the unstable barn alone and return with help. Rescued animals stay safe, and the old guardian may need another visit.",
		[{"label":"WITHDRAW & RECORD FOLLOW-UP","action":"retreat"},
		 {"label":"CONTINUE THE SAFE RESCUE","action":"close"}])

func _auto_save() -> bool:
	story.player_position = player_pos
	var ok := Save.write(story)
	if ok and story.outcome != "":
		World.note_outcome(5,story.outcome)
	return ok

func _save_feedback() -> void:
	if not _auto_save():
		save_error.popup_centered(Vector2i(600,180))
		return
	options.hide()
	_talk("FIELD NOTES","Night 5 saved offline. The previous FOUR night records are intact.",
		[{"label":"CONTINUE","action":"close"}])

func _save_menu() -> void:
	if not _auto_save():
		save_error.popup_centered(Vector2i(600,180))
		return
	get_node("/root/SceneTransit").call("change_to_file", "res://scenes/title.tscn")

func _travel_to_river() -> void:
	if travel_in_progress or story.outcome == "":
		return
	if not _auto_save() or not World.begin_travel("night05","night06",story.outcome):
		save_error.popup_centered(Vector2i(600,180))
		return
	travel_in_progress = true
	motion = Vector2.ZERO
	observe_held = false
	print("TABI_WORLD_TRAVEL_FARM_TO_RIVER")
	get_node("/root/SceneTransit").call("change_to_file", World.scene_for("night06"))

func _return_to_wake() -> void:
	if travel_in_progress:
		return
	if not _auto_save() or not World.begin_travel("night05","night04",story.outcome):
		save_error.popup_centered(Vector2i(600,180))
		return
	travel_in_progress = true
	motion = Vector2.ZERO
	observe_held = false
	print("TABI_WORLD_TRAVEL_FARM_TO_WAKE")
	get_node("/root/SceneTransit").call("change_to_file", World.scene_for("night04"))

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
	_label(stack,"NIGHT 5 • THE OLD PROMISE",30,Color("#ebcf9c"))
	var after := ""
	match story.outcome:
		"resolve":
			after = "Both goats and all chickens are home. The shadow boundary is changed and the Sigbin has a safer territory. Its old loyalty can finally protect without trapping anyone."
		"safe_rescue":
			after = "The animals are home. The farmer will repair the barn and maintain the new lantern boundary. The Sigbin can watch from a place that is safe for everyone."
		"partial":
			after = "The livestock passed the gate alive, but the farm still needs structural repairs and patient follow-up. The creature was not punished for an old duty."
		_:
			after = "The apprentice withdrew without entering the collapsing barn. A careful community rescue plan must be resumed later. No one was injured."
	_label(stack,after,24,Color("#f3e6d0"))
	_label(stack,"FARM RESPECT %d  •  FOUR PRIOR NIGHTS PRESERVED" % story.respect,
		20,Color("#a6d0b3"))
	_button(stack,"REVIEW FIELD NOTES",func():
		ending.hide()
		_open_notes())
	if World.implemented("night06"):
		_button(stack,"CONTINUE NIGHT 6 • THE RIVER (SAVE)",_travel_to_river)
	_button(stack,"RETURN TO THE WAKE (SAVE)",_return_to_wake)
	_button(stack,"SAVE & MAIN MENU",_save_menu)
	_sync_ui()
