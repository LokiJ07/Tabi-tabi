extends RefCounted
## Canonical Tabi-tabi settings/pause panel. Every Night and the title must
## use this ONE layout, button style, preference vocabulary and save-safe
## action order. Individual chapters only supply their scene callbacks.
const SharedHUD = preload("res://scripts/ui/shared_hud.gd")

const NAMES := {
	"text":"PrefText",
	"motion":"PrefMotion",
	"contrast":"PrefContrast",
	"hint":"PrefHint",
	"assist":"PrefAssist",
	"audio":"PrefAudio"
}
const ORDER := ["text","motion","contrast","hint","assist","audio"]

static func create(parent: Control, prefs: RefCounted, heading: String,
		actions: Dictionary, on_change: Callable = Callable(),
		panel_name: String = "SharedPauseOptions") -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.anchor_left = .12
	panel.anchor_right = .88
	panel.anchor_top = .10
	panel.anchor_bottom = .90
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	SharedHUD.style_modal_panel(panel)
	parent.add_child(panel)
	var root := VBoxContainer.new()
	root.name = "SettingsLayout"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation",9)
	panel.add_child(root)
	var heading_label := Label.new()
	heading_label.name = "OptionsTitle"
	heading_label.text = "TABI-TABI  •  " + heading
	heading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading_label.add_theme_font_size_override("font_size",roundi(27.0*prefs.text_scale))
	heading_label.add_theme_color_override("font_color",Color("#f6dfb0"))
	root.add_child(heading_label)
	var columns := HBoxContainer.new()
	columns.name = "Columns"
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",18)
	root.add_child(columns)

	var settings_scroll := ScrollContainer.new()
	settings_scroll.name = "SettingsScroll"
	settings_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_scroll.follow_focus = true
	columns.add_child(settings_scroll)
	var settings := VBoxContainer.new()
	settings.name = "OptionsContent"
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.add_theme_constant_override("separation",8)
	settings_scroll.add_child(settings)
	var options_heading := Label.new()
	options_heading.name = "OptionsHeading"
	options_heading.text = "ACCESSIBILITY & GAME SETTINGS"
	options_heading.add_theme_font_size_override("font_size",roundi(20.0*prefs.text_scale))
	options_heading.add_theme_color_override("font_color",Color("#e8cb95"))
	settings.add_child(options_heading)
	var controls: Dictionary = {"panel":panel}
	for id in ORDER:
		var key: String = str(id)
		var btn := Button.new()
		btn.name = NAMES[key]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.clip_text = true
		btn.custom_minimum_size = Vector2(0,63)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		SharedHUD.style_modal_button(btn,false,false,prefs.text_scale)
		btn.pressed.connect(_change_preference.bind(key,prefs,panel,on_change))
		settings.add_child(btn)
		controls[key] = btn

	var right := VBoxContainer.new()
	right.name = "ActionStack"
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",8)
	columns.add_child(right)
	var action_heading := Label.new()
	action_heading.text = "JOURNEY & PROGRESS" if not bool(actions.get("title",false)) else "YOUR JOURNEY"
	action_heading.add_theme_font_size_override("font_size",roundi(20.0*prefs.text_scale))
	action_heading.add_theme_color_override("font_color",Color("#e8cb95"))
	right.add_child(action_heading)

	if bool(actions.get("title",false)):
		var note := Label.new()
		note.name = "SettingsHint"
		note.text = "These preferences are saved offline and shared across all seven nights. Joystick position can be changed by dragging its handle during play."
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_font_size_override("font_size",roundi(20.0*prefs.text_scale))
		note.add_theme_color_override("font_color",Color("#d9e6db"))
		right.add_child(note)
	else:
		if actions.has("save"):
			controls["save"] = _action(right,"SaveProgress","SAVE PROGRESS",
				actions["save"],prefs,false)
		if actions.has("notes"):
			controls["notes"] = _action(right,"FieldNotes","FIELD NOTES",
				actions["notes"],prefs,false)
		if actions.has("next"):
			controls["next"] = _action(right,"BeginNight2Kapre",
				str(actions.get("next_label","NEXT CHAPTER")),
				actions["next"],prefs,false)
		if actions.has("menu"):
			controls["menu"] = _action(right,"SaveAndMainMenu",
				"SAVE & MAIN MENU",actions["menu"],prefs,
				bool(actions.get("confirm_navigation",false)),parent)
		if actions.has("quit"):
			controls["quit"] = _action(right,"QuitGame","SAVE & QUIT GAME",
				actions["quit"],prefs,
				bool(actions.get("confirm_navigation",false)),parent)
	if actions.has("back"):
		controls["back"] = _action(right,"CloseSettings",
			"BACK TO GAME" if not bool(actions.get("title",false)) else "BACK TO MAIN MENU",
			actions["back"],prefs,false)
	refresh(panel,prefs)
	panel.hide()
	return controls

static func _action(parent: VBoxContainer, name: String, label: String,
		action: Callable, prefs: RefCounted, confirm: bool,
		dialog_parent: Control = null) -> Button:
	var btn := Button.new()
	btn.name = name
	btn.text = label
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0,63)
	SharedHUD.style_modal_button(btn,false,true,prefs.text_scale)
	parent.add_child(btn)
	if confirm and dialog_parent != null:
		var dialog := ConfirmationDialog.new()
		dialog.name = "Confirm" + name
		dialog.title = "Confirm " + label.to_lower() + "?"
		dialog.dialog_text = "Your current chapter will be saved first. If saving fails, the game stays open."
		dialog.ok_button_text = label
		dialog.confirmed.connect(action)
		dialog_parent.add_child(dialog)
		btn.pressed.connect(func(): dialog.popup_centered(Vector2i(600,210)))
	else:
		btn.pressed.connect(action)
	return btn

static func refresh(panel: PanelContainer, prefs: RefCounted) -> void:
	if panel == null:
		return
	var words := {
		"text":"TEXT SIZE: %d%%" % roundi(prefs.text_scale*100.0),
		"motion":"REDUCED MOTION: " + ("ON" if prefs.reduced_motion else "OFF"),
		"contrast":"HIGH-CONTRAST TEXT: " + ("ON" if prefs.high_contrast else "OFF"),
		"hint":"PUZZLE HINTS: " + str(prefs.HINT_LEVELS[prefs.hint_level]),
		"assist":"STORY ASSIST / NO-FAIL: " + ("ON" if prefs.story_assist else "OFF"),
		"audio":"AMBIENCE: " + ["OFF","QUIET","NORMAL"][prefs.audio_level]
	}
	for id in ORDER:
		var key: String = str(id)
		var btn := panel.find_child(NAMES[key],true,false) as Button
		if btn == null:
			continue
		btn.text = words[key]
		SharedHUD.style_modal_button(btn,false,false,prefs.text_scale)
		btn.custom_minimum_size.y = 63
	panel.queue_sort()

static func _change_preference(id: String,prefs: RefCounted,
		panel: PanelContainer,on_change: Callable) -> void:
	match id:
		"text": prefs.next_text_scale()
		"motion": prefs.reduced_motion = not prefs.reduced_motion
		"contrast": prefs.high_contrast = not prefs.high_contrast
		"hint": prefs.next_hint_level()
		"assist": prefs.story_assist = not prefs.story_assist
		"audio": prefs.next_audio_level()
	prefs.save_to()
	refresh(panel,prefs)
	if on_change.is_valid():
		on_change.call()
