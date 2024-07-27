@tool
class_name Page
extends StaticBody3D

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var page_mesh: MeshInstance3D = $PageMesh

@export var page : Texture:
	set(value):
		page = value
		if sprite_3d:
			sprite_3d.texture = value
		if page_mesh:
			var material = page_mesh.get_active_material(0)
			material.albedo_texture = value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !page:
		printerr("Forgot to add a page")
		return
	if sprite_3d:
		sprite_3d.texture = page
