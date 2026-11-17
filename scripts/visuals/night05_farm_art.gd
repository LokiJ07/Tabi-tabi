extends RefCounted
## Farm world details share the same painterly 2.5D ground/roof grammar
## as the wake, mango refuge and flood watchpost. No gameplay colliders.
const STYLE_ID := "night05-dimensional-sigbin-farm-v1"
const SOIL := Color("#5c614c")
const RAIL := Color("#9a8566")
const SHADOW := Color("#13242a")
# Actual contiguous enclosure and one animal-sized gap at the prepared gate.
# Animals start INSIDE; the party stays OUTSIDE for safe observation.
# Both yards are OFF the main public path. The animal pen is uphill/north
# of the path, and the safe holding paddock is east of the path terminus.
const PEN := Rect2(286.0,-42.0,375.0,180.0)
const HOLDING := Rect2(690.0,350.0,335.0,150.0)
const MAIN_ROAD_END := Vector2(570.0,318.0)
# Off-road scenery must never occupy either fenced paddock or cover its sign.
const LOWER_TREE := Vector2(270.0,705.0)
const LOWER_BANANA := Vector2(970.0,760.0)
const HOLDING_SIGN_AT := Vector2(430.0,423.0)
const GATE_LEFT := 500.0
const GATE_RIGHT := 610.0

static func main_road_route(start: Vector2, observe: Vector2,
		night06_exit: Vector2) -> PackedVector2Array:
	# The full road continues from Night 4, through the farm, BEYOND the
	# animal-only side spur to Night 6's separately locked threshold.
	# There is no invisible dead end at MAIN_ROAD_END.
	return PackedVector2Array([
		start,Vector2(-730.0,330.0),Vector2(-405.0,338.0),
		observe,MAIN_ROAD_END,
		Vector2(570.0,244.0),Vector2(750.0,244.0),
		Vector2(830.0,55.0),Vector2(900.0,-180.0),
		night06_exit,night06_exit+Vector2(50.0,-210.0)])

static func gate_approach_route() -> PackedVector2Array:
	# A narrow branch, not the public road's destination.
	return PackedVector2Array([Vector2(640.0,244.0),Vector2(555.0,223.0)])

static func keep_player_before_locked_trail(previous: Vector2,
		desired: Vector2, entrance: Vector2, locked: bool) -> Vector2:
	if not locked:
		return desired
	# Don't let the player run beyond the not-yet-streamable Night 6 scene.
	# The road remains fully drawn BEHIND the physical rope checkpoint.
	if absf(desired.x-entrance.x) < 107.0 and desired.y < entrance.y+50.0:
		return Vector2(desired.x,entrance.y+50.0)
	return desired

static func paint_night06_trail_checkpoint(target: CanvasItem,
		entrance: Vector2, locked: bool, night: bool) -> void:
	# Low-profile timber gate. A visible path continues on the far side;
	# only its chapter transition remains disabled until Night 6 exists.
	var wood := Color("#67513d") if night else Color("#8a7053")
	var left := entrance+Vector2(-78.0,26.0)
	var right := entrance+Vector2(78.0,26.0)
	for post in [left,right]:
		target.draw_line(post+Vector2(0,18),post+Vector2(0,-84),wood,10.0,true)
		target.draw_circle(post+Vector2(0,-82),6.0,Color("#c0a878"))
	if locked:
		target.draw_line(left+Vector2(3,-33),right+Vector2(-3,-33),
			Color("#b89456"),5.0,true)
		for i in range(5):
			var at := left.lerp(right,float(i+1)/6.0)+Vector2(0,-33)
			target.draw_circle(at,4.0,Color("#e7c77f"))
	paint_farm_sign(target,
		"NIGHT 6 TRAIL  •  LOCKED" if locked else "NIGHT 6 TRAIL",
		entrance+Vector2(-250.0,-134.0),245.0,night)

static func gate_label(phase: int, prepared: bool) -> String:
	if prepared:
		return "GATE • READY"
	if phase < 2:
		return "GATE • CLOSED"
	return "GATE • PREPARE"

static func animals_revealed(phase: int, debug_preview: bool) -> bool:
	# The herds were reported missing at dawn: showing them in full view
	# before following the clues makes the investigation feel nonsensical.
	return phase >= 2 or debug_preview

static func inside_livestock_pen(point: Vector2) -> bool:
	return PEN.has_point(point)

