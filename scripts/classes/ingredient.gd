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

enum MeshType {
	ORE,
	BANANA,
	BOWL,
	VIAL,
	JAR,
	CRYSTAL,
}

enum Location {
	HAND,
	ENVIRONMENT
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


var MESH_TABLE : Dictionary = {
	Type.NONE: BOWL,
	Type.SALT: BOWL,
	Type.IRON: ORE,
	Type.LEAD: ORE,
	Type.MERCURY: BANANA,
	Type.PURIFIED_MERCURY: BANANA,
	Type.SULFUR: BANANA,
	Type.PURIFIED_SULFUR: BANANA,
	Type.ACID: BOWL,
	Type.VINEGAR: BOWL,
	Type.PHOSPHORUS: BANANA,
	Type.YELLOW_LIQUID: BOWL,
	Type.BANANA: BANANA,
	Type.POTASSIUM: BOWL,
	Type.POTASSIUM_DUST: BOWL,
	Type.CINNABAR: ORE,
	Type.CINNABAR_DUST: ORE,
	Type.GOLD: BOWL,
	Type.SILVER: BOWL,
	Type.DRAGONS_BLOOD: BOWL,
	Type.FLARE: BOWL,
	Type.PHILOSOPHERS_STONE: BOWL,
}


# TODO: Maybe move to a global
const BOWL = preload("res://assets/models/ingredients/bowl.obj")
const ORE = preload("res://assets/models/ingredients/ore.obj")
const BANANA = preload("res://assets/models/ingredients/banana.res")


@onready var mesh: MeshInstance3D = %Mesh

var type_name : String
var mesh_type : Mesh

var type : Type 

@export var actual_type : Type :
	set(value):
		printraw()
		type = value
		type_name = str(Type.keys()[type]).capitalize()
		self.name = type_name
		assert(mesh, "Mesh not found")
		mesh_type = MESH_TABLE[type]
		mesh.mesh = mesh_type

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
	actual_type = type
