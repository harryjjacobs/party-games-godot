extends Resource
class_name MemeContest

enum ContestType {
	TWO_PLAYER,
	MULTI_PLAYER
}

var type
var id: String
var players: Array = Array()
var meme_template: MemeTemplate
var responses: Array = Array()
var votes: Array = Array()
var vote_weight = 1

func _init():
	id = preload("res://core/util/uuid/uuid.gd").v4()