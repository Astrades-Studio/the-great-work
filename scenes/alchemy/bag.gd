extends MeshInstance3D

var ingredient_type : Ingredient.Type	

# Called when the node enters the scene tree for the first time.
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
	if _ingredient_type == Ingredient.Type.FLARE:
		print("Flare added")
		#resulting_ingredient = FLARE_SCENE.instantiate()
	else:
		pass
		#resulting_ingredient = INGREDIENT_SCENE.instantiate()
	add_child(resulting_ingredient, true)
	resulting_ingredient.type = _ingredient_type
	print(str(resulting_ingredient.type_name) + " added")

	GameManager.player.ingredient_in_hand = resulting_ingredient


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
