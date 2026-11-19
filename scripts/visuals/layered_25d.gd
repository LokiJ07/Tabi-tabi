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
	_oval(target,foot+Vector2(7.0,5.0),Vector2(width*.33,maxf(3.0,width*.055)),
		Color(.017,.031,.032,shadow*.33))
	_oval(target,foot+Vector2(0.0,2.0),Vector2(width*.25,maxf(2.0,width*.040)),
		Color(.012,.019,.023,shadow*.58))

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
	# A short offset second silhouette establishes readable side thickness,
	# without duplicate visible faces, translucent ghosting or huge draw cost.
	var relief := Vector2(clampf(w * .030, 2.0, 7.0), -clampf(h * .014, 2.0, 7.0))
	target.draw_texture_rect(texture, Rect2(image_box.position + relief, dimensions),
		false, Color(.035, .077, .092, .61 * tint.a))
	target.draw_texture_rect(texture, image_box, false, tint)

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
	paint_grounded(target,texture,foot+Vector2(horizontal,0),
		Vector2(width,height),tint,shadow,rise,draw_shadow)


static func lantern(target: CanvasItem, texture: Texture2D, foot: Vector2,
		dimensions: Vector2, lit: bool) -> void:
	paint_grounded(target, texture, foot, dimensions, Color.WHITE, .22)
	if lit:
		var light_at := foot - Vector2(0.0, dimensions.y * .65)
		for i in range(3, 0, -1):
			target.draw_circle(light_at, dimensions.x * (.24 + float(i) * .38),
				Color(1.0, .67, .28, .008 + float(4 - i) * .014))
