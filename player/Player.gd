extends Object
class_name Player

var client_id = ''
var name = ''
var points = 0
var point_history = []

func _init(player_client_id, player_name):
  client_id = player_client_id
  name = player_name