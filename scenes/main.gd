class_name GameMain
extends Node3D

@onready var world_environment: WorldEnvironment = %WorldEnvironment

@onready var game_over_timer: Timer = %GameOverTimer

@export var max_time := 60
@export var tick_length := 1.

static var countdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	countdown = max_time
	GameManager.environment = world_environment
	# GameManager.game_over.connect(_on_game_over)
	game_over_timer.timeout.connect(_on_timer_tick)
	start_midnight_game()


func start_midnight_game():
	game_over_timer.start(tick_length)
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
	
	
	
	
