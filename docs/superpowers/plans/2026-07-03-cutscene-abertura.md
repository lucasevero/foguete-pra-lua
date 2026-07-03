# Cutscene Player reutilizável + CENA 1 (abertura) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar a cutscene de abertura (a ligação do Carlos) via um player de cutscene genérico e data-driven, sem tocar em nenhum sistema de gameplay.

**Architecture:** Uma cena separada `intro.tscn` (nova `main_scene`) roda um `CutscenePlayer` reutilizável alimentado pelos beats da CENA 1; ao terminar/pular, faz `change_scene_to_file("res://main.tscn")`. O gameplay e o contrato `GameEvents` ficam intocados. Arte/áudio entram por slots trocáveis (placeholders coloridos por ora).

**Tech Stack:** Godot 4.7 (exato), GDScript, cenas `.tscn`. Testes: scripts headless `extends SceneTree` + smoke tests headless.

## Global Constraints

- **Godot 4.7 exato** — versão diferente reescreve `.tscn` → conflito de merge.
- **Área: integration (Dev D).** Todos os arquivos são NOVOS, exceto 1 linha em `project.godot` (`run/main_scene`) — arquivo compartilhado, avisar o time.
- **Não tocar:** `game_events.gd`, `player.*`, `asteroid*`, `fuel*`, `parallax_bg.*`, `game_manager.gd`, `ui.*`, `main.tscn`.
- **Sem novas input actions** — usar `ui_accept`/`ui_cancel` (padrão do Godot).
- **Sem `.tres` hand-authored** — dados dos beats montados em código (robusto no smoke headless, sem binário pra dar merge conflict).
- **Binário do Godot:** `/Applications/Godot.app/Contents/MacOS/Godot`.
- **Sempre commitar `.uid`** gerado junto de cada `.gd`.
- **Idioma:** falas em PT-BR, copiadas verbatim do spec (Notion "Storytelling").

---

## File Structure

| Arquivo | Responsabilidade |
|---------|------------------|
| `cutscene_beat.gd` | `class_name CutsceneBeat extends Resource` — 1 "fala" tipada (dados puros) |
| `cutscene_intro.gd` | `class_name CutsceneIntro` — `static build() -> Array[CutsceneBeat]` (roteiro CENA 1) |
| `cutscene_player.tscn` / `cutscene_player.gd` | `class_name CutscenePlayer extends CanvasLayer` — player reutilizável (retratos, caixa, legenda, typewriter, áudio). Emite `finished` |
| `intro.tscn` / `intro.gd` | Fluxo fino: hospeda o player, toca a CENA 1, transiciona pro `main.tscn` |
| `tests/test_cutscene_data.gd` | Teste headless dos dados (`CutsceneIntro.build()` e `CutsceneBeat`) |
| `tests/test_cutscene_player.gd` | Teste headless da lógica do player (progressão de beats, `finished`, skip) |
| `project.godot` | (modificar 1 linha) `run/main_scene` → `res://intro.tscn` |

---

## Task 1: Dados — `CutsceneBeat` + `CutsceneIntro`

**Files:**
- Create: `cutscene_beat.gd`
- Create: `cutscene_intro.gd`
- Test: `tests/test_cutscene_data.gd`

**Interfaces:**
- Produces:
  - `CutsceneBeat` (Resource) com enums `Kind { CALL, DIALOGUE, CAPTION }`, `PortraitSide { LEFT, RIGHT }` e campos: `kind: Kind`, `speaker: String`, `text: String`, `portrait: Texture2D`, `portrait_side: PortraitSide`, `background: Texture2D`, `background_color: Color`, `sfx: AudioStream`, `auto_advance_after: float`.
  - `CutsceneBeat.make(kind, speaker, text, side=LEFT, bg=Color.BLACK) -> CutsceneBeat`
  - `CutsceneIntro.build() -> Array[CutsceneBeat]` (8 beats da CENA 1)

- [ ] **Step 1: Escrever `cutscene_beat.gd`**

