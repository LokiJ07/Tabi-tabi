extends RefCounted
## Night 4 rigged canvas sprites and smooth entry into the shelter.
## Visual only. No collision, story flags, save schema or HUD changes.
const STYLE_ID := "night04-articulated-wing-and-indoor-transition-v1"
const INDOOR_DURATION := 3.3
const FULL_SIZE := Vector2(382.0, 314.0)
const LEFT_PIVOT_PX := Vector2(335, 258)
const RIGHT_PIVOT_PX := Vector2(422, 256)
const WAKE_DOOR := Vector2(7, -66)

static func indoor_progress(seconds: float) -> float:
	return clampf(seconds / INDOOR_DURATION, 0.0, 1.0)

static func indoor_alpha(seconds: float) -> float:
	return 1.0 - smoothstep(.73, 1.0, indoor_progress(seconds))

static func indoor_position(role: String, start: Vector2, seconds: float) -> Vector2:
	var amount := smoothstep(0.0, 1.0, indoor_progress(seconds))
	var destination := WAKE_DOOR
	match role:
		"NENA": destination += Vector2(-22, -5)
		"MARA": destination += Vector2(12, 0)
		"SABEL": destination += Vector2(-1, 8)
		_: return start
	return start.lerp(destination, amount)

static func wing_angle(left: bool, seconds: float, reduced_motion: bool) -> float:
	if reduced_motion:
		return 0.0
	# A broad downstroke followed by a slower recover. The opposed hinge
	# directions make a wing-beat rather than two rotating flat cards.
	var cycle: float = seconds * 2.62
	var stroke: float = sin(cycle) * .215 + sin(cycle*2.0+.35)*.024
	return (1.0 if left else -1.0) * stroke

static func wing_pivot(left: bool, top_left: Vector2, dimensions: Vector2) -> Vector2:
	var p: Vector2 = LEFT_PIVOT_PX if left else RIGHT_PIVOT_PX
	return top_left + Vector2(p.x * dimensions.x / 760.0, p.y * dimensions.y / 620.0)

static func _paint_wing(target: CanvasItem, texture: Texture2D, top_left: Vector2,
		dimensions: Vector2, pivot: Vector2, angle: float, tone: Color) -> void:
	if texture == null:
		return
	target.draw_set_transform(pivot, angle, Vector2.ONE)
	target.draw_texture_rect(texture, Rect2(top_left - pivot, dimensions), false, tone)
	target.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func paint_flying(target: CanvasItem, body: Texture2D,
		left_wing: Texture2D, right_wing: Texture2D, foot: Vector2,
		seconds: float, reduced_motion: bool, tone: Color) -> void:
	if body == null or left_wing == null or right_wing == null:
		return
	var dimensions := FULL_SIZE
	var bob := 0.0 if reduced_motion else sin(seconds * 2.62) * 5.0
	var top_left := foot - Vector2(dimensions.x * .5, dimensions.y + bob)
	# Transparent wing SVGs are rendered behind an opaque body SVG, with
	# per-wing pivot rotation; no clone nodes or texture reloads each frame.
	_paint_wing(target, left_wing, top_left, dimensions,
		wing_pivot(true, top_left, dimensions),
		wing_angle(true, seconds, reduced_motion), tone)
	_paint_wing(target, right_wing, top_left, dimensions,
		wing_pivot(false, top_left, dimensions),
		wing_angle(false, seconds, reduced_motion), tone)
	# Torso banks very slightly beneath the wings. Motion is muted rather
	# than slowed indefinitely for accessibility or a paused chapter.
	var bank: float = 0.0 if reduced_motion else sin(seconds*1.31)*.020
	var pivot: Vector2 = top_left+Vector2(dimensions.x*.5,dimensions.y*.45)
	target.draw_set_transform(pivot,bank,Vector2.ONE)
	target.draw_texture_rect(body,Rect2(top_left-pivot,dimensions),false,tone)
	target.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

## Compute a portrait-safe composition in actual Godot canvas pixels.
## The Android window is physically 2340×1080 but the logical camera is
## 1280×720; framing by physical pixels cropped the creature.
static func camera_fit(hero: Vector2, creature_from: Vector2,
		canvas_size: Vector2, look_direction: Vector2 = Vector2.ZERO) -> Dictionary:
	# The creature's rendered foot is 110px below the approach origin.
	# Include 24px for wing flap rotation and 105px below hero for Bantay.
	# Rotating outer wing tips sweep higher than the unrotated image.
	var wing_safety: float = FULL_SIZE.x*.14
	var top_y: float = creature_from.y + 110.0 - FULL_SIZE.y - wing_safety
	var bottom_y: float = hero.y + 105.0
	var span_y: float = maxf(bottom_y-top_y, 1.0)
	var available: float = maxf(250.0,canvas_size.y-170.0)
	var target_zoom: float = clampf(available/span_y,.42,.82)
	var target_center := Vector2(lerpf(hero.x,creature_from.x,.52),
		(top_y+bottom_y)*.5)
	target_center += Vector2(clampf(look_direction.x,-1,1)*20.0,0.0)
	return {"center":target_center,"zoom":target_zoom,
		"top":top_y,"bottom":bottom_y}

## Original low-cost 2.5D aerodynamics. These remain beneath the wing rig
## and never overlap touch HUD or alter the protective interaction zones.
static func paint_flight_air(target: CanvasItem, anchor: Vector2,
		seconds: float, reduced_motion: bool, danger: float) -> void:
	var motion: float = 0.0 if reduced_motion else sin(seconds*2.62)*12.0
	var intensity: float = clampf(danger,0.0,1.0)
	# A split shadow follows the disturbed air over the nipa roof.
	target.draw_colored_polygon(PackedVector2Array([
		anchor+Vector2(-115+motion,-4),
		anchor+Vector2(-29,-42),anchor+Vector2(18,-37),
		anchor+Vector2(120+motion,10),
		anchor+Vector2(26,35),anchor+Vector2(-35,24)]),
		Color(.018,.027,.048,.13+intensity*.09))
	for index in range(4):
		var n: float = float(index)
		var phase: float = seconds*.65+n*.87
		var drift: float = 0.0 if reduced_motion else sin(phase)*14.0
		var from := anchor+Vector2(-118.0+n*21.0+drift,31.0+n*17.0)
		target.draw_arc(from,57.0+n*9.0,PI*1.12,PI*1.82,18,
			Color(.72,.78,.76,.055+intensity*.015),1.5,true)
