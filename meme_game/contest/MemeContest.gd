extends Resource
class_name MemeContest

enum ContestType {
	BASIC,
	THEMED,
	BLANK_FILL
}

var type
var id: String
var players: Array = Array()
var meme_template: MemeTemplate
var theme: String
var responses: Array = Array()
var votes: Array = Array()
var vote_weight = 10

func _init():
	id = preload("res://core/util/uuid/uuid.gd").v4()