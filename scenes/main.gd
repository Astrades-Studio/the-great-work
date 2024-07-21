extends Node3D

@onready var world_environment: WorldEnvironment = $WorldEnvironment


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.environment = world_environment
