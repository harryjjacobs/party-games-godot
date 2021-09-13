extends Object

var _rounds_generated_count = 0

func _generate_player_pairs(players):
	assert(len(players) > 1)
	if len(players) == 2:
		return [
			{ "a": players[0], "b": players[1] }, 
			{ "a": players[1], "b": players[0] }, 
		]
	var pairs = Array()
	var seen = []
	for i in len(players):
		var j = (i + _rounds_generated_count + 1) % len(players)
		while j == i or ("%s.%s" % [i, j]) in seen:
			j = (j + 1) % len(players)
		pairs.append({"a": players[i], "b": players[j]})
		seen.append("%s.%s" % [i, j])
		seen.append("%s.%s" % [j, i])
	return pairs
