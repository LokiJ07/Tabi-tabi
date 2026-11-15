extends Node
## Original synthetic placeholder ambience: soft river, daytime birds and nighttime insects.
## No network, third-party samples, ritual motifs, or copyrighted music required.
const SAMPLE_RATE := 11025
const LOOP_SECONDS := 2
const SAMPLE_COUNT := SAMPLE_RATE * LOOP_SECONDS
var day_player: AudioStreamPlayer
var night_player: AudioStreamPlayer
var night_active := false
var audio_level := 1


func _ready() -> void:
	day_player = AudioStreamPlayer.new()
	day_player.name = "Day River and Birds"
	day_player.stream = create_loop(false)
	day_player.volume_db = -80.0
	add_child(day_player)
	night_player = AudioStreamPlayer.new()
	night_player.name = "Night River and Insects"
	night_player.stream = create_loop(true)
	night_player.volume_db = -80.0
	add_child(night_player)
	day_player.play()
	night_player.play()
	set_process(true)


func set_night(active: bool) -> void:
	night_active = active


func set_audio_level(level: int) -> void:
	audio_level = clampi(level, 0, 2)


func _process(delta: float) -> void:
	var base_db := -80.0 if audio_level == 0 else -24.0 if audio_level == 1 else -14.0
	if day_player != null:
		day_player.volume_db = lerpf(day_player.volume_db, -80.0 if night_active else base_db, minf(1.0, delta * 1.8))
	if night_player != null:
		night_player.volume_db = lerpf(night_player.volume_db, base_db if night_active else -80.0, minf(1.0, delta * 1.8))


static func create_loop(night: bool) -> AudioStreamWAV:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = SAMPLE_RATE
	wave.stereo = false
	wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wave.loop_begin = 0
	wave.loop_end = SAMPLE_COUNT
	var bytes := PackedByteArray()
	bytes.resize(SAMPLE_COUNT * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13921 if night else 91397
	var filtered_noise := 0.0
	for i in range(SAMPLE_COUNT):
		var time := float(i) / float(SAMPLE_RATE)
		# Slowly filtered synthetic noise approximates nearby moving water.
		filtered_noise = filtered_noise * 0.91 + rng.randf_range(-1.0, 1.0) * 0.09
		var river := filtered_noise * 0.22 + 0.05 * sin(TAU * 32.0 * time)
		var life := 0.0
		if night:
			var insect_envelope := pow(maxf(0.0, sin(TAU * 1.0 * time)), 3.0)
			life = 0.095 * insect_envelope * sin(TAU * 2240.0 * time)
		else:
			var bird_envelope := pow(maxf(0.0, sin(TAU * 0.5 * time)), 8.0)
			life = 0.10 * bird_envelope * sin(TAU * (690.0 * time + 35.0 * time * time))
		# Fades at loop boundaries ensure a safe continuous preview.
		var edge := minf(1.0, minf(time, float(LOOP_SECONDS) - time) / 0.04)
		var sample := clampi(roundi((river + life) * edge * 22000.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample)
	wave.data = bytes
	return wave
