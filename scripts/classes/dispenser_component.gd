class_name DispenserComponent
extends Node

@export var ingredient_type : Ingredient.Type

const INGREDIENT_SCENE = preload("res://scenes/alchemy/ingredient.tscn")
const FLARE_SCENE = preload("res://scenes/alchemy/flare.tscn")

var parent : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !ingredient_type:
		push_error("No ingredient type assigned to " + str(self.get_path()))
	
	parent = get_parent()

	if parent.has_user_signal("interacted"):
		parent.connect("interacted", Callable(self, "request_ingredient").bind(ingredient_type))
		print(parent.get_signal_connection_list("interacted"))

	else:
		push_error("Parent does not have Interact Component")


func request_ingredient(_ingredient_type : Ingredient.Type) -> void:
	if !_ingredient_type:
		printerr("No ingredient type assigned")
		return
  
	if _ingredient_type == Ingredient.Type.NONE:
		GameManager.player.ingredient_in_hand = null
		return

	var resulting_ingredient: Ingredient
	if _ingredient_type == Ingredient.Type.FLARE:
		resulting_ingredient = FLARE_SCENE.instantiate()
	else:
		resulting_ingredient = INGREDIENT_SCENE.instantiate()
	add_child(resulting_ingredient, true)
	resulting_ingredient.type = _ingredient_type
	print(str(resulting_ingredient.type_name) + " added")

	GameManager.player.ingredient_in_hand = resulting_ingredient
