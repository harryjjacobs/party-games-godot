extends Node

enum Types { UNTITLED_MEME_GAME, MUSIQ, QUIZ }

const STRING_IDS = {
	Types.UNTITLED_MEME_GAME: "untitled_meme_game",
	Types.MUSIQ: "musiq",
	Types.QUIZ: "pub_quiz"
}

const NAMES = {
	Types.UNTITLED_MEME_GAME: "untitled meme game",
	Types.MUSIQ: "MusiQ",
	Types.QUIZ: "Pub Quiz"
}

const SCENES = {
	Types.UNTITLED_MEME_GAME: preload("res://meme_game/Memes.tscn"),
	Types.MUSIQ: preload("res://musiq_game/Musiq.tscn"),
	Types.QUIZ: preload("res://quiz_game/Quiz.tscn")
}

const THEMES = {
	Types.UNTITLED_MEME_GAME: preload("res://meme_game/ui/MemeGameTheme.tres"),
	Types.MUSIQ: preload("res://musiq_game/ui/MusiQTheme.tres"),
	Types.QUIZ: preload("res://quiz_game/ui/QuizGameTheme.tres")
}
