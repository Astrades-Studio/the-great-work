@tool
extends CharacterBody3D
class_name UCharacterBody3D

# TODO Thanks to mrezai on Reddit

@onready var body: Node3D = $Body
@onready var head = $Body/Head
@onready var camera : Camera3D = $Body/Head/CameraMarker3D/Camera3D
@onready var camera_target = $Body/Head/CameraMarker3D
@onready var head_position: Vector3 = head.position
@onready var item_camera: Camera3D = %ItemCamera

@onready var item_viewport: SubViewport = %ItemViewport

var mouse_sensitivity: float = 0.1

@export var ACCELERATION_DEFAULT: float = 7.0
@export var ACCELERATION_AIR: float = 1.0
@export var SPEED_DEFAULT: float = 7.0
@export var SPEED_ON_STAIRS: float = 5.0

var acceleration: float = ACCELERATION_DEFAULT
var speed: float = SPEED_DEFAULT

var gravity: float = 9.8
var jump: float = 5.0
var direction: Vector3 = Vector3.ZERO
var main_velocity: Vector3 = Vector3.ZERO
var gravity_direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO

@export var STAIRS_FEELING_COEFFICIENT: float = 2.5
@export var WALL_MARGIN: float = 0.001
@export var STEP_DOWN_MARGIN: float = 0.01
@export var STEP_HEIGHT_DEFAULT: Vector3 = Vector3(0, 0.6, 0)
@export var STEP_HEIGHT_IN_AIR_DEFAULT: Vector3 = Vector3(0, 0.6, 0)
@export var STEP_MAX_SLOPE_DEGREE: float = 40.0
@export var STEP_CHECK_COUNT: int = 2
@export var SPEED_CLAMP_AFTER_JUMP_COEFFICIENT = 0.4
@export var SPEED_CLAMP_SLOPE_STEP_UP_COEFFICIENT = 0.4

var step_height_main: Vector3
var step_incremental_check_height: Vector3
var is_enabled_stair_stepping_in_air: bool = true
var is_jumping: bool = false
var is_in_air: bool = false

var head_offset: Vector3 = Vector3.ZERO
var camera_target_position : Vector3 = Vector3.ZERO
var camera_lerp_coefficient: float = 1.0
var time_in_air: float = 0.0
var update_camera = false
var camera_gt_previous : Transform3D
var camera_gt_current : Transform3D


class StepResult:
	var diff_position: Vector3 = Vector3.ZERO
	var normal: Vector3 = Vector3.ZERO
	var is_step_up: bool = false


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	camera_target_position = camera.global_transform.origin
	camera.set_as_top_level(true)
	camera.global_transform = camera_target.global_transform
	
	camera_gt_previous = camera_target.global_transform
	camera_gt_current = camera_target.global_transform
	
	item_viewport.world_3d = camera.get_world_3d()
	

func update_camera_transform():
	camera_gt_previous = camera_gt_current
	camera_gt_current = camera_target.global_transform
	

func _process(delta: float) -> void:
	if update_camera:
		update_camera_transform()
		update_camera = false
	
	item_camera.global_transform = camera.global_transform
	

	var interpolation_fraction = clamp(Engine.get_physics_interpolation_fraction(), 0, 1)

	var camera_xform = camera_gt_previous.interpolate_with(camera_gt_current, interpolation_fraction)
	camera.global_transform = camera_xform
	
	# Make sure the camera is not rotated on the z axis:
	camera.rotation.z = 0
	
	var head_xform : Transform3D = head.get_global_transform()
	
	camera_target_position = lerp(camera_target_position, head_xform.origin, delta * speed * STAIRS_FEELING_COEFFICIENT * camera_lerp_coefficient)
	
	if is_on_floor():
		time_in_air = 0.0
		camera_lerp_coefficient = 1.0
		camera.position.y = camera_target_position.y
	else:
		time_in_air += delta
		if time_in_air > 1.0:
			camera_lerp_coefficient += delta
			camera_lerp_coefficient = clamp(camera_lerp_coefficient, 2.0, 4.0)
		else: 
			camera_lerp_coefficient = 2.0

		camera.position.y = camera_target_position.y

