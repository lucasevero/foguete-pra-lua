# Cutscene cross-cut (troca de ambiente por falante) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformar os beats de diálogo da cutscene numa montagem cross-cut que mostra, em tela cheia, o ambiente de quem fala (Carlos/Gus → LUA, Você → TERRA), mantendo o beat 0 como "recebendo chamada" e o final como legenda.

**Architecture:** Data-driven: adiciona `location` ao `CutsceneBeat`; `cutscene_intro.gd` define ambiente+cor por beat; `cutscene_player.gd`/`.tscn` renderizam o ambiente do beat (fundo full-screen + rótulo de local + avatar do falante + legenda). A máquina de beats e a API pública (`play/advance/skip/finished`) ficam intactas. Remove o "timer de chamada" do redesign anterior.

**Tech Stack:** Godot 4.7, GDScript, `.tscn`. Testes headless `extends SceneTree` + smoke.

## Global Constraints

- **Godot 4.7 exato.** Binário: `/Applications/Godot.app/Contents/MacOS/Godot`.
- **Área: integration (Dev D).** Mexe SÓ em: `cutscene_beat.gd`, `cutscene_intro.gd`, `cutscene_player.gd`, `cutscene_player.tscn`, `tests/test_cutscene_data.gd`, `tests/test_cutscene_player.gd`, `.claude/devlog/integration.md`.
- **NÃO tocar:** `intro.gd`, `intro.tscn`, `project.godot`, `game_events.gd`, `CONTRACT.md`, e arquivos de gameplay de outras áreas.
- **API pública inalterada:** `class_name CutscenePlayer extends CanvasLayer`, `signal finished`, `@export var beats: Array[CutsceneBeat]`, `play(p_beats)`, `advance()`, `skip()`.
- **Contrato `GameEvents` inalterado.** Texto PT-BR dos beats **verbatim** (não alterar as falas).
- **Sem novas input actions.** Touch-first: tocar avança; botões Atender/Pular; `ui_accept`/`ui_cancel` desktop.
- **Sempre commitar `.uid`** ao lado de cada `.gd` novo. Import antes de rodar script/cena.
- **Lição do time:** `.tscn` corrompida passa no headless mas derruba o editor → validar no editor/F5 (humano) antes do merge, além do headless.

---

## File Structure

| Arquivo | Mudança |
|---------|---------|
| `cutscene_beat.gd` | Adicionar campo `location: String` + param em `make()` |
| `cutscene_intro.gd` | Definir `location` + `background_color` por beat (LUA/TERRA/SKY) |
| `cutscene_player.gd` | Render cross-cut (remove timer; nós `Scene/*`) |
| `cutscene_player.tscn` | Layout cross-cut (Background full + Scene: LocationLabel/Avatar/SubtitleBox/botões) |
| `tests/test_cutscene_data.gd` | Assertar `location` dos beats |
| `tests/test_cutscene_player.gd` | Atualizar node-paths dos botões (`Scene/...`) |

---

## Task 1: Implementar o cross-cut (dados + player + testes)

**Files:**
- Modify: `cutscene_beat.gd`
- Modify: `cutscene_intro.gd`
- Rewrite: `cutscene_player.gd`
- Rewrite: `cutscene_player.tscn`
- Rewrite: `tests/test_cutscene_data.gd`
- Rewrite: `tests/test_cutscene_player.gd`

**Interfaces:**
- `CutsceneBeat` ganha `@export var location: String = ""` e `make(..., p_location := "")`.
- `CutscenePlayer` mantém API: `signal finished`, `@export var beats`, `play(p_beats)`, `advance()`, `skip()`.

- [ ] **Step 1: Adicionar `location` ao `cutscene_beat.gd`** — substituir o arquivo inteiro por:

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
@export var location: String = ""                    # ambiente do falante (rótulo placeholder / cena futura)
@export var portrait: Texture2D                      # null = placeholder colorido
@export var portrait_side: PortraitSide = PortraitSide.LEFT
@export var background: Texture2D                     # null = usa background_color
@export var background_color: Color = Color.BLACK     # fallback quando não há textura
@export var sfx: AudioStream                          # som opcional do beat
@export var auto_advance_after: float = 0.0           # 0 = espera input; >0 = auto após N s

static func make(p_kind: Kind, p_speaker: String, p_text: String,
		p_side: PortraitSide = PortraitSide.LEFT,
		p_bg: Color = Color.BLACK,
		p_location: String = "") -> CutsceneBeat:
	var b := CutsceneBeat.new()
	b.kind = p_kind
	b.speaker = p_speaker
	b.text = p_text
	b.portrait_side = p_side
	b.background_color = p_bg
	b.location = p_location
	return b
```

- [ ] **Step 2: Definir ambientes em `cutscene_intro.gd`** — substituir o arquivo inteiro por:

```gdscript
class_name CutsceneIntro
## Dados da CENA 1 (abertura — a ligação do Carlos). Fonte: Notion "Storytelling".
## Área: integration.

