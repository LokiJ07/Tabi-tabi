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
const HUT_FLOOR: Texture2D = preload("res://assets/world/lola_bamboo_floor.svg")
const HUT_WALL: Texture2D = preload("res://assets/world/lola_sawali_wall.svg")
const HUT_BANIG: Texture2D = preload("res://assets/world/lola_banig_mat.svg")

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
	_quad(SOIL, [Vector3(-44, -0.06, -55), Vector3(44, -0.06, -55),
		Vector3(44, -0.06, 35), Vector3(-44, -0.06, 35)], _tint(), 9.0)
	_quad(WATER, [Vector3(-44, 0.06, -43), Vector3(-9.56, 0.06, -43),
		Vector3(-9.56, 0.06, 35), Vector3(-44, 0.06, 35)],
		Color("#8cbfc5") if game.is_night else Color.WHITE, 3.0)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in range(49):
		var z := -38.0 + float(i) * (60.0 / 48.0)
		var center := 0.54 * sin(z * 0.2) + 0.23 * sin(z * 0.54)
		var half := 2.5 + 0.24 * sin(z * 0.36 + 1.1)
		pts.append(_screen(Vector3(center - half, 0.08, z)))
		uvs.append(Vector2(0, float(i) / 4.0))
	for i in range(48, -1, -1):
		var z := -38.0 + float(i) * (60.0 / 48.0)
		var center := 0.54 * sin(z * 0.2) + 0.23 * sin(z * 0.54)
		var half := 2.5 + 0.24 * sin(z * 0.36 + 1.1)
		pts.append(_screen(Vector3(center + half, 0.08, z)))
		uvs.append(Vector2(1, float(i) / 4.0))
	draw_polygon(pts, PackedColorArray([Color("#cbb99b") if game.is_night else Color.WHITE]), uvs, PATH)

	# Mud edge and beach foam match the native three-strip estuary layout.
	# Draw the bank BEFORE the dock and the actors for correct painter order.
	for strip in range(3):
		var shore := PackedVector2Array()
		for i in range(61):
			var z := -38.0 + float(i) * (60.0 / 60.0)
			var center := -10.07 + 0.34 * sin(z * 0.43) + 0.14 * sin(z * 1.16 + 0.7)
			shore.append(_screen(Vector3(center - .78 + float(strip) * .42, .11, z)))
		for i in range(60, -1, -1):
			var z := -38.0 + float(i) * (60.0 / 60.0)
			var center := -10.07 + 0.34 * sin(z * 0.43) + 0.14 * sin(z * 1.16 + 0.7)
			shore.append(_screen(Vector3(center - .24 + float(strip) * .42, .11, z)))
		draw_colored_polygon(shore, [Color("#797760"), Color("#8c7c5c"), Color("#b1a17a")][strip])
	# The old dock stopped short of the water. Now its native and fallback
	# versions both extend over the muddy bank into the brackish river.
	_quad(PATH, [Vector3(-12.05, .28, 7.48), Vector3(-5.05, .28, 7.48),
		Vector3(-5.05, .28, 10.52), Vector3(-12.05, .28, 10.52)], Color("#b39166"), 2.0)
	for i in range(10):
		var x := -11.75 + float(i) * .72
		draw_line(_screen(Vector3(x, .31, 7.5)), _screen(Vector3(x, .31, 10.5)), Color("#634731"), 2.8, true)
	for x in [-11.35, -8.50, -5.88]:
		for z in [7.65, 10.36]:
			draw_line(_screen(Vector3(x, .25, z)), _screen(Vector3(x, -.84, z)), Color("#644e38"), 4.0)
	for z in [7.52, 10.49]:
		draw_line(_screen(Vector3(-12.05, .42, z)), _screen(Vector3(-5.05, .42, z)), Color("#74583b"), 3.5, true)
	_draw_banca()
	for i in range(15):
		var z := -21.0 + float(i) * 3.0
		var post := _screen(Vector3(-9.73, 1.0, z))
		draw_circle(post, maxf(2.0, _scale_units(0.105)), Color("#74553f"))
	for height in [0.62, 0.94]:
		var rope := PackedVector2Array()
		for i in range(32):
			rope.append(_screen(Vector3(-9.73, height, -21.0 + float(i) * 1.4)))
		draw_polyline(rope, Color("#e0bc85"), 2.5, true)

