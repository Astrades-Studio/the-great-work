@tool
class_name DialogPiece
extends Resource


@export var dialog_speaker : String 
@export_multiline var dialog_text : String

func _init() -> void:
	if !dialog_speaker:
		dialog_speaker = "Melchiades"
