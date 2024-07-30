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
@onready var interaction_label: Node = $InteractionLabel if has_node("InteractionLabel") else null

@export var active : bool = false : 
	set(value):
		if !GameManager.lamp_in_hand or active == value or disabled:
			return
		active = value
		_update_lamp_state()

@export var on_hand : bool = false
@export var min_value : float = 1.4
@export var max_value : float = 5.0
@export var speed : float = 1.0
@export var min_speed := 0.5
@export var max_speed := 1.5

var speed_variance := 1.0
var time_passed : float = 0.0
var countdown := 1.0
var disabled : bool = false:
	set(value):
		disabled = value
		if disabled:
			active = false

func _ready() -> void:
	_setup_lamp()
	_connect_signals()
	_setup_input_actions()
	if !on_hand:
		active = true
		_update_lamp_state()

func _setup_lamp() -> void:
	if on_hand:
		_setup_hand_lamp()
	else:
		_setup_world_lamp()
	if timer:
		timer.start()

func _setup_hand_lamp() -> void:
	hide()
	disabled = true
	if animation_player:
		animation_player.play("GasLampAnimation")
	_set_lamp_layer(2)
	if light:
		light.light_energy = 0.0
	if fire_beam_2:
		fire_beam_2.emitting = false
	active = false
	_update_lamp_state()

func _setup_world_lamp() -> void:
	set_collision_layer_value(3, true)
	if animation_player:
		animation_player.stop()
	_set_lamp_layer(1)
	active = true
	_update_lamp_state()

func _set_lamp_layer(layer: int) -> void:
	if mesh:
		mesh.set_layer_mask_value(layer, true)
	if fire_beam_2:
		fire_beam_2.set_layer_mask_value(layer, true)
	if light:
		light.set_layer_mask_value(layer, true)

func _connect_signals() -> void:
	if GameManager:
		GameManager.lamp_collected.connect(_on_lamp_collected)
		GameManager.tick_countdown.connect(_on_tick_timeout)
		GameManager.game_started.connect(_on_game_started)
	if self.has_user_signal("interacted"):
		self.connect("interacted", on_lamp_interact)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_lamp") and GameManager.lamp_in_hand:
		active = not active
		_play_lamp_sound()

func _setup_input_actions() -> void:
	if not InputMap.has_action("toggle_lamp"):
		InputMap.add_action("toggle_lamp")
		var event = InputEventKey.new()
		event.keycode = KEY_F  # Puedes cambiar KEY_F por la tecla que prefieras
		InputMap.action_add_event("toggle_lamp", event)

func _play_lamp_sound() -> void:
	if active and gas_lamp_on:
		gas_lamp_on.play()
	elif not active and gas_lamp_off:
		gas_lamp_off.play()

func _update_lamp_state() -> void:
	if mesh:
		var material = mesh.get_surface_override_material(1)
		if material and material is StandardMaterial3D:
			material.emission_enabled = active
	if light:
		light.light_energy = 1.0 if active else 0.0
	if fire_beam_2:
		fire_beam_2.emitting = active
	if active and gas_loop:
		gas_loop.play()
	elif not active and gas_loop:
		gas_loop.stop()

func _on_lamp_collected() -> void:
	if on_hand:
		_set_lamp_layer(2)
		if light:
			light.light_energy = 0.0
		if fire_beam_2:
			fire_beam_2.emitting = false
		active = false
		_update_lamp_state()
		show()

func _on_game_started() -> void:
	disabled = false

func on_lamp_interact() -> void:
	if !on_hand:
		hide()
		if GameManager:
			GameManager.lamp_collected.emit()
			GameManager.lamp_in_hand = true
		if interaction_label:
			interaction_label.queue_free()
		set_collision_layer_value(3, false)
		if mesh:
			mesh.visible = false
	if DialogManager:
		DialogManager.create_subtitles_piece("This will come in handy.")

func _on_tick_timeout() -> void:
	# Implementa aquí la lógica del contador si es necesario
	pass

func _process(delta: float) -> void:
	if !active:
		return
	
	time_passed += delta
	_update_light_energy()
	_update_material_emission()

func _update_light_energy() -> void:
	if light:
		var amplitude = (max_value - min_value) / 2.0
		var offset = (max_value + min_value) / 2.0
		var sine = sin(speed * time_passed)
		var energy = (offset + amplitude * sine * speed_variance) * countdown
		light.light_energy = clamp(energy, 0.3, 6)

func _update_material_emission() -> void:
	if mesh:
		var material = mesh.get_surface_override_material(1)
		if material and material is StandardMaterial3D:
			var emission_min = 1.0
			var emission_max = 3.0
			var emission_amplitude = (emission_max - emission_min) / 2.0
			var emission_offset = (emission_max + emission_min) / 2.0
			var emission_sine = sin(speed * time_passed)
			var emission_energy = emission_offset + emission_amplitude * emission_sine
			material.emission_energy = emission_energy

func _on_timer_timeout() -> void:
	if timer:
		timer.wait_time = randf_range(0.5, 1.0)
	speed_variance = randf_range(min_speed, max_speed)
