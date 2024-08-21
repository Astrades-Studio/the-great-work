class_name SubtitleLayer
extends CanvasLayer

@onready var shadow_label: RichTextLabel = %CinematicLabel

@onready var subtitle_label: Label = %SubtitleLabel
@onready var subtitle_label_2: LabelAutoSizer = %SubtitleLabel2
@onready var subtitle_label_3: LabelAutoSizer = %SubtitleLabel3

@onready var labels := [subtitle_label, subtitle_label_2, subtitle_label_3]
var used_labels : Array
var target_label : Label


signal subtitle_finished
signal next_line_request
signal line_hidden
signal line_shown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DialogManager.subtitles_layer = self
	next_line_request.connect(_on_next_line_request)
	subtitle_finished.connect(DialogManager._on_subtitle_finished)
	_init_labels()


func _init_labels() -> void:
	subtitle_label.modulate = Color.TRANSPARENT
	subtitle_label_2.modulate = Color.TRANSPARENT
	subtitle_label_3.modulate = Color.TRANSPARENT
	shadow_label.hide()
	shadow_label.modulate = Color(1.0,1.0,1.0,0.5)


func play_subtitles(dialog : Dialog, duration : float = 2.0) -> void:
	# Check which label is available:
	for label in labels:
		if label.text == "":
			target_label = label
			break

	target_label.show()

	for dialog_piece in dialog.dialog:
		await _show_subtitle(target_label, dialog_piece, duration)
		await line_hidden

	subtitle_finished.emit()


func play_shadow_subtitles(dialog_piece : DialogPiece, duration : float = 1.0) -> void:
	# Initialize the label
	shadow_label.visible_ratio = 0.0
	shadow_label.modulate = Color(1.0,1.0,1.0,0.5)
	shadow_label.show()
	shadow_label.bbcode_enabled = true
	#bbcode for size 32, centered, red color, black outline 1 pixel:
	shadow_label.bbcode_text = "[shake][center][color=darkred][font_size=32][outline_color=black][outline_size=2] %s [/outline_size][/outline_color][/font_size][/color][/center]" % dialog_piece.dialog_text

	# Calculate duration according to length
	var length := dialog_piece.dialog_text.length()
	duration = length * 0.1
	# Show the text letter by letter
	var _tween := get_tree().create_tween()
	_tween.tween_property(shadow_label, "visible_ratio", 1.0, duration)
	await _tween.finished
	await get_tree().create_timer(duration).timeout
	# Fade out the text
	var _tween_2 := get_tree().create_tween()
	_tween_2.tween_property(shadow_label, "modulate", Color.TRANSPARENT, duration)
	await _tween_2.finished
	shadow_label.hide()


var tween : Tween
func _show_subtitle(label: Label, text : DialogPiece, duration : float) -> void:
	used_labels.append(label)
	label.text = text.dialog_text
	label.modulate = Color.WHITE
	label.visible_ratio = 0.0
	label.show()
	await fade_in(label, false)
	if !duration:
		var length := text.dialog_text.length()
		duration = length * 0.1
	await get_tree().create_timer(duration).timeout
	next_line_request.emit()


func _on_next_line_request() -> void:
	var label_to_hide = used_labels.pop_front()
	if label_to_hide:
		_hide_subtitle(label_to_hide)


func _hide_subtitle(label: Label) -> void:
	await fade_in(label, true)
	label.text = ""
	label.hide()
	line_hidden.emit()


func fade_in(label: Label, reversed : bool) -> void:
	var tween = get_tree().create_tween()
	if !reversed:
		tween.tween_property(label, "visible_ratio", 1.0, label.text.length() * 0.05)
	else:
		tween.tween_property(label, "modulate", Color.TRANSPARENT, 1.0)
	await tween.finished
