extends Node
## Original offline Balete ambience: insect bed, leaves, woody roots and dawn birds.
## No copyrighted samples, random stingers, online downloads or panic volume spikes.
const RATE := 11025.0
var output: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var clock := 0.0
var seed := 1707207
var wind := 0.0
var stage := 0
var danger := 0.0
var level := 2

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	output = AudioStreamPlayer.new()
	output.name = "BaleteWindBirdsAndRootCreak"
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
		output.volume_db = -80.0 if level == 0 else -35.0 if level == 1 else -28.0

func set_stage(value: int) -> void:
	stage = clampi(value,0,3)

func set_danger(value: float) -> void:
	danger = clampf(value,0,1)

func _exit_tree() -> void:
	set_process(false)
	if output != null and is_instance_valid(output):
		output.stop()
	playback = null

func _process(_delta: float) -> void:
	if playback == null or level == 0:
		return
	var count := mini(playback.get_frames_available(),1400)
	for i in range(count):
		clock += 1.0/RATE
		seed = (seed*1664525+1013904223)&0x7fffffff
		var white := float(seed%4096)/2048.0-1.0
		wind += (white-wind)*.017
		var dark := clampf(float(stage)/3.0,0,1)
		var breeze := wind*(.028+dark*.008)*(1.0+.30*sin(clock*.31))
		var crickets := dark*.0054*pow(maxf(0.0,sin(clock*1.6)),9.0)*sin(clock*TAU*1477.0)
		var birdwindow := pow(maxf(0.0,sin(clock*.49)),14.0)
		var bird := (1.0-dark)*birdwindow*.0040*sin(clock*TAU*(780.0+90.0*sin(clock*2.7)))
		var rootwindow := pow(maxf(0.0,sin(clock*.48)),25.0)
		var root := dark*(.0034+danger*.0065)*rootwindow*sin(clock*TAU*94.0+1.5*sin(clock*2.2))
		var leaves := dark*.007*wind*sin(clock*1.33)
		var mix := clampf(breeze+crickets+bird+root+leaves,-.065,.065)
		playback.push_frame(Vector2(mix,mix))
