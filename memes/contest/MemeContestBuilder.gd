extends Node2D
class_name MemeContestBuilder

export(Array, Resource) var meme_templates

var _meme_template_pool: Array

func _ready():
	_meme_template_pool = meme_templates.duplicate()
	_meme_template_pool.shuffle()

func build(players: Array, type = MemeContest.ContestType.TWO_PLAYER):
	var instance = MemeContest.new()
	instance.players = players
	instance.type = type
	instance.meme_template = _next_template()

	match type:
		MemeContest.ContestType.TWO_PLAYER:
			pass
		MemeContest.ContestType.MULTI_PLAYER:
			pass
		_:
			printerr("Invalid ContestType: %s" % type)
	return instance

func _next_template():
	if _meme_template_pool.empty():
		_meme_template_pool = meme_templates.duplicate()
	return _meme_template_pool.pop_front()
