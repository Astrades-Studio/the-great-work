@tool
class_name Tool
extends Node3D

enum Type {
	STILL,
	MORTAR,
	FURNACE,
	CAULDRON,
}

@export var ingredient_preview : Node
@export var wait_time : int
@export var sound : AudioStream

@export var tool_type: Type:
	set(value):
		tool_type = value
		self.name = str(Type.keys()[tool_type].capitalize())

@onready var og_name : String = self.name
@onready var wait_label: Label3D = $WaitLabel
@onready var timer: Timer = %Timer

signal ingredient_ready

var processing : bool
var input_type : Ingredient.Type 
var time_passed : int
var last_ingredient : Ingredient # For salt names
#var processing_ingredient: Ingredient # Before it is ready
var stored_ingredient: Ingredient: # For pickup
	set(value):
		stored_ingredient = value
		if stored_ingredient and stored_ingredient.type != Ingredient.Type.NONE and !processing:
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
		Ingredient.Type.SILVER: Ingredient.Type.NIGREDO,
		Ingredient.Type.SALT: Ingredient.Type.ALBEDO,
		Ingredient.Type.LEAD: Ingredient.Type.GOLD,
	}
}

func _ready():
	if wait_label:
		wait_label.hide()
		wait_label.text = str(wait_time)
	timer.timeout.connect(_on_timer_timeout)

	assert(self.has_user_signal("interacted"), "Tool has no interacted signal")
	#await GameManager.ready
	self.connect("interacted", on_tool_use)
	assert(self.tool_type != null, "Tool has no type")

	
#TODO: Make the dialogs for each case
func on_tool_use() -> bool:
	if processing:
		DialogManager.create_dialog_piece("Now I just need to wait a little.")
		return false
	
	var hand_ingredient = GameManager.player.ingredient_in_hand
	if !hand_ingredient:	
		if tool_type == Type.CAULDRON:
			if stored_ingredient:
				if stored_ingredient.type == Ingredient.Type.NONE:
					DialogManager.create_dialog_piece("There's nothing in the Cauldron.")	
					stored_ingredient = null
				DialogManager.create_dialog_piece("The result was some %s." % stored_ingredient.type_name)
				move_ingredient_to_player(stored_ingredient)
				return false
		else:
			if stored_ingredient:
				DialogManager.create_dialog_piece("The result of this formula was %s." % [stored_ingredient.type_name])
				move_ingredient_to_player(stored_ingredient)
				return true
		DialogManager.create_dialog_piece("I need an ingredient to use this")
		return false
	if hand_ingredient is Flare:
		DialogManager.create_dialog_piece("I think this is useful enough as it is")
		return false
	
	if stored_ingredient and tool_type != Type.CAULDRON:
		DialogManager.create_dialog_piece("My hands are full.")
		return false


	var new_ingredient_type: Ingredient.Type
	input_type = hand_ingredient.type
	
	
	if tool_type == Type.MORTAR:
		new_ingredient_type = use_mortar(hand_ingredient)
	elif tool_type == Type.FURNACE:
		new_ingredient_type = use_furnace(hand_ingredient)
	elif tool_type == Type.CAULDRON:
		new_ingredient_type = use_cauldron(hand_ingredient)
	elif tool_type == Type.STILL:
		new_ingredient_type = use_still(hand_ingredient)
	
	stored_ingredient = instance_ingredient(new_ingredient_type)

	start_tool_timer()
	#if new_ingredient_type == Ingredient.Type.ALBEDO or \
		#new_ingredient_type == Ingredient.Type.NIGREDO:	
		#GameManager.player.ingredient_in_hand = null
		#return false
	
	hand_ingredient.queue_free()
	return true


