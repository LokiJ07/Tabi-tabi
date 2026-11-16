extends RefCounted
## Chapter 4's mourners remain indoors after dark; the wake, not wandering
## NPC sprites, communicates a lived-in, protected household.
## Every object is CanvasItem world-space dressing. No collision, HUD or save
## state changes; the mobile compatibility renderer needs no extra shader.
const STYLE_ID := "night04-vigil-dressing-v1"
const CANDLE := Color("#ffcb83")
const WOOD := Color("#78553e")
const FABRIC := Color("#dbd1bc")
const ASH := Color("#3b3737")

static func night_active(stage: int) -> bool:
	return stage >= 2

static func candle_strength(clock: float, reduced_motion: bool) -> float:
	return 1.0 if reduced_motion else (.96+.04*sin(clock*.92))

static func warning_anchor(route: String) -> Vector2:
	match route:
		"roofline": return Vector2(123,-394)
		"rear_window": return Vector2(373,-234)
		"courtyard": return Vector2(242,103)
	return Vector2(123,-394)

static func paint_wake_furniture(target: CanvasItem) -> void:
	# Carefully set to the sides of the original investigation hit zones.
	# Floral tribute on the outer left wall (no grave/horror-gore imagery).
	var stem := Vector2(-187,-110)
	target.draw_line(stem+Vector2(-4,15),stem+Vector2(-4,-65),WOOD,8.0,true)
	for i in range(12):
		var theta := float(i)*TAU/12.0
		var p := stem+Vector2(cos(theta)*34.0,sin(theta)*41.0-79.0)
		target.draw_circle(p,10.0,Color("#587259"))
		target.draw_circle(p+Vector2(cos(theta)*4.0,sin(theta)*3.0),
			5.0,Color("#f2e4c9") if i%3==0 else Color("#cfb089"))
	target.draw_line(stem+Vector2(-20,-25),stem+Vector2(15,-3),
		Color("#c6b594"),4.0,true)
	# Quiet memorial photo table, not a readable or identifying person.
	var table := Vector2(-373,-25)
	target.draw_colored_polygon(PackedVector2Array([
		table+Vector2(-26,5),table+Vector2(49,11),
		table+Vector2(61,27),table+Vector2(-17,21)]),Color("#936f51"))
	target.draw_line(table+Vector2(-16,19),table+Vector2(-16,63),WOOD,8,true)
	target.draw_line(table+Vector2(47,21),table+Vector2(47,69),WOOD,8,true)
	target.draw_rect(Rect2(table+Vector2(-7,-70),Vector2(47,67)),Color("#ae8c68"))
	target.draw_rect(Rect2(table+Vector2(-3,-66),Vector2(39,59)),Color("#c7c2ab"))
	target.draw_circle(table+Vector2(17,-46),10,Color("#766d64"))
	target.draw_colored_polygon(PackedVector2Array([
		table+Vector2(4,-19),table+Vector2(31,-19),
		table+Vector2(36,-8),table+Vector2(-1,-8)]),Color("#716a61"))
	target.draw_line(table+Vector2(-9,-72),table+Vector2(41,-72),Color("#ddbe8a"),4,true)
	# Low woven benches show guests have gathered without leaving NPCs
	# immobile in the street after midnight. Visual-only: path is traversable.
	for b in [Vector2(-512,270),Vector2(476,365)]:
		target.draw_line(b+Vector2(-47,-10),b+Vector2(47,0),WOOD,13.0,true)
		target.draw_line(b+Vector2(-38,-6),b+Vector2(-42,32),Color("#594331"),9.0,true)
		target.draw_line(b+Vector2(35,0),b+Vector2(39,38),Color("#594331"),9.0,true)
		for i in range(5):
			var x := -34.0+float(i)*17.0
			target.draw_line(b+Vector2(x,-13),b+Vector2(x+8,-3),
				Color("#cab18b",.55),2.0,true)
	# Hand-wrapped cloth on the door and a small hanging garland. It moves
	# neither the entry trigger nor the player's obstacle outline.
	var door := Vector2(4,-59)
	target.draw_line(door+Vector2(-46,-188),door+Vector2(71,-183),
		Color("#ac8f67"),4.0,true)
	for i in range(9):
		var x := float(i)*13.5-42.0
		target.draw_line(door+Vector2(x,-187),door+Vector2(x+3,-169),
			FABRIC if i%3==0 else Color("#788b6b"),3.5,true)

