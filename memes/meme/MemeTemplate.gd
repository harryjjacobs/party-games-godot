extends Resource
class_name MemeTemplate

export(Texture) var image
export(Array, Resource) var captions = Array()

func to_json():
	var captions_json = Array()
	for caption in captions:
		captions_json.append({
			"area": {
				"x": caption.x,
				"y": caption.y,
				"width": caption.width,
				"height": caption.height
			},
			"rotation": caption.rotation,
			"color": caption.text_color.to_html(false)
		})
	return {
		"image": _base64_image(),
		"captions": captions_json
	}

func _base64_image():
	return Marshalls.raw_to_base64(image.get_data().save_png_to_buffer())
