extends Node

# general game logic
# warning-ignore:unused_signal
signal create_game(config)
# warning-ignore:unused_signal
signal request_pause
# warning-ignore:unused_signal
signal request_resume
# warning-ignore:unused_signal
signal request_restart
# warning-ignore:unused_signal
signal request_main_menu(error_msg)
# warning-ignore:unused_signal
signal game_started
# warning-ignore:unused_signal
signal game_stopped
# warning-ignore:unused_signal
signal game_paused
# warning-ignore:unused_signal
signal game_resumed
# warning-ignore:unused_signal
signal open_settings
# warning-ignore:unused_signal
signal show_dialog
# warning-ignore:unused_signal
signal gamestage_changed(previous_stage, current_stage)

# network interface
# warning-ignore:unused_signal
signal server_connection_state_changed(state)
# warning-ignore:unused_signal
signal server_message_received(message)
# warning-ignore:unused_signal
signal client_connected(client_id)
# warning-ignore:unused_signal
signal client_disconnected(client_id)
# warning-ignore:unused_signal
signal client_message_received(message)

# room
# warning-ignore:unused_signal
signal room_created(code)
# warning-ignore:unused_signal
signal player_joined_room(player)
# warning-ignore:unused_signal
signal player_rejoined_room(player)
# warning-ignore:unused_signal
signal player_left_room(player)
