extends CenterContainer

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var settings_container: CenterContainer = $"."

@onready var mute_button: Button = %MuteButton
@onready var fullscreen_button: Button = %FullscreenButton
@onready var retro_filter: Button = %RetroFilter

@onready var fov_slider: HSlider = %FOVSlider
@onready var brightness_slider: HSlider = %BrightnessSlider
@onready var sensitivity_slider: HSlider = %SensitivitySlider


@onready var back_button: Button = %BackButton

var master_bus : = AudioServer.get_bus_index("Master")
var music_bus : = AudioServer.get_bus_index("Music")
var sfx_bus : = AudioServer.get_bus_index("SFX")

var master_volume : float
var music_volume : float
var sfx_volume : float

func _ready():
	connect_signals()
	set_current_values()


func set_current_values():
	master_volume = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	music_volume = db_to_linear(AudioServer.get_bus_volume_db(music_bus))
	sfx_volume = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus))

	mute_button.button_pressed = AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	fullscreen_button.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or \
	DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	retro_filter.button_pressed = GameManager.retro_filter

	sensitivity_slider.value = remap(GameManager.mouse_sensitivity, 0.01, 0.2, 0, 1)
	fov_slider.value = remap(GameManager.fov_value, 60, 90, 0, 1)
	if retro_filter:
		brightness_slider.value = clamp(remap(GameManager.brightness, 2.0, 3.8, 0, 1), 0, 1)
	else:
		brightness_slider.value = clamp(remap(GameManager.brightness, 1.0, 2.0, 0, 1), 0, 1)


func connect_signals():
	mute_button.toggled.connect(_on_mute_check_box_toggled)
	master_slider.value_changed.connect(_on_master_slider_value_changed)
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	fullscreen_button.toggled.connect(_on_fullscreen_checkbox_toggled)
	fov_slider.value_changed.connect(_on_fov_slider_value_changed)
	brightness_slider.value_changed.connect(_on_brightness_slider_value_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_slider_value_changed)
	retro_filter.toggled.connect(_on_retro_filter_toggled)

func _on_retro_filter_toggled(button_pressed):
	GameManager.retro_filter = button_pressed

func _on_fov_slider_value_changed(value):
	GameManager.fov_value = value

func _on_brightness_slider_value_changed(value):
	GameManager.brightness = value

func _on_sensitivity_slider_value_changed(value):
	GameManager.mouse_sensitivity = value

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
