extends Node

# Procedural wind, so the game has sound without any audio files.
# Drop real loops into assets/audio/ambience later and replace this.

const MIX_RATE := 22050.0

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _low := 0.0
var _time := 0.0


func _ready() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = 0.4
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	_player.volume_db = -14.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()


func _process(delta: float) -> void:
	if not _playback:
		return
	_time += delta
	var swell := 0.55 + 0.45 * sin(_time * 0.35)
	var frames := _playback.get_frames_available()
	for i in frames:
		var noise := randf_range(-1.0, 1.0)
		_low += (noise - _low) * 0.03
		var sample := _low * swell * 2.2
		_playback.push_frame(Vector2(sample, sample))
