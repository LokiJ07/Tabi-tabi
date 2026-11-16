extends Node
## Offline original procedural Kapre ambience; no copyrighted or streamed media.
## A low-rate generator blends night insects, estuary wind and creaking wood.
## This is intentionally lightweight and safe when Android/headless has no
## audio playback device. Honour the existing accessibility audio setting.
const RATE := 11025.0
var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var phase := 0.0
var wind := 0.0
var seed := 742019
var level := 2
var night_stage := 0
var pressure := 0.0

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "KapreForestAndFloodAmbience"
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = RATE
	stream.buffer_length = 0.26
	player.stream = stream
	player.volume_db = -23.0
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	set_process(true)

func set_audio_level(value: int) -> void:
	level = clampi(value, 0, 2)
	if player != null:
		player.volume_db = -80.0 if level == 0 else -32.0 if level == 1 else -24.0

func set_night_stage(value: int) -> void:
	night_stage = clampi(value, 0, 3)

func set_tension(value: float) -> void:
	pressure = clampf(value,0.0,1.0)

func _exit_tree() -> void:
	# This procedural generator is shared by the Kapre and Tikbalang scenes.
	# Streamed region changes may free two emitters in one frame. Stop audio
	# before their C++ playback resources disappear, avoiding shutdown stalls.
	set_process(false)
	if player != null and is_instance_valid(player):
		player.stop()
	playback = null


func _process(_delta: float) -> void:
	if playback == null or level == 0:
		return
	var frames := mini(playback.get_frames_available(), 1400)
	for i in range(frames):
		phase += 1.0 / RATE
		# Small fixed-state noise rather than nondeterministic or heavy audio libs.
		seed = (seed * 1664525 + 1013904223) & 0x7fffffff
		var white := (float(seed % 4096) / 2048.0) - 1.0
		wind += (white - wind) * .011
		var breeze := .025 * wind * (1.0 + .4 * sin(phase * .33))
		var chirp_gate := pow(maxf(0.0, sin(phase * 2.9)), 4.0)
		# Forest insects intensify after sunset, while daylight stays quieter.
		var night_mix := clampf((float(night_stage)-.6)/1.4, 0.0, 1.0)
		var insect := (.0025 + .0075 * night_mix) * chirp_gate * sin(phase * TAU * 1610.0)
		var low := .004 * sin(phase * TAU * (68.0 + 3.0 * sin(phase * .27)))
		# Soft bending-trunk creak once per slow breeze; not a harsh jump scare.
		var creak_gate := pow(maxf(0.0, sin(phase * .42)), 12.0)
		var creak := (.003 + .005 * night_mix) * creak_gate * sin(phase * TAU * 92.0)
		# Sub-bass pressure comes from genuine unsafe proximity, not random scares.
		var heartbeat := .012 * pressure * pow(maxf(0.0,sin(phase * TAU * 1.15)),15.0)
		var mix := clampf(breeze + insect + low + creak + heartbeat, -.075, .075)
		playback.push_frame(Vector2(mix, mix))