func _input(event):
	if event is InputEventMouseMotion:
		body.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	update_camera = true
	var is_step: bool = false
	
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (body.global_transform.basis * Vector3(input.x, 0, input.y)).normalized()

	if is_on_floor():
		is_jumping = false
		is_in_air = false
		acceleration = ACCELERATION_DEFAULT
		gravity_direction = Vector3.ZERO
	else:
		is_in_air = true
		acceleration = ACCELERATION_AIR
		gravity_direction += Vector3.DOWN * gravity * delta

	if Input.is_action_just_pressed("action_jump") and is_on_floor():
		is_jumping = true
		is_in_air = false
		gravity_direction = Vector3.UP * jump

	main_velocity = main_velocity.lerp(direction * speed, acceleration * delta)

	var step_result : StepResult = StepResult.new()
	
	is_step = step_check(delta, is_jumping, step_result)
	
	if is_step:
		var is_enabled_stair_stepping: bool = true
		if step_result.is_step_up and is_in_air and not is_enabled_stair_stepping_in_air:
			is_enabled_stair_stepping = false

		if is_enabled_stair_stepping:
			global_transform.origin += step_result.diff_position
			head_offset = step_result.diff_position
			speed = SPEED_ON_STAIRS
	else:
		head_offset = head_offset.lerp(Vector3.ZERO, delta * speed * STAIRS_FEELING_COEFFICIENT)
		
		if abs(head_offset.y) <= 0.01:
			speed = SPEED_DEFAULT

	movement = main_velocity + gravity_direction

	set_velocity(movement)
	set_max_slides(6)
	move_and_slide()
	
	if is_step and step_result.is_step_up and is_enabled_stair_stepping_in_air:
		if is_in_air or direction.dot(step_result.normal) > 0:
			main_velocity *= SPEED_CLAMP_AFTER_JUMP_COEFFICIENT
			gravity_direction *= SPEED_CLAMP_AFTER_JUMP_COEFFICIENT

	if is_jumping:
		is_jumping = false
		is_in_air = true

func step_check(delta: float, is_jumping_: bool, step_result: StepResult):
	var is_step: bool = false
	
	step_height_main = STEP_HEIGHT_DEFAULT
	step_incremental_check_height = STEP_HEIGHT_DEFAULT / STEP_CHECK_COUNT
	
	if is_in_air and is_enabled_stair_stepping_in_air:
		step_height_main = STEP_HEIGHT_IN_AIR_DEFAULT
		step_incremental_check_height = STEP_HEIGHT_IN_AIR_DEFAULT / STEP_CHECK_COUNT
		
	if gravity_direction.y >= 0:
		for i in range(STEP_CHECK_COUNT):
			var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
			
			var step_height: Vector3 = step_height_main - i * step_incremental_check_height
			var transform3d: Transform3D = global_transform
			var motion: Vector3 = step_height
			var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)

			if is_player_collided and test_motion_result.get_collision_normal().y < 0:
				continue

			transform3d.origin += step_height
			motion = main_velocity * delta
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if not is_player_collided:
				transform3d.origin += motion
				motion = -step_height
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
				
				if is_player_collided:
					if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
						is_step = true
						step_result.is_step_up = true
						step_result.diff_position = -test_motion_result.get_remainder()
						step_result.normal = test_motion_result.get_collision_normal()
						break
			else:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
				transform3d.origin += wall_collision_normal * WALL_MARGIN
				motion = (main_velocity * delta).slide(wall_collision_normal)
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
				
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					test_motion_params.from = transform3d
					test_motion_params.motion = motion
					
					is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
					
					if is_player_collided:
						if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
							is_step = true
							step_result.is_step_up = true
							step_result.diff_position = -test_motion_result.get_remainder()
							step_result.normal = test_motion_result.get_collision_normal()
							break

	if not is_jumping_ and not is_step and is_on_floor():
		step_result.is_step_up = false
		var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		var transform3d: Transform3D = global_transform
		var motion: Vector3 = main_velocity * delta
		var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
		test_motion_params.from = transform3d
		test_motion_params.motion = motion
		test_motion_params.recovery_as_collision = true

		var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
		if not is_player_collided:
			transform3d.origin += motion
			motion = -step_height_main
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if is_player_collided and test_motion_result.get_travel().y < -STEP_DOWN_MARGIN:
				if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
					is_step = true
					step_result.diff_position = test_motion_result.get_travel()
					step_result.normal = test_motion_result.get_collision_normal()
		elif is_zero_approx(test_motion_result.get_collision_normal().y):
			var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
			transform3d.origin += wall_collision_normal * WALL_MARGIN
			motion = (main_velocity * delta).slide(wall_collision_normal)
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if not is_player_collided:
				transform3d.origin += motion
				motion = -step_height_main
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
				
				if is_player_collided and test_motion_result.get_travel().y < -STEP_DOWN_MARGIN:
					if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
						is_step = true
						step_result.diff_position = test_motion_result.get_travel()
						step_result.normal = test_motion_result.get_collision_normal()

	return is_step
