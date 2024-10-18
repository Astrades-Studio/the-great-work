@tool
class_name ShadowOrbit
extends Marker3D

@export_group("Constants")
@export var INITIAL_DISTANCE: float = -10.0
@export var STEP_DISTANCE: float = 1.0
@export var MAX_ROTATION_SPEED: float = 0.2
@export var MIN_ROTATION_SPEED: float = 0.01
@export var MAX_OFFSET : float = 2.0
@export var FREQUENCY : float = 1.0

@export var VISIBILITY_COOLDOWN: float = 10.0
@export var VISIBILITY_DURATION: float = 5.0

@export_group("Rotation")
@export var active: bool
@export var _rotate_y: bool = true

@export var pivot_point := Node3D


var rotation_speed: float = 0.1
var offset : float = 0.0

@onready var shadow_distance_marker: Marker3D = $ShadowDistance
@onready var skull_mesh: MeshInstance3D = %Skull
@onready var skull_approach_sound: AudioStreamPlayer3D = %SkullApproachSound
@onready var skull_appear_sound: AudioStreamPlayer3D = %SkullAppearSound


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
			await _disappear_gradually()
			print("Shadow waiting")

		State.PURSUING:
			await _appear_gradually()
			_change_distance_by(STEP_DISTANCE)
			print("Shadow pursuing")

		State.ORBITING:
			await _appear_gradually()
			print("Shadow orbiting")

		State.RETREATING:
			await _appear_gradually()
			_change_distance_by(INITIAL_DISTANCE)
			print("Shadow retreating")



signal _appeared


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_appeared.connect(_on_appeared)
	GameManager.tick_countdown.connect(_on_tick_countdown)
	active = true
	# TODO: write initialize code
	# TODO: write flare reset code
	# TODO: add cooldown after flare use
	# TODO: reduce amount of flares available?

func _on_tick_countdown():
	if current_state == State.WAITING:
		skull_approach_sound.play()
		change_state_to(State.PURSUING)


func _on_appeared() -> void:
	await get_tree().create_timer(VISIBILITY_DURATION).timeout
	change_state_to(State.WAITING)

var time := 0.0
@export var offset_active := false

func _process(delta: float) -> void:
	if !active:
		return

	# change global position by offset
	if offset_active:
		time += delta
		offset = sin(time * FREQUENCY) * MAX_OFFSET
		shadow_distance_marker.position.y = offset
	# rotate on the y axis
	if _rotate_y:
		rotate_y(rotation_speed * delta)


# Positive values go closer to the player, while negative values go further
func _change_distance_by(step : float = STEP_DISTANCE):
	var current_distance := shadow_distance_marker.position.z
	var new_distance := current_distance + step

	# if the new_distance is greater than the initial position, then go back to initial position
	if new_distance < INITIAL_DISTANCE:
		new_distance = INITIAL_DISTANCE


	var tween: Tween = get_tree().create_tween()
	tween.tween_property(shadow_distance_marker, "position:z", new_distance, 1.0)




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
		print("Skull already appeared")
		return

	skull_mesh.visible = true
	skull_appear_sound.play()
	var dark_fx : GPUParticles3D = skull_mesh.get_node("DarkFX")
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(skull_mesh.mesh.material, "albedo_color", Color.WHITE, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	tween.parallel().tween_property(dark_fx.draw_pass_1.material, "albedo_color", Color.BLACK, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	await tween.finished
	_appeared.emit()


func _disappear_gradually() -> void:
	var tween : Tween = get_tree().create_tween()
	var dark_fx : GPUParticles3D = skull_mesh.get_node("DarkFX")
	tween.tween_property(skull_mesh.mesh.material, "albedo_color", Color.TRANSPARENT, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	tween.parallel().tween_property(dark_fx.draw_pass_1.material, "albedo_color", Color.TRANSPARENT, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	await tween.finished
	skull_mesh.visible = false
	get_tree().create_timer(VISIBILITY_COOLDOWN).timeout.connect(_appear_gradually)


# Kill the player if too close
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		GameManager.game_over.emit()
