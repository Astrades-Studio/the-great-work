extends Control
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
const INTRO_ASTRA = preload("res://assets/sounds/music/intro astra.mp3")
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("fade in")
	audio_stream_player.stream = INTRO_ASTRA
	audio_stream_player.volume_db = 10.0  # Ajusta el volumen a -10 dB, puedes cambiar este valor
	audio_stream_player.play()
	# MusicManager.play_music(INTRO_ASTRA) # Comenta o elimina esta línea si no es necesaria

func go_title_screen():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _input(event):
	if(event is InputEventKey) or (event is InputEventMouseButton):
		if OS.is_debug_build():
			animation_player.speed_scale *= 3.0
		else:
			animation_player.speed_scale = 3.0
		
func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	go_title_screen()
