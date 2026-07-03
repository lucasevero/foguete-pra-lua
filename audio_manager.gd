extends Node
## Autoload AudioManager. Área: integration/áudio.
## Escuta os signals do GameEvents e toca sons — ninguém mexe no código de
## outra área, só emitem signals. Solte novos arquivos em assets/audio/ e
## conecte aqui conforme forem chegando (ver Notion "Sons a Produzir").

const MUSIC_THEME := preload("res://assets/audio/music/theme_main.mp3")
const SFX_THRUST := preload("res://assets/audio/sfx/thrust_loop.wav")

var _music: AudioStreamPlayer
var _thrust: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # continua tocando na pausa/game over

	_music = AudioStreamPlayer.new()
	_music.stream = MUSIC_THEME
	_music.volume_db = -8.0
	if _music.stream is AudioStreamMP3:
		_music.stream.loop = true
	add_child(_music)
	_music.play()

	_thrust = AudioStreamPlayer.new()
	_thrust.stream = SFX_THRUST
	_thrust.volume_db = -6.0
	add_child(_thrust)

	GameEvents.thrust_changed.connect(_on_thrust_changed)
	GameEvents.game_over.connect(_on_game_over)
	# TODO: conectar fuel_collected / asteroid_hit / player_died / game_over(win)
	#       aos SFX quando os arquivos chegarem (ver Notion).

func _on_thrust_changed(active: bool) -> void:
	if active:
		if not _thrust.playing:
			_thrust.play()
	else:
		_thrust.stop()

func _on_game_over(_won: bool) -> void:
	_thrust.stop()
