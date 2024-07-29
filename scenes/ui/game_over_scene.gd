extends Control

@onready var retry_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/RetryButton
@onready var quit_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/QuitButton


func _ready() -> void:
	retry_button.grab_focus()


func _on_retry_button_pressed() -> void:
	TransitionManager.change_scene_to_file(GameManager.MAIN_SCENE)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
