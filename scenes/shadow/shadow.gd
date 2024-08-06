@tool
class_name Shadow
extends CharacterBody3D


@onready var influence: Area3D = %Influence
@onready var mesh : MeshInstance3D = %Mesh
@onready var material : StandardMaterial3D = mesh.get_active_material(0)
@onready var animation_player: AnimationPlayer = $Import/AnimationPlayer
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D


var invisible : bool = true
var invisibility_tween : Tween
var og_color : Color = Color.BLACK

var speed := 2
var acceleration := 10

func _physics_process(delta: float) -> void:
	var direction : Vector3
	navigation_agent_3d.target_position = GameManager.player.global_position
	
	direction = (navigation_agent_3d.get_next_path_position() - global_position).normalized()
	velocity = velocity.lerp(direction * speed, acceleration * delta)
	look_at(-(navigation_agent_3d.target_position))
	move_and_slide()


var transition_length := 5.0
func turn_invisible() -> void:
	animation_player.play("standing_idle_2")
	await get_tree().create_timer(3.0).timeout # timer 3 seconds
	invisibility_tween = get_tree().create_tween()
	invisibility_tween.tween_property(material, "albedo_color:a", 0.0, transition_length)
	await invisibility_tween.finished
	hide()
	

func reset_invisibility() -> void:	
	show()
	invisibility_tween = get_tree().create_tween()
	invisibility_tween.tween_property(material, "albedo_color", og_color, transition_length)
