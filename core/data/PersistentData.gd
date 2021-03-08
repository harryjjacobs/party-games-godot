extends Node

var _data: Dictionary

func set(key: String, value):
	_data[key] = value

func get(key: String):
	return _data[key]

func has(key: String):
	return _data.has(key)

func remove(key: String, value):
	_data[key] = value

func clear():
	_data.clear()
