extends GridContainer

# range (+ and -) in which to choose a random rotation for each child
export(float) var rotation_randomisation = 7

const _player_label_scene = preload("res://meme_game/player/PlayerLabel.tscn")

func set_players(players):
	for child in get_children():
		child.queue_free()
	for player in players:
		var label = _player_label_scene.instance()
		add_child(label)
		label.text = player.username		
	yield(get_tree(), "idle_frame")
	for child in get_children():
		var rotation = rand_range(-rotation_randomisation, rotation_randomisation)
		child.set_pivot_offset(child.rect_size / 2.0)
		child.set_rotation_degrees(rotation)
