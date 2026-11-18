extends RefCounted
## Connected village life after the seventh-night epilogue.
## All schedules use the same saved clock; NPCs do not reappear outdoors at night.
## These are ambient witnesses, not extra quest targets or duplicated rewards.
const Depth = preload("res://scripts/visuals/layered_25d.gd")
const FISHER: Texture2D = preload("res://assets/characters/post_fisher.svg")
const MARKET: Texture2D = preload("res://assets/characters/post_market.svg")
const TRAIL: Texture2D = preload("res://assets/characters/post_trail.svg")

const ACTORS := {
	"old_mango": [
		{"id":"grove_keeper","job":"trail","at":Vector2(-400,260),"rest":Vector2(-600,382),"home":Vector2(-604,405)},
		{"id":"school_helper","job":"school","at":Vector2(-540,-270),"rest":Vector2(-455,-110),"home":Vector2(-608,-420)}
	],
	"night03": [
		{"id":"ridge_caretaker","job":"trail","at":Vector2(-265,-170),"rest":Vector2(-140,-260),"home":Vector2(-175,-280)},
		{"id":"bamboo_gatherer","job":"farm","at":Vector2(180,365),"rest":Vector2(-265,190),"home":Vector2(-180,285)}
	],
	"night04": [
		{"id":"wake_neighbour","job":"community","at":Vector2(-330,225),"rest":Vector2(-225,140),"home":Vector2(-450,-140)},
		{"id":"courtyard_repairer","job":"repair","at":Vector2(388,120),"rest":Vector2(155,230),"home":Vector2(90,-115)}
	],
	"night05": [
		{"id":"animal_keeper","job":"animals","at":Vector2(520,300),"rest":Vector2(-535,275),"home":Vector2(-740,-105)},
		{"id":"farm_helper","job":"farm","at":Vector2(-320,350),"rest":Vector2(-575,290),"home":Vector2(-740,-105)}
	],
	"night06": [
		{"id":"river_fisher","job":"fish","at":Vector2(-350,188),"rest":Vector2(-620,-155),"home":Vector2(-580,-155)},
		{"id":"archive_helper","job":"community","at":Vector2(-710,-70),"rest":Vector2(-480,-240),"home":Vector2(-605,-250)},
		{"id":"river_repairer","job":"repair","at":Vector2(415,120),"rest":Vector2(342,-165),"home":Vector2(360,-230)}
	]
}
const CONVERSATION := {
	"grove_keeper":"The old mango path is open for travellers again. We still mark the exposed roots so no one is hurt.",
	"school_helper":"Mara's school has lessons again. We teach the children the real flood routes, not frightening rumours.",
	"ridge_caretaker":"The ridge markers tell the truth now. We replace washed-out signs before the next heavy rain.",
	"bamboo_gatherer":"I only gather bamboo from the safe side. The old tree and ridge deserve respect.",
	"wake_neighbour":"We remember the departed, but the family can sit together in daylight now.",
	"courtyard_repairer":"The wake-house shutters are sound again. Nobody should have to stand watch alone.",
	"animal_keeper":"The goats and chickens stay in their safe paddock. We inspect the gate every morning.",
	"farm_helper":"The farm paths are clear now. We still avoid the unstable old barn.",
	"river_fisher":"I cast my net at sunrise. The river feeds our families again, but we still watch the weather.",
	"archive_helper":"The flood record stays open so the next generation can learn, without exposing private witnesses.",
	"river_repairer":"The new rope and landing boards help everyone cross safely. We remember who never returned."
}

static func _clock(scene: Node) -> Node:
	var clock := scene.get_node_or_null("/root/PostgameClock")
	return clock if clock != null and clock.is_active() else null

static func schedule(clock: Node) -> String:
	if clock == null:
		return "story"
	var hour: float = clock.fraction() * 24.0
	if hour < 5.5 or hour >= 19.5:
		return "sleep"
	if hour < 10.75:
		return "morning"
	if hour < 14.0:
		return "market"
	if hour < 17.75:
		return "afternoon"
	return "home"

static func activity_position(actor: Dictionary, period: String, seconds: float = 0.0) -> Vector2:
	var at: Vector2 = actor["at"]
	match period:
		"morning", "afternoon":
			# Deliberate small steps, not wandering over clues or across roads.
			at += Vector2(sin(seconds * 0.50 + at.x * .01) * 15.0, absf(cos(seconds * .48 + at.y * .02)) * 5.0)
		"market":
			at = actor["rest"]
		"home":
			at = actor["home"]
	return at

static func nearby(scene: Node, region: String, player_at: Vector2) -> String:
	var clock := _clock(scene)
	var period := schedule(clock)
	if period in ["sleep", "home", "story"]:
		return ""
	for person in ACTORS.get(region, []):
		if player_at.distance_to(activity_position(person, period)) <= 114.0:
			return "postgame:" + str(person["id"])
	return ""

static func talk(scene: Node, target: String) -> String:
	if _clock(scene) == null or not target.begins_with("postgame:"):
		return ""
	var key := target.trim_prefix("postgame:")
	var village_clock := _clock(scene)
	if village_clock != null and village_clock.village_mood == "healing" and key == "river_fisher":
		return "The old crossing is still watched carefully. I help mend the landing until it is safe to cast the nets."
	return str(CONVERSATION.get(key, ""))

