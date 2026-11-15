extends Control
## A REAL gameplay renderer for GLES3 software adapters whose spatial shader
## cannot link. Physics, AI, dialogue, clues, inventory and save still run in
## the 3D world. This 2.5D CanvasItem draws their live positions using the
## same imported textures as the normal renderer, never a static screenshot.
## This layer is activated ONLY for known Android SwiftShader/Emulator adapters.
const SOIL: Texture2D = preload("res://assets/world/soil_ground.svg")
const PATH: Texture2D = preload("res://assets/world/earthen_path.svg")
const WATER: Texture2D = preload("res://assets/world/tidal_water.svg")
const MANGROVE: Texture2D = preload("res://assets/world/mangrove_illustrated.svg")
const NIPA: Texture2D = preload("res://assets/world/nipa_facade.svg")
const MARKET: Texture2D = preload("res://assets/world/market_facade.svg")
const SCHOOL: Texture2D = preload("res://assets/world/school_facade.svg")
const BANANA: Texture2D = preload("res://assets/world/banana_plant.svg")
const HIBISCUS: Texture2D = preload("res://assets/world/hibiscus_bush.svg")
const LAMP: Texture2D = preload("res://assets/world/lantern_post.svg")
const HERO: Texture2D = preload("res://assets/characters/apprentice.svg")
const BANTAY: Texture2D = preload("res://assets/characters/bantay.svg")
const LOLA: Texture2D = preload("res://assets/characters/lola.svg")
const DADO: Texture2D = preload("res://assets/characters/dado.svg")
const SABEL: Texture2D = preload("res://assets/characters/sabel.svg")
const MARA: Texture2D = preload("res://assets/characters/mara.svg")
const RESIDENT: Texture2D = preload("res://assets/characters/resident.svg")

var game
var camera: Camera3D

static func needs_software_draw(adapter_name: String) -> bool:
	var name := adapter_name.to_lower()
	return name.contains("swiftshader") or name.contains("android emulator opengl es translator")

func bind_game(scene, active_camera: Camera3D) -> void:
	game = scene
	camera = active_camera
	name = "LiveSoftwareWorldDrawing"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(true)

func _process(_dt: float) -> void:
	if camera != null and is_instance_valid(camera) and game != null and is_instance_valid(game):
		queue_redraw()

func _screen(world_at: Vector3) -> Vector2:
	var dimensions: Vector2 = get_viewport().get_visible_rect().size
	var projected: Vector2 = camera.unproject_position(world_at)
	return Vector2(projected.x * size.x / maxf(dimensions.x, 1.0), projected.y * size.y / maxf(dimensions.y, 1.0))

func _scale_units(units: float) -> float:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var ratio := size.y / maxf(viewport_size.y, 1.0)
	return units * viewport_size.y / maxf(camera.size, 1.0) * ratio

func _tint() -> Color:
	return Color("#b2c6cf") if game.is_night else Color.WHITE

func _quad(texture: Texture2D, corners: Array[Vector3], tint: Color, uv_repeat: float = 1.0) -> void:
	var points := PackedVector2Array()
	for v in corners:
		points.append(_screen(v))
	var coords := PackedVector2Array([
		Vector2(0, 0), Vector2(uv_repeat, 0),
		Vector2(uv_repeat, uv_repeat), Vector2(0, uv_repeat)])
	draw_polygon(points, PackedColorArray([tint]), coords, texture)

