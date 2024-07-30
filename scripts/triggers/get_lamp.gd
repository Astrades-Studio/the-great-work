extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		if GameManager.lamp_in_hand:
			return
		DialogManager.create_subtitles_piece("That gas lamp might prove useful.")
