extends RefCounted
## Parses legacy single-string Night 1 dialogue into speaker-attributed pages.
## Colon-delimited narrative phrases (e.g. Morning:) are NOT falsely treated as NPCs.

const SPEAKERS := {
	"LOLA": "LOLA", "LOLA PASING": "LOLA",
	"DADO": "DADO", "TATAY DADO": "DADO",
	"MARA": "MARA", "TEACHER MARA": "MARA",
	"SABEL": "SABEL", "ALING SABEL": "SABEL",
	"APPRENTICE": "APPRENTICE", "BANTAY": "BANTAY",
	"SANTELMO": "SANTELMO", "NARRATOR": "NARRATOR"
}
const NAMES := {
	"LOLA": "LOLA PASING", "DADO": "TATAY DADO",
	"MARA": "TEACHER MARA", "SABEL": "ALING SABEL",
	"APPRENTICE": "APPRENTICE", "BANTAY": "BANTAY",
	"SANTELMO": "SANTELMO", "NARRATOR": "BARRIO LAWOM"
}


static func display_name(id: String) -> String:
	return str(NAMES.get(id, NAMES["NARRATOR"]))


static func speaker_for_context(context: String) -> String:
	# Interaction targets and speakers share a single explicit mapping.
	# Non-people are narration without a misleading generic face.
	var key := context.strip_edges().to_upper()
	if key == "LOLA_HOME":
		return "LOLA"
	return str(SPEAKERS.get(key, "NARRATOR"))


static func parse(raw: String, fallback_context: String = "NARRATOR") -> Array[Dictionary]:
	var pages: Array[Dictionary] = []
	for raw_line in raw.split("\n"):
		var line := raw_line.strip_edges()
		if line == "":
			continue
		var divider := line.find(":")
		var key := ""
		if divider >= 0 and divider < 24:
			key = line.substr(0, divider).strip_edges().to_upper()
		if SPEAKERS.has(key):
			pages.append({"speaker": SPEAKERS[key], "text": line.substr(divider + 1).strip_edges()})
		elif pages.is_empty():
			pages.append({"speaker": speaker_for_context(fallback_context), "text": line})
		else:
			var previous: Dictionary = pages[pages.size() - 1]
			previous["text"] = str(previous["text"]) + "\n" + line
			pages[pages.size() - 1] = previous
	if pages.is_empty():
		pages.append({"speaker": "NARRATOR", "text": "..."})
	return pages
