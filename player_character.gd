extends UCharacterBody3D

@onready var interact_ray: RayCast3D = %InteractRay
@onready var gas_lamp: GasLamp = %GasLamp

@export var interact_distance := 2.0
@onready var hand: Node3D = $Head/Hand

# Mini Inventory
var ingredient_in_hand : Ingredient:
	set(value):
		if ingredient_in_hand:
			ingredient_in_hand.queue_free()
		ingredient_in_hand = value
		hand.add_child(ingredient_in_hand)

# This is used for raycasting
var interaction_result : Node

# Super() are there to call the parent class movement that I got from the asset store and don't want cluttering here
func _ready() -> void:
	super()
	ingredient_in_hand = hand.get_child(0)
	GameManager.player = self


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
	
	# Different case scenarios for handling hovering interactible components
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


# Interactible objects will have a XComponent that will 
# define an "interact()" function that takes a parameter if they need a specific item
func interact():
	if !interaction_result:
		return
	if interaction_result.has_user_signal("interacted"):
		interaction_result.emit_signal("interacted")
		#if ingredient_in_hand:
			#interaction_result.emit_signal("interacted", ingredient_in_hand)
		#else:
			#interaction_result.emit_signal("interacted")
