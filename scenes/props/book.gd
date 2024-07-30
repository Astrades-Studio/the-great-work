extends StaticBody3D

@export var book : BookPages

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

var book_material : StandardMaterial3D = preload("res://scenes/props/book_material.tres")
const FLARE_RECIPE = "res://assets/images/recipes/flare_recipe/flare_recipe.tres"
const STONE_RECIPE = "res://assets/images/recipes/stone_recipe/stone_recipe.tres"

@export var read_stone_trigger_book : bool
@export var flare_book : bool

@export var color := Color.WHITE:
	set(value):
		if !is_node_ready():
			await ready
		color = value
		book_material.albedo_color = color
		mesh_instance_3d.mesh.surface_set_material(0, book_material)


func _ready() -> void:
	if has_user_signal("interacted"):
		connect("interacted", open_book)


func open_book() -> void:
	if book.resource_path == FLARE_RECIPE:
		if !GameManager.philosopher_stone_recipe_read:
			DialogManager.create_subtitles_piece("These are instructions on how to make an illuminant")
		else:
			DialogManager.create_subtitles_piece("Maybe if I make this it will keep me safe")
		
	if read_stone_trigger_book:
		if !GameManager.philosopher_stone_recipe_read:
			GameManager.recipe_read.emit()
			DialogManager.create_subtitles_piece("So this is the recipe... I feel something strange is going on.")
	GameManager.request_book_UI.emit(book)
