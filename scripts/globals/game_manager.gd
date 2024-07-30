extends Node

const MAIN_SCENE := "res://scenes/main.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over_scene.tscn"
const INTRO_CUTSCENE = "res://scenes/layers/intro_cutscene.tscn"
const SHADOW_SCENE := "res://scenes/shadow/shadow.tscn"

const MAX_SPAWNED_INGREDIENT_AMOUNT := 15
const INITIAL_FOG_DENSITY := 0.04
const GAME_START_FOG_DENSITY := 0.1
const FOG_DENSITY_MAX := 0.65

var fog_density_increment : float

enum GameState {
	MAIN_MENU,
	PAUSED,
	PLAYING,
	CUTSCENE,
	DIALOG,
}

# This variable goberns the inputs and pauses. Whenever there is a change, 
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
		
		elif current_state == GameState.CUTSCENE:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		#TODO: decide where to put cutscene CANNOT MOVE behavior
		else:
			printerr("Invalid game state")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Progression
var philosopher_stone_recipe_read : bool = false
var lamp_in_hand : bool = false

# References
var player : UCharacterBody3D
var fog_environment : WorldEnvironment
var text_layer : TextLayer
var ingredient_layer : Node


# Trackers
var spawned_ingredients : Array[Ingredient]
var shadow_spawn_points : Array[Darkness]
var shadows_spawned : Array[Shadow]

# UI Signals
signal interaction_label_updated(string : String)
signal state_label_updated(state : GameState)
signal request_book_UI(book : BookPages)
signal request_debug_panel

# Game State Signals
signal game_over
signal game_started

# Game Progression Signals
signal recipe_read
signal philosopher_stone_progress(int)
#signal philosopher_stone_made(made:bool)
signal tick_countdown
signal stone_consumed


func _ready() -> void:
	current_state = GameState.MAIN_MENU
	fog_density_increment = (FOG_DENSITY_MAX - INITIAL_FOG_DENSITY) / shadow_spawn_points.size()
	game_over.connect(_on_game_over)
	philosopher_stone_progress.connect(_on_philosopher_stone_progress)
	tick_countdown.connect(_on_tick_countdown)
	stone_consumed.connect(_on_stone_consumed)
	recipe_read.connect(_on_philosopher_stone_recipe_read)
	


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
	reset_progress()
	TransitionManager.change_scene_to_file(GAME_OVER_SCENE)
	current_state = GameState.MAIN_MENU
	

func request_page_UI(page: Texture):
	text_layer.show_text(page)


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
	if shadows_spawned.size() >= shadow_spawn_points.size():
		print("Too many shadows spawned")
		return
	
	if shadow_spawn_points.size() > 0:
		spawn_random_shadow()
	
	update_darkness_effect(shadows_spawned.size())
		

func spawn_random_shadow():
	var available_spawns = shadow_spawn_points.filter(is_spot_available)
	if available_spawns.size() > 0:
		var spawn = available_spawns[randi() % available_spawns.size()] # Select random spawn point
		if !spawn.spawn_shadow():
			spawn_random_shadow()
		else:
			print("Shadow spawned")
			shadows_spawned.append(spawn.shadow)
			SfxManager.play_shadow_sound()


func update_darkness_effect(amount: int):
	fog_environment.environment.fog_density = amount * fog_density_increment
	#var fog_increment : float = worlds_environment.environment.fog_density + (countdown / max_time)
	#world_environment.environment.fog_density = clamp(fog_increment, 1, 10)


func on_shadow_removed(shadow: Shadow):
	shadows_spawned.erase(shadow)
	update_darkness_effect(shadows_spawned.size())


func is_spot_available(darkness : Darkness):
	return not darkness.shadow_present and darkness.cooldown <= 0


func _on_philosopher_stone_recipe_read():
	philosopher_stone_recipe_read = true
	# Play cutscene
	# Start game timer
	fog_environment.environment.fog_density = GAME_START_FOG_DENSITY
	game_started.emit()
	print("The game begins")


# Endgame progress:
func _on_philosopher_stone_progress(amount: int):
	# Check progress from 1 to 4:
	if amount == 1:
		pass
	elif amount == 2:
		pass
	elif amount == 3:
		pass
	elif amount == 4:
		_on_philosopher_stone_created()


func _on_philosopher_stone_created():
	# Play cutscene
	#TransitionManager.change_scene_to_file(THANKS_CUTSCENE)
	#print("You win the game")
	#reset_progress()
	pass


func reset_progress():
	spawned_ingredients.clear()
	shadow_spawn_points.clear()
	shadows_spawned.clear()
	philosopher_stone_progress.emit(0)
	philosopher_stone_recipe_read = false
	fog_environment.environment.fog_density = INITIAL_FOG_DENSITY


func _on_stone_consumed():
	# TODO play ending
	pass
