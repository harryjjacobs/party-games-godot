extends Node2D

export(Resource) var meme_template

onready var _meme_renderer = $MemeRenderer

func _ready():
	_meme_renderer.render(meme_template, [
		"This is a caption... Testing abcdefg hijklmno 789. Hello"
	])
	var img = yield(_meme_renderer.capture(), "completed")
	assert(img)
	assert(img.get_size() != Vector2.ZERO)
	_save_meme_to_disk(_meme_renderer)
	print("TEST PASSED")

func _save_meme_to_disk(meme_renderer):
	# save meme to disk
	var path = "user://saved_memes"
	FileUtils.open_user_dir(path, true)
	var img = yield(meme_renderer.capture(), "completed")
	var filename = "TEST" + "_" + Time.formatted_timestamp() + ".png"
	img.save_png(path + "/" + filename)
