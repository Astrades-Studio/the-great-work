class_name TextLayer
extends CanvasLayer

@export var audio_delay : float = 0.5

@onready var texture_rect: TextureRect = %TextureRect
@onready var back_button: Button = %BackButton
@onready var previous_button: Button = %PreviousButton
@onready var next_button: Button = %NextButton
@onready var page_label: Label = %PageLabel

#@onready var text_label: Label = %TextLabel

var book : BookPages
var book_page : int = 0:
	set(value):
		if value < 0:
			book_page = 0
			return
		book_page = value


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	GameManager.text_layer = self
	GameManager.request_book_UI.connect(show_book)
	hide()


func _input(event: InputEvent) -> void:
	if !visible:
		return
	if event.is_action_pressed("interact") \
	or event.is_action_pressed("ui_accept") \
	or event.is_action_pressed("ui_cancel"):
		_on_next_button_pressed.call_deferred()
	elif event.is_action_pressed("drop"):
		_on_previous_button_pressed.call_deferred()


func show_book(_book : BookPages):
	book = _book

	if book.pages.size() <= 0:
		hide_text()
		return

	show_book_page(book_page)


func show_text(text: DialogPiece):
	if !text:
		printerr("Empty dialog piece at " + str(self.get_path()))

	show()
	SfxManager.play_sound(SfxManager.PAGE_BOOK, audio_delay, -8)
	GameManager.current_state = GameManager.GameState.PAUSED
#	text_label.text = text.dialog_text


func show_page(page: Texture2D):
	if !page:
		return
	self.show()
	SfxManager.play_sound(SfxManager.PAGE_BOOK, audio_delay, -8)
	GameManager.current_state = GameManager.GameState.PAUSED

	texture_rect.texture = page


func hide_text():
	self.hide()
	book = null
	book_page = 0
	last_page = -1
	GameManager.current_state = GameManager.GameState.PLAYING
	if texture_rect.texture:
		texture_rect.texture = null
		SfxManager.play_sound(SfxManager.OPEN_BOOK, audio_delay)
		SfxManager.sound_bus_1.volume_db = -14.0
		SfxManager.sound_bus_2.volume_db = -14.0
		SfxManager.sound_bus_3.volume_db = -14.0

var last_page : int = -1

func show_book_page(_page : int):
	if last_page == _page:
		last_page = -1
		return
	last_page = _page
	# If requesting the next page after book ends, hide the text
	if book:
		if _page > book.pages.size() -1:
			hide_text.call_deferred()
			return

		book_page = _page
		page_label.text = str(_page + 1) + "/" + str(book.pages.size())
		show_page(book.pages[book_page])
	else:
		hide_text()


func _on_previous_button_pressed() -> void:
	if !book:
		hide_text()
	book_page -= 1
	if book_page < 0:
		book_page = 0
		return
	show_book_page(book_page)


func _on_next_button_pressed() -> void:
	if !book:
		hide_text()
	book_page += 1
	show_book_page(book_page)


func _on_back_button_pressed():
	book_page = 0
	hide_text()
