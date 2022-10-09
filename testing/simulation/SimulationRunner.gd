extends Node

const DELAY_SCALER = 0.5
const NUM_PLAYERS = 8
const SIM_PLAYER_SCENE = preload("res://testing/simulation/SimulationPlayer.tscn")

var _game_type
var _game_scene
var _gameplay_controller
var _runner

func _process(_delta):
	if _runner.current_game_stage != _gameplay_controller._current_stage: 
		_runner.current_game_stage = _gameplay_controller._current_stage
	
func run(game_type, game_scene):
	Log.warn("==============RUNNING SIMULATION==============")
	NodeUtils.remove_children(self)
	_game_type = game_type
	_game_scene = game_scene
	_gameplay_controller = _game_scene.get_node("GameplayController")
	if game_type == GameTypes.Types.UNTITLED_MEME_GAME:
		_runner = _MemeGameSimulationRunner.new(self)
	elif game_type == GameTypes.Types.MUSIQ:
		_runner = _MusiQGameSimulationRunner.new(self)
	_runner.run()

class _SimulationRunner:
	var current_game_stage setget _current_game_stage_setter
	var players = []
	var _simulation_node
	
	func _init(node):
		_simulation_node = node
	
	func run():
		pass
	
	func delay(time):
		yield(_simulation_node.get_tree().create_timer(time * DELAY_SCALER), "timeout")

	func _current_game_stage_setter(stage):
		current_game_stage = stage
		_on_current_game_stage_changed()

	func _on_player_receieved_message(_message, _player):
		pass
		
	func _on_current_game_stage_changed():
		pass
	
	func _create_simulation_players():
		for player in players:
			_simulation_node.remove_child(player)
		players.clear()
		for _i in range(NUM_PLAYERS):
			var player = SIM_PLAYER_SCENE.instance()
			players.push_back(player)
			_simulation_node.add_child(player)
			var _err = player.connect("message_received", self, "_on_player_receieved_message", [player])
			yield(delay(0.5), "completed")		

	func _do_lobby():
		for player in players:
			player.join()
			yield(delay(0.5), "completed")

	func _do_start_game(prompt_id):
		yield(delay(0.5), "completed")
		players[0].send_message(Message.create(Message.PROMPT_RESPONSE, {
			"id": prompt_id,
			"roomCode": Room.code
		}))

class _MemeGameSimulationRunner extends _SimulationRunner:
	const WORDS_FILE = 'res://meme_game/contest/nouns.txt'
	var _start_game_prompt_input_id
	var _words
	
	func _init(node).(node):
		var f = File.new()
		f.open(WORDS_FILE, File.READ)
		_words = []
		while not f.eof_reached(): # iterate through all lines until the end of file is reached
			var line = f.get_line()
			_words.append(line)
		f.close()
		_words.shuffle()
	
	func run():
		.run()
		yield(Events, "room_created")
		yield(._create_simulation_players(), "completed")
		yield(._do_lobby(), "completed")
		yield(._do_start_game(_start_game_prompt_input_id), "completed")
	
	func _on_current_game_stage_changed():
		if current_game_stage.get_name() == "MemeGameCreditsStage":
			current_game_stage._on_play_again_button_pressed()
	
	func _on_player_receieved_message(message, player):
		if current_game_stage.get_name() == "LobbyStage":
			if message.type == "request_input":
				_start_game_prompt_input_id = message.data.promptData.id
		elif "MemePromptRequestsStage" in current_game_stage.get_name():
			if message.type == "request_input" and message.data.promptType == "meme":
				_handle_meme_prompt_request(player, message.data.promptData)
		elif "MemeContestStage" in current_game_stage.get_name():
			if message.type == "request_input" and message.data.promptType == "multichoice":
				_handle_vote_request(player, message.data.promptData)
	
	func _handle_meme_prompt_request(player, prompt_data):
		randomize()		
		yield(.delay(rand_range(1, 5)), "completed")
		var contest_id = prompt_data.id
		var max_caption_length = prompt_data.maxInputLength
		var template = prompt_data.template
		var caption_responses = []
		for caption in template.captions:
			var caption_response = ""
			var caption_length = rand_range(max_caption_length / 3, max_caption_length)
			while len(caption_response) < caption_length:
				caption_response += _words[rand_range(0, len(_words))] + " "
			caption_response.strip_edges()
			caption_responses.push_back(caption_response)
		player.send_message(Message.create(Message.PROMPT_RESPONSE, {
			"id": contest_id,
			"captions": caption_responses,
			"roomCode": Room.code
		}))
		
	func _handle_vote_request(player, prompt_data):
		randomize()
		yield(.delay(rand_range(1, 6)), "completed")
		if rand_range(0, 100) < 20: # don't vote n% of the time
			return
		var contest_id = prompt_data.id
		var choice = rand_range(0, len(prompt_data.options))
		player.send_message(Message.create(Message.PROMPT_RESPONSE, {
			"id": contest_id,
			"choice": choice,
			"roomCode": Room.code
		}))

