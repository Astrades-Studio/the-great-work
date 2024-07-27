@tool
class_name Tool
extends Node3D

enum Type {
	STILL,
	MORTAR,
	FURNACE,
	CAULDRON,
}

const INGREDIENT_SCENE = preload("res://scenes/alchemy/ingredient.tscn")
const FLARE_SCENE = preload("res://scenes/alchemy/flare.tscn")

@export var ingredient_preview : Node
@export var wait_time : int
@export var sound : AudioStream

@export var type: Type:
	set(value):
		type = value
		self.name = str(Type.keys()[type].capitalize())

@onready var og_name : String = self.name
@onready var wait_label: Label3D = $WaitLabel
#TODO code wait time

var input_type : Ingredient.Type
var last_ingredient : Ingredient

var stored_ingredient: Ingredient:
	set(value):
		stored_ingredient = value
		if stored_ingredient:
			self.name = "%s with %s" % [og_name, stored_ingredient.type_name]
		else:
			self.name = og_name


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
	Type.CAULDRON: {
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
	if wait_label:
		wait_label.hide()
	assert(self.has_user_signal("interacted"), "Tool has no interacted signal")
	#await GameManager.ready
	self.connect("interacted", on_tool_use)
	assert(self.type != null, "Tool has no type")

	
#TODO: Make the dialogs for each case
func on_tool_use() -> void:
	var ingredient = GameManager.player.ingredient_in_hand

	if !ingredient:
		DialogManager.create_dialog_piece("I need an ingredient to use this")
		return
	if ingredient is Flare:
		DialogManager.create_dialog_piece("I think this is useful enough as it is")
		return
	
	var new_ingredient_type: Ingredient.Type
	input_type = ingredient.type
	
	wait_label.show()
	print(str(self.name) + " used")
	
	if type == Type.MORTAR:
		new_ingredient_type = use_mortar(ingredient)
	elif type == Type.FURNACE:
		new_ingredient_type = use_furnace(ingredient)
	elif type == Type.CAULDRON:
		new_ingredient_type = use_cauldron(ingredient)
	elif type == Type.STILL:
		new_ingredient_type = use_still(ingredient)
	
	if new_ingredient_type == Ingredient.Type.NONE:
		ingredient.queue_free()
		GameManager.player.ingredient_in_hand = null
		return

	give_ingredient_to_player(new_ingredient_type)

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


func use_cauldron(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type
	
	# If this is the first ingredient, return nothing
	if !stored_ingredient:
		stored_ingredient = ingredient.duplicate(DUPLICATE_USE_INSTANTIATION)
		DialogManager.create_dialog_piece("I put the %s in the %s" % [ingredient.type_name, Type.keys()[type].capitalize()])
		return Ingredient.Type.NONE
	
	# Check all recipes
	for correct_type in CORRECT_TOOL_DICTIONARY[Type.CAULDRON]:
		# Check if the recipe exists
		if ingredient.type == correct_type:
			# Check if the stored ingredient combines with the ingredient on hand
			if stored_ingredient.type == CORRECT_TOOL_DICTIONARY[Type.CAULDRON][correct_type]:
				# Return the next state of the ingredient
				DialogManager.create_dialog_piece("I combined the %s with the %s" % [stored_ingredient.type_name, ingredient.type_name])
				result = ingredient.NEXT_STATE[ingredient.type]
				# Unless it's the philosophers stone, in which case we need to check the progress
				if result == Ingredient.Type.PHILOSOPHERS_STONE:
					result = progress_philosopher_stone()
					return result
				stored_ingredient = null
				return result

	DialogManager.create_dialog_piece("I can't combine the %s with the %s" % [stored_ingredient.type_name, ingredient.type_name])
	stored_ingredient = null
	return ingredient.Type.SALT

# Check progress of the philospher's stone
var progress := 0
func progress_philosopher_stone() -> Ingredient.Type:
	if progress < 3:
		progress += 1
		GameManager.philosopher_stone_progress.emit(progress)
		DialogManager.create_dialog_piece("I've made %s of it" % progress)
		return Ingredient.Type.NONE
	else:
		progress = 0
		DialogManager.create_dialog_piece("It's finally done")
		GameManager.philosopher_stone_made.emit()
		return Ingredient.Type.PHILOSOPHERS_STONE


func give_ingredient_to_player(new_ingredient_type: Ingredient.Type) -> void:
	if new_ingredient_type == Ingredient.Type.NONE:
		GameManager.player.ingredient_in_hand = null
		return

	var resulting_ingredient: Ingredient
	if new_ingredient_type == Ingredient.Type.FLARE:
		resulting_ingredient = FLARE_SCENE.instantiate()
	else:
		resulting_ingredient = INGREDIENT_SCENE.instantiate()
	add_child(resulting_ingredient, true)
	resulting_ingredient.type = new_ingredient_type
	print(str(resulting_ingredient.type_name) + " added")

	if resulting_ingredient.type == Ingredient.Type.SALT:
		resulting_ingredient.type_name = (Ingredient.Type.keys()[input_type] + " salt").capitalize()

	# Add ingredient to player and Game Manager
	GameManager.ingredient_spawned(resulting_ingredient)
	GameManager.player.ingredient_in_hand = resulting_ingredient
