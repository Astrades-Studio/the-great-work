extends CanvasLayer

@onready var cinematic_label: Label = %CinematicLabel
@onready var background: ColorRect = $Background

signal subtitle_finished
signal cinematic_finished
signal next_line_requested

@export var text_duration := 4.5
@export var sound_duration := 90.10  # Duración del sonido en segundos

func _ready() -> void:
	# Inicializa y comienza el temporizador
	get_tree().create_timer(sound_duration).timeout.connect(_on_timer_timeout)
	
	# Reproduce el sonido
	SfxManager.play_sound(preload("res://assets/sounds/sfx/Intro_carriage.mp3"))
	
	# Comienza el diálogo
	var dialog_1 = load("res://assets/dialog/carriage intro/cutscene_dialog.tres")
	await get_tree().create_timer(10).timeout
	play_cinematic(dialog_1, text_duration)
	var dialog_2 = load("res://assets/dialog/carriage intro/cutscene_dialog_2.tres")
	await get_tree().create_timer(11).timeout
	play_cinematic(dialog_2, text_duration)
	var dialog_3 = load("res://assets/dialog/carriage intro/cutscene_dialog_3.tres")
	await get_tree().create_timer(11).timeout
	play_cinematic(dialog_3, text_duration)
	var dialog_4 = load("res://assets/dialog/carriage intro/cutscene_dialog_4.tres")
	await get_tree().create_timer(8).timeout
	play_cinematic(dialog_4, text_duration)
	var dialog_5 = load("res://assets/dialog/carriage intro/cutscene_dialog_5.tres")
	await get_tree().create_timer(25).timeout
	play_cinematic(dialog_5, text_duration)
	var dialog_6 = load("res://assets/dialog/carriage intro/cutscene_dialog_6.tres")
	await get_tree().create_timer(8).timeout
	play_cinematic(dialog_6, text_duration)


func _input(event: InputEvent) -> void: #TODO: Remove before launch
	if event.is_action_pressed("interact"):
		skip_line()

	if event.is_action_pressed("ui_cancel") or \
	event.is_action_pressed("pause"): #TODO: Remove before launch
		skip_cinematic()

func play_cinematic(dialog : Dialog, duration : float = 2.0) -> void:
	cinematic_label.show()
	background.show()

	for dialog_piece in dialog.dialog: 
		_show_subtitle(dialog_piece, cinematic_label)
		await get_tree().create_timer(duration).timeout
		_hide_subtitle(cinematic_label)
		await next_line_requested
		
	cinematic_finished.emit()

func _on_timer_timeout() -> void:
	TransitionManager.change_scene_to_file(GameManager.MAIN_SCENE)

func skip_line() -> void:
	next_line_requested.emit()

func skip_cinematic() -> void:
	TransitionManager.change_scene_to_file(GameManager.MAIN_SCENE)

var tween : Tween
func _show_subtitle(text : DialogPiece, label : Label) -> void:
	fade_in(label, false)
	label.text = text.dialog_text

func _hide_subtitle(label : Label) -> void:
	fade_in(label, true)
	await tween.finished
	label.text = ""
	next_line_requested.emit()

func fade_in(label : Label, reversed : bool) -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	if !reversed:
		tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 3.5)
	else:
		tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 3.5)
