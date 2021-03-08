extends Node2D

signal request_exit

onready var _timer = $Timer

var _parameters

func enter(params):
	_parameters = params

func exit():
	pass

func set_timeout(duration, params):
	_timer.connect("timeout", self, "_on_timeout", [params])
	_timer.set_wait_time(duration)
	_timer.start()

func _on_timeout(params):
	emit_signal("request_exit", params)