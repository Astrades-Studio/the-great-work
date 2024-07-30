class_name Dispenser
extends StaticBody3D

@export var ingredient_type : Ingredient.Type

func _ready() -> void:
	assert(self.has_user_signal("interacted"), "Dispenser has no interacted signal")
	self.connect("interacted", request_ingredient.bind(ingredient_type))


func request_ingredient(_ingredient_type : Ingredient.Type) -> void:
	if !_ingredient_type:
		printerr("No ingredient type assigned")
		return
  
	if _ingredient_type == Ingredient.Type.NONE:
		GameManager.player.ingredient_in_hand = null
		return

	var resulting_ingredient: Ingredient
	resulting_ingredient = load(Ingredient.MESH_TABLE[_ingredient_type]).instantiate()
	add_child(resulting_ingredient, true)
	resulting_ingredient.type = _ingredient_type
	print(str(resulting_ingredient.type_name) + " added")



	GameManager.ingredient_spawned(resulting_ingredient)

	GameManager.player.ingredient_in_hand = resulting_ingredient