func _ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#274e4a") if game.is_night else Color("#6e998e"))
	_quad(SOIL, [Vector3(-23, -0.06, -23), Vector3(23, -0.06, -23),
		Vector3(23, -0.06, 23), Vector3(-23, -0.06, 23)], _tint(), 5.0)
	_quad(WATER, [Vector3(-23, 0.06, -23), Vector3(-9.56, 0.06, -23),
		Vector3(-9.56, 0.06, 23), Vector3(-23, 0.06, 23)],
		Color("#8cbfc5") if game.is_night else Color.WHITE, 3.0)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in range(49):
		var z := -22.0 + float(i) * 0.92
		var center := 0.54 * sin(z * 0.2) + 0.23 * sin(z * 0.54)
		var half := 2.5 + 0.24 * sin(z * 0.36 + 1.1)
		pts.append(_screen(Vector3(center - half, 0.08, z)))
		uvs.append(Vector2(0, float(i) / 4.0))
	for i in range(48, -1, -1):
		var z := -22.0 + float(i) * 0.92
		var center := 0.54 * sin(z * 0.2) + 0.23 * sin(z * 0.54)
		var half := 2.5 + 0.24 * sin(z * 0.36 + 1.1)
		pts.append(_screen(Vector3(center + half, 0.08, z)))
		uvs.append(Vector2(1, float(i) / 4.0))
	draw_polygon(pts, PackedColorArray([Color("#cbb99b") if game.is_night else Color.WHITE]), uvs, PATH)

	# The boardwalk extends over a living estuary rather than a featureless box.
	_quad(PATH, [Vector3(-9.0, 0.22, 7.2), Vector3(-5.1, 0.22, 7.2),
		Vector3(-5.1, 0.22, 10.65), Vector3(-9.0, 0.22, 10.65)], Color("#bb9364"), 1.5)
	for i in range(6):
		var z := 7.4 + float(i) * 0.57
		draw_line(_screen(Vector3(-9.0, 0.25, z)), _screen(Vector3(-5.2, 0.25, z)), Color("#6b4d36"), 3)
	for i in range(15):
		var z := -21.0 + float(i) * 3.0
		var post := _screen(Vector3(-9.73, 1.0, z))
		draw_circle(post, maxf(2.0, _scale_units(0.105)), Color("#74553f"))
	for height in [0.62, 0.94]:
		var rope := PackedVector2Array()
		for i in range(32):
			rope.append(_screen(Vector3(-9.73, height, -21.0 + float(i) * 1.4)))
		draw_polyline(rope, Color("#e0bc85"), 2.5, true)

func _art(texture: Texture2D, at: Vector3, width_units: float, bottom_aligned: bool = true, color: Color = Color.WHITE) -> void:
	var world_w := _scale_units(width_units)
	if world_w < 2.0:
		return
	var ratio := float(texture.get_height()) / maxf(float(texture.get_width()), 1.0)
	var height_px := world_w * ratio
	var center := _screen(at)
	var top_left := Vector2(center.x - world_w * .5, center.y - height_px if bottom_aligned else center.y - height_px * .5)
	var rect := Rect2(top_left, Vector2(world_w, height_px))
	# Skip art far outside view: this fallback must still run on old CPUs.
	if not rect.intersects(Rect2(-200, -200, size.x + 400, size.y + 400)):
		return
	draw_texture_rect(texture, rect, false, color)

func _paint_building(at: Vector3, texture: Texture2D, roof: Color) -> void:
	# Raised architecture: front facade, roof silhouette, visible porch.
	var roof_pts := PackedVector2Array([
		_screen(at + Vector3(-2.45, 3.1, -2.22)),
		_screen(at + Vector3(2.45, 3.1, -2.22)),
		_screen(at + Vector3(2.45, 3.1, 2.22)),
		_screen(at + Vector3(-2.45, 3.1, 2.22))])
	draw_colored_polygon(roof_pts, roof)
	draw_polyline(PackedVector2Array([roof_pts[0], roof_pts[1], roof_pts[2], roof_pts[3], roof_pts[0]]), roof.lightened(.28), 3.0)
	_art(texture, at + Vector3(0, 0, 2.28), 3.65, true, _tint())
	var porch := _screen(at + Vector3(0, 0.18, 3.1))
	draw_line(porch + Vector2(-_scale_units(1.7), 0), porch + Vector2(_scale_units(1.7), 0), Color("#c5a47c"), 7)

