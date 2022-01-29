extends WindowDialog

const _game_selection_button = preload("res://core//ui/dialogs/GameSelectionButton.tscn")

signal selected(game_type)

onready var _game_selection_grid = $VBoxContainer/GameSelectionGrid

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		accept_event()
		hide()

func set_game_selection_options(options):
	NodeUtils.remove_children(_game_selection_grid)
	for option in options:
		var button = _game_selection_button.instance()
		_game_selection_grid.add_child(button)
		button.text = option.name
		button.connect("pressed", self, "_on_selection_button_pressed", [option.game_type])

func _on_selection_button_pressed(game_type):
	emit_signal("selected", game_type)
	hide()
