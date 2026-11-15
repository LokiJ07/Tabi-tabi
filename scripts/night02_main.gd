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
const MANGO: Texture2D = preload("res://assets/night02/old_mango_tree.svg")
const KAPRE: Texture2D = preload("res://assets/night02/kapre.svg")
const BARRIER: Texture2D = preload("res://assets/night02/closed_path_barrier.svg")
const HERO: Texture2D = preload("res://assets/characters/apprentice.svg")
const BANTAY: Texture2D = preload("res://assets/characters/bantay.svg")
const LOLA: Texture2D = preload("res://assets/characters/lola.svg")
const DADO: Texture2D = preload("res://assets/characters/dado.svg")
const MARA: Texture2D = preload("res://assets/characters/mara.svg")
const HOUSE: Texture2D = preload("res://assets/world/nipa_facade.svg")
const SCHOOL: Texture2D = preload("res://assets/world/school_facade.svg")
const HIBISCUS: Texture2D = preload("res://assets/world/hibiscus_bush.svg")
const LANTERN: Texture2D = preload("res://assets/world/lantern_post.svg")
const SOIL: Texture2D = preload("res://assets/world/soil_ground.svg")

const TREE := Vector2(245, -120)
const OBSERVATION := Vector2(-25, -330)
const PLAYER_SPEED := 255.0
const MAP_LIMIT := Rect2(-950, -690, 1900, 1420)
const TARGETS := {
	"fallen_limb": Vector2(470, 82),
	"exposed_roots": Vector2(342, 250),
	"cigar_ash": Vector2(560, -216),
	"shelter_route": Vector2(-446, 272),
	"witness_accounts": Vector2(-546, -335),
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
	"cigar_ash": "A faint cigar ember glows high in the branches. Someone may be watching. You cannot assume what it proves.",
	"shelter_route": "During the Great Flood, this shortcut led families toward shelter. It is now too close to the unstable tree.",
	"witness_accounts": "Mara remembers the Great Flood; Dado remembers a rescue promise that was never kept. The Kapitan wants to cut the tree immediately."
}
const KEY_ORDER := ["fallen_limb", "exposed_roots", "cigar_ash", "shelter_route", "witness_accounts"]

var story = Story.new()
var prefs = Preferences.new()
var player_pos := Vector2(-510, 140)
var dog_pos := Vector2(-580, 192)
var motion := Vector2.ZERO
var held_moves: Dictionary = {}
var observe_held := false
var camera: Camera2D
var hud: CanvasLayer
var objective: Label
var subtitle: Label
var danger: Label
var progress: ProgressBar
var interaction_hint: Label
var action_buttons: Dictionary = {}
var dialogue: PanelContainer
var dialogue_name: Label
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
var elapsed := 0.0
var particle_phase := 0.0
var last_target := ""
var movement_enabled := true

