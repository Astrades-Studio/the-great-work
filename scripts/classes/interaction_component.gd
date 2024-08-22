class_name InteractionComponent
extends Node

#@export var use_outline : bool = false

enum InteractionType {
	IDLE,
	LOOK,
	INTERACT,
}

@export var interaction_type : InteractionType = InteractionType.LOOK

#const OUTLINE_MATERIAL = preload("res://assets/outline_material.tres")
#const highlight_material : ShaderMaterial = preload("res://assets/outline_material.tres")

var parent : Node
# var meshes : Array[MeshInstance3D] = []
# var sprites : Array[Sprite3D] = []
# var duplicate_materials : Array[Material] = []
# var og_materials : Array[Material] = []
# var outlines : Array[MeshInstance3D] = []

func _ready() -> void:
	parent = get_parent()
	assert(parent, "Node not found")
	connect_parent(parent)
	if parent is Ingredient || parent is Tool || \
	parent is Door || parent is Dispenser || parent is GasLamp:
		interaction_type = InteractionType.INTERACT
	#else:
		#interaction_type = InteractionType.LOOK
	# if parent is MeshInstance3D:
	# 	meshes.append(parent)
	# 	var body = find_body()
	# 	assert(body, "Mesh without physics body")
	# 	connect_parent(body)
	# elif parent is PhysicsBody3D:
	# 	connect_parent(parent)
	# 	find_meshes_and_sprites(parent)
	# else:
	# 	printerr("Parent is not a Physics body or mesh")

# func find_meshes_and_sprites(node: Node) -> void:
# 	for child in node.get_children():
# 		if child is MeshInstance3D:
# 			meshes.append(child)
# 		elif child is Sprite3D:
# 			sprites.append(child)
# 		find_meshes_and_sprites(child)


func find_body() -> PhysicsBody3D:
	for body in parent.get_children():
		if body is PhysicsBody3D:
			return body
	return null


func in_range() -> void:
	GameManager.crosshair_signal.emit(interaction_type)

	# var _text = parent.name
	# if parent is Ingredient:
	# 	_text = parent.type_name
	# GameManager.interaction_label_updated.emit(_text)
	# for i in range(meshes.size()):
	# 	var mesh = meshes[i]
	# 	if use_outline:
	# 		var outline_mesh = mesh.mesh.create_outline(0.22)
	# 		var outline = MeshInstance3D.new()
	# 		outline.mesh = outline_mesh
	# 		mesh.add_child(outline)
	# 		outlines.append(outline)
	# 	else:
	# 		assert(mesh.get_active_material(0), "Mesh without material assigned")
	# 		og_materials.append(mesh.get_active_material(0))
	# 		var duplicate_material = og_materials[i].duplicate()
	# 		duplicate_material.next_pass = highlight_material
	# 		mesh.material_overlay = highlight_material
	# 		duplicate_materials.append(duplicate_material)

	# for sprite in sprites:
	# 	sprite.modulate = Color("fed1ff")

func not_in_range() -> void:
	GameManager.crosshair_signal.emit(InteractionType.IDLE)
	# for i in range(meshes.size()):
	# 	var mesh = meshes[i]
	# 	if use_outline:
	# 		if i < outlines.size():
	# 			outlines[i].queue_free()
	# 	else:
	# 		mesh.material_overlay = null
	# GameManager.interaction_label_updated.emit(InteractionType.IDLE)
	# duplicate_materials.clear()
	# og_materials.clear()
	# outlines.clear()

	# for sprite in sprites:
	# 	sprite.modulate = Color.WHITE


func on_interact() -> void:
	pass


func _on_parent_visibility_change():
	if !parent.visible:
		if parent.has_user_signal("unfocused"):
			parent.unfocused.emit()


func connect_parent(node: Node3D) -> void:
	node.add_user_signal("focused")
	node.add_user_signal("unfocused")
	node.add_user_signal("interacted")
	node.connect("focused", Callable(self, "in_range"))
	node.connect("unfocused", Callable(self, "not_in_range"))
	node.connect("interacted", Callable(self, "on_interact"))
