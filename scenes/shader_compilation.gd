extends Node3D

@onready var camera_3d: Camera3D = $Camera3D

var frame_count : int = 0

func _ready() -> void:
	camera_3d.current = true

func _process(delta: float) -> void:
	frame_count += 1

	if frame_count >= 2:
		queue_free()
