@tool
class_name Ingredient
extends RigidBody3D

enum Type {
	SALT,
	IRON,
	LEAD,
	MERCURY,
	PURIFIED_MERCURY,
	SULFUR,
	PURIFIED_SULFUR,
	ACID,
	VINEGAR,
	PHOSPHORUS,
	YELLOW_LIQUID,
	BANANA,
	POTASSIUM,
	POTASSIUM_DUST,
	CINNABAR,
	CINNABAR_DUST,
	GOLD,
	SILVER,
	DRAGONS_BLOOD,
	FLARE,
}

# TODO: Maybe move to a global
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
		self.name = str(Type.keys()[type])

@onready var initial_mesh: MeshInstance3D = $InitialState
@onready var processed_mesh: MeshInstance3D = $Processed


var current_location : Location = Location.ENVIRONMENT :
	set(value):
		current_location = value
		if current_location == Location.HAND:
			self.freeze = true
			initial_mesh.layers = 0x0002
			processed_mesh.layers = 0x0002
		elif current_location == Location.ENVIRONMENT:
			self.freeze = false
			initial_mesh.layers = 0x0001
			processed_mesh.layers = 0x0001
		else:
			printerr("Ingredient visual layer problem")


var current_state : State = State.INITIAL :
	set(value):
		current_state = value
		if current_state == State.INITIAL:
			initial_mesh.show()
			processed_mesh.hide()
		elif current_state == State.PROCESSED:
			processed_mesh.show()
			initial_mesh.hide()
			
			
func _ready() -> void:
	current_location = Location.ENVIRONMENT
