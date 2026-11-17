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

static func _organic_contour(centers: PackedVector2Array, width: float) -> PackedVector2Array:
	# Narrow tapered silhouette instead of two cylindrical lines joined at a
	# sharp corner; both sides share the same smoothly interpolated spine.
	var contour := PackedVector2Array()
	var last: int = centers.size()-1
	for side in range(2):
		for j in range(centers.size()):
			var idx: int = j if side == 0 else last-j
			var t := float(idx)/float(last)
			var prev: Vector2 = centers[maxi(0,idx-1)]
			var next: Vector2 = centers[mini(last,idx+1)]
			var direction := (next-prev).normalized()
			var normal := direction.orthogonal()
			var radius := width*(.80-.43*t)+sin(t*PI)*1.6
			var sign_side := 1.0 if side == 0 else -1.0
			contour.append(centers[idx]+normal*radius*sign_side)
	return contour

static func _limb(target: CanvasItem, foot: Vector2, seconds: float,
		hip_local: Vector2, hind: bool, phase: float,
		reduced_motion: bool, opacity: float, behind: bool) -> void:
	var hip := foot+hip_local
	var gait := stride(seconds,phase,reduced_motion)
	var lift := hoof_lift(seconds,phase,reduced_motion)
	var ankle := foot+Vector2(hip_local.x+(11.0 if hind else 2.0)+gait*(8.0 if hind else 6.0),
		-4.0-lift)
	var knee := hip+Vector2((-18.0 if hind else -7.0)+gait*2.2,
		(36.0 if hind else 21.0)-lift*.20)
	var outline := Color(.055,.105,.115,opacity*.96)
	var fur := Color(.13,.22,.21,opacity*.90) if behind else Color(.18,.27,.25,opacity)
	var rim := Color(.42,.48,.39,opacity*(.20 if behind else .34))
	var width := 11.5 if hind else 7.0
	var centers := PackedVector2Array()
	for k in range(13):
		var t := float(k)/12.0
		var inv := 1.0-t
		centers.append(hip*inv*inv+knee*(2.0*inv*t)+ankle*t*t)
	target.draw_colored_polygon(_organic_contour(centers,width+2.0),outline)
	target.draw_colored_polygon(_organic_contour(centers,width),fur)
	# Moonlit, asymmetrical muscle highlight; only one edge is lit.
	var highlight := PackedVector2Array()
	for k in range(2,11):
		var i := k
		var t := float(i)/12.0
		var before: Vector2 = centers[i-1]
		var after: Vector2 = centers[i+1]
		var normal := (after-before).normalized().orthogonal()
		highlight.append(centers[i]-normal*(width*(.80-.43*t)*.75))
	target.draw_polyline(highlight,rim,2.2,true)
	# Soft cloven toe pads; stepped hooves return to the same soil plane.
	var hoof := PackedVector2Array([
		ankle+Vector2(-9,0),ankle+Vector2(2,-4),
		ankle+Vector2(14,-1),ankle+Vector2(16,4),
		ankle+Vector2(-11,4)])
	target.draw_colored_polygon(hoof,Color(.12,.17,.16,opacity))
	target.draw_line(ankle+Vector2(8,-2),ankle+Vector2(9,3),
		Color(.48,.49,.41,opacity*.36),1.6,true)

static func paint_ground_contact(target: CanvasItem, foot: Vector2,
		seconds: float, reduced_motion: bool, opacity: float) -> void:
	if opacity <= .01:
		return
	# A soft multi-radius contact ellipse holds the animal visually on soil,
	# avoiding the "floating" silhouette in the previous Android capture.
	target.draw_set_transform(foot+Vector2(-16,3),0.0,Vector2(1.38,.23))
	for layer in range(3,0,-1):
		target.draw_circle(Vector2.ZERO,51.0+float(layer)*11.0,
			Color(.01,.04,.04,opacity*.040))
	target.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	if reduced_motion:
		return
	var puff := maxf(0.0,cos(seconds*4.2))
	for d in range(3):
		var p := foot+Vector2(-46+float(d)*26,-2-float(d%2)*3)
		target.draw_circle(p+Vector2(0,-puff*9.0),
			3.0+float(d%2)*2.0,Color(.56,.54,.39,opacity*.13*puff))

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
		return "SIGBIN • BACKWARD RETREAT"
	match int(floor(seconds/4.2))%3:
		0: return "ODOR • NEAR OLD BARN"
		1: return "LISTEN • TWO EAR-CLAPS"
		_: return "TRACKS • BACKWARD STEPS"