static func keep_player_outside_pen(previous: Vector2, desired: Vector2) -> Vector2:
	# Kural is a genuine movement boundary, not painted lines the hero walks
	# through. Prefer sliding along a fence rather than sticking on diagonals.
	if not inside_livestock_pen(desired):
		return desired
	if inside_livestock_pen(previous):
		return Vector2(previous.x,PEN.end.y+27.0)
	var along_x := Vector2(desired.x,previous.y)
	if not inside_livestock_pen(along_x):
		return along_x
	var along_y := Vector2(previous.x,desired.y)
	if not inside_livestock_pen(along_y):
		return along_y
	return previous

static func _side_fence(target: CanvasItem, x: float,
		top: float, bottom: float, night: bool) -> void:
	var dark_wood := Color("#594a39") if night else Color("#80654a")
	target.draw_line(Vector2(x-2,top-52),Vector2(x-2,bottom-52),
		dark_wood,7.0,true)
	target.draw_line(Vector2(x-2,top-19),Vector2(x-2,bottom-19),
		dark_wood.darkened(.13),6.0,true)
	for step in range(5):
		var y := lerpf(top,bottom,float(step)/4.0)
		target.draw_line(Vector2(x,y+7),Vector2(x,y-79),
			Color("#524735") if night else Color("#756045"),9.0,true)
		target.draw_circle(Vector2(x,y-76),4.2,Color("#ccb386",.70))

static func paint_livestock_enclosure(target: CanvasItem,
		gate: Vector2, prepared: bool, night: bool) -> void:
	# A real closed rectangle of rails, except the only gap at x=500..610.
	# Light floor shading makes the pen unmistakable on both day and night.
	target.draw_colored_polygon(PackedVector2Array([
		Vector2(PEN.position.x,PEN.position.y),
		Vector2(PEN.end.x,PEN.position.y),
		Vector2(PEN.end.x,PEN.end.y),
		Vector2(PEN.position.x,PEN.end.y)]),
		Color(.38,.30,.18,.13 if night else .16))
	paint_fence(target,Vector2(PEN.position.x,PEN.position.y),
		Vector2(PEN.end.x,PEN.position.y),9,night)
	_side_fence(target,PEN.position.x,PEN.position.y,PEN.end.y,night)
	_side_fence(target,PEN.end.x,PEN.position.y,PEN.end.y,night)
	paint_fence(target,Vector2(PEN.position.x,PEN.end.y),
		Vector2(GATE_LEFT,PEN.end.y),5,night)
	paint_fence(target,Vector2(GATE_RIGHT,PEN.end.y),
		Vector2(PEN.end.x,PEN.end.y),2,night)
	paint_safe_gate(target,gate,prepared)

static func paint_safe_holding_area(target: CanvasItem,
		rescued_count: int, night: bool) -> void:
	# The receiving pen sits EAST of the through-road, not across it.
	# Its WEST entrance at y=212..252 accepts the animals after they exit
	# the first gate; the southern/eastern boundaries are complete rails.
	target.draw_colored_polygon(PackedVector2Array([
		HOLDING.position,Vector2(HOLDING.end.x,HOLDING.position.y),
		HOLDING.end,Vector2(HOLDING.position.x,HOLDING.end.y)]),
		Color(.18,.38,.27,.23 if night else .18))
	paint_fence(target,Vector2(HOLDING.position.x,HOLDING.position.y),
		Vector2(HOLDING.end.x,HOLDING.position.y),7,night)
	paint_fence(target,Vector2(HOLDING.position.x,HOLDING.end.y),
		Vector2(HOLDING.end.x,HOLDING.end.y),7,night)
	_side_fence(target,HOLDING.end.x,HOLDING.position.y,HOLDING.end.y,night)
	# Only the lower west rail remains; the north-west mouth is a real gap.
	_side_fence(target,HOLDING.position.x,HOLDING.position.y+122.0,
		HOLDING.end.y,night)
	for i in range(3):
		var pos := Vector2(750.0+float(i)*113.0,HOLDING.end.y+3.0)
		target.draw_circle(pos,6.0,
			Color(.96,.72,.35,.67 if rescued_count>0 else .24))

static func paint_observation_marker(target: CanvasItem,
		at: Vector2, night: bool) -> void:
	# A recognisable fixed standing point, not a fake UI waypoint.
	var glow := Color(.45,.85,.72,.64) if night else Color(.21,.50,.43,.70)
	for i in range(8):
		var t := TAU*float(i)/8.0
		var p := at+Vector2(cos(t)*60.0,sin(t)*25.0)
		var q := at+Vector2(cos(t+.28)*60.0,sin(t+.28)*25.0)
		target.draw_line(p,q,glow,3.0,true)
	target.draw_circle(at,6.0,glow)

