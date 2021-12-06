extends Node2D
class_name GameStage

signal request_exit

enum StageExitTransition { NEXT_STAGE, REPEAT_STAGE, REPEAT_GROUP }

onready var _timer = $Timer
onready var _audio_player = $AudioStreamPlayer

var _parameters

func enter(params):
	_parameters = params

func exit():
	return StageExitTransition.NEXT_STAGE

func set_timeout(duration, params):
	if not _timer.is_connected("timeout", self, "_on_timeout"):
		_timer.connect("timeout", self, "_on_timeout", [params])
	_timer.start(duration)

func get_group_name():
	return ""

func _on_timeout(params):
	_timer.stop()
	emit_signal("request_exit", params)

func _play_audio(audio_stream):
	if not audio_stream:
		return
	_audio_player.stream = audio_stream
	_audio_player.play()
