extends Sprite

onready var _animation_player = $AnimationPlayer

func spin(enabled):
	if enabled:
		_animation_player.play("SpinningVinyl")
	else:
		_animation_player.stop()
