extends Area3D

const SHADOW_BLOCK_DIALOG = preload("res://assets/dialog/shadow_block_dialog.tres")
@onready var target_position: Node3D = $TargetPosition

func _on_body_entered(body: Node3D) -> void:
	if GameManager.shadow_dispelled:
		return
	if body is Player and GameManager.flare_already_made:
		DialogManager.play_dialog(SHADOW_BLOCK_DIALOG)
		await DialogManager.dialog_finished

		var tween: Tween = get_tree().create_tween()
		tween.tween_property(body, "global_position", target_position.global_position, 1)
