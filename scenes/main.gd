class_name GameMain
extends Node3D

@onready var world_environment: WorldEnvironment = %WorldEnvironment
@onready var ingredients: Node3D = %Ingredients
@onready var game_over_timer: Timer = %GameOverTimer
@onready var ovani_player: OvaniPlayer = $OvaniPlayer

@export var max_time := 10
@export var tick_length := 60.

const DEATH_SOUND = preload("res://assets/sounds/sfx/death_sound.mp3")

static var countdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	countdown = max_time
	GameManager.fog_environment = world_environment
	GameManager.ingredient_layer = ingredients
	GameManager.game_started.connect(start_midnight_game)
	GameManager.shadow_removed.connect(_timer_up)
	game_over_timer.timeout.connect(_on_timer_tick)
	await get_tree().create_timer(1).timeout
	
	DialogManager.play_subtitles(load("res://assets/dialog/intro_fireplace.tres"), 2.0)


func start_midnight_game():
	game_over_timer.start(tick_length)
	print("Shadows start now")

func _timer_up():
	countdown += 1
	print(countdown)

func _on_timer_tick():
	countdown -= 1
	GameManager.tick_countdown.emit()
	
	if countdown == 1:
		trigger_death_timer()
	
	if countdown <= 0:
		MusicManager
		GameManager.game_over.emit()
		game_over_timer.stop()


func trigger_death_timer():
	if tick_length < 0:
		return
	MusicManager.music_stream_1.stop()
	get_tree().create_timer(tick_length - 4.89).timeout.connect(
		func(): MusicManager.play_music(DEATH_SOUND)
	)



func _on_basement_trigger_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
