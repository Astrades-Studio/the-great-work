class_name TextLayer
extends CanvasLayer

@onready var texture_rect: TextureRect = $TextureRect
@onready var back_button: Button = %BackButton
@export var audio_delay : float = 0.5

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	GameManager.text_layer = self

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

func _on_back_button_pressed():
	hide_text()


func show_text(text: Texture):
	self.show()
	SfxManager.play_sound(SfxManager.PAGE_BOOK, audio_delay)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	texture_rect.texture = text


func hide_text():
	self.hide()
	SfxManager.play_sound(SfxManager.PAGE_BOOK, audio_delay)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	texture_rect.texture = null
