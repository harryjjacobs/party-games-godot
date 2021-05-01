extends SceneTree

const meme_template_dir = "res://memes/meme/templates"

func _init():
		print("Exporting meme templates to JSON")
		var paths = list_files_in_directory(meme_template_dir)
		for template_file in paths:
			var template_path = meme_template_dir + "/" + template_file
			print("Converting file: " + template_path)
			var meme_template = load(template_path)
			var json = JSON.print(meme_template.to_json())
			var directory = Directory.new()
			var new_dir = directory.get_current_dir() + "/memes/tools/exports/"
			directory.make_dir(new_dir)
			var json_filename = new_dir + template_file.replace(".tres", ".json")
			save(json_filename, json)
		quit()
		

func save(filename, content):
	var file = File.new()
	file.open(filename, File.WRITE)
	file.store_string(content)
	file.close()

func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files