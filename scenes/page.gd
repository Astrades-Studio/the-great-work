@tool
class_name Page
extends StaticBody3D

@export var page : Texture:
	set(value):
		page = value
	#	sprite_3d.texture = value

@onready var sprite_3d: Sprite3D = $Sprite3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !page:
		printerr("Forgot to add a page")
		return
	sprite_3d.texture = page
