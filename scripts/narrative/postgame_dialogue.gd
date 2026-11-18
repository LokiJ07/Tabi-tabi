extends RefCounted
## After the seventh-night epilogue, witnesses reflect what the player learned.
## Sabel's remembrance consent and Dado's privacy survive across regions.
const RiverState = preload("res://scripts/narrative/night06_state.gd")
const RiverSave = preload("res://scripts/core/night06_save.gd")

static func conversation(role: String, village_mood: String) -> String:
	var flood = RiverState.new()
	var verified: bool = RiverSave.read(flood)
	var still_healing := village_mood != "restored"
	match role:
		"DADO":
			if verified and flood.dado_choice == "decline":
				return "The river is quieter. Salamat for letting me choose what I could share. I help with the nets these mornings."
			return "I return to the landing at first light. We keep the flood records honest, and no survivor must be forced to speak."
		"SABEL":
			if verified and flood.sabel_public_choice == "consent_public":
				return "We made a place to remember the rescuer, with our family's permission. Now the market is opening again."
			return "I am tending the shop again. My family still decides which memories stay private. Thank you for respecting that."
		"MARA":
			if still_healing:
				return "The children are learning the repaired routes. The story of the flood needs care; not every family's questions are settled."
			return "School is open. We teach the children how to read the real flood maps and respect the forest and river."
		"LOLA":
			if still_healing:
				return "Knowing the truth is only a beginning. We must live honestly with what was lost, and still protect one another."
			return "The promise of remembrance now belongs to everyone, not to one keeper. Look how the village has begun living again."
		"NENA":
			return "We remember the wake together. The doors are repaired, and nobody has to keep watch by themselves."
	return "The village is still learning how to live with its history."
