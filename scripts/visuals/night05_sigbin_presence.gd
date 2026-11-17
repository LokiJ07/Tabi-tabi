extends RefCounted
## Regional Visayan Sigbin: world-space motion, no fake screen overlays.
const STYLE_ID := "night05-visayan-sigbin-presence-v2"

static func _ease(t: float) -> float:
	var x := clampf(t,0.0,1.0)
	return x*x*(3.0-2.0*x)

static func retreating(seconds: float, route: int) -> bool:
	return fposmod(seconds+float(route)*1.7,15.0)<8.5

static func ground_anchor(route: int) -> Vector2:
	# Physical contact positions OUTSIDE the unstable barn footprint.
	# Shadow clues may originate at the eave, but the animal crouches below it.
	match clampi(route,0,2):
		0: return Vector2(-135,-52)
		1: return Vector2(520,-64)
		_: return Vector2(473,207)

static func backward_foot(anchor: Vector2, seconds: float, route: int,
		reduced_motion: bool) -> Vector2:
	if reduced_motion:
		return anchor
	# Bounded eight-second backward retreat; slower walk back through cover.
	# Avoid the rapid back-and-forth sliding of the original sprite.
	var cycle := fposmod(seconds+float(route)*1.7,15.0)
	var offset := 148.0*_ease(cycle/8.5) if cycle < 8.5 else 148.0*(1.0-_ease((cycle-8.5)/6.5))
	return anchor+Vector2(-offset,2.2*sin(seconds*4.2))

static func stride(seconds: float, phase: float, reduced_motion: bool) -> float:
	return 0.0 if reduced_motion else sin(seconds*4.2+phase)

static func hoof_lift(seconds: float, phase: float, reduced_motion: bool) -> float:
	return 0.0 if reduced_motion else maxf(0.0,cos(seconds*4.2+phase))*7.0

static func _limb(target: CanvasItem, foot: Vector2, seconds: float,
		hip_local: Vector2, hind: bool, phase: float,
		reduced_motion: bool, opacity: float, behind: bool) -> void:
	var hip := foot+hip_local
	var gait := stride(seconds,phase,reduced_motion)
	var lift := hoof_lift(seconds,phase,reduced_motion)
	var ankle := foot+Vector2(hip_local.x+(11.0 if hind else 2.0)+gait*(8.0 if hind else 6.0),
		-4.0-lift)
	var knee := hip+Vector2((-11.0 if hind else -3.0)+gait*2.2,
		(36.0 if hind else 21.0)-lift*.20)
	var outline := Color(.055,.105,.115,opacity*.97)
	var fur := Color(.13,.22,.21,opacity*.90) if behind else Color(.18,.27,.25,opacity)
	var rim := Color(.32,.40,.33,opacity*(.20 if behind else .28))
	var thigh := 21.0 if hind else 13.0
	var shin := 15.0 if hind else 9.0
	target.draw_line(hip,knee,outline,thigh+5.0,true)
	target.draw_line(knee,ankle,outline,shin+4.0,true)
	target.draw_line(hip,knee,fur,thigh,true)
	target.draw_line(knee,ankle,fur,shin,true)
	target.draw_circle(knee,shin*.54,fur)
	target.draw_line(hip+Vector2(-3,-2),knee+Vector2(-4,-1),rim,2.8,true)
	target.draw_colored_polygon(PackedVector2Array([
		ankle+Vector2(-12,0),ankle+Vector2(7,-3),
		ankle+Vector2(16,4),ankle+Vector2(-12,5)]),
		Color(.12,.17,.16,opacity))
	target.draw_line(ankle+Vector2(7,-2),ankle+Vector2(9,3),
		Color(.48,.49,.41,opacity*.48),1.8,true)

static func paint_limb_pair(target: CanvasItem, foot: Vector2,
		seconds: float, reduced_motion: bool, opacity: float,
		behind: bool) -> void:
	if behind:
		_limb(target,foot,seconds,Vector2(-45,-61),true,PI,
			reduced_motion,opacity*.73,true)
		_limb(target,foot,seconds,Vector2(44,-43),false,0.0,
			reduced_motion,opacity*.70,true)
	else:
		_limb(target,foot,seconds,Vector2(-66,-69),true,0.0,
			reduced_motion,opacity,false)
		_limb(target,foot,seconds,Vector2(62,-47),false,PI,
			reduced_motion,opacity,false)

static func clap_strength(seconds: float, reduced_motion: bool) -> float:
	if reduced_motion:
		return 0.0
	var beat := fposmod(seconds,5.8)
	var a := maxf(0.0,1.0-absf(beat-1.08)/.25)
	var b := maxf(0.0,1.0-absf(beat-1.29)/.25)
	return maxf(a,b)

static func visibility(stage: int, identified: bool, debug_preview: bool,
		seconds: float) -> float:
	if stage < 2 and not debug_preview:
		return 0.0
	if identified or debug_preview:
		return 1.0
	return .035+.33*pow(maxf(0.0,sin(seconds*.67+1.7)),6.0)

static func _ear(target: CanvasItem, texture: Texture2D, at: Vector2,
		angle: float, opacity: float, far: bool) -> void:
	if texture == null or opacity <= .01:
		return
	var width := 72.0 if not far else 66.0
	target.draw_set_transform(at,angle,Vector2.ONE)
	# Broad sideways folds attached at the skull, not rabbit points.
	var x := -width*.88 if far else -width*.12
	target.draw_texture_rect(texture,Rect2(x,-40.0,width,44.0),
		false,Color(1.0,1.0,1.0,opacity))
	target.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

static func paint_clapping_ears(target: CanvasItem, near: Texture2D,
		far: Texture2D, foot: Vector2, seconds: float,
		reduced_motion: bool, opacity: float) -> void:
	var clap := clap_strength(seconds,reduced_motion)
	_ear(target,far,foot+Vector2(46,-91),-.10+clap*.29,opacity*.83,true)
	_ear(target,near,foot+Vector2(68,-85),.08-clap*.34,opacity,false)

static func paint_reverse_tracks(target: CanvasItem,
		foot: Vector2, opacity: float) -> void:
	if opacity <= .02:
		return
	for i in range(4):
		var p := foot+Vector2(14.0-float(i)*30.0,12.0+float(i%2)*7.0)
		target.draw_colored_polygon(PackedVector2Array([
			p+Vector2(-12,-3),p+Vector2(5,-8),
			p+Vector2(14,1),p+Vector2(0,8)]),
			Color(.48,.42,.32,.15*opacity*(1.0-float(i)*.15)))

static func detect_warning(stage: int, distance: float, seconds: float,
		identified: bool) -> String:
	if stage < 2 or distance > 960.0:
		return "FOLLOW WAYPOINT • SAFE FARM ROUTE"
	if identified:
		return "WATCH: THE FIGURE RETREATS BACKWARD • KEEP THE SAFE PERIMETER"
	match int(floor(seconds/4.2))%3:
		0: return "SENSE: SOUR, PUNGENT ODOR FROM THE OLD BARN"
		1: return "LISTEN: TWO DRY EAR-CLAPS BEHIND THE SHUTTER"
		_: return "LOOK: TOES FACE EAST, BUT DUST DRIFTS WEST • BACKWARD TRACKS"
