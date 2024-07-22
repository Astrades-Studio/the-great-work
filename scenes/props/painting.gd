@tool
class_name Painting
extends StaticBody3D

@onready var mesh: MeshInstance3D = $MeshInstance3D

@export var painting : Texture2D:
	set(value):
		
		painting = value
		
		if !ready:
			return
		
		var material := StandardMaterial3D.new()
		mesh.material_override = material
		material.albedo_texture = painting
