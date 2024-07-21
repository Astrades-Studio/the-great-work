@tool
class_name Painting
extends StaticBody3D

@onready var mesh: MeshInstance3D = $MeshInstance3D

@export var painting : Texture2D:
	set(value):
		painting = value
		var size := painting.get_size()
		var aspect_ratio := Vector2(size.x / size.y, size.y / size.x)
		var quad : QuadMesh = mesh.mesh
		quad.size = aspect_ratio
		
		var material : Material = mesh.get_active_material(0)
		if material is not StandardMaterial3D:
			material = StandardMaterial3D.new()
		material.albedo_texture = painting
