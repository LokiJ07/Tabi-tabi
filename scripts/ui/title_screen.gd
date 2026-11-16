extends Control
## Actual interactive offline title screen (not a concept image).
## The hand-authored background scales with the landscape viewport.
const GameScene = preload("res://scenes/main.tscn")
const Night02Scene = preload("res://scenes/night02.tscn")
const Night03Scene = preload("res://scenes/night03.tscn")
const Night02State = preload("res://scripts/narrative/night02_state.gd")
const Night03Save = preload("res://scripts/core/night03_save.gd")
const Night01State = preload("res://scripts/narrative/night01_state.gd")
const Night02Save = preload("res://scripts/core/night02_save.gd")
const Save = preload("res://scripts/core/save_service.gd")
const Preferences = preload("res://scripts/core/preferences.gd")
const ART_MANGROVE: Texture2D = preload("res://assets/world/mangrove_illustrated.svg")
const ART_BANANA: Texture2D = preload("res://assets/world/banana_plant.svg")
const ART_FLOWERS: Texture2D = preload("res://assets/world/hibiscus_bush.svg")
const ART_LANTERN: Texture2D = preload("res://assets/world/lantern_post.svg")
const ART_SCHOOL: Texture2D = preload("res://assets/world/school_facade.svg")
const ART_MARKET: Texture2D = preload("res://assets/world/market_facade.svg")
const ART_HERO: Texture2D = preload("res://assets/characters/apprentice.svg")
const ART_BANTAY: Texture2D = preload("res://assets/characters/bantay.svg")

var prefs = Preferences.new()
var continue_button: Button
var night2_button: Button
var night3_button: Button
var settings_panel: PanelContainer
var settings_backdrop: ColorRect
var font_button: Button
var audio_button: Button
var motion_button: Button
var loading_cover: ColorRect
var new_game_dialog: ConfirmationDialog
# On Android DEBUG builds only, a fast three-tap upper-right QA gesture
# allows CI to enter live gameplay independently of menu focus/ANR popups.
var qa_corner_taps := 0
var qa_last_tap_ms := 0

func _ready() -> void:
	prefs.load_from()
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	_build_scenic_art()
	_build_menu()
	_build_settings()
	_build_loading()
	_build_confirmation()
	if OS.get_name() == "Android":
		print("NIGHT1_QA_TITLE_SCENE_READY")

