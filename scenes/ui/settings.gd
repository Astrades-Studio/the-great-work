extends CenterContainer

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var settings_container: CenterContainer = $"."

@onready var mute_check_box: CheckBox = %MuteCheckBox
@onready var fullscreen_checkbox: CheckBox = %FullscreenCheckbox
@onready var back_button: Button = %BackButton

var master_bus : = AudioServer.get_bus_index("Master")
var music_bus : = AudioServer.get_bus_index("Music")
var sfx_bus : = AudioServer.get_bus_index("SFX")

var master_volume : float
var music_volume : float
var sfx_volume : float

func _ready():
	master_volume = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	music_volume = db_to_linear(AudioServer.get_bus_volume_db(music_bus))
	sfx_volume = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus))
	
	mute_check_box.button_pressed = AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	
	mute_check_box.toggled.connect(_on_mute_check_box_toggled)
	master_slider.value_changed.connect(_on_master_slider_value_changed)
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_checkbox_toggled)

func _on_mute_check_box_toggled(button_pressed):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), button_pressed)

func _on_master_slider_value_changed(value):
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))

func _on_music_slider_value_changed(value):
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))

func _on_sfx_slider_value_changed(value):
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))

func _on_fullscreen_checkbox_toggled(button_pressed):
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_button_pressed() -> void:
	settings_container.hide()
