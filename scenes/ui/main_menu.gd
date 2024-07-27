class_name MainMenu
extends Control

@onready var new_game_button: Button = %NewGameButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

signal new_game_requested

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.MAIN_MENU
	new_game_requested.connect(GameManager._on_new_game_requested)
	
	new_game_button.grab_focus()

func _on_new_game_button_pressed() -> void:
		new_game_requested.emit()


func _on_settings_button_pressed() -> void:
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	get_tree().quit()
