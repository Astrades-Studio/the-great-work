extends Control

@onready var retry_button: Button = %RetryButton
@onready var quit_button: Button = %QuitButton
@onready var bad_ending_ui: Control = $BadEndingUI
@onready var good_ending_ui: Control = $GoodEndingUI


@onready var video_stream_player: VideoStreamPlayer = $GoodEndingUI/VideoStreamPlayer

const CREDITS = "res://scenes/ui/credits.tscn"

func _ready() -> void:
	video_stream_player.finished.connect(_on_video_finished)
	if GameManager.good_ending:
		bad_ending_ui.hide()
		good_ending_ui.show()
		video_stream_player.play()
		
	else:
		bad_ending_ui.show()
		good_ending_ui.hide()
		retry_button.grab_focus()


func _on_retry_button_pressed() -> void:
	GameManager.reset_progress()
	GameManager.clear_arrays()
	TransitionManager.change_scene_to_file(GameManager.MAIN_SCENE)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_video_finished():
	TransitionManager.change_scene_to_file(CREDITS)
