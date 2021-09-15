extends Button

onready var _name_label = $HBoxContainer/VBoxContainer/NameLabel
onready var _author_label = $HBoxContainer/VBoxContainer/AuthorLabel

var result

func init(search_result):
	self.result = search_result
	_name_label.text = search_result.Title
	if "Author" in search_result and search_result.Author:
		_author_label.text = search_result.Author
	elif "Artists" in search_result and search_result.Artists:
		_author_label.text = PoolStringArray(search_result.Artists).join(", ")
	$HBoxContainer/NetworkTextureRect.set_url(search_result.Image.Url)
