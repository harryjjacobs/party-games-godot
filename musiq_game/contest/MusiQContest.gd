extends Resource
class_name MusiQContest

enum ContestType {
	ALLVALL,
	HEAD2HEAD,
}

var type
var id: String
var players: Array = Array()
var track: Object
var responses: Array = Array()
var point_weight = 1

func _init():
	id = preload("res://core/util/uuid/uuid.gd").v4()