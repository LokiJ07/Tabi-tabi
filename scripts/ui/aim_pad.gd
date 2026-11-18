extends Control
## Directional touch aim pad; never steers the player's movement.
signal aim_changed(direction: Vector2)
signal aim_released

var prompt_text := "LANTERN AIM"
var active_pointer := -1
var using_mouse := false
var thumb := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := Label.new()
	title.text = prompt_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	title.add_theme_font_size_override("font_size",16)
	title.add_theme_color_override("font_color",Color("#f3ddb3"))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_pointer == -1:
			active_pointer = event.index
			_send_aim(event.position)
			accept_event()
		elif not event.pressed and event.index == active_pointer:
			active_pointer = -1
			thumb = Vector2.ZERO
			queue_redraw()
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
			thumb = Vector2.ZERO
			queue_redraw()
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
		direction = Vector2.ZERO
	thumb = direction
	queue_redraw()
	# The old deadzone returned without sending ZERO, leaving the flashlight
	# aimed at the previous target even when the finger returned to center.
	aim_changed.emit(direction)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		active_pointer = -1
		using_mouse = false
		thumb = Vector2.ZERO
		aim_released.emit()
		queue_redraw()

func _draw() -> void:
	if size.x < 3.0 or size.y < 3.0:
		return
	# One readable tactile look pad on every chapter: navy frame, antique
	# gold guides and a warm thumb that follows the actual input direction.
	draw_rect(Rect2(Vector2.ZERO,size),Color("#0b2c38",.78),true)
	draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),
		Color("#c6a368",.76),false,2.0,true)
	var center := size * .5 + Vector2(0,11)
	var radius := minf(size.x*.28,size.y*.29)
	draw_arc(center,radius,0.0,TAU,44,Color("#a2b6a7",.46),2.0,true)
	draw_line(center+Vector2(-radius*.85,0),center+Vector2(radius*.85,0),
		Color("#9aaea5",.27),1.0,true)
	draw_line(center+Vector2(0,-radius*.85),center+Vector2(0,radius*.85),
		Color("#9aaea5",.27),1.0,true)
	var at := center+thumb*radius*.82
	draw_circle(at,13.0,Color("#111f29",.92))
	draw_circle(at,10.0,Color("#f0d093") if thumb.length()>.1 else Color("#93a99b"))
	draw_arc(at,12.5,0.0,TAU,24,Color("#f7e9c5",.72),1.7,true)

