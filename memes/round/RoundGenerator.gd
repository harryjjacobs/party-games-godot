extends Object
class_name RoundGenerator

var _players: Array
var _contest_builder: MemeContestBuilder
var _count = 0

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
			printerr("Invalid ContestType: %s" % contest_type)
	var r = Round.new()
	r.contests = contests
	_count += 1
	return r

# Generate two contests per player per round
# whereby players are matched against each other
# in an even manner
func _generate_two_player_contests(contest_type, vote_weight):
	var pairs = _generate_player_pairs()
	var contests = Array()
	var builder_context = _contest_builder.using_context()
	for pair in pairs:
		var contest = builder_context.build(
			[pair.a, pair.b], vote_weight, contest_type)
		contests.append(contest)
	return contests

func _generate_player_pairs():
	assert(len(_players) > 1)
	if len(_players) == 2:
		return [
			{ "a": _players[0], "b": _players[1] }, 
			{ "a": _players[1], "b": _players[0] }, 
		]
	var pairs = Array()
	var seen = []
	for i in len(_players):
		var j = (i + _count + 1) % len(_players)
		while j == i or ("%s.%s" % [i, j]) in seen:
			j = (j + 1) % len(_players)
		pairs.append({"a": _players[i], "b": _players[j]})
		seen.append("%s.%s" % [i, j])
		seen.append("%s.%s" % [j, i])
	return pairs
