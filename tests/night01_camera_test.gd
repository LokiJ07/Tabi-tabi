extends SceneTree
const Director = preload("res://scripts/visuals/cinematic_camera.gd")
const Scene = preload("res://scenes/main.tscn")
const Actors = preload("res://scripts/visuals/folk_actors.gd")
var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("Cinematic camera test: " + description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := Node3D.new()
	player.position = Vector3(0, 1.0, 0)
	root.add_child(player)
	var subject := Node3D.new()
	subject.position = Vector3(6, 0.0, 5)
	root.add_child(subject)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 16.0
	root.add_child(camera)
	var director = Director.new()
	check(not director.is_framing(), "default shot is free exploration")
	director.focus_on(subject, "LOLA")
	director.tick(camera, player, 1.0, true)
	check(director.is_framing(), "witness shot active")
	check(absf(camera.size - director.STORY_SIZE) < 0.01, "camera zooms to story framing")
	check(camera.global_position.distance_to(subject.global_position + director.SHOT_OFFSET) < 0.1, "camera closes on the actual witness")
	director.release()
	director.tick(camera, player, 1.0, true)
	check(absf(camera.size - director.WORLD_SIZE) < 0.01, "camera restores original isometric scale")
	check(camera.global_position.distance_to(player.global_position + director.DEFAULT_OFFSET) < 0.1, "camera returns to player")
	camera.queue_free()
	subject.queue_free()
	player.queue_free()

	var actor := Actors.person("LOLA", Color.WHITE, Color.BLACK)
	root.add_child(actor)
	check(actor.get_node_or_null("SpeakingMouth") != null, "named mouth mesh for acting")
	Actors.animate_expression(actor, 4.1, true, false)
	var mouth := actor.get_node("SpeakingMouth") as MeshInstance3D
	check(mouth.scale.y > 0.037, "visible lip-motion expression during speech")
	var eye := actor.get_node("EyeLeft") as MeshInstance3D
	check(eye.scale.y < 0.01, "eye blink expression generated")
	Actors.animate_expression(actor, 0.0, false, true)
	check(absf(mouth.scale.y - 0.025) < 0.001, "reduced motion uses static closed mouth")
	actor.queue_free()

	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.camera_director.is_framing(), "opening prologue dialogue creates cinematic camera shot")
	check(game.camera_director.speaker == "LOLA", "opening prologue frames Lola actor")
	game._close_dialogue()
	check(not game.camera_director.is_framing(), "closing dialogue restores free roaming camera")
	game._show_dialogue("APPRENTICE: Bantay woke me.\nLOLA: Kaon sa.")
	check(game.camera_director.speaker == "APPRENTICE", "player speaking causes close-up player shot")
	game._advance_dialogue()
	check(game.camera_director.speaker == "LOLA", "switching page changes in-world camera focus")
	game._close_dialogue()
	game.camera_director.tick(game.camera, game.player, 1.0, true)
	check(absf(game.camera.size - 16.0) < 0.01, "free roaming zoom restored after final line")
	game.queue_free()
	print("Night 1 cinematic camera and acting: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