```gdscript
class_name CutsceneBeat
extends Resource
## Uma "fala" da cutscene. Dados puros, consumidos pelo CutscenePlayer.
## Área: integration. Não conhece gameplay nem GameEvents.

enum Kind { CALL, DIALOGUE, CAPTION }
enum PortraitSide { LEFT, RIGHT }

@export var kind: Kind = Kind.DIALOGUE
@export var speaker: String = ""
@export_multiline var text: String = ""
@export var portrait: Texture2D                      # null = placeholder colorido
@export var portrait_side: PortraitSide = PortraitSide.LEFT
@export var background: Texture2D                     # null = usa background_color
@export var background_color: Color = Color.BLACK     # fallback quando não há textura
@export var sfx: AudioStream                          # som opcional do beat
@export var auto_advance_after: float = 0.0           # 0 = espera input; >0 = auto após N s

static func make(p_kind: Kind, p_speaker: String, p_text: String,
		p_side: PortraitSide = PortraitSide.LEFT,
		p_bg: Color = Color.BLACK) -> CutsceneBeat:
	var b := CutsceneBeat.new()
	b.kind = p_kind
	b.speaker = p_speaker
	b.text = p_text
	b.portrait_side = p_side
	b.background_color = p_bg
	return b
```

- [ ] **Step 2: Escrever `cutscene_intro.gd`** (roteiro CENA 1, verbatim do spec)

```gdscript
class_name CutsceneIntro
## Dados da CENA 1 (abertura — a ligação do Carlos). Fonte: Notion "Storytelling".
## Área: integration.

const SKY := Color(0.35, 0.65, 0.95)   # azul-céu da base de lançamento

static func build() -> Array[CutsceneBeat]:
	var K := CutsceneBeat.Kind
	var S := CutsceneBeat.PortraitSide
	var beats: Array[CutsceneBeat] = [
		CutsceneBeat.make(K.CALL, "CARLOS", "CARLOS chamando…", S.LEFT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "E aí, beleza? Então… eu e o Gus vibecodamos um foguete no fim de semana.", S.LEFT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "VOCÊ", "Vocês fizeram o quê?", S.RIGHT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "Funcionou! A gente chegou na Lua! De verdade!", S.LEFT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "É… só que a gente esqueceu de codar a volta.", S.LEFT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "GUS", "FALA PRA ELE TRAZER LANCHE!", S.RIGHT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "Dá pra vir buscar a gente? Cê é a nossa única… uh… branch de recuperação.", S.LEFT, Color.BLACK),
		CutsceneBeat.make(K.CAPTION, "", "Missão de resgate iniciada.", S.LEFT, SKY),
	]
	beats[7].auto_advance_after = 2.5   # a legenda final aparece sozinha e segue pro jogo
	return beats
```

- [ ] **Step 3: Escrever o teste headless `tests/test_cutscene_data.gd`**

```gdscript
extends SceneTree
## Teste headless dos dados da cutscene. Rodar:
##   Godot --headless --script res://tests/test_cutscene_data.gd

func _initialize() -> void:
	var ok := true
	var beats := CutsceneIntro.build()
	ok = _check(beats.size() == 8, "esperava 8 beats, veio %d" % beats.size()) and ok
	ok = _check(beats[0].kind == CutsceneBeat.Kind.CALL, "beat 0 deve ser CALL") and ok
	ok = _check(beats[0].speaker == "CARLOS", "beat 0 speaker deve ser CARLOS") and ok
	ok = _check(beats[7].kind == CutsceneBeat.Kind.CAPTION, "beat 7 deve ser CAPTION") and ok
	ok = _check(beats[7].text == "Missão de resgate iniciada.", "legenda final errada") and ok
	ok = _check(beats[7].auto_advance_after > 0.0, "legenda final deve auto-avançar") and ok
	var has_gus := false
	for b in beats:
		if b.speaker == "GUS":
			has_gus = true
	ok = _check(has_gus, "GUS deve aparecer em algum beat") and ok
	if ok:
		print("TEST_OK test_cutscene_data")
		quit(0)
	else:
		printerr("TEST_FAIL test_cutscene_data")
		quit(1)

func _check(cond: bool, msg: String) -> bool:
	if not cond:
		printerr("  FAIL: " + msg)
	return cond
```

