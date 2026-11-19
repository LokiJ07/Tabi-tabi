extends RefCounted
## Shared 2.5D ground-footprint collision: trees are solid at the trunk,
## buildings at their floors, not across their tall foliage or roof art.
## Night 1 uses physical Godot 3D collision instead.
const FOOT_RADIUS := 17.0
# Water polygons use the exact ground polygons drawn by the chapter artists.
# These aren't decorative borders: all foot movement is swept through them.
# Selected bridges, low boardwalks and marked safe stones are the only routes
# through the water; story state still decides when dangerous crossings open.
const RAVINE_3 := [
	Vector2(-220,740),Vector2(155,740),Vector2(310,-600),
	Vector2(100,-710),Vector2(-40,20)
]
const FLOOD_RIVER_6 := [
	Vector2(-1200,209),Vector2(-785,198),Vector2(-375,216),
	Vector2(60,198),Vector2(310,213),Vector2(530,248),
	Vector2(835,286),Vector2(1340,263),Vector2(1350,835),
	Vector2(-1250,835)
]
const RIVERBANK_6 := [
	Vector2(790,520),Vector2(1110,485),Vector2(1330,550),
	Vector2(1360,820),Vector2(780,830)
]
const HIGH_WATER_7 := [
	Vector2(-1460,565),Vector2(-1040,590),Vector2(-780,705),
	Vector2(-400,805),Vector2(-1460,1070)
]
# The geometry is matched to the visible footpaths/crossings, not entire
# roof images, cliffs or canopy silhouettes. Units are world Canvas pixels.
const RAVINE_CROSSINGS_3 := [
	[Vector2(-165,130),Vector2(110,145),53.0], # marked seven-stone ford
	[Vector2(-170,245),Vector2(126,260),48.0], # lower repaired footbridge
	[Vector2(126,260),Vector2(220,50),46.0],
	[Vector2(-154,-293),Vector2(105,-118),58.0],
	[Vector2(105,-118),Vector2(230,-120),52.0], # high ridge pathway
	[Vector2(-396,-335),Vector2(28,-488),60.0],
	[Vector2(28,-488),Vector2(380,-450),60.0] # old rescue walkway
]
const RIVER_CROSSINGS_6 := [
	[Vector2(185,185),Vector2(270,275),61.0],
	[Vector2(270,275),Vector2(475,363),61.0],
	[Vector2(475,363),Vector2(690,458),61.0],
	[Vector2(488,195),Vector2(488,254),55.0], # preparation platform
	[Vector2(884,354),Vector2(1100,390),58.0] # hill road to Night 7 gate
]

static func _near_marked_crossing(point: Vector2, segments: Array) -> bool:
	for entry in segments:
		var start: Vector2 = entry[0]
		var finish: Vector2 = entry[1]
		var limit: float = float(entry[2])
		var closest := Geometry2D.get_closest_point_to_segment(point,start,finish)
		if point.distance_squared_to(closest) <= limit*limit:
			return true
	return false

static func is_water_blocked(chapter: int, foot: Vector2) -> bool:
	match chapter:
		3:
			return Geometry2D.is_point_in_polygon(foot,PackedVector2Array(RAVINE_3)) \
				and not _near_marked_crossing(foot,RAVINE_CROSSINGS_3)
		6:
			if not Geometry2D.is_point_in_polygon(foot,PackedVector2Array(FLOOD_RIVER_6)):
				return false
			if Geometry2D.is_point_in_polygon(foot,PackedVector2Array(RIVERBANK_6)):
				return false
			return not _near_marked_crossing(foot,RIVER_CROSSINGS_6)
		7:
			return Geometry2D.is_point_in_polygon(foot,PackedVector2Array(HIGH_WATER_7))
	return false


