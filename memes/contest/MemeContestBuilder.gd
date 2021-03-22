extends Node2D
class_name MemeContestBuilder

const uuid = preload("res://core/util/uuid/uuid.gd")

export(Array, Resource) var meme_templates
export(String) var themes_file = 'res://memes/contest/nouns.txt'

var _themes = []
var _meme_template_pool: Array
var _theme_pool = []
var _contexts = {}

var meme_types_for_contest = {
	MemeContest.ContestType.BASIC: [
		MemeTemplate.MemeTemplateType.EMPTY_CAPTION
	],
	MemeContest.ContestType.THEMED: [
		MemeTemplate.MemeTemplateType.EMPTY_CAPTION
	],
	MemeContest.ContestType.BLANK_FILL: [
		MemeTemplate.MemeTemplateType.BLANK_FILL
	]
}

func _ready():
	_meme_template_pool = meme_templates.duplicate()
	_meme_template_pool.shuffle()
	_themes = _load_themes_file()

func using_context():
	return _ContextualBuild.new(self)

func create_context():
	var context = _Context.new()
	_contexts[context.id] = context
	return context.id

func destroy_context(context_id):
	if _contexts.has(context_id):
		_contexts.erase(context_id)

# useful for building contests which will happen within a context/group - e.g. 
# contests in the same round. When building in a context, contests will share
# certain features such as theme, or meme template
func build_with_context(context_id, players: Array, vote_weight, contest_type):
	if not _contexts.has(context_id):
		printerr("context with context_id % not found" % context_id)
	var context = _contexts[context_id]
	var contest = MemeContest.new()
	contest.players = players
	contest.type = contest_type
	contest.vote_weight = vote_weight
	match contest_type:
		MemeContest.ContestType.BASIC:
			contest.meme_template = _next_template(contest_type)
		MemeContest.ContestType.THEMED:
			contest.meme_template = _next_template(contest_type)
			if context.common_theme():
				contest.theme = context.common_theme()
			else:
				contest.theme = _next_theme()
		_:
			printerr("Invalid ContestType: %s" % contest_type)
	context.add_contest(contest)
	return contest

func build(players: Array, vote_weight, contest_type):
	return build_with_context(create_context(), players, vote_weight, contest_type)

func _next_template(contest_type):
	if _meme_template_pool.empty():
		_meme_template_pool = meme_templates.duplicate()
	var valid_meme_types = meme_types_for_contest[contest_type]
	while not _meme_template_pool.empty():
		var template = _meme_template_pool.pop_front()
		if template.type in valid_meme_types:
			return template

func _next_theme():
	if _theme_pool.empty():
		_theme_pool = _themes.duplicate()
	return _theme_pool.pop_front()

func _load_themes_file():
	var f = File.new()
	f.open(themes_file, File.READ)
	var nouns = []
	while not f.eof_reached(): # iterate through all lines until the end of file is reached
		var line = f.get_line()
		nouns.append(line)
	f.close()
	nouns.shuffle()
	return nouns

class _ContextualBuild:
	var _context_id
	var _builder
	func _init(builder):
		_builder = builder
		_context_id = _builder.create_context()

	func _notification(what):
		# auto-remove the context when this object is deleted
		if what == NOTIFICATION_PREDELETE:
			_builder.destroy_context(_context_id)

	func build(players: Array, vote_weight, contest_type):
		return _builder.build_with_context(_context_id, players, vote_weight, contest_type)

class _Context:
	var id = uuid.v4()
	var _contests = []

	func add_contest(contest):
		_contests.append(contest)

	func common_theme():
		if len(_contests) > 0:
			return _contests[0].theme

	func common_template():
		if len(_contests) > 0:
			return _contests[0].meme_template