- [ ] **Step 4: Importar o projeto (registra os `class_name`) e rodar o teste — deve FALHAR primeiro**

Antes deste passo os arquivos ainda não existem no import cache. Rodar o import e o teste:

Run:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --import --quit 2>&1 | tail -3
/Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_cutscene_data.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL|FAIL:"
```
Expected na primeira vez (se algum campo/valor estiver errado): linha `TEST_FAIL` ou `FAIL:`. Se já passar de primeira, ok — os dados estão corretos.

- [ ] **Step 5: Ajustar até o teste passar**

Run:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_cutscene_data.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL"
```
Expected: `TEST_OK test_cutscene_data`

- [ ] **Step 6: Commit**

```bash
git add cutscene_beat.gd cutscene_beat.gd.uid cutscene_intro.gd cutscene_intro.gd.uid tests/test_cutscene_data.gd tests/test_cutscene_data.gd.uid
git commit -m "feat(integration): add cutscene beat data model + CENA 1 script"
```

---

## Task 2: `CutscenePlayer` — cena + lógica de progressão (DIALOGUE, typewriter, finished)

**Files:**
- Create: `cutscene_player.gd`
- Create: `cutscene_player.tscn`
- Test: `tests/test_cutscene_player.gd`

**Interfaces:**
- Consumes: `CutsceneBeat`, `CutsceneBeat.Kind`, `CutsceneBeat.PortraitSide` (Task 1).
- Produces:
  - `class_name CutscenePlayer extends CanvasLayer`
  - `signal finished`
  - `@export var beats: Array[CutsceneBeat]` (auto-toca no `_ready` se preenchido)
  - `func play(p_beats: Array[CutsceneBeat]) -> void`
  - `func advance() -> void` (se digitando: completa a linha; senão: próximo beat / finaliza)
  - `func skip() -> void` (emite `finished` imediatamente)

- [ ] **Step 1: Escrever `cutscene_player.gd`**

```gdscript
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
```

- [ ] **Step 2: Escrever `cutscene_player.tscn`** (viewport 1152×648; offsets podem ser afinados no editor depois — o essencial é carregar sem erro e os nós baterem com os `@onready`)

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://cutscene_player.gd" id="1"]

[node name="CutscenePlayer" type="CanvasLayer"]
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0, 0, 0, 1)

[node name="PortraitLeft" type="Panel" parent="."]
offset_left = 80.0
offset_top = 170.0
offset_right = 300.0
offset_bottom = 440.0

[node name="Initial" type="Label" parent="PortraitLeft"]
anchor_right = 1.0
anchor_bottom = 1.0
horizontal_alignment = 1
vertical_alignment = 1
theme_override_font_sizes/font_size = 110

[node name="Art" type="TextureRect" parent="PortraitLeft"]
visible = false
anchor_right = 1.0
anchor_bottom = 1.0
expand_mode = 1
stretch_mode = 5

[node name="PortraitRight" type="Panel" parent="."]
offset_left = 852.0
offset_top = 170.0
offset_right = 1072.0
offset_bottom = 440.0

[node name="Initial" type="Label" parent="PortraitRight"]
anchor_right = 1.0
anchor_bottom = 1.0
horizontal_alignment = 1
vertical_alignment = 1
theme_override_font_sizes/font_size = 110

[node name="Art" type="TextureRect" parent="PortraitRight"]
visible = false
anchor_right = 1.0
anchor_bottom = 1.0
expand_mode = 1
stretch_mode = 5

[node name="DialogueBox" type="Panel" parent="."]
offset_left = 60.0
offset_top = 470.0
offset_right = 1092.0
offset_bottom = 616.0

[node name="SpeakerName" type="Label" parent="DialogueBox"]
offset_left = 24.0
offset_top = 10.0
offset_right = 500.0
offset_bottom = 44.0
theme_override_font_sizes/font_size = 26

[node name="DialogueText" type="RichTextLabel" parent="DialogueBox"]
offset_left = 24.0
offset_top = 48.0
offset_right = 1008.0
offset_bottom = 138.0
theme_override_font_sizes/normal_font_size = 22

