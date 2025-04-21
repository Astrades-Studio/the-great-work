extends Area3D

var played = false

func _on_body_entered(body: Node3D) -> void:
	if body is Player and GameManager.flare_recipe_read and !played:
		GameManager.shadow_crawl_trigger.emit()
		played = true
