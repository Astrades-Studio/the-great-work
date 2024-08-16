class_name DialogLayer
extends CanvasLayer

@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %TextLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal next_line_requested
signal dialog_finished

var text_on_screen : bool
var text_writing_in_process : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide()
	DialogManager.dialog_layer = self
	dialog_finished.connect(DialogManager._on_dialog_finished)
	animation_player.play("next_line_indication")


func _input(event: InputEvent) -> void:
	if !text_on_screen:
		return
	if event.is_action_pressed("ui_accept") \
	or event.is_action_pressed("ui_cancel") \
	or event.is_action_pressed("interact") :
		next_line_requested.emit()


func play_dialog(dialog : Dialog):
	for dialog_piece in dialog.dialog:
		show_text(dialog_piece)
		await next_line_requested

	hide_text.call_deferred()

var tween : Tween

func show_text(dialog_piece: DialogPiece):
	#assert(dialog_piece, "Empty dialog piece at " + str(self.get_path()))
	if !dialog_piece:
		printerr("Empty dialog piece at " + str(self.get_path()))
		dialog_piece = DialogPiece.new()

	show()
	SfxManager.change_bus_volume("SFX", 0.4)
	SfxManager.change_bus_volume("Music", 0.4)
	text_on_screen = true
	name_label.text = dialog_piece.dialog_speaker
	text_label.text = dialog_piece.dialog_text


func hide_text():
	hide()
	SfxManager.change_bus_volume("SFX", 1.0)
	SfxManager.change_bus_volume("Music", 1.0)
	text_on_screen = false
	name_label.text = ""
	text_label.text = "???"
	dialog_finished.emit()
