extends RefCounted
## Shared authored in-world affordance for every 2.5D region.
## Draws only when the apprentice is close; never hides characters, their
## faces, or the touch HUD, and never substitutes for a real _interact() call.
const STYLE_ID := "seven-night-identity-cues-v1"

static func paint(scene: CanvasItem, at: Vector2, player_at: Vector2,
		identity: String, kind: String = "object", reach: float = 185.0,
		body_height: float = 0.0) -> void:
	var distance := player_at.distance_to(at)
	if identity.strip_edges().is_empty() or distance > reach:
		return
	var intensity := clampf((reach-distance)/maxf(reach*.48,1.0),.24,1.0)
	var person := kind == "npc"
	var name := identity.to_upper()
	var font := ThemeDB.fallback_font
	var font_size := 15 if name.length() > 19 else 17
	var text_width := font.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var width := clampf(text_width+24.0,98.0,340.0)
	var head_offset := maxf(63.0,body_height+22.0)
	var tag := Rect2(at+Vector2(-width*.5,-head_offset-32.0),Vector2(width,30.0))
	var border := Color("#abcbab") if person else Color("#f4d397")
	border.a *= intensity
	scene.draw_rect(tag,Color(.025,.096,.119,.83*intensity))
	scene.draw_rect(tag,border,false,1.6)
	scene.draw_string(font,tag.position+Vector2(11,21),name,
		HORIZONTAL_ALIGNMENT_LEFT,width-22.0,font_size,
		Color(1.0,.94,.79,intensity))
	# The amber diamond identifies the specific INTERACT position. It is
	# intentionally only a few pixels tall; no target circle covers actors.
	var rhombus := PackedVector2Array([
		at+Vector2(0,-8),at+Vector2(7,0),
		at+Vector2(0,8),at+Vector2(-7,0)])
	scene.draw_colored_polygon(rhombus,Color(border.r,border.g,border.b,.6*intensity))
	scene.draw_line(at+Vector2(0,-19),at+Vector2(0,-8),
		Color(border.r,border.g,border.b,.6*intensity),1.6,true)

static func paint_nearby(scene: CanvasItem, player_at: Vector2, target: String,
		locations: Dictionary, names: Dictionary = {},
		category: String = "object") -> void:
	if target.is_empty() or not locations.has(target):
		return
	var label := str(names.get(target,target.replace("_"," ")))
	paint(scene,locations[target],player_at,
		("SPEAK • " if category == "npc" else "INTERACT • ")+label,category)
