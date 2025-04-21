class_name InteractionComponent
extends Node

enum InteractionType {
	IDLE,
	LOOK,
	INTERACT,
}

@export var interaction_type : InteractionType = InteractionType.LOOK

var parent : Node

func _ready() -> void:
	parent = get_parent()
	assert(parent, "Node not found")
	connect_parent(parent)
	if parent is Ingredient || parent is Tool || \
	parent is Door || parent is Dispenser || parent is GasLamp:
		interaction_type = InteractionType.INTERACT


func find_body() -> PhysicsBody3D:
	for body in parent.get_children():
		if body is PhysicsBody3D:
			return body
	return null


func in_range() -> void:
	GameManager.crosshair_signal.emit(interaction_type)


func not_in_range() -> void:
	GameManager.crosshair_signal.emit(InteractionType.IDLE)


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
