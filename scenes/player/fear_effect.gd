extends CanvasLayer

@onready var canvas_layer : TextureRect = $FearEffect

func _ready():
	var shader_material = canvas_layer.material
	shader_material.set_shader_parameter("time", 0.0)  # Initialize time
	set_process(true)

func _process(delta):
	var shader_material = canvas_layer.material
	var current_time = shader_material.get_shader_parameter("time")
	shader_material.set_shader_parameter("time", current_time + delta)




func _on_v_slider_value_changed(value: float) -> void:
	$FearEffect.get_material().set_shader_parameter("amplitude",value/1000)
	$FearEffect.get_material().set_shader_parameter("frequency",value/10)
