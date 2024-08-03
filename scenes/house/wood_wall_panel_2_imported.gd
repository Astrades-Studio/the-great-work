extends Node3D


func _ready() -> void:
	var texture = preload("res://assets/models/house/materials/wood_walls.png")
	var image = texture.get_image()
	image.rotate_90(CLOCKWISE)
	texture = ImageTexture.create_from_image(image)
	$Sprite2D.texture = texture
