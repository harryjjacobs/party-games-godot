extends "res://core/game_stages/RoundBeginStage.gd"

onready var _title = $Title

func enter(params):
	.enter(params)
	_title.text = "Round %d" % (len(params.round_history) + 1)
	var players = Room.players
	params.current_round = params.round_generator.next(MusiQContest.ContestType.ALLVALL, players)
	set_timeout(duration, params)