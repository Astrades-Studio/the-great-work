@tool
class_name ShadowOrbit
extends Marker3D

@export_group("Constants")
@export var INITIAL_DISTANCE: float = -10.0
@export var STEP_DISTANCE: float = 1.0
@export var MAX_ROTATION_SPEED: float = 0.2
@export var MIN_ROTATION_SPEED: float = 0.001
@export var MAX_RADIAN_AMPLITUDE: float = 1.0
@export var COOLDOWN_TIME: float = 30.0
@export var VISIBILITY_DURATION: float = 5.0

@export_group("Rotation")
@export var active: bool
@export var _rotate_y: bool = true
@export var _rotate_x: bool = true

var rotation_speed: float = 0.1
var distance_to_player : float
var player_ref : Player

@onready var shadow_distance_marker: Marker3D = $ShadowDistance
@onready var skull_mesh: MeshInstance3D = %Skull

var timer : Timer

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

		State.PURSUING:
			await _appear_gradually()
			_get_closer(STEP_DISTANCE)

		State.ORBITING:
			await _appear_gradually()

		State.RETREATING:
			await _appear_gradually()
			_get_closer(INITIAL_DISTANCE)



signal _appeared


func _ready() -> void:
	_appeared.connect(_on_appeared)
	GameManager.tick_countdown.connect(_on_tick_countdown)
	active = true
	# TODO: write initialize code
	# TODO: write flare reset code
	# TODO: add cooldown after flare use
	# TODO: reduce amount of flares available?

func _on_tick_countdown():
	if current_state == State.WAITING:
		change_state_to(State.PURSUING)


func _on_appeared() -> void:
	await get_tree().create_timer(VISIBILITY_DURATION).timeout
	change_state_to(State.WAITING)


func _process(delta: float) -> void:
	if !active:
		return

	if _rotate_y:
		# rotate on the y axis
		rotate_y(rotation_speed * delta)
	if _rotate_x:
		var h_rotation = rotation_speed
		# rotate on the x axis with a random amplitude
		if global_rotation.x > MAX_RADIAN_AMPLITUDE:
			h_rotation = -h_rotation
		rotate_x(h_rotation * delta)

# Positive values go closer to the player, while negative values go further
func _get_closer(step : float = STEP_DISTANCE):
	var current_distance := shadow_distance_marker.position.z
	var new_distance := current_distance + step

	# if the new_distance is greater than the initial position, then go back to initial position
	if new_distance < INITIAL_DISTANCE:
		new_distance = INITIAL_DISTANCE


	var tween: Tween = get_tree().create_tween()
	tween.tween_property(shadow_distance_marker, "position:z", new_distance, 1.0)

	_change_movement_pattern()


func _change_movement_pattern() -> void:
	_rotate_x = not _rotate_x
	_randomize_speed()


# Randomize speed
func _randomize_speed() -> void:
	rotation_speed = randf_range(MIN_ROTATION_SPEED, MAX_ROTATION_SPEED)


func _appear_gradually() -> void:
	skull_mesh.visible = true
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(skull_mesh.mesh.material, "albedo_color", Color.WHITE, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	await tween.finished
	_appeared.emit()


func _disappear_gradually() -> void:
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(skull_mesh.mesh.material, "albedo_color", Color.TRANSPARENT, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	await tween.finished
	skull_mesh.visible = false


# Kill the player if too close
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		GameManager.game_over.emit()
