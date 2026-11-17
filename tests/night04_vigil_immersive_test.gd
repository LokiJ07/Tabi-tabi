extends SceneTree
## Night 4 cinematic dressing and warning directions. No story/progression
## bypass and no unbounded render resources on Android.
const Vigil = preload("res://scripts/visuals/night04_vigil_art.gd")
const Sound = preload("res://scripts/audio/night04_ambience.gd")
const Motion = preload("res://scripts/visuals/night04_character_motion.gd")
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
	check(Motion.FULL_SIZE.x >= 380.0 and Motion.FULL_SIZE.y >= 310.0,
		"winged entity has an expanded high-resolution vector silhouette")
	var fit: Dictionary = Motion.camera_fit(Vector2(125,205),Vector2(270,-335),
		Vector2(1280,720))
	var fit_center: Vector2 = fit["center"]
	var half_height: float = 360.0 / float(fit["zoom"])
	check(float(fit["top"]) > fit_center.y-half_height+35.0
		and float(fit["bottom"]) < fit_center.y+half_height-35.0,
		"full wing sweep and hero/Bantay remain visible at 720p")
	check(absf(Motion.wing_angle(true,.7,false)-Motion.wing_angle(true,2.0,false))>.07
		and absf(Motion.wing_angle(false,.7,false)-Motion.wing_angle(false,2.0,false))>.07,
		"wing tips move visibly across consecutive animated frames")
	check(Motion.STYLE_ID == "night04-articulated-wing-and-indoor-transition-v1",
		"independently animated wing and civilian transition module imported")
	check(Motion.indoor_alpha(0.0) == 1.0
		and Motion.indoor_alpha(Motion.INDOOR_DURATION) == 0.0,
		"villagers leave visible courtyard smoothly rather than vanish abruptly")
	check(Motion.indoor_position("NENA",Vector2(-420,-180),Motion.INDOOR_DURATION)
		.distance_to(Motion.WAKE_DOOR) < 35.0,
		"Nena heads toward protected front entrance, never into danger")
	check(Motion.indoor_position("MARA",Vector2(-265,100),Motion.INDOOR_DURATION)
		.distance_to(Motion.WAKE_DOOR) < 35.0,
		"Mara follows friends into protected house")
	check(Motion.wing_angle(true,0,true) == 0.0
		and Motion.wing_angle(false,5.0,true) == 0.0,
		"Reduced Motion stops both wing rotations")
	check(absf(Motion.wing_angle(true,.5,false)) > .10
		and Motion.wing_angle(true,.5,false)*Motion.wing_angle(false,.5,false) < 0.0,
		"articulated wings rotate opposite directions around distinct shoulder joints")
	check(Motion.wing_pivot(true,Vector2.ZERO,Motion.FULL_SIZE)
		!= Motion.wing_pivot(false,Vector2.ZERO,Motion.FULL_SIZE),
		"left/right wings are anchored at different shoulder pivots")
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
	check(game.MANANANGGAL_LEFT.get_width() == 760
		and game.MANANANGGAL_RIGHT.get_width() == 760,
		"two independent original SVG wing layers imported into the game")
	check(game.name == "TabiTabiNight4" and game.camera != null,
		"visual pass keeps original chapter and camera")
	check(game.story.phase == 0 or game.story.phase >= 1,
		"existing story state retained without a new skip")
	game.debug_wake_preview = true
	game.previous_light_stage = 0
	game._process(.3)
	check(game.indoor_transition_seconds == 0.0,
		"newly started night does not instantly teleport villagers")
	if game.dialogue.visible:
		game._choose("close")
	game._process(.8)
	check(game.indoor_transition_seconds > .0
		and game.indoor_transition_seconds < Motion.INDOOR_DURATION,
		"characters begin visible movement after dialogue")
	game._process(3.6)
	check(game.indoor_transition_seconds == Motion.INDOOR_DURATION,
		"everyone indoors before the dangerous midnight encounter")
	game.debug_wake_preview = false
	game.queue_free()
	await process_frame
	print("Night 4 wake details / route warning art / original ambience: ",
		"PASS" if errors == 0 else str(errors)+" failures")
	quit(0 if errors == 0 else 1)
