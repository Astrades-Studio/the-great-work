@tool
class_name Ingredient
extends Node3D

enum Type {
	GOLD,
	SILVER,
	IRON,
	LEAD,
	MERCURY,
	SULFUR,
	SALT,
	ACID,
	VINEGAR,
	PHOSPHORUS
}

const BOWL = preload("res://assets/models/ingredients/bowl.obj")
const ORE = preload("res://assets/models/ingredients/ore.obj")

enum State {
	INITIAL,
	PROCESSED
}

enum Location {
	HAND,
	ENVIRONMENT
}

@export var type : Type :
	set(value): 
		type = value
		self.name = str(type)

@onready var initial_mesh: MeshInstance3D = $InitialState
@onready var processed_mesh: MeshInstance3D = $Processed


var current_location : Location:
	set(value):
		current_location = value
		if current_location == Location.HAND:
			initial_mesh.layers = 0x0002
			processed_mesh.layers = 0x0002
		if current_location == Location.ENVIRONMENT:
			initial_mesh.layers = 0x0001
			processed_mesh.layers = 0x0001


var current_state : State:
	set(value):
		current_state = value
		if current_state == State.INITIAL:
			initial_mesh.show()
			processed_mesh.hide()
		elif current_state == State.PROCESSED:
			processed_mesh.show()
			initial_mesh.hide()
		
func _ready() -> void:
	current_location = current_location
	current_state = current_state
