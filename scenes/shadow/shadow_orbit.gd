@tool
class_name ShadowOrbit
extends Marker3D

const BURN_FX = preload("res://scenes/shadow/skull_burn_fx.tres")
const DARK_FX = preload("res://scenes/shadow/skull_dark_fx.tres")

@export_group("Constants")
@export var MAX_DISTANCE: float = 5.0
@export var STEP_DISTANCE: float = 1.0
@export var MAX_ROTATION_SPEED: float = 0.2
@export var MIN_ROTATION_SPEED: float = 0.01
@export var MAX_OFFSET : float = 2.0
@export var FREQUENCY : float = 1.0

@export var VISIBILITY_COOLDOWN: float = 10.0
@export var VISIBILITY_DURATION: float = 5.0
@export var RETREAT_COOLDOWN: float = 30.0

@export_group("Rotation")
@export var active: bool
@export var _rotate_y: bool = true
@export var offset_active := false
@export var getting_closer := false
@export var distance := MAX_DISTANCE

# Rotation parameters
var rotation_speed: float = 0.1
var offset : float = 0.0
var time := 0.0

# Flare parameters
var flare_references : Array[Flare] = []

@onready var skull_position: Marker3D = $ShadowDistance
@onready var skull_mesh: MeshInstance3D = %Skull
@onready var skull_approach_sound: AudioStreamPlayer3D = %SkullApproachSound
@onready var skull_appear_sound: AudioStreamPlayer3D = %SkullAppearSound
@onready var shaker_component: ShakerComponent3D = $ShadowDistance/ShakerComponent3D

enum State {
	WAITING,
	PURSUING,
	ORBITING,
	RETREATING
}

var current_state : State = State.WAITING: set = change_state_to


func change_state_to(state : State) -> void:
	current_state = state
	match state:
		State.WAITING:
			print("Shadow waiting")
			await _disappear_gradually()
			_reset_appear_timer()

		State.PURSUING:
			print("Shadow pursuing")
			await _appear_gradually()
			skull_approach_sound.play()
			await set_distance(distance - STEP_DISTANCE)
			# await _change_distance_by(STEP_DISTANCE)
			change_state_to(State.WAITING)

		State.ORBITING:
			print("Shadow orbiting")
			await _appear_gradually()
			change_state_to(State.WAITING)

		State.RETREATING:
			print("Shadow retreating")
			await _appear_gradually()
			_change_fx_to(BURN_FX)
			skull_appear_sound.play()
			await set_distance(MAX_DISTANCE)
			_change_fx_to(DARK_FX)
			retreated.emit()
			# await _change_distance_by(MAX_DISTANCE)
			await get_tree().create_timer(RETREAT_COOLDOWN).timeout
			change_state_to(State.WAITING)


signal appeared
signal disappeared
signal retreated


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	#appeared.connect(_on_appeared)
	GameManager.game_started.connect(start_pursuing)
	GameManager.tick_countdown.connect(_on_tick_countdown)

	# TODO: write flare reset code
	# TODO: add cooldown after flare use

	_set_up_initial_conditions()


func set_distance(value):
	distance = clamp(value, 0.0, MAX_DISTANCE)
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(skull_position, "position:z", distance, 0.5)
	await tween.finished


func _reset_appear_timer() -> void:
	await get_tree().create_timer(VISIBILITY_COOLDOWN).timeout
	if current_state == State.WAITING:
		current_state = State.ORBITING


func _set_up_initial_conditions() -> void:
	active = false
	hide()
	current_state = State.WAITING
	await set_distance(MAX_DISTANCE)


func start_pursuing() -> void:
	active = true
	show()
	current_state = State.PURSUING


func _on_tick_countdown():
	if current_state == State.WAITING or current_state == State.ORBITING:
		change_state_to(State.PURSUING)


# func _on_appeared() -> void:
# 	await get_tree().create_timer(VISIBILITY_DURATION).timeout
	#change_state_to(State.WAITING)


func _process(delta: float) -> void:
	if !active:
		return

	if current_state != State.RETREATING and !Engine.is_editor_hint():
		if flare_references.size() > 0:
			for flare in flare_references:
				if flare.active:
					change_state_to(State.RETREATING)
					break

	# change global position by offset
	if offset_active:
		time += delta
		offset = sin(time * FREQUENCY) * MAX_OFFSET
		skull_position.position.y = offset

	# rotate on the y axis
	if _rotate_y:
		rotate_y(rotation_speed * delta)

	# change shaker intensity by distance, the closer to the player, the closer to 0 intensity
	var intensity = remap(distance, 0.0, MAX_DISTANCE, 0.0, 1.0)
	shaker_component.intensity = intensity



# # Positive values go closer to the player, while negative values go further
# func _change_distance_by(step : float = STEP_DISTANCE):
# 	var current_distance := skull_position.position.z
# 	var new_distance := current_distance + step

# 	# if the new_distance is greater than the initial position, then go back to initial position
# 	if new_distance < MAX_DISTANCE:
# 		new_distance = MAX_DISTANCE

# 	var tween: Tween = get_tree().create_tween()
# 	tween.tween_property(skull_position, "position:z", new_distance, 1.0)
# 	await tween.finished


# func _change_movement_pattern() -> void:
# 	_rotate_x = not _rotate_x
# 	_randomize_speed()
# 	_can_change_direction = false
# 	get_tree().create_timer(2.0).timeout.connect(func(): _can_change_direction = true)

# 	print("Shadow movement pattern changed")



# Randomize speed
func _randomize_speed() -> void:
	rotation_speed = randf_range(MIN_ROTATION_SPEED, MAX_ROTATION_SPEED)


func _appear_gradually() -> void:
	if skull_mesh.visible:
		print("Skull already visible")
		return

	skull_mesh.visible = true
	skull_appear_sound.play()
	var dark_fx : GPUParticles3D = skull_mesh.get_node("DarkFX")
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(skull_mesh.mesh.material, "albedo_color", Color.WHITE, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	tween.parallel().tween_property(dark_fx.draw_pass_1.material, "albedo_color", Color.BLACK, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	await tween.finished
	appeared.emit()


func _disappear_gradually() -> void:
	var tween : Tween = get_tree().create_tween()
	var dark_fx : GPUParticles3D = skull_mesh.get_node("DarkFX")
	tween.tween_property(skull_mesh.mesh.material, "albedo_color", Color.TRANSPARENT, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	tween.parallel().tween_property(dark_fx.draw_pass_1.material, "albedo_color", Color.TRANSPARENT, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	await tween.finished
	disappeared.emit()
	skull_mesh.visible = false
	get_tree().create_timer(VISIBILITY_COOLDOWN).timeout.connect(_appear_gradually)


func _change_fx_to(fx : Material) -> void:
	var dark_fx : GPUParticles3D = skull_mesh.get_node("DarkFX")
	dark_fx.draw_pass_1.material = fx


# Kill the player if too close
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		GameManager.game_over.emit()


func _on_hurtbox_body_entered(body: Node3D) -> void:
	if body is Flare:
		flare_references.append(body)


func _on_hurtbox_body_exited(body: Node3D) -> void:
	if body is Flare:
		flare_references.erase(body)
