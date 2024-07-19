extends Node

enum GameState {
	MAIN_MENU,
	PAUSED,
	PLAYING,
	LOADING
}

const MAIN := preload("res://scenes/main.tscn")

var environment : WorldEnvironment

# Gets connected automatically
func _on_new_game_requested():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_packed(MAIN)
