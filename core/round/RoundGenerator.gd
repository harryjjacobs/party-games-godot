extends Object

# how many times this pairing has occured previously
var _pair_frequency = {}
var _player_frequency = {}

func _pair_id(a: Player, b: Player):
	# ensure that the pair id is always the same regardless of the order of a and b
	var id_a
	var id_b
	if a.client_id < b.client_id:
		id_a = a.client_id
		id_b = b.client_id
	else:
		id_a = b.client_id
		id_b = a.client_id
	return "%s.%s" % [id_a, id_b]

func _get_pair_score(a: Player, b: Player):
	var score = 0
	
	var player_score = 0
	if a in _player_frequency:
		player_score += _player_frequency[a]
	if b in _player_frequency:
		player_score += _player_frequency[b]
	
	var biggest_player_score = 0
	for freq in _player_frequency.values():
		if freq > biggest_player_score:
			biggest_player_score = freq
	
	var pair_score = 0
	var pair_score_multiplier = biggest_player_score + 1
	var id = _pair_id(a, b)	
	if id in _pair_frequency:
		pair_score = _pair_frequency[id] * pair_score_multiplier
		
	score = player_score + pair_score
	return score
	
func _update_pair_score(a: Player, b: Player):
	var id = _pair_id(a, b)
	if not id in _pair_frequency:
		_pair_frequency[id] = 0	
	_pair_frequency[id] += 1
	if not a in _player_frequency:
		_player_frequency[a] = 0
	_player_frequency[a] += 1
	if not b in _player_frequency:
		_player_frequency[b] = 0
	_player_frequency[b] += 1

func _get_all_pairings(player: Player, all_players: Array):
	var pairings = []
	for other_player in all_players:
		if player == other_player:
			continue
		pairings.push_back({ "a": player, "b": other_player })
	return pairings

func _sort_by_pair_frequency(pair_a, pair_b):
	if _get_pair_score(pair_a.a, pair_a.b) < _get_pair_score(pair_b.a, pair_b.b):
		return true
	return false

func _generate_player_pairs(players: Array, sets: int = 2):
	assert(len(players) > 1)
	var players_shuffled = players.duplicate()
	if len(players) == 2:
		return [
			{ "a": players[0], "b": players[1] }, 
			{ "a": players[1], "b": players[0] }, 
		]
	var pairs = []
	for _i in range(sets):
		players_shuffled.shuffle()		
		for player in players_shuffled:
			var pairings = _get_all_pairings(player, players_shuffled)
			pairings.sort_custom(self, "_sort_by_pair_frequency")
			var pair = pairings[0]
			pairs.push_back(pair)	# pair that has occurred the least
			_update_pair_score(pair.a, pair.b)
	return pairs