const SKY := Color(0.35, 0.65, 0.95)   # azul-céu da base de lançamento (legenda final)
const MOON := Color(0.11, 0.12, 0.18)  # cinza-espaço escuro (ambiente LUA)
const ROOM := Color(0.28, 0.20, 0.15)  # marrom-quente (seu quarto na TERRA)

static func build() -> Array[CutsceneBeat]:
	var K := CutsceneBeat.Kind
	var S := CutsceneBeat.PortraitSide
	var beats: Array[CutsceneBeat] = [
		CutsceneBeat.make(K.CALL, "CARLOS", "CARLOS chamando…", S.LEFT, Color.BLACK, ""),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "E aí, beleza? Então… eu e o Gus vibecodamos um foguete no fim de semana.", S.LEFT, MOON, "LUA"),
		CutsceneBeat.make(K.DIALOGUE, "VOCÊ", "Vocês fizeram o quê?", S.RIGHT, ROOM, "TERRA — seu quarto"),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "Funcionou! A gente chegou na Lua! De verdade!", S.LEFT, MOON, "LUA"),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "É… só que a gente esqueceu de codar a volta.", S.LEFT, MOON, "LUA"),
		CutsceneBeat.make(K.DIALOGUE, "GUS", "FALA PRA ELE TRAZER LANCHE!", S.RIGHT, MOON, "LUA"),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "Dá pra vir buscar a gente? Cê é a nossa única… uh… branch de recuperação.", S.LEFT, MOON, "LUA"),
		CutsceneBeat.make(K.CAPTION, "", "Missão de resgate iniciada.", S.LEFT, SKY, ""),
	]
	beats[7].auto_advance_after = 2.5   # a legenda final aparece sozinha e segue pro jogo
	return beats
```

- [ ] **Step 3: Reescrever `cutscene_player.gd`** (render cross-cut, sem timer) — substituir o arquivo inteiro por:

```gdscript
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
```

- [ ] **Step 4: Reescrever `cutscene_player.tscn`** (layout cross-cut) — substituir o arquivo inteiro por:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://cutscene_player.gd" id="1"]

[node name="CutscenePlayer" type="CanvasLayer"]
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0, 0, 0, 1)

[node name="Scene" type="Control" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0

[node name="LocationLabel" type="Label" parent="Scene"]
anchor_right = 1.0
offset_top = 40.0
offset_bottom = 84.0
horizontal_alignment = 1
theme_override_font_sizes/font_size = 30

[node name="Avatar" type="Panel" parent="Scene"]
anchor_left = 0.5
anchor_right = 0.5
offset_left = -160.0
offset_top = 300.0
offset_right = 160.0
offset_bottom = 620.0

[node name="Initial" type="Label" parent="Scene/Avatar"]
anchor_right = 1.0
anchor_bottom = 1.0
horizontal_alignment = 1
vertical_alignment = 1
theme_override_font_sizes/font_size = 150

[node name="Art" type="TextureRect" parent="Scene/Avatar"]
visible = false
anchor_right = 1.0
anchor_bottom = 1.0
expand_mode = 1
stretch_mode = 5

[node name="SubtitleBox" type="Panel" parent="Scene"]
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 40.0
offset_top = -320.0
offset_right = -40.0
offset_bottom = -130.0

[node name="SpeakerName" type="Label" parent="Scene/SubtitleBox"]
offset_left = 24.0
offset_top = 12.0
offset_right = 400.0
offset_bottom = 46.0
theme_override_font_sizes/font_size = 26

[node name="SubtitleText" type="RichTextLabel" parent="Scene/SubtitleBox"]
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 24.0
offset_top = 52.0
offset_right = -24.0
offset_bottom = -20.0
theme_override_font_sizes/normal_font_size = 26

[node name="AnswerButton" type="Button" parent="Scene"]
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

[node name="SkipButton" type="Button" parent="Scene"]
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

- [ ] **Step 5: Atualizar `tests/test_cutscene_data.gd`** (assertar `location`) — substituir o arquivo inteiro por:

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
	ok = _check(beats[1].location == "LUA", "beat 1 (Carlos) deve ser ambiente LUA") and ok
	ok = _check(beats[2].location == "TERRA — seu quarto", "beat 2 (Você) deve ser ambiente TERRA") and ok
	ok = _check(beats[5].speaker == "GUS", "beat 5 deve ser o GUS") and ok
	ok = _check(beats[5].location == "LUA", "beat 5 (Gus) deve ser ambiente LUA") and ok
	ok = _check(beats[7].kind == CutsceneBeat.Kind.CAPTION, "beat 7 deve ser CAPTION") and ok
	ok = _check(beats[7].text == "Missão de resgate iniciada.", "legenda final errada") and ok
	ok = _check(beats[7].auto_advance_after > 0.0, "legenda final deve auto-avançar") and ok
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

- [ ] **Step 6: Atualizar `tests/test_cutscene_player.gd`** (node-paths dos botões `Scene/...`) — substituir o arquivo inteiro por:

```gdscript
extends SceneTree
## Teste headless da lógica do CutscenePlayer. Rodar:
##   Godot --headless --script res://tests/test_cutscene_player.gd

