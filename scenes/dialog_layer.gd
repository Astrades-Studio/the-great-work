class_name DialogLayer
extends CanvasLayer

@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %TextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide()
	DialogManager.dialog_layer = self

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		if visible:
			DialogManager.skip()


func show_text(string: DialogManager.DialogPiece):
	show()
	name_label.text = string.dialog_name
	text_label.text = string.dialog_text 

func hide_text():
	hide()
	name_label.text = ""
	text_label.text = "???"
