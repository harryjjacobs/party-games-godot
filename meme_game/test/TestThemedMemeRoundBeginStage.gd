extends Node2D

onready var stage = $ThemedMemeRoundBeginStage

func _ready():
	var players = [
		Player.new("0", "Player 1"),
		Player.new("0", "Player 2")
	]
	var params = {
		"round_generator": MemeRoundGenerator.new(players, $MemeContestBuilder),
		"current_round": null,
		"round_history": Array(),
	}
	stage.connect("request_exit", self, "_on_stage_exit")
	stage.enter(params)

func _on_stage_exit(params):
	assert(len(params.current_round.contests) > 0)
	assert(params.current_round.contests[0])
	assert(params.current_round.contests[0].theme)
	var expected_theme = params.current_round.contests[0].theme
	Log.info("Generated contests with common theme: " + expected_theme)
	for contest in params.current_round.contests:
		assert(contest.theme == expected_theme)
	Log.info("TEST PASSED")
