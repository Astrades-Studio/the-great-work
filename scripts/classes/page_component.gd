class_name PageComponent
extends Node

var page : Texture
var parent : Node
var text : DialogPiece

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()
	if parent is Page:
		if parent.page:
			page = parent.page
		#if parent.text:
		#	text = parent.text

	if parent.has_user_signal("interacted"):
		parent.connect("interacted", Callable(self, "request_page_UI"))


func request_page_UI():
	if text:
		GameManager.request_text_UI(text)
	elif page:
		GameManager.request_page_UI(page)
