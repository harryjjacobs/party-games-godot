extends "res://core/game_stages/common/GameStage.gd"

var _current_round 

func enter(params):
	.enter(params)
	_current_round = params.rounds.pop_front()
	params.round_history.append(_current_round)
	