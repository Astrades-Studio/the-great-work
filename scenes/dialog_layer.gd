class_name DialogLayer
extends CanvasLayer

@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %TextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide()
	DialogManager.dialog_layer = self
	dialog_finished.connect(DialogManager._on_dialog_finished)
	

var text_on_screen : bool
var text_writing_in_process : bool

var skip_button_held_time = 0.0
var skip_button_held : bool

func _input(event: InputEvent) -> void:
	if !text_on_screen:
		return
	# Code for checking holding cancel and skipping dialog
	if event.is_action_pressed("ui_cancel"):
		skip_button_held_time = Time.get_ticks_msec()
		skip_button_held = true
	if event.is_action_released("ui_cancel"):
		skip_button_held = false

	if event.is_action_pressed("ui_accept") \
	or event.is_action_pressed("interact") :
		next_line_requested.emit()

func _process(delta: float) -> void:
	if skip_button_held:
		skip_button_held_time += delta
	if skip_button_held_time >= 0.5:
		DialogManager.skip_dialog()
		skip_button_held_time = 0.0
		
signal next_line_requested
signal dialog_finished

func play_dialog(dialog : Dialog):
	for dialog_piece in dialog.dialog:
		show_text(dialog_piece)
		await next_line_requested
	
	hide_text()

var tween : Tween

func show_text(dialog_piece: DialogPiece):
	show()
	text_on_screen = true
	name_label.text = dialog_piece.dialog_speaker
	text_label.text = dialog_piece.dialog_text


func hide_text():
	hide()
	text_on_screen = false
	name_label.text = ""
	text_label.text = "???"
	dialog_finished.emit()
