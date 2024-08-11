class_name GasLamp
extends StaticBody3D


@onready var light : OmniLight3D = %GasLampLight
@onready var mesh: MeshInstance3D = $Eje/Hand_Gas_Lamp_002
@onready var timer: Timer = $Timer
@onready var fire_beam_2: GPUParticles3D = $Eje/Hand_Gas_Lamp_002/FireBeam2
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var gas_lamp_on : AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var gas_loop : AudioStreamPlayer3D = $AudioStreamPlayer3D2
@onready var gas_lamp_off : AudioStreamPlayer3D = $AudioStreamPlayer3D3
@onready var interaction_component: InteractionComponent = $InteractionComponent

@export var active : bool = true : 
	set(value):
		if !GameManager.lamp_in_hand or !on_hand:
			return
		if disabled:
			active = false
			return
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

@export var on_hand : bool = false
@export var min_value : float = 5.0
@export var max_value : float = 10.0

@export var speed : float = 1.0
@export var min_speed := 0.5
@export var max_speed := 1.5

var speed_variance := 1.0

var time_passed : float = 0.0
var countdown := 1.0
var disabled : bool:
	set(value):
		disabled = value
		if disabled:
			active = false

func _ready() -> void:
	if on_hand:
		hide()
		disabled = true
		animation_player.play("GasLampAnimation")
	else:
		set_collision_layer_value(3, true)
		animation_player.stop()
		mesh.layers = 0x0001
		fire_beam_2.layers = 0x0001

	timer.start()
	GameManager.lamp_collected.connect(_on_lamp_collected)
	GameManager.tick_countdown.connect(_on_tick_timeout)
	GameManager.game_started.connect(_on_game_started)
	assert(self.has_user_signal("interacted"), "Lamp has no interacted signal")
	self.connect("interacted", on_lamp_interact)

func _on_lamp_collected():
	set_collision_layer_value(3, false)
	if on_hand:
		disabled = false
		active = true
		mesh.layers = 0x0002
		fire_beam_2.layers = 0x0002
		show()

func _on_game_started():
	disabled = false
	
func on_lamp_interact():
	if !on_hand:
		hide()
		GameManager.lamp_in_hand = true
		GameManager.lamp_collected.emit()
		DialogManager.create_subtitles_piece("This will come in handy.")
		if is_instance_valid(interaction_component):
			interaction_component.queue_free()

# Called by GameManager on tick timeout, multiplies the luminosity negatively with time
func _on_tick_timeout():
	#countdown -= 0.1
	pass

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
		if mesh and on_hand:
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
