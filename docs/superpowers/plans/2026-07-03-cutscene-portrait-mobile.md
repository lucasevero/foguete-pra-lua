# Cutscene mobile/portrait "tela de chamada" — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesenhar o `CutscenePlayer` para o formato retrato mobile (720×1280) como uma "tela de chamada" (recebendo chamada → em chamada → desliga e corta pro foguete), touch-first.

**Architecture:** Reescreve só a camada de apresentação do player reutilizável — `cutscene_player.tscn` (layout retrato com âncoras responsivas) e a parte de render de `cutscene_player.gd` (3 telas por `kind`, avatar único que troca por falante, timer de chamada, botões Atender/Pular). A máquina de beats (índice, typewriter, `advance`/`skip`/`finished`, auto-advance) e a **API pública ficam intactas**, então os testes headless existentes seguem válidos.

**Tech Stack:** Godot 4.7 (exato), GDScript, cenas `.tscn`. Testes headless `extends SceneTree` + smoke tests.

## Global Constraints

- **Godot 4.7 exato.** Binário: `/Applications/Godot.app/Contents/MacOS/Godot`.
- **Área: integration (Dev D).** Mexe SÓ em `cutscene_player.tscn`, `cutscene_player.gd`, `tests/test_cutscene_player.gd` e `.claude/devlog/integration.md`.
- **NÃO tocar:** `cutscene_beat.gd`, `cutscene_intro.gd`, `intro.gd`, `intro.tscn`, `project.godot`, `game_events.gd`, `CONTRACT.md`, e todos os arquivos de gameplay de outras áreas (`player.*`, `asteroid*`, `fuel*`, `parallax_bg.*`, `game_manager.gd`, `ui.*`, `main.tscn`).
- **Sem novas input actions.** Input touch-first: tocar (mouse/toque) avança; botões Atender/Pular; `ui_accept`/`ui_cancel` mantidos p/ desktop.
- **API pública inalterada:** `class_name CutscenePlayer extends CanvasLayer`, `signal finished`, `@export var beats: Array[CutsceneBeat]`, `play(p_beats)`, `advance()`, `skip()`.
- **Dados/contrato inalterados.** Mesmos 8 beats; `portrait_side` fica sem uso (avatar único) — mantido por compat.
- **Sempre commitar `.uid`** ao lado de cada `.gd`.
- **Import antes de rodar script/cena:** `--headless --import --quit` (registra `class_name`).

---

## File Structure

| Arquivo | Mudança |
|---------|---------|
| `cutscene_player.tscn` | **Reescrita** — layout retrato "tela de chamada" (âncoras responsivas) |
| `cutscene_player.gd` | **Reescrita da apresentação** — render por kind, avatar único, timer, botões (máquina de beats/API mantidas) |
| `tests/test_cutscene_player.gd` | Ajuste — mantém cenários atuais + cobre botões Atender/Pular |
| `.claude/devlog/integration.md` | Append — registra o redesign portrait concluído |

---

## Task 1: Reescrever `CutscenePlayer` para portrait "tela de chamada"

**Files:**
- Rewrite: `cutscene_player.gd`
- Rewrite: `cutscene_player.tscn`
- Modify: `tests/test_cutscene_player.gd`

**Interfaces:**
- Consumes: `CutsceneBeat` (`Kind {CALL,DIALOGUE,CAPTION}`, `make()`, campos `kind/speaker/text/portrait/background_color/sfx/auto_advance_after`).
- Produces (inalterado): `class_name CutscenePlayer extends CanvasLayer`; `signal finished`; `@export var beats`; `play(p_beats: Array[CutsceneBeat])`; `advance()`; `skip()`.

- [ ] **Step 1: Reescrever `cutscene_player.tscn`** (layout retrato 720×1280, âncoras responsivas)

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://cutscene_player.gd" id="1"]

[node name="CutscenePlayer" type="CanvasLayer"]
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0, 0, 0, 1)

