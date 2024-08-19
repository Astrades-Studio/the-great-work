extends UCharacterBody3D
class_name Player

@onready var animation_player: AnimationPlayer = $Body/AnimationPlayer
@onready var interact_ray: RayCast3D = %InteractRay
@onready var gas_lamp: GasLamp = %GasLamp
@onready var ingredient_label: Label = %IngredientLabel
@onready var panic_effects: Node = $PanicEffects


@export var interact_distance := 2.0
@export var drop_distance := 1.0
@export var throw_impulse := 3.0

var charging := false
var charge := 0.0

@onready var interaction_label: Label = %InteractionLabel
@onready var hand: Node3D = %Hand
@onready var sub_viewport: SubViewport = %ItemViewport

@onready var collision_shape_normal: CollisionShape3D = $CollisionShapeNormal
@onready var collision_shape_crouch: CollisionShape3D = $CollisionShapeCrouch
@onready var crouch_height: Marker3D = %CrouchHeight


# Mini Inventory
var ingredient_in_hand: Ingredient:
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
var interaction_result: Node

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

	if event.is_action_pressed("crouch"): # Crouch call
		toggle_crouch()

	if event.is_action_pressed("drop"): # Drop call
		charging = true

	if event.is_action_released("drop"):
		charging = false
		if charge >= 1.0:
			throw_ingredient(throw_impulse * charge)
		else:
			drop_ingredient()
		charge = 0.0


func drop_ingredient() -> void:
	if !ingredient_in_hand:
		return
	if ingredient_in_hand.get_parent() == null:
		ingredient_in_hand.queue_free()

	# Stop Axel from dropping the stone
	#if ingredient_in_hand.type == Ingredient.Type.PHILOSOPHERS_STONE:
		#DialogManager.create_dialog_piece("I have no need of parting with it.")
		#return

	var target_position: Vector3 = camera.transform.origin - camera.global_transform.basis.z * drop_distance
	var target_node = GameManager.ingredient_layer

	target_position = raycast_forward(target_position)

	ingredient_in_hand.global_transform.origin = target_position
	ingredient_in_hand.current_location = Ingredient.Location.ENVIRONMENT
	ingredient_in_hand.reparent(target_node)
	ingredient_in_hand = null

	ingredient_label.text = ""


func throw_ingredient(_throw_impulse : float) -> void:
	if !ingredient_in_hand:
		return
	# Stop Axel from dropping the stone
	if ingredient_in_hand.type == Ingredient.Type.PHILOSOPHERS_STONE:
		DialogManager.create_dialog_piece("I'm not insane enough to throw it.")
		return

	var target_node = GameManager.ingredient_layer

	ingredient_in_hand.current_location = Ingredient.Location.ENVIRONMENT
	ingredient_in_hand.reparent(target_node)

	# apply forward force to the rigid body
	ingredient_in_hand.apply_impulse(-camera.global_transform.basis.z * (_throw_impulse))

	ingredient_in_hand = null
	ingredient_label.text = ""


# Check if there's anything in front of the player
func raycast_forward(to_position: Vector3) -> Vector3:
	var from_position = camera.global_transform.origin
	var ray = PhysicsRayQueryParameters3D.create(from_position, to_position)
	ray.hit_back_faces = false
	var result = get_world_3d().direct_space_state.intersect_ray(ray)

	if result:
		return result["position"]
	else:
		return to_position

func charge_throw(delta: float) -> void:
	if !charging:
		return
	charge += delta
	charge = clamp(charge, 0.0, 2.0)

func _process(delta: float) -> void:
	SimpleGrass.set_player_position(global_position)
	if GameManager.current_state == GameManager.GameState.STATIC:
		# Permite el movimiento de la cámara pero no del jugador
		return

	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	super(delta)
	if charging:
		charge_throw(delta)

	if !interact_ray.is_colliding():
		interaction_label.text = ""

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
	if GameManager.current_state == GameManager.GameState.STATIC:
		# Permite el movimiento de la cámara pero no del jugador
		return

	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	super(delta)

# Interactible objects will have a XComponent that will
# define an "interact()" function that takes a parameter if they need a specific item
# Check the PageComponent in Page.tscn to see how this works along the InteractComponent
func interact():
	if interaction_result:
		if interaction_result.has_user_signal("interacted"):
			interaction_result.emit_signal("interacted")
			return
	if is_instance_valid(ingredient_in_hand):
		if ingredient_in_hand is Flare:
			if !ingredient_in_hand.active:
				ingredient_in_hand.active = true
			else:
				animation_player.play("attack")
		elif ingredient_in_hand.type == Ingredient.Type.PHILOSOPHERS_STONE:
			animation_player.play("swallow")
			await animation_player.animation_finished
			GameManager.stone_consumed.emit()


func toggle_crouch() -> void:
	if crouching:
		animation_player.play("crouch", -1, -crouch_speed, true)
		collision_shape_normal.disabled = false
		collision_shape_crouch.disabled = true
	else:
		animation_player.play("crouch", -1, crouch_speed, false)
		collision_shape_normal.disabled = true
		collision_shape_crouch.disabled = false
	crouching = !crouching