static func paint_farm_sign(target: CanvasItem, text: String,
		at: Vector2, width: float, night: bool) -> void:
	# Drawn in the shared world, so signs never block touch buttons.
	target.draw_rect(Rect2(at,Vector2(width,34)),
		Color("#112b2a",.91) if night else Color("#324036",.91))
	target.draw_rect(Rect2(at,Vector2(width,34)),
		Color("#d0ab6d",.83),false,2.0)
	target.draw_string(ThemeDB.fallback_font,at+Vector2(12,24),
		text,HORIZONTAL_ALIGNMENT_LEFT,width-18,16,
		Color("#f0d6a6"))


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

static func paint_lantern_ground_pool(target: CanvasItem, at: Vector2,
		lit: bool, clock: float, reduced_motion: bool) -> void:
	if not lit:
		return
	# Amber ground reflection layered AFTER blue night grading.
	# Low total alpha keeps clues and footpaths readable on mobile.
	var flicker := 1.0 if reduced_motion else .98+.02*sin(clock*.73+at.x*.01)
	var ground := at+Vector2(0,15)
	target.draw_set_transform(ground,0.0,Vector2(1.0,.43))
	for i in range(4,0,-1):
		target.draw_circle(Vector2.ZERO,32.0+float(i)*35.0,
			Color(1.0,.64,.22,(.006+float(5-i)*.002)*flicker))
	target.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

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

static func route_is_open(index: int, rescued_count: int) -> bool:
	# Existing authoritative rescued_groups drives the light-scene geometry;
	# no animation flag needs to be serialized to the Night 5 save.
	return index >= 0 and index < 3 and index < clampi(rescued_count,0,3)

static func animal_pen_position(index: int) -> Vector2:
	return Vector2(340.0+float(index)*107.0,34.0+float(index%2)*27.0)

static func animal_gate_position(index: int, safe_gate: Vector2) -> Vector2:
	# Safe destinations are fully INSIDE the separate east-side paddock.
	return safe_gate+Vector2(200.0+float(index)*100.0,
		275.0+float(index%2)*28.0)

static func animal_crossing_position(index: int, safe_gate: Vector2,
		rescued: bool, progress: float) -> Vector2:
	var start := animal_pen_position(index)
	if not rescued:
		return start
	var finish := animal_gate_position(index,safe_gate)
	var t := clampf(progress,0.0,1.0)
	if t >= 1.0:
		return finish
	# Both enclosures are real fences. Cross the animal gate first, then
	# enter the receiving yard via its WEST opening — never through a top rail.
	var threshold := safe_gate+Vector2(0,23)
	var receiving_mouth := Vector2(HOLDING.position.x+18.0,
		HOLDING.position.y+45.0)
	if t <= .55:
		var into_gate := smoothstep(0.0,.55,t)
		return start.lerp(threshold,into_gate)+Vector2(0,-10.0*sin(PI*into_gate))
	if t <= .86:
		var into_paddock := smoothstep(.55,.86,t)
		return threshold.lerp(receiving_mouth,into_paddock)
	var reach_slot := smoothstep(.86,1.0,t)
	return receiving_mouth.lerp(finish,reach_slot)

static func paint_shadow_links(target: CanvasItem, nodes: Array,
		idx: int, clock: float, reduced_motion: bool,
		rescued_count: int = 0, lantern_positions: Array = []) -> void:
	if idx < 0 or idx >= nodes.size():
		return
	var pen := Vector2(460,83)
	# Previously resolved pathways stay open in the REAL world after rescue.
	# Current route remains a dark connection until correctly illuminated.
	for i in range(nodes.size()):
		var at: Vector2 = nodes[i]
		if route_is_open(i,rescued_count):
			var source: Vector2 = lantern_positions[i] if i < lantern_positions.size() else at
			var destination := animal_pen_position(i)
			var corridor := PackedVector2Array([
				source,source.lerp(at,.52)+Vector2(0,-24),
				at.lerp(destination,.42),destination])
			target.draw_polyline(corridor,Color(.91,.60,.25,.055),26.0,true)
			target.draw_polyline(corridor,Color(.98,.79,.46,.30),4.0,true)
			target.draw_circle(at,17.0,Color(.97,.75,.38,.08))
			# No new HUD popover or full-screen beam; the cleared route
			# is a muted world-space line visible during next rescue.
		elif i == idx:
			target.draw_polyline(PackedVector2Array([
				at,at.lerp(pen,.32)+Vector2(36,-28),
				at.lerp(pen,.73)+Vector2(-28,23),pen]),
				Color(.05,.10,.15,.32),26,true)
		if not route_is_open(i,rescued_count):
			paint_shadow_node(target,at,i == idx,clock,reduced_motion)

