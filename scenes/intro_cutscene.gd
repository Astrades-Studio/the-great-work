extends CanvasLayer

@onready var subtitle_label: Label = %SubtitleLabel
@onready var cinematic_label: Label = %CinematicLabel
@onready var background: ColorRect = $Background


signal subtitle_finished
signal cinematic_finished
signal next_line_requested

@export var text_duration := 2.0

func _ready() -> void:
	play_cinematic(preload("res://assets/dialog/intro_dialog.tres"), text_duration)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		skip_line()

	if event.is_action_pressed("ui_cancel") or \
	event.is_action_pressed("pause"):
		skip_cinematic()

func play_subtitles(dialog : Dialog, duration : float) -> void:
	subtitle_label.show()
	for dialog_piece in dialog.dialog:
		_show_subtitle(dialog_piece, subtitle_label)
		await get_tree().create_timer(duration).timeout
		_hide_subtitle(subtitle_label)
		await tween.finished
	
	subtitle_label.hide()
	subtitle_finished.emit()


func play_cinematic(dialog : Dialog, duration : float = 2.0) -> void:
	cinematic_label.show()
	background.show()

	for dialog_piece in dialog.dialog:
		_show_subtitle(dialog_piece, cinematic_label)
		await get_tree().create_timer(duration).timeout
		_hide_subtitle(cinematic_label)
		await next_line_requested
		
	cinematic_finished.emit()
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
		tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)
	else:
		tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.0)
	
