extends RefCounted
## Farm world details share the same painterly 2.5D ground/roof grammar
## as the wake, mango refuge and flood watchpost. No gameplay colliders.
const STYLE_ID := "night05-dimensional-sigbin-farm-v1"
const SOIL := Color("#5c614c")
const RAIL := Color("#9a8566")
const SHADOW := Color("#13242a")

static func paint_crop_rows(target: CanvasItem, night: bool) -> void:
	for row in range(5):
		var origin := Vector2(-790.0+float(row)*244.0,538.0+float(row%2)*34)
		target.draw_line(origin+Vector2(-30,36),origin+Vector2(181,52),
			Color("#a79166",.23 if night else .46),23.0,true)
		for plant in range(8):
			var at := origin+Vector2(float(plant)*24.0,0.0)
			var color := Color("#567459") if row%2==0 else Color("#6d7e56")
			target.draw_line(at+Vector2(0,25),at+Vector2(-11,-19),color,4.0,true)
			target.draw_line(at+Vector2(0,25),at+Vector2(11,-25),color,4.0,true)
			target.draw_line(at+Vector2(0,20),at+Vector2(3,-33),color,3.0,true)

static func paint_fence(target: CanvasItem, start: Vector2,
		end: Vector2, posts: int, dark: bool) -> void:
	var wood := Color("#685844") if dark else RAIL
	target.draw_line(start+Vector2(0,-57),end+Vector2(0,-57),wood,8.0,true)
	target.draw_line(start+Vector2(0,-22),end+Vector2(0,-22),wood.darkened(.14),7,true)
	for i in range(posts+1):
		var at := start.lerp(end,float(i)/float(maxi(posts,1)))
		target.draw_line(at+Vector2(0,14),at+Vector2(0,-91),
			Color("#574b3b"),10.0,true)
		target.draw_line(at+Vector2(0,-85),at+Vector2(0,-10),
			Color("#c4af89",.31),3,true)
		target.draw_circle(at+Vector2(0,-90),5.0,Color("#b99e73"))

static func paint_safe_gate(target: CanvasItem, center: Vector2, open: bool) -> void:
	var edge := Color("#a59a70") if open else Color("#735c46")
	target.draw_line(center+Vector2(-50,20),center+Vector2(-50,-124),edge,13,true)
	target.draw_line(center+Vector2(54,18),center+Vector2(54,-124),edge,13,true)
	if open:
		target.draw_line(center+Vector2(-45,-84),center+Vector2(-133,-110),edge,9,true)
		target.draw_line(center+Vector2(-44,-49),center+Vector2(-130,-75),edge,9,true)
	else:
		target.draw_line(center+Vector2(-44,-86),center+Vector2(48,-86),edge,11,true)
		target.draw_line(center+Vector2(-44,-48),center+Vector2(48,-48),edge,11,true)

static func paint_tracks(target: CanvasItem, at: Vector2) -> void:
	# Wrong-way impressions tell player the goats were led, not dragged.
	for i in range(5):
		var p := at+Vector2(float(i)*32.0,float(i%2)*13.0)
		target.draw_colored_polygon(PackedVector2Array([
			p+Vector2(-10,-3),p+Vector2(-1,-18),
			p+Vector2(7,-9),p+Vector2(1,9)]),Color("#49463d",.71))
		target.draw_circle(p+Vector2(11,-19),4.0,Color("#695e49",.59))

static func paint_lantern(target: CanvasItem, at: Vector2,
		lit: bool, clock: float, reduced_motion: bool) -> void:
	target.draw_line(at+Vector2(0,26),at+Vector2(0,-74),Color("#69543d"),8.0,true)
	target.draw_line(at+Vector2(-12,-78),at+Vector2(11,-78),Color("#d3b982"),5.0,true)
	target.draw_colored_polygon(PackedVector2Array([
		at+Vector2(-19,-67),at+Vector2(18,-67),
		at+Vector2(14,-35),at+Vector2(-13,-35)]),
		Color("#edc781") if lit else Color("#344247"))
	target.draw_rect(Rect2(at+Vector2(-17,-70),Vector2(34,37)),
		Color("#a68b64"),false,4.0)
	if lit:
		var flicker := 1.0 if reduced_motion else .96+.04*sin(clock*1.2+at.x*.01)
		for i in range(4,0,-1):
			target.draw_circle(at+Vector2(0,-49),float(i)*26.0,
				Color(1.0,.68,.31,.012*flicker))

static func paint_shadow_node(target: CanvasItem, at: Vector2,
		active: bool, seconds: float, reduced_motion: bool) -> void:
	var drift := 0.0 if reduced_motion else sin(seconds*1.24)*12.0
	for i in range(3):
		var widen := float(i)*17.0
		target.draw_colored_polygon(PackedVector2Array([
			at+Vector2(-95-widen,-25),at+Vector2(-22,-43),
			at+Vector2(97+widen+drift,24),at+Vector2(-36,37)]),
			Color(.03,.06,.10,.11 if active else .045))
	# False distant silhouette, obviously tenuous under close observation.
	if active:
		target.draw_circle(at+Vector2(42,-61),12.0,Color(.22,.26,.29,.18))
		target.draw_line(at+Vector2(44,-47),at+Vector2(58,8),
			Color(.17,.23,.26,.18),12.0,true)

static func paint_shadow_links(target: CanvasItem, nodes: Array,
		idx: int, clock: float, reduced_motion: bool) -> void:
	if idx < 0 or idx >= nodes.size():
		return
	var active: Vector2 = nodes[idx]
	var pen := Vector2(460,270)
	# Visible *connected* shadows are essential to the puzzle, not random dark
	# overlays. Lamps cut a specific segment of the path to the animal pens.
	target.draw_polyline(PackedVector2Array([
		active,active.lerp(pen,.32)+Vector2(36,-28),
		active.lerp(pen,.73)+Vector2(-28,23),pen]),
		Color(.05,.10,.15,.30),26,true)
	for i in range(nodes.size()):
		paint_shadow_node(target,nodes[i],i == idx,clock,reduced_motion)
