extends Node
## DONO: Dev D — orquestra o jogo. Único que conhece o "todo".
## Estados: MENU (pausado) → JOGANDO → GAME OVER. Calcula altitude (Terra→Lua),
## tempo, inclinação e decide vitória/derrota.

@export var moon_altitude_offset: float = -10000.0  # sobe = y negativo. Lua fica X px acima do início
@export var time_limit: float = 180.0
@export var time_extra_powerup: float = 15.0        # +tempo do powerup

const PRICES := {"time": 5, "shield": 10, "fuel": 15, "weapon": 25}
const CUTSCENE := preload("res://cutscene_player.tscn")

## Pertence à CLASSE (não à instância), então SOBREVIVE ao reload_current_scene():
## no 1º boot mostra o menu; depois do REINICIAR já entra jogando (replay instantâneo).
static var _has_started_once: bool = false

var player: Node2D
var start_y: float = 0.0
var time_left: float
var running: bool = false
var coins: int = 0                                  # moedas da corrida (zeram no restart)

func _ready() -> void:
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.player_reached_moon.connect(_on_reached_moon)
	GameEvents.coin_collected.connect(_on_coin_collected)
	GameEvents.powerup_purchase_requested.connect(_on_purchase_requested)
	GameEvents.powerup_activated.connect(_on_powerup)
	GameEvents.start_requested.connect(_on_start_requested)
	GameEvents.menu_requested.connect(_on_menu_requested)
	player = get_node_or_null("../Player")
	if player:
		start_y = player.global_position.y
	time_left = time_limit
	running = false
	get_tree().paused = true            # congela tudo; a UI mostra o menu por cima
	if _has_started_once:
		_begin()                        # REINICIAR: joga direto (sem cutscene)

func _on_start_requested() -> void:    # Menu "JOGAR"
	_has_started_once = true
	_play_cutscene()

func _play_cutscene() -> void:
	# Só o JOGAR toca a cutscene (do menu), por cima e com a árvore pausada;
	# ao terminar (ou pular), _begin() despausa e começa a partida.
	# O REINICIAR NÃO passa por aqui (vai direto pro _begin no _ready).
	GameEvents.cutscene_started.emit()          # UI esconde o menu/HUD enquanto toca
	var cs: CutscenePlayer = CUTSCENE.instantiate()
	cs.layer = 100                              # por cima do menu/HUD/loja
	cs.process_mode = Node.PROCESS_MODE_ALWAYS  # roda mesmo com a árvore pausada
	add_child(cs)
	cs.finished.connect(func() -> void:
		cs.queue_free()
		_begin()
	, CONNECT_ONE_SHOT)
	cs.play(CutsceneIntro.build())

func _on_menu_requested() -> void:     # Game over "MENU": volta pro menu inicial
	_has_started_once = false           # zera pra NÃO fazer replay instantâneo no reload
	get_tree().paused = false
	get_tree().reload_current_scene()

func _begin() -> void:
	running = true
	time_left = time_limit
	get_tree().paused = false
	GameEvents.game_started.emit()      # UI esconde menu / mostra HUD; AudioManager (re)inicia a música
	GameEvents.time_changed.emit(time_left)
	GameEvents.coins_changed.emit(coins)

func _on_coin_collected(amount: int) -> void:
	coins += amount
	GameEvents.coins_changed.emit(coins)

func _on_purchase_requested(kind: String) -> void:
	var price: int = PRICES.get(kind, 0)
	if coins >= price:
		coins -= price
		GameEvents.coins_changed.emit(coins)
		GameEvents.powerup_activated.emit(kind)   # Player aplica; _on_powerup trata "time"

func _on_powerup(kind: String) -> void:
	if kind == "time":
		time_left += time_extra_powerup
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
		GameEvents.tilt_changed.emit(player.rotation)   # HUD: indicador de inclinação
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
	get_tree().paused = true         # congela o jogo (player, spawners, asteroides)
	if won:
		_play_final_cutscene()       # CENA 2; ao terminar, mostra o game over
	else:
		GameEvents.game_over.emit(false)   # UI mostra o botão REINICIAR

func _play_final_cutscene() -> void:
	# CENA 2 (a chegada) por cima da árvore pausada; ao terminar → game over (vitória).
	GameEvents.cutscene_started.emit()          # UI esconde o HUD enquanto toca
	var cs: CutscenePlayer = CUTSCENE.instantiate()
	cs.layer = 100
	cs.process_mode = Node.PROCESS_MODE_ALWAYS  # roda com a árvore pausada
	add_child(cs)
	cs.finished.connect(func() -> void:
		cs.queue_free()
		GameEvents.game_over.emit(true)         # mostra REINICIAR/menu
	, CONNECT_ONE_SHOT)
	cs.play(CutsceneFinal.build())
