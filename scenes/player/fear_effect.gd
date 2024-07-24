extends MeshInstance3D

@export var intensity: float = 0.5

func _process(delta: float) -> void:
	if material_override and material_override is ShaderMaterial:
		var shader_material = material_override as ShaderMaterial
		shader_material.set_shader_param("time", Time.get_ticks_msec() / 1000.0)
		shader_material.set_shader_param("intensity", intensity)
