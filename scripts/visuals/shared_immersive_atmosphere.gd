extends Control
## Shared tactile atmosphere for all Tabi-tabi chapters.
## CanvasItem only: works on low-end Android, compatibility renderer and 3D.
## Visual fear comes from the world, not from masking dialogue or touch controls.
## No physics, camera or save data is changed by this layer.

var chapter_id := 1
var light_stage := 0
var tension := 0.0
var reduced_motion := false
var clock := 0.0

func _ready() -> void:
	name = "SharedImmersiveAtmosphere"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(true)

func configure(chapter: int, stage: int, pressure: float, accessibility_reduced_motion: bool) -> void:
	chapter_id = clampi(chapter, 1, 7)
	light_stage = clampi(stage, 0, 3)
	tension = clampf(pressure, 0.0, 1.0)
	reduced_motion = accessibility_reduced_motion
	queue_redraw()

func _process(delta: float) -> void:
	if not reduced_motion:
		clock += minf(delta, 0.08)
	if light_stage > 0:
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 100.0 or h < 100.0 or light_stage == 0:
		return
	# Peripheral darkness induces anticipation while the center playfield
	# and golden HUD remain readable. This never blocks a touch target.
	var edge := clampf(.045 + .055 * float(light_stage) + tension*.12, .05, .32)
	var breath := 0.0 if reduced_motion else sin(clock * (1.25 + tension))*.012*tension
	var rim := edge + breath
	for i in range(7):
		var portion := float(i + 1) / 7.0
		var strip := minf(w, h) * (.012 + portion*.052)
		var alpha := rim*(.17 - portion*.012)
		var ink := Color(.006,.017,.028,alpha)
		draw_rect(Rect2(0.0,0.0,strip,h),ink)
		draw_rect(Rect2(w-strip,0.0,strip,h),ink)
		draw_rect(Rect2(0.0,0.0,w,strip*.68),ink)
		draw_rect(Rect2(0.0,h-strip*.68,w,strip*.68),ink)
	# Two chapters share visual grammar, but not identical weather.
	if chapter_id == 1:
		# Shore: scarce diagonal rain; use dark contours instead of white
		# streaks that would obscure tiny interaction prompts.
		if light_stage >= 2:
			for i in range(25):
				var x := fposmod(float(i*137) + clock*float(36 + i%4*10),w+120.0)-60.0
				var y := fposmod(float(i*83) + clock*float(96+i%5*13),h+90.0)-45.0
				draw_line(Vector2(x,y),Vector2(x-13,y+28),Color(.70,.85,.90,.045),1.4,true)
	else:
		# Mangrove/mango understory: low, slow-moving fog with leaf
		# silhouettes in the margins, not on the center objective.
		var fog_alpha := .026 + tension*.032
		for i in range(8):
			var x := float(i)*w/7.0 - (0.0 if reduced_motion else fposmod(clock*12.0,float(w)/7.0))
			var y := h*(.78 + .04*sin(float(i)*1.8))
			draw_circle(Vector2(x,y),h*(.06 + float(i%3)*.018),
				Color(.70,.81,.75,fog_alpha))
	# A softened peripheral heartbeat responds to genuinely rising danger.
	if tension >= .55:
		var beat := 0.0 if reduced_motion else pow(maxf(0.0,sin(clock*6.9)),8.0)
		var amount := (.008 + beat*.028)*tension
		var pulse_color := Color(.40,.10,.075,amount)
		draw_rect(Rect2(0.0,0.0,w,5.0),pulse_color)
		draw_rect(Rect2(0.0,h-5.0,w,5.0),pulse_color)