[node name="Caption" type="Label" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
horizontal_alignment = 1
vertical_alignment = 1
theme_override_font_sizes/font_size = 44
visible = false

[node name="SkipHint" type="Label" parent="."]
anchor_left = 1.0
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -170.0
offset_top = -40.0
offset_right = -16.0
offset_bottom = -12.0
text = "ESC pular"
theme_override_font_sizes/font_size = 16

[node name="Audio" type="AudioStreamPlayer" parent="."]
```

- [ ] **Step 3: Escrever o teste headless `tests/test_cutscene_player.gd`** (dirige `advance()` sincronamente — sem depender de tempo/tween real)

```gdscript
extends SceneTree
## Teste headless da lógica do CutscenePlayer. Rodar:
##   Godot --headless --script res://tests/test_cutscene_player.gd

func _initialize() -> void:
	var ok := true

	var scene: PackedScene = load("res://cutscene_player.tscn")
	var player: CutscenePlayer = scene.instantiate()
	get_root().add_child(player)

	var done := {"v": false}
	player.finished.connect(func(): done["v"] = true)

	var d1 := CutsceneBeat.make(CutsceneBeat.Kind.DIALOGUE, "CARLOS", "oi")
	var d2 := CutsceneBeat.make(CutsceneBeat.Kind.DIALOGUE, "VOCÊ", "tchau", CutsceneBeat.PortraitSide.RIGHT)
	var beats: Array[CutsceneBeat] = [d1, d2]
	player.play(beats)

	# dirige advance() até finalizar (cada beat: 1 advance completa a linha, 1 avança)
	var guard := 0
	while not done["v"] and guard < 20:
		player.advance()
		guard += 1
	ok = _check(done["v"], "finished deveria disparar ao fim dos beats") and ok
	ok = _check(guard < 20, "não deve precisar de 20 advances (loop travado?)") and ok

	# skip() finaliza imediatamente
	var player2: CutscenePlayer = scene.instantiate()
	get_root().add_child(player2)
	var done2 := {"v": false}
	player2.finished.connect(func(): done2["v"] = true)
	player2.play(beats)
	player2.skip()
	ok = _check(done2["v"], "skip() deveria disparar finished") and ok

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

- [ ] **Step 4: Importar e rodar o teste — verificar que passa**

Run:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --import --quit 2>&1 | tail -3
/Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_cutscene_player.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL|FAIL:|SCRIPT ERROR"
```
Expected: `TEST_OK test_cutscene_player` (sem `SCRIPT ERROR` nem `FAIL:`). Se falhar, corrigir o script/cena e repetir.

- [ ] **Step 5: Commit**

```bash
git add cutscene_player.gd cutscene_player.gd.uid cutscene_player.tscn tests/test_cutscene_player.gd tests/test_cutscene_player.gd.uid
git commit -m "feat(integration): add reusable data-driven CutscenePlayer"
```

---

## Task 3: `intro.tscn` + fluxo, e ligar como `main_scene`

**Files:**
- Create: `intro.gd`
- Create: `intro.tscn`
- Modify: `project.godot` (linha `run/main_scene`)

**Interfaces:**
- Consumes: `CutscenePlayer` (Task 2), `CutsceneIntro.build()` (Task 1).
- Produces: cena de abertura executável em `res://intro.tscn`; nova `main_scene`.

- [ ] **Step 1: Escrever `intro.gd`**

```gdscript
extends Node
## Fluxo da abertura: toca a CENA 1 e, ao terminar/pular, entra no jogo.
## Área: integration. Só orquestra cena — não conhece gameplay nem GameEvents.

@onready var _player: CutscenePlayer = $CutscenePlayer

func _ready() -> void:
	_player.finished.connect(_on_finished)
	_player.play(CutsceneIntro.build())

func _on_finished() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
```

- [ ] **Step 2: Escrever `intro.tscn`** (root fino + instância do player; `beats` do player fica vazio — quem toca é o `intro.gd`)

```
[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene" path="res://cutscene_player.tscn" id="1"]
[ext_resource type="Script" path="res://intro.gd" id="2"]

[node name="Intro" type="Node"]
script = ExtResource("2")

[node name="CutscenePlayer" parent="." instance=ExtResource("1")]
```

- [ ] **Step 3: Trocar a `main_scene` em `project.godot`**

Modificar a linha existente em `[application]`:
```
run/main_scene="res://main.tscn"
```
para:
```
run/main_scene="res://intro.tscn"
```
(Não mexer em mais nada no `project.godot`.)

- [ ] **Step 4: Importar e verificar que a abertura carrega sem erro de script**

Run:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --import --quit 2>&1 | grep -iE "error|parse" | grep -vi "0 error"
/Applications/Godot.app/Contents/MacOS/Godot --headless res://intro.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|nil|invalid"
```
Expected: ambas as saídas VAZIAS. (Em headless sem input, a cutscene fica parada no beat CALL esperando "atender" — isso é esperado; o que importa é não haver erro.)

- [ ] **Step 5: Verificar que o `main.tscn` ainda carrega sem erro (não quebramos o gameplay)**

Run:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless res://main.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|nil|invalid"
```
Expected: saída VAZIA.

- [ ] **Step 6: Commit**

```bash
git add intro.gd intro.gd.uid intro.tscn project.godot
git commit -m "feat(integration): wire opening cutscene as main scene (intro -> main)"
```

---

## Task 4: Verificação final, devlog e aviso ao time

**Files:**
- Modify: `.claude/devlog/integration.md`

**Interfaces:** nenhuma nova; consolida verificação.

- [ ] **Step 1: Rodar a suíte completa de verificação headless**

Run:
```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --import --quit 2>&1 | grep -iE "error|parse" | grep -vi "0 error"
$GODOT --headless --script res://tests/test_cutscene_data.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL"
$GODOT --headless --script res://tests/test_cutscene_player.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL"
$GODOT --headless res://intro.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|nil|invalid"
$GODOT --headless res://main.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|nil|invalid"
```
Expected: dois `TEST_OK`; todas as linhas de `grep error/SCRIPT ERROR` vazias.

- [ ] **Step 2: Checklist de verificação manual no editor (F5)** — registrar resultado no devlog

Abrir no editor e rodar; confirmar:
- Abre na tela de ligação ("CARLOS chamando…") em fundo preto.
- Espaço avança; durante o typewriter, Espaço completa a linha na hora.
- Diálogo passa por Carlos → Você → Carlos → Gus → Carlos com retratos placeholder coloridos (esq/dir).
- ESC pula a cutscene a qualquer momento.
- No fim aparece a legenda "Missão de resgate iniciada." sobre fundo azul-céu e, após ~2.5s, entra no `main.tscn` e o gameplay começa normal.

- [ ] **Step 3: Registrar no devlog `.claude/devlog/integration.md`**

Acrescentar uma entrada (formato do devlog existente) descrevendo: cutscene de abertura + CutscenePlayer reutilizável; arquivos novos; ⚠️ **mudança em `project.godot`** (`run/main_scene` agora é `res://intro.tscn`) a comunicar ao time; contrato `GameEvents` inalterado; próximo passo natural = CENA 2 (final) reusando o player no `game_over(won)`.

- [ ] **Step 4: Commit**

```bash
git add .claude/devlog/integration.md
git commit -m "docs(integration): devlog da cutscene de abertura + aviso de main_scene"
```

> Observação: rodar a skill `/context-sync` ao final é opcional/complementar — o Step 3 já cobre o devlog manualmente. Como o contrato não mudou, `CONTRACT.md`/`game_events.gd` não precisam de update.

---

## Notas de execução

- **Ordem obrigatória:** sempre `--import` antes de rodar `--script res://...` ou uma cena, pois os `class_name` (`CutsceneBeat`, `CutsceneIntro`, `CutscenePlayer`) só ficam disponíveis após o import registrar a lista global de classes.
- **`.uid`:** o Godot gera um `.uid` ao lado de cada `.gd` no primeiro import. Commitar sempre junto (regra do projeto). Se um `.uid` não existir no momento do `git add`, rodar o `--import` antes.
- **Placeholders → arte:** quando a arte real chegar, basta preencher `portrait`/`background`/`sfx` nos beats (ou promover `cutscene_intro.gd` para um `.tres` editável no inspector). Nenhuma lógica muda.
