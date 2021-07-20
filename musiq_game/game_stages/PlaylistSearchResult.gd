extends Button

onready var _name_label = $HBoxContainer/VBoxContainer/NameLabel
onready var _author_label = $HBoxContainer/VBoxContainer/AuthorLabel

func init(result):
	_name_label.text = result.Title
	if "Author" in result and result.Author:
		_author_label.text = result.Author
	elif "Artists" in result and result.Artists:
		_author_label.text = PoolStringArray(result.Artists).join(", ")
