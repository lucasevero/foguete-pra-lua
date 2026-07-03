class_name CutscenePlayer
extends CanvasLayer
## Player de cutscene reutilizável e data-driven.
## Consome Array[CutsceneBeat] e toca em sequência. Emite `finished` no fim ou ao pular.
## Área: integration. Não conhece gameplay nem GameEvents — é pré-jogo/overlay genérico.

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
@onready var _p_left: Panel = $PortraitLeft
@onready var _p_left_initial: Label = $PortraitLeft/Initial
@onready var _p_left_art: TextureRect = $PortraitLeft/Art
@onready var _p_right: Panel = $PortraitRight
@onready var _p_right_initial: Label = $PortraitRight/Initial
@onready var _p_right_art: TextureRect = $PortraitRight/Art
@onready var _box: Panel = $DialogueBox
@onready var _speaker: Label = $DialogueBox/SpeakerName
@onready var _text: RichTextLabel = $DialogueBox/DialogueText
@onready var _caption: Label = $Caption
@onready var _audio: AudioStreamPlayer = $Audio

func _ready() -> void:
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
	_bg.color = beat.background_color   # placeholder; textura real entra depois via slot
	if beat.sfx != null:
		_audio.stream = beat.sfx
		_audio.play()
	_caption.visible = false
	_box.visible = false
	_p_left.visible = false
	_p_right.visible = false
	match beat.kind:
		CutsceneBeat.Kind.CAPTION:
			_show_caption(beat)
		CutsceneBeat.Kind.CALL:
			_show_call(beat)
		_:
			_show_dialogue(beat)
	_arm_auto_advance(beat)

func _show_dialogue(beat: CutsceneBeat) -> void:
	_box.visible = true
	_speaker.text = beat.speaker
	_show_portrait(beat)
	_start_typing(beat.text)

func _show_call(beat: CutsceneBeat) -> void:
	_box.visible = true
	_speaker.text = ""
	_start_typing("%s chamando…" % beat.speaker)

func _show_caption(beat: CutsceneBeat) -> void:
	_caption.visible = true
	_caption.text = beat.text
	_caption.modulate.a = 0.0
	_typing = false
	_tween = create_tween()
	_tween.tween_property(_caption, "modulate:a", 1.0, 0.6)

func _show_portrait(beat: CutsceneBeat) -> void:
	var use_left := beat.portrait_side == CutsceneBeat.PortraitSide.LEFT
	var panel := _p_left if use_left else _p_right
	var initial := _p_left_initial if use_left else _p_right_initial
	var art := _p_left_art if use_left else _p_right_art
	panel.visible = true
	if beat.portrait != null:
		art.texture = beat.portrait
		art.visible = true
		initial.visible = false
	else:
		art.visible = false
		initial.visible = true
		initial.text = beat.speaker.substr(0, 1)
		panel.modulate = SPEAKER_COLORS.get(beat.speaker, DEFAULT_SPEAKER_COLOR)

func _start_typing(full_text: String) -> void:
	_text.text = full_text
	_text.visible_ratio = 0.0
	_typing = true
	var dur := maxf(0.2, float(full_text.length()) / CHARS_PER_SEC)
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, dur)
	_tween.finished.connect(func(): _typing = false)

func _finish_typing() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_text.visible_ratio = 1.0
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