func _draw_banca() -> void:
	# Low-poly craft is projected from the live boat node, never fixed wallpaper.
	if game == null or game.river_boat == null or not is_instance_valid(game.river_boat):
		return
	var p: Vector3 = game.river_boat.global_position
	var hull := PackedVector2Array([
		_screen(p + Vector3(0, .20, -1.78)),
		_screen(p + Vector3(.68, .20, -.95)),
		_screen(p + Vector3(.75, .20, .85)),
		_screen(p + Vector3(0, .20, 1.80)),
		_screen(p + Vector3(-.75, .20, .85)),
		_screen(p + Vector3(-.68, .20, -.95))
	])
	draw_colored_polygon(hull, Color("#715037"))
	draw_polyline(PackedVector2Array([hull[0],hull[1],hull[2],hull[3],hull[4],hull[5],hull[0]]), Color("#e0b783"), 4.0, true)
	for z in [-.90, 0.20, 1.02]:
		draw_line(_screen(p+Vector3(-.60,.25,z)),_screen(p+Vector3(.60,.25,z)),Color("#c6a174"),3.1,true)
	for side in [-1.0,1.0]:
		var x: float = 2.14 * float(side)
		draw_line(_screen(p+Vector3(x,.09,-1.48)),_screen(p+Vector3(x,.09,1.56)),Color("#b39a68"),5.0,true)
		for z in [-.52,.82]:
			draw_line(_screen(p+Vector3(.60*side,.24,z)),_screen(p+Vector3(x,.13,z)),Color("#92744e"),2.4,true)


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
	# Volume-first 2.5D: a REAL gabled nipa house with four spatial wall
	# corners, two pitched roof planes, porch and flush front facade.
	# Old renderer pasted a facade under a flat slab and looked broken.
	var x_left := -1.98
	var x_right := 1.98
	var z_rear := -2.02
	var z_front := 2.02
	var foot := 0.16
	var wall_top := 2.82
	var ridge_top := 3.78
	# Side walls stay behind the roof; front wall gets the attached facade.
	_quad(HUT_WALL, [at + Vector3(x_left,foot,z_rear), at + Vector3(x_left,foot,z_front),
		at + Vector3(x_left,wall_top,z_front), at + Vector3(x_left,wall_top,z_rear)], Color("#947552"))
	_quad(HUT_WALL, [at + Vector3(x_right,foot,z_rear), at + Vector3(x_right,foot,z_front),
		at + Vector3(x_right,wall_top,z_front), at + Vector3(x_right,wall_top,z_rear)], Color("#b89a72"))
	_quad(HUT_WALL, [at + Vector3(x_left,foot,z_front), at + Vector3(x_right,foot,z_front),
		at + Vector3(x_right,wall_top,z_front), at + Vector3(x_left,wall_top,z_front)], Color("#cbb088"))
	# True ridge at x=0 along the depth axis, eaves at x ±2.45.
	_hut_face([at + Vector3(-2.46,2.94,-2.34), at + Vector3(0,ridge_top,-2.34),
		at + Vector3(0,ridge_top,2.35), at + Vector3(-2.46,2.94,2.35)],
		roof.lightened(.11), roof.darkened(.25), 3.2)
	_hut_face([at + Vector3(0,ridge_top,-2.34), at + Vector3(2.46,2.94,-2.34),
		at + Vector3(2.46,2.94,2.35), at + Vector3(0,ridge_top,2.35)],
		roof.darkened(.12), roof.lightened(.25), 3.2)
	_hut_face([at + Vector3(-2.45,2.93,2.34), at + Vector3(0,ridge_top,2.34),
		at + Vector3(2.45,2.93,2.34)], Color("#aa855e"), Color("#5b4435"), 2.5)
	for i in range(5):
		var z := -1.85 + float(i) * .93
		_hut_line(at + Vector3(-2.40,2.97,z), at + Vector3(-.06,ridge_top-.03,z), roof.lightened(.24), 2.0)
		_hut_line(at + Vector3(.08,ridge_top-.04,z), at + Vector3(2.40,2.96,z), roof.darkened(.24), 2.0)
	# Facade texture is grounded in the real wall plane, directly below gable.
	_art(texture, at + Vector3(0, .13, 2.15), 3.90, true, _tint())
	# Small timber porch with individual floorboard seams and short steps.
	_hut_face([at + Vector3(-1.71,.30,2.20), at + Vector3(1.71,.30,2.20),
		at + Vector3(1.71,.30,3.28), at + Vector3(-1.71,.30,3.28)],
		Color("#a88155"), Color("#624830"), 2.5)
	for i in range(7):
		var x := -1.45 + float(i) * .48
		_hut_line(at + Vector3(x,.32,2.23), at + Vector3(x,.32,3.24), Color("#755337"), 1.8)
	for i in range(3):
		_hut_line(at + Vector3(-.82,.26,3.35 + float(i)*.28),
			at + Vector3(.82,.26,3.35 + float(i)*.28), Color("#bd9b6a"), 3.0)

