extends "res://meme_game/game_stages/common/MemePromptRequestsStage.gd"

onready var theme_label = $Theme

func enter(params):
	.enter(params)
	var theme = _current_round.contests[0].theme
	theme_label.text = theme
