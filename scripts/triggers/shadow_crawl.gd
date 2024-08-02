extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body is Player and GameManager.flare_recipe_read:
		GameManager.shadow_crawl_trigger.emit()
