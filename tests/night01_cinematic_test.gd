extends SceneTree
const Conversations = preload("res://scripts/narrative/conversation_pages.gd")
const Portrait = preload("res://scripts/ui/speaker_portrait.gd")
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
	check(Portrait.PAINTED_SHEET.get_width() == 1024, "actual painted artwork imported into Godot project")
	check(Portrait.painted_region_for("LOLA") == Rect2(0, 0, 512, 512), "Lola shows own painted bust")
	check(Portrait.painted_region_for("DADO") == Rect2(512, 0, 512, 512), "Dado uses fishing portrait quadrant")
	check(Portrait.painted_region_for("MARA") == Rect2(0, 512, 512, 512), "Mara has separate glasses portrait")
	check(Portrait.painted_region_for("SABEL") == Rect2(512, 512, 512, 512), "Sabel has own purple headwrap portrait")
	check(Portrait.painted_region_for("NARRATOR").size.x == 0, "narrator retains original symbolic artwork")
	portrait.queue_free()

	var game = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	game._close_dialogue()
	game._show_dialogue("APPRENTICE: Bantay woke me.\nLOLA: Kaon sa.")
	check(game.dialogue.visible, "conversation panel visible")
	check(game.dialogue_pages.size() == 2, "both lines queued")
	check(game.dialogue_portrait.speaker_id == "APPRENTICE", "player head-and-shoulders first")
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
	game.queue_free()
	print("Cinematic conversations: ", "PASS" if errors == 0 else str(errors) + " failures")
	quit(0 if errors == 0 else 1)
