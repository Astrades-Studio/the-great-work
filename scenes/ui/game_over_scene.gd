extends Control

@onready var retry_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/RetryButton
@onready var quit_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/QuitButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	retry_button.grab_focus()


func _on_retry_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
