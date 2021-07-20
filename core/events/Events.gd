extends Node

# general game logic
signal create_game(config)
signal request_pause
signal request_resume
signal request_restart
signal request_main_menu
signal game_started
signal game_stopped
signal game_paused
signal game_resumed
signal open_settings
signal show_dialog
signal gamestage_changed(previous_stage, current_stage)

# network interface
signal server_connection_state_changed(state)
signal server_message_received(message)
signal client_connected(client_id)
signal client_disconnected(client_id)
signal client_message_received(message)

# room
signal room_created(code)
signal player_joined_room(player)
signal player_rejoined_room(player)
signal player_left_room(player)
