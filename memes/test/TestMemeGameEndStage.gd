extends Node2D

onready var _stage = $MemeGameEndStage
onready var _icons_container = $MemeGameEndStage/PlayerIconDisplay/PlayerIconContainer

func _ready():
	var players = [
		Player.new("0", "Player 1"),
		Player.new("1", "Player 2"),
		Player.new("2", "Player 3"),
		Player.new("3", "Player 4"),
		Player.new("4", "Player 5"),
	]
	# points awarded in first round
	players[0].update_points(50, 0)
	players[1].update_points(72, 0)
	players[2].update_points(50, 0)
	players[3].update_points(60, 0)
	players[4].update_points(60, 0)
	# points awarded in second round
	players[0].update_points(20, 1)
	players[2].update_points(50, 1)
	players[3].update_points(40, 1)
	players[4].update_points(15, 1)
	Room.players = players
	var params = {
		"round_generator": null,
		"current_round": null,
		"round_history": [Round.new(), Round.new()],
	}
	_stage.connect("request_exit", self, "_on_stage_exit")
	_stage.enter(params)

func _on_stage_exit(_params):
	Log.info("TEST PASSED")

func _sort_descending_by_points(a, b):
	return b.points < a.points