func _input(event: InputEvent) -> void:
	# Debug APK screenshot automation can launch the ACTUAL Night 2 scene
	# without fabricating an unlocked Night 1 save. Production has no shortcut.
	if OS.get_name() == "Android" and OS.has_feature("debug") and event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.keycode == KEY_F11:
			get_viewport().set_input_as_handled()
			print("NIGHT3_QA_DEBUG_ENTRY")
			get_tree().change_scene_to_packed(Night03Scene)
			return
		if key.pressed and key.keycode == KEY_F10:
			var viewport := get_viewport()
			if viewport != null:
				viewport.set_input_as_handled()
			print("NIGHT2_QA_DEBUG_ENTRY")
			# Freeing the title is deferred by scene change; never access its
			# viewport after change_scene_to_packed() removes the current scene.
			get_tree().change_scene_to_packed(Night02Scene)
			return
	# Debug-only QA gesture, a backup when Android's screenshot automation
	# cannot reliably tap the real START GAME button. Support touch AND mouse
	# because Android emulator adb input may emulate either event type.
	if not OS.has_feature("debug") or OS.get_name() != "Android":
		return
	var touch: bool = event is InputEventScreenTouch and event.pressed
	var mouse: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not touch and not mouse:
		return
	var at: Vector2 = (event as InputEventScreenTouch).position if touch else (event as InputEventMouseButton).position
	var dimensions := get_viewport().get_visible_rect().size
	var current_ms := Time.get_ticks_msec()
	if current_ms - qa_last_tap_ms < 80:
		return  # Ignore paired synthetic mouse event from the same touch.
	if at.x < dimensions.x * 0.91 or at.y > dimensions.y * 0.19:
		qa_corner_taps = 0
		return
	if current_ms - qa_last_tap_ms > 2000:
		qa_corner_taps = 0
	qa_last_tap_ms = current_ms
	qa_corner_taps += 1
	if qa_corner_taps >= 3:
		qa_corner_taps = 0
		print("NIGHT1_QA_DEBUG_SHORTCUT: entering gameplay")
		_enter_game(true)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / 1280.0, size.y / 720.0))
	# Dusk gradient and mangrove lagoon: all local draw calls, no network image.
	for i in range(28):
		var color := Color("#0d2535").lerp(Color("#77553d"), float(i) / 27.0)
		draw_rect(Rect2(0, float(i) * 27.0, 1280, 27.0), color)
	draw_circle(Vector2(1115, 132), 45, Color("#e5c583"))
	draw_circle(Vector2(1130, 123), 45, Color("#1e3541"))
	draw_colored_polygon(PackedVector2Array([Vector2(445, 438), Vector2(1280, 390), Vector2(1280, 720), Vector2(400, 720)]), Color("#123f46"))
	draw_colored_polygon(PackedVector2Array([Vector2(520, 495), Vector2(735, 393), Vector2(1280, 423), Vector2(1280, 720), Vector2(800, 720)]), Color("#655339"))
	draw_line(Vector2(510, 497), Vector2(735, 394), Color("#b69c65"), 7)
	for i in range(15):
		var yy := 495.0 + float(i) * 14.0
		draw_line(Vector2(480 + float(i % 3) * 8, yy), Vector2(720 + float(i % 5) * 21, yy), Color(0.58, 0.76, 0.70, 0.16), 2)
	# The foreground is now actual imported Godot artwork, not silhouette
	# circles, roofs and boxes drawn into a mock-looking title canvas.
	# Lantern pools and original low-cost firefly accents.
	for i in range(13):
		var x := 710.0 + float(i % 6) * 85.0
		var y := 360.0 + float(i / 6) * 72.0
		draw_circle(Vector2(x, y), 4, Color("#f5c876"))
		draw_circle(Vector2(x, y), 12, Color(1.0, 0.69, 0.24, 0.08))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _build_scenic_art() -> void:
	# Layer real authored textures on the title background. These SVGs are
	# shared with playable Night 1, so the menu no longer advertises unrelated art.
	var scene := Control.new()
	scene.name = "IllustratedTitleScene"
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene)
	_title_sprite(scene, "MangroveAtDusk", ART_MANGROVE, Vector4(0.56, 0.12, 1.02, 0.98))
	_title_sprite(scene, "SchoolhouseAtDusk", ART_SCHOOL, Vector4(0.79, 0.43, 1.06, 0.75))
	_title_sprite(scene, "MarketAtDusk", ART_MARKET, Vector4(0.60, 0.49, 0.83, 0.77))
	_title_sprite(scene, "BananaLeavesAtDusk", ART_BANANA, Vector4(0.83, 0.68, 1.03, 1.05))
	_title_sprite(scene, "VillageLantern", ART_LANTERN, Vector4(0.53, 0.54, 0.67, 0.97))
	_title_sprite(scene, "ApprenticeAtDusk", ART_HERO, Vector4(0.65, 0.56, 0.79, 0.98))
	_title_sprite(scene, "BantayAtDusk", ART_BANTAY, Vector4(0.76, 0.76, 0.88, 1.00))
	_title_sprite(scene, "FloweringShore", ART_FLOWERS, Vector4(0.83, 0.82, 1.04, 1.08))

func _title_sprite(parent: Control, label: String, texture: Texture2D, rect: Vector4) -> void:
	var art := TextureRect.new()
	art.name = label
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.anchor_left = rect.x
	art.anchor_top = rect.y
	art.anchor_right = rect.z
	art.anchor_bottom = rect.w
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)