static func speaker(target: String) -> String:
	return target.trim_prefix("postgame:").replace("_", " ").to_upper()

static func paint(scene: Node2D, region: String, seconds: float, reduced_motion: bool, player_at: Vector2) -> void:
	var clock := _clock(scene)
	if clock == null:
		return
	var period := schedule(clock)
	if period in ["sleep", "story"]:
		return
	var confidence: String = str(clock.get("village_mood"))
	for person in ACTORS.get(region, []):
		var at := activity_position(person, period, 0.0 if reduced_motion else seconds)
		var job: String = str(person["job"])
		if confidence == "healing" and region == "night06" and str(person["id"]) == "river_fisher":
			job = "repair"
		if period == "home":
			continue # At home, the authored house window lights represent residents.
		var id: String = str(person["id"])
		_paint_work(scene, job, at, period, confidence, seconds, reduced_motion)
		var image := _sprite_for(job, id)
		var tint := Color.WHITE
		if job == "trail": tint = Color("#ded7bd")
		if job == "community": tint = Color("#f1dac8")
		if job == "repair": tint = Color("#d6d9d0")
		var bob := 0.0 if reduced_motion else absf(sin(seconds * .95 + at.x)) * 1.6
		Depth.paint_grounded(scene, image, at, Vector2(95,132), tint, .34, bob)
		if player_at.distance_to(at) < 158.0:
			# Only a proximity cue; never add HUD panels or cover chapter controls.
			scene.draw_string(ThemeDB.fallback_font, at + Vector2(-64,-157),
				"INTERACT • " + speaker("postgame:" + id), HORIZONTAL_ALIGNMENT_CENTER,
				290, 16, Color("#f0dfa9"))

static func _sprite_for(job: String, actor_id: String) -> Texture2D:
	if job == "fish" or actor_id == "animal_keeper":
		return FISHER
	if job == "school" or job == "community" or actor_id == "farm_helper":
		return MARKET
	return TRAIL

static func _paint_work(scene: Node2D, job: String, at: Vector2, period: String,
		confidence: String, seconds: float, reduced_motion: bool) -> void:
	var wood := Color("#a1835f")
	if period == "market":
		# Work shifts visibly include a market/rest stop, not frozen idle villagers.
		scene.draw_rect(Rect2(at + Vector2(-72,-12), Vector2(68,21)), Color("#76523c"))
		scene.draw_rect(Rect2(at + Vector2(-69,-24), Vector2(62,12)), Color("#c5a169"))
		for i in range(3):
			scene.draw_circle(at + Vector2(-59 + i * 19,-27), 7, Color("#9d9e4c"))
		return
	match job:
		"fish":
			var tip := at + Vector2(70,-78)
			var float_pos := at + Vector2(112,104)
			scene.draw_line(at + Vector2(14,-59), tip, wood, 4.0, true)
			scene.draw_line(tip, float_pos, Color("#d7caaa"),1.5,true)
			scene.draw_circle(float_pos, 5, Color("#eec28d"))
			scene.draw_rect(Rect2(at+Vector2(-60,-21),Vector2(37,19)),Color("#a17d54"))
			scene.draw_rect(Rect2(at+Vector2(-60,-21),Vector2(37,19)),Color("#5b4534"),false,2)
		"farm", "animals":
			for i in range(3):
				var leaf := at + Vector2(-53+i*22,21)
				scene.draw_line(leaf, leaf+Vector2(0,-27), Color("#527b4d"),3,true)
				scene.draw_circle(leaf+Vector2(-5,-25),7,Color("#779767"))
			if job == "animals":
				scene.draw_rect(Rect2(at+Vector2(-69,6),Vector2(36,24)),Color("#a07c51"))
		"repair", "trail":
			scene.draw_line(at+Vector2(-57,19), at+Vector2(-57,-31), wood,5,true)
			scene.draw_line(at+Vector2(-85,-31), at+Vector2(-30,-31),Color("#ccb28a"),7,true)
			if not reduced_motion:
				var hammer := at+Vector2(-23,-82+sin(seconds*2.0)*6)
				scene.draw_line(hammer, hammer+Vector2(-14,27),Color("#8b6240"),3,true)
				scene.draw_line(hammer+Vector2(-14,-3),hammer+Vector2(8,7),Color("#7e8581"),5,true)
		"school", "community":
			scene.draw_rect(Rect2(at + Vector2(-67,-27), Vector2(48,32)), Color("#d3bf8c"))
			scene.draw_rect(Rect2(at + Vector2(-67,-27), Vector2(48,32)), Color("#725740"),false,3)
			scene.draw_line(at+Vector2(-43,-10),at+Vector2(-18,-10),Color("#6f6655"),2)
	# Partial endings keep repairs and support work; no unearned festival props.
	if confidence == "healing" and job in ["trail","repair"]:
		scene.draw_line(at + Vector2(-77,29), at + Vector2(-12,29), Color("#c2a67b"), 3,true)
