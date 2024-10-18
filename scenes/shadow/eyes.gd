class_name Eyes
extends Node3D


@export var COOLDOWN : float = 30.0

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var material : StandardMaterial3D = mesh_instance_3d.material_override
@onready var og_color : Color = material.albedo_color
@onready var og_position : Vector3 = self.global_position

var active : bool = true
var player_ref : Player

func _ready() -> void:
	_appear_gradually()


func _appear_gradually() -> void:
	active = true
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(material, "albedo_color", og_color, 3.0)
	tween.parallel().tween_property(self, "global_position", og_position, 0.1)
	await tween.finished


func _disappear_gradually() -> void:
	var tween : Tween = get_tree().create_tween()
	var camera = get_viewport().get_camera_3d()
	tween.tween_property(material, "albedo_color", Color.TRANSPARENT, 3.0)
	if player_ref:
		tween.parallel().tween_property(self, "global_position", camera.global_position, 3.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	# get the current camera


	active = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		player_ref = body
		_disappear_gradually()
		_start_cooldown()


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Player and active:
		player_ref = null
		_appear_gradually()



func _start_cooldown() -> void:
	await get_tree().create_timer(COOLDOWN).timeout
	_appear_gradually()
