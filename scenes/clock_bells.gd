extends Area3D
@onready var clock_bells: AudioStreamPlayer3D = $ClockBells

var played : bool = false

func _on_body_entered(body: Node3D) -> void:
	if !played:
		clock_bells.play()
		played = true
