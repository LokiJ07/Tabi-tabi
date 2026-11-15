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

## Lola hut: hand-composed cutaway architecture, with all props at real 3D
## interaction positions. Drawn every frame from the real orthographic camera,
## and only on the software-rendered Android fallback.
func _hut_face(corners: Array[Vector3], color: Color, stroke: Color = Color.TRANSPARENT, stroke_width: float = 2.0) -> void:
	var points := PackedVector2Array()
	for point in corners:
		points.append(_screen(point))
	draw_colored_polygon(points, color)
	if stroke.a > 0.0:
		points.append(points[0])
		draw_polyline(points, stroke, stroke_width, true)


func _hut_block(top: Vector3, half_x: float, half_z: float, thickness: float, color: Color) -> void:
	var n := top + Vector3(-half_x, 0, -half_z)
	var e := top + Vector3(half_x, 0, -half_z)
	var s := top + Vector3(half_x, 0, half_z)
	var w := top + Vector3(-half_x, 0, half_z)
	_hut_face([w, s, s - Vector3(0, thickness, 0), w - Vector3(0, thickness, 0)], color.darkened(0.33), Color("#453427"), 2.0)
	_hut_face([e, s, s - Vector3(0, thickness, 0), e - Vector3(0, thickness, 0)], color.darkened(0.18), Color("#4c3625"), 2.0)
	_hut_face([n, e, s, w], color, color.lightened(0.13), 2.0)


func _hut_line(start: Vector3, finish: Vector3, color: Color, weight: float = 2.0) -> void:
	draw_line(_screen(start), _screen(finish), color, weight, true)


