extends WindowDialog

func _ready():
	var _err = Events.connect("game_paused", self, "_on_game_paused")

func _on_game_paused():
	popup_centered()