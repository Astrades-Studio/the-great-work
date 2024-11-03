extends Node

const MAIN_SCENE := "res://scenes/main.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over_scene.tscn"
const INTRO_CUTSCENE = "res://scenes/layers/intro_cutscene.tscn"
const SHADOW_SCENE := "res://scenes/shadow/shadow.tscn"
const MAIN_MENU = "res://scenes/ui/main_menu.tscn"

const SORROW_SONG = preload("res://assets/sounds/music/sorrow_song.tres")
const INTERACTIVE_HIGHLIGHT = preload("res://assets/ui/crosshairs/crosshair180.png")

const MAX_SPAWNED_INGREDIENT_AMOUNT := 20
const INITIAL_FOG_DENSITY := 0.04
const GAME_START_FOG_DENSITY := 0.1
const FOG_DENSITY_MAX := 0.65
const MAX_SHADOW_SPAWNS := 7

var fog_density_increment : float

enum GameState {
	MAIN_MENU,
	PAUSED,
	PLAYING,
	CUTSCENE,
	DIALOG,
	STATIC  # Nuevo estado
}

# This variable governs the inputs and pauses. Whenever there is a change,
# it should be modified from anywhere needed. Just check for double calls
var current_state : GameState:
	set(value):
		current_state = value
		state_label_updated.emit(current_state)

		if current_state == GameState.PLAYING:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		elif current_state == GameState.PAUSED:
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		elif current_state == GameState.DIALOG:
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		elif current_state == GameState.MAIN_MENU:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		elif current_state == GameState.STATIC:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

		elif current_state == GameState.CUTSCENE:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			printerr("Invalid game state")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Progression
var philosopher_stone_recipe_read : bool = false
var alchemy_recipe_read : bool = false
var flare_recipe_read : bool = false
var flare_already_made : bool = false
var lamp_in_hand : bool = false
var first_shadow_encountered : bool = false
var shadow_dispelled : bool = false
var first_shadow_spawned : bool = false
var good_ending : bool = false
var bad_ending : bool = false

# References
var player : UCharacterBody3D
var fog_environment : WorldEnvironment
var text_layer : TextLayer
var ingredient_layer : Node
var ovani_player : OvaniPlayer

# Trackers
var spawned_ingredients : Array[Ingredient]
var shadow_spawn_points : Array[Darkness]
var shadows_spawned : Array[Shadow]
var dispensers : Array[Dispenser]

# Settings
var fov_value : float = 75:
	set(value):
		fov_value = clamp(remap(value, 0, 1, 60, 90), 60, 90)
		if is_instance_valid(player):
			player.camera.fov = fov_value


var brightness : float = 1.0:
	set(value):
		if !is_node_ready():
			await ready
		if retro_filter:
			brightness = clamp(remap(value, 0, 1, 2.0, 3.8), 2.0, 3.8)
		else:
			brightness = clamp(remap(value, 0, 1, 1.0, 2.0), 1.0, 2.0)
		if is_instance_valid(fog_environment):
			fog_environment.environment.adjustment_brightness = brightness


var mouse_sensitivity : float = 0.1:
	set(value):
		mouse_sensitivity = clamp(remap(value, 0, 1, 0.01, 0.2), 0.01, 0.2)
		if is_instance_valid(player):
			player.mouse_sensitivity = mouse_sensitivity


var retro_filter : bool = false:
	set(value):
		retro_filter = value
		retro_filter_signal.emit(retro_filter)
		if !retro_filter:
			brightness = clamp(remap(brightness, 2.0, 3.8, 1., 2.), 1.0, 2.0)
		else:
			brightness = clamp(remap(brightness, 1.0, 2.0, 2., 3.8), 2.0, 3.8)

# UI Signals
signal retro_filter_signal(value : bool)
signal interaction_label_updated(string : String)
signal crosshair_signal(crosshair : InteractionComponent.InteractionType)
signal state_label_updated(state : GameState)
signal request_book_UI(book : BookPages)
signal request_debug_panel
signal shadow_distance_changed(distance : float)

