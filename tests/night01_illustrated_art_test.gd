extends SceneTree
## G6 art acceptance: verify GAME scenes truly use imported 2.5D assets.
const GameScene = preload("res://scenes/main.tscn")
const Actors = preload("res://scripts/visuals/folk_actors.gd")
const Art = preload("res://scripts/world/illustrated_barrio.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("G6 illustrated Night 1 art: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for role in ["LOLA", "DADO", "MARA", "SABEL", "APPRENTICE", "RESIDENT"]:
		var actor: Node3D = Actors.person(role, Color.WHITE, Color.BLACK)
		root.add_child(actor)
		var sprite := actor.get_node_or_null("IllustratedSprite") as Sprite3D
		check(sprite != null, role + ": visible dedicated illustrated sprite exists")
		if sprite != null:
			check(sprite.texture != null and sprite.texture.get_width() >= 256, role + ": SVG imports at usable resolution")
			check(sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y, role + ": sprite faces moving isometric camera")
		check(not (actor.get_node("Head") as MeshInstance3D).visible, role + ": old sphere head no longer visible")
		actor.queue_free()
	var dog := Actors.dog()
	root.add_child(dog)
	check(dog.get_node_or_null("IllustratedSprite") is Sprite3D, "Bantay has unique illustrated dog art")
	check(not (dog.get_node("Head") as MeshInstance3D).visible, "blockout dog face hidden")
	dog.queue_free()

	var game = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	game._close_dialogue()
	check(game.get_node_or_null(Art.ROOT_NAME) != null, "actual playable world integrates imported environment illustrations")
	var scene_art := game.get_node(Art.ROOT_NAME) as Node3D
	check(scene_art.get_child_count() >= 19, "village has authored mangroves, lanterns, banana leaves and hibiscus")
	check(scene_art.get_node_or_null("Winding illustrated earthen path") is MeshInstance3D, "road uses organically shaped textured surface")
	check(scene_art.get_node_or_null("Tidal safety bamboo pole 00") is MeshInstance3D, "river fence is now recognizable woven posts")
	check(not (game.get_node("Main footpath") as MeshInstance3D).visible, "flat rectangular road blockout no longer draws")
	check(not (game.get_node("River bank safety fence") as MeshInstance3D).visible, "opaque shoreline fence replaced by rope art")
	check(game.get_node_or_null("River bank safety fence collision") != null, "invisible river safety physics preserved")
	check(scene_art.get_node_or_null("Painted estuary mangrove 00") is Sprite3D, "mangrove illustration used on shore")
	check(scene_art.get_node_or_null("Illustrated garden hibiscus 00") is Sprite3D, "flower garden illustration present")
	var village := game.get_node_or_null("BarrioEnvironmentDetails") as Node3D
	check(village.get_node_or_null("Lola woven home/Lola authored bamboo facade") != null, "Lola facade is an imported asset")
	check(village.get_node_or_null("Sabel riverside store/Sabel illustrated market facade") != null, "Sabel storefront is an imported asset")
	check(village.get_node_or_null("Mara schoolhouse/Mara illustrated school facade") != null, "school has authored facade")
	for label in ["Ground", "Main footpath", "River"]:
		var mesh := game.get_node_or_null(label) as MeshInstance3D
		check(mesh != null and (mesh.material_override as StandardMaterial3D).albedo_texture != null, label + " uses tiled imported art")
	check(game.get_node_or_null("Ground collision") != null, "ground collision preserved after visual pass")
	check(game.apprentice_visual.get_node_or_null("IllustratedSprite") != null, "player itself uses visible new character art")
	check(game.bantay_visual.get_node_or_null("IllustratedSprite") != null, "following Bantay uses new dog art")
	var first := Art.decorate(game)
	check(first == scene_art, "reapplying art does not duplicate sprites")
	game.queue_free()
	await process_frame
	print("G6 actual illustrated game artwork: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
