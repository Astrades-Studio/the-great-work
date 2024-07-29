class_name Darkness
extends Area3D

@export var MAX_COOLDOWN : float = 30.0
@export var MAX_HP : int = 20
@export var HP_DOWN_TICK : float = 1.

var shadow_present : bool
var cooldown : float = 0.0
var flare_near : bool
var flare_reference : Flare
var hp : float:
	set(value):
		hp = value
		if hp <= 0:
			remove_shadow()

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var shadow: Shadow = $Shadow
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var darkness_fx: GPUParticles3D = $DarknessFX
@onready var darkness_light: OmniLight3D = $DarknessLight


func _ready() -> void:
	hp = MAX_HP
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	# self.area_entered.connect(_on_area_entered)
	# self.area_exited.connect(_on_area_exited)
	GameManager.tick_countdown.connect(_on_tick_countdown)
	GameManager.shadow_spawn_points.append(self)


func _process(delta: float) -> void:
	if flare_reference:
		if flare_reference.active and shadow_present:
			hp -= delta
			print(hp)
	if !shadow_present and cooldown >= 0.:
		cooldown -= delta


func _on_tick_countdown() -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body is Flare:
		flare_reference = body.ingredient_in_hand
	if body is Player:
		if body.ingredient_in_hand is Flare:
			flare_reference = body.ingredient_in_hand
		if shadow_present:
			body.gas_lamp.disabled = true
			shadow.turn_invisible()
			# TODO: VFX and SFX


func _on_body_exited(body: Node3D) -> void:
	if body is Flare:
		flare_reference = null
	if body is Player:
		body.gas_lamp.disabled = false
		shadow.reset_invisibility()
		if body.ingredient_in_hand is Flare:
			flare_reference = null


# func _on_area_entered(_area: Area3D) -> void:
# 	if _area.is_in_group("flare"):
# 		if _area.get_parent().active:
# 			print("Flare near")
# 			flare_near = true


# func _on_area_exited(_area: Area3D) -> void:
# 	if _area.is_in_group("flare"):
# 		print("Flare left")
# 		flare_near = false


var tween : Tween        
func spawn_shadow() -> bool:
	if shadow_present:
		return false
	if cooldown >= 0.:
		return false
	hp = MAX_HP
	shadow_present = true
	# TODO: VFX
	shadow.visible = true
	darkness_fx.emitting = true
	darkness_light.visible = true
	return true


func remove_shadow() -> void:
	cooldown = MAX_COOLDOWN
	shadow_present = false
	# TODO: VFX
	shadow.visible = false
	darkness_fx.emitting = false
	darkness_light.visible = false
