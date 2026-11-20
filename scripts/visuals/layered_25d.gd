extends RefCounted
## One authored 2.5D painting rule for Nights 1 (software), 2 and 3.
## Ground shadows stay at the character's actual feet; sprite relief is
## behind the texture, not an opaque post-process filter over the HUD.
## Only called inside CanvasItem._draw, so it uses no extra viewport/shader.
const STYLE_ID := "shared-2.5d-layered-v1"

static func _oval(target: CanvasItem, center: Vector2, radii: Vector2, ink: Color) -> void:
	var outline := PackedVector2Array()
	for i in range(28):
		var theta := TAU * float(i) / 28.0
		outline.append(center + Vector2(cos(theta) * radii.x, sin(theta) * radii.y))
	target.draw_colored_polygon(outline, ink)

static func paint_contact_shadow(target: CanvasItem, foot: Vector2,
		width: float, shadow: float) -> void:
	if shadow <= 0.0 or width <= 1.0:
		return
	# Two faint, flattened layers sit BELOW the feet rather than a large dark
	# disk visible through a character or a building. Keep local shadows on
	# the ground; they must not read as extra NPC silhouettes.
	_oval(target,foot+Vector2(5.0,5.0),Vector2(width*.32,maxf(2.5,width*.045)),
		Color(.018,.041,.040,shadow*.24))
	_oval(target,foot+Vector2(0.0,2.0),Vector2(width*.23,maxf(2.0,width*.033)),
		Color(.010,.026,.029,shadow*.44))

static func paint_grounded(target: CanvasItem, texture: Texture2D, foot: Vector2,
		dimensions: Vector2, tint: Color = Color.WHITE, shadow: float = .32,
		bob: float = 0.0, draw_shadow: bool = true) -> void:
	if texture == null or dimensions.x <= 1.0 or dimensions.y <= 1.0:
		return
	var w: float = dimensions.x
	var h: float = dimensions.y
	# Diffuse occlusion + compact contact shadow. A floating image no longer
	# pretends to be a solid actor: the light remains attached to its footprint.
	if draw_shadow:
		paint_contact_shadow(target,foot,w,shadow)
	var image_box := Rect2(foot - Vector2(w * .5, h + bob), dimensions)
	# Exactly one bright actor image. A dark duplicate plane previously
	# overlapped heads/eyes and turned daytime NPCs into black silhouettes,
	# especially on Android software rendering. Ground ovals above provide
	# the physical 2.5D contact without tinting a second human body.
	target.draw_texture_rect(texture,image_box,false,tint)

