class_name IngredientComponent
extends Node

var parent : Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()
	
	assert(parent is Ingredient or Flare, "Parent is not an ingredient")
		
	if parent.has_user_signal("interacted"):
		parent.connect("interacted", Callable(self, "pick_up_ingredient"))


func pick_up_ingredient() -> void:
	GameManager.player.ingredient_in_hand = parent
