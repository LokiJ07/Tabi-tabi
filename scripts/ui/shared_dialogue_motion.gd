extends RefCounted
## Tabi-tabi's single reversible dialogue-motion grammar for every night.
## Purely presentation: story state and input gates change synchronously.
## An inert exit ghost lets the actual dialogue close immediately, preserving
## touch safety and existing scene flow while its rendered art fades away.
const OPEN_SECONDS := 0.22
const CLOSE_SECONDS := 0.18
const SPEAKER_SECONDS := 0.15
const OPEN_SCALE := Vector2(0.985, 0.985)

static func _stop_previous(panel: Control) -> void:
	if panel.has_meta("cinematic_tween"):
		var running: Variant = panel.get_meta("cinematic_tween")
		if is_instance_valid(running) and running is Tween and running.is_running():
			running.kill()
		panel.remove_meta("cinematic_tween")
	if panel.has_meta("cinematic_exit_ghost"):
		var old: Variant = panel.get_meta("cinematic_exit_ghost")
		if is_instance_valid(old) and old is Node:
			old.queue_free()
		panel.remove_meta("cinematic_exit_ghost")

static func reveal(panel: Control, reduced_motion: bool) -> void:
	if panel == null:
		return
	_stop_previous(panel)
	panel.pivot_offset = panel.size * 0.5
	panel.modulate.a = 1.0
	panel.scale = Vector2.ONE
	panel.show()
	if reduced_motion or not panel.is_inside_tree():
		return
	panel.modulate.a = 0.0
	panel.scale = OPEN_SCALE
	var fade := panel.create_tween().set_parallel(true)
	fade.tween_property(panel,"modulate:a",1.0,OPEN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade.tween_property(panel,"scale",Vector2.ONE,OPEN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	panel.set_meta("cinematic_tween",fade)

static func _set_inert(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		(node as Control).focus_mode = Control.FOCUS_NONE
	# Mouse IGNORE and no keyboard focus keep duplicated choice buttons inert;
	# do not disable them, which would flash their grey disabled palette.
	for child in node.get_children():
		_set_inert(child)

static func conceal(panel: Control, reduced_motion: bool) -> void:
	if panel == null:
		return
	_stop_previous(panel)
	# Never postpone a story choice or the HUD's return while waiting on art.
	var make_ghost := panel.visible and not reduced_motion and panel.is_inside_tree() and panel.get_parent() != null
	if make_ghost:
		# Copy procedural portrait drawing too, but not old signal handlers.
		var ghost := panel.duplicate(Node.DUPLICATE_SCRIPTS) as Control
		ghost.name = "DialogueExitAfterimage"
		_set_inert(ghost)
		panel.get_parent().add_child(ghost)
		ghost.pivot_offset = ghost.size * 0.5
		ghost.modulate.a = minf(1.0,panel.modulate.a)
		ghost.scale = panel.scale
		ghost.show()
		panel.set_meta("cinematic_exit_ghost",ghost)
		var tween := ghost.create_tween().set_parallel(true)
		tween.tween_property(ghost,"modulate:a",0.0,CLOSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(ghost,"scale",Vector2(0.99,0.99),CLOSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(ghost.queue_free)
	panel.hide()
	panel.modulate.a = 1.0
	panel.scale = Vector2.ONE

static func reveal_text(line: Label, reduced_motion: bool) -> void:
	if line == null:
		return
	if line.has_meta("dialogue_text_tween"):
		var old: Variant = line.get_meta("dialogue_text_tween")
		if old is Tween and old.is_running():
			old.kill()
		line.remove_meta("dialogue_text_tween")
	line.visible_characters = -1
	if reduced_motion or not line.is_inside_tree() or line.text.is_empty():
		return
	# A quick cinematic reveal, not a slow mandatory reading timer.
	var count := line.text.length()
	var duration := clampf(float(count) / 135.0, 0.24, 0.90)
	line.visible_characters = 0
	var tween := line.create_tween()
	tween.tween_property(line,"visible_characters",count,duration).set_trans(Tween.TRANS_LINEAR)
	line.set_meta("dialogue_text_tween",tween)

static func finish_text(line: Label) -> bool:
	if line == null:
		return false
	var unfinished := line.visible_characters >= 0 and line.visible_characters < line.text.length()
	if unfinished:
		if line.has_meta("dialogue_text_tween"):
			var running: Variant = line.get_meta("dialogue_text_tween")
			if is_instance_valid(running) and running is Tween and running.is_running():
				running.kill()
			line.remove_meta("dialogue_text_tween")
		line.visible_characters = -1
	return unfinished

static func restore_gameplay(hud: Control, reduced_motion: bool) -> void:
	if hud == null:
		return
	if hud.has_meta("hud_restore_tween"):
		var earlier: Variant = hud.get_meta("hud_restore_tween")
		if is_instance_valid(earlier) and earlier is Tween and earlier.is_running():
			earlier.kill()
		hud.remove_meta("hud_restore_tween")
	hud.modulate.a = 1.0
	if reduced_motion or not hud.is_inside_tree():
		return
	# Only the chrome eases back in; buttons become usable immediately.
	hud.modulate.a = 0.42
	var fade := hud.create_tween()
	fade.tween_property(hud,"modulate:a",1.0,0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hud.set_meta("hud_restore_tween",fade)

static func reset_gameplay(hud: Control) -> void:
	if hud == null:
		return
	if hud.has_meta("hud_restore_tween"):
		var earlier: Variant = hud.get_meta("hud_restore_tween")
		if is_instance_valid(earlier) and earlier is Tween and earlier.is_running():
			earlier.kill()
		hud.remove_meta("hud_restore_tween")
	hud.modulate.a = 1.0

static func speaker_change(content: Array, reduced_motion: bool) -> void:
	# Speaker name/portrait/text are updated immediately for gameplay tests and
	# screen readers, with a brief presentation-only cross-dissolve.
	for element in content:
		if element == null or not is_instance_valid(element) or not element.visible:
			continue
		if element.has_meta("speaker_tween"):
			var older: Variant = element.get_meta("speaker_tween")
			if is_instance_valid(older) and older is Tween and older.is_running():
				older.kill()
			element.remove_meta("speaker_tween")
		element.modulate.a = 1.0
		if not reduced_motion and element.is_inside_tree():
			element.modulate.a = 0.34
			var tween: Tween = (element as Control).create_tween()
			tween.tween_property(element,"modulate:a",1.0,SPEAKER_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			element.set_meta("speaker_tween",tween)
