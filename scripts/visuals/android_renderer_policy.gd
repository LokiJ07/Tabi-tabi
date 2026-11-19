extends RefCounted
## Android emulator GPU compatibility policy.
## Godot 4.3's GLES3 3D shader can exceed SwiftShader's fragment uniform limit.
## The software renderer already draws Night 1 with 2D CanvasItem art; keep
## its real 3D physics/AI/camera but skip unnecessary native 3D framebuffer.
## Never disable the 3D renderer on a real Adreno/Mali/PowerVR GPU.
const POLICY_ID := "swiftshader-canvas-with-3d-physics-v1"

static func needs_software_draw(adapter_name: String) -> bool:
	var gpu := adapter_name.to_lower()
	return gpu.contains("swiftshader") or gpu.contains("android emulator opengl es translator")

static func configure_viewport(viewport: Viewport, adapter_name: String) -> bool:
	if viewport == null:
		return false
	var software := needs_software_draw(adapter_name)
	# Godot Viewport.disable_3d only disables DRAWING, not PhysicsServer3D or
	# Camera3D.unproject_position, preserving gameplay with a live 2.5D canvas.
	viewport.disable_3d = software
	return software
