extends "res://core/round/RoundGenerator.gd"
class_name MusiQRoundGenerator

enum GameDurationProfile {
	SHORT,
	MEDIUM,
	LONG 
}

const _max_track_count = {
	GameDurationProfile.SHORT: {
		MusiQContest.ContestType.ALLVALL: 2,
		MusiQContest.ContestType.HEAD2HEAD: 1
	},
	GameDurationProfile.MEDIUM: {
		MusiQContest.ContestType.ALLVALL: 10,
		MusiQContest.ContestType.HEAD2HEAD: 2
	},
	GameDurationProfile.LONG: {
		MusiQContest.ContestType.ALLVALL: 15,
		MusiQContest.ContestType.HEAD2HEAD: 2
	}
}

var _contest_builder: MusiQContestBuilder
var _game_duration

func _init(contest_builder: MusiQContestBuilder, game_duration):
	_contest_builder = contest_builder
	_game_duration = game_duration

func next(contest_type, p_players, point_weight = 1):
	var players = p_players.duplicate()
	players.shuffle()
	var contests
	match contest_type:
		MusiQContest.ContestType.ALLVALL:
			contests = _generate_shared_player_contests(contest_type, players, point_weight)
		MusiQContest.ContestType.HEAD2HEAD:
			contests = _generate_two_player_contests(contest_type, players, point_weight)
		_:
			Log.error("Invalid ContestType: %s" % contest_type)
	var r = Round.new()
	r.contests = contests
	_rounds_generated_count += 1
	return r

# Generate contests with all players competing against each other
func _generate_shared_player_contests(contest_type, players, point_weight):
	var contests = []
	var max_track_count = _max_track_count[_game_duration][contest_type]
	for _i in range(0, max_track_count):
		var contest = _contest_builder.build(players, point_weight, contest_type)
		contests.push_back(contest)
	return contests

func _generate_two_player_contests(contest_type, players, point_weight):
	var pairs = ._generate_player_pairs(players)
	var contests = Array()
	for pair in pairs:
		var contest = _contest_builder.build(
			[pair.a, pair.b], point_weight, contest_type)
		contests.append(contest)
	return contests
