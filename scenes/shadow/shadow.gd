class_name Shadow
extends Node3D


@onready var influence: Area3D = %Influence
@onready var mesh : MeshInstance3D = %Mesh
@onready var material : StandardMaterial3D = mesh.get_active_material(0)


# TODO not working
var invisible : bool = true
var invisibility_tween : Tween
var og_color : Color = Color.BLACK


func _ready() -> void:
	pass
	

func _process(_delta: float) -> void:
	pass
	# if target and active:
	# 	look_at(target.global_position, Vector3.UP, true)


var transition_length := 4.0
func turn_invisible() -> void:
	print(self.name + " turning invisible" )
	invisibility_tween = get_tree().create_tween()
	invisibility_tween.tween_property(material, "albedo_color:a", 0.0, transition_length)
	await invisibility_tween.finished
	#hide()
	

func reset_invisibility() -> void:	
	#show()
	print(self.name + " turning visible" )
	invisibility_tween = get_tree().create_tween()
	invisibility_tween.tween_property(material, "albedo_color", og_color, transition_length)
	

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	print("Shadow on screen")
	turn_invisible()


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	print("Shadow off screen")
	reset_invisibility()
