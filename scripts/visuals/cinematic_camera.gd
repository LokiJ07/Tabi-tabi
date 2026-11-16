extends RefCounted
## Reversible, actor-aware story framing for the existing mobile isometric camera.
## Camera motion affects visuals only, never the player's position or save data.

const DEFAULT_OFFSET := Vector3(12.0, 17.0, 12.0)
const SHOT_OFFSET := Vector3(3.8, 4.7, 5.5)
const WORLD_SIZE := 16.0
const STORY_SIZE := 7.6
var subject: Node3D
var active := false
var speaker := ""
var blend := 0.0


func focus_on(actor: Node3D, role: String) -> void:
	if actor == null:
		release()
		return
	subject = actor
	speaker = role
	active = true


func release() -> void:
	active = false
	subject = null
	speaker = ""


func is_framing() -> bool:
	return active and is_instance_valid(subject)


func target_world_position(player: Node3D) -> Vector3:
	return player.global_position + DEFAULT_OFFSET


func target_story_position(player: Node3D) -> Vector3:
	var focus: Vector3 = subject.global_position if is_framing() else player.global_position
	var relative: Vector3 = SHOT_OFFSET
	if speaker == "SANTELMO":
		relative = Vector3(5.3, 5.8, 6.4)
	return focus + relative


func tick(camera: Camera3D, player: Node3D, delta: float, reduced_motion: bool) -> void:
	if camera == null or player == null:
		return
	var intended: float = 1.0 if is_framing() else 0.0
	var factor: float = 1.0 if reduced_motion else clampf(delta * 3.8, 0.0, 1.0)
	blend = lerpf(blend, intended, factor)
	if absf(blend - intended) < 0.003:
		blend = intended
	var default_pos := target_world_position(player)
	var close_pos := target_story_position(player)
	var destination := default_pos.lerp(close_pos, blend)
	var follow: float = 1.0 if reduced_motion else clampf(delta * 4.0, 0.0, 1.0)
	camera.global_position = camera.global_position.lerp(destination, follow)
	camera.size = lerpf(WORLD_SIZE, STORY_SIZE, blend)
	var look: Vector3 = player.global_position + Vector3(0, 0.7, 0)
	if is_framing():
		look = look.lerp(subject.global_position + Vector3(0, 1.4, 0), blend)
	camera.look_at(look)


func reset() -> void:
	release()
	blend = 0.0
