@tool
class_name GasLamp
extends StaticBody3D

@onready var light : OmniLight3D = $OmniLight3D
@onready var mesh: MeshInstance3D = $Hand_Gas_Lamp_002
@onready var timer: Timer = $Timer

@export var active : bool = true : 
	set(value):
		active = value
		if mesh:
			mesh.get_surface_override_material(1).emission_enabled = value
		if light:
			if active:
				light.light_energy = lerp(light.light_energy, 1.0, 1.0)
			else:
				light.light_energy = lerp(light.light_energy, 0.0, 1.0)

@export var min_value : float = 0.8
@export var max_value : float = 1.2

@export var speed : float = 1.0
@export var min_speed := 0.5
@export var max_speed := 1.5
@export var speed_variance := 1.0

var time_passed : float = 0.0
var countdown := 1.0

func _ready() -> void:
	active = false
	timer.start()
	GameManager.tick_countdown.connect(_on_tick_timeout)

# Called by GameManager on tick timeout, multiplies the luminosity negatively with time
func _on_tick_timeout():
	countdown -= 0.1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_passed += delta
		
	if !active:
		light.light_energy = lerp(light.light_energy, 0.0, 1.0)
		return
		
	if active:
		var amplitude = (max_value - min_value) / 2.0
		var offset = (max_value + min_value) / 2.0
		var sine = sin(speed * time_passed)
		var energy = (offset + amplitude * sine * speed_variance) * countdown

		light.light_energy = clamp(energy, 0.3, 6)


func _on_timer_timeout() -> void:
	timer.wait_time = randf_range(0.5, 1.0)
	speed_variance = randf_range(min_speed, max_speed)
