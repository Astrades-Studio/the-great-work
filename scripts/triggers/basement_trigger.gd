extends Area3D

@export_multiline var trigger_dialogue : String


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		await DialogManager.create_subtitles_piece(trigger_dialogue, 2.5)
		queue_free()