# Game State Signals
signal game_over
signal game_started
signal cutscene_started
signal cutscene_finished

# Game Progression Signals
signal lamp_collected
signal recipe_read
signal alchemy_read_signal

signal flare_read_signal
signal flare_created
signal philosopher_stone_progress(int)
#signal philosopher_stone_made(made:bool)
signal tick_countdown
signal stone_consumed
signal shadow_crawl_trigger
signal shadow_removed
signal turned_on_flare


func _ready() -> void:
	reset_progress()
	ovani_player = OvaniPlayer.new()
	ovani_player.process_mode = Node.PROCESS_MODE_ALWAYS
	ovani_player.FadeVolume(-80, 10)
	add_child(ovani_player)
	current_state = GameState.MAIN_MENU
	fog_density_increment = (FOG_DENSITY_MAX - INITIAL_FOG_DENSITY) / MAX_SHADOW_SPAWNS
	game_over.connect(_on_game_over)
	philosopher_stone_progress.connect(_on_philosopher_stone_progress)
	tick_countdown.connect(_on_tick_countdown)
	stone_consumed.connect(_on_stone_consumed)
	recipe_read.connect(_on_read_stone_trigger_book)
	alchemy_read_signal.connect(_on_read_alchemy_trigger_book)
	flare_read_signal.connect(_on_read_flare_trigger_book)
	flare_created.connect(_on_flare_created)
	shadow_distance_changed.connect(_on_shadow_distance_changed)
	#assign_random_ingredient_to_each_dispenser()




func _input(event):
	if event.is_action_pressed("interact") and current_state == GameState.PLAYING:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	#if ALT key code is pressed, alternate between capturing and freezing the mouse
	if event is InputEventKey and event.keycode == KEY_BACKSPACE and event.is_pressed():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Gets connected from main menu
func _on_new_game_requested():
	current_state = GameState.PLAYING
	TransitionManager.change_scene_to_file(INTRO_CUTSCENE)


func _on_game_over():
	bad_ending = true
	clear_arrays()
	TransitionManager.change_scene_to_file(GAME_OVER_SCENE)
	current_state = GameState.MAIN_MENU


func request_page_UI(page: Texture):
	text_layer.show_page(page)

func request_text_UI(text : DialogPiece):
	text_layer.show_text(text)

# Ingredient logic
# Assign a random ingredient to each dispenser
#func assign_random_ingredient_to_each_dispenser():
	#var essential_ingredients := [Ingredient.Type.GOLD, Ingredient.Type.SILVER, Ingredient.Type.MERCURY, Ingredient.Type.SALT, Ingredient.Type.SULFUR]
	#for dispenser : Dispenser in get_tree().get_nodes_in_group("dispenser"):
		#if dispenser.ingredient_type != Ingredient.Type.BANANA or dispenser.ingredient_type != Ingredient.Type.YELLOW_LIQUID:
			#dispenser.ingredient_type = essential_ingredients[randi() % essential_ingredients.size()]
			#print("Dispenser %s has ingredient: %s" % [dispenser.name, dispenser.ingredient_type])


func ingredient_spawned(ingredient: Ingredient):
	spawned_ingredients.append(ingredient)
	if spawned_ingredients.size() > MAX_SPAWNED_INGREDIENT_AMOUNT:
		var ingredient_to_delete = spawned_ingredients.pop_front()
		if is_instance_valid(ingredient_to_delete):
			ingredient_to_delete.queue_free()


# Shadow logic
# Check when there is a tick countdown timer and select a shadow_spawn_point to spawn a shadow in one of those at random
# The more shadows there are, the faster the timer counts down
# Play a sound and increase global darkness for each shadow spawned

func _on_tick_countdown():
	pass
	# if shadows_spawned.size() >= shadow_spawn_points.size():
	# 	print("Too many shadows spawned")
	# 	return

	# if shadow_spawn_points.size() > 0:
	# 	spawn_random_shadow()

	# update_darkness_effect(shadows_spawned.size())


