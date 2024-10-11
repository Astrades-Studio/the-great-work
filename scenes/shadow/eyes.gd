class_name Eyes
extends Node3D

@onready var right_eye: MeshInstance3D = %RightEye
@onready var left_eye: MeshInstance3D = %LeftEye

@onready var material : StandardMaterial3D = right_eye.mesh.surface_get_material(0)
@onready var og_color : Color = material.albedo_color

@export var COOLDOWN : float = 30.0

var active : bool = true


func _ready() -> void:
	active = true
	_appear_gradually()


func _process(_delta: float) -> void:
	look_at(GameManager.player.global_position, Vector3.UP, true)


func _appear_gradually() -> void:
	active = true
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(material, "albedo_color", og_color, 3.0)
	await tween.finished


func _disappear_gradually() -> void:
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(material, "albedo_color", Color.TRANSPARENT, 3.0)
	await tween.finished
	active = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		_disappear_gradually()
		_start_cooldown()


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Player and active:
		_appear_gradually()



func _start_cooldown() -> void:
	await get_tree().create_timer(COOLDOWN).timeout
	_appear_gradually()
