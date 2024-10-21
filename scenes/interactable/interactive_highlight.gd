class_name InteractiveHighlight
extends Sprite3D

const IDLE = preload("res://assets/ui/crosshairs/crosshair180.png")
const READY = preload("res://assets/ui/icons/check.tres")

enum States {
	IDLE,
	READY
}

@export var current_state : States = States.IDLE:
	set(value):
		current_state = value
		match current_state:
			States.IDLE:
				texture = IDLE
				visibility_range_end = 3
			States.READY:
				texture = READY
				visibility_range_end = 10


func _on_ingredient_ready() -> void:
	current_state = States.READY

func reset() -> void:
	current_state = States.IDLE
