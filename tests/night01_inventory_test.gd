extends SceneTree
const Kit = preload("res://scripts/items/night01_inventory.gd")
var fails := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		printerr("Kit failure: " + message)
func _run() -> void:
	var kit = Kit.new()
	check(kit.is_ready(), "four equipment defaults")
	check(kit.has("signal_bell"), "defensive item available in default kit")
	check(not kit.toggle("invented_item"), "unknown item refused")
	check(not kit.toggle("spare_wick"), "no fifth slot")
	check(kit.toggle("rope"), "remove equipped item")
	check(not kit.is_ready(), "three slots not prepared")
	check(kit.toggle("dog_treat"), "new choice fits empty slot")
	check(kit.is_ready(), "four slots restored")
	check(kit.consume("cloth_wrap"), "first legitimate use")
	check(not kit.consume("cloth_wrap"), "no repeated use")
	check(not kit.consume("rope"), "cannot use unequipped item")
	var persisted = Kit.new()
	check(persisted.from_dict(kit.to_dict()), "load valid save")
	check(persisted.has("dog_treat") and not persisted.has("rope"), "selection persists")
	check(persisted.is_used("cloth_wrap"), "use tracked across reload")
	check(persisted.from_dict({"selected": ["signal_bell", "signal_bell", "foreign", "cloth_wrap"], "used": {"foreign": true}}), "legacy or invalid entries sanitized")
	check(persisted.selected.size() == 2, "dedupe and filter")
	check(not persisted.from_dict({"selected": "bad"}), "invalid selection rejected")
	print("Night 1 equipment tests: ", "PASS" if fails == 0 else str(fails) + " failures")
	quit(0 if fails == 0 else 1)
