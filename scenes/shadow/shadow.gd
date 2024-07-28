class_name Shadow
extends Node3D


@onready var shadow_influence: Area3D = $ShadowInfluence

@onready var mesh : MeshInstance3D = $MeshInstance3D
@onready var right_eye: MeshInstance3D = %RightEye
@onready var left_eye: MeshInstance3D = %LeftEye
@onready var material : StandardMaterial3D = mesh.get_active_material(0)

@export var active : bool = false
@export var SPEED : float = 0.1

var following_player : bool
var target : Node
var tween: Tween

# TODO not working
var invisible : bool = true
var inv_tween : Tween
@onready var og_color : Color = Color.BLACK


@export var HP := 100:
	set(value):
		HP = clamp(value, 0, 100)
		var ratio : float = float(HP / 100.)
		
		var new_color = Color(1.0, ratio, ratio, 0.5)
		
		right_eye.mesh.material.albedo_color = new_color
		left_eye.mesh.material.albedo_color = new_color
		
		if HP % 10 == 0:
			follow_player_for(10)
		if HP < 80:
			turn_invisible(20.)



func _ready() -> void:
	if !GameManager.ready:
		await GameManager.ready
	GameManager.tick_countdown.connect(_on_tick_countdown)
	

func _process(_delta: float) -> void:
	if target and active:
		look_at(target.global_position, Vector3.UP, true)


func _on_tick_countdown():
	# TODO: make enemy teleport or faster
	HP -= 1
	target = GameManager.player.head


func follow_player_for(duration : int = 20):
	if !active:
		return
	following_player = true
	get_tree().create_timer(duration).timeout.connect(func(): following_player = false)
	var _target_position : Vector3 = target.global_position
	
	tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", _target_position, 1/SPEED)

var transition_length := 1.0
func turn_invisible(duration: float = 10.) -> void:
	push_warning("Turning invisible")
	
	#get_tree().create_timer(duration).timeout.connect(reset_invisibility)
	inv_tween = get_tree().create_tween()
	inv_tween.tween_property(material, "albedo_color:a", 0.0, transition_length)
	#inv_tween.parallel().tween_property(left_eye, "surface_material_override/0/albedo_color/a", 0.0, transition_length)
	#inv_tween.parallel().tween_property(right_eye, "surface_material_override/0/albedo_color/a", 0.0, transition_length)
	#hide()
	
func reset_invisibility() -> void:

	push_warning("Reseting visibility")
	
	inv_tween = get_tree().create_tween()
	inv_tween.tween_property(material, "albedo_color", og_color, transition_length)
	
	#inv_tween.parallel().tween_pr operty(left_eye, "surface_material_override/0/albedo_color", og_color, transition_length)
	#inv_tween.parallel().tween_property(right_eye, "surface_material_override/0/albedo_color", og_color, transition_length)
	#show()


func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	print("Shadow on screen")
	turn_invisible(1)


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	print("Shadow off screen")
	reset_invisibility()


func _on_shadow_influence_body_entered(body: Node3D) -> void:
	if body is Flare:
		turn_invisible(5.0)