func use_mortar(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type

	print("Mortar used")

	for correct_type in CORRECT_TOOL_DICTIONARY[Type.MORTAR]:
		if ingredient.type == correct_type:
			result = ingredient.NEXT_STATE[ingredient.type]
			return result
	
	return ingredient.Type.CAPUT_MORTUUM


func use_furnace(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type

	for correct_type in CORRECT_TOOL_DICTIONARY[Type.FURNACE]:
		if ingredient.type == correct_type:
			result = ingredient.NEXT_STATE[ingredient.type]
			return result
	
	return ingredient.Type.CAPUT_MORTUUM


func use_still(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type

	for correct_type in CORRECT_TOOL_DICTIONARY[Type.STILL]:
		if ingredient.type == correct_type:
			result = ingredient.NEXT_STATE[ingredient.type]
			return result
	
	return ingredient.Type.CAPUT_MORTUUM

var item_1
var item_2

func use_cauldron(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type
	
	# If this is the first ingredient, return nothing
	if !item_1:
		item_1 = ingredient.duplicate(DUPLICATE_USE_INSTANTIATION)
		DialogManager.create_dialog_piece("I put the %s in the %s" % [ingredient.type_name, Type.keys()[tool_type].capitalize()])
		return Ingredient.Type.NONE
	else:
		item_2 = ingredient.duplicate(DUPLICATE_USE_INSTANTIATION)
		DialogManager.create_dialog_piece("I added %s to the %s" % [item_2.type_name, item_2])
	
	# Check all recipes
	for correct_type in CORRECT_TOOL_DICTIONARY[Type.CAULDRON]:
		# Check if the recipe exists
		if item_2.type == correct_type:
			# Check if the stored ingredient combines with the ingredient on hand
			if item_1.type == CORRECT_TOOL_DICTIONARY[Type.CAULDRON][correct_type]:
				# Return the next state of the ingredient
				result = item_2.NEXT_STATE[item_2.type]
				# Unless it's the philosophers stone, in which case we need to check the progress
				if result == Ingredient.Type.NIGREDO and progress == 0:
					result = advance_progress_philosopher_stone()
					return result
				elif result == Ingredient.Type.ALBEDO and progress == 1:
					result = advance_progress_philosopher_stone()
					return result
				elif result == Ingredient.Type.PHILOSOPHERS_STONE and progress == 2:
					result = advance_progress_philosopher_stone()
					return result
				
				return result
	if item_1.type != Ingredient.Type.NONE and item_2.type != Ingredient.Type.NONE:
		DialogManager.create_dialog_piece("Combining the %s with the %s does not seem particularly useful." % [stored_ingredient.type_name, ingredient.type_name])
	else:
		push_error("Something went wrong with the cauldron code")
	return Ingredient.Type.CAPUT_MORTUUM

# Check progress of the philospher's stone
var progress := 0
func advance_progress_philosopher_stone() -> Ingredient.Type:
	progress += 1
	GameManager.philosopher_stone_progress.emit(progress)
	if progress == 1:
		DialogManager.create_dialog_piece("The cinnabar has turned black. I'm doing something right.")
		return Ingredient.Type.NIGREDO
	if progress == 2:
		DialogManager.create_dialog_piece("Now the substance is white... I'm getting closer.")
		return Ingredient.Type.ALBEDO
	if progress == 3:
		progress = 0
		DialogManager.create_dialog_piece("Glorious red. This must be it!")
		return Ingredient.Type.PHILOSOPHERS_STONE
	else:
		push_error("Something went wrong with the philospher's stone code")
		progress = 0
		return Ingredient.Type.CAPUT_MORTUUM


# func give_new_ingredient_to_player(new_ingredient_type: Ingredient.Type) -> void:
# 	if new_ingredient_type == Ingredient.Type.NONE or \
# 	new_ingredient_type == Ingredient.Type.NIGREDO or \
# 	new_ingredient_type == Ingredient.Type.ALBEDO:
# 		GameManager.player.ingredient_in_hand = null
# 		return

# 	var resulting_ingredient = instance_ingredient(new_ingredient_type)
# 	add_child(resulting_ingredient, true)
# 	move_ingredient_to_player(resulting_ingredient)
	# print(str(resulting_ingredient.type_name) + " added")
	# if resulting_ingredient.type == Ingredient.Type.CAPUT_MORTUUM:
	# 	resulting_ingredient.type_name = (Ingredient.Type.keys()[input_type] + " salt").capitalize()


func instance_ingredient(_type : Ingredient.Type) -> Ingredient:
	if Ingredient.MESH_TABLE[_type]:
		var new_ingredient = load(Ingredient.MESH_TABLE[_type]).instantiate() as Ingredient
		new_ingredient.type = _type
		return new_ingredient
	else:
		var new_ingredient = load(Ingredient.MESH_TABLE[Ingredient.Type.IRON]).instantiate() as Ingredient
		new_ingredient.type = _type
		return new_ingredient
		

func move_ingredient_to_player(ingredient: Ingredient) -> void:
	# TODO play animation?
	add_child(ingredient, true)
	stored_ingredient = null
	item_1 = null
	item_2 = null
	GameManager.ingredient_spawned(ingredient)
	GameManager.player.ingredient_in_hand = ingredient


func start_tool_timer() -> void:
	processing = true
	wait_label.show()
	wait_label.text = str(wait_time)
	time_passed = 0
	timer.start(1)


func _on_timer_timeout() -> void:
	processing = false
	time_passed += 1
	wait_label.text = str(wait_time - time_passed)
	
	if time_passed < wait_time:
		timer.start(1)
	else:
		DialogManager.create_subtitles_piece("I think the %s is ready" % name)
		ingredient_ready.emit()
		wait_label.hide()
		timer.stop()
