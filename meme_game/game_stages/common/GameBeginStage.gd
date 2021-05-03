extends "res://core/game_stages/common/GameStage.gd"

onready var _meme_contest_builder = $MemeContestBuilder

func enter(params):
	.enter(params)
	var round_generator = RoundGenerator.new(Room.players, _meme_contest_builder)
	emit_signal("request_exit", {
		"round_generator": round_generator,
		"current_round": null,
		"round_history": []
	})