func _draw_village() -> void:
	_ground()
	var props: Array[Dictionary] = []
	for i in range(8):
		var z: float = [-18.1,-13.1,-4.9,1.7,9.0,16.3,-15.3,20.0][i]
		var x: float = [-19.3,-14.0,-18.7,-14.2,-18.4,-13.9,-11.4,-17.2][i]
		props.append({"at": Vector3(x, 0.03, z), "type": "sprite", "texture": MANGROVE, "width": 4.5})
	for at in [Vector3(14.5, 0, -19.3), Vector3(16.7, 0, -8.5),
		Vector3(14.8, 0, 3.8), Vector3(18.3, 0, 15), Vector3(11.2, 0, 17.9)]:
		props.append({"at": at, "type": "sprite", "texture": BANANA, "width": 4.0})
	for at in [Vector3(9,0,10.8), Vector3(10,0,2.4), Vector3(9.7,0,-4.4),
		Vector3(11.5,0,-12), Vector3(-4.4,0,-16.3), Vector3(-5.9,0,-11),
		Vector3(-6.6,0,4.2), Vector3(-7.8,0,16.5)]:
		props.append({"at": at, "type": "sprite", "texture": HIBISCUS, "width": 1.9})
	for at in [Vector3(-4.0,0,9.0),Vector3(2.8,0,-2.0)]:
		props.append({"at": at, "type": "sprite", "texture": LAMP, "width": 1.5})
	props.append({"at": Vector3(6,0,5), "type": "house", "texture": NIPA, "roof": Color("#76513b")})
	props.append({"at": Vector3(7,0,-8), "type": "house", "texture": MARKET, "roof": Color("#8d6650")})
	props.append({"at": Vector3(-2,0,-12), "type": "house", "texture": SCHOOL, "roof": Color("#4d6b65")})

	for key in ["LOLA", "DADO", "MARA", "SABEL"]:
		var actor = game.interaction_nodes.get(key)
		if actor == null:
			continue
		var tex: Texture2D = LOLA if key == "LOLA" else DADO if key == "DADO" else MARA if key == "MARA" else SABEL
		props.append({"at": actor.global_position, "type": "sprite", "texture": tex, "width": 1.5})
	for walker in game.ambient_walkers:
		if is_instance_valid(walker) and walker.visible:
			props.append({"at": walker.global_position, "type": "sprite", "texture": RESIDENT, "width": 1.45})
	props.append({"at": game.bantay.global_position + Vector3(0, -0.1, 0), "type": "sprite", "texture": BANTAY, "width": 1.72})
	props.append({"at": game.player.global_position + Vector3(0, -0.7, 0), "type": "sprite", "texture": HERO, "width": 1.55})
	# Painter's depth order uses camera distance, not arbitrary list order.
	props.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return camera.global_position.distance_squared_to(a["at"]) > camera.global_position.distance_squared_to(b["at"]))
	for entry in props:
		if entry["type"] == "house":
			_paint_building(entry["at"], entry["texture"], entry["roof"])
		else:
			_art(entry["texture"], entry["at"], entry["width"], true, _tint())

	if game.is_night and game.santelmo != null and is_instance_valid(game.santelmo):
		var light_at := _screen(game.santelmo.global_position)
		draw_circle(light_at, _scale_units(1.15), Color("#57bfc4", .26))
		draw_circle(light_at, _scale_units(.55), Color("#b4e4ec", .64))
		draw_circle(light_at, _scale_units(.19), Color("#f2f4db"))

