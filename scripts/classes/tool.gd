class_name Tool
extends Node3D

enum Type {
	STILL,
	MORTAR,
	FURNACE,
	CAULDRON,
}
const RECIPE_COMPLETE = preload("res://assets/sounds/sfx/Recipe complete.wav")
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

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
@onready var target_spot : Node3D = $Target 


signal ingredient_ready

var processing : bool
var input_type : Ingredient.Type 
var time_passed : int
var last_ingredient : Ingredient # For salt names
#var processing_ingredient: Ingredient # Before it is ready
var stored_ingredient: Ingredient # For pickup


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
	play_animation()

	if wait_label:
		wait_label.hide()
		wait_label.text = str(wait_time)
	timer.timeout.connect(_on_timer_timeout)

	assert(self.has_user_signal("interacted"), "Tool has no interacted signal")
	self.connect("interacted", on_tool_use)
	assert(self.tool_type != null, "Tool has no type")

func on_tool_use() -> bool:
	# if GameManager.flare_recipe_read == false:
	# 	DialogManager.create_dialog_piece("I should look for Adam first.")
	# 	return false
	if processing:
		DialogManager.create_dialog_piece("It's processing. I need to wait.")
		return false
	

	var hand_ingredient = GameManager.player.ingredient_in_hand
	if !hand_ingredient:	
		if tool_type == Type.CAULDRON:
			if is_instance_valid(stored_ingredient):
				if stored_ingredient.type == Ingredient.Type.NONE:
					DialogManager.create_dialog_piece("There's nothing in the Cauldron.")	
					stored_ingredient = null
				if (stored_ingredient.type == Ingredient.Type.ALBEDO):
					DialogManager.create_dialog_piece("The mix looks very white. Albedo is the second step towards getting the stone.")
					return false
				if (stored_ingredient.type == Ingredient.Type.NIGREDO):
					DialogManager.create_dialog_piece("The mix looks very dark. This is the first step towards attaining the stone.")
					return false	
				DialogManager.create_dialog_piece("The result was some %s." % stored_ingredient.type_name)
				
				if (stored_ingredient.type == Ingredient.Type.FLARE):
					DialogManager.create_dialog_piece("I made enough luminant for three flares. This should be enough to banish those shadows.")
					GameManager.flare_created.emit()
					var flare_1 : Node = stored_ingredient.duplicate()
					var flare_2 : Node = stored_ingredient.duplicate()
					#var flare_3 : Node = stored_ingredient.duplicate()
					spawn_at_target(flare_1)
					spawn_at_target(flare_2)
					move_ingredient_to_player(stored_ingredient)
					return false
				move_ingredient_to_player(stored_ingredient)
				return false
		else:
			if tool_type == Type.FURNACE:
				animation_player.play("open_door")
				await animation_player.animation_finished
				await get_tree().create_timer(0.1).timeout
				animation_player.play_backwards("open_door")
				
			if stored_ingredient:
				DialogManager.create_dialog_piece("The result of this formula was %s." % [stored_ingredient.type_name])
				move_ingredient_to_player(stored_ingredient)
				return true
		if tool_type == Type.CAULDRON:
			if item_1:
				DialogManager.create_dialog_piece("I can combine elements if I put them in here. It currently has %s in it.", % item_1.type_name)
			else:
				DialogManager.create_dialog_piece("I can combine elements if I put them in here. I should try putting something in it.")
		elif tool_type == Type.FURNACE:
			DialogManager.create_dialog_piece("The furnace burns elements to a crisp, leaving only the most resistant essence.")
		elif tool_type == Type.MORTAR:
			DialogManager.create_dialog_piece("I can use this mortar to pulverize elements that are too tough to dissolve.")
		elif tool_type == Type.STILL:
			DialogManager.create_dialog_piece("The still extracts impurities from a substance.")
		return false

	# Items that don't mix
	if hand_ingredient is Flare:
		DialogManager.create_dialog_piece("I think this is useful enough as it is")
		return false
	if hand_ingredient.type == Ingredient.Type.CAPUT_MORTUUM:
		DialogManager.create_dialog_piece("Caput Mortuum is an inert substance. I need to find something else.")
		return false
	if hand_ingredient.type == Ingredient.Type.ASH:
		DialogManager.create_dialog_piece("This ash is burned beyond salvage. I need something else.")
		return false
	if hand_ingredient.type == Ingredient.Type.PHILOSOPHERS_STONE:
		DialogManager.create_dialog_piece("That would be a grave mistake.")
		return false
	# Couple of hints:
	if tool_type == Type.CAULDRON and (hand_ingredient.type == Ingredient.Type.CINNABAR or hand_ingredient.type == Ingredient.Type.POTASSIUM):
		DialogManager.create_dialog_piece("This substance is too tough to dissolve like this.")
		return false

	if stored_ingredient:
		if stored_ingredient.type != Ingredient.Type.ALBEDO and stored_ingredient.type != Ingredient.Type.NIGREDO:
			DialogManager.create_dialog_piece("My hands are full.")
			return false


	var new_ingredient_type: Ingredient.Type
	input_type = hand_ingredient.type
	
	# Update name label
	if item_1:
		self.name = "%s with %s" % [og_name, item_1.type_name]
	else:
		self.name = "%s with %s" % [og_name, hand_ingredient.type_name]

	GameManager.current_state = GameManager.GameState.CUTSCENE
	if tool_type != Type.MORTAR:
		await play_use_animation()
	await get_tree().create_timer(0.5).timeout
	GameManager.current_state = GameManager.GameState.PLAYING

	if tool_type == Type.MORTAR:
		new_ingredient_type = use_mortar(hand_ingredient)
	elif tool_type == Type.FURNACE:
		new_ingredient_type = use_furnace(hand_ingredient)
	elif tool_type == Type.CAULDRON:
		new_ingredient_type = use_cauldron(hand_ingredient)
	elif tool_type == Type.STILL:
		new_ingredient_type = use_still(hand_ingredient)
	
	if new_ingredient_type != Ingredient.Type.NONE:
		stored_ingredient = instance_ingredient(new_ingredient_type)
	
		start_tool_timer()
	
	
	GameManager.player.ingredient_in_hand = null
	hand_ingredient.queue_free()
	return true


