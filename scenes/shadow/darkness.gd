class_name Darkness
extends Area3D

@export var MAX_COOLDOWN : float = 10.0
@export var MAX_HP : int = 100
@export var HP_DOWN_TICK : float = 10.

var shadow_present : bool
var cooldown : float = 0.0
var flare_near : bool
var hp : int:
	set(value):
		hp = value
		if hp <= 0:
			remove_shadow()

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var area: CollisionShape3D = $CollisionShape3D
@onready var shadow: Shadow = $Shadow
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _ready() -> void:
	hp = MAX_HP
	area.body_entered.connect(_on_body_entered)
	area.area_entered.connect(_on_area_entered)
	GameManager.tick_countdown.connect(_on_tick_countdown)
	spawn_shadow() # TODO: remove


func _process(delta: float) -> void:
	if flare_near:
		hp -= HP_DOWN_TICK * delta


func _on_tick_countdown() -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body is Flare and shadow_present:
		if body.active:
			print("Flare inside")
			flare_near = true
	if body is Player and shadow_present:
		print("Player inside")
		# TODO: VFX and SFX
		pass


func _on_area_entered(_area: Area3D) -> void:
	if _area.is_in_group("flare"):
		if _area.active:
			print("Flare near")
			flare_near = true


func _on_area_exited(_area: Area3D) -> void:
	if _area.is_in_group("flare"):
		print("Flare left")
		flare_near = false


var tween : Tween        
func spawn_shadow() -> void:
	shadow_present = true
	mesh.show() # TODO: VFX
	shadow.visible = true


func remove_shadow() -> void:
	cooldown = MAX_COOLDOWN
	shadow_present = false
	mesh.hide() # TODO: VFX
	shadow.visible = false
	
