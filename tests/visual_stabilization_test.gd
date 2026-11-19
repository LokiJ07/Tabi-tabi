extends SceneTree
## Regression from real Android Night 2 and Night 6 screenshots, 19 Nov 2026.
## A green APK cannot stand in for real-world labels and correctly grounded art.
const HUD = preload("res://scripts/ui/shared_hud.gd")
const Night02 = preload("res://scripts/night02_main.gd")
var failures := 0

func check(ok: bool, title: String) -> void:
	if not ok:
		failures += 1
		printerr("Android visual stabilization: " + title)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var overlay := Control.new()
	root.add_child(overlay)
	var prompt := HUD.make_nearby_prompt(overlay)
	check(not prompt.visible and prompt.text == "",
		"blank Night 6 nearby prompt must never draw an empty dark panel")
	HUD.set_nearby_prompt_text(prompt,"INTERACT • RESCUE ORDER")
	check(prompt.visible and prompt.text == "INTERACT • RESCUE ORDER",
		"real nearby action restores the same shared chip")
	HUD.set_nearby_prompt_text(prompt,"  ")
	check(not prompt.visible,
		"leaving an interaction removes the empty chip across all nights")
	HUD.set_nearby_prompt_text(prompt,"FOLLOW THE VISIBLE PATH")
	check(prompt.visible,"route guidance reappears when meaningful")
	overlay.free()

	var kapre := Night02.new()
	kapre.player_pos = Vector2(0,0)
	kapre.dog_pos = Vector2(290,0)
	check(not kapre._world_label_clear(Vector2(-40,-30),160),
		"floating Kapre route text must not cross the apprentice's silhouette")
	check(not kapre._world_label_clear(Vector2(275,-25),150),
		"floating Kapre route text must not cross Bantay")
	check(kapre._world_label_clear(Vector2(1050,1000),220),
		"wayfinding text remains legible when actors move away")
	kapre.free()

	var night06_src := FileAccess.get_file_as_string("res://scripts/night06_main.gd")
	check(night06_src.contains("Shadow follows the FOUR wall-foot vertices")
		and night06_src.contains("draw_colored_polygon(PackedVector2Array(["),
		"Night 6 building shadows stay beneath projected walls rather than making dark circles")
	check(not night06_src.contains("draw_circle(foot+Vector2(10,5),w*.48"),
		"Night 6 huge opaque circle behind villagers cannot regress")
	check(night06_src.contains("Carved wooden source marker")
		and not night06_src.contains("draw_circle(at-Vector2(0,20),20"),
		"river evidence must appear as grounded documentary markers, not eye-shaped circles")
	var night05_src := FileAccess.get_file_as_string("res://scripts/night05_main.gd")
	check(night05_src.contains("func _paint_east_foothills()")
		and night05_src.contains("_paint_east_foothills()")
		and night05_src.contains("var hillside := Rect2(930,-900,1080,1770)"),
		"Night 5 eastern road cannot terminate in unpainted flat green scenery")
	check(night05_src.contains("const MAP := Rect2(-1120,-790,2240,1590)")
		and night05_src.contains("const FUTURE_TRAIL := Vector2(955,-470)"),
		"Night 5 terrain polish preserves real walkability bounds and Night 6 gate")
	var night04_src := FileAccess.get_file_as_string("res://scripts/night04_main.gd")
	check(night04_src.contains("Imported nipa-thatch texture follows BOTH real sloping roof planes")
		and night04_src.contains("roof_uv,NIPA"),
		"Night 4 lamay roof retains dimensional nipa material on its two planes")
	for night in range(2,8):
		var source := FileAccess.get_file_as_string(
			"res://scripts/night%02d_main.gd" % night)
		check(source.contains("SharedHUD.set_nearby_prompt_text(interaction_hint,"),
			"Night %d must use the same hide-empty prompt setter" % night)
	print("Visual stabilization regression: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
