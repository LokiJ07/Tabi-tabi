extends Control
## Directional touch aim pad; never steers the player's movement.
signal aim_changed(direction: Vector2)
signal aim_released

var active_pointer := -1
var using_mouse := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := Label.new()
	title.text = "LANTERN AIM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_pointer == -1:
			active_pointer = event.index
			_send_aim(event.position)
			accept_event()
		elif not event.pressed and event.index == active_pointer:
			active_pointer = -1
			aim_released.emit()
			accept_event()
	elif event is InputEventScreenDrag and event.index == active_pointer:
		_send_aim(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		using_mouse = event.pressed
		if using_mouse:
			_send_aim(event.position)
		else:
			aim_released.emit()
		accept_event()
	elif event is InputEventMouseMotion and using_mouse:
		_send_aim(event.position)
		accept_event()


func _send_aim(local: Vector2) -> void:
	var half := size * 0.5
	if half.x < 1 or half.y < 1:
		return
	var direction := ((local - half) / half).limit_length()
	if direction.length() < 0.12:
		return
	aim_changed.emit(direction)
