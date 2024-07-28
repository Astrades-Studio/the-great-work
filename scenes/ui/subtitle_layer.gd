class_name SubtitleLayer
extends CanvasLayer

@onready var subtitle_label: Label = %SubtitleLabel
@onready var cinematic_label: Label = %CinematicLabel
@onready var background: ColorRect = $Background


signal subtitle_finished
signal next_line_request
signal line_hidden

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DialogManager.subtitles_layer = self
	next_line_request.connect(_on_next_line_request)
	subtitle_finished.connect(DialogManager._on_subtitle_finished)

func play_subtitles(dialog : Dialog, duration : float = 2.0) -> void:	
	subtitle_label.show()
	for dialog_piece in dialog.dialog:
		_show_subtitle(dialog_piece, subtitle_label)
		await line_hidden
	
	subtitle_label.hide()
	subtitle_finished.emit()


var tween : Tween
func _show_subtitle(text : DialogPiece, label : Label) -> void:
	await fade_in(label, false)
	var length := text.dialog_text.length()
	var duration := length * 0.1
	label.text = text.dialog_text
	await get_tree().create_timer(duration).timeout
	next_line_request.emit()


func _on_next_line_request() -> void:
	_hide_subtitle(subtitle_label)


func _hide_subtitle(label : Label) -> void:
	await fade_in(label, true)
	line_hidden.emit()


func fade_in(label : Label, reversed : bool) -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	if !reversed:
		tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)
	else:
		tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.0)
	await tween.finished
	
#signal cinematic_finished
# func play_cinematic(dialog : Dialog, duration : float) -> void:
# 	cinematic_label.show()
# 	background.show()

# 	for dialog_piece in dialog.dialog:
# 		await _show_subtitle(dialog_piece, cinematic_label)
		
# 		_hide_subtitle(cinematic_label)

# 	cinematic_label.show()
# 	background.hide()
# 	cinematic_finished.emit()
