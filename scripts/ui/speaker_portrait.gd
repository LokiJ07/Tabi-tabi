extends Control
## Original illustrated head-and-shoulders portrait, matched to the NPC's
## procedurally authored 3D costume. No external textures or extra 3D viewport.

const FolkActors = preload("res://scripts/visuals/folk_actors.gd")
var speaker_id := "NARRATOR"
var breathing := 0.0
var breath_clock := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(245, 235)
	resized.connect(queue_redraw)


func set_speaker(who: String) -> void:
	var role := FolkActors.role_id(who)
	if who.to_upper().contains("BANTAY"):
		role = "BANTAY"
	elif who.to_upper().contains("SANTELMO"):
		role = "SANTELMO"
	elif who.to_upper().contains("NARRATOR") or who == "":
		role = "NARRATOR"
	speaker_id = role
	breath_clock = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	breath_clock += delta
	if breath_clock >= 0.10:
		breath_clock = 0.0
		breathing += 0.18
		queue_redraw()


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(33):
		var a := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(points, color)


func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / 256.0, size.y / 256.0))
	draw_rect(Rect2(0, 0, 256, 256), Color("#13232e"))
	# Film-like rim lights and an intentionally simple inked illustration style.
	for i in range(7):
		draw_line(Vector2(0, 22 + i * 38), Vector2(256, -20 + i * 38), Color(0.34, 0.51, 0.49, 0.055), 3)
	draw_circle(Vector2(128, 111), 100, Color("#264148"))
	draw_circle(Vector2(128, 111), 79, Color("#315258"))
	if speaker_id == "SANTELMO":
		for radius in [93, 72, 49]:
			_ellipse(Vector2(130, 127), Vector2(radius * 0.78, radius), Color(0.99, 0.57, 0.18, 0.09))
		draw_circle(Vector2(130, 127), 36, Color("#eda74f"))
		draw_circle(Vector2(128, 121), 21, Color("#fff3b1"))
		return
	if speaker_id == "NARRATOR":
		_ellipse(Vector2(128, 160), Vector2(73, 68), Color("#24333e"))
		draw_line(Vector2(82, 128), Vector2(167, 70), Color("#a08b68"), 6)
		draw_line(Vector2(88, 154), Vector2(173, 94), Color("#bfad87"), 5)
		return
	if speaker_id == "BANTAY":
		_ellipse(Vector2(129, 214), Vector2(98, 49), Color("#795336"))
		_ellipse(Vector2(126, 130), Vector2(61, 73), Color("#a76e42"))
		_ellipse(Vector2(77, 91), Vector2(22, 49), Color("#49362d"))
		_ellipse(Vector2(175, 91), Vector2(22, 49), Color("#49362d"))
		_ellipse(Vector2(127, 171), Vector2(44, 28), Color("#d5a472"))
		draw_circle(Vector2(109, 126), 5, Color("#1d201e"))
		draw_circle(Vector2(151, 126), 5, Color("#1d201e"))
		draw_circle(Vector2(129, 163), 13, Color("#25221f"))
		return
	var identity: Dictionary = FolkActors.identity(speaker_id)
	var shirt: Color = identity["shirt"]
	var skin: Color = identity["skin"]
	var hair: Color = identity["hair"]
	var accent: Color = identity["accent"]
	var bob := sin(breathing) * 2.0
	_ellipse(Vector2(130, 240), Vector2(105, 73), shirt.darkened(0.36))
	draw_colored_polygon(PackedVector2Array([
		Vector2(22, 255), Vector2(41, 203 + bob), Vector2(83, 183 + bob),
		Vector2(171, 183 + bob), Vector2(217, 205 + bob), Vector2(235, 255)
	]), shirt)
	_ellipse(Vector2(126, 199 + bob), Vector2(25, 31), skin.darkened(0.08))
	if speaker_id == "LOLA":
		draw_colored_polygon(PackedVector2Array([
			Vector2(33, 220 + bob), Vector2(88, 186 + bob), Vector2(128, 223),
			Vector2(168, 186 + bob), Vector2(227, 220 + bob), Vector2(217, 255), Vector2(39, 255)
		]), accent)
	elif speaker_id == "DADO":
		draw_rect(Rect2(86, 203 + bob, 84, 48), Color("#66634a"))
		draw_line(Vector2(90, 190), Vector2(152, 244), accent.lightened(0.05), 8)
	elif speaker_id == "MARA":
		draw_colored_polygon(PackedVector2Array([Vector2(100, 189), Vector2(127, 213), Vector2(110, 225), Vector2(80, 197)]), accent)
		draw_colored_polygon(PackedVector2Array([Vector2(155, 189), Vector2(127, 213), Vector2(144, 225), Vector2(177, 197)]), accent)
		draw_rect(Rect2(185, 191, 31, 54), Color("#684b39"))
	elif speaker_id == "SABEL":
		draw_rect(Rect2(96, 215, 62, 43), accent)
		draw_line(Vector2(96, 216), Vector2(160, 215), Color("#c29d83"), 5)
	elif speaker_id == "APPRENTICE":
		draw_line(Vector2(84, 188), Vector2(154, 254), Color("#68513c"), 9)
	# The close-up face is the focus of the storytelling overlay.
	_ellipse(Vector2(129, 118 + bob), Vector2(57, 76), hair)
	_ellipse(Vector2(129, 130 + bob), Vector2(51, 70), skin)
	_ellipse(Vector2(129, 72 + bob), Vector2(56, 34), hair)
	if speaker_id == "LOLA":
		_ellipse(Vector2(129, 60), Vector2(52, 30), Color("#c1b5a6"))
		_ellipse(Vector2(174, 71), Vector2(28, 27), Color("#b6ada1"))
		draw_line(Vector2(104, 107), Vector2(117, 105), skin.darkened(0.22), 2)
		draw_line(Vector2(143, 105), Vector2(156, 107), skin.darkened(0.22), 2)
	elif speaker_id == "DADO":
		draw_rect(Rect2(75, 53, 111, 26), Color("#a58759"))
		_ellipse(Vector2(128, 44), Vector2(52, 24), Color("#90744f"))
		draw_rect(Rect2(61, 68, 140, 12), accent)
	elif speaker_id == "MARA":
		_ellipse(Vector2(168, 79), Vector2(27, 32), hair)
		for dx in [-21, 21]:
			draw_rect(Rect2(109 + dx - 15, 111, 30, 21), Color("#dec99b"), false, 3)
		draw_line(Vector2(115, 121), Vector2(142, 121), Color("#dec99b"), 3)
	elif speaker_id == "SABEL":
		_ellipse(Vector2(128, 66), Vector2(66, 30), Color("#6f506d"))
		_ellipse(Vector2(181, 76), Vector2(20, 18), Color("#a57d92"))
	elif speaker_id == "APPRENTICE":
		_ellipse(Vector2(128, 59), Vector2(60, 25), Color("#ac8751"))
		draw_rect(Rect2(51, 69, 154, 12), accent)
	for dx in [-23, 23]:
		_ellipse(Vector2(129 + dx, 133 + bob), Vector2(5, 6), Color("#211e1e"))
	_ellipse(Vector2(129, 154 + bob), Vector2(8, 13), skin.darkened(0.12))
	draw_line(Vector2(114, 173 + bob), Vector2(145, 172 + bob), Color("#704b41"), 3)
	if speaker_id == "DADO":
		draw_rect(Rect2(110, 164 + bob, 38, 7), hair)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
