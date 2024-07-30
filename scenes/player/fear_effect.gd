extends CanvasLayer

@onready var nausea : TextureRect = $FearEffect
@onready var vignette : TextureRect = $Vignette
@export var amplitude : float = 0.0 #0.05 is target for tween
@export var frequency: float = 0.0 #10 is rapid breathing
@export var vignette_inner_radius : float = 0.1 #0.01 is target for tween
@export var vignette_outer_radius: float = 10.0 #1 is target for tween

func _ready():
	var nausea_material = nausea.material
	var vignette_material = vignette.material
	nausea_material.set_shader_parameter("time", 0.0)  # Initialize time
	set_process(true)
	#await get_tree().create_timer(5).timeout
	#increase_agitation()
	#await get_tree().create_timer(10).timeout
	#decrease_agitation()

func _process(delta):
	var current_time = nausea.material.get_shader_parameter("time")
	nausea.material.set_shader_parameter("amplitude",amplitude)
	nausea.material.set_shader_parameter("frequency",frequency)
	nausea.material.set_shader_parameter("time", current_time + delta)
	vignette.material.set_shader_parameter("inner_radius",vignette_inner_radius)
	vignette.material.set_shader_parameter("outer_radius",vignette_outer_radius)
	#print(nausea.material.get_shader_parameter("amplitude"))
	#print(nausea.material.get_shader_parameter("frequency"))

	
func increase_agitation():
	var tween = get_tree().create_tween().set_parallel(true) 
	tween.tween_property(self, "amplitude", 0.1, 2.0)
	frequency = 10.0
	tween.tween_property(self, "vignette_outer_radius", 1.0, 1.0)
	tween.tween_property(self, "vignette_inner_radius", 0.01, 1.0)
	



func decrease_agitation():
	var tween = get_tree().create_tween().set_parallel(true)
	amplitude = 0
	tween.tween_property(self, "vignette_outer_radius", 10.0, 10.0)
	tween.tween_property(self, "vignette_inner_radius", 0.1, 10.0)
