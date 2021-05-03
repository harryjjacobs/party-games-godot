extends "res://core/game_stages/common/GameStage.gd"

export(float) var duration = 7

func enter(params):
	.enter(params)
	set_timeout(duration, params)
	$AnimationPlayer.play("Title Entrance")
