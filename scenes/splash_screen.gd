extends Control
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
const INTRO_ASTRA = preload("res://assets/sounds/music/intro astra.mp3")
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("fade in")
	#audio_stream_player.play(0.0)
	MusicManager.play_music(INTRO_ASTRA)

func go_title_screen():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _input(event):
	if(event is InputEventKey) or (event is InputEventMouseButton):
		animation_player.speed_scale= 3.0
		
 
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	# Replace with function body.
		go_title_screen()
