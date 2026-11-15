extends RefCounted
## Deterministic 1-meter grid used by the initial Barrio Lawom blockout.
## Route safety is conservative: no river cells, house footprints, or tree trunks.
## Replace with baked navmesh when the authored environment replaces blockout art.

const X_MIN := -9
const X_MAX := 22
const Z_MIN := -22
const Z_MAX := 22
var grid: AStarGrid2D


func _init() -> void:
	grid = AStarGrid2D.new()
	grid.region = Rect2i(X_MIN, Z_MIN, X_MAX - X_MIN + 1, Z_MAX - Z_MIN + 1)
	grid.cell_size = Vector2.ONE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	# Buildings with a conservative margin around the actual collision footprint.
	_block_rect(3, 9, 2, 8) # Lola's hut (6,5)
	_block_rect(4, 10, -11, -5) # Sabel's store (7,-8)
	_block_rect(-5, 1, -15, -9) # School (-2,-12)
	# Solid tree trunks including a margin for Bantay's body.
	for x in [13, 19]:
		for z in [-18, -5, 14]:
			_block_rect(x - 1, x + 1, z - 1, z + 1)


func _block_rect(x0: int, x1: int, z0: int, z1: int) -> void:
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			var cell := Vector2i(x, z)
			if grid.is_in_boundsv(cell):
				grid.set_point_solid(cell, true)


func cell_for(world: Vector3) -> Vector2i:
	return Vector2i(roundi(world.x), roundi(world.z))


func is_safe(world: Vector3) -> bool:
	var cell := cell_for(world)
	return grid.is_in_boundsv(cell) and not grid.is_point_solid(cell)


func route(from_world: Vector3, to_world: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	var start := _closest_safe(cell_for(from_world))
	var goal := _closest_safe(cell_for(to_world))
	if start == Vector2i(-999, -999) or goal == Vector2i(-999, -999):
		return result
	for point in grid.get_id_path(start, goal):
		result.append(Vector3(float(point.x), 0.45, float(point.y)))
	return result


func _closest_safe(cell: Vector2i) -> Vector2i:
	# Limit the search. No unsafe teleporting across the river or through walls.
	for radius in range(0, 7):
		for dx in range(-radius, radius + 1):
			for dz in range(-radius, radius + 1):
				var test_cell := cell + Vector2i(dx, dz)
				if grid.is_in_boundsv(test_cell) and not grid.is_point_solid(test_cell):
					return test_cell
	return Vector2i(-999, -999)
