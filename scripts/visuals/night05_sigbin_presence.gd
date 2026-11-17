extends RefCounted
## Source-aware Visayan Sigbin visual and sensory behavior.
## World-space drawing only, NO fullscreen static mockup and NO extra colliders.
const STYLE_ID := "night05-visayan-sigbin-presence-v1"

static func backward_foot(anchor: Vector2, seconds: float, route: int,
		reduced_motion: bool) -> Vector2:
	if reduced_motion:
		return anchor
	# The muzzle points right, but the stronger hind legs lead to the LEFT.
	var cycle := seconds*.78+float(route)*1.41
	return anchor+Vector2(-46.0*(.5+.5*sin(cycle)),3.5*sin(cycle*2.0))

static func clap_strength(seconds: float, reduced_motion: bool) -> float:
	if reduced_motion:
		return 0.0
	var cycle := fposmod(seconds,5.8)
	var one := maxf(0.0,1.0-absf(cycle-1.08)/.28)
	var two := maxf(0.0,1.0-absf(cycle-1.29)/.28)
	return maxf(one,two)

static func visibility(stage: int, identified: bool, debug_preview: bool,
		seconds: float) -> float:
	if stage < 2 and not debug_preview:
		return 0.0
	if debug_preview or identified:
		return 1.0
	# Fleeting indistinct shape; it is not a constant opaque enemy.
	return .035+.33*pow(maxf(0.0,sin(seconds*.67+1.7)),6.0)

static func _paint_ear(target: CanvasItem, texture: Texture2D, at: Vector2,
		angle: float, opacity: float, width: float) -> void:
	if texture == null or opacity <= .01:
		return
	target.draw_set_transform(at,angle,Vector2.ONE)
	target.draw_texture_rect(texture,Rect2(-width*.5,-79.0,width,83.0),
		false,Color(1.0,1.0,1.0,opacity))
	target.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

static func paint_clapping_ears(target: CanvasItem, near: Texture2D,
		far: Texture2D, foot: Vector2, seconds: float,
		reduced_motion: bool, opacity: float) -> void:
	var clap := clap_strength(seconds,reduced_motion)
	_paint_ear(target,far,foot+Vector2(59,-91),-.26+clap*.49,opacity*.88,45.0)
	_paint_ear(target,near,foot+Vector2(75,-86),.24-clap*.47,opacity,51.0)

static func paint_reverse_tracks(target: CanvasItem,foot: Vector2, alpha: float) -> void:
	if alpha <= .02:
		return
	# Toes face east, movement is west: readable reversed travel.
	for i in range(4):
		var p := foot+Vector2(15.0-float(i)*28.0,14.0+float(i%2)*6.0)
		var ink := Color(.52,.45,.32,.20*alpha*(1.0-float(i)*.12))
		target.draw_colored_polygon(PackedVector2Array([
			p+Vector2(-11,-4),p+Vector2(4,-8),
			p+Vector2(13,0),p+Vector2(1,8)]),ink)

static func detect_warning(stage: int,distance: float,seconds: float,
		identified: bool) -> String:
	if stage < 2 or distance > 960.0:
		return "FOLLOW WAYPOINT • SAFE FARM ROUTE"
	if identified:
		return "WATCH: THE FIGURE RETREATS BACKWARD • KEEP THE SAFE PERIMETER"
	match int(floor(seconds/4.2))%3:
		0: return "SENSE: SOUR, PUNGENT ODOR FROM THE OLD BARN"
		1: return "LISTEN: TWO DRY EAR-CLAPS BEHIND THE SHUTTER"
		_: return "LOOK: TOES FACE EAST, BUT DUST DRIFTS WEST • BACKWARD TRACKS"
