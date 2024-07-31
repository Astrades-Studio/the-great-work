class_name SubtitleLayer
extends CanvasLayer

@onready var subtitle_label: Label = %SubtitleLabel
#@onready var cinematic_label: Label = %CinematicLabel
#@onready var background: ColorRect = $Background


signal subtitle_finished
signal next_line_request
signal line_hidden
signal line_shown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DialogManager.subtitles_layer = self
	next_line_request.connect(_on_next_line_request)
	subtitle_finished.connect(DialogManager._on_subtitle_finished)

func play_subtitles(dialog : Dialog, duration : float = 2.0) -> void:	
	subtitle_label.show()
	for dialog_piece in dialog.dialog:
		await _show_subtitle(dialog_piece, duration)
		await line_hidden
	
	subtitle_label.hide()
	subtitle_label.text = ""
	subtitle_finished.emit()


var tween : Tween
func _show_subtitle(text : DialogPiece, duration : float) -> void:
	subtitle_label.text = text.dialog_text
	await fade_in(false)
	if !duration:
		var length := text.dialog_text.length()
		duration = length * 0.1
	await get_tree().create_timer(duration).timeout
	next_line_request.emit()


func _on_next_line_request() -> void:
	await _hide_subtitle()


func _hide_subtitle() -> void:
	await fade_in(true)
	line_hidden.emit()


func fade_in(reversed : bool) -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	if !reversed:
		tween.tween_property(subtitle_label, "modulate", Color.WHITE, 1.0)
	else:
		tween.tween_property(subtitle_label, "modulate", Color.TRANSPARENT, 1.0)
	await tween.finished
