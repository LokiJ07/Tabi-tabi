extends RefCounted
## Shared, physical-screen HUD grammar for every Tabi-tabi chapter.
## The mobile touch zones stay in the same corners when the world/renderer changes.
## Coordinates are measured in the project's 1280x720 reference viewport.
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

static func style_game_button(button: Button, font_size: int = 19, touch: bool = false, text_scale: float = 1.0) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#082b37")
	normal.border_color = Color("#c69b55")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(13 if touch else 8)
	normal.content_margin_left = 11
	normal.content_margin_right = 11
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#154758")
	hover.border_color = Color("#f5ce7a")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#365442")
	pressed.border_color = Color("#ffd47a")
	pressed.set_border_width_all(3)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("#ffde92")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
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
