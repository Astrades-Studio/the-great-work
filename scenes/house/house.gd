@tool
extends Node3D

@onready var roof: Node3D = %Roof

@export var roof_visible: bool:
	set(value):
		if !Engine.is_editor_hint():
			return
		if !roof:
			return
		roof_visible = value
		if !roof_visible:
			roof.hide()
		else:
			roof.show()

func _ready() -> void:
	roof_visible = true
