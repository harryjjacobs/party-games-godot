extends Node2D

onready var _icon_display = $PlayerIconDisplay

# Called when the node enters the scene tree for the first time.
func _ready():
	if is_inside_tree():
		yield(get_tree().create_timer(1.0), "timeout")
	var players = [
		Player.new("0", "Player A"),
		Player.new("1", "Player B"),
		Player.new("2", "Player C"),
		Player.new("3", "Player D"),
		Player.new("4", "Player E"),
		Player.new("5", "Player F"),
	]
	players[0].color = Color(0.8, 0.5, 0.5, 1.0)
	players[1].color = Color(0.5, 0.8, 0.5, 1.0)
	players[2].color = Color(0.5, 0.5, 0.8, 1.0)
	players[3].color = Color(0.8, 0.8, 0.5, 1.0)
	players[4].color = Color(0.5, 0.8, 0.8, 1.0)
	players[5].color = Color(0.8, 0.5, 0.8, 1.0)
	_icon_display.add_players(players, true)
	if is_inside_tree():
		yield(get_tree().create_timer(1.0), "timeout")
	_icon_display.swap_players(players[1], players[3])
	if is_inside_tree():
		yield(get_tree().create_timer(1.0), "timeout")
	_icon_display.swap_players(players[0], players[5])

