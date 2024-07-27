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

# enum MeshType {
# 	ORE,
# 	BANANA,
# 	BOWL,
# 	VIAL,
# 	JAR,
# 	CRYSTAL,
# }

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
Type.VINEGAR : Type.VINEGAR 
}


var MESH_TABLE : Dictionary = {
	Type.NONE: null,
	Type.SALT: SALT,
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
	Type.DRAGONS_BLOOD: SALT,
	Type.FLARE: FLARE,
	Type.PHILOSOPHERS_STONE: PHILOSOPHERS_STONE,
}
#
#var COLOR_TABLE : Dictionary = {
	#Type.NONE: Color.WHITE,
	#Type.SALT: Color.WHITE,
	#Type.IRON: Color.GRAY,
	#Type.LEAD: Color.DARK_GRAY,
	#Type.MERCURY: Color.SILVER,
	#Type.PURIFIED_MERCURY: Color.LIGHT_SLATE_GRAY,
	#Type.SULFUR: Color.OLIVE,
	#Type.PURIFIED_SULFUR: Color.GOLDENROD,
	#Type.ACID: Color.GREEN_YELLOW,
	#Type.VINEGAR: Color.TRANSPARENT,
	#Type.PHOSPHORUS: Color.DARK_RED,
	#Type.YELLOW_LIQUID: Color.YELLOW,
	#Type.BANANA: Color.YELLOW,
	#Type.POTASSIUM: Color.DIM_GRAY,
	#Type.POTASSIUM_DUST: Color.DIM_GRAY,
	#Type.CINNABAR: Color.LIGHT_CORAL,
	#Type.CINNABAR_DUST: Color.LIGHT_CORAL,
	#Type.GOLD: Color.GOLD,
	#Type.SILVER: Color.SILVER,
	#Type.DRAGONS_BLOOD: Color.DARK_RED,
	#Type.FLARE: Color.WHITE,
	#Type.PHILOSOPHERS_STONE: Color.DARK_RED,
#}


# TODO: Maybe move to a global
const BANANA := "res://scenes/alchemy/ingredients/banana.tscn"
const CINNABAR := "res://scenes/alchemy/ingredients/cinnabar.tscn"
const CINNABAR_DUST := "res://scenes/alchemy/ingredients/cinnabar_dust.tscn"
const FLARE := "res://scenes/alchemy/ingredients/flare.tscn"
const GOLD := "res://scenes/alchemy/ingredients/gold.tscn"
const MERCURY := "res://scenes/alchemy/ingredients/mercury.tscn"
const PHOSPHORUS := "res://scenes/alchemy/ingredients/phosphorus.tscn"
const POTASSIUM := "res://scenes/alchemy/ingredients/potassium.tscn"
const POTASSIUM_DUST := "res://scenes/alchemy/ingredients/potassium_dust.tscn"
const PURIFIED_MERCURY := "res://scenes/alchemy/ingredients/purified_mercury.tscn"
const PURIFIED_SULFUR := "res://scenes/alchemy/ingredients/purified_sulfur.tscn"
const SALT := "res://scenes/alchemy/ingredients/salt.tscn"
const SULFUR := "res://scenes/alchemy/ingredients/sulfur.tscn"
const THE_STONE := "res://scenes/alchemy/ingredients/the_stone.tscn"
const VINEGAR := "res://scenes/alchemy/ingredients/vinegar.tscn"
const YELLOW_LIQUID := "res://scenes/alchemy/ingredients/yellow_liquid.tscn"
const PHILOSOPHERS_STONE := "res://scenes/alchemy/ingredients/the_stone.tscn"
const INGOT := "res://scenes/alchemy/ingredients/ingot.tscn"
const JAR := "res://scenes/alchemy/ingredients/jar_mesh.tscn"
# #
# const BOWL = "res://assets/models/ingredients/bowl.obj"
# const ORE = "res://assets/models/ingredients/rocks/Rock_05.res"
# const BANANA = "res://assets/models/ingredients/banana.res"
# const JAR = "res://assets/models/ingredients/jar_mesh.res"

@onready var mesh: MeshInstance3D = %Mesh
@onready var collision_shape: CollisionShape3D = %CollisionShape3D

var type_name : String
var mesh_type : Mesh


@export var type : Type :
	set(value):
		if !Engine.is_editor_hint():
			if !ready:
				await ready
		type = value
		type_name = str(Type.keys()[type]).capitalize()
		self.name = type_name
		# if !mesh:
		# 	await tree_entered
		# 	mesh = get_node("%Mesh")
		# mesh_type = MESH_TABLE[type]
		# mesh.mesh = mesh_type
		#if !collision_shape:
			#await tree_entered
			#collision_shape = get_node("%CollisionShape3D")
		#collision_shape.make_convex_from_siblings()
		#collision_shape.global_transform = mesh.global_transform
			
		
signal location_changed

var current_location : Location = Location.ENVIRONMENT :
	set(value):
		if current_location != value:
			location_changed.emit()
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
	
	#var target_color = COLOR_TABLE[type]	
	#var active_material = mesh.get_active_material(0)
	#active_material.albedo_color = target_color


var _mesh : Mesh

func get_mesh(type : Type) -> Mesh:
	if _mesh:
		_mesh.queue_free()
	_mesh = load(MESH_TABLE[type]).instantiate()
	_mesh.name = "Mesh"
	_mesh.unique_name_in_owner = true
	#add_child(_mesh)
	return _mesh
