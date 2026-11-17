extends Node
## Original, entirely offline wake ambience: insects, gentle courtyard wind,
## occasional bamboo creak and increasing approach pressure. No spoken prayers,
## unlicensed music, network requests or sharp random jumpscares.
const RATE := 11025.0
var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var clock := 0.0
var filtered_noise := 0.0
var seed := 510084
var level := 2
var night_stage := 0
var tension := 0.0

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	player = AudioStreamPlayer.new()
	player.name = "WakeCourtyardOriginalSoundscape"
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = RATE
	stream.buffer_length = .26
	player.stream = stream
	player.volume_db = -27.0
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback

func set_audio_level(value: int) -> void:
	level = clampi(value,0,2)
	if player != null:
		player.volume_db = -80.0 if level == 0 else -34.0 if level == 1 else -26.0

func set_night_stage(value: int) -> void:
	night_stage = clampi(value,0,3)

func set_tension(value: float) -> void:
	tension = clampf(value,0.0,1.0)

func _exit_tree() -> void:
	set_process(false)
	if player != null and is_instance_valid(player):
		player.stop()
	playback = null

func _process(_delta: float) -> void:
	if playback == null or level == 0:
		return
	var frames := mini(playback.get_frames_available(),1400)
	for i in range(frames):
		clock += 1.0/RATE
		seed = (seed*1664525+1013904223)&0x7fffffff
		var white := float(seed%4096)/2048.0-1.0
		filtered_noise += (white-filtered_noise)*.013
		var night_mix := clampf(float(night_stage)/2.0,0.0,1.0)
		var wind := (.022+night_mix*.009)*filtered_noise*(1.0+.35*sin(clock*.31))
		var insect := .005*night_mix*pow(maxf(0.0,sin(clock*3.2)),6.0)*sin(clock*TAU*1378.0)
		var bamboo := .005*pow(maxf(0.0,sin(clock*.43)),18.0)*sin(clock*TAU*97.0)
		# Quiet delayed call from the far settlement, not a loud alert.
		var beat := fposmod(clock,17.0)
		var bell := (.004*exp(-beat*3.6))*sin(clock*TAU*352.0)
		# When a real approach builds, low wind pressure advances gradually.
		var wing := night_mix*tension*.013*filtered_noise*sin(clock*1.24)
		var pulse := night_mix*tension*.008*pow(maxf(0,sin(clock*TAU*1.01)),12.0)
		var mix := clampf(wind+insect+bamboo+bell+wing+pulse,-.072,.072)
		playback.push_frame(Vector2(mix,mix))
