extends RefCounted
## Shared 2.5D ground-footprint collision: trees are solid at the trunk,
## buildings at their floors, not across their tall foliage or roof art.
## Night 1 uses physical Godot 3D collision instead.
const FOOT_RADIUS := 17.0
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
const BUILDINGS := {
	2: [Rect2(-710,-504,260,113),Rect2(-720,347,267,112)],
	3: [],
	4: [Rect2(-185,-365,566,283)],
	5: [Rect2(-228,-607,775,520),Rect2(-925,-289,343,170)],
	6: [Rect2(-678,-393,216,86),Rect2(295,-372,166,90),Rect2(-209,-424,170,85)],
	7: []
}

static func is_blocked(chapter: int, foot: Vector2) -> bool:
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
	var pieces := clampi(ceili(difference.length()/12.0),1,48)
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
