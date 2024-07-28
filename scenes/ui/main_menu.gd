class_name MainMenu
extends Control

@onready var new_game_button: Button = %NewGameButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var audio_stream_player_4: AudioStreamPlayer = $AudioStreamPlayer4
@onready var audio_stream_player_5: AudioStreamPlayer = $AudioStreamPlayer5

signal new_game_requested

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.MAIN_MENU
	new_game_requested.connect(GameManager._on_new_game_requested)
	new_game_button.grab_focus()

func _on_new_game_button_pressed() -> void:
		new_game_requested.emit()
		audio_stream_player_5.play()

func _on_settings_button_pressed() -> void:
	pass # Replace with function body.

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_button_mouse_entered() -> void:
	var pitches = [0.80, 1.30, 0.95]
	audio_stream_player_4.pitch_scale = pitches[randi() % pitches.size()]
	audio_stream_player_4.play()

func _on_button_mouse_exited() -> void:
	audio_stream_player_4.stop()


func _on_focus_entered() -> void:
	var pitches = [0.80, 1.30, 0.95]
	audio_stream_player_4.pitch_scale = pitches[randi() % pitches.size()]
	audio_stream_player_4.play()

func _on_focus_exited() -> void:
	var pitches = [0.80, 1.30, 0.95]
	audio_stream_player_4.pitch_scale = pitches[randi() % pitches.size()]
	audio_stream_player_4.play()
