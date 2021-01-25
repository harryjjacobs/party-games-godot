extends Node2D
class_name PlayerIcon

const Player = preload("res://player/Player.gd")

onready var label: Label = $"PlayerNameLabel"
onready var tween: Tween = $"Tween"

var player: Player

func _ready():
	if player:
		label.text = player.name
	tween_entry()

func init(_player: Player):
	player = _player

func tween_position_to(position: Vector2):
	var _x = tween.interpolate_property($Node2D, "position",
		position, position, 0.8,
		Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
	var _err = tween.start()

func tween_entry():
	var orig_scale = scale
	var _x = tween.interpolate_property($PlayerSprite, "scale",
		Vector2.ZERO, orig_scale, 1.0,
		Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
	var _err = tween.start()
