tool
extends Node2D
class_name PlayerIcon

const Player = preload("res://core/player/Player.gd")

export var animate_entry = false
export(float) var position_movement_speed = 2
export(float) var points_label_change_speed = 1

onready var label: Label = $PlayerNameLabel
onready var sprite = $PlayerSprite
onready var tween: Tween = $Tween
onready var point_change_label: Label = $PointChangeLabel
onready var points_label: Label = $PointsLabel
onready var animation_player = $AnimationPlayer

var _points_label_text = "%d Pts"
var _player: Player

func _ready():
	_initialise()

func _initialise():
	if _player:
		label.text = _player.username
		sprite.modulate = _player.color
	point_change_label.visible = false
	points_label.visible = false

func init(player: Player):
	_player = player
	if is_inside_tree():
		_initialise()

func show():
	.show()	
	if animate_entry:
		yield(_animate_entry(), "completed")
	
func hide():
	if animate_entry:
		yield(_animate_exit(), "completed")
	.hide()

func tween_position_to(new_position: Vector2):
	var _x = tween.interpolate_property(self, "position",
		position, new_position, 1.0 / position_movement_speed,
		Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	var _err = tween.start()
	yield(tween, "tween_completed")

func tween_scale_to(new_scale: float):
	var _err = tween.interpolate_property(self, "scale",
		scale, Vector2.ONE * new_scale, 1.0 / position_movement_speed,
		Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_err = tween.start()
	yield(tween, "tween_completed")

func _animate_entry():
	if Engine.is_editor_hint():
		yield(get_tree(), "idle_frame")
		return
	if not is_inside_tree():
		yield(self, "ready")
	animation_player.play("IconEntrance")
	yield(animation_player, "animation_finished")

func _animate_exit():
	if Engine.is_editor_hint():
		yield(get_tree(), "idle_frame")
		return
	animation_player.play("IconExit")
	yield(animation_player, "animation_finished")

func show_points(show, points = null):
	if points != null:
		_set_points_label_text(points)
	points_label.visible = show

func animate_points_change(from, to):
	show_points(true, from)
	var _err = tween.interpolate_method(self, "_set_points_label_text",
		from, to, points_label_change_speed, Tween.TRANS_SINE, Tween.EASE_OUT)
	_err = tween.start()
	yield(tween, "tween_completed")

func animate_point_award(amount):
	var duration = 0.3
	var delay = 1.0
	var orig_scale = point_change_label.rect_scale
	var _err = tween.interpolate_property(point_change_label, "rect_scale",
		Vector2.ZERO, orig_scale, duration, Tween.TRANS_ELASTIC, Tween.EASE_IN)
	_err = tween.interpolate_property(point_change_label, "rect_scale",
		orig_scale, Vector2.ZERO, duration, Tween.TRANS_LINEAR, Tween.EASE_IN, duration + delay)
	point_change_label.rect_scale = Vector2.ZERO
	point_change_label.text = "+%d" % amount
	point_change_label.visible = true
	_err = tween.start()
	yield(tween, "tween_all_completed")
	point_change_label.visible = false
	point_change_label.rect_scale = orig_scale

func _set_points_label_text(points):
	points_label.text = _points_label_text % int(points)
