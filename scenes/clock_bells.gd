extends Area3D

@onready var clock_bells: AudioStreamPlayer3D = $ClockBells

var played : bool = false

func _on_body_entered(body: Node3D) -> void:
	if played:
		return
	if body is Player and GameManager.alchemy_recipe_read:
		clock_bells.play(6.0)
		played = true
			
