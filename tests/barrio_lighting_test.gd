extends SceneTree
const Lighting = preload("res://scripts/visuals/barrio_lighting.gd")
var failures := 0

func check(value: bool, name: String) -> void:
	if not value:
		failures += 1
		printerr("Barrio lighting test: " + name)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root.add_child(root_node)
	var sun := DirectionalLight3D.new()
	root_node.add_child(sun)
	var env_node := WorldEnvironment.new()
	env_node.environment = Environment.new()
	root_node.add_child(env_node)
	var lantern := SpotLight3D.new()
	root_node.add_child(lantern)
	Lighting.apply(sun, env_node, lantern, true)
	check(sun.light_energy < 0.4, "dim blue moon instead of full midday light")
	check(env_node.environment.ambient_light_energy < 0.4, "nighttime ambient darker")
	check(lantern.light_energy >= 4.0, "functional warm lantern at night")
	check(lantern.light_color.r > lantern.light_color.b, "lantern stays amber")
	check(env_node.environment.background_color == Lighting.NIGHT_SKY, "night sky color applied")
	Lighting.apply(sun, env_node, lantern, false)
	check(sun.light_energy > 1.0, "daytime warm key light restored")
	check(lantern.light_energy == 0.0, "lantern not overlighting day")
	check(env_node.environment.background_color == Lighting.DAY_SKY, "day sky restored")
	check(env_node.environment.ambient_light_energy > 0.6, "warm daytime ambient restored")
	root_node.queue_free()
	print("Barrio day/night lighting: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
