class_name InteractiveHighlight
extends Sprite3D

const IDLE = preload("res://assets/ui/crosshairs/crosshair180.png")
const HALF = preload("res://assets/ui/crosshairs/crosshair178.png")
const READY = preload("res://assets/ui/icons/check.tres")

enum States {
	IDLE,
	HALF,
	READY
}

@export var current_state : States = States.IDLE:
	set(value):
		current_state = value
		match current_state:
			States.IDLE:
				texture = IDLE
				visibility_range_end = 1
			States.HALF:
				texture = HALF
				visibility_range_end = 3
			States.READY:
				texture = READY
				visibility_range_end = 6


func _on_ingredient_ready() -> void:
	current_state = States.READY

func has_item_inside() -> void:
	current_state = States.HALF

func reset() -> void:
	current_state = States.IDLE
