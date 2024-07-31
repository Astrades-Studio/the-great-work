extends CanvasLayer

@onready var pause_container: CenterContainer = %PauseContainer
@onready var quit_confirmation: CenterContainer = %QuitConfirmation
@onready var settings_container: CenterContainer = %SettingsContainer

@onready var continue_button: Button = %ContinueButton
@onready var back_button: Button = settings_container.back_button
@onready var quit_refuse_button: Button = %QuitRefuseButton

func _ready() -> void:
	hide_pause_menu()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if quit_confirmation.visible:
			_on_quit_refuse_button_pressed()
		elif settings_container.visible:
			_on_back_button_pressed()
		elif pause_container.visible:
			hide_pause_menu()
		elif GameManager.current_state == GameManager.GameState.PLAYING:
			show_pause_menu()
		


func show_pause_menu():
	show()
	GameManager.current_state = GameManager.GameState.PAUSED
	pause_container.show()
	continue_button.grab_focus()


func hide_pause_menu():
	GameManager.current_state = GameManager.GameState.PLAYING
	quit_confirmation.hide()
	settings_container.hide()
	pause_container.hide()
	hide()


func _on_continue_button_pressed() -> void:
	hide_pause_menu()
	

func _on_restart_button_pressed() -> void:
	self.hide_pause_menu()
	GameManager.current_state = GameManager.GameState.CUTSCENE
	GameManager.reset_progress()
	GameManager.clear_arrays()
	TransitionManager.change_scene_to_file(GameManager.MAIN_SCENE)
	

func _on_settings_button_pressed() -> void:
	settings_container.show()
	back_button.grab_focus()

func _on_back_button_pressed() -> void:
	settings_container.hide()
	show_pause_menu()


func _on_quit_button_pressed() -> void:
	quit_confirmation.show()
	quit_refuse_button.grab_focus()
	

func _on_quit_confirm_button_pressed() -> void:
	get_tree().quit()
	

func _on_quit_refuse_button_pressed() -> void:
	quit_confirmation.hide()
	show_pause_menu()
