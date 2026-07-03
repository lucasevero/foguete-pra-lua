class_name CutscenePlayer
extends CanvasLayer
## Player de cutscene reutilizável e data-driven — cross-cut (mobile/portrait).
## Mostra o AMBIENTE do falante em tela cheia (fundo por textura), o personagem
## grande ancorado no rodapé (esquerda/direita conforme o lado) e a fala no topo.
## Área: integration. Não conhece gameplay nem GameEvents — é pré-jogo/overlay genérico.
## Input MOBILE: toque/clique avança; botões Atender/Pular. Sem teclado.

signal finished

## Se preenchido no inspector, auto-toca no _ready (útil pra testar a cena isolada).
@export var beats: Array[CutsceneBeat] = []

const CHARS_PER_SEC := 45.0
## Cores de placeholder por falante (usado só quando não há retrato de arte).
const SPEAKER_COLORS := {
	"CARLOS": Color(0.90, 0.45, 0.25),
	"GUS": Color(0.35, 0.70, 0.45),
	"LUCA": Color(0.45, 0.55, 0.90),
}
const DEFAULT_SPEAKER_COLOR := Color(0.5, 0.5, 0.5)

## Enquadramento do personagem (grande, ancorado no rodapé; corte na perna = borda).
const AV_SIZE := 640      # largura/altura do quadro do personagem
const AV_DROP := 40       # quanto o quadro passa da borda inferior
const AV_OVER := 40       # transbordo lateral (personagem encosta na borda)

var _beats: Array[CutsceneBeat] = []
var _index: int = -1
var _typing: bool = false
var _tween: Tween

@onready var _bg: ColorRect = $Background
@onready var _bg_art: TextureRect = $BackgroundArt
@onready var _scene_art: TextureRect = $SceneArt
@onready var _scene: Control = $Scene
@onready var _top_panel: Panel = $Scene/TopPanel
@onready var _location: Label = $Scene/TopPanel/LocationLabel
@onready var _speaker: Label = $Scene/TopPanel/SpeakerName
@onready var _subtitle: RichTextLabel = $Scene/TopPanel/SubtitleText
@onready var _avatar: Panel = $Scene/Avatar
@onready var _avatar_initial: Label = $Scene/Avatar/Initial
@onready var _avatar_art: TextureRect = $Scene/Avatar/Art
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
	# Mobile: toque/clique avança. O toque emula mouse (emulate_mouse_from_touch,
	# ligado por padrão — mesma convenção do player.gd), então basta o MouseButton
	# (tratar ScreenTouch junto dispararia 2x por toque). Os Control não-botão têm
	# mouse_filter=IGNORE no .tscn pra o evento chegar aqui; os botões capturam o seu.
	if event is InputEventMouseButton and event.pressed:
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
	_bg.color = beat.background_color        # cor de fallback do ambiente
	if beat.background != null:               # textura do ambiente (ex.: LUA, espaço)
		_bg_art.texture = beat.background
		_bg_art.visible = true
	else:
		_bg_art.visible = false
	if beat.scene_art != null:                # ilustração por cima do fundo (ex.: cena final)
		_scene_art.texture = beat.scene_art
		_scene_art.visible = true
	else:
		_scene_art.visible = false
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
	# Tela "Carlos chamando" — sem imagem do personagem, só o texto + Atender.
	_scene.visible = true
	_caption.visible = false
	_top_panel.visible = true
	_location.visible = false
	_speaker.visible = true
	_speaker.text = beat.text                 # "Carlos chamando"
	_subtitle.visible = false
	_avatar.visible = false
	_answer_button.visible = true
	_skip_button.visible = true
	_typing = false

func _show_dialogue(beat: CutsceneBeat) -> void:
	# Cross-cut: ambiente + personagem grande no rodapé + fala no topo.
	# Beats de "ação"/wide-shot (sem retrato/nome) mostram só a cena + o texto.
	_scene.visible = true
	_caption.visible = false
	_top_panel.visible = true
	_location.visible = false
	_speaker.visible = not beat.speaker.is_empty()
	_speaker.text = beat.speaker
	_subtitle.visible = true
	_answer_button.visible = false
	_skip_button.visible = true
	if beat.portrait != null:
		_avatar.visible = true
		_set_avatar(beat)
	else:
		_avatar.visible = false
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
	# Posiciona o personagem grande no rodapé, no lado indicado por portrait_side.
	var on_right := beat.portrait_side == CutsceneBeat.PortraitSide.RIGHT
	_avatar.anchor_top = 1.0
	_avatar.anchor_bottom = 1.0
	_avatar.offset_top = -AV_SIZE
	_avatar.offset_bottom = AV_DROP
	if on_right:
		_avatar.anchor_left = 1.0
		_avatar.anchor_right = 1.0
		_avatar.offset_left = -AV_SIZE + AV_OVER
		_avatar.offset_right = AV_OVER
	else:
		_avatar.anchor_left = 0.0
		_avatar.anchor_right = 0.0
		_avatar.offset_left = -AV_OVER
		_avatar.offset_right = AV_SIZE - AV_OVER
	# textura vs placeholder
	if beat.portrait != null:
		_avatar_art.texture = beat.portrait
		_avatar_art.visible = true
		_avatar_initial.visible = false
		_avatar.self_modulate = Color(1, 1, 1, 0)   # esconde a caixa; só o sprite transparente
	else:
		_avatar_art.visible = false
		_avatar_initial.visible = true
		_avatar_initial.text = beat.speaker.substr(0, 1)
		_avatar.self_modulate = SPEAKER_COLORS.get(beat.speaker, DEFAULT_SPEAKER_COLOR)

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
