class_name Shadow
extends CharacterBody3D

@onready var hurtbox: Area3D = %Hurtbox
@onready var hitbox: Area3D = %Hitbox
@onready var mesh : MeshInstance3D = %Mesh
@onready var material : Material = mesh.material_overlay
@onready var animation_player: AnimationPlayer = $Import/AnimationPlayer2
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var wait_timer: Timer = $WaitTimer
@onready var label_3d: Label3D = $Label3D
@onready var darkness_fx: GPUParticles3D = %DarknessFX


enum State{
	WAITING,
	PURSUING,
	RETURNING,
	HURT
}

var current_state := State.WAITING
const MAX_WAIT := 10.
var wait_time : float = 10.
var can_attack := false

# Moving
var target : Node
var target_position : Vector3
var spawn_point : Vector3
var speed := 0.5
var acceleration := 5

# Invisibility
var invisible : bool = true
var invisibility_tween : Tween

# get the shader_parameter/alpha from the material
@onready var og_color : float = material.get_shader_parameter("alpha")


func _ready() -> void:
	spawn_point = self.global_position
	wait_timer.timeout.connect(self._on_timeout)
	animation_player.play("standing_idle")


func _physics_process(delta: float) -> void:
	if current_state == State.WAITING:
		#animation_player.play("standing_idle")
		pass
	elif current_state == State.HURT:
		pass
		#turn_invisible()
		#move_to_target(spawn_point, delta)
	elif current_state == State.RETURNING:
		move_to_target(spawn_point, delta)
	elif current_state == State.PURSUING:
		if target:
			move_to_target(target.global_position, delta)
		elif target_position:
			move_to_target(target_position, delta)


func _on_timeout() -> void:
	if current_state == State.WAITING:
		change_state_to(State.RETURNING)


func change_state_to(state : State) -> void:
	current_state = state
	match state:
		State.WAITING:
			can_attack = true
			wait_timer.start(wait_time)

		State.PURSUING:
			can_attack = true
			pass

		State.HURT:
			can_attack = false
			animation_player.play("agony")

		State.RETURNING:
			can_attack = true
			pass
	label_3d.text = State.keys()[state]

func move_to_target(_position : Vector3, delta : float):
	animation_player.play("walking")
	var direction : Vector3
	navigation_agent_3d.target_position = _position

	direction = (navigation_agent_3d.get_next_path_position() - global_position).normalized()
	velocity = velocity.lerp(direction * speed, acceleration * delta)
	look_at(navigation_agent_3d.target_position, Vector3.UP, true)
	move_and_slide()


var transition_length := 5.0
func turn_invisible() -> void:
	#animation_player.play("standing_idle_2")
	#await get_tree().create_timer(3.0).timeout # timer 3 seconds
	invisibility_tween = get_tree().create_tween()
	invisibility_tween.tween_property(material, "shader_parameter/alpha", 1.0, 1/3)
	darkness_fx.emitting = false
	await invisibility_tween.finished
	hide()


func reset_invisibility() -> void:
	show()
	invisibility_tween = get_tree().create_tween()
	invisibility_tween.tween_property(material, "shader_parameter/alpha", og_color, transition_length)


func _on_navigation_agent_3d_target_reached() -> void:
	print("Target reached")
	change_state_to(State.WAITING)
	target_position = Vector3.ZERO


func _on_hitbox_body_entered(body: Node3D) -> void:
	if body is Player and can_attack:
		GameManager.game_over.emit()

func start_agony_animation() -> void:
	animation_player.play("agony")
	await animation_player.animation_finished
