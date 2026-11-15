extends SceneTree
const Conversations = preload("res://scripts/narrative/conversation_pages.gd")
const Portrait = preload("res://scripts/ui/speaker_portrait.gd")
const Actors = preload("res://scripts/visuals/folk_actors.gd")
const GameScene = preload("res://scenes/main.tscn")
var errors := 0

func _initialize() -> void:
	call_deferred("_run")


func check(value: bool, message: String) -> void:
	if not value:
		errors += 1
		printerr("Cinematic conversation: " + message)


func _run() -> void:
	var pages: Array[Dictionary] = Conversations.parse("APPRENTICE: Bantay woke me.\nLOLA: Kaon sa.\nAyaw pagdali.")
	check(pages.size() == 2, "two distinct speaker pages parsed")
	check(pages[0]["speaker"] == "APPRENTICE", "first speaker identified")
	check(pages[1]["speaker"] == "LOLA", "second speaker identified")
	check(str(pages[1]["text"]).find("Ayaw pagdali") >= 0, "continuation belongs to Lola")
	check(Conversations.parse("Morning: the bank is quiet.")[0]["speaker"] == "NARRATOR", "colon narrative not accidentally NPC")
	check(Conversations.display_name("MARA") == "TEACHER MARA", "consistent displayed name")

	var portrait: Control = Portrait.new()
	root.add_child(portrait)
	portrait.call("set_speaker", "TATAY DADO")
	check(portrait.speaker_id == "DADO", "portrait resolves fisher identity")
	portrait.call("set_speaker", "TEACHER MARA")
	check(portrait.speaker_id == "MARA", "portrait switches speaker")
	var profiles := {}
	for role in ["LOLA", "DADO", "MARA", "SABEL", "APPRENTICE"]:
		var profile: Dictionary = Portrait.portrait_identity(role)
		check(profile["id"] == role, role + " fixed illustrated identity")
		check(profile["shirt"] == Actors.identity(role)["shirt"], role + " portrait costume matches in-world actor")
		var geometry := str(profile["face_width"]) + ":" + str(profile["face_height"]) + ":" + str(profile["eye_spacing"])
		check(not profiles.has(geometry), role + " has its own recognizable face proportions")
		profiles[geometry] = true
	check(Conversations.parse("A quiet ledger.", "MARA")[0]["speaker"] == "MARA", "unattributed witness dialogue uses correct speaker identity")
	check(Conversations.parse("NARRATOR: The notebook rests on the desk.")[0]["text"] == "The notebook rests on the desk.", "narrator label stripped from object description")
	check(Conversations.parse("A worn rope.", "MOORING")[0]["speaker"] == "NARRATOR", "landscape clue has no invented speaking face")
	portrait.queue_free()

	var game = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	game._close_dialogue()
	game._show_dialogue("APPRENTICE: Bantay woke me.\nLOLA: Kaon sa.")
	check(game.dialogue.visible, "conversation panel visible")
	check(game.dialogue_pages.size() == 2, "both lines queued")
	check(game.dialogue_portrait.speaker_id == "APPRENTICE", "player head-and-shoulders first")
	check(game.dialogue_portrait.visible, "named speaker has a visible portrait")
	check(game.dialogue_speaker.text.find("APPRENTICE") >= 0, "player speaking heading")
	check(not game.gameplay_hud.visible, "cinematic mode temporarily hides gameplay controls")
	check(game.modal_backdrop.color.a < 0.5, "cinematic world remains visible behind portrait")
	check(game.dialogue.get_node_or_null("DialogueLayout/DialogueScroll/PortraitAndText/SpeakerBustPortrait") != null, "portrait is part of rendered dialogue layout")
	game._interact()
	check(game.dialogue_portrait.speaker_id == "LOLA", "interact advances to Lola portrait")
	check(game.dialogue_speaker.text.find("LOLA PASING") >= 0, "speaker name updates with portrait")
	check(game.dialogue.visible, "conversation stays open for second speaker")
	game._advance_dialogue()
	check(not game.dialogue.visible, "last speaker Continue closes conversation")
	check(game.gameplay_hud.visible, "world HUD returns after conversation")
	game._show_dialogue("A weathered journal with a name.", "MOORING")
	check(game.dialogue_speaker.text.find("BARRIO LAWOM") >= 0, "object description is narrator, not a random villager")
	check(not game.dialogue_portrait.visible, "narrator/object interaction does not reuse generic human face")
	game._show_dialogue("A handwritten ledger shows Mang Celso.", "MARA")
	check(game.dialogue_portrait.speaker_id == "MARA" and game.dialogue_portrait.visible, "Mara's unlabeled line uses Mara's unique portrait")
	game._show_dialogue("TATAY DADO: I saw the light.")
	check(game.dialogue_portrait.speaker_id == "DADO", "Dado's named line never borrows Mara's face")
	game._close_dialogue()
	game.queue_free()
	print("Cinematic conversations: ", "PASS" if errors == 0 else str(errors) + " failures")
	quit(0 if errors == 0 else 1)
