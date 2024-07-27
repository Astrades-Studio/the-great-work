class_name SubtitleLayer
extends CanvasLayer

@onready var subtitle_label: Label = %SubtitleLabel
@onready var cinematic_label: Label = %CinematicLabel
@onready var background: ColorRect = $Background


signal subtitle_finished
signal cinematic_finished


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DialogManager.subtitle_layer = self
	subtitle_finished.connect(DialogManager._on_subtitle_finished)

func play_subtitles(dialog : Dialog, duration : float) -> void:
	subtitle_label.show()
	for dialog_piece in dialog.dialog:
		_show_subtitle(dialog_piece, subtitle_label)
		await get_tree().create_timer(duration).timeout
		_hide_subtitle(subtitle_label)
		await tween.finished
	
	subtitle_label.hide()
	subtitle_finished.emit()


func play_cinematic(dialog : Dialog, duration : float) -> void:
	cinematic_label.show()
	background.show()

	for dialog_piece in dialog.dialog:
		_show_subtitle(dialog_piece, cinematic_label)
		await get_tree().create_timer(duration).timeout
		_hide_subtitle(cinematic_label)
		await tween.finished

	cinematic_label.show()
	background.hide()
	cinematic_finished.emit()

var tween : Tween
func _show_subtitle(text : DialogPiece, label : Label) -> void:
	fade_in(label, false)
	label.text = text.dialog_text


func _hide_subtitle(label : Label) -> void:
	fade_in(label, true)


func fade_in(label : Label, reversed : bool) -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	if !reversed:
		tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)
	else:
		tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.0)
	
