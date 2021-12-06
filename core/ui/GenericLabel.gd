tool
extends Label

enum FontSizePreset { SMALL, MEDIUM, LARGE }

const _font_name_lookup = {
	FontSizePreset.SMALL: "small",
	FontSizePreset.MEDIUM: "medium",
	FontSizePreset.LARGE: "large",
}

export(FontSizePreset) var font_size = FontSizePreset.MEDIUM

func _ready():
	_update_font()

func _process(_delta):
	if Engine.is_editor_hint():
		_update_font()

func _update_font():
	add_font_override("font", get_font(_font_name_lookup[font_size], "Fonts"))
