# Cutscene final (CENA 2 — a chegada) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar a cutscene final (CENA 2 — a chegada), que toca ao vencer (chegar na Lua), reaproveitando o `CutscenePlayer` cross-cut, e disparada pelo `game_manager._end(true)`.

**Architecture:** Nova fonte de dados `CutsceneFinal.build()` (beats do roteiro) + 2 backgrounds pixel-art novos (`moon_surface`, `moon_sit`) + pequeno ajuste no `CutscenePlayer` (avatar/nome opcionais por beat, p/ os planos de ação/wide-shot) + hook no `game_manager._end(true)` que instancia o player com `CutsceneFinal.build()`. Sem mudança de contrato (reusa `game_over` + `cutscene_started`).

**Tech Stack:** Godot 4.7, GDScript, `.tscn`. Testes headless `extends SceneTree` + smoke.

## Global Constraints

- **Godot 4.7 exato.** Binário: `/Applications/Godot.app/Contents/MacOS/Godot`.
- **Área: integration (Dev D).** Arquivos novos são da minha área; `game_manager.gd` é **compartilhado** (outro dev edita) → commit + **push rápido** + aviso no devlog.
- **NÃO tocar:** `game_events.gd`/`CONTRACT.md` (sem novo signal), `cutscene_beat.gd`, `cutscene_intro.gd`, e arquivos de gameplay de outras áreas.
- **API pública do CutscenePlayer inalterada** (`play`/`advance`/`skip`/`finished`).
- Texto PT-BR **verbatim** do roteiro. Legenda final **sem emoji** (fonte pixel não renderiza).
- **Sempre commitar `.uid`** ao lado de cada `.gd` novo; `.import` dos PNGs. Import antes de rodar script/cena.
- **Import antes** de `--script`/cena (registra `class_name`).

---

## File Structure

| Arquivo | Mudança |
|---------|---------|
| `assets/cutscenes/generate_final_bgs.py` | Novo — gera os 2 fundos |
| `assets/cutscenes/moon_surface.png` (+`.import`) | Novo — exterior lunar + foguete + Terra |
| `assets/cutscenes/moon_sit.png` (+`.import`) | Novo — os três sentados na Lua |
| `cutscene_final.gd` | Novo — `CutsceneFinal.build()` (beats CENA 2) |
| `cutscene_player.gd` | Modificar `_show_dialogue` (avatar/nome opcionais) |
| `game_manager.gd` | Modificar `_end` + add `_play_final_cutscene` (⚠️ compartilhado) |
| `tests/test_cutscene_final.gd` | Novo — teste headless dos dados |

---

## Task 1: Backgrounds da CENA 2 (moon_surface + moon_sit)

**Files:**
- Create: `assets/cutscenes/generate_final_bgs.py`
- Create (gerados): `assets/cutscenes/moon_surface.png`, `assets/cutscenes/moon_sit.png` (+ `.import`)

**Interfaces:**
- Produces: `res://assets/cutscenes/moon_surface.png`, `res://assets/cutscenes/moon_sit.png` (Texture2D, 90×160).

- [ ] **Step 1: Escrever `assets/cutscenes/generate_final_bgs.py`**

