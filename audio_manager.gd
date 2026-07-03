extends Node
## Autoload AudioManager. Área: integration/áudio.
## Escuta os signals do GameEvents e toca sons — ninguém mexe no código de
## outra área, só emitem signals. Solte novos arquivos em assets/audio/ e
## conecte aqui conforme forem chegando (ver Notion "Sons a Produzir").

const MUSIC_THEME := preload("res://assets/audio/music/theme_main.mp3")
const SFX_THRUST := preload("res://assets/audio/sfx/thrust_loop.wav")
const SFX_LIFTOFF := preload("res://assets/audio/sfx/liftoff.wav")
const SFX_PICKUP := preload("res://assets/audio/sfx/fuel_pickup.wav")
const SFX_CRASH_ASTEROID := preload("res://assets/audio/sfx/crash_asteroid.wav")
const SFX_CRASH_GROUND := preload("res://assets/audio/sfx/crash_ground.wav")
const SFX_LAND := preload("res://assets/audio/sfx/land_soft.wav")
const SFX_ALARM := preload("res://assets/audio/sfx/fuel_low.wav")
const SFX_WIN := preload("res://assets/audio/sfx/win.wav")
const SFX_GAME_OVER := preload("res://assets/audio/sfx/game_over.wav")
const SFX_UI_CLICK := preload("res://assets/audio/sfx/ui_click.wav")
const SFX_COIN := preload("res://assets/audio/sfx/coin.wav")
const SFX_COIN_BIG := preload("res://assets/audio/sfx/coin_big.wav")
# phone_ring.wav existe em assets/audio/sfx/ — a ser tocado pela cutscene (área Dev D)

const MUSIC_START := 10.0   # a faixa começa/reinicia aos 10s
const FUEL_LOW_RATIO := 0.25

var _music: AudioStreamPlayer
var _thrust: AudioStreamPlayer
var _liftoff: AudioStreamPlayer
var _pickup: AudioStreamPlayer
var _crash_ast: AudioStreamPlayer
var _crash_gnd: AudioStreamPlayer
var _land: AudioStreamPlayer
var _alarm: AudioStreamPlayer
var _win: AudioStreamPlayer
var _game_over: AudioStreamPlayer
var _ui_click: AudioStreamPlayer
var _coin: AudioStreamPlayer
var _coin_big: AudioStreamPlayer

var _fuel_low: bool = false
var _skip_ground_crash: bool = false   # evita som duplo quando morre por asteroide

func _make(stream: AudioStream, db: float = 0.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	add_child(p)
	return p

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # continua na pausa/game over

	_music = _make(MUSIC_THEME, -6.0)   # +25% volume vs -8 dB
	if _music.stream is AudioStreamMP3:
		_music.stream.loop = true
	# a música inicia/reinicia via _on_game_started (MUSIC_START), inclusive no restart

	_thrust = _make(SFX_THRUST, -6.0)
	_liftoff = _make(SFX_LIFTOFF, -3.0)
	_pickup = _make(SFX_PICKUP, -3.0)
	_crash_ast = _make(SFX_CRASH_ASTEROID, 0.0)
	_crash_gnd = _make(SFX_CRASH_GROUND, 0.0)
	_land = _make(SFX_LAND, -4.0)
	_alarm = _make(SFX_ALARM, -4.0)
	_win = _make(SFX_WIN, -2.0)
	_game_over = _make(SFX_GAME_OVER, -2.0)
	_ui_click = _make(SFX_UI_CLICK, -4.0)
	_coin = _make(SFX_COIN, -4.0)
	_coin_big = _make(SFX_COIN_BIG, -3.0)

	# O autoload persiste entre reloads da cena; a música só reinicia quando o
	# GameManager (re)emite game_started — inclusive no REINICIAR (reload_current_scene).
	GameEvents.game_started.connect(_on_game_started)
	GameEvents.menu_requested.connect(_on_menu_requested)
	GameEvents.thrust_changed.connect(_on_thrust_changed)
	GameEvents.lifted_off.connect(func(): _liftoff.play())
	GameEvents.landed_safely.connect(func(): _land.play())
	GameEvents.fuel_collected.connect(func(_a): _pickup.play())
	GameEvents.asteroid_hit.connect(_on_asteroid_hit)
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.fuel_changed.connect(_on_fuel_changed)
	GameEvents.game_over.connect(_on_game_over)
	GameEvents.coin_collected.connect(_on_coin_collected)

func _notification(what: int) -> void:
	# Silencia quando o app vai pro background / perde foco / tela desliga
	# (web e mobile) — senão a música continua tocando fora do app.
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			AudioServer.set_bus_mute(0, true)
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			AudioServer.set_bus_mute(0, false)

func _on_coin_collected(amount: int) -> void:
	if amount >= 5:
		_coin_big.play()
	else:
		_coin.play()

## Toca o clique de UI. Chamado por botões (ex: REINICIAR) — AudioManager é serviço global.
func play_ui_click() -> void:
	_ui_click.play()

func _on_game_started() -> void:
	_music.play(MUSIC_START)   # sempre do começo a cada (re)início de partida

func _on_menu_requested() -> void:
	_music.stop()              # menu inicial é silencioso; a música volta no próximo JOGAR
	_thrust.stop()

func _on_thrust_changed(active: bool) -> void:
	if active:
		if not _thrust.playing:
			_thrust.play()
	else:
		_thrust.stop()

func _on_asteroid_hit() -> void:
	_crash_ast.play()
	_skip_ground_crash = true   # o player_died seguinte não toca o crash de chão

func _on_player_died() -> void:
	if _skip_ground_crash:
		_skip_ground_crash = false
	else:
		_crash_gnd.play()

func _on_fuel_changed(current: float, maximum: float) -> void:
	var ratio := current / maximum if maximum > 0.0 else 0.0
	if ratio <= FUEL_LOW_RATIO and not _fuel_low:
		_fuel_low = true
		_alarm.play()
	elif ratio > FUEL_LOW_RATIO:
		_fuel_low = false

func _on_game_over(won: bool) -> void:
	_thrust.stop()
	if won:
		_win.play()
	else:
		_game_over.play()
