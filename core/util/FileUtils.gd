class_name FileUtils

static func open_user_dir(path: String, make_if_necessary: bool):
	if not path.begins_with("user://"):
		path = "user://" + path
	var d = Directory.new()
	if not d.dir_exists(path):
		if make_if_necessary:
			var res = OK
			res = d.open("user://")
			if res != OK:
				return res
			res = d.make_dir_recursive(path)
			if res != OK:
				return res
		else:
			return ERR_FILE_NOT_FOUND
	return d