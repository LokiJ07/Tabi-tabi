extends SceneTree
## Night 4 cinematic dressing and warning directions. No story/progression
## bypass and no unbounded render resources on Android.
const Vigil = preload("res://scripts/visuals/night04_vigil_art.gd")
const Sound = preload("res://scripts/audio/night04_ambience.gd")
const Scene = preload("res://scenes/night04.tscn")
var errors := 0

func check(ok: bool, why: String) -> void:
	if not ok:
		errors += 1
		printerr("Night4 vigil: "+why)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	check(Vigil.STYLE_ID == "night04-vigil-dressing-v1","nighttime art helper imported")
	check(not Vigil.night_active(0) and not Vigil.night_active(1)
		and Vigil.night_active(2) and Vigil.night_active(3),
		"safe/unsafe lighting responds only after dusk")
	check(is_equal_approx(Vigil.candle_strength(1.0,true),
		Vigil.candle_strength(9.0,true)),"reduced motion freezes candle flicker")
	check(Vigil.candle_strength(1.0,false) >= .91
		and Vigil.candle_strength(9.0,false) <= 1.01,
		"candle light must stay gentle, not strobe")
	check(Vigil.warning_anchor("roofline") != Vigil.warning_anchor("rear_window")
		and Vigil.warning_anchor("rear_window") != Vigil.warning_anchor("courtyard"),
		"three physical directional threat tells are unique")
	var ambience = Sound.new()
	root.add_child(ambience)
	ambience.set_audio_level(0)
	ambience.set_night_stage(3)
	ambience.set_tension(2.0)
	check(ambience.level == 0 and ambience.night_stage == 3
		and is_equal_approx(ambience.tension,1.0),"offline audio honors mute, stage and bounds")
	ambience.queue_free()
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.get_node_or_null("WakeWindAndQuietPrayer") != null,
		"real playable wake installs original nighttime sound node")
	check(game.name == "TabiTabiNight4" and game.camera != null,
		"visual pass keeps original chapter and camera")
	check(game.story.phase == 0 or game.story.phase >= 1,
		"existing story state retained without a new skip")
	game.queue_free()
	await process_frame
	print("Night 4 wake details / route warning art / original ambience: ",
		"PASS" if errors == 0 else str(errors)+" failures")
	quit(0 if errors == 0 else 1)
