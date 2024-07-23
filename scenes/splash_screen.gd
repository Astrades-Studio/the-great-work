extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("fade in")

func go_title_screen():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _input(event):
	if(event is InputEventKey):
		go_title_screen()
		

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	# Replace with function body.
		go_title_screen()
