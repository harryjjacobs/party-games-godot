extends Object
class_name MemeContestVote

var choice: MemeContestResponse
var voter: Player

func _init(_vote: MemeContestResponse, _voter: Player):
  choice = _vote
  voter = _voter
