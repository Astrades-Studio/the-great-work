extends Node

const MAIN_SCENE := "res://scenes/main.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over_scene.tscn"
const INTRO_CUTSCENE = "res://scenes/layers/intro_cutscene.tscn"
const SHADOW_SCENE := "res://scenes/shadow/shadow.tscn"

const MAX_SPAWNED_INGREDIENT_AMOUNT := 10

enum GameState {
	MAIN_MENU,
	PAUSED,
	PLAYING,
	CUTSCENE,
	DIALOG,
}

var spawned_ingredients : Array[Ingredient]

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
			get_tree().paused = false
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


# References
var player : UCharacterBody3D
var environment : WorldEnvironment
var text_layer : TextLayer
var ingredient_layer : Node
var transition_screen : Node

# UI Signals
signal interaction_label_updated(string : String)
signal state_label_updated(state : GameManager.GameState)
signal request_book_UI(book : BookPages)

# Game State Signals
signal game_over
signal game_started

# Game Progression Signals
signal philosopher_stone_progress(int)
signal philosopher_stone_made(made:bool)
signal tick_countdown


func _ready() -> void:
	current_state = GameState.MAIN_MENU
	game_over.connect(_on_game_over)

func _input(event):
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
	#get_tree().change_scene_to_packed(INTRO_CUTSCENE)


func _on_game_over():
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

# Check when there is a tick countdown timer and select a shadow_spawn_point to spawn a shadow in one of those at random
# The more shadows there are, the faster the timer counts down
# Play a sound and increase global darkness for each shadow spawned
var spawned_shadows : Array
func _on_tick_countdown():
	if spawned_shadows.size() > 0:
		var shadow_spawn_points = get_tree().get_nodes_in_group("shadow_spawn_point")
		var shadow_spawn_point = shadow_spawn_points[randi() % shadow_spawn_points.size()]
		
		var shadow_instance = load(SHADOW_SCENE).instantiate()
		shadow_instance.global_transform = shadow_spawn_point.global_transform
		add_child(shadow_instance)
		
		match spawned_shadows.size():
			1:
				SfxManager.play_sound(SfxManager.SHADOW_1_SOUND)
				update_darkness_effect(1)
			2:
				SfxManager.play_sound(SfxManager.SHADOW_2_SOUND)
				update_darkness_effect(2)
			3:
				SfxManager.play_sound(SfxManager.SHADOW_3_SOUND)
				update_darkness_effect(3)
			4:
				SfxManager.play_sound(SfxManager.SHADOW_4_SOUND)
				update_darkness_effect(4)
			5:
				SfxManager.play_sound(SfxManager.SHADOW_5_SOUND)
				update_darkness_effect(5)
			6:
				SfxManager.play_sound(SfxManager.SHADOW_6_SOUND)
				update_darkness_effect(6)
			_:
				SfxManager.play_sound(SfxManager.SHADOW_7_SOUND)
				update_darkness_effect(7)


func update_darkness_effect(amount: int):
	
	#var fog_increment : float = worlds_environment.environment.fog_density + (countdown / max_time)
	#world_environment.environment.fog_density = clamp(fog_increment, 1, 10)
	# TODO lerp?
	environment.environment.fog_density = amount
