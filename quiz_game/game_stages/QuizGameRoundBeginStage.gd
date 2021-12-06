extends "res://core/game_stages/RoundBeginStage.gd"

onready var _title_label = $Title
onready var _subtitle_label = $Subtitle

func enter(params):
	.enter(params)
	params.current_round = params.rounds.pop_front()
	_title_label.text = "Round %d" % (len(params.round_history) + 1)
	_subtitle_label.text = params.current_round.category.name
	params["question_index"] = 0
	set_timeout(duration, params)

func get_group_name():
	return "round"
