extends StaticBody3D

@onready var fireplace_off: MeshInstance3D = $Fireplace_OFF
@onready var fireplace_on: MeshInstance3D = $Fireplace_ON
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fireplace_2: OmniLight3D = $Fireplace2
var on_active_fire: bool = false

func _ready():
	assert(self.has_user_signal("interacted"), "Fireplace has no interacted signal")
	self.connect("interacted", on_fireplace_use)

func on_fireplace_use():
	if on_active_fire:
		return
	
	GameManager.current_state = GameManager.GameState.STATIC
	on_active_fire = true
	SfxManager.play_sound(preload("res://assets/sounds/sfx/light_fireplace.mp3"), 0.0, -15.0)
	await get_tree().create_timer(2.84).timeout
	fireplace_off.hide()
	fireplace_on.show()
	animation_player.play("Emission")
	GameManager.current_state = GameManager.GameState.PLAYING
	
