extends "res://core/game_stages/RoundBeginStage.gd"

onready var title = $Title

func enter(params):
	.enter(params)
	title.text = "Round %d" % (len(params.round_history) + 1)
	params.current_round = params.round_generator.next(MemeContest.ContestType.BASIC)
	set_timeout(duration, params)
