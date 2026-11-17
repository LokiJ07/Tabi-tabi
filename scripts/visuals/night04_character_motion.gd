extends RefCounted
## Night 4 rigged canvas sprites and smooth entry into the shelter.
## Visual only. No collision, story flags, save schema or HUD changes.
const STYLE_ID := "night04-articulated-wing-and-indoor-transition-v1"
const INDOOR_DURATION := 3.3
const FULL_SIZE := Vector2(300.0, 247.0)
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
	return (1.0 if left else -1.0) * sin(seconds * 2.4) * .19

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
	var bob := 0.0 if reduced_motion else sin(seconds * 2.4) * 3.3
	var top_left := foot - Vector2(dimensions.x * .5, dimensions.y + bob)
	# Transparent wing SVGs are rendered behind an opaque body SVG, with
	# per-wing pivot rotation; no clone nodes or texture reloads each frame.
	_paint_wing(target, left_wing, top_left, dimensions,
		wing_pivot(true, top_left, dimensions),
		wing_angle(true, seconds, reduced_motion), tone)
	_paint_wing(target, right_wing, top_left, dimensions,
		wing_pivot(false, top_left, dimensions),
		wing_angle(false, seconds, reduced_motion), tone)
	target.draw_texture_rect(body, Rect2(top_left, dimensions), false, tone)
