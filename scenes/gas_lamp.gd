@tool
class_name GasLamp
extends StaticBody3D

@onready var light : OmniLight3D = $OmniLight3D
@onready var mesh: MeshInstance3D = $Eje/Hand_Gas_Lamp_002
@onready var timer: Timer = $Timer
@onready var fire_beam_2: GPUParticles3D = $Eje/Hand_Gas_Lamp_002/FireBeam2
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var gas_lamp_on : AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var gas_loop : AudioStreamPlayer3D = $AudioStreamPlayer3D2
@onready var gas_lamp_off : AudioStreamPlayer3D = $AudioStreamPlayer3D3

@export var active : bool = true : 
	set(value):
		active = value
		if mesh:
			var material = mesh.get_surface_override_material(1)
			if material and material is StandardMaterial3D:
				material.emission_enabled = value
		if light:
			if active:
				light.light_energy = lerp(light.light_energy, 1.0, 1.0)
				fire_beam_2.emitting = true
				gas_lamp_on.play()
				gas_loop.play()
			else:
				light.light_energy = lerp(light.light_energy, 0.0, 1.0)
				fire_beam_2.emitting = false
				gas_lamp_off.play()
				gas_loop.stop()

@export var min_value : float = 1.4
@export var max_value : float = 5.0

@export var speed : float = 1.0
@export var min_speed := 0.5
@export var max_speed := 1.5
@export var speed_variance := 1.0

var time_passed : float = 0.0
var countdown := 1.0

func _ready() -> void:
	timer.start()
	GameManager.tick_countdown.connect(_on_tick_timeout)
	animation_player.play("GasLampAnimation")

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
		
		
		# Animate emission in material
		if mesh:
			var material = mesh.get_surface_override_material(1)
			if material and material is StandardMaterial3D:
				# Animate emission from x to x and back
				var emission_min = 1.0
				var emission_max = 3.0
				var emission_amplitude = (emission_max - emission_min) / 2.0
				var emission_offset = (emission_max + emission_min) / 2.0
				var emission_sine = sin(speed * time_passed)
				var emission_energy = emission_offset + emission_amplitude * emission_sine
				material.emission_energy = emission_energy

func _on_timer_timeout() -> void:
	timer.wait_time = randf_range(0.5, 1.0)
	speed_variance = randf_range(min_speed, max_speed)
