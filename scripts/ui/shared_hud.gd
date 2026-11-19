extends RefCounted
## Shared, physical-screen HUD grammar for every Tabi-tabi chapter.
## The mobile touch zones stay in the same corners when the world/renderer changes.
## Coordinates are measured in the project's 1280x720 reference viewport.
## Night 1 is the single source of truth. Do not author independent
## chapter HUD coordinates or button/icon rules in Night 2–7.
const ICON_PREPARE: Texture2D = preload("res://assets/ui/prepare.svg")
const ICON_NOTES: Texture2D = preload("res://assets/ui/notebook.svg")
const ICON_FOCUS: Texture2D = preload("res://assets/ui/focus.svg")
const ICON_INTERACT: Texture2D = preload("res://assets/ui/interact.svg")
const ICON_DAYNIGHT: Texture2D = preload("res://assets/ui/daynight.svg")
const ICON_RETREAT: Texture2D = preload("res://assets/ui/retreat.svg")
const STATUS_WIDTH := .37
const HOLD_LABEL := "OBSERVING..."
const MovementJoystick = preload("res://scripts/ui/movement_joystick.gd")
const HOLD_COLOR := Color("#665123")
const HOLD_BORDER := Color("#ffda70")

static func create_status_card(parent: Control, chapter_heading: String, text_scale: float = 1.0) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "QuestStatusCard"
	panel.anchor_left = 0.0
	panel.anchor_right = STATUS_WIDTH
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 16.0
	panel.offset_right = -8.0
	panel.offset_top = 10.0
	panel.offset_bottom = 250.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	style_status_panel(panel)
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.name = "StatusRows"
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 6)
	panel.add_child(stack)
	var heading := Label.new()
	heading.name = "VillageHeading"
	heading.text = chapter_heading
	heading.add_theme_font_size_override("font_size", roundi(22.0*text_scale))
	heading.add_theme_color_override("font_color", Color("#f3e2b8"))
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(heading)
	var objective := Label.new()
	objective.name = "QuestObjective"
	objective.add_theme_font_size_override("font_size", roundi(22.0*text_scale))
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective.add_theme_color_override("font_color", Color("#f2f5f2"))
	stack.add_child(objective)
	return {"panel": panel, "stack": stack, "heading": heading, "objective": objective}

static func make_gameplay_button(parent: Control, title: String, pos: Vector2, dimensions: Vector2, down: Callable, up: Callable, text_scale: float = 1.0) -> Button:
	# Clones Night 1's original icon-first button, including responsive
	# bottom-left/right anchoring and exact touch target dimensions.
	var button := Button.new()
	button.text = title
	button.clip_text = true
	var right_side := pos.x > 900
	button.anchor_left = 1.0 if right_side else 0.0
	button.anchor_right = button.anchor_left
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = pos.x - (1280.0 if right_side else 0.0)
	button.offset_top = pos.y - 720.0
	button.offset_right = button.offset_left + dimensions.x
	button.offset_bottom = button.offset_top + dimensions.y
	button.custom_minimum_size = dimensions
	button.size = dimensions
	button.button_down.connect(down)
	button.button_up.connect(up)
	# Dragging outside a touch button must never leave a MOVE or OBSERVE
	# action held. This was inconsistent in the earlier farm/wake chapters.
	if title in ["▲","▼","◀","▶","HOLD OBSERVE","HOLD FOCUS"]:
		button.mouse_exited.connect(up)
		parent.visibility_changed.connect(func():
			if not parent.is_visible_in_tree():
				up.call())
	style_game_button(button, 18 if dimensions.x < 95.0 and title.length() > 2 else 23, dimensions.x < 95.0, text_scale)
	# The tiny RETRY button must fit even at 140% text preference.
	if title == "RETRY" and dimensions.x < 95.0:
		button.add_theme_font_size_override("font_size",18)
	match title:
		"PREPARE": button.icon = ICON_PREPARE
		"FIELD NOTES": button.icon = ICON_NOTES
		"HOLD FOCUS", "HOLD OBSERVE": button.icon = ICON_FOCUS
		"INTERACT": button.icon = ICON_INTERACT
		"DAY / NIGHT": button.icon = ICON_DAYNIGHT
		"SAFE RETREAT": button.icon = ICON_RETREAT
	if button.icon != null:
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		# Night 2 shares Night 1's exact touch rect. Use a compact font for
		# longer translated/action labels so text is never clipped on Android.
		var action_font_size := 16.0 if title.length() >= 12 else 19.0
		button.add_theme_font_size_override("font_size", roundi(action_font_size * text_scale))
		button.add_theme_constant_override("h_separation", 3 if title.length() >= 12 else 4)
	button.set_meta("hud_component", "night1-shared")
	button.set_meta("hud_reference_pos", pos)
	# Night 1 focus already owns its contextual FOCUS HELD state. Later nights
	# use a unified OBSERVING indicator with a real hold-to-release lifecycle.
	if title == "HOLD OBSERVE":
		button.set_meta("hud_hold_action", "observe")
		button.set_meta("hold_visual_active",false)
		button.button_down.connect(func(): set_hold_feedback(button,true))
		button.button_up.connect(func(): set_hold_feedback(button,false))
		button.mouse_exited.connect(func(): set_hold_feedback(button,false))
		parent.visibility_changed.connect(func():
			if not parent.is_visible_in_tree():
				set_hold_feedback(button,false))
	parent.add_child(button)
	return button