func _ready() -> void:
	name = "TabiTabiNight2"
	prefs.load_from()
	var previous := Night1State.new()
	if not Night1Save.read(previous).is_empty():
		story.night1_outcome = previous.outcome
	Save.read(story) # Distinct save, never rewrites Night 1.
	camera = Camera2D.new()
	camera.name = "Night2IsometricCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = not prefs.reduced_motion
	camera.position_smoothing_speed = 4.0
	camera.position = player_pos
	add_child(camera)
	_build_ui()
	_rebuild_objective()
	if story.outcome != "":
		_show_ending()
	elif story.phase == 0 and story.clues.is_empty():
		_show_dialogue("LOLA PASING",
			"Night 2 — Ang Higante sa Daang Mangga.\n" +
			"Lola: Ang kahoy buhi na sa mga kasaysayan sa baryo. Pero naa nay nangatumpag nga sanga. Ayaw pagpatuyang. Tan-awa una ang peligro.",
			[{"label": "SABTON NAKO, LOLA", "action": "close"}])
	print("NIGHT2_QA_SCENE_READY")
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if not prefs.reduced_motion:
		particle_phase += delta
	var axis := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	axis += motion
	if dialogue.visible or notebook.visible or options_panel.visible or ending_panel.visible or menu_confirm.visible or quit_confirm.visible:
		axis = Vector2.ZERO
	if axis.length() > 1.0:
		axis = axis.normalized()
	# Isometric movement matches the visible diagonally laid roads.
	var walk := Vector2(axis.x + axis.y * .42, axis.y * .75 - axis.x * .15).normalized()
	if axis.length() > .02:
		player_pos += walk * PLAYER_SPEED * delta
		player_pos.x = clampf(player_pos.x, MAP_LIMIT.position.x + 55, MAP_LIMIT.end.x - 55)
		player_pos.y = clampf(player_pos.y, MAP_LIMIT.position.y + 65, MAP_LIMIT.end.y - 65)
		# The main trunk is a real obstacle, not a walk-through tree picture.
		var tree_offset := player_pos - TREE
		if tree_offset.length() < 70:
			player_pos = TREE + tree_offset.normalized() * 70 if tree_offset.length() > .01 else TREE + Vector2(-70, 0)
		dog_pos = dog_pos.lerp(player_pos + Vector2(-48, 27), clampf(delta * 2.9, 0.0, 1.0))
	camera.position = player_pos
	var sheltered := player_pos.distance_to(OBSERVATION) < 125
	var closed_zone := player_pos.distance_to(TREE) < 115 and story.phase < 3
	story.danger_tick(delta, closed_zone, sheltered, prefs.story_assist)
	if story.phase == 2 and observe_held and not dialogue.visible and sheltered:
		if story.observe_from_safety(delta, true, true):
			observe_held = false
			_show_dialogue("BANTAY",
				"Bantay does not bark. Through the shifting leaves you see the Kapre shielding his home, not chasing the villagers. Observe the smoke and swaying branches before speaking.",
				[{"label": "TABİ-TABI PO — ASK PERMISSION", "action": "greet"}])
			_auto_save()
	if story.encounter_failed and not dialogue.visible and story.outcome == "":
		_show_dialogue("NARRATOR", "The old branches crack above. Bantay pulls you back. The safe route remains available; retry the checkpoint or withdraw.",
			[{"label": "SAFE RETRY", "action": "retry"}, {"label": "WITHDRAW", "action": "retreat"}])
	_update_hint()
	if progress != null:
		progress.visible = story.phase == 2
		progress.value = story.observation * 100.0
	danger.text = "COURAGE %d  •  TENSION %d%%" % [roundi(story.courage), roundi(story.alarm * 100.0)]
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not dialogue.visible:
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
		if key.pressed and not key.echo and key.keycode == KEY_F9:
			# QA-only: camera tour without mutating saved canonical outcome.
			_close_dialogue()
			notebook.hide()
			player_pos = Vector2(90, -80)
			camera.position = player_pos
			print("NIGHT2_QA_MANGO_VIEW")
			get_viewport().set_input_as_handled()

func _draw() -> void:
	# Scene is drawn as 2.5D world-space polygons and detailed imported SVG art.
	# It renders on GLES compatibility and SwiftShader with no spatial shaders.
	draw_rect(Rect2(-1500, -1200, 3000, 2600), Color("#22392f"))
	for i in range(30):
		var y := -820.0 + float(i) * 56.0
		var color := Color("#304a3b").lerp(Color("#557052"), float(i) / 29.0)
		draw_rect(Rect2(-1040, y, 2200, 57), color)
	draw_texture_rect(SOIL, Rect2(-925, -685, 1830, 1390), false, Color(1.0, 1.0, 1.0, .23))
	# Great Flood washout — a continuous diagonal corridor with shallow
	# eroded banks and dried floodwater scars.
	_polygon([Vector2(-910,330),Vector2(810,-590),Vector2(950,-535),Vector2(-760,430)], Color("#5f5a45"))
	_polygon([Vector2(-900,350),Vector2(780,-560),Vector2(860,-510),Vector2(-720,410)], Color("#8b7758"))
	_polygon([Vector2(-900,373),Vector2(785,-540),Vector2(830,-502),Vector2(-720,438)], Color("#aa8d65"))
	for i in range(15):
		var x := -830 + float(i) * 116
		var y := 347 - float(i) * 64
		draw_line(Vector2(x, y), Vector2(x + 48, y - 26), Color(.90,.74,.54,.32), 2.0)
	# The former shelter line marks the re-routed safe path, turning away
	# from the giant tree, rather than a flat danger-zone sticker.
	_polyline([Vector2(-570,520),Vector2(-420,280),Vector2(-440,70),Vector2(-650,-280)], Color("#67785a"), 64)
	_polyline([Vector2(-570,520),Vector2(-420,280),Vector2(-440,70),Vector2(-650,-280)], Color("#b8a37c"), 44)
	for i in range(23):
		var x := -850.0 + float((i * 277) % 1550)
		var y := -580.0 + float((i * 193) % 1170)
		if Vector2(x,y).distance_to(TREE) > 230:
			draw_texture_rect(HIBISCUS, Rect2(x-34, y-41, 74, 62), false, Color("#a1bd94"))
	# A recognizable village refuge, and Mara's school with its own facade.
	_building_at(Vector2(-600, -445), SCHOOL, "MARA • SCHOOL")
	_building_at(Vector2(-610, 410), HOUSE, "SAFE SHELTER")
	# Woven screening at the observation post.
	_polygon([OBSERVATION+Vector2(-105,24), OBSERVATION+Vector2(100,24),
		OBSERVATION+Vector2(105,73), OBSERVATION+Vector2(-105,73)], Color("#685943"))
	for i in range(9):
		var wx := OBSERVATION.x-91 + float(i)*23
		draw_line(Vector2(wx,OBSERVATION.y+23),Vector2(wx,OBSERVATION.y+69),Color("#c5ab74"),3)
	draw_texture_rect(LANTERN,Rect2(OBSERVATION.x-145, OBSERVATION.y-139, 74, 152),false)
	# Unstable ground ring illustrates actual hazard zone before approaching.
	draw_arc(TREE, 128.0, 0, TAU, 65, Color("#d9a16b", .44), 3.0, true)
	# Multi-layered original mango tree and resident Kapre at actual location.
	var canopy_sway := sin(particle_phase * .65) * (4.0 if not prefs.reduced_motion else 0.0)
	draw_texture_rect(MANGO, Rect2(TREE.x-350+canopy_sway,TREE.y-560,700,600), false)
	var kapre_tint := Color("#b4bcb7") if story.phase < 2 else Color.WHITE
	draw_texture_rect(KAPRE, Rect2(TREE.x+83, TREE.y-242, 161, 242),false,kapre_tint)
	# Clue props each have a different silhouette; no generic quest circles.
	_draw_evidence()
	for id in Story.BARRIER_POSITIONS:
		var point: Vector2 = TARGETS[id]
		if story.barriers.has(id):
			draw_texture_rect(BARRIER, Rect2(point-Vector2(38,78), Vector2(76,100)), false)
		else:
			draw_line(point + Vector2(-31,0),point + Vector2(31,0),Color("#e9c280",.65),3)
			draw_arc(point,43,0,TAU,45,Color("#e9c280",.44),2)
	# Paths stay grounded; actors and ambient lights are last.
	draw_texture_rect(DADO, Rect2(-640,-390,78,126), false)
	draw_texture_rect(MARA, Rect2(-525,-385,78,126), false)
	draw_texture_rect(BANTAY, Rect2(dog_pos-Vector2(45,67),Vector2(90,96)),false)
	draw_texture_rect(HERO, Rect2(player_pos-Vector2(46,116),Vector2(92,124)),false)
	_draw_world_labels()
	if story.phase >= 2 or story.outcome != "":
		# Suspense arrives only once the safety route is secured.
		draw_circle(TREE+Vector2(135,-192),35 + sin(particle_phase*1.5)*4.0,Color(1.0,.68,.25,.09))
	if story.outcome == "resolve":
		draw_arc(TREE, 157, 0, TAU, 80, Color("#bcd79d",.58), 3.0)
	elif story.outcome == "partial":
		draw_arc(TREE, 157, 0, TAU, 80, Color("#e2b879",.58), 3.0)

