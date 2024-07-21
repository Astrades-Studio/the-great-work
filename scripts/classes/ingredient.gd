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
		self.name = str(Type.keys()[type])

@onready var initial_mesh: MeshInstance3D = $InitialState
@onready var processed_mesh: MeshInstance3D = $Processed

#@export var INITIAL_MESH : Mesh:
	#set(value):
		#if !initial_mesh:
			#return
		#INITIAL_MESH = value
		#initial_mesh.mesh = INITIAL_MESH

var current_location : Location = Location.ENVIRONMENT :
	set(value):
		current_location = value
		if current_location == Location.HAND:
			initial_mesh.layers = 0x0002
			processed_mesh.layers = 0x0002
		elif current_location == Location.ENVIRONMENT:
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
# 	print(str(self) + " " + str(Location.keys()[current_location]))
# 	#current_location = Location.ENVIRONMENT
