@tool
extends StaticBody3D

@export var book : BookPages

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

var book_material : StandardMaterial3D = preload("res://scenes/props/book_material.tres")


@export var color := Color.WHITE:
	set(value):
		if !is_node_ready():
			await ready
		color = value
		book_material.albedo_color = color
		mesh_instance_3d.mesh.surface_set_material(0, book_material)


func _ready() -> void:
	if has_user_signal("interacted"):
		connect("interacted", open_book)


func open_book() -> void:
	GameManager.request_book_UI.emit(book)
