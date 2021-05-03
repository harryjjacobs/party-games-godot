extends Node2D

export(Resource) var meme_template

onready var _meme_renderer = $MemeRenderer

func _ready():
	_meme_renderer.init(meme_template, [
		"This is a caption... Testing abcdefg hijklmno 789. Hello"
	])