class _MusiQGameSimulationRunner extends _SimulationRunner:
		var _start_game_prompt_input_id
		
		func _init(node).(node):
			pass
		
		func run():
			.run()
			_start_game_prompt_input_id = null

		func _on_current_game_stage_changed():
			if current_game_stage.get_name() == "MusiQGameSetupStage":
				yield(_simulation_node.get_tree(), "idle_frame")
				print(get_class() + ": Performing spotify authorization")
				if not current_game_stage._track_player.IsAuthorized:
					current_game_stage._track_player.PerformAuthorization()
					yield(current_game_stage._track_player, "authorization_succeeded")
					print(get_class() + ": Authorization succeeded")
				# print(get_class() + ": Launching spotify")
				# var _exit_code = OS.execute("spotify", [], false)
				yield(_simulation_node.get_tree().create_timer(5), "timeout")
				var devices = []
				while not devices:
					devices = yield(current_game_stage._track_player.GetAvailableDevicesForConnection(), "completed")
				var connected = yield(current_game_stage._track_player.PerformDeviceConnection(devices[0].Id), "completed")
				assert(connected)
				current_game_stage.get_node("SetupOptionsContainer/PlaylistsSearch/LineEdit").emit_signal("text_changed", "indie rock")
				yield(_simulation_node.get_tree().create_timer(5), "timeout")
				var results_button = current_game_stage.get_node("SetupOptionsContainer/PlaylistsSearch/SearchResultsScrollContainer/SearchResults").get_children()
				for i in range(5):
					results_button[i].emit_signal("pressed")
				yield(_simulation_node.get_tree().create_timer(1), "timeout")
				current_game_stage.get_node("SetupOptionsContainer/PlayButton").emit_signal("pressed")
			elif current_game_stage.get_name() == "MusiQLobbyStage":
				yield(._create_simulation_players(), "completed")
				yield(._do_lobby(), "completed")
				yield(._do_start_game(_start_game_prompt_input_id), "completed")
			elif current_game_stage.get_name() == "MusiQGameCreditsStage":
				yield(_simulation_node.get_tree().create_timer(1), "timeout")
				current_game_stage.get_node("Container/ActionsContainer/PlayAgainSamePlayersButton").emit_signal("pressed")

		func _on_player_receieved_message(message, player):
			if current_game_stage.get_name() == "MusiQLobbyStage" and message.type == "request_input":
				_start_game_prompt_input_id = message.data.promptData.id
			elif "MusiQContestsGameStage" in current_game_stage.get_name():
				if message.type == "request_input" and message.data.promptType == "song_search":
					_handle_musiq_prompt_request(player, message.data.promptData)
		
		func _handle_musiq_prompt_request(player, prompt_data):
			randomize()
			yield(.delay(rand_range(2, 8)), "completed")
			var contest_id = prompt_data.id
			var track_id
			if rand_range(0, 100) > 50: # players skip n % of the time
				if rand_range(0, 100) < 30: # players correct n % of the time when they guess
					track_id = current_game_stage._current_contest.track.Id
				else:
					track_id = "4cOdK2wGLETKBW3PvgPWqT"
			player.send_message(Message.create(Message.PROMPT_RESPONSE, {
				"id": contest_id,
				"roomCode": Room.code,
				"trackId": track_id
			}))