# Related Leyte segben telling mentions squash blossoms; a plausible farm prop,
# not magical proof. The vines sit beside normal crops, not across walkable gates.
static func paint_squash_patch(target: CanvasItem, center: Vector2,
		night: bool) -> void:
	for row in range(3):
		var base := center+Vector2(float(row)*56.0,float(row%2)*33.0)
		var vine := PackedVector2Array([
			base,base+Vector2(25,-11),base+Vector2(47,9),
			base+Vector2(88,-8),base+Vector2(116,5)])
		target.draw_polyline(vine,Color("#385e43") if night else Color("#547b46"),5.5,true)
		for leaf in range(3):
			var at := base+Vector2(20+float(leaf)*37,6+float(leaf%2)*-13)
			target.draw_colored_polygon(PackedVector2Array([
				at+Vector2(-23,0),at+Vector2(-12,-17),
				at+Vector2(1,-19),at+Vector2(15,-9),
				at+Vector2(24,4),at+Vector2(4,14)]),
				Color("#426f49") if night else Color("#638b53"))
			target.draw_line(at+Vector2(-19,-1),at+Vector2(18,4),
				Color("#a2ab68",.42),2.0,true)
		var blossom := base+Vector2(89,-23)
		for petal in range(5):
			var angle := float(petal)*TAU/5.0
			var point := blossom+Vector2(cos(angle),sin(angle))*10.0
			target.draw_circle(point,8.0,
				Color("#d6a851") if night else Color("#eab854"))
		target.draw_circle(blossom,6.0,Color("#986a39"))

# A quiet caretaker keepsake. Do not depict it as objective proof that a
# living person is a sigbinan; local traditions and families must not be accused.
static func paint_caretaker_jar(target: CanvasItem, at: Vector2,
		night: bool) -> void:
	var pottery := Color("#80604b") if night else Color("#ae805f")
	target.draw_colored_polygon(PackedVector2Array([
		at+Vector2(-25,-47),at+Vector2(-32,-37),
		at+Vector2(-29,-9),at+Vector2(-13,4),
		at+Vector2(15,4),at+Vector2(29,-9),
		at+Vector2(31,-37),at+Vector2(24,-47)]),pottery)
	target.draw_line(at+Vector2(-22,-22),at+Vector2(21,-22),
		Color("#d2ad79",.60),4.0,true)
	target.draw_circle(at+Vector2(0,-46),23.0,
		Color("#493a34"))
	target.draw_circle(at+Vector2(0,-46),17.0,
		Color("#987457"))
	target.draw_line(at+Vector2(-17,-15),at+Vector2(17,-15),
		Color("#e0c292",.34),3.0,true)

# Stable world-space soil detailing; deterministic positions, no new colliders.
static func paint_ground_texture(target: CanvasItem, night: bool) -> void:
	for i in range(74):
		var px := -1060.0+fposmod(float(i*227),2080.0)
		var py := -710.0+fposmod(float(i*169),1320.0)
		var at := Vector2(px,py)
		var soil_ink := Color(.21,.27,.20,.27) if night else Color(.34,.39,.27,.26)
		target.draw_circle(at,3.0+float(i%4)*2.0,soil_ink)
		if i%3 == 0:
			var stem := Color(.29,.40,.29,.50) if night else Color(.35,.49,.29,.60)
			target.draw_line(at+Vector2(0,3),at+Vector2(-5,-9),stem,2.0,true)
			target.draw_line(at+Vector2(0,3),at+Vector2(5,-12),stem,2.0,true)
		if i%7 == 0:
			target.draw_line(at+Vector2(-11,3),at+Vector2(13,5),
				Color(.53,.48,.35,.34),2.0,true)

static func paint_barn_ground_shadow(target: CanvasItem,
		origin: Vector2, night: bool) -> void:
	# Broad cast shadow from the raised barn into open soil, never a giant
	# vignette obscuring touch UI or the safe gate.
	var stretch := 280.0 if night else 175.0
	target.draw_colored_polygon(PackedVector2Array([
		origin+Vector2(-250,19),origin+Vector2(204,19),
		origin+Vector2(270+stretch,125),
		origin+Vector2(-90+stretch,167)]),
		Color(.035,.075,.075,.20 if night else .13))
	target.draw_line(origin+Vector2(-250,19),
		origin+Vector2(270+stretch,125),
		Color(.11,.15,.15,.12),3.0,true)
