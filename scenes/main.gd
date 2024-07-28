class_name GameMain
extends Node3D

@onready var world_environment: WorldEnvironment = %WorldEnvironment
@onready var ingredients: Node3D = %Ingredients

@onready var game_over_timer: Timer = %GameOverTimer

@export var max_time := 10
@export var tick_length := 60.

static var countdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	countdown = max_time
	GameManager.environment = world_environment
	GameManager.ingredient_layer = ingredients
	GameManager.tick_countdown.emit()
	
	game_over_timer.timeout.connect(_on_timer_tick)
	
	DialogManager.play_subtitles(load("res://assets/dialog/intro_fireplace.tres"), 2.0)
	start_midnight_game()


func start_midnight_game():
	GameManager.game_started.emit()
	game_over_timer.start(tick_length)
	#DialogManager.play_dialog(DialogManager.INTRO)


func _on_timer_tick():
	countdown -= 1
	GameManager.tick_countdown.emit()
	
	if countdown <= 0:
		GameManager.game_over.emit()
		game_over_timer.stop()
	