func _draw_village() -> void:
	_ground()
	var props: Array[Dictionary] = []
	for i in range(8):
		var z: float = [-18.1,-13.1,-4.9,1.7,9.0,16.3,-15.3,20.0][i]
		var x: float = [-19.3,-14.0,-18.7,-14.2,-18.4,-13.9,-11.4,-17.2][i]
		props.append({"at": Vector3(x, 0.03, z), "type": "sprite", "texture": MANGROVE, "width": 4.5})
	for i in range(7):
		var far_z := -24.3 - float(i) * 2.13
		props.append({"at": Vector3(-16.5 - float(i % 2) * 3.0, 0, far_z),
			"type": "sprite", "texture": MANGROVE, "width": 4.5})
	for i in range(8):
		var far_z := -23.1 - float(i) * 1.91
		props.append({"at": Vector3(9.0 + float(i % 3) * 2.7, 0, far_z),
			"type": "sprite", "texture": BANANA, "width": 4.0})
	for i in range(7):
		var far_z := -23.5 - float(i) * 1.99
		props.append({"at": Vector3(4.7 + float(i % 3) * .5, 0, far_z),
			"type": "sprite", "texture": HIBISCUS, "width": 1.9})
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

	# Actual North Trail crossing to the Old Mango Grove: same 3D marker
	# positions as the native renderer, and visible in software Android.
	var trail := Vector3(1.0, 0, -32.28)
	for x in [-.65, 2.65]:
		draw_line(_screen(Vector3(x, .04, -32.28)),
			_screen(Vector3(x, 1.87, -32.28)), Color("#805e43"), 6.0, true)
	_hut_face([Vector3(-.82, 1.4, -32.28), Vector3(2.82, 1.4, -32.28),
		Vector3(2.82, 1.98, -32.28), Vector3(-.82, 1.98, -32.28)], Color("#bd9b6a"),
		Color("#674a37"), 3.0)
	var trail_text := _screen(trail + Vector3(-1.55, 1.72, -.03))
	draw_string(ThemeDB.fallback_font, trail_text, "NORTH TRAIL • MANGO TREE",
		HORIZONTAL_ALIGNMENT_LEFT, 250, 15, Color("#2d342e"))
	for i in range(23):
		var z := -15.15 - float(i) * .74
		draw_line(_screen(Vector3(-.4, .12, z)), _screen(Vector3(2.4, .12, z)),
			Color("#c7a579"), 3.0, true)

	if game.is_night:
		# Real Night 1 low-light grade. Earlier software previews barely
		# changed day colors, making Santelmo feel like a daylight orb.
		# This is beneath HUD controls and never changes collision/gameplay.
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.042, 0.098, 0.38))
		# A subtle misted-blue top horizon rather than one flat black screen.
		for i in range(8):
			var band_height := size.y * float(i) / 24.0
			draw_rect(Rect2(0, band_height, size.x, size.y / 30.0),
				Color(0.23, 0.40, 0.52, 0.021))
		# Warm pools of light: exactly the two authored lantern locations.
		for lamp_at in [Vector3(-4.0, 2.05, 9.0), Vector3(2.8, 2.05, -2.0)]:
			var p := _screen(lamp_at)
			var radius := _scale_units(1.75)
			for j in range(6, 0, -1):
				var fraction := float(j) / 6.0
				draw_circle(p, radius * fraction,
					Color(1.0, .68, .30, 0.012 + .006 * (1.0 - fraction)))
			draw_circle(p, maxf(3.5, _scale_units(.11)), Color("#ffe0a0"))
		# The supernatural light sits on top of the dark grade and remains
		# a readable animated threat instead of disappearing into the water.
		if game.santelmo != null and is_instance_valid(game.santelmo):
			var light_at := _screen(game.santelmo.global_position)
			for i in range(8, 0, -1):
				var glow_fraction := float(i) / 8.0
				draw_circle(light_at, _scale_units(1.70) * glow_fraction,
					Color(.30, .80, .93, 0.015 + 0.012 * (1.0 - glow_fraction)))
			draw_circle(light_at, _scale_units(.50), Color("#72b9c4", .31))
			draw_circle(light_at, _scale_units(.17), Color("#f3f5e3"))


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
	# Architectural cutaway: all projected coordinates share the native hut's
	# actual 9x8m footprint. No duplicate imaginary facades or floating roofs.
	var c := Vector3(55.0, 0.0, 0.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color("#183739"))
	_quad(SOIL, [c + Vector3(-18, -.48, -16), c + Vector3(18, -.48, -16),
		c + Vector3(18, -.48, 16), c + Vector3(-18, -.48, 16)], Color("#8fa177"))
	# A garden outside the footprint, never cluttering the playable interior.
	for i in range(4):
		var garden_z := -7.1 + float(i) * 4.6
		_art(HIBISCUS if i % 2 == 0 else BANANA,
			c + Vector3(-8.0 - float(i % 2) * 2.4, -.32, garden_z),
			1.45 if i % 2 == 0 else 3.0, true, Color("#b7c99d"))
	for i in range(6):
		var step_z := 4.75 + float(i) * .99
		_hut_block(c + Vector3(0, -.22, step_z), 1.18, .38, .11, Color("#b59b75"))

	# Raised timber platform and open porch; these are true spatial polygons,
	# not rectangular screen UI stickers pretending to be architecture.
	var nw := c + Vector3(-4.5, -.02, -4.0)
	var ne := c + Vector3(4.5, -.02, -4.0)
	var se := c + Vector3(4.5, -.02, 4.0)
	var sw := c + Vector3(-4.5, -.02, 4.0)
	_hut_face([sw, se, se + Vector3(0, -.53, 0), sw + Vector3(0, -.53, 0)],
		Color("#61432f"), Color("#412e25"), 2.0)
	_hut_face([ne, se, se + Vector3(0, -.53, 0), ne + Vector3(0, -.53, 0)],
		Color("#7c5738"), Color("#412e25"), 2.0)

	# Woven rear walls remain fully visible. The camera-facing +X and +Z walls
	# are intentionally absent, matching the native scene's cutaway meshes.
	_quad(HUT_WALL, [c + Vector3(-4.44, .01, -3.94), c + Vector3(4.44, .01, -3.94),
		c + Vector3(4.44, 3.07, -3.94), c + Vector3(-4.44, 3.07, -3.94)],
		Color("#e0b88a"))
	_quad(HUT_WALL, [c + Vector3(-4.44, .01, 3.91), c + Vector3(-4.44, .01, -3.94),
		c + Vector3(-4.44, 3.07, -3.94), c + Vector3(-4.44, 3.07, 3.91)],
		Color("#ba946c"))
	# Solid raised floor with visible textile surface, not a flat brown fill.
	_quad(HUT_FLOOR, [nw + Vector3(0,.065,0), ne + Vector3(0,.065,0),
		se + Vector3(0,.065,0), sw + Vector3(0,.065,0)], Color.WHITE)
	_hut_line(c + Vector3(-4.42,.10,-3.9), c + Vector3(4.42,.10,-3.9), Color("#684a32"), 3.0)
	_hut_line(c + Vector3(-4.42,.10,3.9), c + Vector3(4.42,.10,3.9), Color("#513a2b"), 4.0)

	# Structural posts, rim joists and pitched gable in one consistent scale.
	for x in [-4.44, 4.44]:
		_hut_line(c + Vector3(x,0,-3.94), c + Vector3(x,3.1,-3.94), Color("#68492f"), 9)
		_hut_line(c + Vector3(x,0,3.93), c + Vector3(x,2.7,3.93), Color("#694c34"), 8)
	_hut_line(c + Vector3(-4.55,3.14,-3.94), c + Vector3(4.55,3.14,-3.94),
		Color("#5c3f2e"), 11)
	_hut_face([c + Vector3(-4.66,3.16,-4.05), c + Vector3(0,4.13,-4.05),
		c + Vector3(4.66,3.16,-4.05)], Color("#835c42"), Color("#d4ae7c"), 3.0)
	for i in range(7):
		var x := -3.68 + float(i) * 1.23
		_hut_line(c + Vector3(x,.04,-3.94), c + Vector3(x,3.07,-3.94),
			Color(1.0,.85,.65,.31), 1.5)

	# One window to the LEFT of the family portrait, avoiding past overlap.
	_hut_face([c + Vector3(-.88,1.45,-3.86), c + Vector3(.79,1.45,-3.86),
		c + Vector3(.79,2.62,-3.86), c + Vector3(-.88,2.62,-3.86)],
		Color("#245d64"), Color("#694a32"), 5.0)
	_hut_line(c + Vector3(-.03,1.47,-3.84), c + Vector3(-.03,2.60,-3.84),
		Color("#dfbd86"), 4.0)
	_hut_line(c + Vector3(-.87,2.03,-3.84), c + Vector3(.79,2.03,-3.84),
		Color("#dfbd86"), 4.0)

	# Original banig weave, modest sleeping mat, and actual room furniture.
	_quad(HUT_BANIG, [c + Vector3(-1.37,.103,-.57), c + Vector3(1.32,.103,-.57),
		c + Vector3(1.32,.103,1.65), c + Vector3(-1.37,.103,1.65)], Color.WHITE)
	_hut_block(c + Vector3(-2.60,.23,1.03), .86, 1.17, .13, Color("#827052"))
	_hut_block(c + Vector3(-2.60,.32,.17), .72, .28, .10, Color("#e5d1aa"))

	# Dedicated writing desk, exactly at BLUE_NOTEBOOK world coordinates.
	for x in [-3.35,-1.95]:
		_hut_line(c + Vector3(x,.08,-2.6), c + Vector3(x,.60,-2.6), Color("#705139"), 5.5)
	_hut_block(c + Vector3(-2.65,.62,-2.25), .91, .52, .16, Color("#926747"))
	_hut_block(c + Vector3(-2.65,.775,-2.25), .35, .25, .08, Color("#285f87"))
	_hut_line(c + Vector3(-2.88,.83,-2.43), c + Vector3(-2.88,.83,-2.05),
		Color("#edd3a4"), 2.3)
	_hut_line(c + Vector3(-2.76,.83,-2.38), c + Vector3(-2.45,.83,-2.38),
		Color("#acd6e2"), 1.6)

	# Distinct breakfast table and pottery, separated from notebook and exit.
	_hut_line(c + Vector3(.58,.10,-.96), c + Vector3(.58,.62,-.96), Color("#674834"), 5)
	_hut_line(c + Vector3(1.93,.10,-.28), c + Vector3(1.93,.62,-.28), Color("#674834"), 5)
	_hut_block(c + Vector3(1.25,.65,-.65), .90,.55,.18, Color("#825a3a"))
	var tea := _screen(c + Vector3(1.45,.85,-.35))
	draw_circle(tea,maxf(4.0,_scale_units(.17)),Color("#efcf8f"))
	draw_circle(tea,maxf(2.0,_scale_units(.075)),Color("#99734d"))

	# Framed family photograph, not intersecting the cutaway window.
	var p := c + Vector3(2.79,1.64,-3.86)
	_hut_face([p + Vector3(-.52,-.41,0),p + Vector3(.52,-.41,0),
		p + Vector3(.52,.41,0),p + Vector3(-.52,.41,0)],
		Color("#aa825a"),Color("#6a482e"),3.0)
	_hut_face([p + Vector3(-.40,-.29,.02),p + Vector3(.40,-.29,.02),
		p + Vector3(.40,.29,.02),p + Vector3(-.40,.29,.02)],
		Color("#3a7778"))
	_hut_line(p+Vector3(-.20,-.15,.04),p+Vector3(.21,.13,.04),Color("#d6c298"),2.0)

	# Small warm practical light, but no bright discs obscuring playable props.
	_art(LAMP,c+Vector3(-3.65,0,2.51),.89,true,Color("#f5d3a4"))
	var glow := _screen(c+Vector3(-3.65,1.2,2.51))
	draw_circle(glow,maxf(5.0,_scale_units(.22)),Color(1.0,.75,.38,.13))
	_hut_block(c+Vector3(0,-.10,4.38),1.35,.55,.15,Color("#ad855b"))
	for i in range(5):
		var x := -.95+float(i)*.48
		_hut_line(c+Vector3(x,-.01,3.90),c+Vector3(x,-.01,4.81),
			Color("#674934"),2.0)

	# Actual actor transforms from the authoritative 3D simulation.
	var elder := game.get_node_or_null("LolaHutInterior/Lola seated") as Node3D
	if elder != null:
		_art(LOLA,elder.global_position+Vector3(0,.02,0),1.84)
	_art(HERO,game.player.global_position+Vector3(0,-.65,0),1.82)
	_art(BANTAY,game.bantay.global_position+Vector3(0,-.20,0),1.78)

func _draw() -> void:
	if game == null or not is_instance_valid(game) or camera == null or not is_instance_valid(camera):
		return
	if game.in_lola_hut:
		_draw_hut()
	else:
		_draw_village()
