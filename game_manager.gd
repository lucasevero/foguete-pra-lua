extends Node
## DONO: Dev D — orquestra o jogo. Único que conhece o "todo".
## Calcula altitude (Terra->Lua), tempo, e decide vitória/derrota.

@export var moon_altitude_offset: float = -5000.0  # sobe = y negativo. Lua fica X px acima do início
@export var time_limit: float = 120.0

var player: Node2D
var start_y: float = 0.0
var time_left: float
var running: bool = false

func _ready() -> void:
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.player_reached_moon.connect(_on_reached_moon)
	player = get_node_or_null("../Player")
	if player:
		start_y = player.global_position.y
	time_left = time_limit
	running = true
	GameEvents.game_started.emit()
	GameEvents.time_changed.emit(time_left)

func _process(delta: float) -> void:
	if not running:
		return
	time_left -= delta
	GameEvents.time_changed.emit(time_left)
	if time_left <= 0.0:
		time_left = 0.0
		_end(false)
		return
	if player:
		var moon_y := start_y + moon_altitude_offset
		var ratio := inverse_lerp(start_y, moon_y, player.global_position.y)
		GameEvents.altitude_changed.emit(clampf(ratio, 0.0, 1.0))
		if player.global_position.y <= moon_y:
			GameEvents.player_reached_moon.emit()

func _on_player_died() -> void:
	_end(false)

func _on_reached_moon() -> void:
	_end(true)

func _end(won: bool) -> void:
	if not running:
		return
	running = false
	GameEvents.game_over.emit(won)   # UI mostra o botão REINICIAR (process_mode=ALWAYS)
	get_tree().paused = true         # congela o jogo (player, spawners, asteroides)
