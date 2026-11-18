extends Control
## One draggable movement joystick for Nights 1-7. The grip relocates ONLY
## the joystick; the circular thumb pad moves the player, not the look camera.
signal axis_changed(axis: Vector2)
const DIAMETER := 188.0
const HEIGHT := 212.0
const CENTER := Vector2(94.0,125.0)
const RADIUS := 65.0
var settings: RefCounted
var thumb := Vector2.ZERO
var active_touch := -1
var reposition_touch := -1
var mouse_move := false
var mouse_drag := false

func configure(user_settings: RefCounted) -> void:
	settings = user_settings

func _ready() -> void:
	name = "MovementJoystick"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(DIAMETER,HEIGHT)
	size = Vector2(DIAMETER,HEIGHT)
	var grip := Label.new()
	grip.name = "MoveGrip"
	grip.text = "↔ MOVE JOYSTICK"
	grip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grip.position = Vector2(4,2)
	grip.size = Vector2(DIAMETER-8,30)
	grip.add_theme_font_size_override("font_size",15)
	grip.add_theme_color_override("font_color",Color("#f5d8a2"))
	grip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grip)
	_reposition_from_settings()
	get_viewport().size_changed.connect(_reposition_from_settings)

func _reposition_from_settings() -> void:
	if settings == null:
		return
	var viewport_size := get_viewport_rect().size
	_place_center(Vector2(float(settings.get("joystick_x"))*viewport_size.x,
		float(settings.get("joystick_y"))*viewport_size.y))

func _place_center(at: Vector2) -> void:
	var viewport_size := get_viewport_rect().size
	var desired := Vector2(
		clampf(at.x,DIAMETER*.5+20.0,maxf(DIAMETER*.5+20.0,viewport_size.x*.48-DIAMETER*.5)),
		clampf(at.y,HEIGHT*.5+180.0,maxf(HEIGHT*.5+180.0,viewport_size.y-HEIGHT*.5-8.0)))
	position = desired-size*.5
	queue_redraw()

func _drag(delta: Vector2) -> void:
	_place_center(position+size*.5+delta)

func _save_position() -> void:
	if settings == null:
		return
	var viewport_size := get_viewport_rect().size
	settings.set("joystick_x",(position.x+size.x*.5)/maxf(viewport_size.x,1.0))
	settings.set("joystick_y",(position.y+size.y*.5)/maxf(viewport_size.y,1.0))
	settings.call("save_to")

func _set_axis_from_local(at: Vector2) -> void:
	var axis := ((at-CENTER)/RADIUS).limit_length()
	if axis.length() < .13:
		axis = Vector2.ZERO
	thumb = axis
	axis_changed.emit(axis)
	queue_redraw()

func _release() -> void:
	thumb = Vector2.ZERO
	active_touch = -1
	mouse_move = false
	axis_changed.emit(Vector2.ZERO)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if active_touch != -1 or reposition_touch != -1:
				return
			if event.position.y < 39.0:
				reposition_touch = event.index
			else:
				active_touch = event.index
				_set_axis_from_local(event.position)
		elif event.index == active_touch:
			_release()
		elif event.index == reposition_touch:
			reposition_touch = -1
			_save_position()
		accept_event()
	elif event is InputEventScreenDrag:
		if event.index == active_touch:
			_set_axis_from_local(event.position)
			accept_event()
		elif event.index == reposition_touch:
			_drag(event.relative)
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_drag = event.position.y < 39.0
			mouse_move = not mouse_drag
			if mouse_move:
				_set_axis_from_local(event.position)
		else:
			if mouse_drag:
				_save_position()
			mouse_drag = false
			_release()
		accept_event()
	elif event is InputEventMouseMotion:
		if mouse_drag:
			_drag(event.relative)
			accept_event()
		elif mouse_move:
			_set_axis_from_local(event.position)
			accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		reposition_touch = -1
		mouse_drag = false
		_release()

func _draw() -> void:
	draw_rect(Rect2(0,0,DIAMETER,35),Color("#132e39",.86),true)
	draw_rect(Rect2(1,1,DIAMETER-2,33),Color("#ccab74",.81),false,2.0,true)
	draw_circle(CENTER,82,Color("#081e29",.75))
	draw_arc(CENTER,82,0,TAU,48,Color("#d1a765",.87),3.0,true)
	draw_circle(CENTER,67,Color("#42606a",.48))
	draw_line(CENTER+Vector2(-52,0),CENTER+Vector2(52,0),Color("#d0c3a0",.42),2.0,true)
	draw_line(CENTER+Vector2(0,-52),CENTER+Vector2(0,52),Color("#d0c3a0",.42),2.0,true)
	var at := CENTER+thumb*RADIUS
	draw_circle(at,29,Color("#102b35"))
	draw_circle(at,24,Color("#efc987") if thumb.length()>.12 else Color("#a1b6ab"))
	draw_arc(at,29,0,TAU,40,Color("#f7e8c5",.85),2.0,true)