func _draw_mangrove(at: Vector2, scale2: float) -> void:
	var wood := Color("#302f29")
	draw_line(at + Vector2(0, 7), at + Vector2(0, -123) * scale2, wood, 15 * scale2)
	for i in range(5):
		var dx := (float(i) - 2.0) * 21.0 * scale2
		draw_line(at + Vector2(0, -65) * scale2, at + Vector2(dx, 23) * scale2, wood, 5.5 * scale2)
	for i in range(4):
		var dx := (float(i) - 1.5) * 36.0 * scale2
		draw_circle(at + Vector2(dx, -148 + float(i % 2) * 16) * scale2, 46 * scale2, Color("#244c41") if i % 2 == 0 else Color("#365740"))
		draw_circle(at + Vector2(dx + 11, -154) * scale2, 20 * scale2, Color(0.42, 0.56, 0.30, 0.34))

func _draw_hut(at: Vector2, scale2: float) -> void:
	var w := 104.0 * scale2
	var h := 95.0 * scale2
	draw_rect(Rect2(at.x - w * 0.5, at.y - h, w, h), Color("#aa855c"))
	for i in range(7):
		var dx := -w * 0.45 + float(i) * w / 7.0
		draw_line(at + Vector2(dx, -h), at + Vector2(dx, 0), Color("#725b41"), 2)
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-w * 0.67, -h),
		at + Vector2(0, -h * 1.43),
		at + Vector2(w * 0.66, -h),
		at + Vector2(w * 0.59, -h * 0.86),
		at + Vector2(0, -h * 1.24),
		at + Vector2(-w * 0.60, -h * 0.86)]), Color("#624338"))
	draw_rect(Rect2(at.x - 18 * scale2, at.y - 68 * scale2, 35 * scale2, 31 * scale2), Color("#f2ca78"))
	draw_rect(Rect2(at.x - 22 * scale2, at.y - 70 * scale2, 43 * scale2, 36 * scale2), Color("#5e4636"), false, 4)
	for side in [-1, 1]:
		draw_line(at + Vector2(40 * side, 0) * scale2, at + Vector2(40 * side, 43) * scale2, Color("#5e4638"), 6 * scale2)

