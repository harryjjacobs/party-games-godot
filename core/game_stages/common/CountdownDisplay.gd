extends HBoxContainer

onready var countdown_label = $CountdownLabel
onready var text_label = $TextLabel
onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	_hide()

func start(duration):
	timer.start(duration)
	_show()

func stop():
	timer.stop()
	_hide()

func _show():
	_update_text()
	text_label.visible = true
	countdown_label.visible = true

func _hide():
	text_label.visible = false
	countdown_label.visible = false

func _process(_delta):
	if not timer.is_stopped():
		_update_text()

func _update_text():
	countdown_label.text = "%d" % int(timer.time_left)

#TODO
func _tween_entry():
	pass

func on_Timer_timeout():
	timer.stop()
	_hide()
