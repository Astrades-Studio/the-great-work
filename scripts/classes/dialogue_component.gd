extends Node

@export var dialog : Dialog

var parent : Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()

	if parent.has_user_signal("interacted"):
		parent.connect("interacted", Callable(self, "play_dialog"))


func play_dialog(_dialog : Dialog):
	if !_dialog:
		printerr("No dialog assigned")
		return
	DialogManager.play_dialog(_dialog)