static func set_hold_feedback(button: Button, held: bool) -> void:
	if button == null or not is_instance_valid(button):
		return
	# A concrete, accessible state indicator instead of relying on an almost
	# invisible darkening. Keep the original touch rect, icon and anchors.
	button.text = HOLD_LABEL if held else "HOLD OBSERVE"
	button.set_meta("hold_visual_active",held)
	button.tooltip_text = "Release to stop observing" if held else "Press and hold to observe"
	var style := StyleBoxFlat.new()
	style.bg_color = HOLD_COLOR if held else Color("#082b37")
	style.border_color = HOLD_BORDER if held else Color("#c69b55")
	style.set_border_width_all(3 if held else 2)
	style.set_corner_radius_all(9)
	style.shadow_color = Color(.0,.0,.0,.30)
	style.shadow_size = 3
	button.add_theme_stylebox_override("normal",style)
	if held:
		button.add_theme_color_override("font_color",Color("#fff5d7"))
	else:
		button.add_theme_color_override("font_color",Color("#f8e8c7"))

static func create_movement_joystick(parent: Control, settings: RefCounted, on_axis: Callable) -> Control:
	var joystick := MovementJoystick.new()
	joystick.configure(settings)
	joystick.axis_changed.connect(on_axis)
	parent.add_child(joystick)
	return joystick


static func make_options_button(parent: Control, callback: Callable, text_scale: float = 1.0) -> Button:
	var button := Button.new()
	button.name = "Options"
	button.text = "OPTIONS"
	place_action_button(button, "OPTIONS")
	style_game_button(button, 23, false, text_scale)
	button.pressed.connect(callback)
	button.set_meta("hud_component", "night1-shared")
	parent.add_child(button)
	return button

static func make_nearby_prompt(parent: Control, text_scale: float = 1.0) -> Label:
	var prompt := Label.new()
	prompt.name = "NearbyPrompt"
	prompt.anchor_left = .67
	prompt.anchor_right = .86
	prompt.anchor_top = 0.0
	prompt.anchor_bottom = 0.0
	prompt.offset_top = 9.0
	prompt.offset_bottom = 89.0
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", roundi(19.0*text_scale))
	prompt.add_theme_color_override("font_color", Color("#ffe5ad"))
	# Floating wayfinding is a readable chip, not loose text on bright soil.
	var cue := StyleBoxFlat.new()
	cue.bg_color = Color(.035,.105,.133,.86)
	cue.border_color = Color("#aa905c")
	cue.set_border_width_all(1)
	cue.set_corner_radius_all(8)
	cue.content_margin_left = 8
	cue.content_margin_right = 8
	cue.content_margin_top = 4
	cue.content_margin_bottom = 4
	prompt.add_theme_stylebox_override("normal",cue)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# An empty nearby hint is not an actionable chip. Do not paint blank frames.
	prompt.visible = false
	parent.add_child(prompt)
	return prompt

static func set_nearby_prompt_text(prompt: Label, message: String) -> void:
	if prompt == null or not is_instance_valid(prompt):
		return
	prompt.text = message
	prompt.visible = not message.strip_edges().is_empty()

const MOVE_POSITIONS := {
	"up": Vector2(95, 505),
	"left": Vector2(20, 575),
	"right": Vector2(170, 575),
	"down": Vector2(95, 645)
}
const ACTION_POSITIONS := {
	"FIELD NOTES": Vector2(1050, 415),
	"HOLD OBSERVE": Vector2(1050, 490),
	"INTERACT": Vector2(1050, 565),
	"SAFE RETREAT": Vector2(1050, 640)
}

