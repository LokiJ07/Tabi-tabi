extends RefCounted
## Pure near-target helper: deterministic order and interaction distance.
const RANGE := 3.4
const LABELS := {
	"LOLA": "LOLA PASING",
	"DADO": "TATAY DADO",
	"MOORING": "OLD MOORING",
	"SABEL": "ALING SABEL",
	"MARA": "TEACHER MARA",
	"HUT_ENTRY": "LOLA'S HOUSE",
	"HUT_EXIT": "HUT DOOR",
	"LOLA_HOME": "LOLA PASING",
	"BLUE_NOTEBOOK": "BLUE NOTEBOOK",
	"WARM_CUP": "WARM CUP",
	"RIVER_PHOTO": "OLD RIVER PHOTO",
	"MANGO_TRAIL": "NORTH TRAIL • OLD MANGO TREE"
}

static func closest(origin: Vector3, targets: Dictionary) -> String:
	var nearest := ""
	var best := RANGE
	for id in ["LOLA", "DADO", "MOORING", "SABEL", "MARA", "HUT_ENTRY", "HUT_EXIT", "LOLA_HOME", "BLUE_NOTEBOOK", "WARM_CUP", "RIVER_PHOTO", "MANGO_TRAIL"]:
		if not targets.has(id):
			continue
		var point: Vector3 = targets[id]
		var offset := Vector2(origin.x - point.x, origin.z - point.z)
		var d := offset.length()
		if d < best:
			best = d
			nearest = id
	return nearest


static func caption(key: String) -> String:
	return "INTERACT  •  " + str(LABELS.get(key, "")) if LABELS.has(key) else ""
