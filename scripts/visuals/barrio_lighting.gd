extends RefCounted
## Controlled daytime/night color script for Godot 4.3 GL Compatibility.
## Does not create expensive shadow cascades or additional fullscreen effects.

const DAY_SKY := Color(0.49, 0.68, 0.72)
const NIGHT_SKY := Color(0.036, 0.073, 0.13)
const DAY_AMBIENT := Color(0.77, 0.74, 0.68)
const NIGHT_AMBIENT := Color(0.27, 0.41, 0.54)
const DAY_SUN := Color(1.0, 0.88, 0.70)
const NIGHT_MOON := Color(0.45, 0.62, 0.88)


static func apply(sun: DirectionalLight3D, env_node: WorldEnvironment, lantern: SpotLight3D, night: bool) -> void:
	if sun != null:
		sun.light_energy = 0.21 if night else 1.05
		sun.light_color = NIGHT_MOON if night else DAY_SUN
	if env_node != null and env_node.environment != null:
		var sky: Environment = env_node.environment
		sky.background_mode = Environment.BG_COLOR
		sky.background_color = NIGHT_SKY if night else DAY_SKY
		sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		sky.ambient_light_color = NIGHT_AMBIENT if night else DAY_AMBIENT
		sky.ambient_light_energy = 0.32 if night else 0.62
	if lantern != null:
		lantern.light_color = Color(1.0, 0.73, 0.38)
		lantern.light_energy = 4.2 if night else 0.0
		lantern.spot_angle = 49.0
		lantern.spot_range = 11.5
