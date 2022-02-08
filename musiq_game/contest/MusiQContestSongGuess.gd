extends Node2D

onready var _title_label = $Panel/HBoxContainer/VBoxContainer/SongGuessTitleLabel
onready var _artists_label = $Panel/HBoxContainer/VBoxContainer/SongGuessArtistsLabel
onready var _artwork_image = $Panel/HBoxContainer/NetworkTextureRect
onready var _correct_sprite = $CorrectSprite
onready var _incorrect_sprite = $IncorrectSprite

func _ready():
	_correct_sprite.visible = false
	_incorrect_sprite.visible = false

func init(track):
	if track:
		_title_label.text = track.Title
		_artists_label.text = PoolStringArray(track.Artists).join(", ")
		if track.Image:
			_artwork_image.set_url(track.Image.Url)
	else:
		_title_label.text = ""
		_artists_label.text = ""
		_artwork_image.texture = null

func show_result(correct_answer: bool):
	if (correct_answer):
		_correct_sprite.visible = true
		$AnimationPlayer.play("CorrectAnswer")
	else:
		_incorrect_sprite.visible = true
		$AnimationPlayer.play("IncorrectAnswer")

