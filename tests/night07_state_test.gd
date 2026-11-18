extends SceneTree
## Seven-night final canon: no hidden Resolve-count lock, witness privacy,
## recoverable clues, fair nonfatal encounters, four ending paths and save.
const State = preload("res://scripts/narrative/night07_state.gd")
const Save = preload("res://scripts/core/night07_save.gd")
var failed := 0
func check(value: bool,why: String) -> void:
	if not value:
		failed += 1
		printerr("Keeper finale state: "+why)
func _initialize() -> void:
	call_deferred("_run")
func _prepare_all() -> RefCounted:
	var s=State.new()
	s.night06_outcome="partial"
	s.night05_outcome="partial"
	s.night04_outcome="drive_away"
	s.night03_outcome="partial"
	s.night02_outcome="retreat"
	s.night01_outcome="partial"
	s.sabel_privacy="private"
	s.previous_facts={"cancelled_rescue":true,"returning_boat":true,"limited_refuge":true}
	s.review_notebook()
	s.acknowledge_privacy()
	check(s.begin_final_trial(),"entry accepts non-resolve outcomes from all six chapters")
	s.respect_sabel()
	for id in State.FACTS:
		check(s.present_fact(id),"corroborated public history: "+id)
	for id in State.COMMITMENTS:
		check(s.confirm_commitment(id),"real community undertaking: "+id)
	check(s.acknowledge_public_record(),"public record independent from Sabel appearing")
	check(s.conclude_gathering() and s.reveal_keeper(),"Keeper hears a real community report")
	for action in State.PATH_RESPONSES:
		check(s.observe_tick(1.2,true,true),"observes safe root warning with lantern/Bantay cue")
		check(s.respond_path(action),"correct path response: "+action)
	for id in State.FACTS:
		check(s.present_truth(id),"Keeper receives explicitly documented fact: "+id)
	for action in State.AWAKENED_RESPONSES:
		check(s.observe_tick(1.2,true,true),"observes awakened Balete root warning")
		check(s.respond_awakened(action),"respond to environment not boss HP: "+action)
	return s
func _run() -> void:
	var preserved: Dictionary={}
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			preserved[path]=FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var s=State.new()
	check(not s.begin_final_trial(),"can't skip unrecorded Night 6")
	s.night06_outcome="partial"
	check(not s.begin_final_trial(),"explicit readiness and privacy choices required")
	s.review_notebook()
	check(not s.begin_final_trial(),"consent and uncertainty not assumed")
	s.acknowledge_privacy()
	check(s.begin_final_trial(),"visible readiness checkpoint admits documented partial")
	check(not s.present_fact("returning_boat"),"Keeper has no omniscient hidden human facts")
	check(not s.recover_fact("returning_boat","magic"),"only physical corroboration can recover a gap")
	check(s.recover_fact("returning_boat","archive_corrob"),"source-based recoverable final investigation")
	check(s.present_fact("returning_boat"),"recovered fact can enter meeting")
	check(not s.confirm_commitment("family_memorial"),"family memorial requires witness privacy consent")
	check(s.respect_sabel() and s.confirm_commitment("family_memorial"),
		"private Sabel remembrance never blocks community memorial")
	check(not s.conclude_gathering(),"public record isn't automatically performed")
	check(s.acknowledge_public_record() and s.conclude_gathering(),
		"community can proceed with uncertainty but not fabricated sources")
	check(s.reveal_keeper(),"source-aware, limited Keeper arrives")
	check(not s.respond_path("raise_lantern"),"no blind path guesses before observation")
	check(s.observe_tick(1.2,true,true),"safe position and hold reveal cue")
	check(not s.respond_path("cross_root") and s.path_index==0,"wrong warning is revisable")
	check(s.respond_path("raise_lantern"),"safe path cue is not an HP duel")
	s.danger=.97
	s.unsafe_step()
	check(s.encounter_failed and s.path_index==1,"warning failure nonfatal and local")
	check(s.retry_checkpoint() and s.path_index==1 and s.presented.size()==1,
		"checkpoint retry retains prior root and all evidence")
	for action in State.PATH_RESPONSES.slice(1,3):
		s.observe_tick(1.2,true,true)
		s.respond_path(action)
	check(s.phase==4,"truth trial follows path")
	check(not s.present_truth("limited_refuge"),"truth has an evidence order")
	check(s.admit_truth_gap(),"missing first corroboration may be admitted, not invented")
	check(s.present_truth("returning_boat"),"known second fact is presented")
	check(s.admit_truth_gap(),"missing third fact recorded as uncertainty")
	check(s.phase==5,"honest uncertainty doesn't hard-lock survival")
	for action in State.AWAKENED_RESPONSES:
		s.observe_tick(1.2,true,true)
		s.respond_awakened(action)
	check(s.phase==6 and not s.offer_outcomes().has("true"),
		"purely confident final dialogue can't fake unverified evidence")
	check(not s.commit("dark"),"dark requires deliberate warning, never a failed puzzle")
	check(s.warn_denial() and s.commit("dark"),"only explicit double-confirmed denial yields dark")
	check(s.outcome=="dark","no arbitrary death or unexpected ending")
	var t=_prepare_all()
	check(t.earned_allies().size()>=1,"optional earned allies detected but never mandatory")
	check(t.qualifies_true() and t.offer_outcomes().has("true"),
		"true ending based on documented facts and real community commitments, not six Resolves")
	check(t.commit("true") and t.sabel_privacy=="private",
		"TRUE permits private witness and prior partial cases")
	check(t.speak_epilogue("sabel") and t.speak_epilogue("mara"),
		"playable epilogue has resident-specific conversations")
	check(t.finish_story() and t.finished,"player voluntarily ends morning walk")
	check(Save.write(t),"independent v7 save written offline")
	var loaded=State.new()
	check(Save.read(loaded) and loaded.outcome=="true" and loaded.finished,
		"completed ending and voluntary epilogue restore")
	check(loaded.night01_outcome=="partial" and loaded.night06_outcome=="partial",
		"all six previous case outcomes preserved")
	var broken=loaded.to_dict()
	broken["path_index"]=8
	check(not State.new().from_dict(broken),"corrupt checkpoint index rejected")
	var good=_prepare_all()
	check(good.commit("good"),"temporary peace ending is explicit")
	var bittersweet=_prepare_all()
	check(bittersweet.commit("bittersweet"),"fractured cooperation ending is separate")
	check(State.new().from_dict(good.to_dict()) and State.new().from_dict(bittersweet.to_dict()),
		"other endings reload without separate Lola death rule")
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in preserved:
		var file:=FileAccess.open(path,FileAccess.WRITE)
		if file!=null:
			file.store_buffer(preserved[path])
			file.close()
	print("Night 7 source-backed readiness, four endings, fair roots and epilogue: ",
		"PASS" if failed==0 else str(failed)+" failures")
	quit(0 if failed==0 else 1)