static func paint_animated_actor(target: CanvasItem, texture: Texture2D,
		foot: Vector2, dimensions: Vector2, phase: float, stride: float,
		reduced_motion: bool, tint: Color = Color.WHITE, shadow: float = .32,
		companion: bool = false, draw_shadow: bool = true) -> void:
	# One coherent movement grammar for the stylized 2.5D chapters.
	# Feet maintain contact with their world coordinates; a small squash,
	# counter-step and shadow make the cutout read as walking instead of
	# floating or perpetually bobbing while idle.
	var intensity := clampf(stride,0.0,1.0)
	if reduced_motion:
		intensity = 0.0
	var cycle := sin(phase * (1.13 if companion else 1.0))
	var compression := 1.0 + absf(cycle) * intensity * (.021 if companion else .016)
	var width := dimensions.x * compression
	var height := dimensions.y * (1.0 - .008 * intensity * absf(cycle))
	var horizontal := cycle * intensity * (1.6 if companion else 1.9)
	var rise := absf(cycle) * intensity * (2.6 if companion else 3.0)
	if draw_shadow and intensity > .03:
		# Paired opposing step shadows give movement a grounded leg rhythm,
		# without ever changing hitboxes or putting dark art over the HUD.
		_oval(target,foot+Vector2(-dimensions.x*.095 + cycle*3.0*intensity,4),
			Vector2(dimensions.x*.10,dimensions.x*.027),
			Color(.016,.027,.027,shadow*.20*intensity))
		_oval(target,foot+Vector2(dimensions.x*.095 - cycle*3.0*intensity,4),
			Vector2(dimensions.x*.10,dimensions.x*.027),
			Color(.016,.027,.027,shadow*.20*intensity))
	if intensity < .09:
		paint_grounded(target,texture,foot+Vector2(horizontal,0),
			Vector2(width,height),tint,shadow,rise,draw_shadow)
		return
	# Two independent lower-body slices counter-step while the shoulders
	# follow a softer weight shift. The prior one-piece cutout only bobbed
	# up/down and looked like a static paper puppet while walking. Keep all
	# animated pieces in the SAME ground-foot coordinate system and retain
	# the original authored SVG (no new GPU shader or animation asset).
	if draw_shadow:
		paint_contact_shadow(target,foot,width,shadow)
	var source: Vector2 = texture.get_size()
	if source.x < 2.0 or source.y < 2.0:
		return
	var waist_ratio := .60 if companion else .70
	var upper_h := height*waist_ratio
	var lower_h := height-upper_h
	var image_origin := foot-Vector2(width*.5,height+rise)
	var step := sin(phase * (1.13 if companion else 1.0))*intensity
	var stride_px := (4.2 if companion else 6.2)*step
	var left_lift := maxf(0.0,step)*intensity*(3.0 if companion else 4.5)
	var right_lift := maxf(0.0,-step)*intensity*(3.0 if companion else 4.5)
	var source_upper_h := source.y*waist_ratio
	var half_source_w := source.x*.5
	var half_image_w := width*.5
	var left_source := Rect2(0,source_upper_h,half_source_w,source.y-source_upper_h)
	var right_source := Rect2(half_source_w,source_upper_h,half_source_w,source.y-source_upper_h)
	target.draw_texture_rect_region(texture,
		Rect2(image_origin+Vector2(-stride_px*.44,upper_h-left_lift),
			Vector2(half_image_w+1.0,lower_h+1.0)),left_source,tint)
	target.draw_texture_rect_region(texture,
		Rect2(image_origin+Vector2(half_image_w+stride_px*.44,upper_h-right_lift),
			Vector2(half_image_w+1.0,lower_h+1.0)),right_source,tint)
	var shoulder_sway := sin(phase*.5)*intensity*(1.5 if companion else 2.3)
	target.draw_texture_rect_region(texture,
		Rect2(image_origin+Vector2(horizontal+shoulder_sway,0),
			Vector2(width,upper_h+2.5)),
		Rect2(0,0,source.x,source_upper_h+source.y*.012),tint)


static func paint_living_npc(target: CanvasItem, texture: Texture2D,
		foot: Vector2, dimensions: Vector2, seconds: float,
		reduced_motion: bool, tint: Color = Color.WHITE,
		shadow: float = .30, draw_shadow: bool = true) -> void:
	# NPCs breathe, adjust their stance and turn gently toward the activity.
	# This is intentionally subtle: a stationary witness must not skate
	# around the river or leave the physical interaction marker.
	var shift := 0.0 if reduced_motion else sin(seconds*1.45+foot.x*.031)*1.8
	var breath := 0.0 if reduced_motion else sin(seconds*1.9+foot.y*.017)*.85
	paint_grounded(target,texture,foot+Vector2(shift,0),
		Vector2(dimensions.x*(1.0+breath*.0025),dimensions.y),
		tint,shadow,breath,draw_shadow)


static func lantern(target: CanvasItem, texture: Texture2D, foot: Vector2,
		dimensions: Vector2, lit: bool) -> void:
	paint_grounded(target, texture, foot, dimensions, Color.WHITE, .22)
	if lit:
		var light_at := foot - Vector2(0.0, dimensions.y * .65)
		for i in range(3, 0, -1):
			target.draw_circle(light_at, dimensions.x * (.24 + float(i) * .38),
				Color(1.0, .67, .28, .008 + float(4 - i) * .014))
