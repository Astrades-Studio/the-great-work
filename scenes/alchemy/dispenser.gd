class_name Dispenser
extends StaticBody3D

@export var ingredient_type : Ingredient.Type

func _ready() -> void:
	assert(self.has_user_signal("interacted"), "Dispenser has no interacted signal")
	self.connect("interacted", request_ingredient.bind(ingredient_type))
	GameManager.dispensers.append(self)


func request_ingredient(_ingredient_type : Ingredient.Type) -> void:
	if !_ingredient_type:
		DialogManager.create_subtitles_piece("It seems to be empty")
		return

	if _ingredient_type == Ingredient.Type.NONE:
		GameManager.player.ingredient_in_hand = null
		return

	# if ingredient type is the same as ingredient in hand, create a dialog saying I already have the ingredient:
	if GameManager.player.ingredient_in_hand:
		if GameManager.player.ingredient_in_hand.type == _ingredient_type:
			DialogManager.create_subtitles_piece("I am already carrying %s" % GameManager.player.ingredient_in_hand.type_name)
			return
		else:
			DialogManager.create_subtitles_piece("I am already carrying something")

	var resulting_ingredient: Ingredient
	resulting_ingredient = load(Ingredient.MESH_TABLE[_ingredient_type]).instantiate()
	add_child(resulting_ingredient, true)
	resulting_ingredient.type = _ingredient_type
	print(str(resulting_ingredient.type_name) + " added")


	DialogManager.create_subtitles_piece("I've picked up some %s" % resulting_ingredient.type_name)
	GameManager.ingredient_spawned(resulting_ingredient)

	GameManager.player.ingredient_in_hand = resulting_ingredient
