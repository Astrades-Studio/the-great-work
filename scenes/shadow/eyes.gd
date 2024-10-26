@tool
class_name Eyes
extends Node3D


@export var COOLDOWN : float = 30.0
@export var _range : float = 2.0

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var material : StandardMaterial3D = mesh_instance_3d.material_override
@onready var og_color : Color = Color(1.0, 1.0, 1.0, 0.5)
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var collision_shape_3d: CollisionShape3D = $Area3D/CollisionShape3D

var active : bool = false
var player_ref : Player
var max_lifetime := 3.0
var current_lifetime := 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	show()
	active = false
	collision_shape_3d.shape.radius = _range
	_appear_gradually()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		collision_shape_3d.shape.radius = _range

	if !active:
		return
	else:
		current_lifetime += delta
		if player_ref:
			global_position = lerp(global_position, player_ref.camera.global_position, delta)
			if current_lifetime >= max_lifetime:
				current_lifetime = 0.0
				_disappear_gradually()


func _appear_gradually() -> void:
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(material, "albedo_color", og_color, 1.0)
	await tween.finished
	active = true


func _disappear_gradually() -> void:
	audio_stream_player_3d.play()

	var tween : Tween = get_tree().create_tween()
	tween.tween_property(material, "albedo_color", Color.TRANSPARENT, 3.0)
	await tween.finished

	queue_free()
	active = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		player_ref = body
	if active:
		_disappear_gradually()
