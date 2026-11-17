extends Node
## Original procedurally synthesized river, wind and rope soundscape.
## No internet, copyrighted samples or jumpscare stingers.
const RATE := 11025.0
var output: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var clock := 0.0
var noise_state := 190526
var soft_water := 0.0
var level := 2
var stage := 0
var risk := 0.0

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	output = AudioStreamPlayer.new()
	output.name = "UnfinishedRiverWindAndCurrent"
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = RATE
	stream.buffer_length = .28
	output.stream = stream
	output.volume_db = -28.0
	add_child(output)
	output.play()
	playback = output.get_stream_playback() as AudioStreamGeneratorPlayback

func set_audio_level(value: int) -> void:
	level = clampi(value,0,2)
	if output != null:
		output.volume_db = -80.0 if level == 0 else -36.0 if level == 1 else -28.0

func set_stage(value: int) -> void:
	stage = clampi(value,0,3)

func set_risk(value: float) -> void:
	risk = clampf(value,0,1)

func _exit_tree() -> void:
	set_process(false)
	if output != null and is_instance_valid(output):
		output.stop()
	playback = null

func _process(_delta: float) -> void:
	if playback == null or level == 0: return
	var count := mini(playback.get_frames_available(),1400)
	for i in range(count):
		clock += 1.0 / RATE
		noise_state = (noise_state*1664525+1013904223)&0x7fffffff
		var white := float(noise_state%4096)/2048.0-1.0
		soft_water += (white-soft_water)*.029
		var nighttime := clampf(float(stage)/3.0,0,1)
		var current := (.022+.016*nighttime)*soft_water*(1.0+.35*sin(clock*.32))
		var shore_wash := .006*sin(clock*TAU*72.0+sin(clock*.29)*3.0)*sin(clock*.44)
		var rope_creak := .0
		if stage >= 2:
			var creak := pow(maxf(0.0,sin(clock*.61)),24.0)
			rope_creak = creak * .0045 * sin(clock*TAU*111.0)
		var distant_insects := (.005*(1.0-nighttime*.38))*sin(clock*TAU*934.0)*pow(maxf(.0,sin(clock*1.9)),12.0)
		var surge := (nighttime*risk*.018)*soft_water*sin(clock*1.08)
		var mix := clampf(current+shore_wash+rope_creak+distant_insects+surge,-.065,.065)
		playback.push_frame(Vector2(mix,mix))