func use_mortar(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type
	DialogManager.create_subtitles_piece("I will grind this %s." % ingredient.type_name)
	GameManager.current_state = GameManager.GameState.CUTSCENE
	play_use_animation()
	for correct_type in CORRECT_TOOL_DICTIONARY[Type.MORTAR]:
		if ingredient.type == correct_type:
			result = ingredient.NEXT_STATE[ingredient.type]
			return result
	
	return ingredient.Type.CAPUT_MORTUUM


func use_furnace(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type
	DialogManager.create_dialog_piece("I put the %s in the %s" % [ingredient.type_name, Type.keys()[tool_type].capitalize()])
	for correct_type in CORRECT_TOOL_DICTIONARY[Type.FURNACE]:
		if ingredient.type == correct_type:
			result = ingredient.NEXT_STATE[ingredient.type]
			return result
	
	return ingredient.Type.ASH


func use_still(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type
	DialogManager.create_dialog_piece("I put the %s in the %s" % [ingredient.type_name, Type.keys()[tool_type].capitalize()])
	for correct_type in CORRECT_TOOL_DICTIONARY[Type.STILL]:
		if ingredient.type == correct_type:
			result = ingredient.NEXT_STATE[ingredient.type]
			return result
	
	return ingredient.Type.CAPUT_MORTUUM

var item_1 : Ingredient
var item_2 : Ingredient
func use_cauldron(ingredient: Ingredient) -> Ingredient.Type:
	var result: Ingredient.Type

	# If this is the first ingredient, return nothing
	if !item_1:
		item_1 = ingredient.duplicate(DUPLICATE_USE_INSTANTIATION)
		DialogManager.create_dialog_piece("I put the %s in the %s" % [ingredient.type_name, Type.keys()[tool_type].capitalize()])
		GameManager.player.ingredient_in_hand = null
		return Ingredient.Type.NONE
	else:
		item_2 = ingredient.duplicate(DUPLICATE_USE_INSTANTIATION)
		DialogManager.create_dialog_piece("I added %s to the %s" % [item_2.type_name, item_1.type_name])

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
		DialogManager.create_dialog_piece("Combining the %s with the %s does not seem particularly useful." % [item_1.type_name, item_2.type_name])
	else:
		push_error("Something went wrong with the cauldron code")
	if progress > 0:
		DialogManager.create_dialog_piece("Damn... that was not it.")
		progress = 0
	return Ingredient.Type.CAPUT_MORTUUM

# Check progress of the philospher's stone
var progress := 0
func advance_progress_philosopher_stone() -> Ingredient.Type:
	progress += 1
	GameManager.philosopher_stone_progress.emit(progress)
	if progress == 1:
		DialogManager.create_dialog_piece("The cinnabar has turned black. I'm doing something right.")
		item_1 = instance_ingredient(Ingredient.Type.NIGREDO)
		#stored_ingredient = instance_ingredient(Ingredient.Type.NIGREDO)
		return Ingredient.Type.NONE
	if progress == 2:
		DialogManager.create_dialog_piece("Now the substance is white... I'm getting closer.")
		item_1 = instance_ingredient(Ingredient.Type.ALBEDO)
		return Ingredient.Type.NONE
	if progress == 3:
		progress = 0
		DialogManager.create_dialog_piece("Glorious red. This must be it!")
		return Ingredient.Type.PHILOSOPHERS_STONE
	else:
		push_error("Something went wrong with the philospher's stone code")
		progress = 0
		return Ingredient.Type.CAPUT_MORTUUM


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
	self.name = og_name
	if ingredient is not Flare:
		GameManager.ingredient_spawned(ingredient)
	GameManager.player.ingredient_in_hand = ingredient


func spawn_at_target(ingredient : Ingredient) -> void:
	add_child(ingredient, true)
	ingredient.global_position = target_spot.global_position
	GameManager.ingredient_spawned(ingredient)


func start_tool_timer() -> void:
	processing = true
	wait_label.show()
	wait_label.text = str(wait_time)
	time_passed = 0
	timer.start(1)


func _on_timer_timeout() -> void:
	time_passed += 1
	wait_label.text = str(wait_time - time_passed)
	
	if time_passed < wait_time:
		timer.start(1)
	else:
		if GameManager.current_state == GameManager.GameState.CUTSCENE:
			GameManager.current_state = GameManager.GameState.PLAYING
		if audio_stream_player_3d:
			audio_stream_player_3d.play(0.0)
		processing = false
		ingredient_ready.emit()
		wait_label.hide()
		timer.stop()
		await get_tree().create_timer(0.5).timeout
		DialogManager.create_subtitles_piece("I think the %s is ready" % Type.keys()[tool_type].capitalize())


func play_animation():
	if tool_type == Tool.Type.CAULDRON:
		animation_player.play("brewing")
	elif tool_type == Tool.Type.STILL:
		animation_player.play("boiling")
	elif tool_type == Tool.Type.MORTAR:
		return
	elif tool_type == Tool.Type.FURNACE:
		return


func play_use_animation():
	var ingredient = GameManager.player.ingredient_in_hand
	#ingredient.current_location = Ingredient.Location.ENVIRONMENT
	if tool_type == Tool.Type.FURNACE:
		animation_player.play("open_door")
		await animation_player.animation_finished
		await tween_to_target(ingredient, ingredient_preview)
		await get_tree().create_timer(0.2).timeout
		animation_player.play_backwards("open_door")
		await animation_player.animation_finished
	else:
		await tween_to_target(ingredient, ingredient_preview)
	if tool_type == Tool.Type.MORTAR:
		animation_player.play("grind")
		await animation_player.animation_finished
	if tool_type == Tool.Type.CAULDRON:
		animation_player.play("mix")
		await animation_player.animation_finished


func tween_to_target(ingredient : Ingredient, _target_spot : Node3D):
	ingredient.change_layers(Ingredient.Location.ENVIRONMENT)
	ingredient.freeze = true
	var tween = get_tree().create_tween()
	tween.tween_property(ingredient, "global_position", _target_spot.global_position, 0.5)
	await tween.finished
