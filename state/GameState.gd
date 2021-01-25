extends Node

signal request_exit

onready var _timer = $"Timer"

func enter():
	pass

func exit():
	pass

func set_timeout(duration):
	_timer.connect("timeout", self, "_request_exit")
	_timer.set_wait_time(duration)
	_timer.start()

func _request_exit():
	emit_signal("request_exit")