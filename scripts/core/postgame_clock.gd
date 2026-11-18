extends Node
## One shared in-game clock for the post-finale free-roam world.
## Story nights remain authored/scripted until the Night 7 epilogue is finished.
const World = preload("res://scripts/core/connected_world.gd")
const FULL_DAY_SECONDS := 24.0 * 60.0
const SAVE_INTERVAL_SECONDS := 15.0
const START_FRACTION := 0.29 # 06:58 on the first peaceful morning.
signal light_changed(stage: int)

var village_mood := "healing"
var _active := false
var _fraction := START_FRACTION
var _unsaved_seconds := 0.0

func _ready() -> void:
	refresh()

func refresh() -> void:
	var ledger: Dictionary = World.read()
	_active = World.is_postgame(ledger)
	if _active:
		var endings: Dictionary = ledger.get("outcomes", {})
		var final_outcome: String = str(endings.get("night07", "")).to_lower()
		village_mood = "restored" if final_outcome in ["resolve","reconcile","peaceful","renewal"] else "healing"
		_fraction = fposmod(clampf(float(ledger.get("postgame_time", START_FRACTION)), 0.0, 1.0), 1.0)
	_unsaved_seconds = 0.0

func is_active() -> bool:
	return _active

func fraction() -> float:
	return _fraction

func light_stage() -> int:
	# 0 day, 1 dawn/dusk, 2 twilight, 3 true night.
	if _fraction >= 0.82 or _fraction < 0.15:
		return 3
	if _fraction >= 0.75 or _fraction < 0.20:
		return 2
	if _fraction >= 0.68 or _fraction < 0.25:
		return 1
	return 0

func is_night() -> bool:
	return light_stage() >= 2

func clock_label() -> String:
	var minutes: int = int(floor(_fraction * 1440.0)) % 1440
	return "%02d:%02d" % [minutes / 60, minutes % 60]

func _process(delta: float) -> void:
	if not _active:
		return
	var before := light_stage()
	_fraction = fposmod(_fraction + maxf(delta, 0.0) / FULL_DAY_SECONDS, 1.0)
	if light_stage() != before:
		light_changed.emit(light_stage())
	_unsaved_seconds += maxf(delta, 0.0)
	if _unsaved_seconds >= SAVE_INTERVAL_SECONDS:
		save_clock()

func save_clock() -> bool:
	if not _active:
		return false
	var ledger: Dictionary = World.read()
	if not World.is_postgame(ledger):
		_active = false
		return false
	ledger["postgame_time"] = _fraction
	var saved := World.write(ledger)
	if saved:
		_unsaved_seconds = 0.0
	return saved

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_clock()
