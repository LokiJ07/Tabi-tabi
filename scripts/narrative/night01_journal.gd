extends RefCounted
## Source-aware notebook entries: eyewitness testimony is never equivalent to
## historical documentation, and the boatman identity is not proven by Night 1.

static func lines(story: RefCounted) -> Array[String]:
	var entries: Array[String] = []
	entries.append("QUEST JOURNAL  |  DAY 1: THE RIVER LIGHT")
	if story.outcome != "":
		entries.append("Night 1 result: " + story.outcome.capitalize() + ". The barrio has changed.")
	else:
		entries.append("Investigate, compare accounts, then choose a safe night approach.")
	entries.append("")
	entries.append("PEOPLE / SOURCES")
	if story.seen_people.has("dado"):
		entries.append("DADO — firsthand witness; frightened but not certain of the cause.")
	if story.seen_people.has("mara"):
		entries.append("MARA — consulted ledger; did not witness the old flood as an adult.")
	if story.seen_people.has("sabel"):
		entries.append("SABEL — family privacy respected; her husband is NOT Mang Celso.")
	entries.append("")
	entries.append("CLUES / CONFIDENCE")
	if story.clues.has("light_retreat"):
		entries.append("SUSPECTED (witness) • Dado says strong focus makes the light retreat.")
	if story.clues.has("old_mooring"):
		entries.append("OBSERVED (place) • Worn rope and water marks at the old mooring.")
	if story.clues.has("boatman_name"):
		entries.append("CORROBORATED (ledger) • Mang Celso was a boatman; no proven spirit identity.")
	if story.clues.is_empty():
		entries.append("No clues yet. Speak to Dado, inspect the mooring, and ask Mara.")
	entries.append("")
	entries.append("DEDUCTIONS")
	entries.append("Dado + Mooring: " + ("LINKED" if story.evidence_links.has("light_mooring") else "NOT LINKED"))
	entries.append("Mooring + Ledger: " + ("LINKED" if story.evidence_links.has("ledger_mooring") else "NOT LINKED"))
	entries.append("Private theory: " + ("Guide gently" if story.hypothesis == "guide" else "Drive away" if story.hypothesis == "chase" else "Undecided") + " (revisable; not verified fact)")
	if story.bestiary.has("santelmo"):
		entries.append("")
		entries.append("CREATURES / BESTIARY")
		entries.append("Santelmo — " + str(story.bestiary["santelmo"]["result"]).capitalize() + " recorded once.")
		entries.append("Observed light behavior is established; its human identity is NOT confirmed.")
	return entries