const CIRCLES := {
	2: [[Vector2(245,-120),55.0],[Vector2(-898,178),35.0],[Vector2(-886,582),40.0],
		[Vector2(-595,692),34.0],[Vector2(-286,667),36.0],[Vector2(725,590),38.0],[Vector2(812,-84),36.0]],
	3: [[Vector2(-845,-349),26.0],[Vector2(-755,-530),31.0],[Vector2(-540,-548),23.0],
		[Vector2(-20,-523),27.0],[Vector2(425,-505),32.0],[Vector2(820,-591),29.0],
		[Vector2(875,181),25.0],[Vector2(760,609),32.0],[Vector2(-700,710),27.0],[Vector2(-480,548),23.0]],
	4: [[Vector2(-800,-373),35.0],[Vector2(-850,-113),35.0],[Vector2(-680,-568),35.0],
		[Vector2(690,-483),35.0],[Vector2(800,-118),35.0],[Vector2(812,527),35.0]],
	5: [[Vector2(-950,-415),36.0],[Vector2(-835,-630),36.0],[Vector2(775,-585),38.0],
		[Vector2(670,-490),34.0],[Vector2(-850,-80),25.0],[Vector2(1030,190),25.0]],
	6: [[Vector2(-1020,-245),36.0],[Vector2(-880,-550),36.0],
		[Vector2(1020,-340),36.0],[Vector2(1150,180),36.0],
		[Vector2(-790,-270),22.0],[Vector2(940,-130),22.0]],
	7: [[Vector2(530,-260),85.0],[Vector2(-880,-220),38.0],
		[Vector2(-520,-420),38.0],[Vector2(25,-430),38.0],
		[Vector2(1160,-180),38.0],[Vector2(1010,480),38.0]]
}
# Scene geometry belongs to ground corners. Large roofs/foliage are NOT
# collision areas: only physical walls, supporting posts, and tree roots.
const PROJECTED_HOUSES := {
	4: [[Vector2(-215,-80),Vector2(295,-30),Vector2(405,-320),Vector2(-105,-375)]],
	5: [[Vector2(-912,-256),Vector2(-669,-225),Vector2(-663,-100),Vector2(-912,-132)]]
}
const GROVE_TREES := {
	3: [[Vector2(-845,-349),.95],[Vector2(-755,-530),1.10],
		[Vector2(-540,-548),.75],[Vector2(-20,-523),.88],
		[Vector2(425,-505),1.12],[Vector2(820,-591),.95],
		[Vector2(875,181),.85],[Vector2(760,609),1.08],
		[Vector2(-700,710),.98],[Vector2(-480,548),.78]],
	4: [[Vector2(-800,-400),1.0],[Vector2(-850,-140),1.0],
		[Vector2(-680,-595),1.0],[Vector2(690,-510),1.0],
		[Vector2(800,-145),1.0],[Vector2(812,500),1.0]],
	5: [[Vector2(-950,-445),1.0],[Vector2(-835,-660),1.0],
		[Vector2(775,-615),1.0],[Vector2(670,-520),1.0]],
	6: [[Vector2(-1020,-245),1.0],[Vector2(-880,-550),1.0],
		[Vector2(1020,-340),1.0],[Vector2(1150,180),1.0]],
	7: [[Vector2(-880,-220),1.0],[Vector2(-520,-420),1.0],
		[Vector2(25,-430),1.0],[Vector2(1160,-180),1.0],
		[Vector2(1010,480),1.0]]
}
const BUILDINGS := {
	2: [],
	3: [],
	4: [],
	5: [Rect2(-228,-607,775,520)],
	6: [Rect2(-678,-393,216,86),Rect2(295,-372,166,90),Rect2(-209,-424,170,85)],
	7: []
}

# Night 2's precise base polygons come from _building_at()'s four
# ground corners. A roof extends UP from this ground plane; it is not floor.
const NIGHT2_HOUSE_FOOTPRINTS := [
	[Vector2(-706,-450),Vector2(-524,-408),Vector2(-442,-466),Vector2(-624,-508)],
	[Vector2(-716,405),Vector2(-534,447),Vector2(-452,389),Vector2(-634,347)]
]

static func _point_segment_distance_squared(point: Vector2, a: Vector2, b: Vector2) -> float:
	var edge := b-a
	var amount := clampf((point-a).dot(edge)/maxf(edge.length_squared(),.0001),0.0,1.0)
	return point.distance_squared_to(a+edge*amount)

static func _point_in_footprint(point: Vector2, corners: Array) -> bool:
	if Geometry2D.is_point_in_polygon(point,PackedVector2Array(corners)):
		return true
	for i in range(corners.size()):
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i+1)%corners.size()]
		if _point_segment_distance_squared(point,a,b) < FOOT_RADIUS*FOOT_RADIUS:
			return true
	return false

static func mango_road_centerline() -> Array[Vector2]:
	# The original straight road went through the giant mango's roots,
	# while the drawn canopy made the player look airborne. Curve the
	# physical route around the southern side of the tree instead.
	return [Vector2(-910,330),Vector2(-760,285),Vector2(-570,240),
		Vector2(-350,190),Vector2(-90,120),Vector2(140,80),
		Vector2(405,-65),Vector2(655,-310),Vector2(910,-535)]


