extends RefCounted
## Visual-only foreground/midground/background depth details shared by all
## three connected nights. Deterministic shapes: no RNG, resource or save data.
## Use within the current live CanvasItem draw pass, beneath the shared HUD.
const PASS_ID := "nights1-3-landscape-depth-v2"

static func ridge_palette(chapter: int, stage: int) -> Array[Color]:
	var dark := stage >= 2
	if chapter == 2:
		return [Color("#1b3434"),Color("#29443e"),Color("#3c5546")] if dark else [
			Color("#385a51"),Color("#50745e"),Color("#698263")]
	return [Color("#172d38"),Color("#294650"),Color("#38585a")] if dark else [
		Color("#34535d"),Color("#4b6e66"),Color("#678276")]

static func parallax_ridges(target: CanvasItem, world: Rect2,
		camera_point: Vector2, chapter: int, stage: int) -> void:
	# The distant skyline moves slower than the camera. It is not a backdrop
	# image with baked text/UI and does not follow the physical trail geometry.
	var colors := ridge_palette(chapter,stage)
	for layer in range(3):
		var offset := Vector2(camera_point.x * (.13 + float(layer) * .045),
			camera_point.y * (.018 + float(layer) * .010))
		var peak_y := world.position.y + 420.0 + float(layer) * 126.0
		var pts := PackedVector2Array()
		pts.append(Vector2(world.position.x - 400.0 + offset.x,world.position.y - 110.0))
		for i in range(30):
			var x := world.position.x - 350.0 + float(i) * (world.size.x + 700.0) / 29.0
			var contour := sin(float(i) * (.64 + float(layer) * .13) + float(layer) * .7) * (76.0 - float(layer) * 13.0)
			contour += cos(float(i) * 1.81 + float(layer)) * 26.0
			pts.append(Vector2(x + offset.x,peak_y + contour + offset.y))
		pts.append(Vector2(world.end.x + 420.0 + offset.x,world.position.y - 110.0))
		target.draw_colored_polygon(pts,colors[layer])

static func rock(target: CanvasItem, at: Vector2, width: float,
		daylight: bool = true) -> void:
	# Three visible rock faces + a compressed floor shadow make real depth.
	if width < 5.0:
		return
	var shade := Color("#4b534d") if daylight else Color("#303d43")
	var top := Color("#87907c") if daylight else Color("#667276")
	var moss := Color("#708d63") if daylight else Color("#58776d")
	var base := PackedVector2Array([
		at+Vector2(-width*.53,0),at+Vector2(-width*.38,-width*.34),
		at+Vector2(width*.23,-width*.42),at+Vector2(width*.52,-width*.15),
		at+Vector2(width*.52,width*.15),at+Vector2(-width*.33,width*.18)])
	target.draw_circle(at+Vector2(5.0,6.0),width*.52,Color(.025,.04,.045,.19))
	target.draw_colored_polygon(base,shade)
	target.draw_colored_polygon(PackedVector2Array([
		base[1],base[2],base[3],at+Vector2(width*.12,-width*.07),
		at+Vector2(-width*.31,-width*.05)]),top)
	target.draw_line(base[1]+Vector2(2.0,0.0),base[2],moss,2.0,true)

static func reeds(target: CanvasItem, foot: Vector2, height: float,
		wind: float, dark: bool) -> void:
	# Estuary reeds have slender stems, not an inland forest-tree silhouette.
	var stem := Color("#385447") if dark else Color("#556a43")
	var tip := Color("#6f8a65") if dark else Color("#849c66")
	for i in range(6):
		var step := float(i)
		var at := foot+Vector2((step-2.5)*9.0,0.0)
		var reach := height*(.62+float(i%3)*.14)
		var bend := sin(step*1.76+wind)*9.0
		var peak := at+Vector2(bend,-reach)
		target.draw_line(at,peak,stem,2.4,true)
		target.draw_colored_polygon(PackedVector2Array([
			peak,peak+Vector2(-8,-13),peak+Vector2(2,-11)]),tip)
		target.draw_line(at.lerp(peak,.68),at.lerp(peak,.68)+Vector2(-12,-7),
			tip,2.0,true)

static func trail_stones(target: CanvasItem, start: Vector2, finish: Vector2,
		count: int, width: float, dark: bool) -> void:
	# Small fixed edge debris reveals elevation without adding invisible walls
	# or placing artificial quest dots in the center of the safe path.
	var path := finish-start
	var perpendicular := Vector2(-path.y,path.x).normalized()
	for i in range(count):
		var t := (float(i)+.5)/float(count)
		var side := -1.0 if i%2 == 0 else 1.0
		var jitter := sin(float(i)*2.39996)*9.0
		var at := start.lerp(finish,t)+perpendicular*(width*.58+jitter)*side
		rock(target,at,8.0+float(i%4)*3.0,not dark)

static func mist(target: CanvasItem, anchor: Vector2, width: float,
		phase: float, moving: bool, dark: bool) -> void:
	var fade := .022 if dark else .014
	for i in range(7):
		var t := float(i)/6.0
		var drift := sin(phase*.31+float(i)*1.5)*16.0 if moving else 0.0
		var center := anchor+Vector2((t-.5)*width+drift,sin(float(i)*1.87)*13.0)
		target.draw_circle(center,34.0+float(i%3)*10.0,
			Color(.61,.79,.77,fade))
