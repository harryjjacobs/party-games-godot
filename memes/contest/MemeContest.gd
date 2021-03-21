extends Resource
class_name MemeContest

enum ContestType {
	BASIC = 1,
	THEMED = 2,
	BLANK_FILL = 4
}

var type
var id: String
var players: Array = Array()
var meme_template: MemeTemplate
var responses: Array = Array()
var votes: Array = Array()
var vote_weight = 10

func _init():
	id = preload("res://core/util/uuid/uuid.gd").v4()