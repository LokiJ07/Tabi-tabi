extends RefCounted
## Simple deterministic Bantay awareness model; no extra story flags or rewards.
const RIVER_ALERT_X := -5.0
const LIGHT_ALERT_DISTANCE := 9.0
const COOLDOWN_SECONDS := 10.0
var warning_cooldown := 0.0
var last_message := ""

func tick(delta: float, player_pos: Vector3, is_night: bool, has_light: bool, light_pos: Vector3, alarm: float) -> String:
	warning_cooldown = maxf(0.0, warning_cooldown - delta)
	if warning_cooldown > 0.0:
		return ""
	var text := ""
	if is_night and has_light and player_pos.distance_to(light_pos) < LIGHT_ALERT_DISTANCE and alarm > 0.55:
		text = "Bantay growls softly. The light is unsettled; ease the lantern."
	elif player_pos.x < RIVER_ALERT_X:
		text = "Bantay pauses by the riverside. Stay on the safe path."
	if text != "" and text != last_message:
		last_message = text
		warning_cooldown = COOLDOWN_SECONDS
	elif text == "":
		last_message = ""
	return text if warning_cooldown == COOLDOWN_SECONDS else ""


func reset() -> void:
	warning_cooldown = 0.0
	last_message = ""
