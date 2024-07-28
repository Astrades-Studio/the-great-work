class_name Ingredient
extends RigidBody3D


enum Type {
	NONE,
	CAPUT_MORTUUM,
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
Type.CAPUT_MORTUUM : Type.CAPUT_MORTUUM,
Type.IRON : Type.IRON,
Type.DRAGONS_BLOOD : Type.DRAGONS_BLOOD,
Type.FLARE : Type.FLARE,
Type.ACID : Type.ACID,
Type.VINEGAR : Type.VINEGAR 
}


static var MESH_TABLE : Dictionary = {
	Type.NONE: null,
	Type.CAPUT_MORTUUM: CAPUT_MORTUUM,
	Type.IRON: INGOT,
	Type.LEAD: INGOT,
	Type.MERCURY: MERCURY,
	Type.PURIFIED_MERCURY: PURIFIED_MERCURY,
	Type.SULFUR: SULFUR,
	Type.PURIFIED_SULFUR: PURIFIED_SULFUR,
	Type.ACID: JAR,
	Type.VINEGAR: VINEGAR,
	Type.PHOSPHORUS: PHOSPHORUS,
	Type.YELLOW_LIQUID: YELLOW_LIQUID,
	Type.BANANA: BANANA,
	Type.POTASSIUM: POTASSIUM,
	Type.POTASSIUM_DUST: POTASSIUM_DUST,
	Type.CINNABAR: CINNABAR,
	Type.CINNABAR_DUST: CINNABAR_DUST,
	Type.GOLD: GOLD,
	Type.SILVER: INGOT,
	Type.DRAGONS_BLOOD: CAPUT_MORTUUM,
	Type.FLARE: FLARE,
	Type.PHILOSOPHERS_STONE: PHILOSOPHERS_STONE,
}

# TODO: Maybe move to a global
const BANANA := "res://scenes/alchemy/ingredients/banana.tscn"
const CINNABAR := "res://scenes/alchemy/ingredients/cinnabar.tscn"
const CINNABAR_DUST := "res://scenes/alchemy/ingredients/cinnabar_dust.tscn"
const FLARE := "res://scenes/alchemy/flare.tscn"
const GOLD := "res://scenes/alchemy/ingredients/gold.tscn"
const MERCURY := "res://scenes/alchemy/ingredients/mercury.tscn"
const PHOSPHORUS := "res://scenes/alchemy/ingredients/phosphorus.tscn"
const POTASSIUM := "res://scenes/alchemy/ingredients/potassium.tscn"
const POTASSIUM_DUST := "res://scenes/alchemy/ingredients/potassium_dust.tscn"
const PURIFIED_MERCURY := "res://scenes/alchemy/ingredients/purified_mercury.tscn"
const PURIFIED_SULFUR := "res://scenes/alchemy/ingredients/purified_sulfur.tscn"
const CAPUT_MORTUUM := "res://scenes/alchemy/ingredients/salt.tscn"
const SULFUR := "res://scenes/alchemy/ingredients/sulfur.tscn"
const THE_STONE := "res://scenes/alchemy/ingredients/the_stone.tscn"
const VINEGAR := "res://scenes/alchemy/ingredients/vinegar.tscn"
const YELLOW_LIQUID := "res://scenes/alchemy/ingredients/yellow_liquid.tscn"
const PHILOSOPHERS_STONE := "res://scenes/alchemy/ingredients/the_stone.tscn"
const INGOT := "res://scenes/alchemy/ingredients/ingot.tscn"
const JAR := "res://scenes/alchemy/ingredients/jar_mesh.tscn"

var type_name : String


@export var type : Type :
	set(value):
		type = value
		type_name = str(Type.keys()[type]).capitalize()
		self.name = type_name

signal location_changed

var current_location : Location = Location.ENVIRONMENT :
	set(value):
		if current_location != value:
			location_changed.emit()
		current_location = value
		change_layers()


func _ready() -> void:
	if type == Type.NONE:
		self.queue_free()
		return


func change_layers():
	for _mesh in self.get_children():
		if _mesh is MeshInstance3D:
			if current_location == Location.HAND:
				self.freeze = true
				_mesh.layers = 0x0002
			elif current_location == Location.ENVIRONMENT:
				self.freeze = false
				_mesh.layers = 0x0001
			else:
				printerr("Ingredient visual layer problem")
