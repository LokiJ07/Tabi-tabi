extends SceneTree
## The same real autoload now handles ALL 7 chapter gates, title actions and
## return-to-previous-trail routes. Verify the persistent curtain and the
## headless/reduced-motion scene-switch contract without spoofing story saves.
const Transit = preload("res://scripts/core/scene_transit.gd")
const World = preload("res://scripts/core/connected_world.gd")
var failures := 0

func check(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		printerr("All-night cinematic transfer: "+reason)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var service := root.get_node_or_null("SceneTransit")
	check(service != null and service is CanvasLayer,
		"persistent scene transition autoload exists ABOVE every chapter HUD")
	if service == null:
		quit(1)
		return
	check(service.layer > 100,"cinematic curtain overlays gameplay and dialogue")
	check(service.curtain != null and not service.curtain.visible,
		"curtain is invisible and does not block game controls while idle")
	check(service.curtain.mouse_filter == Control.MOUSE_FILTER_STOP,
		"screen-touch controls are held safely during crossfade")
	check(service.FADE_OUT_SECONDS > .16 and service.FADE_OUT_SECONDS < .5,
		"old map fade is legible but short")
	check(service.FADE_IN_SECONDS > .17 and service.FADE_IN_SECONDS < .6,
		"new map reveal gives the player time to orient")
	for region in World.REGIONS:
		var path: String = World.scene_for(region)
		check(path != "" and ResourceLoader.exists(path),
			"every region in one connected world is a real playable scene: "+region)
		var key := path.get_file().get_basename()
		check(service.LOCATION_NAMES.has(key),
			"cinematic arrival explicitly names destination: "+region)
	check(service.LOCATION_NAMES.has("title"),
		"returning to menu does not hard-cut the screen")
	check(service.change_to_file("res://scenes/NO_FAKE_CHAPTER.tscn") == ERR_FILE_NOT_FOUND,
		"invalid scene never leaves player in a black screen")
	check(not service.busy and not service.curtain.visible,
		"missing scene does not strand touch input")
	service.busy = true
	check(service.change_to_file("res://scenes/main.tscn") == ERR_BUSY,
		"repeated mobile tap cannot start two simultaneous scene streams")
	service.busy = false
	service._start_curtain("res://scenes/night07.tscn")
	check(service.curtain.visible and service.state == "fade_out"
		and service.destination_label.text.contains("BALETE"),
		"Balete transition has the correct chapter identity")
	check(is_zero_approx(service.curtain.modulate.a),
		"outgoing world begins visible, no abrupt black flash")
	await service._cover_old_world()
	check(service.curtain.modulate.a > .99,
		"old map has fully faded before replacement")
	await service._reveal_new_world()
	check(not service.curtain.visible and not service.busy and service.state == "idle",
		"new chapter fade ends with no black screen or locked controls")
	# Reduced Motion must commit immediately. Scene change still uses Godot's
	# native deferred instantiation, just as all pre-polish tests expected.
	var before: int = int(service.completed_transfers)
	check(service.change_to_file("res://scenes/night02.tscn",true) == OK,
		"Reduced Motion transfers to an actual world region")
	check(service.completed_transfers == before+1 and not service.busy,
		"accessibility path never waits for a cosmetic animation")
	await process_frame
	await process_frame
	check(current_scene != null and current_scene.name == "TabiTabiNight2",
		"actual destination loaded, not a screenshot or detached debug overlay")
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	await process_frame
	print("All seven-night cinematic travel curtain and reduced-motion route: ",
		"PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
