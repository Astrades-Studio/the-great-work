extends Node3D

@onready var mesh : MeshInstance3D = $MeshInstance3D
@onready var right_eye : MeshInstance3D = $MeshInstance3D/MeshInstance3D
@onready var left_eye: MeshInstance3D = $MeshInstance3D/MeshInstance3D2


@export var active : bool = false

@export var HP := 100:
	set(value):
		HP = clamp(value, 0, 100)
		var ratio : float = float(HP / 100)
		
		var new_color = Color(1.0, ratio, ratio, 0.5)
		
		right_eye.mesh.material.albedo_color = new_color
		left_eye.mesh.material.albedo_color = new_color
		
		if HP % 10 == 0:
			follow_player_for(10)
		if HP < 80:
			turn_invisible(20.)

var following_player : bool
var target : Node


func _ready() -> void:
	if !GameManager.ready:
		await GameManager.ready
	GameManager.tick_countdown.connect(_on_tick_countdown)
	
	
var tween: Tween
@export var SPEED : float = 0.1

func _process(delta: float) -> void:
	if target and active:
		look_at(target.global_position, Vector3.UP, true)


func _on_tick_countdown():
	# TODO: make enemy teleport or faster
	print("Shadow HP: " + str(HP))
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


# TODO not working
var invisible : bool = true
var inv_tween : Tween
@onready var og_color : Color = mesh.mesh.material.albedo_color

func turn_invisible(duration: float = 10.) -> void:
	get_tree().create_timer(duration).timeout.connect(func(): invisible = false)
	inv_tween = get_tree().create_tween()
	inv_tween.tween_property(mesh, "mesh/material/albedo_color", Color.TRANSPARENT, 3.0)
	inv_tween.parallel().tween_property(left_eye, "mesh/material/albedo_color", Color.TRANSPARENT, 3.0)
	inv_tween.parallel().tween_property(right_eye, "mesh/material/albedo_color", Color.TRANSPARENT, 3.0)
	
