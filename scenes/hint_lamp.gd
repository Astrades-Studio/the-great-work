extends Area3D
@onready var hint_lamp: AudioStreamPlayer3D = $HintLamp

var played : bool = false

func _on_body_entered(body: Node3D) -> void:
	hint_lamp.play()
	played = true
