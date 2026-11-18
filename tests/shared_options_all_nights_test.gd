extends SceneTree
## Screenshot-derived quality gate: one *real* in-game settings and pause
## experience throughout the title and all seven connected night scenes.
const Prefs = preload("res://scripts/core/preferences.gd")
const SharedOptions = preload("res://scripts/ui/shared_options.gd")
const SCENES := [
	["res://scenes/title.tscn","TitleSettings",true],
	["res://scenes/main.tscn","SettingsPanel",false],
	["res://scenes/night02.tscn","Night2Options",false],
	["res://scenes/night03.tscn","Night3Options",false],
	["res://scenes/night04.tscn","WakeOptions",false],
	["res://scenes/night05.tscn","FarmOptions",false],
	["res://scenes/night06.tscn","RiverOptions",false],
	["res://scenes/night07.tscn","Night7Options",false]
]
var failures := 0

func check(ok: bool,label: String) -> void:
	if not ok:
		failures += 1
		printerr("Shared menus and accessibility: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var original := FileAccess.file_exists(Prefs.PATH)
	var settings_text := ""
	if original:
		var file := FileAccess.open(Prefs.PATH,FileAccess.READ)
		if file != null:
			settings_text = file.get_as_text()
			file.close()
	var previous_sizes := []
	for i in range(SCENES.size()):
		var item: Array = SCENES[i]
		var packed := load(str(item[0])) as PackedScene
		check(packed != null,"packaged chapter " + str(i) + " exists")
		if packed == null:
			continue
		var chapter := packed.instantiate()
		root.add_child(chapter)
		await process_frame
		var panel := chapter.find_child(str(item[1]),true,false) as PanelContainer
		check(panel != null,"chapter %d has the same canonical Options panel" % i)
		if panel != null:
			var columns := panel.find_child("Columns",true,false) as HBoxContainer
			check(columns != null,"chapter %d shares responsive two-column menu" % i)
			var prefs_col := panel.find_child("OptionsContent",true,false) as VBoxContainer
			var action_col := panel.find_child("ActionStack",true,false) as VBoxContainer
			check(prefs_col != null and action_col != null,
				"chapter %d has organized settings and save navigation" % i)
			for key in SharedOptions.ORDER:
				var button_name: String = SharedOptions.NAMES[str(key)]
				var button := panel.find_child(button_name,true,false) as Button
				check(button != null,"chapter %d missing setting %s" % [i,str(key)])
				if button != null:
					check(button.get_signal_connection_list("pressed").size() > 0,
						"chapter %d setting %s is clickable" % [i,str(key)])
					check(button.get_theme_stylebox("normal") is StyleBoxFlat,
						"chapter %d setting %s has canonical navy/gold style" % [i,str(key)])
					check(button.custom_minimum_size.y >= 63.0,
						"chapter %d setting %s has Android touch target" % [i,str(key)])
			var back := panel.find_child("CloseSettings",true,false) as Button
			check(back != null,"chapter %d has Back button" % i)
			if i > 0:
				for name in ["SaveProgress","FieldNotes","SaveAndMainMenu","QuitGame"]:
					var btn := panel.find_child(name,true,false) as Button
					check(btn != null,"Night %d missing %s" % [i,name])
					if btn != null:
						check(btn.get_signal_connection_list("pressed").size()>0,
							"Night %d %s must work" % [i,name])
			else:
				# This is the same pref object saved and read across all chapters.
				var button := panel.find_child("PrefText",true,false) as Button
				if button != null:
					var before: float = float((chapter.get("prefs") as RefCounted).get("text_scale"))
					button.pressed.emit()
					check(float((chapter.get("prefs") as RefCounted).get("text_scale")) != before,
						"title settings actually change persistent text size")
					previous_sizes.append(float((chapter.get("prefs") as RefCounted).get("text_scale")))
		chapter.queue_free()
		await process_frame
		if i == 1 and previous_sizes.size()>0:
			var restored := Prefs.new()
			check(restored.load_from() and is_equal_approx(restored.text_scale,previous_sizes[0]),
				"title setting follows player into Night 1")
	if original:
		var file := FileAccess.open(Prefs.PATH,FileAccess.WRITE)
		if file != null:
			file.store_string(settings_text)
			file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Prefs.PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Prefs.PATH+".tmp"))
	print("Menu consistency and common settings (title + Night 1-7): ",
		"PASS" if failures==0 else str(failures)+" failures")
	quit(0 if failures==0 else 1)
