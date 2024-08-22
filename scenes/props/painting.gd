@tool
class_name Painting
extends Node3D

@onready var mesh: MeshInstance3D = $MeshInstance3D

@export var painting : Texture2D:
	set(value):

		painting = value

		if !mesh:
			return

		var material := StandardMaterial3D.new()
		mesh.material_override = material
		material.albedo_texture = painting
