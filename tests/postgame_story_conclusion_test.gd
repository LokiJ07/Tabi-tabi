extends SceneTree
## Canonical Great Flood conclusion, four persistent dawn moods and all
## seven region aftermaths. Text and evidence gates are source-checked.
const End = preload("res://scripts/narrative/postgame_conclusion.gd")
var fails := 0
func check(ok: bool,reason: String) -> void:
	if not ok:
		fails+=1
		printerr("Seven-night conclusion: "+reason)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	check(End.ENDINGS.size()==4,"exactly four meaningful finale outcomes")
	check(End.REGIONS.size()==7,"seven connected world aftermaths")
	var all_verified := {"cancelled_rescue":true,"returning_boat":true,"limited_refuge":true}
	var none_verified := {}
	var flood: String=End.seven_night_revelation(all_verified)
	check(flood.contains("official second launch") and flood.contains("prioritised"),
		"former captain's real, unequal cancellation is explained")
	check(flood.contains("Sabel's missing husband") and flood.contains("never came home"),
		"independently corroborated final boat and Sabel sacrifice acknowledged")
	check(flood.contains("limited") or flood.contains("elevated Balete refuge"),
		"Keeper is physically limited, not omniscient or an all-night monster master")
	check(flood.contains("not the entire river") and flood.contains("did not choose"),
		"Keeper is not the cause of the public evacuation choice")
	var unknown: String=End.seven_night_revelation(none_verified)
	check(not unknown.contains("Corroborated survivor") and unknown.contains("need corroboration"),
		"missing evidence never becomes magically verified on a partial ending")
	check(not unknown.contains("links its rescuer") and unknown.contains("still need"),
		"uncorroborated rescuer identity remains uncertain")
	var unique_moods: Dictionary={}
	var unique_colors: Dictionary={}
	var unique_endings: Dictionary={}
	for ending in End.ENDINGS:
		var mood: String=End.mood(ending)
		var statement: String=End.outcome_message(ending)
		check(mood!="" and statement.length()>125 and not unique_moods.has(mood),
			"unique, substantive physical community future: "+ending)
		check(not unique_endings.has(statement),"ending not merely a dialog label: "+ending)
		unique_endings[statement]=true
		unique_moods[mood]=true
		var palette: Color=End.notice_color(ending)
		check(not unique_colors.has(palette.to_html()),"distinct world environmental palette: "+ending)
		unique_colors[palette.to_html()]=true
		for region in End.REGIONS:
			var local: String=End.region_after(ending,region,"partial")
			check(local.contains("Your recorded chapter outcome remains PARTIAL"),
				"postgame honours non-resolve prior chapter: "+region)
			check(local.contains(End.CHAPTERS[region]) and local.contains(statement),
				"all seven maps respond to the same one finale: "+region)
		for resident in ["mara","sabel","dado","lola","river","memorial","bantay"]:
			check(End.character_after(ending,resident,"private",true,true,true).length()>50,
				"playable epilogue resident has grounded response: "+resident+"/"+ending)
	check(End.mood("true").contains("PEACEFUL") and
		End.outcome_message("true").contains("laughter"),
		"TRUE is peaceful and hopeful, but the lost still remembered")
	check(End.mood("good").contains("QUIET") and
		End.outcome_message("good").contains("unfinished"),
		"GOOD is calm but unresolved, not secretly a second True ending")
	check(End.mood("bittersweet").contains("SAD") and
		End.outcome_message("bittersweet").contains("forgive"),
		"BITTERSWEET is grief and fractured reconciliation, not instant harmony")
	check(End.mood("dark").contains("UNEASY") and
		End.outcome_message("dark").contains("Nobody is automatically killed"),
		"DARK is unsettling, but no fabricated random death or permanent player prison")
	var private_sabel: String=End.character_after("true","sabel","private",true,true,true)
	var uncertain_sabel: String=End.character_after("true","sabel","private",true,true,false)
	check(private_sabel.contains("corroborated") and private_sabel.contains("different boatman"),
		"verified final crossing separate from Santelmo Mang Celso")
	check(uncertain_sabel.contains("still missing") and not uncertain_sabel.contains("are corroborated"),
		"family identity is never fabricated when clue is missing")
	check(End.character_after("dark","lola","private",true,false,false).contains("alive"),
		"Lola survives unless separate personal story records otherwise")
	check(End.character_after("true","lola","private",false,false,false).contains("separate human story"),
		"Lola mortality never caused by ending")
	var prior: Dictionary={}
	for n in range(1,7): prior["night%02d" % n]="partial"
	var history: String=End.long_conclusion("true",all_verified,prior)
	for region in End.REGIONS:
		check(history.contains(End.CHAPTERS[region]),
			"complete notebook joins all seven nights: "+region)
	check(history.contains("Night 1: partial") and history.contains("Night 6: partial"),
		"previous choices remain visible and immutable in the final notebook")
	check(history.contains("no forced public testimony") or history.contains("no forced"),
		"final story explicitly honours witness consent")
	print("One connected seven-night Great Flood conclusion, four distinctive village futures, seven maps and resident fates: ",
		"PASS" if fails==0 else str(fails)+" failures")
	quit(0 if fails==0 else 1)