func _panel_style(fill: Color, gold: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = gold
	style.set_border_width_all(3)
	style.set_corner_radius_all(13)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	style.shadow_size = 6
	return style

func _button(label: String, parent: Node, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.name = label.replace(" ", "")
	b.clip_text = true
	b.custom_minimum_size = Vector2(380, 62)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", roundi(29.0 * prefs.text_scale))
	b.add_theme_color_override("font_color", Color("#fbeccc"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("#859496"))
	b.add_theme_stylebox_override("normal", _panel_style(Color("#073441"), Color("#dfb562")))
	b.add_theme_stylebox_override("hover", _panel_style(Color("#19525a"), Color("#ffe29a")))
	b.add_theme_stylebox_override("pressed", _panel_style(Color("#2e5747"), Color("#ffd987")))
	b.add_theme_stylebox_override("disabled", _panel_style(Color("#28393e"), Color("#64736e")))
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _build_menu() -> void:
	var title := Label.new()
	title.name = "TitleWordmark"
	title.text = "TABI-TABI"
	title.anchor_left = 0.05
	title.anchor_right = 0.50
	title.anchor_top = 0.07
	title.anchor_bottom = 0.19
	title.add_theme_font_size_override("font_size", 70)
	title.add_theme_color_override("font_color", Color("#ffe4a2"))
	title.add_theme_color_override("font_outline_color", Color("#192a31"))
	title.add_theme_constant_override("outline_size", 6)
	add_child(title)
	var subtitle := Label.new()
	subtitle.name = "VillageSubtitle"
	subtitle.text = "B A R R I O   L A W O M"
	subtitle.anchor_left = 0.06
	subtitle.anchor_right = 0.50
	subtitle.anchor_top = 0.20
	subtitle.anchor_bottom = 0.27
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color("#e2c68b"))
	add_child(subtitle)
	var menu := VBoxContainer.new()
	menu.name = "MainMenu"
	menu.anchor_left = 0.065
	menu.anchor_right = 0.415
	menu.anchor_top = 0.285
	menu.anchor_bottom = 0.945
	menu.add_theme_constant_override("separation", 10)
	add_child(menu)
	_button("START GAME", menu, _start_game)
	continue_button = _button("CONTINUE", menu, func(): _enter_game(false))
	continue_button.disabled = not _has_save()
	night2_button = _button("NIGHT 2  •  KAPRE", menu, _enter_night2)
	var night2_ready: bool = _night2_unlocked()
	# This is a DEVELOPMENT QA APK: allow direct Kapre testing even if
	# ephemeral Android signing forced a clean install without Night 1 save.
	# Production/non-debug releases still require canonical Night 1 completion.
	night2_button.disabled = not night2_ready and not OS.has_feature("debug")
	if Night02Save.exists():
		night2_button.text = "CONTINUE NIGHT 2  •  KAPRE" if night2_ready else "TEST NIGHT 2 (QA)"
	elif not night2_ready and OS.has_feature("debug"):
		night2_button.text = "TEST NIGHT 2 (QA)"
	night3_button = _button("NIGHT 3  •  TIKBALANG",menu,_enter_night3)
	var night3_ready := _night3_unlocked()
	night3_button.disabled = not night3_ready and not OS.has_feature("debug")
	if Night03Save.exists() and night3_ready:
		night3_button.text = "CONTINUE NIGHT 3  •  TIKBALANG"
	elif not night3_ready and OS.has_feature("debug"):
		night3_button.text = "TEST NIGHT 3 (QA)"
	_button("SETTINGS", menu, _open_settings)
	_button("CREDITS", menu, _credits)
	_button("EXIT", menu, func(): get_tree().quit())
	var chapter := Label.new()
	chapter.text = "NIGHT 1 • SANTELMO    /    NIGHT 2 • KAPRE    /    NIGHT 3 • TIKBALANG"
	chapter.anchor_left = 0.075
	chapter.anchor_right = 0.55
	chapter.anchor_top = 0.958
	chapter.anchor_bottom = 0.996
	chapter.add_theme_font_size_override("font_size", 26)
	chapter.add_theme_color_override("font_color", Color("#f7d58c"))
	add_child(chapter)

func _night2_unlocked() -> bool:
	# Any canonically completed Night 1 outcome can move forward. Night 2
	# never overwrites the existing Santelmo save, even after SAFE RETREAT.
	var previous := Night01State.new()
	return not Save.read(previous).is_empty() and previous.outcome != ""


func _night3_unlocked() -> bool:
	if not _night2_unlocked():
		return false
	var kapre := Night02State.new()
	return Night02Save.read(kapre) and kapre.outcome != ""


func _enter_night3() -> void:
	if not _night3_unlocked() and not OS.has_feature("debug"):
		return
	loading_cover.show()
	var loading_label := loading_cover.get_node_or_null("LoadingStatus") as Label
	if loading_label != null:
		loading_label.text = "Opening Night 3: Tikbalang — The False Trail..."
	await get_tree().process_frame
	get_tree().change_scene_to_packed(Night03Scene)


func _enter_night2() -> void:
	if not _night2_unlocked() and not OS.has_feature("debug"):
		return
	loading_cover.show()
	var loading_label := loading_cover.get_node_or_null("LoadingStatus") as Label
	if loading_label != null:
		loading_label.text = "Opening Night 2: The Giant in the Mango Tree..."
	await get_tree().process_frame
	get_tree().change_scene_to_packed(Night02Scene)


func _has_save() -> bool:
	return FileAccess.file_exists(Save.PATH) or FileAccess.file_exists(Save.PATH + ".bak")

func _start_game() -> void:
	if _has_save():
		new_game_dialog.popup_centered(Vector2i(650, 220))
	else:
		_enter_game(true)

func _build_confirmation() -> void:
	new_game_dialog = ConfirmationDialog.new()
	new_game_dialog.title = "Begin a new Night 1?"
	new_game_dialog.dialog_text = "Starting over will replace your current Night 1 save. Continue?"
	new_game_dialog.ok_button_text = "START NEW GAME"
	new_game_dialog.confirmed.connect(func(): _enter_game(true))
	add_child(new_game_dialog)

func _enter_game(fresh: bool) -> void:
	if fresh:
		for path in [Save.PATH, Save.PATH + ".bak", Save.PATH + ".tmp"]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	loading_cover.show()
	await get_tree().process_frame
	get_tree().change_scene_to_packed(GameScene)

func _build_loading() -> void:
	loading_cover = ColorRect.new()
	loading_cover.name = "LoadingScreen"
	loading_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_cover.color = Color("#071e2b")
	loading_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(loading_cover)
	var title := Label.new()
	title.text = "TABI-TABI  •  BARRIO LAWOM"
	title.anchor_left = 0.12
	title.anchor_right = 0.88
	title.anchor_top = 0.36
	title.anchor_bottom = 0.50
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#f6d68d"))
	loading_cover.add_child(title)
	var progress := Label.new()
	progress.name = "LoadingStatus"
	progress.text = "Opening Night 1: Santelmo..."
	progress.anchor_left = 0.20
	progress.anchor_right = 0.80
	progress.anchor_top = 0.54
	progress.anchor_bottom = 0.65
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", 26)
	progress.add_theme_color_override("font_color", Color("#b5d5cc"))
	loading_cover.add_child(progress)
	loading_cover.hide()

func _build_settings() -> void:
	settings_backdrop = ColorRect.new()
	settings_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_backdrop.color = Color(0.0, 0.0, 0.0, 0.76)
	settings_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(settings_backdrop)
	settings_panel = PanelContainer.new()
	settings_panel.name = "TitleSettings"
	settings_panel.anchor_left = 0.25
	settings_panel.anchor_right = 0.75
	settings_panel.anchor_top = 0.18
	settings_panel.anchor_bottom = 0.84
	settings_panel.add_theme_stylebox_override("panel", _panel_style(Color("#0b2b36"), Color("#dcb46a")))
	settings_backdrop.add_child(settings_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	settings_panel.add_child(stack)
	var heading := Label.new()
	heading.text = "GAME SETTINGS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 36)
	heading.add_theme_color_override("font_color", Color("#f6d58f"))
	stack.add_child(heading)
	font_button = _button("TEXT SIZE", stack, _cycle_title_font)
	audio_button = _button("AMBIENCE", stack, _cycle_title_audio)
	motion_button = _button("REDUCED MOTION", stack, _toggle_title_motion)
	_button("BACK", stack, func(): settings_backdrop.hide())
	_refresh_settings()
	settings_backdrop.hide()

func _refresh_settings() -> void:
	font_button.text = "TEXT SIZE   %d%%" % roundi(prefs.text_scale * 100.0)
	audio_button.text = "AMBIENCE   " + ["OFF", "QUIET", "NORMAL"][prefs.audio_level]
	motion_button.text = "REDUCED MOTION   " + ("ON" if prefs.reduced_motion else "OFF")

func _cycle_title_font() -> void:
	prefs.next_text_scale()
	prefs.save_to()
	_refresh_settings()
	for btn in [font_button, audio_button, motion_button]:
		btn.add_theme_font_size_override("font_size", roundi(29.0 * prefs.text_scale))

func _cycle_title_audio() -> void:
	prefs.next_audio_level()
	prefs.save_to()
	_refresh_settings()

func _toggle_title_motion() -> void:
	prefs.reduced_motion = not prefs.reduced_motion
	prefs.save_to()
	_refresh_settings()

func _open_settings() -> void:
	settings_backdrop.show()
	_refresh_settings()

func _credits() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "TABI-TABI — Credits"
	dialog.dialog_text = "Barrio Lawom • Night 1: Santelmo / Night 2: Kapre\nAn original Filipino folklore investigation adventure.\nPrototype visual art and local offline story systems."
	add_child(dialog)
	dialog.popup_centered(Vector2i(630, 250))
	dialog.confirmed.connect(dialog.queue_free)