func _draw_hut() -> void:
	draw_rect(Rect2(Vector2.ZERO,size), Color("#4f5b46"))
	var center := Vector3(55,0,0)
	_quad(SOIL, [center + Vector3(-19, -.4, -17), center + Vector3(19, -.4, -17),
		center + Vector3(19, -.4, 17), center + Vector3(-19, -.4, 17)], Color("#657353"))
	_quad(PATH, [center + Vector3(-4.4, .05, -3.9), center + Vector3(4.4, .05, -3.9),
		center + Vector3(4.4, .05, 3.9), center + Vector3(-4.4, .05, 3.9)], Color("#ad8960"))
	draw_line(_screen(center + Vector3(-4.4, 1.6, -3.9)), _screen(center + Vector3(4.4, 1.6, -3.9)), Color("#634b39"), 15)
	_art(NIPA, center + Vector3(0, 0.2, -3.93), 8.6, true, Color("#b9a183"))
	# Place every interactive prop at its ACTUAL LolaHut GDScript position,
	# so a player using the software renderer can find/inspect prologue items.
	var desk := center + Vector3(-2.65, 0.57, -2.25)
	_quad(PATH, [desk + Vector3(-0.88, 0, -0.49), desk + Vector3(0.88, 0, -0.49),
		desk + Vector3(0.88, 0, 0.49), desk + Vector3(-0.88, 0, 0.49)],
		Color("#ae805b"))
	var journal := PackedVector2Array([
		_screen(center + Vector3(-2.96, 0.79, -2.47)),
		_screen(center + Vector3(-2.32, 0.79, -2.47)),
		_screen(center + Vector3(-2.32, 0.79, -2.02)),
		_screen(center + Vector3(-2.96, 0.79, -2.02))])
	draw_colored_polygon(journal, Color("#205c87"))
	draw_polyline(PackedVector2Array([journal[0],journal[1],journal[2],journal[3],journal[0]]), Color("#a6daea"), 3.0)
	var paper := _screen(center + Vector3(-2.61, 0.82, -2.25))
	draw_circle(paper, maxf(3.0, _scale_units(.12)), Color("#f8e3b9"))
	# Lola's separate breakfast table/cup remain distinct from the writing desk.
	var breakfast := center + Vector3(1.25, 0.52, -0.65)
	_quad(PATH, [breakfast + Vector3(-0.92, 0, -0.57), breakfast + Vector3(0.92, 0, -0.57),
		breakfast + Vector3(0.92, 0, 0.57), breakfast + Vector3(-0.92, 0, 0.57)],
		Color("#76513a"))
	var cup := _screen(center + Vector3(1.45, 0.75, -0.35))
	draw_circle(cup, maxf(4.0, _scale_units(.17)), Color("#f4dba9"))
	draw_circle(cup, maxf(2.0, _scale_units(.085)), Color("#986b45"))
	var frame := _screen(center + Vector3(2.75, 1.67, -3.75))
	draw_rect(Rect2(frame - Vector2(_scale_units(.32), _scale_units(.24)), Vector2(_scale_units(.64),_scale_units(.48))), Color("#b18a5b"))
	draw_rect(Rect2(frame - Vector2(_scale_units(.26), _scale_units(.18)), Vector2(_scale_units(.52),_scale_units(.36))), Color("#4a8585"))
	# A warm woven mat and folded bedding make the room navigable at a glance.
	_quad(PATH, [center + Vector3(-1.5, .06, -.9), center + Vector3(1.5,.06,-.9),
		center + Vector3(1.5,.06,1.1), center + Vector3(-1.5,.06,1.1)], Color("#a96d4f"))
	var sleep_at := center + Vector3(-2.6, .16, 1.0)
	_quad(PATH, [sleep_at + Vector3(-.9,0,-1.22), sleep_at + Vector3(.9,0,-1.22),
		sleep_at + Vector3(.9,0,1.22), sleep_at + Vector3(-.9,0,1.22)], Color("#725e49"))
	_art(LOLA, center + Vector3(-0.35, 0.12, -2.8), 1.6)
	_art(HERO, game.player.global_position + Vector3(0, -0.65, 0), 1.65)
	_art(BANTAY, game.bantay.global_position + Vector3(0, -0.2, 0), 1.62)

func _draw() -> void:
	if game == null or not is_instance_valid(game) or camera == null or not is_instance_valid(camera):
		return
	if game.in_lola_hut:
		_draw_hut()
	else:
		_draw_village()
