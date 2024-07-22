extends Node

var ingredient_1 : Ingredient
var ingredient_2 : Ingredient

var parent : Node

func _ready() -> void:
	parent = get_parent()
	if parent.has_user_signal("interacted"):
		parent.connect("interacted", Callable(self, "use_mortar"))


func use_mortar():
	var ingredient = GameManager.player.ingredient_in_hand
	if !ingredient:
		DialogManager.create_dialog_piece("I require an ingredient")
	elif ingredient:
		if ingredient_1:
			DialogManager.create_dialog_piece("There's already an ingredient there")
		elif ingredient.current_state == Ingredient.State.PROCESSED:
			DialogManager.create_dialog_piece("This is already processed")
		elif !ingredient_1:
			DialogManager.create_dialog_piece("Let's grind this up")
			ingredient.current_state = Ingredient.State.PROCESSED
		
			
