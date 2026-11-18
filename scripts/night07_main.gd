extends Node2D
## Night 7 • Balete Grounds — original Keeper, accountability & living epilogue.
## No Keeper HP bar. The story doesn't turn victims into monsters, or force
## public grief or perfect scores from the previous six chapters.
const Story = preload("res://scripts/narrative/night07_state.gd")
const Save = preload("res://scripts/core/night07_save.gd")
const Night06State = preload("res://scripts/narrative/night06_state.gd")
const Night06Save = preload("res://scripts/core/night06_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
const Prefs = preload("res://scripts/core/preferences.gd")
const BaleteSound = preload("res://scripts/audio/night07_ambience.gd")
const SharedHUD = preload("res://scripts/ui/shared_hud.gd")
const Depth = preload("res://scripts/visuals/layered_25d.gd")
const Landscape = preload("res://scripts/visuals/folklore_landscape_25d.gd")
const Windows = preload("res://scripts/visuals/nighttime_windows.gd")
const DialogueMotion = preload("res://scripts/ui/shared_dialogue_motion.gd")
const AimPad = preload("res://scripts/ui/aim_pad.gd")
const HERO: Texture2D = preload("res://assets/characters/apprentice.svg")
const BANTAY: Texture2D = preload("res://assets/characters/bantay.svg")
const MARA: Texture2D = preload("res://assets/characters/mara.svg")
const SABEL: Texture2D = preload("res://assets/characters/sabel.svg")
const LOLA: Texture2D = preload("res://assets/characters/lola.svg")
const DADO: Texture2D = preload("res://assets/characters/dado.svg")
const TREE: Texture2D = preload("res://assets/world/north_forest_tree.svg")
const MANGROVE: Texture2D = preload("res://assets/world/mangrove_illustrated.svg")
const BANANA: Texture2D = preload("res://assets/world/banana_plant.svg")
const LANTERN: Texture2D = preload("res://assets/world/lantern_post.svg")
const NIPA: Texture2D = preload("res://assets/world/nipa_facade.svg")
const SOIL: Texture2D = preload("res://assets/world/soil_ground.svg")
const MAP := Rect2(-1190,-830,2560,1700)
const RIVER_TRAIL := Vector2(-1030,340)
const READINESS_BOARD := Vector2(-760,132)
const MEETING := Vector2(-590,-65)
const SABEL_AT := Vector2(-805,-82)
const DADO_AT := Vector2(-840,235)
const MARA_AT := Vector2(-550,-240)
const LOLA_AT := Vector2(-290,-242)
const PUBLIC_RECORD := Vector2(-525,82)
const GATE := Vector2(45,-205)
const KEEPER := Vector2(555,-300)
const FACT_POS := {
	"cancelled_rescue":Vector2(-750,-17),
	"returning_boat":Vector2(-568,-23),
	"limited_refuge":Vector2(-386,-13)
}
const COMMIT_POS := {
	"correct_archive":Vector2(-798,235),
	"protect_witnesses":Vector2(-480,230),
	"family_memorial":Vector2(-206,125)
}
const PATH_STONES := [
	Vector2(135,-218),Vector2(323,-289),Vector2(525,-278)
]
const AWAKENED_STONES := [
	Vector2(385,-100),Vector2(598,-35),Vector2(777,-109)
]
const EPILOGUE_POS := {
	"mara":Vector2(-523,-196),
	"sabel":Vector2(-817,-69),
	"dado":Vector2(-900,212),
	"lola":Vector2(-278,-208),
	"river":Vector2(215,285),
	"memorial":Vector2(-216,116),
	"bantay":Vector2(-615,257)
}
const SPEED := 240.0
var story = Story.new()
var prefs = Prefs.new()
var player_pos := Story.START
var bantay_pos := Story.START+Vector2(-42,26)
var camera: Camera2D
var ambient
var clock := 0.0
var walk := 0.0
var qa_view := 0 # Visual-only Android debug camera; canonical model not edited.
var moving := Vector2.ZERO
var held: Dictionary = {}
var looking := Vector2.ZERO
var observing := false
var travel_in_progress := false
var unsafe_cooldown := 0.0
var hud: CanvasLayer
var controls: Control
var status_panel: PanelContainer
var status_stack: VBoxContainer
var objective: Label
var subtitle: Label
var trust_line: Label
var waypoint: Label
var prompt: Label
var meter: ProgressBar
var darken: ColorRect
var dialogue: PanelContainer
var speaker: Label
var speech: Label
var choices: VBoxContainer
var notebook: PanelContainer
var notebook_text: Label
var options: PanelContainer
var outcome_panel: PanelContainer
var save_error: AcceptDialog

func _ready() -> void:
	name = "TabiTabiNight7"
	set_meta("dimensional_art","shared-2.5d-layered-v1")
	set_meta("canon","original-keeper-truth-and-path-v1")
	prefs.load_from()
	var river = Night06State.new()
	if Night06Save.read(river):
		story.night01_outcome = river.night01_outcome
		story.night02_outcome = river.night02_outcome
		story.night03_outcome = river.night03_outcome
		story.night04_outcome = river.night04_outcome
		story.night05_outcome = river.night05_outcome
		story.night06_outcome = river.outcome
		story.previous_facts = {
			"cancelled_rescue":river.cancellation_confirmed,
			"returning_boat":river.independent_return_confirmed and river.rescuer_confirmed,
			"limited_refuge":river.lola_covenant_truth_known
		}
		story.sabel_privacy = river.sabel_public_choice
	Save.read(story)
	player_pos = story.player_position
	var arrival: Dictionary = World.consume_arrival("night07")
	if str(arrival.get("from","")) == "night06":
		player_pos = Story.START
	camera = Camera2D.new()
	camera.name = "BaleteFinalCamera"
	camera.position = player_pos
	camera.enabled = true
	camera.position_smoothing_enabled = not prefs.reduced_motion
	camera.position_smoothing_speed = 4.6
	add_child(camera)
	ambient = BaleteSound.new()
	ambient.name = "BaleteOriginalEnvironmentSound"
	add_child(ambient)
	ambient.set_audio_level(prefs.audio_level)
	_build_ui()
	_refresh()
	if story.phase == 7:
		_show_outcome()
	elif story.phase == 0:
		_talk("MARA • THE LAST MORNING",
			"Naa na tay mga rekord sa baha. Sa dili pa ta mosulod sa Balete Grounds, susihon nato ang mga wala pa matino ug kinsa ang gustong magpabiling pribado. Walay kinahanglan pugson sa pagpasaylo.",
			[{"label":"OPEN THE READINESS NOTEBOOK","id":"readiness_notes"}])
	print("NIGHT7_QA_SCENE_READY")

func _stage() -> int:
	if qa_view == 3 or story.phase in [2,3,4,5,6]: return 3
	if qa_view == 4 or story.phase == 7: return 0
	return 1 if story.phase == 1 else 0

func _modal() -> bool:
	return dialogue.visible or notebook.visible or options.visible or outcome_panel.visible

func _active_stone() -> Vector2:
	if story.phase == 3 and story.path_index < 3: return PATH_STONES[story.path_index]
	if story.phase == 5 and story.awake_index < 3: return AWAKENED_STONES[story.awake_index]
	return GATE

func _safe_segment(p: Vector2) -> bool:
	# Only corridors up to the current solved stone are safe. The older
	# implementation inspected ALL future segments, letting a player walk
	# into the unsolved Keeper roots without observing their warnings.
	var stones: Array = PATH_STONES if story.phase == 3 else AWAKENED_STONES
	var start: Vector2 = GATE if story.phase == 3 else PATH_STONES[2]
	var unlocked: int = clampi(
		story.path_index if story.phase == 3 else story.awake_index,
		0,stones.size()-1)
	for i in range(unlocked+1):
		var at: Vector2 = stones[i]
		var near: Vector2 = Geometry2D.get_closest_point_to_segment(p,start,at)
		if p.distance_to(near) < 93.0:
			return true
		start = at
	return false

func _process(delta: float) -> void:
	if not prefs.reduced_motion: clock += delta
	unsafe_cooldown = maxf(0.0,unsafe_cooldown-delta)
	if ambient!=null:
		ambient.set_stage(_stage())
		ambient.set_danger(story.danger)
	var axis := (Input.get_vector("ui_left","ui_right","ui_up","ui_down")+moving).limit_length()
	if _modal() or travel_in_progress: axis = Vector2.ZERO
	if axis.length()>.06:
		if not prefs.reduced_motion: walk+=delta*8.8
		var world_axis := Vector2(axis.x+axis.y*.4,axis.y*.8-axis.x*.16).normalized()
		var candidate := player_pos+world_axis*SPEED*delta
		candidate.x = clampf(candidate.x,MAP.position.x+65,MAP.end.x-65)
		candidate.y = clampf(candidate.y,MAP.position.y+65,MAP.end.y-65)
		if story.phase in [0,1] and candidate.x > 105:
			candidate.x = 105 # A visibly roped Keeper path, not a hidden warp.
		if story.phase in [3,5]:
			if not _safe_segment(candidate):
				candidate = player_pos
				if unsafe_cooldown <= 0.0:
					story.unsafe_step()
					unsafe_cooldown = 1.5
					_refresh()
		player_pos=candidate
	bantay_pos=bantay_pos.lerp(player_pos+Vector2(-48,29),clampf(delta*3.7,0,1))
	var target := player_pos+looking*42
	var zoom: Vector2 = Vector2(1.02,1.02)
	if story.phase in [3,5] or qa_view == 3:
		target = player_pos.lerp(KEEPER,.19)+looking*36
		zoom = Vector2(.88,.88)
	# The enormous Keeper must appear with its face AND critical root footing
	# inside the real Android landscape frame, never cut at the upper edge.
	if story.phase == 5 or qa_view == 3:
		target += Vector2(0,-105)
		zoom = Vector2(.79,.79)
	camera.position=camera.position.lerp(target,1.0 if prefs.reduced_motion else clampf(delta*4.5,0,1))
	camera.zoom=camera.zoom.lerp(zoom,1.0 if prefs.reduced_motion else clampf(delta*3.2,0,1))
	if not _modal() and player_pos.distance_to(RIVER_TRAIL)<72:
		_return_to_river()
		return
	if story.phase in [3,5] and not _modal():
		var safe := player_pos.distance_to(_active_stone())<115.0 and _safe_segment(player_pos)
		if story.observe_tick(delta,safe,observing,prefs.story_assist):
			observing=false
			_save_story()
			_show_cue()
		elif story.encounter_failed:
			observing=false
			_talk("BANTAY • WARNING / SAFE RETRY",
				"The roots moved too fast. We are still alive on safe ground. Keep every record and completed step; retry only this warning.",
				[{"label":"RETRY THE CURRENT SAFE STONE","id":"retry_stone"},
				 {"label":"REVIEW THE NOTEBOOK","id":"notes"}])
	if meter!=null:
		meter.visible=story.phase in [3,5] and not story.warning_ready
		meter.value=story.observation*100.0
	if trust_line!=null:
		trust_line.text="EVIDENCE %d/3  •  COMMUNITY ACTIONS %d/3  •  ROOTS %d/3" % [
			story.presented.size(),story.commitments.size(),
			story.path_index if story.phase<5 else story.awake_index]
	_refresh_hint()
	queue_redraw()

func _paint_balete(at: Vector2,awakening: bool) -> void:
	# One giant, sculpted Balete with projecting bark planes, aerial roots and
	# animated canopy. This is a fictional Keeper, not a sacred entity claim.
	var ground: Vector2 = at+Vector2(0,52)
	for j in range(10):
		var i:=float(j)
		var arc_x:=sin(i*2.399)*224.0
		var arc_y:=cos(i*.94)*58.0
		draw_circle(ground+Vector2(arc_x,arc_y),45,
			Color(.02,.04,.035,.12))
	draw_colored_polygon(PackedVector2Array([
		ground+Vector2(-112,-12),at+Vector2(-133,-275),
		at+Vector2(-67,-502),at+Vector2(8,-560),
		at+Vector2(88,-486),at+Vector2(143,-243),
		ground+Vector2(102,-15),ground+Vector2(26,30)]),Color("#4a5543"))
	draw_colored_polygon(PackedVector2Array([
		ground+Vector2(-48,0),at+Vector2(-54,-500),
		at+Vector2(8,-560),at+Vector2(45,-502),
		at+Vector2(51,-54),ground+Vector2(44,21)]),Color("#78806a"))
	draw_colored_polygon(PackedVector2Array([
		at+Vector2(-131,-266),at+Vector2(-67,-501),
		at+Vector2(-35,-495),at+Vector2(-74,-234)]),Color("#927a56"))
	# Balete buttress roots originate at the FOOT of the trunk, not in
	# the Keeper's shoulders. Curved multi-segment courses avoid the former
	# unnaturally straight wheel-spokes over the player's ground.
	for i in range(9):
		var t: float = (float(i)-4.0)/4.0
		var sway: float = 0.0 if prefs.reduced_motion else sin(clock*.23+float(i)*.75)*2.5
		var base: Vector2 = ground+Vector2(t*73.0,-9.0)
		var first: Vector2 = ground+Vector2(t*139.0+sway,27.0+float(i%3)*11.0)
		var second: Vector2 = ground+Vector2(t*238.0+sin(float(i)*2.1)*26.0,
			71.0+float(i%2)*28.0)
		var end: Vector2 = ground+Vector2(t*(310.0+float(i%3)*44.0),
			112.0+sin(float(i)*1.72)*45.0)
		var course := PackedVector2Array([base,first,second,end])
		draw_polyline(course,Color("#283d33"),41.0-float(i%3)*5.0,true)
		draw_polyline(course,Color("#60705a"),24.0-float(i%3)*3.5,true)
		draw_line(first+Vector2(1,-7),second+Vector2(-2,-7),
			Color("#9b9876",.58),4.0,true)
		# Short forked rootlets, not extra radial beams.
		var sprout: Vector2 = second.lerp(end,.58)
		draw_polyline(PackedVector2Array([
			second,sprout+Vector2((1.0 if i%2==0 else -1.0)*33.0,5),
			sprout+Vector2((1.0 if i%2==0 else -1.0)*62.0,27)]),
			Color("#394c3d"),9.0,true)
	# Angular bark ridges and lichen patches make the trunk a physical
	# hundreds-year-old tree rather than a smooth upright mannequin.
	for grain in range(19):
		var g: float = float(grain)
		var x: float = -97.0+float(grain%10)*21.0
		var top: float = -455.0+float(grain/10)*142.0
		var a: Vector2 = at+Vector2(x,top)
		var b: Vector2 = a+Vector2(sin(g*1.31)*15.0,73.0+float(grain%4)*13.0)
		draw_line(a,b,Color("#293e32",.63),5.0,true)
		draw_line(a+Vector2(4,0),b+Vector2(2,0),
			Color("#a8a080",.39),2.0,true)
	for clump in range(13):
		var n: float = float(clump)
		var patch: Vector2 = at+Vector2(-111.0+float(clump%7)*36.0,
			-413.0+float(clump/7)*142.0+sin(n)*17.0)
		draw_circle(patch,7.0+float(clump%3)*4.0,
			Color("#69856a",.43))
	# Overlapping leaf masses with lit edges, asymmetric silhouettes and
	# hanging adventitious roots, characteristic of a mature Balete.
	for layer in range(4):
		for i in range(19):
			var rad: float = float(i)*TAU/19.0
			var spread: float = 336.0-float(layer)*49.0
			var foot: Vector2 = at+Vector2(
				cos(rad)*spread+sin(float(i)*2.83)*23.0,
				-531.0+sin(rad)*149.0+float(layer)*53.0)
			var shift: float = 0.0 if prefs.reduced_motion else sin(clock*.31+float(i)) * 3.2
			var size: float = 74.0-float(layer)*8.0+float(i%4)*4.0
			draw_circle(foot+Vector2(shift,5),size+8.0,
				Color("#192f2b") if _stage()>=2 else Color("#2e5041"))
			draw_circle(foot+Vector2(shift-9,-13),size*.79,
				Color("#3b5946") if _stage()>=2 else Color("#597655"))
			for leaf_id in range(3):
				var n: float = float(leaf_id)
				draw_colored_polygon(PackedVector2Array([
					foot+Vector2(shift-15+n*17,-12),
					foot+Vector2(shift-9+n*17,-29),
					foot+Vector2(shift+5+n*17,-14),
					foot+Vector2(shift-2+n*17,1)]),
					Color("#708668",.47) if _stage()>=2 else Color("#849a70",.67))
	for aerial in range(13):
		var n: float = float(aerial)
		var x: float = -302.0+n*50.0+sin(n*1.77)*12.0
		var top: Vector2 = at+Vector2(x,-527.0+cos(n*.71)*49.0)
		var end: Vector2 = top+Vector2(sin(n*1.8)*18.0,
			157.0+float(aerial%4)*39.0)
		draw_polyline(PackedVector2Array([
			top,top.lerp(end,.35)+Vector2(9,3),
			top.lerp(end,.68)+Vector2(-5,-7),end]),
			Color("#7c8a66",.77),3.5+float(aerial%3)*.7,true)
		draw_circle(end,3.6,Color("#a39c71",.70))
	if awakening:
		for k in range(8):
			var an := float(k)*TAU/8
			draw_arc(at+Vector2(0,-220),154+float(k%3)*31,
				an,an+.78,14,Color(.79,.85,.59,.12),4.0,true)
		# Humanoid figure merges back into the mighty trunk at final trial;
		# its scale communicates force without a targetable enemy HP bar.
		var breathe:=0.0 if prefs.reduced_motion else sin(clock*.63)*5
		var face: Vector2=at+Vector2(1,-305+breathe)
		draw_circle(face+Vector2(0,6),50,Color(.10,.18,.14,.13))
		draw_colored_polygon(PackedVector2Array([
			face+Vector2(-43,-18),face+Vector2(-28,-43),
			face+Vector2(5,-49),face+Vector2(33,-30),
			face+Vector2(45,9),face+Vector2(15,45),
			face+Vector2(-25,39),face+Vector2(-47,8)]),Color("#83917a"))
		draw_colored_polygon(PackedVector2Array([
			face+Vector2(-42,-15),face+Vector2(-25,-43),
			face+Vector2(-18,20),face+Vector2(-35,30)]),Color("#536950"))
		draw_line(face+Vector2(-31,-25),face+Vector2(-10,-30),Color("#3c513e"),5,true)
		draw_line(face+Vector2(11,-30),face+Vector2(33,-23),Color("#3c513e"),5,true)
		draw_colored_polygon(PackedVector2Array([
			face+Vector2(0,-17),face+Vector2(9,8),
			face+Vector2(-3,15)]),Color("#a4a88a"))
		draw_line(face+Vector2(-17,23),face+Vector2(12,26),Color("#455c46"),3.4,true)
		# The Keeper is a living outline carved into the trunk, not a
		# separately floating stick-bodied human. Deep carved ribs merge with
		# the tree buttress and retain the folklore creature's silhouette.
		draw_colored_polygon(PackedVector2Array([
			at+Vector2(-61,-267+breathe),at+Vector2(54,-263+breathe),
			at+Vector2(87,-197),at+Vector2(65,-101),
			at+Vector2(-3,-59),at+Vector2(-80,-105),
			at+Vector2(-96,-207)]),Color("#50634e",.92))
		for rib in range(7):
			var rr: float = float(rib)
			var begin: Vector2 = at+Vector2(-58.0+rr*18.0,-248.0+breathe)
			var end: Vector2 = ground+Vector2(-85.0+rr*28.0,-24.0)
			draw_polyline(PackedVector2Array([
				begin,begin.lerp(end,.43)+Vector2(sin(rr*1.9)*10.0,-6.0),end]),
				Color("#7b8a6c",.76),6.0,true)
		draw_line(at+Vector2(-53,-239),at+Vector2(-113,-161),
			Color("#485f4a"),26,true)
		draw_line(at+Vector2(51,-231),at+Vector2(111,-163),
			Color("#485f4a"),27,true)
		draw_line(at+Vector2(-60,-227),at+Vector2(-91,-187),
			Color("#9e9c78",.45),4,true)
		draw_line(at+Vector2(53,-225),at+Vector2(93,-185),
			Color("#9e9c78",.45),4,true)
		draw_circle(face+Vector2(-16,-7),5,Color("#f1d99b"))
		draw_circle(face+Vector2(19,-7),5,Color("#f1d99b"))
		draw_circle(face+Vector2(-16,-7),2,Color("#f6f0cb"))
		draw_circle(face+Vector2(19,-7),2,Color("#f6f0cb"))
		# Subtle bark grain rather than an untextured mannequin torso.
		for grain in range(5):
			var g:=float(grain)
			draw_line(at+Vector2(-36+g*17,-237),
				at+Vector2(-41+g*19,-164+sin(g*1.2)*7),
				Color(.22,.34,.26,.34),2.0,true)

func _paint_hut(foot: Vector2,w: float,lit: bool) -> void:
	draw_circle(foot+Vector2(14,5),w*.48,Color(.02,.04,.03,.21))
	draw_colored_polygon(PackedVector2Array([
		foot+Vector2(-w*.45,-w*.19),foot+Vector2(-w*.46,-w*.8),
		foot+Vector2(0,-w*1.08),foot+Vector2(0,-w*.30)]),Color("#98876a"))
	draw_colored_polygon(PackedVector2Array([
		foot+Vector2(0,-w*.30),foot+Vector2(0,-w*1.08),
		foot+Vector2(w*.47,-w*.79),foot+Vector2(w*.47,-w*.18)]),Color("#596859"))
	draw_colored_polygon(PackedVector2Array([
		foot+Vector2(-w*.54,-w*.83),foot+Vector2(-w*.05,-w*1.33),
		foot+Vector2(w*.51,-w*1.12),foot+Vector2(0,-w*.74)]),Color("#554d3e"))
	draw_line(foot+Vector2(-w*.54,-w*.83),foot+Vector2(-w*.05,-w*1.33),
		Color("#b9a17d"),4,true)
	draw_rect(Rect2(foot+Vector2(-w*.22,-w*.48),Vector2(w*.2,w*.30)),Color("#4e483c"))
	Windows.paint_window(self,foot+Vector2(w*.27,-w*.72),
		Vector2(w*.19,w*.18),0,_stage()>=2,clock,prefs.reduced_motion)
	for i in range(5):
		draw_line(foot+Vector2(-w*.43,-w*.71+float(i)*w*.09),
			foot+Vector2(-w*.02,-w*.92+float(i)*w*.09),
			Color(.85,.77,.61,.35),1.8,true)

func _paint_groundlife() -> void:
	# River valley foothills: broad, irregular moss and leaf-litter islands,
	# short grass and fallen twigs, not a flat color or tile/square pattern.
	# Fixed deterministic placements preserve the same landmarks and fps
	# while the camera moves; all drawn BELOW the walkable paths and HUD.
	for patch in range(126):
		var n := float(patch)
		var col := float(patch % 14)
		var row := float(patch / 14)
		var foot := Vector2(-1130+col*176+sin(n*1.61)*46,
			-745+row*177+cos(n*.97)*35)
		var w := 49.0+float(patch%5)*17.0
		var h := 19.0+float(patch%4)*8.0
		var moss := Color("#4e7159") if patch%4==0 else Color("#64806a") if patch%4==1 else Color("#405e51") if patch%4==2 else Color("#76846c")
		draw_colored_polygon(PackedVector2Array([
			foot+Vector2(-w*.62,-h*.2),foot+Vector2(-w*.24,-h*.59),
			foot+Vector2(w*.34,-h*.47),foot+Vector2(w*.69,-h*.10),
			foot+Vector2(w*.40,h*.57),foot+Vector2(-w*.44,h*.42)]),
			moss.darkened(.15) if _stage()>=2 else moss)
		# Real organic stems cut through the flat ground at the tuft base.
		for blade in range(3):
			var origin := foot+Vector2(float(blade-1)*16,4)
			var bend := sin(n*.91+float(blade))*6.0
			draw_line(origin,origin+Vector2(bend,-12.0-float(blade%2)*7),
				Color("#8f9a6a") if patch%2==0 else Color("#567963"),2.2,true)
	for drift in range(49):
		var n := float(drift)
		var at := Vector2(-1080+float(drift%11)*221+sin(n*2.13)*36,
			-580+float(drift/11)*335+cos(n*.81)*48)
		var delta := Vector2(26+float(drift%3)*16,-11.0+sin(n*.71)*7)
		draw_line(at,at+delta,Color("#7b7554"),3.7,true)
		draw_line(at+delta*.48,at+delta*.48+Vector2(9,-15),
			Color("#aa9e73"),2.3,true)


func _draw() -> void:
	var night:=_stage()>=2
	var morning: bool = story.phase == 7 or qa_view == 4
	draw_rect(MAP.grow(450),Color("#2c4940"))
	Landscape.parallax_ridges(self,MAP.grow(280),camera.position,7,3 if night else 0)
	for band in range(22):
		var tone: Color=Color("#38554d").lerp(Color("#687b61"),float(band)/21.0)
		draw_rect(Rect2(-2700,-330+float(band)*78,5100,80),tone)
	draw_texture_rect(SOIL,Rect2(-2600,-1100,4900,2200),false,Color(1,1,1,.15))
	_paint_groundlife()
	var road: PackedVector2Array=PackedVector2Array([
		RIVER_TRAIL,Vector2(-879,267),READINESS_BOARD,
		Vector2(-618,88),MEETING,Vector2(-311,-132),
		GATE,PATH_STONES[0],PATH_STONES[1],PATH_STONES[2]])
	draw_polyline(road,Color("#36493f"),108,true)
	draw_polyline(road,Color("#ac9776"),76,true)
	# Secondary public access to witnessed records; not an empty giant map.
	draw_polyline(PackedVector2Array([
		MEETING,COMMIT_POS["correct_archive"],COMMIT_POS["protect_witnesses"],
		COMMIT_POS["family_memorial"],GATE]),Color("#a18b71"),37,true)
	# Archive house and inhabited village edge before entering the grove.
	_paint_hut(Vector2(-900,-170),192,true)
	_paint_hut(Vector2(-610,-331),186,true)
	_paint_hut(Vector2(-330,-327),170,true)
	for foot in [Vector2(-1080,-190),Vector2(-1020,-620),Vector2(-520,-612),
		Vector2(105,-640),Vector2(1040,-365),Vector2(1080,307)]:
		Depth.paint_grounded(self,TREE,foot,Vector2(240,295),Color("#bec9ae"),.25)
	for foot in [Vector2(-984,125),Vector2(-285,258),Vector2(830,333)]:
		Depth.paint_grounded(self,BANANA,foot,Vector2(125,171),Color("#c9d2ad"),.19)
	# Dry stone and grass relief avoids featureless square terrain patches.
	for i in range(19):
		var at:=Vector2(-1120+float(i)*133,-435+sin(float(i)*1.75)*77)
		if at.distance_to(MEETING)>140:
			Landscape.rock(self,at,16+float(i%4)*4,not night)
	# The central community table, its lantern and the archive ledger.
	draw_colored_polygon(PackedVector2Array([
		MEETING+Vector2(-134,2),MEETING+Vector2(-43,-53),
		MEETING+Vector2(136,3),MEETING+Vector2(39,54)]),Color("#aa9274"))
	draw_colored_polygon(PackedVector2Array([
		MEETING+Vector2(-134,2),MEETING+Vector2(39,54),
		MEETING+Vector2(39,85),MEETING+Vector2(-134,29)]),Color("#655747"))
	draw_line(MEETING+Vector2(-52,-27),MEETING+Vector2(78,12),
		Color("#e3d2a9"),7.0,true)
	Depth.lantern(self,LANTERN,MEETING+Vector2(-136,10),Vector2(95,137),night)
	# Historical exhibition: three distinct records with contextual indicators.
	for id in Story.FACTS:
		var at: Vector2=FACT_POS[id]
		draw_circle(at+Vector2(5,6),29,Color(.018,.05,.04,.24))
		draw_rect(Rect2(at+Vector2(-33,-72),Vector2(65,61)),Color("#81684a"))
		draw_rect(Rect2(at+Vector2(-27,-66),Vector2(53,47)),
			Color("#b7d0be") if story.presented.has(id) else Color("#e3cf9d"))
		for l in range(3):
			draw_line(at+Vector2(-18,-51+float(l)*12),
				at+Vector2(18,-51+float(l)*12),Color("#7a7862"),2,true)
		if story.phase == 1 and player_pos.distance_to(at)<165:
			draw_string(ThemeDB.fallback_font,at+Vector2(-78,35),
				id.replace("_"," ").to_upper(),HORIZONTAL_ALIGNMENT_CENTER,158,15,Color("#f2e3bb"))
	for id in Story.COMMITMENTS:
		var at: Vector2=COMMIT_POS[id]
		draw_circle(at+Vector2(0,7),32,Color(.018,.048,.04,.22))
		draw_colored_polygon(PackedVector2Array([
			at+Vector2(-39,-21),at+Vector2(27,-42),
			at+Vector2(43,-11),at+Vector2(-26,10)]),
			Color("#a6bca2") if story.commitments.has(id) else Color("#ba9a69"))
		draw_line(at+Vector2(-21,-7),at+Vector2(21,-24),Color("#e9e4c9"),3,true)
	# A visible roped threshold is closed until the explicit readiness/gathering gate.
	for edge in [GATE+Vector2(-44,20),GATE+Vector2(44,-14)]:
		draw_line(edge,edge+Vector2(0,-84),Color("#725d49"),11,true)
	if story.phase < 2:
		draw_line(GATE+Vector2(-44,-50),GATE+Vector2(44,-81),
			Color("#dec098"),6,true)
	# Giant Balete is dominant and fixed to the authored glade ground.
	_paint_balete(KEEPER,story.phase>=2 or qa_view==3)
	var rootpath:=PackedVector2Array([GATE,PATH_STONES[0],PATH_STONES[1],PATH_STONES[2]])
	draw_polyline(rootpath,Color("#364f45"),60,true)
	for i in range(PATH_STONES.size()):
		var foot: Vector2=PATH_STONES[i]
		Landscape.rock(self,foot,61,not night)
		draw_circle(foot+Vector2(0,-12),11,
			Color("#e8d099") if story.phase>=3 and i<=story.path_index else Color("#7fa19b"))
		if story.phase==3 and i==story.path_index:
			draw_arc(foot+Vector2(0,-13),48,0,TAU,28,Color("#edcc8d"),3,true)
	var defense_path:=PackedVector2Array([
		PATH_STONES[2],AWAKENED_STONES[0],AWAKENED_STONES[1],AWAKENED_STONES[2]])
	draw_polyline(defense_path,Color("#435448"),56,true)
	for i in range(AWAKENED_STONES.size()):
		var at: Vector2=AWAKENED_STONES[i]
		Landscape.rock(self,at,63,not night)
		if story.phase==5 and i==story.awake_index:
			draw_arc(at,49,0,TAU,30,Color("#e9ca89"),3,true)
	if story.phase in [3,5] or qa_view==3:
		# Warnings pulse as slow arcs and never hide the floor's safe path.
		var c: Vector2=_active_stone()
		for i in range(3):
			var radius:=74+float(i)*37
			var half:=0.0 if prefs.reduced_motion else sin(clock*.87+float(i))*.11
			draw_arc(c,radius,PI*.15+half,PI*.86+half,24,
				Color(.86,.70,.43,.10),3,true)
	if night:
		draw_rect(MAP.grow(450),Color(.015,.026,.066,.25))
		Landscape.mist(self,KEEPER+Vector2(10,87),640,clock,
			not prefs.reduced_motion,true)
		# Warm firefly edge light reveals the Keeper's grounded carved face
		# and path; a dark unlit silhouette alone was unreadable on Android.
		if story.phase in [2,3,4,5,6] or qa_view == 3:
			var eyes: Vector2 = KEEPER+Vector2(1,-312)
			draw_circle(eyes+Vector2(-16,-7),13,
				Color("#e2c87e",.14))
			draw_circle(eyes+Vector2(19,-7),13,
				Color("#e2c87e",.14))
			for i in range(6):
				var n: float = float(i)
				var at: Vector2 = KEEPER+Vector2(
					sin(n*2.34)*164,-219+cos(n*1.23)*174)
				var pulse: float = .0 if prefs.reduced_motion else sin(clock*.57+n)*2.4
				draw_circle(at+Vector2(0,pulse),3.5+float(i%2),
					Color("#efdb93",.40))
	if morning:
		draw_rect(MAP.grow(450),Color(.78,.70,.46,.06))
	# Physical silhouettes stay visible as the day advances, withdrawing from
	# the dangerous glade at midnight. Their consent is handled in dialogue.
	if not night or story.phase == 7 or qa_view == 4:
		for actor in [[MARA,MARA_AT,Vector2(99,146)],
			[SABEL,SABEL_AT,Vector2(98,145)],
			[DADO,DADO_AT,Vector2(100,148)],
			[LOLA,LOLA_AT,Vector2(102,153)]]:
			if actor[0]==LOLA and not story.lola_is_living: continue
			Depth.paint_grounded(self,actor[0],actor[1],actor[2],Color.WHITE,.24)
	var bob:=0.0 if prefs.reduced_motion else absf(sin(walk))*2.4
	Depth.paint_grounded(self,BANTAY,bantay_pos,Vector2(94,101),Color.WHITE,.28,bob)
	Depth.paint_grounded(self,HERO,player_pos,Vector2(108,142),Color.WHITE,.35,bob)
	if player_pos.distance_to(RIVER_TRAIL)<240:
		draw_string(ThemeDB.fallback_font,RIVER_TRAIL+Vector2(-33,-72),
			"RIVER RETURN",HORIZONTAL_ALIGNMENT_CENTER,190,16,Color("#f0e1b9"))
	if player_pos.distance_to(GATE)<240 and story.phase<2:
		draw_string(ThemeDB.fallback_font,GATE+Vector2(-93,-110),
			"FINAL TRIAL • PREPARE FIRST",HORIZONTAL_ALIGNMENT_CENTER,235,16,Color("#ecd7a4"))
	if story.phase in [2,3,4,5,6] and player_pos.distance_to(KEEPER)<300:
		draw_string(ThemeDB.fallback_font,KEEPER+Vector2(-124,103),
			"ANCIENT KEEPER • FICTIONAL GUARDIAN",HORIZONTAL_ALIGNMENT_CENTER,320,16,Color("#e4dbc1"))

func _build_ui() -> void:
	hud=CanvasLayer.new()
	hud.layer=5
	hud.name="Night07HUD"
	add_child(hud)
	controls=Control.new()
	controls.name="SharedGameplayHUD"
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.add_child(controls)
	var card: Dictionary=SharedHUD.create_status_card(controls,
		"TABI-TABI  •  NIGHT 7 / BALETE GROUNDS",prefs.text_scale)
	status_panel=card["panel"]
	status_stack=card["stack"]
	objective=card["objective"]
	status_stack.minimum_size_changed.connect(func():call_deferred("_fit_status"))
	subtitle=_label(status_stack,"",18,Color("#ccd8cb"))
	trust_line=_label(status_stack,"",16,Color("#edcd9a"))
	waypoint=_label(status_stack,"",16,Color("#b6d7cb"))
	prompt=SharedHUD.make_nearby_prompt(controls,prefs.text_scale)
	for direction in SharedHUD.MOVE_POSITIONS:
		var at: Vector2=SharedHUD.MOVE_POSITIONS[direction]
		var glyph: String=str({"up":"▲","left":"◀","right":"▶","down":"▼"}.get(direction,"▲"))
		var button:=SharedHUD.make_gameplay_button(controls,glyph,at,Vector2(70,65),
			func():_hold(direction,true),func():_hold(direction,false),prefs.text_scale)
		button.name="Move_"+direction
		button.mouse_exited.connect(func():_hold(direction,false))
	for title in SharedHUD.ACTION_POSITIONS:
		var at: Vector2=SharedHUD.ACTION_POSITIONS[title]
		match title:
			"FIELD NOTES":
				SharedHUD.make_gameplay_button(controls,title,at,Vector2(180,60),
					_open_notebook,func():pass,prefs.text_scale)
			"HOLD OBSERVE":
				var watch:=SharedHUD.make_gameplay_button(controls,title,at,Vector2(180,60),
					func():observing=true,func():observing=false,prefs.text_scale)
				watch.mouse_exited.connect(func():observing=false)
			"INTERACT":
				SharedHUD.make_gameplay_button(controls,title,at,Vector2(180,60),
					_interact,func():pass,prefs.text_scale)
			"SAFE RETREAT":
				SharedHUD.make_gameplay_button(controls,title,at,Vector2(180,60),
					_confirm_retreat,func():pass,prefs.text_scale)
	var prep:=SharedHUD.make_gameplay_button(controls,"PREPARE",Vector2(1050,276),
		Vector2(180,56),_open_preparation,func():pass,prefs.text_scale)
	prep.name="PrepareButton"
	var save:=SharedHUD.make_gameplay_button(controls,"SAVE",Vector2(1050,345),
		Vector2(85,52),_save_feedback,func():pass,prefs.text_scale)
	save.name="SaveButton"
	var retry:=SharedHUD.make_gameplay_button(controls,"RETRY",Vector2(1142,345),
		Vector2(88,52),_retry_save,func():pass,prefs.text_scale)
	retry.name="RetryButton"
	SharedHUD.make_options_button(controls,_open_options,prefs.text_scale)
	var look:=AimPad.new()
	look.name="SharedLookPad"
	look.prompt_text="LOOK AROUND"
	look.anchor_left=1.0
	look.anchor_right=1.0
	look.anchor_top=1.0
	look.anchor_bottom=1.0
	look.offset_left=-435
	look.offset_right=-260
	look.offset_top=-205
	look.offset_bottom=-40
	look.aim_changed.connect(func(v: Vector2):looking=v)
	look.aim_released.connect(func():looking=Vector2.ZERO)
	controls.add_child(look)
	meter=ProgressBar.new()
	meter.anchor_left=.34
	meter.anchor_right=.67
	meter.offset_top=71
	meter.offset_bottom=93
	meter.max_value=100
	meter.show_percentage=false
	meter.visible=false
	controls.add_child(meter)
	darken=ColorRect.new()
	darken.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	darken.color=Color(.01,.015,.018,.63)
	darken.mouse_filter=Control.MOUSE_FILTER_STOP
	hud.add_child(darken)
	dialogue=_panel(darken,"KeeperDialogue",Vector4(.14,.10,.86,.91))
	var ds:=_stack(dialogue)
	speaker=_label(ds,"",26,Color("#e7d398"))
	speech=_label(ds,"",22,Color("#eef0e3"))
	speech.custom_minimum_size.y=82
	choices=VBoxContainer.new()
	choices.add_theme_constant_override("separation",6)
	ds.add_child(choices)
	notebook=_panel(darken,"FinalReadinessNotebook",Vector4(.12,.06,.88,.94))
	var ns:=_stack(notebook)
	_label(ns,"THE LAST NIGHT • RECORDS & RESPONSIBILITY",26,Color("#eacb91"))
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	ns.add_child(scroll)
	notebook_text=_label(scroll,"",20,Color("#eef0e1"))
	notebook_text.custom_minimum_size.x=635
	_button(ns,"RETURN TO BALETE GROUNDS",func():notebook.hide();_sync_ui())
	options=_panel(darken,"Night07Options",Vector4(.22,.15,.78,.85))
	var os:=_stack(options)
	_label(os,"NIGHT 7 • PAUSE",27,Color("#e8d19c"))
	_button(os,"SAVE THE STORY",_save_feedback)
	_button(os,"OPEN FIELD NOTES",_open_notebook)
	_button(os,"SAVE AND TITLE",_save_menu)
	_button(os,"RETURN TO WORLD",func():options.hide();_sync_ui())
	outcome_panel=_panel(darken,"KeeperFinalOutcome",Vector4(.15,.10,.85,.90))
	save_error=AcceptDialog.new()
	save_error.dialog_text="Unable to write this offline chapter save; check device storage."
	hud.add_child(save_error)
	dialogue.hide()
	notebook.hide()
	options.hide()
	outcome_panel.hide()
	darken.hide()

func _fit_status() -> void:
	if status_panel==null or status_stack==null or not is_inside_tree(): return
	var needed:=status_stack.get_combined_minimum_size().y+32.0
	status_panel.offset_bottom=clampf(needed,144.0,
		get_viewport().get_visible_rect().size.y*.67)

func _panel(parent: Control,title: String,bounds: Vector4) -> PanelContainer:
	var p:=PanelContainer.new()
	p.name=title
	p.anchor_left=bounds.x
	p.anchor_top=bounds.y
	p.anchor_right=bounds.z
	p.anchor_bottom=bounds.w
	SharedHUD.style_modal_panel(p)
	parent.add_child(p)
	return p

func _stack(parent: Node) -> VBoxContainer:
	var box:=VBoxContainer.new()
	box.add_theme_constant_override("separation",7)
	parent.add_child(box)
	return box

func _label(parent: Node,value: String,scale: int,color: Color) -> Label:
	var l:=Label.new()
	l.text=value
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",scale)
	l.add_theme_color_override("font_color",color)
	parent.add_child(l)
	return l

func _button(parent: Node,value: String,callback: Callable) -> Button:
	var b:=Button.new()
	b.text=value
	b.clip_text=true
	SharedHUD.style_modal_button(b,false,true,prefs.text_scale)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _hold(id: String,on: bool) -> void:
	held[id]=on
	moving=Vector2(float(int(held.get("right",false))-int(held.get("left",false))),
		float(int(held.get("down",false))-int(held.get("up",false)))).limit_length()

func _nearest() -> String:
	if player_pos.distance_to(RIVER_TRAIL)<128: return "river_return"
	if story.phase == 0:
		if player_pos.distance_to(READINESS_BOARD)<190: return "readiness"
		if player_pos.distance_to(GATE)<120: return "begin_trial"
	elif story.phase == 1:
		if not story.sabel_choice_respected and player_pos.distance_to(SABEL_AT)<135:
			return "sabel"
		for id in Story.FACTS:
			if not story.presented.has(id) and player_pos.distance_to(FACT_POS[id])<87:
				return "fact_"+id
		for id in Story.COMMITMENTS:
			if not story.commitments.has(id) and player_pos.distance_to(COMMIT_POS[id])<106:
				return "commit_"+id
		if not story.lola_reflected and player_pos.distance_to(LOLA_AT)<122: return "lola"
		if not story.public_acknowledged and player_pos.distance_to(PUBLIC_RECORD)<128: return "public"
		if player_pos.distance_to(GATE)<160: return "gather_finish"
	elif story.phase == 2:
		if player_pos.distance_to(GATE)<185 or player_pos.distance_to(KEEPER)<205:
			return "keeper_intro"
	elif story.phase == 3:
		if player_pos.distance_to(_active_stone())<128: return "path_cue"
	elif story.phase == 4:
		if player_pos.distance_to(KEEPER)<265 or player_pos.distance_to(PATH_STONES[2])<165:
			return "truth"
	elif story.phase == 5:
		if player_pos.distance_to(_active_stone())<145: return "awake_cue"
	elif story.phase == 6:
		if player_pos.distance_to(KEEPER)<275 or player_pos.distance_to(AWAKENED_STONES[2])<210:
			return "final_words"
	elif story.phase == 7:
		for id in EPILOGUE_POS:
			if player_pos.distance_to(EPILOGUE_POS[id])<130:
				return "epilogue_"+id
	return ""

func _interact() -> void:
	if _modal() or travel_in_progress: return
	var id:=_nearest()
	if id=="river_return":
		_return_to_river()
	elif id=="readiness" or id=="begin_trial":
		_readiness_dialog()
	elif id=="sabel":
		_talk("ALING SABEL • CONSENT IS HERS",
			"Ang iyang desisyon sa iyang bana nagpabiling iyang kaugalingon. Whether she wants privacy, written remembrance or to speak publicly, the verified historical record can be corrected without naming a private witness.",
			[{"label":"RESPECT HER EXISTING CHOICE","id":"respect_sabel"}])
	elif id.begins_with("fact_"):
		var which: String=id.trim_prefix("fact_")
		if story.previous_fact_verified(which):
			_talk("COMMUNITY ARCHIVE • CORROBORATED RECORD",
				"Show the community the documented finding: "+which.replace("_"," ")+". No invented omniscient testimony, no victim spirits.",
				[{"label":"PRESENT VERIFIED EVIDENCE","id":"present_"+which},
				{"label":"REVIEW NOTES FIRST","id":"notes"}])
		else:
			_talk("MARA • DOCUMENT THE UNCERTAINTY",
				"We cannot pronounce a fact without a source. The physical archive contains surviving records; inspect the additional corroboration at this board, or leave the gap acknowledged.",
				[{"label":"INSPECT ARCHIVE CORROBORATION","id":"recover_"+which},
				{"label":"KEEP IT UNRESOLVED FOR NOW","id":"close"}])
	elif id.begins_with("commit_"):
		var task: String=id.trim_prefix("commit_")
		if task=="family_memorial" and not story.sabel_choice_respected:
			_talk("FAMILY REMEMBRANCE",
				"Speak to Sabel privately first. A memorial is not permission to expose her grief.",
				[{"label":"RETURN TO SABEL","id":"close"}])
		else:
			var description:= {
				"correct_archive":"Ruben and Mara will compare the official flood ledger against survivor-verified records and publish corrections.",
				"protect_witnesses":"The barrio will preserve private names securely and let witnesses decide whether to speak.",
				"family_memorial":"Build a modest memorial plan with families' permission. Names require consent; private remembrance counts."
			}
			_talk("GATHERING • WORK TO BE DONE",str(description[task]),
				[{"label":"CONFIRM A CONCRETE COMMUNITY TASK","id":"pledge_"+task},
				{"label":"NOT YET","id":"close"}])
	elif id=="lola":
		_talk("LOLA PASING • A SEPARATE HUMAN STORY",
			"I kept the evidence to protect people, then let my silence last too long. The Keeper protected only the high refuge. I can acknowledge that without asking anyone to forgive me. My life is not payment for this trial.",
			[{"label":"LET HER SPEAK WITHOUT FORCING FORGIVENESS","id":"lola_reflect"}])
	elif id=="public":
		_talk("MARA • AN HONEST PUBLIC RECORD",
			"We can tell people the confirmed order, the rescuer's action and the limited refuge without publishing private family names. Do we now acknowledge the documented facts in the community ledger?",
			[{"label":"ACKNOWLEDGE DOCUMENTED TRUTH WITH PRIVACY","id":"public_record"},
			 {"label":"REVIEW EVIDENCE AGAIN","id":"notes"}])
	elif id=="gather_finish":
		if story.conclude_gathering():
			_save_story()
			_talk("MARA • GATHERING OF REMEMBRANCE",
				"Records have been heard and public accountability begun. We do not need unanimous forgiveness. The Keeper has no way to know private historical facts unless we present them.",
				[{"label":"WALK INTO THE BALETE GROUNDS","id":"close"}])
		else:
			_talk("GATHERING • RECOVERABLE TASKS",
				"Present at least one verified source, respect Sabel's privacy, and make the factual public record. You may revisit the archive; no previous Resolve counter blocks the door.",
				[{"label":"OPEN NOTEBOOK","id":"notes"},{"label":"KEEP WORKING","id":"close"}])
	elif id=="keeper_intro":
		if story.reveal_keeper():
			_save_story()
			_talk("ANCIENT KEEPER • THE COVENANT",
				"Nangayo kamo og lugar diin makalingkawas. Unsa man ang inyong gibuhat sa mga wala nakaabot? Dili ko makapili sa inyong pulong, ug dili ko makapugos sa pagpasaylo. I can witness actions, not know your hidden records.",
				[{"label":"FACE THE PATH TRIAL","id":"close"}])
	elif id in ["path_cue","awake_cue"]:
		if story.warning_ready: _show_cue()
		else:
			_talk("BANTAY • THE ROOTS ARE MOVING",
				"Stand on the illuminated grounded stone. HOLD OBSERVE until the warning is visible; do not guess through a blind timing attack.",
				[{"label":"WATCH THE WARNING","id":"close"}])
	elif id=="truth":
		_show_truth()
	elif id=="final_words":
		_show_final_choice()
	elif id.begins_with("epilogue_"):
		_epilogue(id.trim_prefix("epilogue_"))
	else:
		_talk("BANTAY • WALK THE VISIBLE ROAD",
			"Your notebook describes the next evidence or safe stone. Follow the path. You can always save and return; the Keeper is not a sudden one-shot trap.",
			[{"label":"CONTINUE","id":"close"}])
	_refresh()

func _readiness_dialog() -> void:
	# Merely approaching the board is not a notebook review; require
	# the actual reading action before confirming the final checkpoint.
	var missing:=story.readiness_missing()
	var details: String="Historical evidence and the consent decisions are in your notes. This is an explicit point of no surprise lockout; return to the river for unresolved details or begin the final trial."
	if missing.size()>0:
		details+="\nUnresolved: "+str(missing[0])
	_talk("FINAL READINESS • EVIDENCE BEFORE CHOICE",details,
		[{"label":"REVIEW THE FINAL NOTEBOOK","id":"notes"},
		 {"label":"ACKNOWLEDGE GAPS AND PRIVACY","id":"acknowledge"},
		 {"label":"BEGIN FINAL TRIAL (CHECKPOINT)","id":"begin_final"},
		 {"label":"RETURN TO NIGHT 6 RIVER","id":"return_river"}])

func _show_cue() -> void:
	if not story.warning_ready: return
	if story.phase == 3:
		var cue: String=[
			"PATH 1 • Mist hides the safe stone. Bantay hears wood cracking. What reveals the edge?",
			"PATH 2 • A false footprint crosses the exposed roots. Who tracks the safe ground?",
			"PATH 3 • The twisted root has one solid, bark-marked crossing. Which action is safe?"
		][story.path_index]
		_talk("THE KEEPER • PATH WARNING %d/3" % [story.path_index+1],cue,[
			{"label":"RAISE THE LANTERN","id":"path_raise_lantern"},
			{"label":"FOLLOW BANTAY'S TRACKS","id":"path_follow_bantay"},
			{"label":"CROSS THE MARKED ROOT","id":"path_cross_root"}])
	elif story.phase == 5:
		var cue: String=[
			"AWAKENED ROOT 1 • The glade bridge lifts. The rope anchor is still accessible.",
			"AWAKENED ROOT 2 • Broad leaves swing down in front of the party. Light shows the safe gap.",
			"AWAKENED ROOT 3 • The root line approaches the barrio path. Protect neighbours, not a boss HP bar."
		][story.awake_index]
		_talk("THE BALETE AWAKENS • SURGE %d/3" % [story.awake_index+1],cue,[
			{"label":"ANCHOR THE ROPE","id":"awake_anchor_rope"},
			{"label":"RAISE THE LANTERN","id":"awake_raise_lantern"},
			{"label":"SHIELD THE NEIGHBOURS","id":"awake_shield_neighbors"}])

func _show_truth() -> void:
	if story.phase != 4 or story.truth_index >= 3: return
	var id: String=Story.FACTS[story.truth_index]
	var line: String={
		"cancelled_rescue":"Keeper asks: why did the official second rescue stop? The flood was dangerous, but the decision shielded some neighbours unequally.",
		"returning_boat":"Keeper asks: who helped the far bank? No magical record reveals identities; the community's separate boat and survivor sources do.",
		"limited_refuge":"Keeper asks: could I save the stranded far bank? My reach covered only the elevated refuge by Balete Grounds."
	}[id]
	var options2: Array=[
		{"label":"PRESENT THE CORROBORATED FACT","id":"truth_"+id},
		{"label":"ADMIT THIS IS NOT YET VERIFIED","id":"truth_unknown"},
		{"label":"REVIEW SOURCES","id":"notes"}
	]
	_talk("KEEPER • TRUTH TRIAL %d/3" % [story.truth_index+1],line,options2)

func _show_final_choice() -> void:
	if story.phase != 6: return
	var available:=story.offer_outcomes()
	var options2: Array=[]
	if available.has("true"):
		options2.append({"label":"FULFIL THE PROMISE • RECORDS AND ACTION","id":"ending_true"})
	options2.append({"label":"PROTECT THE BARRIO • TEMPORARY PEACE","id":"ending_good"})
	if available.has("bittersweet"):
		options2.append({"label":"SPEAK TRUTH • COOPERATION REMAINS BROKEN","id":"ending_bittersweet"})
	options2.append({"label":"DELIBERATELY DENY THE KNOWN HISTORY","id":"denial_warning"})
	_talk("ANCIENT KEEPER • WHAT WILL REMAIN?",
		"Kung ang inyong saad mausab na usab ngadto sa kahilom, unsay mopabilin? The Keeper will not accept a pleasant answer without real records and a living community commitment. Your choice is deliberate and has different consequences.",
		options2)

func _epilogue(id: String) -> void:
	if story.phase != 7: return
	story.speak_epilogue(id)
	var speaker2: String="BARRIO LAWOM • THE NEXT MORNING"
	var line: String=""
	match id:
		"mara":
			line="Mara keeps the documented timeline at school; students can question the record safely. Her cooperation began before this final decision."
		"sabel":
			line="Sabel remembers her husband as a laughing neighbour, not only his final night. She chose %s remembrance. No one is entitled to her public testimony." % story.sabel_privacy
		"dado":
			line="Dado shows the path that once led to shelter. Respecting his choice about his name does not erase the verified rescue records."
		"lola":
			line="Lola is resting, still living and accountable to the community. Her personal future is not an automatic reward or sacrifice for a finale." if story.lola_is_living else "Bantay settles beside Lola's keepsake. Her passing was recorded separately, never caused by the player's ending."
		"river":
			line="The river is quieter; the waterline markers remain as public reminders that safety takes maintenance and honest decisions."
		"memorial":
			if story.community_fractured:
				line="A memorial plan exists, but the people responsible have fractured their cooperation. The work is unfinished despite what was promised."
			else:
				line="The community's memorial plan has begun, with families' consent." if story.commitments.has("family_memorial") else "The memorial still has no approved plan; its unfinished notice remains beside the public records."
		"bantay":
			line="Bantay stays beside the Apprentice, in every ending. Life continues even when a promise remains unfinished."
	_save_story()
	_talk(speaker2,line,[{"label":"CONTINUE THE MORNING WALK","id":"close"},
		{"label":"CHOOSE WHEN TO FINISH THE STORY","id":"finish_confirm"}])

func _choose(id: String) -> void:
	if id=="close":
		_close_dialogue()
		return
	if id=="reload":
		get_tree().call_deferred("reload_current_scene")
		return
	if id=="notes" or id=="readiness_notes":
		_open_notebook()
		return
	if id=="return_river":
		_close_dialogue()
		_return_to_river()
		return
	if id=="acknowledge":
		story.acknowledge_privacy()
		_save_story()
		_readiness_dialog()
		return
	if id=="begin_final":
		if story.begin_final_trial():
			_save_story()
			_talk("MARA • A REAL CHECKPOINT",
				"The gathering is now open. Present verified documents, ask consent and propose real responsibilities before facing the Keeper. You can still walk back to the river.",
				[{"label":"MEET WITH THE COMMUNITY","id":"close"}])
		else:
			_talk("MARA • READINESS NOT YET CONFIRMED",
				"Finish or document the Night 6 case, review the notebook and acknowledge privacy. The gate is not a hidden percentage check.",
				[{"label":"REVIEW NOTEBOOK","id":"notes"},{"label":"BACK TO PATH","id":"close"}])
		return
	if id=="respect_sabel":
		if story.respect_sabel():
			_save_story()
			_talk("SABEL • HER CHOICE IS ENOUGH",
				"I will remember him my way. The town can correct its records without requiring me to tell strangers what hurts.",
				[{"label":"RESPECT HER DECISION","id":"close"}])
	elif id=="lola_reflect":
		story.reflect_with_lola()
		_save_story()
		_talk("LOLA PASING • NO FORCED FORGIVENESS",
			"The evidence is no longer mine to hide. I will keep helping while I can; you do not need to excuse what I withheld.",
			[{"label":"CONTINUE","id":"close"}])
	elif id.begins_with("recover_"):
		var fact: String=id.trim_prefix("recover_")
		if story.recover_fact(fact,"archive_corrob"):
			_save_story()
			_talk("MARA • SECONDARY ARCHIVE VERIFIED",
				"The physical meeting exhibit and the dated testimony now corroborate "+fact.replace("_"," ")+". It may be presented as a source-backed claim.",
				[{"label":"RETURN TO RECORD","id":"close"}])
	elif id.begins_with("present_"):
		var fact: String=id.trim_prefix("present_")
		if story.present_fact(fact):
			_save_story()
			_talk("PUBLIC ARCHIVE • FACT ENTERED",
				"The meeting ledger includes "+fact.replace("_"," ")+", with privacy safeguards and a link to the primary record.",
				[{"label":"CONTINUE","id":"close"}])
	elif id.begins_with("pledge_"):
		var pledge: String=id.trim_prefix("pledge_")
		if story.confirm_commitment(pledge):
			_save_story()
			_talk("COMMUNITY • ACTION BEGUN",
				"The public register now includes the practical task "+pledge.replace("_"," ")+". Promises need named people and continuing work, not a magic Keeper approval.",
				[{"label":"CONTINUE","id":"close"}])
	elif id=="public_record":
		if story.acknowledge_public_record():
			_save_story()
			_talk("MARA • THE RECORD IS PUBLIC",
				"Verified facts were publicly acknowledged without exposing protected identities. The Keeper knows only what people bring into the glade.",
				[{"label":"CONTINUE THE GATHERING","id":"close"}])
		else:
			_talk("MARA • NOT READY FOR A PUBLIC CLAIM",
				"Verify at least one historical source and respect Sabel's privacy first.",
				[{"label":"RETURN TO SOURCES","id":"close"}])
	elif id=="retry_stone":
		if story.retry_checkpoint():
			player_pos=GATE if story.phase==3 and story.path_index==0 else PATH_STONES[maxi(0,story.path_index-1)] if story.phase==3 else PATH_STONES[2] if story.awake_index==0 else AWAKENED_STONES[story.awake_index-1]
			_save_story()
			_talk("BANTAY • RETRY WITHOUT LOST EVIDENCE",
				"Earlier roots and every family record are preserved. Observe the current stone before choosing.",
				[{"label":"RETURN TO SAFE PATH","id":"close"}])
	elif id.begins_with("path_"):
		var action: String=id.trim_prefix("path_")
		if story.respond_path(action):
			_save_story()
			if story.phase == 4:
				_talk("KEEPER • THE PATHS SHIFT",
					"Your lantern and Bantay kept you safe. Now show me human records; I cannot know who made which decision without your evidence.",
					[{"label":"FACE THE TRUTH TRIAL","id":"close"}])
			else:
				_talk("BANTAY • GROUND HOLDS",
					"That was the safe action for this warning. Follow the next visible root and observe again.",
					[{"label":"CONTINUE","id":"close"}])
		else:
			_talk("BANTAY • WRONG CUE, SAFE REVISION",
				"No one died and the previous stones remain complete. The lantern, tracks and stable bark have different clues.",
				[{"label":"LOOK AGAIN","id":"close"}])
	elif id.begins_with("truth_"):
		var fact: String=id.trim_prefix("truth_")
		if story.present_truth(fact):
			_save_story()
			_talk("KEEPER • CLAIM WITH SOURCE",
				"That documented fact was presented to me, not guessed from the roots. Corrected records matter because people maintain them.",
				[{"label":"CONTINUE TRUTH TRIAL","id":"close"}])
		else:
			_talk("KEEPER • CORROBORATION REQUIRED",
				"A hidden or unsupported claim is not magically known. Revisit the notebook, or acknowledge a real gap honestly.",
				[{"label":"REVIEW SOURCES","id":"notes"},{"label":"RETURN TO TRIAL","id":"close"}])
	elif id=="truth_unknown":
		if story.admit_truth_gap():
			_save_story()
			_talk("KEEPER • UNFINISHED SOURCE",
				"Your uncertainty was honestly recorded. It cannot fulfill the full promise yet, but it does not trap you or turn the trial into a guessing contest.",
				[{"label":"CONTINUE","id":"close"}])
		else:
			_talk("KEEPER • FACT IS ALREADY AVAILABLE",
				"That source was presented at the meeting. Use its evidence rather than denying a known fact.",
				[{"label":"RETURN TO TRIAL","id":"close"}])
	elif id.begins_with("awake_"):
		var response: String=id.trim_prefix("awake_")
		if story.respond_awakened(response):
			_save_story()
			if story.phase == 6:
				_show_final_choice()
			else:
				_talk("BANTAY • ROOTS EASE FOR A MOMENT",
					"No boss health was removed; the people and traversable path were protected. The next root has a different warning.",
					[{"label":"FOLLOW THE NEXT STONE","id":"close"}])
		else:
			_talk("BANTAY • CHOOSE FROM THE WARNING",
				"We can read the anchor, canopy and village boundary before responding. Retry safely.",
				[{"label":"LOOK AGAIN","id":"close"}])
	elif id=="denial_warning":
		if story.warn_denial():
			_talk("FINAL DECISION • DELIBERATE DENIAL",
				"You are about to knowingly reject the available historical record and abandon community responsibility. This is the DARK ending. One missed puzzle or private witness choice never causes it. Do you deliberately choose this?",
				[{"label":"YES, KNOWINGLY ABANDON THE TRUTH","id":"ending_dark"},
				 {"label":"NO • RETURN TO ACCOUNTABILITY OPTIONS","id":"final_again"}])
	elif id=="final_again":
		_show_final_choice()
	elif id.begins_with("ending_"):
		var result: String=id.trim_prefix("ending_")
		if story.commit(result):
			_save_story()
			player_pos=RIVER_TRAIL+Vector2(255,-130)
			_show_outcome()
	elif id=="epilogue":
		outcome_panel.hide()
		_sync_ui()
		player_pos=RIVER_TRAIL+Vector2(225,-145)
		camera.position=player_pos
		_refresh()
	elif id=="finish_confirm":
		_talk("THE MORNING AFTER • YOUR OWN PACE",
			"You can speak to neighbours and visit the river for as long as you wish. Finish only when you choose; the epilogue and its records remain available in your save.",
			[{"label":"KEEP WALKING","id":"close"},
			 {"label":"FINISH THE STORY & RETURN TO TITLE","id":"finish_story"}])
	elif id=="finish_story":
		if story.finish_story() and _save_story():
			get_tree().change_scene_to_file("res://scenes/title.tscn")
		return
	_refresh()

func _talk(who: String,line: String,actions: Array) -> void:
	notebook.hide()
	options.hide()
	outcome_panel.hide()
	darken.show()
	dialogue.show()
	speaker.text=who
	speech.text=line
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	for option in actions:
		var code: String=str(option["id"])
		_button(choices,str(option["label"]),func():_choose(code))
	DialogueMotion.reveal(dialogue,prefs.reduced_motion)
	DialogueMotion.reveal_text(speech,prefs.reduced_motion)
	_sync_ui()

func _close_dialogue() -> void:
	DialogueMotion.conceal(dialogue,prefs.reduced_motion)
	_sync_ui()
	DialogueMotion.restore_gameplay(controls,prefs.reduced_motion)

func _sync_ui() -> void:
	darken.visible=dialogue.visible or notebook.visible or options.visible or outcome_panel.visible
	controls.visible=not darken.visible
	if darken.visible:
		moving=Vector2.ZERO
		held.clear()
		observing=false

func _refresh() -> void:
	if objective==null:return
	var phases:=["MORNING • READINESS","GATHERING • REMEMBRANCE",
		"EVENING • KEEPER ARRIVES","NIGHT • TRIAL OF PATHS",
		"NIGHT • TRIAL OF TRUTH","MIDNIGHT • AWAKENED BALETE",
		"MIDNIGHT • ACCOUNTABILITY","DAWN • MORNING AFTER"]
	subtitle.text=phases[clampi(story.phase,0,7)]
	match story.phase:
		0: objective.text="Review the final notebook and witness privacy, then explicitly begin the trial."
		1: objective.text="Present historical records, respect Sabel, and record practical community work."
		2: objective.text="Walk along the marked path to the Balete Keeper. Show what the community learned."
		3: objective.text="ROOT PATH %d/3 • use HOLD OBSERVE on the marked stone." % [story.path_index+1]
		4: objective.text="Keeper truth trial • present evidence. Admit genuine gaps instead of inventing proof."
		5: objective.text="AWAKENED ROOTS %d/3 • guard the village and traverse safely." % [story.awake_index+1]
		6: objective.text="Choose an evidence-credible ending. The dark choice requires deliberate confirmation."
		7: objective.text="THE MORNING AFTER • %s • Walk freely; finish when you choose." % story.outcome.to_upper()
	if qa_view!=0:
		var qa_titles: Array[String] = [
			"","MORNING • READINESS VISUAL QA",
			"DUSK • REMEMBRANCE VISUAL QA",
			"MIDNIGHT • AWAKENED BALETE VISUAL QA",
			"DAWN • MORNING PATH VISUAL QA"]
		subtitle.text=qa_titles[clampi(qa_view,0,4)]
		objective.text="ENVIRONMENT PREVIEW • QA CAMERA ONLY • Saved story state unchanged."
	_refresh_hint()
	call_deferred("_fit_status")

func _refresh_hint() -> void:
	if prompt==null: return
	var near:=_nearest()
	prompt.text=("INTERACT • "+near.replace("_"," ").to_upper()) if near!="" else ""
	var goal:=READINESS_BOARD
	var label: String="FINAL NOTEBOOK"
	match story.phase:
		0: goal=READINESS_BOARD
		1:
			goal=GATE
			label="COMMUNITY GATHERING"
			if not story.sabel_choice_respected:
				goal=SABEL_AT
				label="ASK SABEL PRIVATELY"
			elif not story.public_acknowledged:
				goal=PUBLIC_RECORD
				label="PUBLIC RECORD"
		2: goal=GATE;label="THE KEEPER"
		3: goal=_active_stone();label="PATH • HOLD OBSERVE"
		4: goal=KEEPER;label="PRESENT DOCUMENTED TRUTH"
		5: goal=_active_stone();label="AWAKENED ROOT • OBSERVE"
		6: goal=KEEPER;label="FINAL RESPONSIBILITY"
		7: goal=RIVER_TRAIL;label="MORNING WALK / RIVER"
	waypoint.text="%s  •  %d STEPS" % [label,roundi(player_pos.distance_to(goal)/12)]

func _open_notebook() -> void:
	if _modal() and not dialogue.visible and not options.visible and not outcome_panel.visible:
		return
	if story.phase==0:
		story.review_notebook()
		_save_story()
	dialogue.hide()
	options.hide()
	outcome_panel.hide()
	notebook.show()
	darken.show()
	var content: String="NIGHT 7 • FINAL READINESS CHECKPOINT\n\n"
	content+="Earlier six chapter outcomes remain saved independently.\n"
	var past: Dictionary=story.prior_outcomes()
	for id in ["night01","night02","night03","night04","night05","night06"]:
		content+=id.to_upper()+": "+str(past.get(id,"unrecorded"))+"\n"
	content+="\nDOCUMENTED FLOOD EVIDENCE\n"
	for id in Story.FACTS:
		content+=("[VERIFIED] " if story.previous_fact_verified(id) else "[UNRESOLVED] ")+id.replace("_"," ")+"\n"
	content+="\nWITNESS CHOICES\n"
	content+="Sabel: "+story.sabel_privacy+" • PUBLIC APPEARANCE NEVER REQUIRED\n"
	content+="Lola's record: "+("acknowledged" if story.lola_reflected else "can be discussed privately")+"\n"
	content+="\nCOMMUNITY WORK\n"
	for id in Story.COMMITMENTS:
		content+=("[AGREED] " if story.commitments.has(id) else "[PLANNED / NOT YET AGREED] ")+id.replace("_"," ")+"\n"
	content+="Public historical record: "+("acknowledged" if story.public_acknowledged else "not yet acknowledged")+"\n"
	content+="\nNo hidden 5/6 Resolve score. Earlier allies can help, but never gate final evidence or survival. Wrong hypotheses may be revised.\n"
	content+="\nKEEPER: limited to the elevated refuge, not omniscient and not a documented Indigenous ritual. Family consent and continuing human action matter.\n"
	if story.phase==0:
		content+="\nREADINESS ITEMS\n"
		for missing in story.readiness_missing():
			content+="- "+missing+"\n"
		content+="You may return to Night 6 or consciously proceed once prepared.\n"
	notebook_text.text=content
	_sync_ui()

func _open_preparation() -> void:
	if _modal(): return
	_talk("NIGHT 7 • FINAL PREPARATION",
		"The approved Night 1 thumb controls remain unchanged. No boss HP bar: walk the real paths, HOLD OBSERVE for root warnings, present only corroborated facts, and protect family consent. Complete previous nights only as needed; one partial case does not automatically deny the best ending.",
		[{"label":"REVIEW THE NOTEBOOK","id":"notes"},
		 {"label":"RETURN TO WORLD","id":"close"}])

func _retry_save() -> void:
	if _modal(): return
	_talk("RETRY • LAST SAVED CHECKPOINT",
		"Reload the last saved Night 7 checkpoint? This never erases Nights 1–6; only unsaved actions here will be lost.",
		[{"label":"RELOAD THE FINAL-NIGHT CHECKPOINT","id":"reload"},
		 {"label":"CONTINUE CURRENT WALK","id":"close"}])

func _confirm_retreat() -> void:
	if _modal(): return
	_talk("SAFE RETREAT • NO STORY PUNISHMENT",
		"The player may return to Night 6 with a save at any time. The Keeper's environmental trial remains available upon return; this is not the Dark ending.",
		[{"label":"RETURN SAFELY TO THE RIVER","id":"return_river"},
		 {"label":"CONTINUE THE FINAL TRIAL","id":"close"}])

func _open_options() -> void:
	if dialogue.visible or outcome_panel.visible: return
	options.show()
	_sync_ui()

func _save_story() -> bool:
	story.player_position=player_pos
	var saved:=Save.write(story)
	if saved and story.outcome!="":
		World.note_outcome(7,story.outcome)
	return saved

func _save_feedback() -> void:
	if not _save_story():
		save_error.popup_centered(Vector2i(600,185))
		return
	options.hide()
	_talk("FINAL NOTEBOOK SAVED","Night 7 was saved offline. All six prior chapter save files remain untouched.",
		[{"label":"CONTINUE","id":"close"}])

func _save_menu() -> void:
	if _save_story():
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	else:
		save_error.popup_centered(Vector2i(600,185))

func _return_to_river() -> void:
	if travel_in_progress:return
	if not _save_story() or not World.begin_travel("night07","night06",story.outcome):
		save_error.popup_centered(Vector2i(600,185))
		return
	travel_in_progress=true
	get_tree().change_scene_to_file(World.scene_for("night06"))

func _show_outcome() -> void:
	dialogue.hide()
	notebook.hide()
	options.hide()
	outcome_panel.show()
	for child in outcome_panel.get_children():
		outcome_panel.remove_child(child)
		child.queue_free()
	var box:=_stack(outcome_panel)
	_label(box,"TABI-TABI • THE MORNING AFTER",28,Color("#f0d39e"))
	var title: String={
		"true":"TRUE • TABI-TABI",
		"good":"GOOD • THE QUIET BARRIO",
		"bittersweet":"BITTERSWEET • WHAT REMAINS",
		"dark":"DARK • THE DOOR LEFT OPEN"
	}.get(story.outcome,"THE COMMUNITY RECORD")
	_label(box,title,24,Color("#d2e2cb"))
	var descriptions: Dictionary={
		"true":"The essential history was verified and acknowledged with consent, with a real archive, privacy and memorial plan. The Keeper releases its watch: 'Dili na nako kinahanglan dalhon nga ako ra ang nahinumdom.'",
		"good":"The glade settles and people are safe today, but the full community promise remains incomplete. The Keeper warns: 'Ayaw ninyo isagol ang kahilom sa katumanan.'",
		"bittersweet":"Credible truths are public, but cooperation or serious commitments have broken down. Residents now know what happened; not all are ready to respond.",
		"dark":"The known history was knowingly denied. Roots remain unsettled, but Bantay and the Apprentice survive, able to live with and revisit their choice."
	}
	_label(box,str(descriptions.get(story.outcome,"The community returns home.")),21,Color("#e7e6db"))
	_label(box,"LOLA'S PERSONAL STORY IS SEPARATE • SABEL'S PRIVACY REMAINS RESPECTED",17,Color("#b5d2ba"))
	_button(box,"PLAY THE MORNING AFTER",func():_choose("epilogue"))
	_button(box,"REVIEW FINAL EVIDENCE",_open_notebook)
	_button(box,"SAVE & MAIN MENU",_save_menu)
	_sync_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if dialogue.visible:
			if not DialogueMotion.finish_text(speech): _close_dialogue()
		else:
			_interact()
	elif event.is_action_pressed("ui_cancel"):
		if dialogue.visible: _close_dialogue()
		elif notebook.visible: notebook.hide();_sync_ui()
		elif options.visible: options.hide();_sync_ui()
		else: _open_options()
	if OS.get_name()=="Android" and OS.has_feature("debug") and event is InputEventKey:
		var key:=event as InputEventKey
		if key.pressed and not key.echo and key.keycode in [KEY_F3,KEY_F6,KEY_F9,KEY_F11]:
			if dialogue.visible: _close_dialogue()
			notebook.hide()
			outcome_panel.hide()
			options.hide()
			match key.keycode:
				KEY_F3:
					qa_view=1
					player_pos=READINESS_BOARD+Vector2(57,-33)
					print("NIGHT7_QA_READINESS_GROUNDS")
				KEY_F6:
					qa_view=2
					player_pos=PUBLIC_RECORD+Vector2(78,95)
					print("NIGHT7_QA_COMMUNITY_GATHERING")
				KEY_F9:
					qa_view=3
					player_pos=PATH_STONES[2]+Vector2(23,78)
					print("NIGHT7_QA_AWAKENED_BALETE")
				KEY_F11:
					qa_view=4
					player_pos=RIVER_TRAIL+Vector2(240,-240)
					print("NIGHT7_QA_MORNING_PATH")
			camera.position=player_pos
			_refresh()
			_sync_ui()
			get_viewport().set_input_as_handled()
