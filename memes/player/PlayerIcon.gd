extends Node2D
class_name PlayerIcon

const Player = preload("res://core/player/Player.gd")

export var animate_entry = false

onready var label: Label = $PlayerNameLabel
onready var tween: Tween = $Tween
onready var point_change_label: Label = $PointChangeLabel

var player: Player

func _ready():
	_initialise()

func _initialise():
	if player:
		label.text = player.username
	point_change_label.visible = false
	if animate_entry: 
		tween_entry()

func init(_player: Player):
	player = _player
	if is_inside_tree():
		_initialise()

func tween_position_to(position: Vector2):
	var _x = tween.interpolate_property($Node2D, "position",
		position, position, 0.8,
		Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
	var _err = tween.start()

func tween_entry():
	var orig_scale = $PlayerSprite.scale
	var _x = tween.interpolate_property($PlayerSprite, "scale",
		Vector2.ZERO, orig_scale, 1.0,
		Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
	$PlayerSprite.scale = Vector2.ZERO
	var _err = tween.start()

func tween_exit():
	var orig_scale = $PlayerSprite.scale
	var _x = tween.interpolate_property($PlayerSprite, "scale",
	orig_scale, Vector2.ZERO, 1.0,
		Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
	var _err = tween.start()

func tween_point_change(amount):
	var duration = 0.3
	var delay = 1.0
	var orig_scale = point_change_label.rect_scale
	var _success = tween.interpolate_property(point_change_label, "rect_scale",
		Vector2.ZERO, orig_scale, duration, Tween.TRANS_ELASTIC, Tween.EASE_IN)
	_success = tween.interpolate_property(point_change_label, "rect_scale",
		orig_scale, Vector2.ZERO, duration, Tween.TRANS_LINEAR, Tween.EASE_IN, duration + delay)
	point_change_label.rect_scale = Vector2.ZERO
	point_change_label.text = "+%d" % amount
	point_change_label.visible = true
	var _err = tween.start()
	yield(tween, "tween_all_completed")
	point_change_label.visible = false
