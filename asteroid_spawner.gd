extends Node2D
## DONO: Dev B — gera meteoros. Eles só começam quando o CÉU COMEÇA A ESCURECER
## (altitude), e a dificuldade sobe COM O TEMPO: mais meteoros e maiores.
## No fundo claro (perto do chão) NÃO nasce nada. Sem mudança de contrato:
## escuta GameEvents.altitude_changed (0=chão claro, 1=Lua) e game_started.

@export var asteroid_scene: PackedScene
@export var dark_start_ratio: float = 0.30   # altitude em que o céu escurece → meteoros começam
@export var base_interval: float = 2.2       # s entre spawns no começo (poucos)
@export var min_interval: float = 0.35       # s entre spawns na dificuldade máxima
@export var ramp_time: float = 90.0          # s (de céu escuro) até a dificuldade ~máxima
@export var spawn_margin: float = 60.0       # quão acima do topo da tela nasce

# 3 tamanhos: textura + escala (a colisão escala junto com o nó).
const VARIANTS := [
	{"tex": preload("res://assets/sprites/obstacles/asteroid_01.png"), "scale": 0.5},  # pequeno
	{"tex": preload("res://assets/sprites/obstacles/asteroid_02.png"), "scale": 0.7},  # médio
	{"tex": preload("res://assets/sprites/obstacles/asteroid_03.png"), "scale": 1.0},  # grande
]

var _player: Node2D
var _ratio: float = 0.0        # altitude atual (0..1)
var _elapsed: float = 0.0      # tempo desde que os meteoros começaram
var _timer: float = 0.0        # conta regressiva até o próximo spawn

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	GameEvents.altitude_changed.connect(func(r: float) -> void: _ratio = r)
	GameEvents.game_started.connect(_reset)
	_reset()

func _reset() -> void:
	_ratio = 0.0
	_elapsed = 0.0
	_timer = base_interval

func _process(delta: float) -> void:
	if asteroid_scene == null or _player == null:
		return
	if _ratio < dark_start_ratio:
		return                                          # céu ainda claro → sem meteoros
	_elapsed += delta
	var diff := clampf(_elapsed / ramp_time, 0.0, 1.0)  # 0 no começo → 1 conforme o tempo passa
	var interval := lerpf(base_interval, min_interval, diff)
	_timer -= delta
	while _timer <= 0.0:
		_spawn(diff)
		_timer += interval

func _spawn(diff: float) -> void:
	var vp := get_viewport()
	var screen_size := vp.get_visible_rect().size
	var to_world := vp.get_canvas_transform().affine_inverse()  # tela -> mundo
	var sx := randf() * screen_size.x
	var a := asteroid_scene.instantiate()
	var v: Dictionary = _pick_variant(diff)
	a.get_node("Sprite").texture = v["tex"]
	a.scale = Vector2(v["scale"], v["scale"])   # escala colisão junto
	add_child(a)
	a.global_position = to_world * Vector2(sx, -spawn_margin)  # acima do topo

func _pick_variant(diff: float) -> Dictionary:
	# pequeno domina cedo; médio cresce; grande é quadrático (só aparece bem mais tarde).
	var weights := [
		maxf(0.05, 1.0 - diff * 1.1),   # pequeno
		0.25 + diff * 0.5,              # médio
		diff * diff,                    # grande
	]
	var total: float = weights[0] + weights[1] + weights[2]
	var pick := randf() * total
	var acc := 0.0
	for i in range(VARIANTS.size()):
		acc += weights[i]
		if pick <= acc:
			return VARIANTS[i]
	return VARIANTS[0]
