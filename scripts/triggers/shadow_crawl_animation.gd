extends Marker3D

@onready var running_crawl_imported: Node3D = $"Running Crawl_Imported"
@onready var animation_player: AnimationPlayer = $"Running Crawl_Imported/AnimationPlayer"

const SOUND := preload("res://assets/sounds/sfx/shadow/shadow_crawl.mp3")

var played : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	running_crawl_imported.hide()
	GameManager.shadow_crawl_trigger.connect(_on_player_walk_by)
	

func _on_player_walk_by():
	if played:
		return
	running_crawl_imported.show()
	animation_player.play("Crawl_downstairs")
	SfxManager.play_sound(SOUND)
	played = true
