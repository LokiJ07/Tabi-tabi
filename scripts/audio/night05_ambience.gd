extends Node
## Original offline farm wind and insects; quiet, non-jumpscare soundscape.
const RATE := 11025.0
var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var clock := 0.0
var filter := 0.0
var seed := 615052
var level := 2
var night_stage := 0
var tension := 0.0

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	player = AudioStreamPlayer.new()
	player.name = "FarmInsectsAndBamboo"
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
		player.volume_db = -80.0 if level == 0 else -35.0 if level == 1 else -27.0

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
	var count := mini(playback.get_frames_available(),1400)
	for i in range(count):
		clock += 1.0/RATE
		seed = (seed*1664525+1013904223)&0x7fffffff
		var white := float(seed%4096)/2048.0-1.0
		filter += (white-filter)*.012
		var darkness := clampf(float(night_stage)/2.0,0.0,1.0)
		var breeze := (.020+darkness*.015)*filter*(1.0+.32*sin(clock*.29))
		var crickets := .004*darkness*pow(maxf(0.0,sin(clock*3.35)),7.0)*sin(clock*TAU*1422.0)
		var loose_barn := .004*pow(maxf(0.0,sin(clock*.37)),17.0)*sin(clock*TAU*108.0)
		var pressure := darkness*tension*.012*filter*sin(clock*1.08)
		var mix := clampf(breeze+crickets+loose_barn+pressure,-.065,.065)
		playback.push_frame(Vector2(mix,mix))
