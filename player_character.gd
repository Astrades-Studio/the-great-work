extends UCharacterBody3D


@onready var interact_ray: RayCast3D = %InteractRay
@onready var gas_lamp: GasLamp = %GasLamp

@export var interact_distance := 2.0
@onready var hand: Node3D = %Hand
@onready var sub_viewport: SubViewport = $HandLayer/SubViewportContainer/SubViewport

# Mini Inventory
var ingredient_in_hand : Ingredient:
	set(value):
		if !value: # If clearing the hand
			ingredient_in_hand = value
			return
		
		if ingredient_in_hand:
			ingredient_in_hand.queue_free()
		ingredient_in_hand = value
		
		hand.add_child(ingredient_in_hand)
		ingredient_in_hand.current_location = Ingredient.Location.HAND

# This is used for raycasting
var interaction_result : Node

# Super() are there to call the parent class movement that I got from the asset store and don't want cluttering here
func _ready() -> void:
	super()
	sub_viewport.size = get_viewport().size # Make sure the item viewport is the same as game viewport
	ingredient_in_hand = hand.get_child(0) # Setup the current ingredient in your hand
	GameManager.player = self # Assign this node to the Autoload for global reference


func _input(event: InputEvent) -> void:
	# Player should not move in other game states 
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	super(event)
	
	if event.is_action_pressed("light"): # Lamp call
		gas_lamp.active = !gas_lamp.active
	
	if event.is_action_pressed("interact"): # Interact call
		interact()
	
	if event.is_action_pressed("drop"): # Drop call
		drop_ingredient()


func drop_ingredient() -> void:
	if ingredient_in_hand:
		# Duplicate the ingredient in hand and change its parent to the node below with a raycast, then free the one in hand
		var dropped_ingredient : Ingredient = ingredient_in_hand.duplicate()

		var ray = RayCast3D.new()
		ray.name = "DropRay"
		ray.target_position = Vector3.DOWN * interact_distance
		add_child(ray)
		ray.force_raycast_update()
		
		if ray.is_colliding():
			var target_node = ray.get_collider() as Node
			target_node.add_child(dropped_ingredient)
			dropped_ingredient.global_transform.origin = ray.target_position
			dropped_ingredient.current_location = Ingredient.Location.ENVIRONMENT
		
		ingredient_in_hand.queue_free()
		ingredient_in_hand = null
		
		ray.queue_free()


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
# Check the PageComponent in Page.tscn to see how this works along the InteractComponent
func interact():
	if !interaction_result:
		return
	if interaction_result.has_user_signal("interacted"):
		interaction_result.emit_signal("interacted")
