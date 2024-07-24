extends Node

@export var dialog : Dialog

var parent : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()

	if parent.has_user_signal("interacted"):
		parent.connect("interacted", play_dialog.bind(dialog))


# Called when interacting
func play_dialog(_dialog : Dialog):
	assert(_dialog, "No dialog assigned to " + parent.name)
	if !_dialog:
		printerr("No dialog assigned to " + parent.name)
	DialogManager.play_dialog(_dialog)
