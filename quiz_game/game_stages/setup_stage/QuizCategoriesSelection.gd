extends VBoxContainer

signal categories_updated(categories)

const CategoryButton = preload("res://quiz_game/game_stages/setup_stage/QuizRoundCategoryButton.tscn")

onready var _category_list = $ScrollContainer/CategoryList
onready var _chosen_categories_list = $ChosenCategoriesScrollContainer/ChosenCategoriesList

var _selected_categories = []

func populate(categories: Array):
	NodeUtils.remove_children(_category_list)
	for category in categories:
		var category_button = CategoryButton.instance()
		category_button.init(category)
		_category_list.add_child(category_button)
		category_button.connect("pressed", self, "_on_category_chosen", [category_button])

func _on_category_chosen(button):
	_selected_categories.push_back(button.category)
	var chosen_category_button = CategoryButton.instance()
	chosen_category_button.init(button.category)
	_chosen_categories_list.add_child(chosen_category_button)
	chosen_category_button.connect("pressed", self, "_on_category_remove", [chosen_category_button])
	emit_signal("categories_updated", _selected_categories)

func _on_category_remove(button):
	var index = _chosen_categories_list.get_children().find(button)
	_selected_categories.remove(index)
	_chosen_categories_list.remove_child(button)
	emit_signal("categories_updated", _selected_categories)