static func paint_inner_lights(target: CanvasItem, stage: int,
		clock: float, reduced_motion: bool) -> void:
	if not night_active(stage):
		return
	var pulse := candle_strength(clock,reduced_motion)
	# Front entrance, right below the two lit window panes. This remains
	# glowing while the rear entry is almost black: safe-vs-unsafe readability.
	var threshold := Vector2(8,-137)
	for ring in range(5,0,-1):
		target.draw_circle(threshold,34.0+float(ring)*22.0,
			Color(1,.68,.30,.008*pulse))
	target.draw_colored_polygon(PackedVector2Array([
		Vector2(-28,-38),Vector2(45,-35),Vector2(120,70),
		Vector2(-86,55)]),Color(1,.64,.25,.045*pulse))
	target.draw_line(Vector2(-16,-221),Vector2(-13,-90),
		Color("#f2c68a",.70*pulse),3.0,true)
	# Each vigil flame has a tiny realistic flicker, not a screen-filling
	# pulsing sprite or flashing effect that could trigger discomfort.
	for j in range(3):
		var candle_at := Vector2(-292.0+float(j)*59.0,27.0-float(j)*5.0)
		var v := pulse*(1.0+.02*float(j%2))
		for ring in range(3,0,-1):
			target.draw_circle(candle_at,14.0+float(ring)*12.0,
				Color(1,.67,.24,.016*v))
		target.draw_circle(candle_at,5.0,CANDLE)
	# A low lit window can reveal an anonymous person *indoors*; no external
	# mourner sprite is spawned or used as a clue/accusation.
	var window := Vector2(193,-163)
	target.draw_circle(window+Vector2(14,19),8.0,Color(.24,.18,.15,.32))
	target.draw_line(window+Vector2(14,27),window+Vector2(12,39),
		Color(.24,.18,.15,.27),8.0,true)

static func paint_warning_tell(target: CanvasItem, route: String,
		stage: int, clock: float, tension: float,
		reduced_motion: bool) -> void:
	if stage < 3 or not ["roofline","rear_window","courtyard"].has(route):
		return
	var sway := 0.0 if reduced_motion else sin(clock*1.14)*11.0
	var intensity := .24+clampf(tension,0,1)*.30
	var anchor := warning_anchor(route)
	# Wing shadow is visible before the player chooses a defense. Players
	# observe the SAME actual direction for which the response is intended.
	if route == "roofline":
		var shadow := Color(.02,.025,.045,.12+intensity*.28)
		target.draw_colored_polygon(PackedVector2Array([
			anchor+Vector2(-102+sway,12),anchor+Vector2(-19,-35),
			anchor+Vector2(22,-19),anchor+Vector2(119+sway,36),
			anchor+Vector2(19,12),anchor+Vector2(-15,9)]),shadow)
		for i in range(3):
			var base := anchor+Vector2(-67+float(i)*57,29)
			target.draw_line(base,base+Vector2(27+sway*.15,-13),
				Color(.78,.75,.66,.22+intensity*.17),2.0,true)
	elif route == "rear_window":
		for i in range(4):
			var x := -31.0+float(i)*20.0
			var begin := anchor+Vector2(x+sway*.16,-21)
			target.draw_line(begin,begin+Vector2(18,35),
				Color(.78,.73,.63,.20+intensity*.35),3.0,true)
		target.draw_circle(anchor,59.0,Color(.75,.83,.92,.014+intensity*.02))
	else:
		for i in range(7):
			var h := float(i)*14.0
			var start := anchor+Vector2(-90.0+sway,h-55.0)
			target.draw_line(start,start+Vector2(130.0+float(i%3)*11,-9),
				Color(.59,.73,.67,.14+intensity*.20),2.0,true)
		# Late warning is from the empty courtyard, NOT from inside the
		# funeral home, preventing the narrative from blaming the guests.
		target.draw_circle(anchor+Vector2(20,5),25.0,
			Color(.85,.77,.56,.025+intensity*.04))
