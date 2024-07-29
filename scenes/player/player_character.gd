extends UCharacterBody3D
class_name Player

@onready var interact_ray: RayCast3D = %InteractRay
@onready var gas_lamp: GasLamp = %GasLamp
@onready var ingredient_label: Label = %IngredientLabel

@export var interact_distance := 2.0
@export var drop_distance := 1.0

@onready var hand: Node3D = %Hand
@onready var sub_viewport: SubViewport = %ItemViewport

# Mini Inventory
var ingredient_in_hand : Ingredient:
	set(value):
		if !value:
			ingredient_label.text = ""
			ingredient_in_hand = null
		if value:
			drop_ingredient()

		ingredient_in_hand = value

		if ingredient_in_hand:
			ingredient_in_hand.global_transform = hand.global_transform
			ingredient_in_hand.reparent(hand)
			ingredient_in_hand.current_location = Ingredient.Location.HAND
			ingredient_label.text = ingredient_in_hand.type_name


# This is used for raycasting
var interaction_result : Node


# Super() are there to call the parent class movement that I got from the asset store and don't want cluttering here
func _ready() -> void:
	super()
	sub_viewport.size = get_viewport().size # Make sure the item viewport is the same as game viewport
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
	if !ingredient_in_hand:
		return
	
	var target_position : Vector3 = camera.transform.origin - camera.global_transform.basis.z * drop_distance
	var target_node = GameManager.ingredient_layer

	target_position = raycast_forward(target_position)

	ingredient_in_hand.global_transform.origin = target_position
	ingredient_in_hand.current_location = Ingredient.Location.ENVIRONMENT
	ingredient_in_hand.reparent(target_node)
	ingredient_in_hand = null
	
	ingredient_label.text = ""

# Check if there's anything in front of the player
func raycast_forward(to_position : Vector3) -> Vector3:
	var from_position = camera.global_transform.origin
	#var to_position = from_position + camera.global_transform.basis.z * interact_distance
	
	var ray = PhysicsRayQueryParameters3D.create(from_position, to_position)
	var result = get_world_3d().direct_space_state.intersect_ray(ray)
	
	if result:
		return result["position"]
	else:
		return to_position


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
	if is_instance_valid(ingredient_in_hand):
		if ingredient_in_hand is Flare:
			if !ingredient_in_hand.active:
				ingredient_in_hand.active = true
				return

	if !interaction_result:
		return
	
	if interaction_result.has_user_signal("interacted"):
		interaction_result.emit_signal("interacted")
		
