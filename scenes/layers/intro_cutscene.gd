extends CanvasLayer

@onready var cinematic_label: Label = %CinematicLabel
@onready var background: ColorRect = $Background
@onready var subtitle_label: Label = %SubtitleLabel
@onready var loading: Label = $MarginContainer/Loading
@onready var animation_player: AnimationPlayer = $MarginContainer/AnimationPlayer

signal cinematic_finished
signal next_line_requested

@export var text_duration := 4.3 # tiempo de cada dialogo
@export var sound_duration := 87.10  # Duración del sonido en segundos

func _ready() -> void:
	subtitle_label.hide()
	cinematic_finished.connect(TransitionManager._on_cinematic_finished)
	TransitionManager.preload_scene(GameManager.MAIN_SCENE)
	play_intro_cinematic()
	loading.show()
	animation_player.play("loading")
	TransitionManager.loading_finished.connect(_on_loading_finished)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or \
	event.is_action_pressed("pause"):
		skip_cinematic()
	if event.is_action_pressed("interact"):
		show_skip_button()


func _on_loading_finished() -> void:
	animation_player.stop()
	loading.text = "Done"


func play_cinematic(dialog : Dialog, duration : float = 2.0) -> void:
	cinematic_label.show()
	background.show()

	for dialog_piece in dialog.dialog:
		_show_subtitle(dialog_piece, cinematic_label)
		await get_tree().create_timer(duration).timeout
		_hide_subtitle(cinematic_label)
		await next_line_requested


func _on_timer_timeout() -> void:
	cinematic_finished.emit()


func show_skip_button() -> void:
	subtitle_label.show()

	var tween_subs : = get_tree().create_tween()
	tween_subs.tween_property(subtitle_label, "modulate", Color.WHITE, 1.0)
	await tween_subs.finished
	await get_tree().create_timer(1.0).timeout
	tween_subs.tween_property(subtitle_label, "modulate", Color.TRANSPARENT, 1.0)


func skip_cinematic() -> void:
	SfxManager.stop_all_sounds()
	cinematic_finished.emit()
	#TransitionManager.change_scene_to_file(GameManager.MAIN_SCENE)

var tween : Tween
func _show_subtitle(text : DialogPiece, label : Label) -> void:
	fade_in(label, false)
	label.text = text.dialog_text

func _hide_subtitle(label : Label) -> void:
	fade_in(label, true)
	await tween.finished
	label.text = ""
	next_line_requested.emit()

func fade_in(label : Label, reversed : bool, duration : float = 3.5) -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	if !reversed:
		tween.tween_property(label, "modulate", Color.WHITE, duration)
	else:
		tween.tween_property(label, "modulate", Color.TRANSPARENT, duration)


func play_intro_cinematic() -> void:
	# Inicializa y comienza el temporizador
	get_tree().create_timer(sound_duration).timeout.connect(_on_timer_timeout)
	# Reproduce el sonido
	SfxManager.play_sound(preload("res://assets/sounds/sfx/Intro_carriage2.mp3"))
	SfxManager.sound_bus_1.volume_db = -1.0 #volumen musica
	# Comienza el diálogo
	var dialog_1 = load("res://assets/dialog/carriage intro/cutscene_dialog.tres")
	await get_tree().create_timer(8).timeout
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
