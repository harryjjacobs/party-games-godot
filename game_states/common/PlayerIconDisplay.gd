extends Node2D
class_name PlayerIconDisplay

const Player = preload("res://player/Player.gd")
const PlayerIcon = preload("res://player/PlayerIcon.gd")

enum DisplayType {
	RING,
	LEADERBOARD
}

export(float, 0.0, 1.0) var margin_x = 0.1
export(float, 0.0, 1.0) var margin_y = 0.1
export(DisplayType) var type = DisplayType.RING

var _player_icons = []
var _player_icon_lookup = {}
var _screen_size

func _ready():
	_screen_size = get_viewport().size

func add_player(player: Player, animate = true):
	if player in _player_icon_lookup:
		return
	var player_icon = preload("res://player/PlayerIcon.tscn").instance()
	player_icon.init(player)
	add_child(player_icon)
	_player_icons.push_back(player_icon)
	_player_icon_lookup[player] = player_icon
	_update_player_positions()
	
func remove_player(player: Player, animate = true):
	var player_icon = _player_icon_lookup.get(player)
	if not player_icon:
		return
	_player_icons.erase(player_icon)
	_player_icon_lookup.erase(player)
	player_icon.queue_free()

func add_players(players: Array, animate = true):
	for player in players:
		add_player(player, animate)
	
func swap_players(a: Player, b: Player, animate = true):
	var player_icon_a = _player_icon_lookup.get(a)
	var player_icon_b = _player_icon_lookup.get(b)
	if not a or not b:
		return
	var index_a = _player_icons.find(player_icon_a)
	var index_b = _player_icons.find(player_icon_b)
	_player_icons[index_a] = player_icon_b
	_player_icons[index_b] = player_icon_a
	# TODO animate position change
	var new_pos_a = _calculate_player_position(player_icon_a)
	var new_pos_b = _calculate_player_position(player_icon_a)
	player_icon_a.tween_position_to(new_pos_a)
	player_icon_b.tween_position_to(new_pos_b)
	
func _update_player_positions():
	for player_icon in _player_icons:
		player_icon.position = _calculate_player_position(player_icon)

func _calculate_player_position(player_icon: PlayerIcon):
	var index = _player_icons.find(player_icon)
	if index == -1:
		print("%s._calculate_player_position() player_icon for %s not added" 
			% name, player_icon.player.name)
		return
	match type:
		DisplayType.RING:
			var radius_scale = Vector2(1 - margin_x, 1 - margin_y)
			var angle_increment = (2 * PI) / len(_player_icons)
			var x = _screen_size.x / 2 * radius_scale.y * sin(angle_increment * index)
			var y = _screen_size.y / 2 * radius_scale.x * -cos(angle_increment * index)
			return Vector2(x, y)
		DisplayType.LEADERBOARD:
			pass
