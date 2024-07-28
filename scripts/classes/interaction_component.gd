class_name InteractionComponent
extends Node

@export var mesh : MeshInstance3D
@export var sprite : Sprite3D
@export var use_outline : bool = false

const OUTLINE_MATERIAL = preload("res://assets/outline_material.tres")
const highlight_material : ShaderMaterial = preload("res://assets/outline_material.tres")
var parent : Node
var duplicate_material : Material
var og_material : Material
var outline : MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()
	
	if parent is MeshInstance3D:
		mesh = parent
		var body = find_body()
		assert(body, "Mesh without physics body")
		connect_parent(body)

	elif parent is PhysicsBody3D:
		connect_parent(parent)

	else:
		printerr("Parent is not a Physics body or mesh")

func find_body() -> PhysicsBody3D:
	for body in parent.get_children():
		if body is PhysicsBody3D:
			return body
	return null


func in_range() -> void:
	var _text = parent.name
	if parent is Ingredient:
		_text = parent.type_name
	
	GameManager.interaction_label_updated.emit(_text)
	
	if !is_instance_valid(mesh):
		mesh = find_mesh()
	if is_instance_valid(mesh):
		if use_outline:
			var outline_mesh = mesh.mesh.create_outline(0.22)
			outline = MeshInstance3D.new()
			outline.mesh = outline_mesh
			mesh.add_child(outline)
		else:
			assert(mesh.get_active_material(0), "Mesh without material assigned")
			# Get the original material
			og_material = mesh.get_active_material(0)
			# Duplicate it to avoid modifying the original shared one
			duplicate_material = og_material.duplicate()
			# Change the next pass to the highlight material
			duplicate_material.next_pass = highlight_material
			# Apply the new material to the object's active material slot
			mesh.material_overlay = highlight_material
			
	elif sprite:
		sprite.modulate = Color("fed1ff")
	else:
		printerr("No mesh or sprite found")


func not_in_range() -> void:
	GameManager.interaction_label_updated.emit("")
	if duplicate_material:
		mesh.material_overlay = null
		# Free the reference to the duplicate material
		duplicate_material = null
	
	if outline and use_outline:
		outline.queue_free()
		
	if sprite:
		sprite.modulate = Color.WHITE


func on_interact() -> void:
	print("interacted with " + self.name)
	pass


func connect_parent(node: PhysicsBody3D) -> void:
	node.add_user_signal("focused")
	node.add_user_signal("unfocused")
	node.add_user_signal("interacted")
	node.connect("focused", Callable(self, "in_range"))
	node.connect("unfocused", Callable(self, "not_in_range"))
	node.connect("interacted", Callable(self, "on_interact"))

func find_mesh() -> MeshInstance3D:
	for child in parent.get_children():
		if child is MeshInstance3D:
			return child
	return null
