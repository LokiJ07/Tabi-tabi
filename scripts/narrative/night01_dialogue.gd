extends RefCounted
## Night 1 witness dialogue: deterministic, non-linear, privacy-aware.
## Dialogue is not an evidence grant on its own; established observations remain explicit.

static func response(who: String, story: RefCounted, is_night: bool) -> String:
	var revisiting: bool = story.seen_people.has(who.to_lower())
	match who:
		"LOLA":
			if story.outcome != "":
				return "LOLA PASING: Salamat nga nakauli ka. Ang mga nahitabo sa suba adunay mga kasunod nga epekto."
			if story.has_complete_evidence():
				return "LOLA PASING: Nakakuha ka sa tulo ka timailhan. Dili tanan kahayag peligro. Pangutan-a ang imong nahibaloan, dili ang imong kahadlok."
			return "LOLA PASING: Ayaw una isulat ang imong gituohan. Paminaw sa, dayon pangita og pamatuod."
		"DADO":
			if revisiting:
				return "TATAY DADO: Mao ra ang akong nakita: mosibog ang kahayag kon tutokan. Wala ko kahibalo kon unsa gyud siya."
			return "TATAY DADO: Gamay nga kahayag. Kung akong tutokan, mosibog. Kung molingi ko, murag naghulat."
		"SABEL":
			if story.seen_people.has("privacy_agreed"):
				return "ALING SABEL: Salamat. Ang istorya sa pamilya kinahanglan dili himuong tsismis."
			return "ALING SABEL: Usa ka boatman si Mang Celso. Ayaw ipakaylap ang mga detalye sa iyang pamilya. Ang respeto dili baligya."
		"MARA":
			if story.clues.has("old_mooring"):
				if revisiting:
					return "TEACHER MARA: Balika ang duha ka ebidensya: ang karaang mooring ug ang pangalan sa ledger. Ayaw pagpasaka og konklusyon nga walay pagsusi."
				return "TEACHER MARA: Sa karaang ledger, Mang Celso ang boatman. Ang dokumento makatabang, apan dili pa kini pamatuod sa unsay kahayag."
			return "TEACHER MARA: Susiha una ang karaang mooring. Ikumpara ang lugar sa ledger ug istorya sa mga saksi."
		"MOORING":
			return "The mooring bears worn rope marks. At night, a wavering light lingers beyond the safe bank." if is_night else "A weathered mooring. Old rope fibers and water marks suggest years of use."
	return "No new information. Observe the surroundings."
