extends Node

const MAIN_SCENE := preload("res://scenes/main.tscn")

enum GameState {
	MAIN_MENU,
	PAUSED,
	PLAYING,
	LOADING,
	DIALOG
}

# This variable goberns the inputs and pauses. Whenever there is a change, 
# it should be modified from anywhere needed. Just check for double calls
var current_state : GameState:
	set(value):
		current_state = value
		if current_state == GameState.PLAYING:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		elif current_state == GameState.PAUSED:
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		elif current_state == GameState.DIALOG:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		elif current_state == GameState.MAIN_MENU:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		elif current_state == GameState.LOADING:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		else:
			printerr("Invalid game state")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

var environment : WorldEnvironment
var text_layer : TextLayer
var player : UCharacterBody3D

signal update_interaction_label(string : String)
signal game_over
signal tick_countdown

# Gets connected automatically
func _on_new_game_requested():
	current_state = GameState.PLAYING
	get_tree().change_scene_to_packed(MAIN_SCENE)

func request_page_UI(page: Texture):
	text_layer.show_text(page)
