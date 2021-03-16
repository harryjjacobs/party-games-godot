extends Node2D

signal request_exit

onready var _timer = $Timer
onready var _audio_player = $AudioStreamPlayer

var _parameters

func enter(params):
	_parameters = params

func exit():
	pass

func set_timeout(duration, params):
	_timer.connect("timeout", self, "_on_timeout", [params])
	_timer.start(duration)

func _on_timeout(params):
	_timer.stop()
	emit_signal("request_exit", params)

func _play_audio(audio_stream):
	if not audio_stream:
		return
	_audio_player.stream = audio_stream
	_audio_player.play()