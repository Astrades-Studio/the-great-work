extends Node

const MAIN_SCENE := preload("res://scenes/main.tscn")

enum GameState {
	MAIN_MENU,
	PAUSED,
	PLAYING,
	LOADING
}

var current_state : GameState:
	set(value):
		current_state = value
		if current_state == GameState.PLAYING:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif current_state == GameState.PAUSED:
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

var environment : WorldEnvironment
var text_layer : TextLayer

signal update_interaction_label(string : String)

# Gets connected automatically
func _on_new_game_requested():
	current_state = GameState.PLAYING
	get_tree().change_scene_to_packed(MAIN_SCENE)

func request_page_UI(page: Texture):
	text_layer.show_text(page)