static func repair_saved_position(chapter: int, at: Vector2) -> Vector2:
	# Older chapter saves can already contain a ghosted position INSIDE a
	# house or tree. A swept collision cannot get such a player unstuck.
	if not is_blocked(chapter,at):
		return at
	for radius in range(20,720,20):
		for i in range(32):
			var theta := TAU*float(i)/32.0
			var candidate := at+Vector2(cos(theta),sin(theta))*float(radius)
			if not is_blocked(chapter,candidate):
				return candidate
	return at

static func _within_painted_tree(chapter: int, foot: Vector2) -> bool:
	# Foreground tree only hides an actor BEHIND its real trunk.
	for item in GROVE_TREES.get(chapter,[]):
		var trunk: Vector2 = item[0]
		var scale: float = float(item[1])
		if absf(foot.x-trunk.x) < 120.0*scale \
				and foot.y > trunk.y-300.0*scale \
				and foot.y < trunk.y+12.0:
			return true
	return false

static func _within_roof(foot: Vector2, at: Vector2, half_width: float,
		roof_height: float, feet_y: float) -> bool:
	return absf(foot.x-at.x)<half_width \
		and foot.y>at.y-roof_height and foot.y<feet_y

static func scenery_covers_actor(chapter: int, foot: Vector2) -> bool:
	# Occlusion means a grounded actor is BEHIND an illustrated volume.
	# It has NOTHING to do with colliding against the tall leaf canopy.
	if _within_painted_tree(chapter,foot):
		return true
	if chapter == 3:
		return _within_roof(foot,Vector2(-145,-230),183.0,315.0,-235.0)
	if chapter == 4:
		return _within_roof(foot,Vector2(75,-185),360.0,650.0,-80.0)
	if chapter == 5:
		return _within_roof(foot,Vector2(165,-73),375.0,560.0,-95.0) \
			or _within_roof(foot,Vector2(-795,-220),193.0,205.0,-120.0)
	if chapter == 6:
		return _within_roof(foot,Vector2(-580,-301),126.0,320.0,-316.0) \
			or _within_roof(foot,Vector2(379,-278),100.0,230.0,-290.0) \
			or _within_roof(foot,Vector2(-120,-340),100.0,230.0,-352.0)
	if chapter == 7:
		return _within_roof(foot,Vector2(515,-242),340.0,735.0,-265.0)
	if chapter != 2:
		return false
	for at in [Vector2(-600,-445),Vector2(-610,410)]:
		if foot.x > at.x-145.0 and foot.x < at.x+220.0 \
				and foot.y > at.y-310.0 and foot.y < at.y+55.0:
			return true
	# The mango's painter anchor is TREE + (0,40), i.e. (245,-80).
	if foot.x > -120.0 and foot.x < 610.0 and foot.y > -685.0 and foot.y < -68.0:
		return true
	return false

static func is_blocked(chapter: int, foot: Vector2) -> bool:
	if is_water_blocked(chapter,foot):
		return true
	for corners in PROJECTED_HOUSES.get(chapter, []):
		if _point_in_footprint(foot,corners):
			return true
	if chapter == 2:
		for corners in NIGHT2_HOUSE_FOOTPRINTS:
			if _point_in_footprint(foot,corners):
				return true
	for building in BUILDINGS.get(chapter,[]):
		var footprint: Rect2 = building
		if footprint.grow(FOOT_RADIUS).has_point(foot):
			return true
	for item in CIRCLES.get(chapter,[]):
		var center: Vector2 = item[0]
		var radius: float = float(item[1])+FOOT_RADIUS
		if foot.distance_squared_to(center)<radius*radius:
			return true
	return false

static func slide(chapter: int, origin: Vector2, intended: Vector2) -> Vector2:
	var difference := intended-origin
	if difference.length_squared()<0.0001:
		return origin
	# Sweep in short steps to prevent tunneling at low Android frame rates;
	# axis sliding lets players move along a wall instead of teleporting.
	var pieces := clampi(ceili(difference.length()/12.0),1,128)
	var step := difference/float(pieces)
	var foot := origin
	for i in range(pieces):
		var next := foot+step
		if not is_blocked(chapter,next):
			foot = next
			continue
		var horizontal := foot+Vector2(step.x,0)
		var vertical := foot+Vector2(0,step.y)
		if not is_blocked(chapter,horizontal):
			foot = horizontal
		elif not is_blocked(chapter,vertical):
			foot = vertical
	return foot
