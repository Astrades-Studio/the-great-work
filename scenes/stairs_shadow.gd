extends Marker3D

@onready var shadow: Shadow = $Shadow
@onready var animation_player: AnimationPlayer = $AnimationPlayer
#@onready var static_body_3d: StaticBody3D = $StaticBody3D
@onready var area_3d: Area3D = $Area3D


var flare_reference: Flare

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide()
	GameManager.flare_created.connect(_on_flare_created)
	area_3d.body_entered.connect(_on_body_entered)


func _on_flare_created():
	self.show()


func _on_body_entered(body: Node3D) -> void:
	if !GameManager.flare_already_made:
		return
	if GameManager.shadow_dispelled:
		return
	if body is Player:
		if is_instance_valid(body.ingredient_in_hand):
			if body.ingredient_in_hand is Flare:
				flare_reference = body.ingredient_in_hand


func _process(_delta: float) -> void:
	if GameManager.shadow_dispelled:
		return
	if !is_instance_valid(flare_reference):
		return
	if flare_reference.active:
		dispel_shadow()


func dispel_shadow() -> void:
	GameManager.shadow_dispelled = true
	# animation_player.play("dispel")
	# await animation_player.animation_finished
	DialogManager.create_dialog_piece("I managed to banish this shadow")
	hide()