```python
#!/usr/bin/env python3
"""Gera os backgrounds da CENA 2 (final), SEM dependências (encoder PNG stdlib).
Rode: python3 generate_final_bgs.py
- moon_surface.png : exterior lunar + foguete gambiarra pousado + Terra no céu.
- moon_sit.png     : plano aberto, os três sentados na Lua, Terra brilhando.
Baixa resolução 90x160 (escala nearest no Godot). Placeholder reproduzível.
"""
import os, zlib, struct, math

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 90, 160

SPACE  = (7, 8, 18, 255)
STAR   = (232, 240, 255, 255)
STARD  = (150, 165, 200, 255)
MOON_D = (104, 104, 122, 255)
MOON   = (150, 150, 166, 255)
MOON_L = (192, 192, 206, 255)
EARTH_B= (58, 128, 200, 255)
EARTH_G= (92, 170, 120, 255)
EARTH_L= (150, 200, 235, 255)
STEEL  = (52, 58, 82, 255)
STEEL_L= (86, 96, 130, 255)
INK    = (18, 18, 30, 255)
TAPE   = (206, 184, 128, 255)
GREEN  = (190, 228, 30, 255)
SKIN   = (214, 150, 110, 255)
HELMET = (210, 214, 224, 255)
CARLOS_C = (200, 90, 70, 255)
LUCA_C   = (90, 120, 200, 255)
GUS_C    = (90, 180, 110, 255)

STARS = [(10, 20), (22, 14), (34, 24), (50, 12), (63, 22), (75, 16),
         (14, 40), (40, 46), (56, 40), (70, 50), (82, 34), (28, 58)]


def blank():
    return [[(0, 0, 0, 0) for _ in range(W)] for _ in range(H)]

def rect(g, x0, y0, x1, y1, c):
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(max(0, x0), min(W, x1 + 1)):
            g[y][x] = c

def px(g, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = c

def disc(g, cx, cy, r, c):
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                px(g, x, y, c)

def earth(g, cx, cy, r):
    disc(g, cx, cy, r, EARTH_B)
    for dx, dy, rr in [(-3, -2, 2), (2, 1, 3), (-1, 4, 2), (4, -3, 1), (-4, 2, 1)]:
        disc(g, cx + dx, cy + dy, rr, EARTH_G)
    for a in range(200, 265, 6):
        rad = math.radians(a)
        px(g, cx + int(r * math.cos(rad)), cy + int(r * math.sin(rad)), EARTH_L)

def ground(g, top):
    rect(g, 0, top, W - 1, H - 1, MOON_D)
    for x in range(W):
        h = top - (1 if (x // 4) % 2 else 0)
        rect(g, x, h, x, top - 1, MOON)

def rocket(g, x, y):
    rect(g, x, y, x + 12, y + 34, STEEL)
    rect(g, x, y, x + 3, y + 34, STEEL_L)
    rect(g, x + 2, y - 6, x + 10, y, STEEL)
    rect(g, x + 4, y - 9, x + 8, y - 6, STEEL_L)
    disc(g, x + 6, y + 10, 3, GREEN)
    px(g, x + 6, y + 9, INK)
    rect(g, x + 3, y + 20, x + 9, y + 24, TAPE)
    for i in range(5):
        px(g, x - 1 - i, y + 30 + i, STEEL)
        px(g, x + 13 + i, y + 30 + i, STEEL)
    rect(g, x, y + 34, x + 12, y + 35, INK)

def sit_figure(g, x, base, col):
    rect(g, x - 3, base - 5, x + 3, base - 1, col)   # tronco
    rect(g, x - 4, base - 1, x + 4, base, col)       # pernas dobradas
    disc(g, x, base - 7, 2, SKIN)                    # cabeça
    px(g, x, base - 9, INK)                          # cabelo
    disc(g, x + 6, base - 1, 2, HELMET)              # capacete ao lado
    px(g, x + 6, base - 2, STEEL)

def stars(g):
    for i, (sx, sy) in enumerate(STARS):
        px(g, sx, sy, STAR if i % 3 else STARD)

def write_png(path, g):
    raw = bytearray()
    for y in range(H):
        raw.append(0)
        for x in range(W):
            raw += bytes(g[y][x])
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))
    ihdr = struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
                + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))

def build_surface():
    g = blank()
    rect(g, 0, 0, W - 1, H - 1, SPACE)
    stars(g)
    earth(g, 22, 34, 12)
    ground(g, 112)
    disc(g, 18, 132, 5, MOON_D); disc(g, 62, 142, 6, MOON_D)
    rocket(g, 56, 74)
    for x in range(50, 78, 3):
        px(g, x, 117, MOON_L)
    return g

def build_sit():
    g = blank()
    rect(g, 0, 0, W - 1, H - 1, SPACE)
    stars(g)
    earth(g, 45, 40, 20)
    ground(g, 122)
    disc(g, 14, 142, 6, MOON_D); disc(g, 72, 146, 7, MOON_D)
    sit_figure(g, 32, 120, CARLOS_C)
    sit_figure(g, 46, 120, LUCA_C)
    sit_figure(g, 60, 120, GUS_C)
    return g

write_png(os.path.join(HERE, "moon_surface.png"), build_surface())
write_png(os.path.join(HERE, "moon_sit.png"), build_sit())
print("wrote moon_surface.png e moon_sit.png (%dx%d)" % (W, H))
```

- [ ] **Step 2: Gerar os PNGs e importar**

Run:
```bash
cd assets/cutscenes && python3 generate_final_bgs.py && cd ../..
/Applications/Godot.app/Contents/MacOS/Godot --headless --import --quit 2>&1 | grep -iE "error|parse|failed" | grep -viE "0 error|p_position" || echo "import OK"
ls assets/cutscenes/moon_surface.png.import assets/cutscenes/moon_sit.png.import
```
Expected: `wrote moon_surface.png e moon_sit.png (90x160)`; `import OK`; os dois `.import` existem.

- [ ] **Step 3: Commit**

```bash
git add assets/cutscenes/generate_final_bgs.py assets/cutscenes/moon_surface.png assets/cutscenes/moon_surface.png.import assets/cutscenes/moon_sit.png assets/cutscenes/moon_sit.png.import
git commit -m "feat(integration): backgrounds da CENA 2 (moon_surface, moon_sit)"
```

---

## Task 2: Dados CENA 2 (`CutsceneFinal`) + ajuste no player + teste

