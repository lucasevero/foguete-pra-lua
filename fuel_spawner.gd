extends Node2D
## DONO: Dev C — gera pickups de combustível POR DISTÂNCIA de subida (densidade
## constante por trecho). Nascem acima do topo visível; caem.

@export var fuel_scene: PackedScene
@export var spawn_distance: float = 550.0   # px de subida entre pickups (raro que asteroide)
@export var distance_jitter: float = 0.4
@export var spawn_margin: float = 60.0

var _player: Node2D
var _next_spawn_y: float

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_next_spawn_y = _player.global_position.y - spawn_distance

func _process(_delta: float) -> void:
	if fuel_scene == null or _player == null:
		return
	while _player.global_position.y <= _next_spawn_y:
		_spawn()
		var step := spawn_distance * (1.0 + randf_range(-distance_jitter, distance_jitter))
		_next_spawn_y -= maxf(40.0, step)

func _spawn() -> void:
	var vp := get_viewport()
	var screen_size := vp.get_visible_rect().size
	var to_world := vp.get_canvas_transform().affine_inverse()  # tela -> mundo
	var sx := randf() * screen_size.x
	var f := fuel_scene.instantiate()
	add_child(f)
	f.global_position = to_world * Vector2(sx, -spawn_margin)   # acima do topo
