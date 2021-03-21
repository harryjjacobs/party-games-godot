extends Node2D
class_name MemeContestBuilder

export(Array, Resource) var meme_templates

var _meme_template_pool: Array

var meme_types_for_contest = {
	MemeContest.ContestType.BASIC: [
		MemeTemplate.MemeTemplateType.EMPTY_CAPTION
	],
	MemeContest.ContestType.THEMED: [
		MemeTemplate.MemeTemplateType.EMPTY_CAPTION
	],
	MemeContest.ContestType.BLANK_FILL: [
		MemeTemplate.MemeTemplateType.BLANK_FILL
	]
}

func _ready():
	_meme_template_pool = meme_templates.duplicate()
	_meme_template_pool.shuffle()

func build(players: Array, vote_weight, 
					 contest_type = MemeContest.ContestType.BASIC):
	var instance = MemeContest.new()
	instance.players = players
	instance.type = contest_type
	instance.meme_template = _next_template(contest_type)
	instance.vote_weight = vote_weight
	match contest_type:
		MemeContest.ContestType.BASIC:
			pass
		MemeContest.ContestType.THEMED:
			pass
		_:
			printerr("Invalid ContestType: %s" % contest_type)
	return instance

func _next_template(contest_type):
	if _meme_template_pool.empty():
		_meme_template_pool = meme_templates.duplicate()
	var valid_meme_types = meme_types_for_contest[contest_type]
	while not _meme_template_pool.empty():
		var template = _meme_template_pool.pop_front()
		if template.type in valid_meme_types:
			return template
