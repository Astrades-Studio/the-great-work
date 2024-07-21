class_name InteractionComponent
extends Node

@export var mesh : MeshInstance3D
@export var sprite : Sprite3D

const highlight_material : ShaderMaterial = preload("res://assets/outline_material.tres")
var parent : Node
var active_material : Material

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()
	connect_parent()


func in_range() -> void:
	GameManager.update_interaction_label.emit(parent.name)
	
	if mesh:
		active_material = mesh.get_active_material(0)
		if !active_material:
			printerr("Mesh without material assigned")
		active_material.next_pass = highlight_material
	elif sprite:
		sprite.modulate = Color("fed1ff")
	


func not_in_range() -> void:
	GameManager.update_interaction_label.emit("")
	if active_material:
		active_material.next_pass = null
	if sprite:
		sprite.modulate = Color.WHITE


func on_interact() -> void:
	pass


func connect_parent() -> void:
	parent.add_user_signal("focused")
	parent.add_user_signal("unfocused")
	parent.add_user_signal("interacted")
	parent.connect("focused", Callable(self, "in_range"))
	parent.connect("unfocused", Callable(self, "not_in_range"))
	parent.connect("interacted", Callable(self, "on_interact"))
