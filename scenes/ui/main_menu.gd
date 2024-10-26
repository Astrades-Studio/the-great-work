class_name MainMenu
extends Control

@onready var new_game_button: Button = %NewGameButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var audio_stream_player_4: AudioStreamPlayer = $AudioStreamPlayer4
@onready var audio_stream_player_5: AudioStreamPlayer = $AudioStreamPlayer5
@onready var settings_container: CenterContainer = %SettingsContainer
@onready var audio_stream_player_6: AudioStreamPlayer = $AudioStreamPlayer6
@onready var credits: Control = $Credits

signal new_game_requested

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.MAIN_MENU
	new_game_requested.connect(GameManager._on_new_game_requested)
	settings_container.menu_closed.connect(button_grab_focus)


func button_grab_focus():
	new_game_button.grab_focus()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventJoypadButton:
		if event.is_pressed():
			if credits.visible:
				credits.hide()

# Hacky, check if it works
func _on_new_game_button_pressed() -> void:
	GameManager.philosopher_stone_recipe_read = false
	GameManager.alchemy_recipe_read = false
	GameManager.flare_recipe_read = false
	GameManager.flare_already_made = false
	GameManager.lamp_in_hand = false
	GameManager.first_shadow_encountered = false
	GameManager.shadow_dispelled = false
	GameManager.first_shadow_spawned = false
	GameManager.good_ending = false
	GameManager.bad_ending = false
	
	new_game_requested.emit()
	SfxManager.play_sound(load("res://assets/sounds/sfx/startnewgame_impact.mp3"), 0.5, 0.0)


func _on_settings_button_pressed() -> void:
	audio_stream_player_6.play()
	settings_container.show()

func _on_quit_button_pressed() -> void:
	audio_stream_player_6.play()
	get_tree().quit()

func _on_button_mouse_entered() -> void:
	var pitches = [0.80, 1.30, 0.95]
	audio_stream_player_4.pitch_scale = pitches[randi() % pitches.size()]
	audio_stream_player_4.play()

func _on_button_mouse_exited() -> void:
	audio_stream_player_4.stop()

func _on_back_button_pressed() -> void:
	audio_stream_player_6.play()
	settings_container.hide()
	settings_button.grab_focus()


func _on_credits_button_pressed() -> void:
	credits.show()
