extends "res://core/game_stages/RoundEndStage.gd"

func exit():
	if _parameters.rounds.empty():
		return StageExitTransition.NEXT_STAGE
	else:
		return StageExitTransition.REPEAT_GROUP

func get_group_name():
	return "round"
