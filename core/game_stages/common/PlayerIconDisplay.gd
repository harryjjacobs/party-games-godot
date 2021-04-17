tool
extends Node2D
class_name PlayerIconDisplay

const Player = preload("res://core/player/Player.gd")

enum LayoutType {
	RING,
	LEADERBOARD,
	ROW
}

export(PackedScene) var player_icon_scene
export(PackedScene) var ranking_label_scene
export(float, 0.0, 1.0) var margin_x = 0.1
export(float, 0.0, 1.0) var margin_y = 0.1
export(float, 0.0, 10.0) var player_icon_scale = 1.0
export(float, 0.0, 2.0) var max_ranking_label_scale = 1.0
export(float, 0.0, 1.0) var min_ranking_label_scale = 0.5
export(LayoutType) var type = LayoutType.RING
export(int, 1, 10) var max_leaderboard_columns = 4

onready var _player_icon_container = $PlayerIconContainer
onready var _ranking_label_container = $RankingLabelContainer

var _player_icon_lookup = {}
var _screen_size

func _ready():
	_screen_size = get_viewport().size

func _process(_delta):
	if Engine.editor_hint:
		_update_player_positions()

func add_player(player: Player, animate = true):
	if player in _player_icon_lookup:
		return
	var player_icon = player_icon_scene.instance()
	player_icon.animate_entry = animate
	player_icon.scale = Vector2(player_icon_scale, player_icon_scale)
	player_icon.init(player)
	_player_icon_container.add_child(player_icon)
	_player_icon_lookup[player] = player_icon
	if ranking_label_scene:
		var ranking_label = ranking_label_scene.instance()
		ranking_label.set_rank(_player_icon_container.get_child_count())
		_ranking_label_container.add_child(ranking_label)
	_update_player_positions()
	
func remove_player(player: Player, animate = true):
	var player_icon = _player_icon_lookup.get(player)
	if not player_icon:
		return
	_player_icon_lookup.erase(player)
	if animate:
		player_icon.tween_exit()
		yield(player_icon.get_node("Tween"), "tween_finished")
	player_icon.queue_free()
	var from = _ranking_label_container.get_child_count() - 1
	var to = _player_icon_container.get_child_count() - 1
	for i in range(from, to, -1):
		_ranking_label_container.get_child(i).queue_free()

func clear():
	for player in _player_icon_lookup.keys():
		remove_player(player, false)

func add_players(players: Array, animate = true):
	for player in players:
		add_player(player, animate)
		# if animate:
		# 	yield(get_tree().create_timer(0.3), "timeout")
	
func swap_players(a: Player, b: Player, animate = true):
	yield(get_tree(), "idle_frame")
	var player_icon_a = _player_icon_lookup.get(a)
	var player_icon_b = _player_icon_lookup.get(b)
	if not a or not b:
		return
	var index_a = player_icon_a.get_position_in_parent()
	var index_b = player_icon_b.get_position_in_parent()
	# always move the lower index first to preserve
	# the lower indices when moving the higher one
	if index_b < index_a:
		_player_icon_container.move_child(player_icon_b, index_a)
		_player_icon_container.move_child(player_icon_a, index_b)
	else:
		_player_icon_container.move_child(player_icon_a, index_b)
		_player_icon_container.move_child(player_icon_b, index_a)
	var new_pos_a = _calculate_player_position(player_icon_a)
	var new_pos_b = _calculate_player_position(player_icon_b)
	if animate:
		# only yield the second one, so they are simultaneous
		player_icon_a.tween_position_to(new_pos_a)
		yield(player_icon_b.tween_position_to(new_pos_b), "completed")
	else:
		player_icon_a.position = new_pos_a
		player_icon_b.position = new_pos_b
	_update_player_positions()

func get_player_icon(player):
	return _player_icon_lookup.get(player)

func get_player_icons():
	return _player_icon_container.get_children()

func _update_player_positions():
	var i = 0
	for player_icon in _player_icon_container.get_children():
		var new_position = _calculate_player_position(player_icon)
		player_icon.position = new_position
		# update ranking label position and scale
		if i < _ranking_label_container.get_child_count():
			var ranking_label = _ranking_label_container.get_child(i)
			ranking_label.position = new_position
			var scale_factor = 1 - float(i) / _ranking_label_container.get_child_count()
			var label_scale = min_ranking_label_scale + scale_factor * \
				(max_ranking_label_scale - min_ranking_label_scale)
			ranking_label.scale = Vector2(label_scale, label_scale)
		i += 1

func _calculate_player_position(player_icon: PlayerIcon):
	var index = player_icon.get_position_in_parent()
	if index == -1:
		Log.info("%s._calculate_player_position() player_icon for %s not added" %
			[name, player_icon.player.username])
		return
	match type:
		LayoutType.RING:
			var radius_scale = Vector2(1 - margin_x, 1 - margin_y)
			var angle_increment = (2 * PI) / _player_icon_container.get_child_count()
			var x = _screen_size.x / 2 * radius_scale.y * sin(angle_increment * index)
			var y = _screen_size.y / 2 * radius_scale.x * -cos(angle_increment * index)
			return Vector2(x, y)
		LayoutType.ROW:
			var count = _player_icon_container.get_child_count()
			var width = _screen_size.x * (1 - margin_x)
			var separation = 0
			if count > 1:
				separation = width / (count - 1)
			var x = -((count - 1) * separation) / 2 + separation * index
			var y = 0
			return Vector2(x, y)
		LayoutType.LEADERBOARD:
			var column_count = min(_player_icon_container.get_child_count(), max_leaderboard_columns)
			var column_index = index % max_leaderboard_columns
			var row_count = max(ceil(_player_icon_container.get_child_count() / 
				float(max_leaderboard_columns)), 1)
			var row_index = index / max_leaderboard_columns
			var width = _screen_size.x * (1 - margin_x)
			var height = _screen_size.y * (1 - margin_y)
			var spacing_x = 0
			if column_count > 1:
				spacing_x = width / (column_count - 1)
			var spacing_y = 0
			if row_count > 1:
				spacing_y = min(height / (row_count - 1), spacing_x)
			var x = -width / 2 + spacing_x * column_index
			var y = 0
			if row_count > 1:
				y = -((row_count - 1) * spacing_y) / 2 + spacing_y * row_index
			return Vector2(x, y)
