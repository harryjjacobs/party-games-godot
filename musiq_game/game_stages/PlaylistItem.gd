extends Panel

signal request_remove

var item

func init(search_result):
	item = search_result
	$Label.text = search_result.Title
	$NetworkTextureRect.set_url(search_result.Image.Url)

func _on_RemoveButton_pressed():
	emit_signal("request_remove")
