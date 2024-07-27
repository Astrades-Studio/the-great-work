extends Node3D

@onready var ingredients: Node3D = $Ingredients

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.current_state = GameManager.GameState.PLAYING
	GameManager.ingredient_layer = ingredients
