extends Control

const _meme_game_scene = preload("res://memes/Memes.tscn")

func _on_play_button_pressed():
	visible = false
	get_tree().get_root().add_child(_meme_game_scene.instance())
