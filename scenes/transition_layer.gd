extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal animation_finished

func _ready() -> void:
	GameManager.game_started.connect(_on_game_start)
	
func _on_game_start():
	animation_player.play("fade_in")
	animation_player.animation_finished.connect(on_animation_finished)
	
func on_animation_finished(_anim_name: StringName) -> void:
	animation_finished.emit()
