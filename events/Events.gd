extends Node

# general game logic
signal create_game(config)
signal pause_game
signal resume_game
signal gamestate_changed(previous_state, current_state)

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
