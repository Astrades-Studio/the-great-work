@tool
class_name Tool
extends Node3D

enum Type {
	STILL,
	MORTAR,
	FURNACE,
	MIXER,
}

const INGREDIENT_SCENE = preload("res://scenes/alchemy/ingredient.tscn")

@export var type: Type:
	set(value):
		type = value
		self.name = str(Type.keys()[type].capitalize())

var stored_ingredient: Ingredient

var CORRECT_TOOL_DICTIONARY: Dictionary = {
	Type.STILL: [
		Ingredient.Type.YELLOW_LIQUID,
		Ingredient.Type.MERCURY,
		Ingredient.Type.SULFUR,
	],
	Type.MORTAR: [
		Ingredient.Type.POTASSIUM,
		Ingredient.Type.CINNABAR,
	],
	Type.FURNACE: [
		Ingredient.Type.BANANA,
		Ingredient.Type.DRAGONS_BLOOD,
	],
	Type.MIXER: {
		Ingredient.Type.POTASSIUM_DUST: Ingredient.Type.PHOSPHORUS,
		Ingredient.Type.PHOSPHORUS: Ingredient.Type.POTASSIUM_DUST,
		Ingredient.Type.PURIFIED_SULFUR: Ingredient.Type.PURIFIED_MERCURY,
		Ingredient.Type.PURIFIED_MERCURY: Ingredient.Type.PURIFIED_SULFUR,
		Ingredient.Type.CINNABAR_DUST: Ingredient.Type.GOLD,
		Ingredient.Type.GOLD: Ingredient.Type.CINNABAR_DUST,
		Ingredient.Type.SILVER: Ingredient.Type.CINNABAR_DUST,
		Ingredient.Type.LEAD: Ingredient.Type.GOLD,
	}
}

func _ready():
	assert(self.has_user_signal("interacted"), "Tool has no interacted signal")
	#await GameManager.ready
	self.connect("interacted", on_tool_use)
	assert(self.type != null, "Tool has no type")
	

func on_tool_use() -> void:
	var ingredient = GameManager.player.ingredient_in_hand
	if !ingredient:
		DialogManager.create_dialog_piece("I need an ingredient to use this")
		return
	
	var new_ingredient_type: Ingredient.Type

	print(str(self.name) + " used")
	
	if type == Type.MORTAR:
		new_ingredient_type = use_mortar(ingredient)
	elif type == Type.FURNACE:
		new_ingredient_type = use_furnace(ingredient)
	elif type == Type.MIXER:
		new_ingredient_type = use_mixer(ingredient)
	elif type == Type.STILL:
		new_ingredient_type = use_still(ingredient)
	
	if new_ingredient_type == Ingredient.Type.NONE:
		# TODO: check
		print("Ingredient left at still")
		return

	var resulting_ingredient: Ingredient = INGREDIENT_SCENE.instantiate()
	resulting_ingredient.type = new_ingredient_type
	add_child(resulting_ingredient, true)
	print(str(resulting_ingredient.type_name) + " added")

	if resulting_ingredient.type == Ingredient.Type.SALT:
		resulting_ingredient.type_name = (Ingredient.Type.keys()[ingredient.type] + " salt").capitalize()

	# HACK ?
	GameManager.player.ingredient_in_hand = resulting_ingredient
	ingredient.queue_free()


func use_mortar(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type

	print("Mortar used")

	for correct_type in CORRECT_TOOL_DICTIONARY[Type.MORTAR]:
		if ingredient.type == correct_type:
			result = ingredient.NEXT_STATE[ingredient.type]
			return result
	
	return ingredient.Type.SALT


func use_furnace(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type

	for correct_type in CORRECT_TOOL_DICTIONARY[Type.FURNACE]:
		if ingredient.type == correct_type:
			result = ingredient.NEXT_STATE[ingredient.type]
			return result
	
	return ingredient.Type.SALT


func use_still(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type

	for correct_type in CORRECT_TOOL_DICTIONARY[Type.STILL]:
		if ingredient.type == correct_type:
			result = ingredient.NEXT_STATE[ingredient.type]
			return result
	
	return ingredient.Type.SALT


func use_mixer(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type

	if !stored_ingredient:
		stored_ingredient = ingredient
		return Ingredient.Type.NONE

	for correct_type in CORRECT_TOOL_DICTIONARY[Type.MIXER]:
		if ingredient.type == correct_type:
			if stored_ingredient.type == CORRECT_TOOL_DICTIONARY[Type.MIXER][correct_type]:
				result = ingredient.NEXT_STATE[ingredient.type]
				stored_ingredient = null
				return result	

	stored_ingredient = null
	return ingredient.Type.SALT
