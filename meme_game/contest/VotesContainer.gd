extends GridContainer

const _player_label_scene = preload("res://meme_game/player/PlayerLabel.tscn")

func set_players(players):
	for child in get_children():
		child.queue_free()
	for player in players:
		var label = _player_label_scene.instance()
		add_child(label)
		label.text = player.username
	