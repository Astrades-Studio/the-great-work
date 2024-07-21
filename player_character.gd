extends UCharacterBody3D

@onready var interact_ray: RayCast3D = %InteractRay
@onready var gas_lamp: GasLamp = %GasLamp

@export var interact_distance := 2.0

var interaction_result : Node

func _ready() -> void:
	super()

func _input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	super(event)
	if event.is_action_pressed("light"):
		gas_lamp.active = !gas_lamp.active
	
	if event.is_action_pressed("interact"):
		interact()

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	super(delta)
	
	if interact_ray.is_colliding():
		var current_interact_result = interact_ray.get_collider()
		if interaction_result != current_interact_result:
			if interaction_result and interaction_result.has_user_signal("unfocused"):
				interaction_result.emit_signal("unfocused")
				
			interaction_result = current_interact_result
			if interaction_result and interaction_result.has_user_signal("focused"):
				interaction_result.emit_signal("focused")
				
	else:
		if interaction_result and interaction_result.has_user_signal("unfocused"):
			interaction_result.emit_signal("unfocused")
			interaction_result = null
	
func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	super(delta)

func interact():
	if !interaction_result:
		return
	if interaction_result.has_user_signal("interacted"):
		interaction_result.emit_signal("interacted")
