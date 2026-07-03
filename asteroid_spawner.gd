extends Node2D
## DONO: Dev B — gera asteroides no topo da tela.

@export var asteroid_scene: PackedScene
@export var spawn_interval: float = 1.5
@export var spawn_width: float = 1152.0

var _timer: float = 0.0

func _process(delta: float) -> void:
	# TODO(Dev B): aumentar dificuldade conforme sobe (ler GameEvents.altitude_changed)
	if asteroid_scene == null:
		return
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		var a := asteroid_scene.instantiate()
		add_child(a)
		a.position = Vector2(randf() * spawn_width, -50.0)
