extends SceneTree
## Shared real 3D window geometry + quiet-night cast across the four chapters.
const Windows = preload("res://scripts/visuals/nighttime_windows.gd")
const Game = preload("res://scenes/main.tscn")
var errors := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		errors += 1
		printerr("Night lighting: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	check(Windows.STYLE_ID == "shared-lived-in-night-v1","shared lighting module loaded")
	check(Windows.interior_strength(0) > Windows.interior_strength(1)
		and Windows.interior_strength(1) > Windows.interior_strength(3)
		and Windows.interior_strength(3) > Windows.interior_strength(2),
		"occupied home, wake, lookout and closed school differ")
	for chapter in range(1,5):
		check(Windows.outdoor_actor_visible(chapter,0,"NENA"),"day residents visible")
		check(not Windows.outdoor_actor_visible(chapter,3,"SABEL"),"no midnight street crowds")
		check(Windows.outdoor_actor_visible(chapter,3,"HERO")
			and Windows.outdoor_actor_visible(chapter,3,"BANTAY"),"party stays visible")
		check(Windows.outdoor_actor_visible(chapter,3,"MANANANGGAL"),"creature never hidden")
	var game = Game.instantiate()
	root.add_child(game)
	await process_frame
	var village := game.get_node_or_null("BarrioEnvironmentDetails") as Node3D
	check(village != null,"original physical house meshes present")
	if village != null:
		var houses := ["Lola woven home","Sabel riverside store","Mara schoolhouse"]
		for i in range(houses.size()):
			var house := village.get_node_or_null(str(houses[i])) as Node3D
			check(house != null,"original 3D building intact")
			if house == null:
				continue
			var glass := house.get_node_or_null("Dark window") as MeshInstance3D
			check(glass != null,"original wall-mounted glass intact")
			Windows.sync_barrio_3d(game,true,0.0,true)
			if glass != null:
				var mat := glass.material_override as StandardMaterial3D
				check(mat != null and mat.emission_enabled == (i < 2),
					"night lights only inhabited buildings")
			var lamp := house.get_node_or_null("NightWindowAmberSpill") as OmniLight3D
			check((lamp != null) == (i < 2),"max two mobile-friendly Omni lights")
			if lamp != null:
				check(lamp.visible and lamp.light_energy > 0.05,"actual nighttime exterior spill")
			Windows.sync_barrio_3d(game,false,0.0,true)
			if glass != null:
				check(not (glass.material_override as StandardMaterial3D).emission_enabled,
					"sunrise deactivates window emission")
			if lamp != null:
				check(not lamp.visible,"sunrise deactivates light")
			Windows.sync_barrio_3d(game,true,1.0,false)
			Windows.sync_barrio_3d(game,true,2.0,false)
			var count := 0
			for child in house.get_children():
				if child.name == "NightWindowAmberSpill":
					count += 1
			check(count == (1 if i < 2 else 0),"no duplicated light on animation tick")
	game.queue_free()
	await process_frame
	print("Nights 1–4 lived-in windows and safe nighttime crowd: ",
		"PASS" if errors == 0 else str(errors)+" failures")
	quit(0 if errors == 0 else 1)
