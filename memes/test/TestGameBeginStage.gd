extends Node2D

onready var stage = $GameBeginStage

func _ready():
	pass
	# Room.players = [
	# 	Player.new("", "a"),
	# 	Player.new("", "b"),
	# 	Player.new("", "c"),
	# 	Player.new("", "d"),
	# 	Player.new("", "e"),
	# 	Player.new("", "f"),
	# 	Player.new("", "g"),
	# ]
	# stage.connect("request_exit", self, "_on_stage_exit")
	# stage.num_rounds = 2
	# stage.enter({})

# func _on_stage_exit(params):
# 	assert(len(params.rounds) == 2)
# 	for i in len(params.rounds):
# 		print("Round %d contest" % (i + 1))
# 		for contest in params.rounds[i].contests:
# 			print("%s Vs %s" % [contest.players[0].username, contest.players[1].username])
# 	assert(len(params.rounds[0].contests) == len(Room.players))