func _initialize() -> void:
	var ok := true

	var scene: PackedScene = load("res://cutscene_player.tscn")

	var d1 := CutsceneBeat.make(CutsceneBeat.Kind.DIALOGUE, "CARLOS", "oi", CutsceneBeat.PortraitSide.LEFT, Color.BLACK, "LUA")
	var d2 := CutsceneBeat.make(CutsceneBeat.Kind.DIALOGUE, "VOCÊ", "tchau", CutsceneBeat.PortraitSide.RIGHT, Color.BLACK, "TERRA")
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
	(player4.get_node("Scene/SkipButton") as Button).pressed.emit()
	ok = _check(done4["v"], "SkipButton deveria disparar skip()->finished") and ok

	# 5) AnswerButton.pressed -> advance() a partir do CALL, depois dirige até o fim
	var player5: CutscenePlayer = scene.instantiate()
	get_root().add_child(player5)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo
	var done5 := {"v": false}
	player5.finished.connect(func(): done5["v"] = true)
	player5.play(caption_beats)
	(player5.get_node("Scene/AnswerButton") as Button).pressed.emit()
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

- [ ] **Step 7: Importar e rodar a suíte headless — tudo verde**

Run:
```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --import --quit 2>&1 | grep -iE "error|parse" | grep -vi "0 error"   # esperado: vazio
$GODOT --headless --script res://tests/test_cutscene_data.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL|FAIL:"      # esperado: TEST_OK
$GODOT --headless --script res://tests/test_cutscene_player.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL|FAIL:|SCRIPT ERROR"  # esperado: TEST_OK só
$GODOT --headless res://intro.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|nil|invalid"      # esperado: vazio
$GODOT --headless res://main.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|nil|invalid"       # esperado: vazio
```
Expected: `test_cutscene_data` e `test_cutscene_player` = `TEST_OK`; greps de erro vazios. Se algo falhar (node-path `Scene/...` divergente, etc.), corrigir e repetir.

- [ ] **Step 8: Commit**

```bash
git add cutscene_beat.gd cutscene_beat.gd.uid cutscene_intro.gd cutscene_intro.gd.uid cutscene_player.gd cutscene_player.gd.uid cutscene_player.tscn tests/test_cutscene_data.gd tests/test_cutscene_data.gd.uid tests/test_cutscene_player.gd tests/test_cutscene_player.gd.uid
git commit -m "feat(integration): cross-cut environment cutscene (location per beat)"
```

---

## Task 2: Verificação final + devlog

**Files:**
- Modify: `.claude/devlog/integration.md`

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

Ler o `.claude/devlog/integration.md` p/ manter o formato (entradas mais recentes no topo) e adicionar uma entrada nova (2026-07-03) descrevendo: a cutscene virou **cross-cut** — corta pro ambiente de quem fala (Carlos/Gus → LUA, Você → TERRA/quarto em SP), mantendo beat 0 "recebendo chamada" e legenda final; `CutsceneBeat` ganhou `location`, definido por beat no `cutscene_intro.gd`; o timer de chamada do redesign anterior foi removido; só `cutscene_beat.gd`/`cutscene_intro.gd`/`cutscene_player.gd`/`.tscn` (+ testes) mudaram; contrato `GameEvents` inalterado; resultados headless; e que o **playtest manual F5 / validação no editor continua PENDENTE** (interativo; + lição do time de que headless não pega `.tscn` que derruba o editor). Itens do checklist F5:
- Recebe chamada ("CARLOS") com botão Atender; tocar também atende.
- Cada fala corta pro ambiente do falante: LUA (Carlos/Gus) e TERRA/quarto (Você), com rótulo do local + avatar + legenda typewriter.
- Botão Pular encerra a qualquer momento.
- Legenda final "Missão de resgate iniciada." (fundo azul) → entra no `main.tscn`.
- Layout cabe bem em 720×1280 (nada cortado).

- [ ] **Step 3: Commit**

```bash
git add .claude/devlog/integration.md
git commit -m "docs(integration): devlog da cutscene cross-cut"
```

---

## Notas de execução

- **`@onready` vs `.tscn`:** os caminhos em `cutscene_player.gd` agora são `$Scene/...` (não mais `$CallUI/...`). Precisam bater com `cutscene_player.tscn`. Divergência = crash no load → `test_cutscene_player.gd` pega.
- **Import antes de script/cena** sempre; commitar `.uid`.
- **Validação no editor:** headless não garante que a `.tscn` abre no editor. Deixar o playtest F5 (humano) como gate antes do merge.
- **Offsets do `.tscn`** são ponto de partida p/ 720×1280; afinamento fino pode ser feito no editor no playtest.
