extends SceneTree
## Godot 4.3 low-uniform GLES3 / SwiftShader shader-link regression.
## Offscreen camera math and 3D physics stay live while native 3D pixels
## are disabled; the real 2.5D CanvasItem fallback owns the visual output.
const Policy = preload("res://scripts/visuals/android_renderer_policy.gd")
const Fallback = preload("res://scripts/visuals/software_world_fallback.gd")
var failures := 0

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("Android GPU policy regression: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	check(Policy.needs_software_draw("Google SwiftShader 4.0.0.1"),
		"SwiftShader GPU requires software 2.5D drawing")
	check(Policy.needs_software_draw("Android Emulator OpenGL ES Translator"),
		"legacy Android emulator vendor names are also recognized")
	for gpu in ["Adreno (TM) 610","Mali-G57","PowerVR Rogue","Apple M3"]:
		check(not Policy.needs_software_draw(gpu),
			"physical GPU must not lose native Night 1 3D rendering: " + gpu)
	check(Fallback.needs_software_draw("Google SwiftShader")
		== Policy.needs_software_draw("Google SwiftShader"),
		"fallback and viewport share one adapter policy")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280,720)
	root.add_child(viewport)
	check(Policy.configure_viewport(viewport, "Google SwiftShader"),
		"software viewport is configured")
	check(viewport.disable_3d,"SwiftShader 3D framebuffer actually disabled")
	var camera := Camera3D.new()
	camera.position = Vector3(12,15,12)
	viewport.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var projected: Vector2 = camera.unproject_position(Vector3.ZERO)
	check(projected.is_finite(),
		"Camera3D still projects real world locations for the live Canvas fallback")
	var body := CharacterBody3D.new()
	body.name = "LivePhysicsActor"
	viewport.add_child(body)
	var shape := CollisionShape3D.new()
	shape.shape = CapsuleShape3D.new()
	body.add_child(shape)
	check(body.is_inside_tree() and shape.shape != null,
		"3D collision nodes remain live while the viewport only draws 2D")
	check(not Policy.configure_viewport(viewport,"Adreno (TM) 610")
		and not viewport.disable_3d,
		"native Android GPU re-enables full Night 1 3D shading")
	viewport.free()
	var title := FileAccess.get_file_as_string("res://scripts/ui/title_screen.gd")
	var night1 := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(title.contains("RendererPolicy.configure_viewport(get_viewport(),adapter)")
		and night1.contains("RendererPolicy.configure_viewport(get_viewport(),adapter)"),
		"both title and Night 1 block broken shaders BEFORE 3D scene rendering")
	print("Android GPU policy regression: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
