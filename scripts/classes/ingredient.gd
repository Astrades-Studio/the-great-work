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

enum State {
	INITIAL,
	PROCESSED
}

@export var type : Type

@onready var initial_mesh: MeshInstance3D = $InitialState
@onready var processed_mesh: MeshInstance3D = $Processed

var current_state : State:
	set(value):
		current_state = value
		if current_state == State.INITIAL:
			initial_mesh.show()
			processed_mesh.hide()
		elif current_state == State.PROCESSED:
			processed_mesh.show()
			initial_mesh.hide()
		
	
