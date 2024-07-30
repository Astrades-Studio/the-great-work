extends Marker3D

@onready var running_crawl_imported: Node3D = $"Running Crawl_Imported"
@onready var animation_player: AnimationPlayer = $"Running Crawl_Imported/AnimationPlayer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	running_crawl_imported.hide()
	GameManager.shadow_crawl_trigger.connect(_on_player_walk_by)
	

func _on_player_walk_by():
	running_crawl_imported.show()
	animation_player.play("Crawl_downstairs")
