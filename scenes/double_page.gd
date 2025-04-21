extends StaticBody3D

@export var book : BookPages


func _ready() -> void:
	if has_user_signal("interacted"):
		connect("interacted", open_book)


func open_book() -> void:
	GameManager.request_book_UI.emit(book)