func spawn_random_shadow():
	var available_spawns = shadow_spawn_points.filter(is_spot_available)
	if available_spawns.size() > 0:
		var spawn : Darkness = available_spawns[randi() % available_spawns.size()] # Select random spawn point
		if spawn.shadow_present:
			spawn_random_shadow()
		else:
			print("Shadow spawned")
			spawn.spawn_shadow()
			shadows_spawned.append(spawn.shadow)


func update_darkness_effect(amount: int):
	return
	if fog_environment:
		fog_environment.environment.fog_density = amount * fog_density_increment
		if flare_already_made:
			fog_environment.environment.fog_height_density = 0.2
		else:
			fog_environment.environment.fog_height_density = 0.8


func on_shadow_removed(shadow: Shadow):
	shadows_spawned.erase(shadow)
	shadow_removed.emit()
	update_darkness_effect(shadows_spawned.size())


func is_spot_available(darkness : Darkness):
	return not darkness.shadow_present and darkness.cooldown <= 0


func _on_read_stone_trigger_book():
	philosopher_stone_recipe_read = true
	# Play cutscene
	fog_environment.environment.fog_density = GAME_START_FOG_DENSITY
	game_started.emit()
	print("The game begins")


func _on_read_alchemy_trigger_book():
	alchemy_recipe_read = true


func _on_read_flare_trigger_book():
	flare_recipe_read = true


func _on_flare_created():
	flare_read_signal.emit()
	flare_already_made = true
	update_darkness_effect(1)


# Endgame progress:
func _on_philosopher_stone_progress(amount: int):
	# Check progress from 1 to 4:
	ovani_player.FadeIntensity(amount/3.0, 5.0)
	if amount == 0:
		ovani_player.FadeVolume(-80, 5)
		pass
	if amount == 1:
		ovani_player.FadeVolume(-15, 5)
		ovani_player.PlaySongNow(SORROW_SONG)
		shadow_removed.emit()
		pass
	elif amount == 2:
		shadow_removed.emit()
		pass
	elif amount == 3:
		shadow_removed.emit()
		_on_philosopher_stone_created()


func _on_philosopher_stone_created():
	# Play cutscene
	DialogManager.create_subtitles_piece("Now there is only one thing left to do...")


func reset_progress():
	if flare_already_made:
		flare_recipe_read = true
		flare_already_made = true
	else:
		flare_already_made = false
		flare_recipe_read = false
	philosopher_stone_recipe_read = false
	lamp_in_hand = false
	first_shadow_encountered = false
	first_shadow_spawned = false
	good_ending = false
	bad_ending = false
	alchemy_recipe_read = false

func clear_arrays():
	spawned_ingredients.clear()
	shadow_spawn_points.clear()
	shadows_spawned.clear()


func _on_stone_consumed():
	clear_arrays()
	ovani_player.FadeVolume(-80, 3)
	good_ending = true
	TransitionManager.change_scene_to_file(GAME_OVER_SCENE)


func _on_shadow_distance_changed(distance: float):
	if distance == 3.0:
		DialogManager.create_subtitles_piece("The darkness is closing in on me. I need to hurry.")
	elif distance == 2.0:
		DialogManager.create_subtitles_piece("It's almost upon me, I need a flare.")


const EYE_SCENE = preload("res://scenes/shadow/eyes.tscn")
var shadow_chance : Array[bool]= []

func _on_ingredient_delivered():
	if shadow_chance.is_empty():
		shadow_chance = [false, false, true]
		shadow_chance.shuffle()

	var result : bool = shadow_chance.pop_front()
	print("Shadow chance: " + str(result))
	if !result:
		return

	# get the camera direction
	var camera_direction = player.camera.global_basis.z

	var player_position = player.global_position
	var target_position = player_position + camera_direction * 2

	var eye = EYE_SCENE.instantiate()
	GameMain.shadow_layer.add_child(eye)
	eye.global_position = target_position
	eye.global_position.y = player.camera.global_position.y
	pass
