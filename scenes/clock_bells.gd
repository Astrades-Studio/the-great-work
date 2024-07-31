extends Area3D
@onready var clock_bells: AudioStreamPlayer3D = $ClockBells

var played : bool = false

func _on_body_entered(body: Node3D) -> void:
	clock_bells.play()
	played = true
