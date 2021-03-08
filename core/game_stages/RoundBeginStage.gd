extends "res://core/game_stages/common/GameStage.gd"

var Message = preload("res://core/comms/Message.gd")

export(float) var duration = 4.0

func enter(params):
	.enter(params)

func exit():
	.exit()