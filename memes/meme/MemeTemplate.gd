extends Resource
class_name MemeTemplate

export(Texture) var image
export(Array, Resource) var captions = Array()
enum MemeTemplateType {EMPTY_CAPTION, BLANK_FILL}
export(MemeTemplateType, FLAGS) var type = MemeTemplateType.EMPTY_CAPTION

func to_json():
	var captions_json = Array()
	for caption in captions:
		captions_json.append(caption.to_json())
	return {
		"image": _base64_image(),
		"captions": captions_json
	}

func _base64_image():
	return Marshalls.raw_to_base64(image.get_data().save_png_to_buffer())
