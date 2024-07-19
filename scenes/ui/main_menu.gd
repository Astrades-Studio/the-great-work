class_name MainMenu
extends Control


signal new_game_requested

func _ready() -> void:
	new_game_requested.connect(GameManager._on_new_game_requested)

func _on_new_game_button_pressed() -> void:
	new_game_requested.emit()


func _on_settings_button_pressed() -> void:
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	pass # Replace with function body.
