extends "res://core/game_stages/common/GameStage.gd"

func enter(params):
	.enter(params)

func exit():
	.exit()

func _on_play_again_button_pressed():
	Events.emit_signal("request_restart", false)

func _on_play_again_same_players_button_pressed():
	Events.emit_signal("request_restart", true)

func _on_exit_to_main_menu_button_pressed():
	Events.emit_signal("request_main_menu")

