extends CanvasLayer
## One world: seamless-looking chapter transfers, not disconnected menus.
## Root-persistent screen curtain survives Godot's scene replacement so the
## OLD world fades out and the NEW world fades in. No story/save state here.
## Headless CI and Reduced Motion retain synchronous scene calls.
const FADE_OUT_SECONDS := 0.25
const FADE_IN_SECONDS := 0.34
const LOCATION_NAMES := {
	"main":"BARRIO LAWOM • THE RIVERSIDE",
	"night02":"THE OLD MANGO • KAPRE",
	"night03":"THE RIDGE • TIKBALANG",
	"night04":"THE WAKE • MANANANGGAL",
	"night05":"THE FARM • SIGBIN",
	"night06":"THE FLOOD RIVER • REMEMBRANCE",
	"night07":"THE ANCIENT BALETE • THE PROMISE",
	"title":"BARRIO LAWOM • MAIN MENU"
}
var busy := false
var curtain: ColorRect
var destination_label: Label
var title_label: Label
var detail_label: Label
var latest_destination := ""
var completed_transfers := 0
var state := "idle"

func _ready() -> void:
	layer = 120
	name = "SceneTransit"
	curtain = ColorRect.new()
	curtain.name = "ChapterCrossingCurtain"
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.color = Color("#081b23")
	curtain.modulate.a = 0.0
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	curtain.visible = false
	add_child(curtain)
	var center := CenterContainer.new()
	center.name = "TravelingLabelContainer"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.add_child(center)
	var column := VBoxContainer.new()
	column.name = "ChapterTransitionText"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation",16)
	column.custom_minimum_size = Vector2(520,175)
	center.add_child(column)
	title_label = _make_text(column,"TABI-TABI • BARRIO LAWOM",20,Color("#c4a675"))
	destination_label = _make_text(column,"FOLLOWING THE OLD FOOTPATH",29,Color("#f5e7c1"))
	detail_label = _make_text(column,"THE ROAD CONTINUES",16,Color("#a9bdb2"))

func _make_text(parent: VBoxContainer, content: String, size_pt: int,
		shade: Color) -> Label:
	var text_line := Label.new()
	text_line.text = content
	text_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_line.add_theme_font_size_override("font_size",size_pt)
	text_line.add_theme_color_override("font_color",shade)
	parent.add_child(text_line)
	return text_line

func change_to_file(path: String, reduced_motion: bool = false) -> Error:
	if path == "" or not ResourceLoader.exists(path):
		push_error("SceneTransit: chapter is not implemented: "+path)
		return ERR_FILE_NOT_FOUND
	if busy:
		return ERR_BUSY
	latest_destination = path
	if _skip_animation(reduced_motion):
		# Headless tests must observe exactly the previous immediate Godot
		# scene-commit behavior. Do not introduce a hidden frame of delay.
		state = "instant"
		completed_transfers += 1
		return get_tree().change_scene_to_file(path)
	_animate_file(path)
	return OK

func change_to_packed(packed: PackedScene, reduced_motion: bool = false) -> Error:
	if packed == null:
		return ERR_INVALID_PARAMETER
	if busy:
		return ERR_BUSY
	latest_destination = packed.resource_path
	if _skip_animation(reduced_motion):
		state = "instant"
		completed_transfers += 1
		return get_tree().change_scene_to_packed(packed)
	_animate_packed(packed)
	return OK

func _skip_animation(reduced_motion: bool) -> bool:
	return reduced_motion or DisplayServer.get_name() == "headless" or not is_inside_tree()

func _animate_file(path: String) -> void:
	busy = true
	_start_curtain(path)
	await _cover_old_world()
	var result := get_tree().change_scene_to_file(path)
	if result != OK:
		push_error("SceneTransit: chapter failed to load: "+path)
		_uncover_failed()
		return
	await get_tree().process_frame
	completed_transfers += 1
	await _reveal_new_world()

func _animate_packed(packed: PackedScene) -> void:
	busy = true
	_start_curtain(packed.resource_path)
	await _cover_old_world()
	var result := get_tree().change_scene_to_packed(packed)
	if result != OK:
		push_error("SceneTransit: packed chapter failed: "+str(result))
		_uncover_failed()
		return
	await get_tree().process_frame
	completed_transfers += 1
	await _reveal_new_world()

func _start_curtain(path: String) -> void:
	state = "fade_out"
	var file_name := path.get_file().get_basename()
	destination_label.text = str(LOCATION_NAMES.get(file_name,
		"FOLLOWING THE OLD FOOTPATH"))
	detail_label.text = "THE ROAD CONTINUES" if file_name != "title" else "THE STORY REMAINS SAVED"
	curtain.modulate.a = 0.0
	curtain.show()

func _cover_old_world() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(curtain,"modulate:a",1.0,FADE_OUT_SECONDS)
	await tween.finished

func _reveal_new_world() -> void:
	state = "fade_in"
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(curtain,"modulate:a",0.0,FADE_IN_SECONDS)
	await tween.finished
	curtain.hide()
	busy = false
	state = "idle"

func _uncover_failed() -> void:
	state = "error"
	var tween := create_tween()
	tween.tween_property(curtain,"modulate:a",0.0,.15)
	await tween.finished
	curtain.hide()
	busy = false
	state = "idle"
