extends "res://core/round/RoundGenerator.gd"
class_name MemeRoundGenerator

var _players: Array
var _contest_builder: MemeContestBuilder

func _init(players, contest_builder: MemeContestBuilder):
	_players = players.duplicate()
	_players.shuffle()
	_contest_builder = contest_builder

func next(contest_type, vote_weight = 1):
	var contests
	match contest_type:
		MemeContest.ContestType.THEMED, MemeContest.ContestType.BASIC:
			contests = _generate_two_player_contests(contest_type, vote_weight)
		_:
			Log.error("Invalid ContestType: %s" % contest_type)
	var r = Round.new()
	r.contests = contests
	return r

# Generate two contests per player per round
# whereby players are matched against each other
# in an even manner
func _generate_two_player_contests(contest_type, vote_weight):
	var pairs = ._generate_player_pairs(_players, 1)
	var contests = Array()
	var builder_context = _contest_builder.using_context()
	for pair in pairs:
		var contest = builder_context.build(
			[pair.a, pair.b], vote_weight, contest_type)
		contests.append(contest)
	return contests
