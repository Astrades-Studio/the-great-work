class_name PageComponent
extends Node

var page : Texture
var parent : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()
	if parent is Page:
		page = parent.page
	if parent.has_user_signal("interacted"):
		parent.connect("interacted", Callable(self, "request_page_UI").bind(page))

func request_page_UI(page: Texture):
	if !page:
		printerr("No page assigned")
		return
	GameManager.request_page_UI(page)
