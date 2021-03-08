extends Object
class_name Player

var client_id = ''
var username = ''
var points = 0
var points_history = []

class PointChange extends Object:
  var amount: int
  var reason: String
  func _init(_amount: int, _reason: String = ""):
    amount = _amount
    reason = _reason

func _init(player_client_id, player_name):
  client_id = player_client_id
  username = player_name

func reset():
  points = 0
  points_history = []
  
func update_points(amount, reason = ""):
  points_history.push_front(PointChange.new(amount, reason))
  points += amount

func get_points_history_until(historical_points: int):
  var history = []
  var points_snapshot = points
  for point_change in points_history:
    if points_snapshot == historical_points:
      return history
    history.push_front(point_change)
    points_snapshot -= point_change.amount