class_name TextLayer
extends CanvasLayer

@onready var texture_rect: TextureRect = $TextureRect
@onready var back_button: Button = %BackButton
@export var audio_delay : float = 0.5


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	GameManager.text_layer = self
	self.hide_text()


func _input(event: InputEvent) -> void:
	if !visible:
		return

	if event.is_action_pressed("ui_cancel") \
	or event.is_action_pressed("interact"):
		_on_back_button_pressed.call_deferred()


func _on_back_button_pressed():
	hide_text()


func show_text(text: Texture):
	self.show()
	SfxManager.play_sound(SfxManager.PAGE_BOOK, audio_delay)
	GameManager.current_state = GameManager.GameState.PAUSED
	texture_rect.texture = text


func hide_text():
	self.hide()
	GameManager.current_state = GameManager.GameState.PLAYING
	if texture_rect.texture:
		texture_rect.texture = null
		SfxManager.play_sound(SfxManager.PAGE_BOOK, audio_delay)
	
