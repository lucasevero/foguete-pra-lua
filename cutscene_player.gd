class_name CutscenePlayer
extends CanvasLayer
## Player de cutscene reutilizável e data-driven — layout cross-cut (mobile/portrait).
## Mostra o AMBIENTE do falante em tela cheia, cortando por beat. Emite `finished` no fim ou ao pular.
## Área: integration. Não conhece gameplay nem GameEvents — é pré-jogo/overlay genérico.
## Input touch-first: tocar avança; botões Atender/Pular; ui_accept/ui_cancel p/ desktop.

signal finished

## Se preenchido no inspector, auto-toca no _ready (útil pra testar a cena isolada).
@export var beats: Array[CutsceneBeat] = []

const CHARS_PER_SEC := 45.0
## Cores de placeholder por falante (enquanto não há retrato de arte real).
const SPEAKER_COLORS := {
	"CARLOS": Color(0.90, 0.45, 0.25),
	"GUS": Color(0.35, 0.70, 0.45),
	"VOCÊ": Color(0.45, 0.55, 0.90),
}
const DEFAULT_SPEAKER_COLOR := Color(0.5, 0.5, 0.5)

var _beats: Array[CutsceneBeat] = []
var _index: int = -1
var _typing: bool = false
var _tween: Tween

@onready var _bg: ColorRect = $Background
@onready var _scene: Control = $Scene
@onready var _location: Label = $Scene/LocationLabel
@onready var _avatar: Panel = $Scene/Avatar
@onready var _avatar_initial: Label = $Scene/Avatar/Initial
@onready var _avatar_art: TextureRect = $Scene/Avatar/Art
@onready var _subtitle_box: Panel = $Scene/SubtitleBox
@onready var _speaker: Label = $Scene/SubtitleBox/SpeakerName
@onready var _subtitle: RichTextLabel = $Scene/SubtitleBox/SubtitleText
@onready var _answer_button: Button = $Scene/AnswerButton
@onready var _skip_button: Button = $Scene/SkipButton
@onready var _caption: Label = $Caption
@onready var _audio: AudioStreamPlayer = $Audio

func _ready() -> void:
	_answer_button.pressed.connect(advance)
	_skip_button.pressed.connect(skip)
	if not beats.is_empty():
		play(beats)

func play(p_beats: Array[CutsceneBeat]) -> void:
	_beats = p_beats
	_index = -1
	_next()

func advance() -> void:
	if _index < 0 or _index >= _beats.size():
		return
	if _typing:
		_finish_typing()
	else:
		_next()

func skip() -> void:
	_cleanup()
	finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		skip()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		advance()
		get_viewport().set_input_as_handled()

func _next() -> void:
	_index += 1
	if _index >= _beats.size():
		_cleanup()
		finished.emit()
		return
	_show_beat(_beats[_index])

func _show_beat(beat: CutsceneBeat) -> void:
	_bg.color = beat.background_color   # placeholder do ambiente; textura real entra via slot
	if beat.sfx != null:
		_audio.stream = beat.sfx
		_audio.play()
	match beat.kind:
		CutsceneBeat.Kind.CAPTION:
			_show_caption(beat)
		CutsceneBeat.Kind.CALL:
			_show_call(beat)
		_:
			_show_dialogue(beat)
	_arm_auto_advance(beat)

func _show_call(beat: CutsceneBeat) -> void:
	# Beat 0: tela "recebendo chamada" (estruturada a partir de beat.speaker).
	_scene.visible = true
	_caption.visible = false
	_location.text = "recebendo chamada"
	_speaker.text = beat.speaker
	_subtitle_box.visible = false
	_answer_button.visible = true
	_skip_button.visible = true
	_set_avatar(beat)
	_typing = false

func _show_dialogue(beat: CutsceneBeat) -> void:
	# Cross-cut: mostra o ambiente do falante (beat.location) em tela cheia.
	_scene.visible = true
	_caption.visible = false
	_location.text = beat.location
	_speaker.text = beat.speaker
	_subtitle_box.visible = true
	_answer_button.visible = false
	_skip_button.visible = true
	_set_avatar(beat)
	_start_typing(beat.text)

func _show_caption(beat: CutsceneBeat) -> void:
	# Fim: some com a cena, mostra a legenda central sobre o fundo.
	_scene.visible = false
	_caption.visible = true
	_caption.text = beat.text
	_caption.modulate.a = 0.0
	_typing = false
	_tween = create_tween()
	_tween.tween_property(_caption, "modulate:a", 1.0, 0.6)

func _set_avatar(beat: CutsceneBeat) -> void:
	if beat.portrait != null:
		_avatar_art.texture = beat.portrait
		_avatar_art.visible = true
		_avatar_initial.visible = false
	else:
		_avatar_art.visible = false
		_avatar_initial.visible = true
		_avatar_initial.text = beat.speaker.substr(0, 1)
		_avatar.modulate = SPEAKER_COLORS.get(beat.speaker, DEFAULT_SPEAKER_COLOR)

func _start_typing(full_text: String) -> void:
	_subtitle.text = full_text
	_subtitle.visible_ratio = 0.0
	_typing = true
	var dur := maxf(0.2, float(full_text.length()) / CHARS_PER_SEC)
	_tween = create_tween()
	_tween.tween_property(_subtitle, "visible_ratio", 1.0, dur)
	_tween.finished.connect(func(): _typing = false)

func _finish_typing() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_subtitle.visible_ratio = 1.0
	_typing = false

func _arm_auto_advance(beat: CutsceneBeat) -> void:
	if beat.auto_advance_after > 0.0:
		var armed_index := _index
		get_tree().create_timer(beat.auto_advance_after).timeout.connect(func():
			if _index == armed_index:
				_next()
		)

func _cleanup() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_index = _beats.size()
	_typing = false
