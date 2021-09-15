extends Object
class_name Player

var client_id = ''
var username = ''
var points = 0
var points_history = []
var color: Color = Color.aquamarine

class PointChange extends Object:
	var amount: int
	var reason: String
	var group
	func _init(_amount: int, _group: String, _reason: String = ""):
		amount = _amount
		reason = _reason
		group = _group

func _init(player_client_id, player_name):
	client_id = player_client_id
	username = player_name

func reset():
	points = 0
	points_history = []
	
func update_points(amount, group: String, reason = ""):
	points_history.push_front(PointChange.new(amount, group, reason))
	points += amount

func get_points_history_by_group(group):
	var history = []
	for point_change in points_history:
		if point_change.group == group:
			history.append(point_change)
	return history

func get_point_change_by_group(group):
	var change = 0
	for point_change in points_history:
		if point_change.group == group:
			change += point_change.amount
	return change

static func sort_players_descending_by_points(players):
	players.sort_custom(PointsSorter, "_sort_descending")
	return players

class PointsSorter: 
	static func _sort_descending(a, b):
		return b.points < a.points