[node name="CallUI" type="Control" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0

[node name="TopBar" type="Panel" parent="CallUI"]
anchor_right = 1.0
offset_bottom = 170.0

[node name="CallLabel" type="Label" parent="CallUI/TopBar"]
anchor_right = 1.0
offset_top = 18.0
offset_bottom = 46.0
horizontal_alignment = 1
theme_override_font_sizes/font_size = 20

[node name="Speaker" type="Label" parent="CallUI/TopBar"]
anchor_right = 1.0
offset_top = 52.0
offset_bottom = 112.0
horizontal_alignment = 1
theme_override_font_sizes/font_size = 40

[node name="CallTimer" type="Label" parent="CallUI/TopBar"]
anchor_right = 1.0
offset_top = 118.0
offset_bottom = 150.0
horizontal_alignment = 1
theme_override_font_sizes/font_size = 22

[node name="Avatar" type="Panel" parent="CallUI"]
anchor_left = 0.5
anchor_right = 0.5
offset_left = -150.0
offset_top = 230.0
offset_right = 150.0
offset_bottom = 530.0

[node name="Initial" type="Label" parent="CallUI/Avatar"]
anchor_right = 1.0
anchor_bottom = 1.0
horizontal_alignment = 1
vertical_alignment = 1
theme_override_font_sizes/font_size = 140

[node name="Art" type="TextureRect" parent="CallUI/Avatar"]
visible = false
anchor_right = 1.0
anchor_bottom = 1.0
expand_mode = 1
stretch_mode = 5

[node name="SubtitleBox" type="Panel" parent="CallUI"]
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 40.0
offset_top = -360.0
offset_right = -40.0
offset_bottom = -150.0

[node name="SubtitleText" type="RichTextLabel" parent="CallUI/SubtitleBox"]
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 24.0
offset_top = 20.0
offset_right = -24.0
offset_bottom = -20.0
theme_override_font_sizes/normal_font_size = 26

[node name="AnswerButton" type="Button" parent="CallUI"]
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -120.0
offset_top = -120.0
offset_right = 120.0
offset_bottom = -50.0
text = "Atender"
modulate = Color(0.45, 0.85, 0.5, 1)
theme_override_font_sizes/font_size = 30

[node name="SkipButton" type="Button" parent="CallUI"]
anchor_left = 1.0
anchor_right = 1.0
offset_left = -140.0
offset_top = 24.0
offset_right = -24.0
offset_bottom = 68.0
text = "Pular"
theme_override_font_sizes/font_size = 20

[node name="Caption" type="Label" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
horizontal_alignment = 1
vertical_alignment = 1
theme_override_font_sizes/font_size = 44
visible = false

[node name="Audio" type="AudioStreamPlayer" parent="."]
```

- [ ] **Step 2: Reescrever `cutscene_player.gd`** (render "tela de chamada"; máquina de beats/API mantidas)

```gdscript
class_name CutscenePlayer
extends CanvasLayer
## Player de cutscene reutilizável e data-driven — layout "tela de chamada" (mobile/portrait).
## Consome Array[CutsceneBeat] e toca em sequência. Emite `finished` no fim ou ao pular.
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
var _in_call: bool = false        # true durante os beats DIALOGUE (após atender) -> timer corre
var _call_seconds: float = 0.0

@onready var _bg: ColorRect = $Background
@onready var _call_ui: Control = $CallUI
@onready var _top_bar: Panel = $CallUI/TopBar
@onready var _call_label: Label = $CallUI/TopBar/CallLabel
@onready var _speaker: Label = $CallUI/TopBar/Speaker
@onready var _call_timer: Label = $CallUI/TopBar/CallTimer
@onready var _avatar: Panel = $CallUI/Avatar
@onready var _avatar_initial: Label = $CallUI/Avatar/Initial
@onready var _avatar_art: TextureRect = $CallUI/Avatar/Art
@onready var _subtitle_box: Panel = $CallUI/SubtitleBox
@onready var _subtitle: RichTextLabel = $CallUI/SubtitleBox/SubtitleText
@onready var _answer_button: Button = $CallUI/AnswerButton
@onready var _skip_button: Button = $CallUI/SkipButton
@onready var _caption: Label = $Caption
@onready var _audio: AudioStreamPlayer = $Audio

func _ready() -> void:
	_answer_button.pressed.connect(advance)
	_skip_button.pressed.connect(skip)
	if not beats.is_empty():
		play(beats)

func _process(delta: float) -> void:
	if _in_call:
		_call_seconds += delta
		_call_timer.text = _format_time(_call_seconds)

func play(p_beats: Array[CutsceneBeat]) -> void:
	_beats = p_beats
	_index = -1
	_in_call = false
	_call_seconds = 0.0
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
	match beat.kind:
		CutsceneBeat.Kind.CAPTION:
			_show_caption(beat)
		CutsceneBeat.Kind.CALL:
			_show_call(beat)
		_:
			_show_dialogue(beat)
	_arm_auto_advance(beat)

func _show_call(beat: CutsceneBeat) -> void:
	# Tela "recebendo chamada": estruturada a partir de beat.speaker.
	# (beat.text não é exibido aqui — o CALL é UI estruturada, não uma frase.)
	_in_call = false
	_call_ui.visible = true
	_caption.visible = false
	_top_bar.visible = true
	_call_label.text = "chamando…"
	_speaker.text = beat.speaker
	_call_timer.visible = false
	_subtitle_box.visible = false
	_answer_button.visible = true
	_skip_button.visible = true
	_set_avatar(beat)
	_typing = false

func _show_dialogue(beat: CutsceneBeat) -> void:
	_in_call = true
	_call_ui.visible = true
	_caption.visible = false
	_top_bar.visible = true
	_call_label.text = "chamada"
	_speaker.text = beat.speaker
	_call_timer.visible = true
	_subtitle_box.visible = true
	_answer_button.visible = false
	_skip_button.visible = true
	_set_avatar(beat)
	_start_typing(beat.text)

func _show_caption(beat: CutsceneBeat) -> void:
	# A ligação "desligou": derruba a moldura de chamada, mostra a legenda central.
	_in_call = false
	_call_ui.visible = false
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

func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]

func _cleanup() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_index = _beats.size()
	_typing = false
	_in_call = false
```

- [ ] **Step 3: Ajustar `tests/test_cutscene_player.gd`** — manter os cenários atuais e adicionar cobertura dos botões. Substituir o arquivo inteiro por:

```gdscript
extends SceneTree
## Teste headless da lógica do CutscenePlayer. Rodar:
##   Godot --headless --script res://tests/test_cutscene_player.gd

func _initialize() -> void:
	var ok := true

	var scene: PackedScene = load("res://cutscene_player.tscn")

	var d1 := CutsceneBeat.make(CutsceneBeat.Kind.DIALOGUE, "CARLOS", "oi")
	var d2 := CutsceneBeat.make(CutsceneBeat.Kind.DIALOGUE, "VOCÊ", "tchau", CutsceneBeat.PortraitSide.RIGHT)
	var beats: Array[CutsceneBeat] = [d1, d2]

	# 1) DIALOGUE: dirige advance() até finalizar
	var player: CutscenePlayer = scene.instantiate()
	get_root().add_child(player)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo
	var done := {"v": false}
	player.finished.connect(func(): done["v"] = true)
	player.play(beats)
	var guard := 0
	while not done["v"] and guard < 20:
		player.advance()
		guard += 1
	ok = _check(done["v"], "finished deveria disparar ao fim dos beats") and ok
	ok = _check(guard < 20, "não deve precisar de 20 advances (loop travado?)") and ok

	# 2) skip() finaliza imediatamente
	var player2: CutscenePlayer = scene.instantiate()
	get_root().add_child(player2)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo
	var done2 := {"v": false}
	player2.finished.connect(func(): done2["v"] = true)
	player2.play(beats)
	player2.skip()
	ok = _check(done2["v"], "skip() deveria disparar finished") and ok

	# 3) CALL + CAPTION: cobre os dois outros caminhos de render (chamada e legenda)
	var caption_beats: Array[CutsceneBeat] = [
		CutsceneBeat.make(CutsceneBeat.Kind.CALL, "CARLOS", "CARLOS chamando…"),
		CutsceneBeat.make(CutsceneBeat.Kind.CAPTION, "", "Missão de resgate iniciada."),
	]
	var player3: CutscenePlayer = scene.instantiate()
	get_root().add_child(player3)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo
	var done3 := {"v": false}
	player3.finished.connect(func(): done3["v"] = true)
	player3.play(caption_beats)
	var guard3 := 0
	while not done3["v"] and guard3 < 20:
		player3.advance()
		guard3 += 1
	ok = _check(done3["v"], "finished deveria disparar ao fim dos beats CALL/CAPTION") and ok
	ok = _check(guard3 < 20, "não deve precisar de 20 advances no CALL/CAPTION (loop travado?)") and ok

	# 4) SkipButton.pressed -> skip() -> finished
	var player4: CutscenePlayer = scene.instantiate()
	get_root().add_child(player4)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo
	var done4 := {"v": false}
	player4.finished.connect(func(): done4["v"] = true)
	player4.play(beats)
	(player4.get_node("CallUI/SkipButton") as Button).pressed.emit()
	ok = _check(done4["v"], "SkipButton deveria disparar skip()->finished") and ok

	# 5) AnswerButton.pressed -> advance() a partir do CALL, depois dirige até o fim
	var player5: CutscenePlayer = scene.instantiate()
	get_root().add_child(player5)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo
	var done5 := {"v": false}
	player5.finished.connect(func(): done5["v"] = true)
	player5.play(caption_beats)
	(player5.get_node("CallUI/AnswerButton") as Button).pressed.emit()
	var guard5 := 0
	while not done5["v"] and guard5 < 20:
		player5.advance()
		guard5 += 1
	ok = _check(done5["v"], "AnswerButton deveria avançar a partir do CALL") and ok

	if ok:
		print("TEST_OK test_cutscene_player")
		quit(0)
	else:
		printerr("TEST_FAIL test_cutscene_player")
		quit(1)

func _check(cond: bool, msg: String) -> bool:
	if not cond:
		printerr("  FAIL: " + msg)
	return cond
```

- [ ] **Step 4: Importar e rodar a suíte headless — tudo deve passar**

Run:
```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --import --quit 2>&1 | grep -iE "error|parse" | grep -vi "0 error"   # esperado: vazio
$GODOT --headless --script res://tests/test_cutscene_data.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL"      # esperado: TEST_OK
$GODOT --headless --script res://tests/test_cutscene_player.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL|FAIL:|SCRIPT ERROR"  # esperado: TEST_OK só
$GODOT --headless res://intro.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|nil|invalid"       # esperado: vazio (para no CALL)
$GODOT --headless res://main.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|nil|invalid"        # esperado: vazio
```
Expected: `test_cutscene_data` e `test_cutscene_player` = `TEST_OK`; os greps de erro vazios. Se algo falhar (ex.: node-path divergente entre `.gd` e `.tscn`), corrigir e repetir.

- [ ] **Step 5: Commit**

```bash
git add cutscene_player.gd cutscene_player.gd.uid cutscene_player.tscn tests/test_cutscene_player.gd tests/test_cutscene_player.gd.uid
git commit -m "feat(integration): redesign CutscenePlayer for portrait mobile call-screen"
```

---

## Task 2: Verificação final + devlog

**Files:**
- Modify: `.claude/devlog/integration.md`

**Interfaces:** nenhuma nova; consolida verificação e registra o redesign.

- [ ] **Step 1: Rodar a suíte headless completa e capturar os resultados**

Run:
```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --import --quit 2>&1 | grep -iE "error|parse" | grep -vi "0 error"
$GODOT --headless --script res://tests/test_cutscene_data.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL"
$GODOT --headless --script res://tests/test_cutscene_player.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL"
$GODOT --headless res://intro.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|nil|invalid"
$GODOT --headless res://main.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|nil|invalid"
```
Expected: dois `TEST_OK`; greps de erro vazios. Se algo falhar, STOP e reportar BLOCKED (não escrever devlog "passando").

- [ ] **Step 2: Registrar no devlog `.claude/devlog/integration.md`**

Ler o `.claude/devlog/integration.md` p/ manter o formato (entradas mais recentes no topo) e adicionar uma entrada nova (2026-07-03) descrevendo: o redesign portrait/mobile da cutscene em "tela de chamada" (recebendo chamada → em chamada com avatar+timer+legenda → desliga e corta pro foguete); input touch-first (tocar avança; botões Atender/Pular; ESC/Espaço só desktop); que resolve o item "adaptar layout p/ portrait" que estava PENDENTE na entrada anterior; que só `cutscene_player.gd`/`.tscn` (+ teste) mudaram; contrato `GameEvents` e dados (`cutscene_*intro/beat`) inalterados; resultados headless; e que o **playtest manual F5 continua PENDENTE** (interativo). Itens do checklist F5:
- Recebe chamada ("CARLOS" + "chamando…") com botão Atender; tocar em qualquer lugar também atende.
- Em chamada: avatar do falante troca (Carlos/Você/Gus), timer conta, legenda com typewriter; tocar avança/completa a linha.
- Botão Pular encerra a cutscene a qualquer momento.
- Legenda final "Missão de resgate iniciada." (fundo azul) → entra no `main.tscn`.
- Layout cabe bonito em 720×1280 (nada cortado/fora da tela).

- [ ] **Step 3: Commit**

```bash
git add .claude/devlog/integration.md
git commit -m "docs(integration): devlog do redesign portrait da cutscene"
```

---

## Notas de execução

- **`@onready` vs `.tscn`:** os caminhos em `cutscene_player.gd` (`$CallUI/TopBar/CallLabel`, `$CallUI/Avatar/Initial`, `$CallUI/SubtitleBox/SubtitleText`, `$CallUI/AnswerButton`, `$CallUI/SkipButton`, etc.) precisam bater exatamente com os nós de `cutscene_player.tscn`. Divergência = crash no load → o `test_cutscene_player.gd` pega.
- **Import antes de script/cena** sempre, p/ registrar `class_name`. Commitar `.uid`.
- **Offsets do `.tscn`** são um ponto de partida razoável p/ 720×1280; afinamento fino de posição/tamanho pode ser feito no editor no playtest, sem mexer na lógica.
