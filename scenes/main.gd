class_name GameMain
extends Node3D

@onready var world_environment: WorldEnvironment = %WorldEnvironment
@onready var ingredients: Node3D = $Ingredients

@onready var game_over_timer: Timer = %GameOverTimer

@export var max_time := 60
@export var tick_length := 1.

static var countdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	countdown = max_time
	GameManager.environment = world_environment
	GameManager.ingredient_layer = ingredients
	# GameManager.game_over.connect(_on_game_over)
	game_over_timer.timeout.connect(_on_timer_tick)
	start_midnight_game()

# HACK: move to a singleton or smth
func _input(event: InputEvent) -> void:
	# change to fullscreen
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func start_midnight_game():
	game_over_timer.start(tick_length)
	await get_tree().create_timer(1).timeout
	DialogManager.play_dialog(DialogManager.INTRO)


func _on_timer_tick():
	countdown -= 1
	GameManager.tick_countdown.emit()
	
	if countdown <= 0:
		GameManager.game_over.emit()
		game_over_timer.stop()
	
	var fog_increment := world_environment.environment.fog_density + 0.1
	world_environment.environment.fog_density = clamp(fog_increment, 1, 4)
	
	
# func _on_game_over():
# 	#TODO: transicion
# 	get_tree().change_scene_to_file("res://scenes/ui/game_over_scene.tscn")
	
	
	
	