func _polyline(points: Array[Vector2], color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), color, width, true)

func _polygon(points: Array[Vector2], color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _building_at(at: Vector2, texture: Texture2D, name_text: String) -> void:
	var base := Rect2(at-Vector2(115,150),Vector2(230,160))
	draw_colored_polygon(PackedVector2Array([
		at+Vector2(-121,-108),at+Vector2(0,-216),at+Vector2(121,-108),
		at+Vector2(105,-91),at+Vector2(0,-192),at+Vector2(-105,-91)]), Color("#74513a"))
	draw_texture_rect(texture,base,false)
	draw_line(at+Vector2(-104,1),at+Vector2(104,1),Color("#e2c08a"),6)
	# World labels are small and below the buildings, never above residents.
	var font := ThemeDB.fallback_font
	draw_string(font,at+Vector2(-85,32),name_text,HORIZONTAL_ALIGNMENT_LEFT,180,19,Color("#f0dbaa"))

func _draw_evidence() -> void:
	for id in KEY_ORDER:
		var pos: Vector2 = TARGETS[id]
		var done := story.clues.has(id)
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
			draw_arc(pos,64+sin(particle_phase*2)*3,0,TAU,40,Color("#ffd790",.7),2.8)
		elif done:
			draw_circle(pos+Vector2(45,-48),12,Color("#7ba787"))
			draw_line(pos+Vector2(39,-48),pos+Vector2(43,-43),Color.WHITE,3)
			draw_line(pos+Vector2(43,-43),pos+Vector2(52,-57),Color.WHITE,3)

func _draw_world_labels() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font,TREE+Vector2(-173,105),"OLD MANGO • KEEP DISTANCE",HORIZONTAL_ALIGNMENT_LEFT,420,21,Color("#e6d8b2"))
	if story.phase == 2:
		draw_string(font,OBSERVATION+Vector2(-138,100),"SAFE LOOKOUT • HOLD OBSERVE",HORIZONTAL_ALIGNMENT_LEFT,360,19,Color("#ffe1a2"))
	if story.phase >= 1 and story.phase <= 2:
		draw_string(font,Vector2(-440,378),"SHELTER DETOUR",HORIZONTAL_ALIGNMENT_LEFT,240,20,Color("#e5d2a4"))
