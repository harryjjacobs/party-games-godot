extends Node

const DELAY_SCALER = 0.5
const NUM_PLAYERS = 6
const SIM_PLAYER_SCENE = preload("res://testing/simulation/SimulationPlayer.tscn")

var _game_type
var _game_scene
var _gameplay_controller
var _runner

func _process(_delta):
	_runner.current_game_stage = _gameplay_controller._current_stage.get_name()
	
func run(game_type, game_scene):
	Log.warn("==============RUNNING SIMULATION==============")
	NodeUtils.remove_children(self)
	_game_type = game_type
	_game_scene = game_scene
	_gameplay_controller = _game_scene.get_node("GameplayController")
	if game_type == GameTypes.Types.UNTITLED_MEME_GAME:
		_runner = _MemeGameSimulationRunner.new(self)
		yield(_runner.run(), "completed")

class _SimulationRunner:
	var current_game_stage
	var players = []
	var _simulation_node
	
	func _init(node):
		_simulation_node = node
	
	func run():
		pass
	
	func delay(time):
		yield(_simulation_node.get_tree().create_timer(time * DELAY_SCALER), "timeout")		

	func _on_player_receieved_message(message, player):
		pass
	
	func _create_simulation_players():
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
#	const NO_MEME_RESPONSE_FREQUENCY = 0.05
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
	
	func _on_player_receieved_message(message, player):
		if current_game_stage == "LobbyStage":
			if message.type == "request_input":
				_start_game_prompt_input_id = message.data.promptData.id
		elif "MemePromptRequestsStage" in current_game_stage:
			if message.type == "request_input" and message.data.promptType == "meme":
				_handle_meme_prompt_request(player, message.data.promptData)
		elif "MemeContestStage" in current_game_stage:
			if message.type == "request_input" and message.data.promptType == "multichoice":
				_handle_vote_request(player, message.data.promptData)
	
	func _handle_meme_prompt_request(player, prompt_data):
		randomize()		
		yield(.delay(rand_range(1, 5)), "completed")
		var contest_id = prompt_data.id
		var max_caption_length = prompt_data.maxInputLength
		var template = prompt_data.template
		print(template.captions)
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
		if rand_range(0, 100) < 20: # don't vote x% of the time
			return
		var contest_id = prompt_data.id
		var choice = rand_range(0, len(prompt_data.options))
		player.send_message(Message.create(Message.PROMPT_RESPONSE, {
			"id": contest_id,
			"choice": choice,
			"roomCode": Room.code
		}))
