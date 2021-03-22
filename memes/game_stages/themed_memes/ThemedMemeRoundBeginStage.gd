extends "res://core/game_stages/RoundBeginStage.gd"

onready var title = $Title

func enter(params):
	.enter(params)
	title.text = "Round %d" % (len(params.round_history) + 1)
	$AnimationPlayer.play("Thmemes")
	params.current_round = params.round_generator.next(MemeContest.ContestType.THEMED)
	set_timeout(5.0, params)
