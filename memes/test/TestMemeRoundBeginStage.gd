extends Node2D

onready var stage = $BasicMemeRoundBeginStage

func _ready():
	var players = [
		Player.new("0", "Player 1"),
		Player.new("0", "Player 2")
	]
	var params = {
		"round_generator": RoundGenerator.new(players, $MemeContestBuilder),
		"current_round": null,
		"round_history": Array(),
	}
	stage.connect("request_exit", self, "_on_stage_exit")
	stage.enter(params)

func _on_stage_exit(params):
	assert(len(params.current_round.contests) > 0)
	print("TEST PASSED")