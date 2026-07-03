extends Node2D
## DONO: Dev C — gera pickups de combustível.

@export var fuel_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var spawn_width: float = 1152.0

var _timer: float = 0.0

func _process(delta: float) -> void:
	if fuel_scene == null:
		return
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		var f := fuel_scene.instantiate()
		add_child(f)
		f.position = Vector2(randf() * spawn_width, -50.0)
