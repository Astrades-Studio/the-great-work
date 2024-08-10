class_name GameMain
extends Node3D

@onready var world_environment: WorldEnvironment = %WorldEnvironment
@onready var ingredients: Node3D = %Ingredients
@onready var game_over_timer: Timer = %GameOverTimer
@onready var ovani_player: OvaniPlayer = $OvaniPlayer
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $Level/Ambient/AudioStreamPlayer3D

@export var max_time := 10
@export var tick_length := 60.

@onready var palette_layer: CanvasLayer = $PaletteLayer
@onready var dithering_layer: CanvasLayer = $DitheringLayer
@onready var color_reduction_layer: CanvasLayer = $ColorReductionLayer
@onready var pixelize_layer: CanvasLayer = $PixelizeLayer



const DEATH_SOUND = preload("res://assets/sounds/sfx/death_sound.mp3")

static var countdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SimpleGrass.set_interactive(true)
	countdown = max_time
	GameManager.fog_environment = world_environment
	world_environment.environment.adjustment_brightness = GameManager.brightness
	GameManager.update_darkness_effect(1)
	GameManager.ingredient_layer = ingredients
	GameManager.ovani_player = ovani_player
	GameManager.game_started.connect(start_midnight_game)
	GameManager.shadow_removed.connect(_timer_up)
	GameManager.retro_filter_signal.connect(retro_filter_toggle)
	game_over_timer.timeout.connect(_on_timer_tick)
	await get_tree().create_timer(1).timeout
	audio_stream_player_3d.play()
	DialogManager.play_subtitles(load("res://assets/dialog/intro_adam.tres"), 2.0)

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


func retro_filter_toggle(value : bool) -> void:
	if value:
		palette_layer.show()
		dithering_layer.show()
		color_reduction_layer.show()
		pixelize_layer.show()
	else:
		palette_layer.hide()
		dithering_layer.hide()
		color_reduction_layer.hide()
		pixelize_layer.hide()
	
