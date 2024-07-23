@tool
class_name Ingredient
extends RigidBody3D

enum Type {
	NONE,
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
	PHILOSOPHERS_STONE,
}

static var NEXT_STATE : Dictionary = {
	# For Flare:
	Type.YELLOW_LIQUID : Type.PHOSPHORUS,
	Type.BANANA : Type.POTASSIUM,
	Type.POTASSIUM : Type.POTASSIUM_DUST,
	Type.POTASSIUM_DUST : Type.FLARE,
	Type.PHOSPHORUS : Type.FLARE,

	# For Philosophers Stone:
	Type.MERCURY : Type.PURIFIED_MERCURY,
	Type.PURIFIED_MERCURY : Type.CINNABAR,
	Type.SULFUR : Type.PURIFIED_SULFUR,
	Type.PURIFIED_SULFUR : Type.CINNABAR,
			
	Type.CINNABAR : Type.CINNABAR_DUST,
	Type.CINNABAR_DUST : Type.PHILOSOPHERS_STONE,
	Type.GOLD : Type.PHILOSOPHERS_STONE,
	Type.SILVER : Type.PHILOSOPHERS_STONE,

	#Unused:
	Type.LEAD : Type.GOLD,
	Type.SALT : Type.SALT,
	Type.IRON : Type.IRON,
	Type.DRAGONS_BLOOD : Type.DRAGONS_BLOOD,
	Type.FLARE : Type.FLARE,
	Type.ACID : Type.ACID,
	Type.VINEGAR : Type.VINEGAR,
}

# TODO: Maybe move to a global
const BOWL = preload("res://assets/models/ingredients/bowl.obj")
const ORE = preload("res://assets/models/ingredients/ore.obj")

enum Location {
	HAND,
	ENVIRONMENT
}

@export var type : Type :
	set(value):
		type = value
		self.name = str(Type.keys()[type])
		#TODO: change mesh

@onready var mesh: MeshInstance3D = $Mesh

var current_location : Location = Location.ENVIRONMENT :
	set(value):
		current_location = value
		if current_location == Location.HAND:
			self.freeze = true
			mesh.layers = 0x0002
		elif current_location == Location.ENVIRONMENT:
			self.freeze = false
			mesh.layers = 0x0001
		else:
			printerr("Ingredient visual layer problem")


func _ready() -> void:
	current_location = Location.ENVIRONMENT