func _draw_hut() -> void:
	var c := Vector3(55.0, 0.0, 0.0)
	# Quiet backyard. Unlike the first flat box, vegetation and stepped
	# walkways continue behind the real hut footprint.
	draw_rect(Rect2(Vector2.ZERO, size), Color("#233e32"))
	_quad(SOIL, [c + Vector3(-20, -.46, -17), c + Vector3(20, -.46, -17),
		c + Vector3(20, -.46, 17), c + Vector3(-20, -.46, 17)], Color("#82946c"), 4.0)
	for i in range(9):
		var dx: float = -11.2 + float(i) * 3.0
		var dz: float = -9.0 + float(i % 3) * 5.4
		_art(HIBISCUS if i % 3 == 0 else BANANA,
			c + Vector3(dx, -.24, dz), 1.55 if i % 3 == 0 else 2.9, true,
			Color("#a8b58e"))
	for i in range(8):
		var z: float = 4.7 + float(i) * 1.05
		_hut_block(c + Vector3(0.0, -.21, z), 1.02, .42, .08, Color("#b39a72"))

	# Platform thickness, timber perimeter, and visible bamboo floor.
	var north_left := c + Vector3(-4.5, -.02, -4.0)
	var north_right := c + Vector3(4.5, -.02, -4.0)
	var south_right := c + Vector3(4.5, -.02, 4.0)
	var south_left := c + Vector3(-4.5, -.02, 4.0)
	_hut_face([north_left, north_right, south_right, south_left], Color("#4f392b"), Color("#d6b079"), 4.0)
	_hut_face([south_left, south_right, south_right - Vector3(0, .55, 0), south_left - Vector3(0, .55, 0)],
		Color("#61462f"), Color("#39281f"), 3.0)
	_hut_face([north_right, south_right, south_right - Vector3(0, .55, 0), north_right - Vector3(0, .55, 0)],
		Color("#75543a"), Color("#39281f"), 3.0)
	# Slats are independent alternating bamboo tones with dark seams. This
	# remains readable even if the software adapter cannot sample UVs.
	for i in range(18):
		var z0: float = -3.94 + float(i) * .438
		var z1: float = z0 + .424
		var pigment := Color("#ac8354") if i % 3 == 0 else Color("#bd9766") if i % 3 == 1 else Color("#9d774d")
		_hut_face([c + Vector3(-4.35, .035, z0), c + Vector3(4.35, .035, z0),
			c + Vector3(4.35, .035, z1), c + Vector3(-4.35, .035, z1)], pigment)
		_hut_line(c + Vector3(-4.36, .055, z0), c + Vector3(4.36, .055, z0), Color("#775538"), 1.8)
	for i in range(10):
		var x: float = -4.1 + float(i) * .86
		_hut_line(c + Vector3(x, .065, -3.86), c + Vector3(x, .065, 3.83),
			Color(0.94, 0.79, 0.57, .17), 1.1)

	# CUTAWAY: two textured rear walls, front and camera-side walls omitted
	# entirely so neither Lola nor notebook can disappear behind the facade.
	_hut_face([c + Vector3(-4.48, .04, -3.98), c + Vector3(4.48, .04, -3.98),
		c + Vector3(4.48, 3.06, -3.98), c + Vector3(-4.48, 3.06, -3.98)],
		Color("#bd9666"), Color("#5a422f"), 5.0)
	_hut_face([c + Vector3(-4.48, .04, 3.94), c + Vector3(-4.48, .04, -3.98),
		c + Vector3(-4.48, 3.06, -3.98), c + Vector3(-4.48, 3.06, 3.94)],
		Color("#917047"), Color("#513b2a"), 5.0)
	# Cross-hatched woven sawali pattern on rear walls.
	for i in range(22):
		var x: float = -4.35 + float(i) * .40
		_hut_line(c + Vector3(x, .13, -3.95), c + Vector3(x, 2.97, -3.95),
			Color("#e2bc83") if i % 2 == 0 else Color("#896747"), 1.7)
	for i in range(14):
		var y: float = .15 + float(i) * .202
		_hut_line(c + Vector3(-4.37, y, -3.94), c + Vector3(4.38, y, -3.94),
			Color("#7b593b") if i % 2 == 0 else Color("#e0b780"), 1.35)
	for i in range(13):
		var z: float = -3.66 + float(i) * .58
		_hut_line(c + Vector3(-4.45, .14, z), c + Vector3(-4.45, 2.95, z),
			Color("#d1a977") if i % 2 == 0 else Color("#705037"), 2.0)
	for i in range(13):
		var y: float = .18 + float(i) * .22
		_hut_line(c + Vector3(-4.43, y, -3.88), c + Vector3(-4.43, y, 3.85),
			Color("#6e5138") if i % 2 == 0 else Color("#d1a875"), 1.5)

	# Open-view framed river window in the rear wall (not a covering facade).
	_hut_face([c + Vector3(1.55, 1.43, -3.90), c + Vector3(3.78, 1.43, -3.90),
		c + Vector3(3.78, 2.67, -3.90), c + Vector3(1.55, 2.67, -3.90)], Color("#285e62"), Color("#533b2a"), 5.0)
	_hut_line(c + Vector3(2.665, 1.43, -3.88), c + Vector3(2.665, 2.67, -3.88), Color("#edc692"), 4.0)
	_hut_line(c + Vector3(1.55, 2.06, -3.88), c + Vector3(3.78, 2.06, -3.88), Color("#edc692"), 4.0)
	# A decorative hanging lamp between two visible roof beams.
	_hut_line(c + Vector3(-4.55, 3.15, -4.02), c + Vector3(4.55, 3.15, -4.02), Color("#60452e"), 13)
	_hut_line(c + Vector3(-4.55, 3.27, -4.02), c + Vector3(4.55, 3.27, -4.02), Color("#d2a66e"), 3)
	_hut_line(c + Vector3(-.5, 3.23, -3.78), c + Vector3(-.5, 2.65, -3.78), Color("#674f3b"), 3)
	var lamp_pos := _screen(c + Vector3(-.5, 2.54, -3.79))
	draw_circle(lamp_pos, maxf(5.0, _scale_units(.34)), Color(1.0, .65, .3, .16))
	draw_circle(lamp_pos, maxf(3.0, _scale_units(.15)), Color("#ffdd91"))

	# Woven rug, sleeping mat and blanket. All surfaces sit below feet and
	# are shown with slightly distinct edges instead of floating rectangles.
	_hut_block(c + Vector3(-.1, .10, .55), 1.43, 1.14, .06, Color("#b65f49"))
	for i in range(7):
		var z: float = -.42 + float(i) * .31
		_hut_line(c + Vector3(-1.4,.155,z), c + Vector3(1.25,.155,z),
			Color("#e2aa74") if i % 2 == 0 else Color("#733f39"), 1.5)
	_hut_block(c + Vector3(-2.6, .23, 1.05), .88, 1.18, .13, Color("#77664d"))
	_hut_block(c + Vector3(-2.6, .27, .19), .75, .28, .04, Color("#e6d6b4"))

	# Low writing desk at EXACT authored clue position, with supports/shadows.
	_hut_block(c + Vector3(-3.39, .42, -2.65), .085, .085, .49, Color("#62432d"))
	_hut_block(c + Vector3(-1.92, .42, -2.65), .085, .085, .49, Color("#62432d"))
	_hut_block(c + Vector3(-2.65, .60, -2.25), .875, .48, .14, Color("#765039"))
	for i in range(4):
		var x: float = -3.36 + float(i) * .44
		_hut_line(c + Vector3(x,.69,-2.65), c + Vector3(x,.69,-1.86), Color("#c18a55"), 1.7)
	# Blue notebook is recognizable and precisely overlays BLUE_NOTEBOOK target.
	_hut_block(c + Vector3(-2.65, .775, -2.25), .36, .27, .078, Color("#275982"))
	_hut_line(c + Vector3(-2.89,.79,-2.45), c + Vector3(-2.89,.79,-2.07), Color("#e0c182"), 2.3)
	_hut_line(c + Vector3(-2.77,.79,-2.38), c + Vector3(-2.45,.79,-2.38), Color("#afdaeb"), 1.5)
	var notebook_screen := _screen(c + Vector3(-2.65, .82, -2.25))
	draw_circle(notebook_screen, maxf(5.0, _scale_units(.32)), Color(.35,.75,1.0,.14))

	# Lola's pottery breakfast table and clickable warm cup.
	_hut_block(c + Vector3(.55, .34, -1.02), .085, .085, .4, Color("#523627"))
	_hut_block(c + Vector3(1.95, .34, -.28), .085, .085, .4, Color("#523627"))
	_hut_block(c + Vector3(1.25, .59, -.65), .91, .58, .19, Color("#69462e"))
	_hut_block(c + Vector3(1.45, .78, -.35), .17, .17, .12, Color("#e4bd76"))
	var cup := _screen(c + Vector3(1.45, .86, -.35))
	draw_circle(cup, maxf(2.0, _scale_units(.07)), Color("#916a43"))
	# Framed family photo and a clay jar, placed clear of the playable path.
	var photo := c + Vector3(2.75,1.67,-3.84)
	_hut_face([photo + Vector3(-.58,-.44,0), photo + Vector3(.58,-.44,0),
		photo + Vector3(.58,.44,0), photo + Vector3(-.58,.44,0)], Color("#b18a5c"), Color("#60442c"), 3.0)
	_hut_face([photo + Vector3(-.43,-.32,.015), photo + Vector3(.43,-.32,.015),
		photo + Vector3(.43,.32,.015), photo + Vector3(-.43,.32,.015)], Color("#4e8783"))
	_hut_line(photo + Vector3(-.24,-.17,.03), photo + Vector3(.26,.12,.03), Color("#dfc58d"), 2.0)
	_art(LAMP, c + Vector3(-3.67, -.03, 2.6), .85, true, Color("#ead4a3"))

	# Visible exit threshold and exterior bamboo steps (no opaque front wall).
	_hut_block(c + Vector3(0.0, -.11, 4.42), 1.48, .67, .18, Color("#a17b51"))
	for i in range(6):
		var x: float = -1.32 + float(i) * .51
		_hut_line(c + Vector3(x,-.015,3.93), c + Vector3(x,-.015,4.88), Color("#704d35"), 2.0)

	# Layer characters LAST, in the live physics positions so no furniture
	# accidentally paints over faces. Lola is at (-.35,0,-2.8), not at a
	# made-up location outside her own house.
	_art(LOLA, c + Vector3(-.35, .10, -2.8), 1.87)
	_art(HERO, game.player.global_position + Vector3(0, -.65, 0), 1.83)
	_art(BANTAY, game.bantay.global_position + Vector3(0, -.23, 0), 1.78)


func _draw() -> void:
	if game == null or not is_instance_valid(game) or camera == null or not is_instance_valid(camera):
		return
	if game.in_lola_hut:
		_draw_hut()
	else:
		_draw_village()
