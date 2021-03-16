extends Node

export(float) var crossfade_duration = 2.0
onready var _player = $AudioStreamPlayer
onready var _tween = $Tween

var _tracks = []
var _track_history = []

func clear_tracks():
	_tracks.clear()
	_track_history.clear()

func add_tracks(audio_streams: Array):
	for stream in audio_streams:
		add_track(stream)

func add_track(audio_stream: AudioStreamSample):
	_tracks.append(audio_stream)

func remove_track(audio_stream: AudioStreamSample):
	_tracks.remove(audio_stream)

func play():
	if _player.get_stream_paused():
		_player.set_stream_paused(false)
	else:
		if _player.stream:
			_player.play()
		else:
			_play_next_track()

func play_oneshot(audio_stream: AudioStreamSample):
	if _player.stream:
		_tracks.push_front(_player.stream)
	_crossfade_to(audio_stream)

func pause():
	_player.set_stream_paused(true)

func skip_track():
	_play_next_track()

func _on_track_finished():
	_play_next_track()

func _play_next_track():
	if len(_tracks) == 0:
		_tracks = _track_history
	if len(_tracks) > 0:
		var track = _tracks.pop_front()
		_track_history.append(track)
		_crossfade_to(track)

func _crossfade_to(audio_stream: AudioStreamSample):
	if _player.is_playing():
		_tween.interpolate_property(_player, "volume_db", 0, -80,
			crossfade_duration * 0.5, Tween.TRANS_SINE, Tween.EASE_IN, 0)
		_tween.start()
		yield(_tween, "tween_completed")
	_player.stop()
	_player.stream = audio_stream
	_tween.interpolate_property(_player, "volume_db", -80, 0,
		crossfade_duration * 0.5, Tween.TRANS_SINE, Tween.EASE_IN, 0)
	_tween.start()
	yield(_tween, "tween_started")
	_player.play()
