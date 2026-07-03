extends Node2D
## DONO: Dev B — obstáculos da BAIXA altitude (onde os asteroides NÃO nascem):
## pombos (diagonal, lentos) e zepelins (horizontal, um pouco mais rápidos).
## Só spawna enquanto o céu está claro (ratio < active_max_ratio); a partir daí
## os asteroides assumem. Sem mudança de contrato (escuta altitude_changed/game_started).

@export var pigeon_scene: PackedScene
@export var zeppelin_scene: PackedScene
@export var active_max_ratio: float = 0.30   # deve casar com dark_start_ratio do asteroid_spawner
@export var pigeon_interval: float = 2.0
@export var zeppelin_interval: float = 4.5
@export var pigeon_speed: float = 90.0       # lento
@export var zeppelin_speed: float = 160.0    # um pouco mais rápido

var _player: Node2D
var _ratio: float = 0.0
var _pt: float = 0.0
var _zt: float = 0.0

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	GameEvents.altitude_changed.connect(func(r: float) -> void: _ratio = r)
	GameEvents.game_started.connect(_reset)
	_reset()

func _reset() -> void:
	_ratio = 0.0
	_pt = pigeon_interval
	_zt = zeppelin_interval

func _process(delta: float) -> void:
	if pigeon_scene == null or _player == null:
		return
	if _ratio >= active_max_ratio:
		return                              # céu escuro → asteroides assumem
	_pt -= delta
	if _pt <= 0.0:
		_pt = pigeon_interval
		_spawn_pigeon()
	_zt -= delta
	if _zt <= 0.0:
		_zt = zeppelin_interval
		_spawn_zeppelin()

func _spawn_pigeon() -> void:
	var vp := get_viewport()
	var sz := vp.get_visible_rect().size
	var to_world := vp.get_canvas_transform().affine_inverse()
	var p := pigeon_scene.instantiate()
	p.velocity = Vector2(pigeon_speed * 0.8, pigeon_speed * 0.6)         # diagonal lenta, sempre p/ direita
	add_child(p)
	p.global_position = to_world * Vector2(randf_range(-40.0, sz.x * 0.3), -60.0)  # nasce à esquerda/topo

func _spawn_zeppelin() -> void:
	var vp := get_viewport()
	var sz := vp.get_visible_rect().size
	var to_world := vp.get_canvas_transform().affine_inverse()
	var sy := randf_range(120.0, sz.y * 0.5)                            # banda superior da tela
	var z := zeppelin_scene.instantiate()
	z.velocity = Vector2(zeppelin_speed, 0.0)                           # sempre esquerda -> direita
	add_child(z)
	z.global_position = to_world * Vector2(-120.0, sy)                  # nasce fora, à esquerda