**Files:**
- Create: `cutscene_final.gd`
- Modify: `cutscene_player.gd` (função `_show_dialogue`)
- Create: `tests/test_cutscene_final.gd`

**Interfaces:**
- Consumes: `CutsceneBeat` (`make`, campos), `CutscenePlayer` (render por beat), os 3 backgrounds (Task 1 + `lua_bg`), retratos existentes.
- Produces: `CutsceneFinal.build() -> Array[CutsceneBeat]` (9 beats).

- [ ] **Step 1: Ajustar `_show_dialogue` em `cutscene_player.gd`** (avatar/nome opcionais por beat) — substituir a função inteira por:

```gdscript
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
```

- [ ] **Step 2: Escrever `cutscene_final.gd`**

```gdscript
class_name CutsceneFinal
## Dados da CENA 2 (final — a chegada). Fonte: roteiro do time.
## Área: integration. Reaproveita o CutscenePlayer.

const MOON := Color(0.11, 0.12, 0.18)     # fallback (interior/espaço)
const GROUND := Color(0.10, 0.11, 0.18)   # fallback (exterior lunar)

const CARLOS_1 := preload("res://assets/cutscenes/carlos1.png")
const CARLOS_2 := preload("res://assets/cutscenes/carlos2.png")
const GUS_2 := preload("res://assets/cutscenes/gus2.png")
const LUCA_1 := preload("res://assets/cutscenes/luca1.png")
const LUA_BG := preload("res://assets/cutscenes/lua_bg.png")
const MOON_SURFACE := preload("res://assets/cutscenes/moon_surface.png")
const MOON_SIT := preload("res://assets/cutscenes/moon_sit.png")

static func build() -> Array[CutsceneBeat]:
	var K := CutsceneBeat.Kind
	var S := CutsceneBeat.PortraitSide
	var beats: Array[CutsceneBeat] = [
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "CARA! Eu sabia que você vinha! Salvou a gente!", S.LEFT, GROUND, ""),
		CutsceneBeat.make(K.DIALOGUE, "LUCA", "Bora voltar pra casa.", S.RIGHT, GROUND, ""),
		CutsceneBeat.make(K.DIALOGUE, "", "(Todos entram. Ignição… o motor tosse. Tenta de novo. Silêncio.)", S.LEFT, MOON, ""),
		CutsceneBeat.make(K.DIALOGUE, "GUS", "Ãhn… Carlos.", S.RIGHT, MOON, ""),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "Que foi.", S.LEFT, MOON, ""),
		CutsceneBeat.make(K.DIALOGUE, "GUS", "Esse foguete também não tem a volta codada.", S.RIGHT, MOON, ""),
		CutsceneBeat.make(K.DIALOGUE, "", "(Os três, sentados na Lua. Capacetes na mão. A Terra, brilhando.)", S.LEFT, GROUND, ""),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "…Alguém trouxe o lanche?", S.LEFT, GROUND, ""),
		CutsceneBeat.make(K.CAPTION, "", "Missão de resgate: concluída.\nMissão de retorno: não implementada.\n// TODO: codar a volta", S.LEFT, GROUND, ""),
	]
	beats[0].portrait = CARLOS_1
	beats[1].portrait = LUCA_1
	beats[3].portrait = GUS_2
	beats[4].portrait = CARLOS_2
	beats[5].portrait = GUS_2
	# beats 2, 6, 7, 8 sem retrato (ação / wide-shot / legenda)
	beats[0].background = MOON_SURFACE
	beats[1].background = MOON_SURFACE
	beats[2].background = LUA_BG
	beats[3].background = LUA_BG
	beats[4].background = LUA_BG
	beats[5].background = LUA_BG
	beats[6].background = MOON_SIT
	beats[7].background = MOON_SIT
	beats[8].background = MOON_SIT
	return beats
```

- [ ] **Step 3: Escrever `tests/test_cutscene_final.gd`**

```gdscript
extends SceneTree
## Teste headless dos dados da CENA 2. Rodar:
##   Godot --headless --script res://tests/test_cutscene_final.gd

func _initialize() -> void:
	var ok := true
	var beats := CutsceneFinal.build()
	ok = _check(beats.size() == 9, "esperava 9 beats, veio %d" % beats.size()) and ok
	ok = _check(beats[0].speaker == "CARLOS", "beat 0 deve ser CARLOS") and ok
	ok = _check(beats[1].speaker == "LUCA", "beat 1 deve ser LUCA") and ok
	ok = _check(beats[2].speaker == "", "beat 2 (ação) deve ter speaker vazio") and ok
	ok = _check(beats[7].text == "…Alguém trouxe o lanche?", "beat 7 (lanche) errado") and ok
	ok = _check(beats[8].kind == CutsceneBeat.Kind.CAPTION, "beat 8 deve ser CAPTION") and ok
	ok = _check(beats[8].text.contains("TODO: codar a volta"), "legenda final deve ter o TODO") and ok
	if ok:
		print("TEST_OK test_cutscene_final")
		quit(0)
	else:
		printerr("TEST_FAIL test_cutscene_final")
		quit(1)

func _check(cond: bool, msg: String) -> bool:
	if not cond:
		printerr("  FAIL: " + msg)
	return cond
```

