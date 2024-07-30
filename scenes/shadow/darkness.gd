class_name Darkness
extends Area3D

@export var MAX_COOLDOWN : float = 30.0
@export var MAX_HP : int = 3
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
@onready var darkness_fx_intensity = darkness_fx.amount_ratio
@onready var darkness_light: OmniLight3D = $DarknessLight

signal shadow_banished(Shadow)

func _ready() -> void:
	hide()
	hp = MAX_HP
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	GameManager.tick_countdown.connect(_on_tick_countdown)
	GameManager.shadow_spawn_points.append(self)
	shadow_banished.connect(GameManager.on_shadow_removed.bind(shadow))


func _process(delta: float) -> void:
	if flare_reference:
		if flare_reference.active and shadow_present:
			hp -= delta
			print("HP: " + str(hp))
	if !shadow_present and cooldown >= 0.:
		cooldown -= delta


func _on_tick_countdown() -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body is Flare:
		if is_instance_valid(body):
			flare_reference = body
	if body is Player:
		if body.ingredient_in_hand is Flare:
			flare_reference = body.ingredient_in_hand
		if shadow_present:
			body.gas_lamp.disabled = true
			shadow.turn_invisible()
			body.panic_effects.increase_agitation()


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		body.gas_lamp.disabled = false
		shadow.reset_invisibility()
		if is_instance_valid(body.ingredient_in_hand):
			if body.ingredient_in_hand is Flare:
				flare_reference = null
		await get_tree().create_timer(2).timeout			
		body.panic_effects.decrease_agitation()

var tween : Tween        
func spawn_shadow() -> bool:
	if shadow_present:
		return false
	if cooldown >= 0.:
		return false
	hp = MAX_HP
	shadow_present = true
	# TODO: VFX
	show()
	#shadow.visible = true
	#darkness_fx.emitting = true
	#darkness_light.visible = true
	return true


func remove_shadow() -> void:
	shadow_banished.emit()
	cooldown = MAX_COOLDOWN
	shadow_present = false
	# TODO: VFX
	shadow.visible = false
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self, "darkness_fx_intensity",0.0,3.0)
