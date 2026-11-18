extends RefCounted
## Postgame living Barrio Lawom: one persistent clock, actual daily jobs.
## Visual-only; never moves story witnesses, changes investigation collision,
## duplicates chapter rewards, or blocks the continuous public road.
const Folk = preload("res://scripts/visuals/folk_actors.gd")
const Banca = preload("res://scripts/world/river_banca.gd")
const FISHER: Texture2D = preload("res://assets/characters/post_fisher.svg")
const MARKET: Texture2D = preload("res://assets/characters/post_market.svg")
const TRAIL: Texture2D = preload("res://assets/characters/post_trail.svg")
const RootName := "PostgameBarrioLife"
const SETTLEMENT_ACTORS := [
	{"id":"dock_fisher","home":Vector3(4.6,0,-2.4),"work":Vector3(-6.3,0.1,10.2),"rest":Vector3(-5.5,0,-1.0),"shirt":Color("#4a8690")},
	{"id":"market_vendor","home":Vector3(9.0,0,-9.5),"work":Vector3(11.3,0,-5.9),"rest":Vector3(9.9,0,-6.7),"shirt":Color("#9b6f72")},
	{"id":"garden_farmer","home":Vector3(12.8,0,6.7),"work":Vector3(11.0,0,2.8),"rest":Vector3(9.0,0,1.4),"shirt":Color("#648269")},
	{"id":"trail_caretaker","home":Vector3(-2.6,0,-10.0),"work":Vector3(3.5,0,-20.5),"rest":Vector3(2.1,0,-16.4),"shirt":Color("#b6a17b")}
]

static func ensure(world: Node3D) -> Node3D:
	var existing := world.get_node_or_null(RootName) as Node3D
	if existing != null:
		return existing
	var root := Node3D.new()
	root.name = RootName
	root.set_meta("visual_only", true)
	world.add_child(root)
	# Fishing gear and returned livelihood are anchored to the actual existing dock.
	_box(root,"Drying rack rail",Vector3(-7.7,.93,11.25),Vector3(2.4,.11,.11),Color("#c29f71"))
	for i in range(4):
		_box(root,"Fish net hemp top %d" % i,Vector3(-8.8+float(i)*.67,.78,11.28),
			Vector3(.055,.46,.08),Color("#d3c59b"))
	for i in range(3):
		_box(root,"Dock creel basket %d" % i,Vector3(-6.4+float(i)*.5,.17,11.9),
			Vector3(.37,.32,.41),Color("#ab8c60"))
	# A little stall is open in the morning and closed at night, not a ghost booth.
	_box(root,"Market table",Vector3(12.1,.65,-7.3),
		Vector3(2.35,.13,1.05),Color("#936d4b"))
	for x in [-.9,.9]:
		_box(root,"Market wooden leg",Vector3(12.1+x,.34,-7.3),
			Vector3(.10,.65,.10),Color("#735339"))
	for i in range(5):
		var crop := MeshInstance3D.new()
		crop.name = "Market crop %d" % i
		crop.mesh = SphereMesh.new()
		crop.scale = Vector3(.17,.13,.16)
		crop.position = Vector3(11.35+float(i%3)*.55,.83,-7.59+float(i/3)*.42)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#b9a25c") if i%2==0 else Color("#749156")
		crop.material_override = mat
		root.add_child(crop)
	# Bamboo garden beds stay east of the travelled footpath, never across it.
	for i in range(5):
		_box(root,"Vegetable garden bed %d" % i,Vector3(12.5,.07,-1.0+float(i)*.65),
			Vector3(1.7,.13,.39),Color("#73593f"))
	# A repaired waymarker gives a physical reason for the caretaker to work.
	_box(root,"Trail waymark post",Vector3(5.1,.76,-20.8),Vector3(.14,1.52,.14),Color("#9d845e"))
	_box(root,"Trail waymark plank",Vector3(5.1,1.36,-20.7),Vector3(1.5,.34,.10),Color("#ceb084"))
	for i in range(SETTLEMENT_ACTORS.size()):
		var data: Dictionary = SETTLEMENT_ACTORS[i]
		var actor: Node3D = Folk.person(str(data["id"]),data["shirt"],Color("#6d4c38"))
		actor.name = str(data["id"])
		var selected: Texture2D = FISHER if i == 0 else MARKET if i == 1 else TRAIL
		var face := actor.get_node_or_null("IllustratedSprite") as Sprite3D
		if face != null:
			face.texture = selected
		var depth_face := actor.get_node_or_null("DimensionalBackPlane") as Sprite3D
		if depth_face != null:
			depth_face.texture = selected
		actor.set_meta("visual_asset",selected.resource_path)
		actor.position = data["work"]
		actor.set_meta("postgame_job",data["id"])
		root.add_child(actor)
	# A second real banca animates fishing work in the channel and never on the path.
	var working_boat := Banca.build(root,Vector3(-15.0,.12,0.5))
	working_boat.name = "WorkingFishingBanca"
	working_boat.set_meta("work_boat", true)
	return root

static func update(root: Node3D, fraction: float, elapsed: float,
		reduced_motion: bool) -> void:
	if root == null:
		return
	var hour := fraction*24.0
	var work_shift := hour >= 5.5 and hour < 18.5
	var night_rest := hour >= 19.5 or hour < 5.5
	for i in range(SETTLEMENT_ACTORS.size()):
		var data: Dictionary = SETTLEMENT_ACTORS[i]
		var actor := root.get_node_or_null(str(data["id"])) as Node3D
		if actor == null:
			continue
		actor.visible = not night_rest
		if night_rest:
			continue
		var current: Vector3 = data["work"]
		if hour >= 11.0 and hour < 13.8:
			current = data["rest"]
		elif hour >= 17.7:
			var weight := clampf((hour-17.7)/1.8,0,1)
			current = (data["work"] as Vector3).lerp(data["home"],weight)
		elif hour >= 5.5 and hour < 6.7:
			var weight := clampf((hour-5.5)/1.2,0,1)
			current = (data["home"] as Vector3).lerp(data["work"],weight)
		actor.position = current + (Vector3(0,0,sin(elapsed*.48+float(i))*0.38) if not reduced_motion and work_shift else Vector3.ZERO)
		Folk.animate_person(actor,elapsed+float(i)*1.8,work_shift)
		actor.rotation.y = 0.0 if not work_shift else -2.6
	var boat := root.get_node_or_null("WorkingFishingBanca") as Node3D
	if boat != null:
		boat.visible = hour >= 5.5 and hour < 16.5
		boat.position = Vector3(-15.0,.12,0.5+(0.0 if reduced_motion else sin(elapsed*.09)*3.2))
		Banca.animate(boat, elapsed, reduced_motion)
	var market := root.get_node_or_null("Market table") as MeshInstance3D
	if market != null:
		# Signboards and vegetable stall are present; shutters are represented by
		# residents going home and warm lights inside the existing houses.
		market.visible = true

static func _box(parent: Node3D, id: String, at: Vector3,
		dimensions: Vector3, shade: Color) -> void:
	var wood := MeshInstance3D.new()
	wood.name = id
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	wood.mesh = mesh
	wood.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = shade
	mat.roughness = .93
	wood.material_override = mat
	parent.add_child(wood)