- [ ] **Step 4: Importar e rodar a suíte**

Run:
```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --import --quit 2>&1 | grep -iE "SCRIPT ERROR|error|parse|failed" | grep -viE "0 error|p_position" || echo "import OK"
$GODOT --headless --script res://tests/test_cutscene_final.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL|FAIL:|SCRIPT ERROR"
$GODOT --headless --script res://tests/test_cutscene_data.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL"
$GODOT --headless --script res://tests/test_cutscene_player.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL|SCRIPT ERROR"
```
Expected: `import OK`; `TEST_OK test_cutscene_final`; os outros dois `TEST_OK` (sem regressão). Se falhar (preload de bg errado, etc.), corrigir e repetir.

- [ ] **Step 5: Commit**

```bash
git add cutscene_final.gd cutscene_final.gd.uid cutscene_player.gd tests/test_cutscene_final.gd tests/test_cutscene_final.gd.uid
git commit -m "feat(integration): CENA 2 data (CutsceneFinal) + player sem retrato por beat"
```

---

## Task 3: Hook na vitória (`game_manager.gd`) + verificação + devlog

**Files:**
- Modify: `game_manager.gd` (função `_end` + nova `_play_final_cutscene`)
- Modify: `.claude/devlog/integration.md`

**Interfaces:**
- Consumes: `CutsceneFinal.build()` (Task 2), `CutscenePlayer` (const `CUTSCENE` já existe no game_manager), signals `cutscene_started` + `game_over` (já no contrato).

- [ ] **Step 1: Substituir `_end` em `game_manager.gd` e adicionar `_play_final_cutscene`**

Trocar a função `_end` atual:
```gdscript
func _end(won: bool) -> void:
	if not running:
		return
	running = false
	GameEvents.game_over.emit(won)   # UI mostra o botão REINICIAR (process_mode=ALWAYS)
	get_tree().paused = true         # congela o jogo (player, spawners, asteroides)
```
por:
```gdscript
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
```

- [ ] **Step 2: Importar e verificar a suíte completa (sem regressão)**

Run:
```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --import --quit 2>&1 | grep -iE "SCRIPT ERROR|error|parse|failed" | grep -viE "0 error|p_position" || echo "import OK"
$GODOT --headless --script res://tests/test_cutscene_final.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL"
$GODOT --headless --script res://tests/test_cutscene_data.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL"
$GODOT --headless --script res://tests/test_cutscene_player.gd 2>&1 | grep -E "TEST_OK|TEST_FAIL"
$GODOT --headless res://main.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|nil|invalid" | grep -viE "p_position" || echo "main OK"
```
Expected: `import OK`; três `TEST_OK`; `main OK`. (A CENA 2 só dispara ao vencer — não é exercitada pelo smoke; validação real é no F5.)

- [ ] **Step 3: Registrar no devlog `.claude/devlog/integration.md`**

Ler o `.claude/devlog/integration.md` (formato, entradas mais recentes no topo) e adicionar entrada nova (2026-07-03): CENA 2 (final) toca ao **vencer** — `game_manager._end(true)` instancia o `CutscenePlayer` com `CutsceneFinal.build()` (mesma receita do `_play_cutscene` de abertura, `process_mode=ALWAYS`), e ao terminar dispara `game_over(true)`; 2 backgrounds novos (`moon_surface`, `moon_sit`), reaproveita retratos + `lua_bg`; ajuste no player p/ beats sem retrato/nome (planos de ação/wide-shot); **⚠️ mexi no `game_manager.gd` (compartilhado)** — avisar o time; **sem mudança de contrato**; playtest F5 (ganhar) pendente.

- [ ] **Step 4: Commit**

```bash
git add game_manager.gd .claude/devlog/integration.md
git commit -m "feat(integration): dispara CENA 2 ao vencer (hook no game_manager._end)"
```

---

## Notas de execução

- **Import antes** de rodar `--script`/cena (registra `CutsceneFinal`). Commitar `.uid`/`.import`.
- **`game_manager.gd` é compartilhado** — após a Task 3, o controller deve fazer push rápido pra minimizar janela de conflito com o outro Dev D.
- **Retratos são poses "no telefone"** — por isso os planos finais (beats 6–8) não usam retrato. Substituíveis por retratos dedicados depois.
- **F5 (validação real):** vencer a partida (chegar na Lua) dispara a CENA 2 → ao final, game over/REINICIAR. Conferir os 2 fundos novos e o timing.
