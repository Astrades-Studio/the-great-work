extends Area3D
@onready var clock_bells: AudioStreamPlayer3D = $ClockBells

var played : bool = false

func _on_body_entered(body: Node3D) -> void:
	if body is Player and GameManager.philosopher_stone_recipe_read:
		if not played:
			clock_bells.play(5.78)
			played = true
