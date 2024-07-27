class_name Dispenser
extends StaticBody3D

@export var ingredient_type : Ingredient.Type

const INGREDIENT_SCENE = preload("res://scenes/alchemy/ingredient.tscn")
const FLARE_SCENE = preload("res://scenes/alchemy/flare.tscn")


static var spawned_ingredients : Array[Ingredient]


func _ready() -> void:
	if !ingredient_type:
		push_error("No ingredient type assigned to " + str(self.get_path()))
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
	if _ingredient_type == Ingredient.Type.FLARE:
		resulting_ingredient = FLARE_SCENE.instantiate()
	else:
		resulting_ingredient = INGREDIENT_SCENE.instantiate()
	add_child(resulting_ingredient, true)
	resulting_ingredient.type = _ingredient_type
	print(str(resulting_ingredient.type_name) + " added")

	spawned_ingredients.append(resulting_ingredient)
	if spawned_ingredients.size() > GameManager.MAX_SPAWNED_INGREDIENT_AMOUNT:
		var ingredient_to_delete = spawned_ingredients.pop_front()
		if ingredient_to_delete:
			ingredient_to_delete.queue_free()


	GameManager.player.ingredient_in_hand = resulting_ingredient