static func style_modal_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#092936")
	style.border_color = Color("#d0a65b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

static func modal_button_style(fill: Color, outline: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

static func style_modal_button(button: Button, selected: bool = false, footer: bool = false, text_scale: float = 1.0) -> void:
	# Identical to Night 1's readable modal choices / notebook / options.
	var edge := Color("#ffd47a") if selected else Color("#bb995c")
	var background := Color("#295643") if selected else Color("#0d3443")
	button.add_theme_stylebox_override("normal", modal_button_style(background, edge))
	button.add_theme_stylebox_override("hover", modal_button_style(Color("#184d59"),Color("#ffdf96")))
	button.add_theme_stylebox_override("pressed", modal_button_style(Color("#2a5644"),Color("#fbd485")))
	button.add_theme_stylebox_override("hover_pressed", modal_button_style(Color(.26,.40,.39),Color(.90,.80,.49)))
	button.add_theme_stylebox_override("focus",modal_button_style(Color(0,0,0,0),Color("#ffde92")))
	button.add_theme_stylebox_override("disabled", modal_button_style(Color(.11,.18,.21),edge.darkened(.15)))
	button.add_theme_color_override("font_color",Color("#f8e8c7"))
	button.add_theme_color_override("font_hover_color",Color.WHITE)
	button.add_theme_color_override("font_pressed_color",Color.WHITE)
	button.add_theme_color_override("font_focus_color",Color.WHITE)
	button.add_theme_color_override("font_disabled_color",Color(.85,.91,.90))
	button.add_theme_font_size_override("font_size",roundi((25.0 if footer else 27.0)*text_scale))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER if footer else HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(button.custom_minimum_size.x,maxf(button.custom_minimum_size.y,63.0))

static func style_game_button(button: Button, font_size: int = 19, touch: bool = false, text_scale: float = 1.0) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#082b37")
	normal.border_color = Color("#c69b55")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(13 if touch else 8)
	normal.content_margin_left = 11
	normal.content_margin_right = 11
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	normal.shadow_color = Color(.0,.0,.0,.27)
	normal.shadow_size = 3
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#154758")
	hover.border_color = Color("#f5ce7a")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#365442")
	pressed.border_color = Color("#ffd47a")
	pressed.set_border_width_all(3)
	pressed.shadow_color = Color(.0,.0,.0,.08)
	pressed.shadow_size = 1
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("#ffde92")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	var disabled_style := normal.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color("#192f36")
	disabled_style.border_color = Color("#68777a")
	button.add_theme_stylebox_override("disabled",disabled_style)
	button.add_theme_color_override("font_disabled_color",Color("#b4c2ba"))
	button.add_theme_color_override("font_color", Color("#f8e8c7"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("#fff4d1"))
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", roundi(float(font_size) * text_scale))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.clip_text = true
	button.set_meta("art_theme", "night1-gold-navy")
	button.set_meta("shared_hud_version", 1)

static func style_status_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.09, 0.83)
	style.border_color = Color("#c29a55")
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

static func place_move_button(button: Button, direction: String) -> void:
	var at: Vector2 = MOVE_POSITIONS.get(direction, Vector2(95, 505))
	button.anchor_left = 0.0
	button.anchor_right = 0.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = at.x
	button.offset_top = at.y - 720.0
	button.offset_right = at.x + 70.0
	button.offset_bottom = at.y - 720.0 + 65.0
	button.custom_minimum_size = Vector2(70, 65)

static func place_action_button(button: Button, action: String) -> void:
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	if action == "OPTIONS":
		# Same top-right anchor as Night 1's pause/settings button.
		button.anchor_top = 0.0
		button.anchor_bottom = 0.0
		button.offset_left = -171.0
		button.offset_right = -20.0
		button.offset_top = 14.0
		button.offset_bottom = 60.0
		button.custom_minimum_size = Vector2(151, 46)
		return
	var at: Vector2 = ACTION_POSITIONS.get(action, Vector2(1050, 565))
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = at.x - 1280.0
	button.offset_right = button.offset_left + 180.0
	button.offset_top = at.y - 720.0
	button.offset_bottom = button.offset_top + 60.0
	button.custom_minimum_size = Vector2(180, 60)
