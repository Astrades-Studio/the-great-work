extends Area3D

const BASEMENT_FLARE_CHECK = preload("res://assets/dialog/basement_flare_check.tres")

var tween: Tween

@onready var target_position: Node3D = $TargetPosition


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		if GameManager.flare_already_made:
			return
		DialogManager.play_dialog(BASEMENT_FLARE_CHECK)
		await DialogManager.dialog_finished
		
		tween = get_tree().create_tween()
		
		tween.tween_property(body, "global_position", target_position.global_position, 1)
		
