extends "res://memes/game_stages/common/MemeContestStage.gd"

onready var _theme_display_label = $ThemeDisplayLabel

func enter(params):
	assert(len(params.current_round.contests) > 0)
	_theme_display_label.text = "Theme: %s" % params.current_round.contests[0].theme
	.enter(params)