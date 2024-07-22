@tool
class_name Dialog
extends Resource

#static var dialog_array : Array[int]
#static var dialog_count : int

@export var dialog_id : StringName
@export var dialog : Array[DialogPiece]

# Counts how many dialogs have been made to assign unique ids automatically
#static func _static_init() -> void:
	#dialog_array.append(dialog_count)
	#dialog_count += 1
#
#func free() -> void:
	#pass
