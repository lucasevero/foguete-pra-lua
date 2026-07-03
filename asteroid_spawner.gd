extends Node2D
## DONO: Dev B — gera asteroides POR DISTÂNCIA de subida (densidade constante por
## trecho do mapa, imune à velocidade). Nascem acima do topo visível; caem.

@export var asteroid_scene: PackedScene
@export var spawn_distance: float = 220.0   # px de subida entre spawns
@export var distance_jitter: float = 0.4    # variação aleatória (0 = grade perfeita)
@export var spawn_margin: float = 60.0      # quão acima do topo da tela nasce

var _player: Node2D
var _next_spawn_y: float

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_next_spawn_y = _player.global_position.y - spawn_distance

func _process(_delta: float) -> void:
	# TODO(Dev B): variar spawn_distance por altitude p/ curva de dificuldade
	if asteroid_scene == null or _player == null:
		return
	# subir = y diminui. spawna cada vez que o player cruza o próximo marco.
	while _player.global_position.y <= _next_spawn_y:
		_spawn()
		var step := spawn_distance * (1.0 + randf_range(-distance_jitter, distance_jitter))
		_next_spawn_y -= maxf(40.0, step)

func _spawn() -> void:
	var vp := get_viewport()
	var screen_size := vp.get_visible_rect().size
	var to_world := vp.get_canvas_transform().affine_inverse()  # tela -> mundo
	var sx := randf() * screen_size.x
	var a := asteroid_scene.instantiate()
	add_child(a)
	a.global_position = to_world * Vector2(sx, -spawn_margin)  # acima do topo
