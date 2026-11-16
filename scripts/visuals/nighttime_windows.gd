extends RefCounted
## Shared Night 1–4 "lived-in village" nighttime direction.
## Draw warm *interior* light and its exterior spill after the world-darkness
## pass, but below all people, encounters, HUD and dialogue. No fake screenshots,
## extra colliders, network assets, random window blinking or saved timers.
const STYLE_ID := "shared-lived-in-night-v1"
const DARK_PANE := Color("#263941")
const WARM_PANE := Color("#ffc782")
const WARM_GLOW := Color("#ffc168")

static func outdoor_actor_visible(chapter: int, stage: int, role: String) -> bool:
	# Story dialogue and interaction remain available independently of where
	# residents stand. Only the player's party stays out during deep night.
	if role in ["HERO","APPRENTICE","BANTAY","TIKBALANG","KAPRE","MANANANGGAL"]:
		return true
	return stage < 2

static func interior_strength(room: int) -> float:
	# Lived-in homes / wake are brightest, school nearly closed, isolated
	# watchpost small; not every window looks the same at night.
	match room:
		0: return 1.0 # family or shelter
		1: return .78 # wake / busy shop
		2: return .13 # sleeping / closed school
		3: return .59 # flood watchpost
	return .70

static func paint_window(target: CanvasItem, center: Vector2, dimensions: Vector2,
		room: int, night: bool, clock: float, reduced_motion: bool,
		ground_spill: bool = true) -> void:
	if dimensions.x < 4.0 or dimensions.y < 4.0:
		return
	var r := Rect2(center - dimensions * .5, dimensions)
	if not night:
		return # Daylight is authored on the building wall itself.
	var strength := interior_strength(room)
	# Brightness variation never becomes a strobe. Reduced Motion freezes
	# candle micro-flicker and keeps silhouettes legible.
	var flutter := 1.0 if reduced_motion else 0.97 + .03 * sin(clock*.86 + float(room)*1.71)
	var light := strength*flutter
	if light > .20:
		for i in range(4,0,-1):
			var radius := dimensions.x*(.67+float(i)*.33)
			target.draw_circle(center, radius,
				Color(1.0,.62,.24, (.013+float(5-i)*.006)*light))
	# The dark outer lintel stays dimensional, even when the room is lit.
	target.draw_rect(r.grow(4.0),Color("#332f2e"))
	var fill := DARK_PANE.lerp(WARM_PANE,clampf(light*.93,0.0,1.0))
	target.draw_rect(r,fill)
	# Shutters and curtains are INSIDE the window; silhouettes indicate
	# awake residents indoors without re-spawning idle NPCs in the street.
	var curtain := Color("#534944",.84)
	target.draw_rect(Rect2(r.position,Vector2(dimensions.x*.12,dimensions.y)),curtain)
	target.draw_rect(Rect2(Vector2(r.end.x-dimensions.x*.12,r.position.y),
		Vector2(dimensions.x*.12,dimensions.y)),curtain)
	if room in [0,1] and light > .3:
		var silhouette := Color("#413731",.51)
		target.draw_circle(center+Vector2(dimensions.x*.19,dimensions.y*.08),
			dimensions.y*.115,silhouette)
		target.draw_rect(Rect2(center+Vector2(dimensions.x*.12,dimensions.y*.19),
			Vector2(dimensions.x*.15,dimensions.y*.24)),silhouette)
	target.draw_line(Vector2(center.x,r.position.y),Vector2(center.x,r.end.y),
		Color("#795e4b"),maxf(2,dimensions.x*.055),true)
	target.draw_line(Vector2(r.position.x,center.y),Vector2(r.end.x,center.y),
		Color("#9e7958"),maxf(2,dimensions.y*.055),true)
	target.draw_rect(r,Color("#705841"),false,maxf(2,dimensions.x*.05))
	if ground_spill and light > .20:
		# Low-alpha wedge of reflected amber on earth, not an opaque
		# yellow gameplay rectangle covering evidence, footpaths or controls.
		var near := Vector2(center.x, r.end.y + 13.0)
		target.draw_colored_polygon(PackedVector2Array([
			Vector2(r.position.x+dimensions.x*.13,r.end.y),
			Vector2(r.end.x-dimensions.x*.13,r.end.y),
			near+Vector2(dimensions.x*.98,dimensions.y*.64),
			near+Vector2(-dimensions.x*.98,dimensions.y*.64)]),
			Color(1.0,.64,.27,.027*light))

static func sync_barrio_3d(world: Node3D, night: bool,
		clock: float, reduced_motion: bool) -> void:
	# Night 1 native (non-software) path uses actual window meshes and
	# two tiny unshadowed OmniLight3D spills at the original 3D house positions.
	# Do not create frame-by-frame nodes or duplicate the existing geometry.
	var root := world.get_node_or_null("BarrioEnvironmentDetails") as Node3D
	if root == null:
		return
	var names := ["Lola woven home","Sabel riverside store","Mara schoolhouse"]
	for i in range(names.size()):
		var building := root.get_node_or_null(names[i]) as Node3D
		if building == null:
			continue
		var pane := building.get_node_or_null("Dark window") as MeshInstance3D
		if pane == null:
			continue
		var strength := interior_strength(i)
		var amount := strength * (1.0 if reduced_motion else .98+.02*sin(clock*.86+float(i)))
		var material := pane.material_override as StandardMaterial3D
		if material == null:
			material = StandardMaterial3D.new()
			pane.material_override = material
		material.albedo_color = DARK_PANE.lerp(WARM_PANE,
			amount*.88 if night else 0.0)
		material.emission_enabled = night and strength > .25
		if material.emission_enabled:
			material.emission = WARM_GLOW
			material.emission_energy_multiplier = 1.35*amount
		var halo := building.get_node_or_null("NightWindowAmberSpill") as OmniLight3D
		if halo == null and i < 2:
			halo = OmniLight3D.new()
			halo.name = "NightWindowAmberSpill"
			halo.position = Vector3(1.20,1.45,2.62)
			halo.light_color = WARM_GLOW
			halo.omni_range = 3.4
			halo.shadow_enabled = false
			building.add_child(halo)
		if halo != null:
			halo.visible = night
			halo.light_energy = .45*amount if night else 0.0
