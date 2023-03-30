extends "res://core/game_stages/common/GameStage.gd"

const AnswerLabel = preload("res://quiz_game/game_stages/question_stage/QuizGameAnswerOption.tscn")

export var duration = 20

onready var _question_label = $VBoxContainer/QuizGameQuestion
onready var _answers_container = $VBoxContainer/AnswersContainer
onready var _player_icon_display = $VBoxContainer/PlayerIconDisplay
onready var _countdown_display = $CountdownDisplay

var _current_question

func enter(params):
	.enter(params)
	_current_question = params.current_round.questions[params.question_index]
	# TODO: tween animation
	_question_label.text = _current_question.trivia.question
	if is_inside_tree():
		yield(get_tree().create_timer( 0.5), "timeout")
	for option in QuizTrivia.get_answers_as_options(_current_question.trivia.answers):
		var answer_label = AnswerLabel.instance()
		answer_label.text = option
		_answers_container.add_child(answer_label)
		if get_tree():
			if is_inside_tree():
				yield(get_tree().create_timer( 0.5), "timeout")
	NetworkInterface.on_player(Message.PROMPT_RESPONSE, self, "_on_response_received")
	set_timeout(duration, params)
	_countdown_display.start(duration)
	_send_question_prompt_to_players()

func exit():
	NetworkInterface.send_players(Room.players, Message.create(Message.HIDE_PROMPT, {}))
	NetworkInterface.off_player(Message.PROMPT_RESPONSE, self, "_on_response_received")
	_player_icon_display.clear()
	NodeUtils.remove_children(_answers_container)
	return .exit()

func get_group_name():
	return "q_and_a"

func _on_response_received(client_id, message):
	var player = Room.find_player_by_id(client_id)
	if not player:
		Log.warn("Message from unknown client_id recieved %s. Ignoring" % client_id)
		return
		
	Log.info("Prompt response received from %s (%s)" % [client_id, player.username])
	
	print(_current_question.id)
	print(message.data.id)
	
	if _current_question.id != message.data.id:
		Log.warn("Invalid ID received for current question. Ignoring")
		return
		
	for existing_response in _current_question.responses:
		if existing_response.player.client_id == player.client_id:
			Log.warn("Response already received from player %s. Ignoring" % player.username)
			return
			
	NetworkInterface.send_player(player, Message.create(Message.HIDE_PROMPT, {}))
	_current_question.responses.push_back(QuizQuestionResponse.new(player, message.data.choice))
	_player_icon_display.add_player(player)
	
	if len(_current_question.responses) == len(Room.players):
		if is_inside_tree():
			yield(get_tree().create_timer(1.0), "timeout")
		if is_inside_tree():
			emit_signal("request_exit", _parameters)
	
func _send_question_prompt_to_players():
	var options = QuizTrivia.get_answers_as_options(_current_question.trivia.answers)
	NetworkInterface.send_players(Room.players, Message.create(Message.REQUEST_INPUT, {
		"promptType": "multichoice",	# input type
		"promptData": {	# data that corresponds to input type
			"id": _current_question.id,
			"prompt": _current_question.trivia.question,
			"options": options
		}
	}))
