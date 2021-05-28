extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$MemeRenderer.init(preload("res://meme_game/meme/templates/BernieOnceAgainAsking.tres"), ["TESTING 123!"])
	$MemeRenderer.get_as_image()


	# Called every frame. 'delta' is the elapsed time since the previous frame.
	#func _process(delta):
	#	pass
