# Design — Cutscene Player reutilizável + CENA 1 (abertura)

**Data:** 2026-07-03
**Área:** integration (Dev D) — arquivos novos + 1 linha em `project.godot`
**Fonte narrativa:** Notion "Storytelling" (CENA 1 — A ligação do Carlos)

## Objetivo

Adicionar a cutscene de abertura do jogo (a ligação do Carlos pedindo resgate) sem
tocar em nenhum sistema de gameplay. A peça central é um **CutscenePlayer genérico e
data-driven**, para que a CENA 2 (final/chegada) seja depois só mais um arquivo de
dados + um gatilho no `game_over(won)`.

Decisões já validadas com o usuário:
- Fidelidade: **cutscene animada** (retratos, caixa de diálogo, legenda, áudio) — não texto cru.
- Assets: **placeholder agora, arte depois** — tudo em slots trocáveis, sem arquivos de imagem novos nesta entrega.
- Escopo: **player reutilizável + CENA 1**. CENA 2 fica fora desta entrega (mas o player já a suporta).

## Abordagem

Uma cena separada `intro.tscn` vira a nova `main_scene`. Ela roda a cutscene e, ao
terminar (ou ser pulada), faz `get_tree().change_scene_to_file("res://main.tscn")`.
O gameplay segue **intocado**: o `GameManager` continua auto-iniciando no `_ready()` do
`main.tscn` — só que agora isso acontece depois da abertura.

Alternativas descartadas:
- **Overlay dentro do `main.tscn`** (pausar o GameManager até a cutscene acabar): acopla
  a cutscene ao início do gameplay e obriga a mexer em `game_manager.gd`. Rejeitado.
- **Autoload SceneFlow (intro→jogo→final)**: mais escalável, mas adiciona autoload
  (arquivo compartilhado) e arquitetura que YAGNI para o protótipo. Rejeitado por ora.

## Arquivos (todos NOVOS, exceto 1 linha compartilhada)

```
intro.tscn / intro.gd          fluxo fino: hospeda o CutscenePlayer, transiciona pro main.tscn
cutscene_player.tscn / .gd     player reutilizável (CanvasLayer). Emite signal `finished`.
cutscene_beat.gd               class_name CutsceneBeat extends Resource — 1 "fala" tipada
cutscene_intro.gd              class_name CutsceneIntro — static build() -> Array[CutsceneBeat] (roteiro CENA 1)
```

**Compartilhado tocado:** `project.godot` → `run/main_scene` de `res://main.tscn` para
`res://intro.tscn` (1 linha). ⚠️ Combinar com o time; registrar em `.claude/devlog/integration.md`.

**Não tocado:** `game_events.gd` (contrato), `player.*`, `asteroid*`, `fuel*`,
`parallax_bg.*`, `game_manager.gd`, `ui.*`, `main.tscn`.

## Componentes

### CutscenePlayer (`cutscene_player.tscn` / `cutscene_player.gd`)
Raiz `CanvasLayer` full-rect (renderiza por cima de qualquer coisa — serve como cena
standalone e, no futuro, como overlay do final). Nós:
- `Background` — `ColorRect` full-rect (fallback). Recebe `Texture2D` do beat quando houver.
- `PortraitLeft` / `PortraitRight` — slots de retrato. Sem textura → `ColorRect` colorido
  com a inicial do falante (Label). Com textura → `TextureRect`.
- `DialogueBox` — `Panel` + `SpeakerName` (Label) + `DialogueText` (`RichTextLabel`, typewriter).
- `Caption` — `Label` central para legendas (kind CAPTION), com fade.
- `SkipHint` — Label discreto: "ESC pular".
- `Audio` — `AudioStreamPlayer` (stream vazio por ora).

API:
- `func play(beats: Array[CutsceneBeat]) -> void` — inicia a sequência.
- `signal finished` — emitido ao fim do último beat OU ao pular.
- Se `@export var beats` estiver preenchido, auto-toca no `_ready()` (permite testar a cena isolada no editor).

Estado interno: índice do beat atual, flag "linha totalmente revelada", Tween/Timer do typewriter.

### CutsceneBeat (`cutscene_beat.gd`)
`class_name CutsceneBeat extends Resource`. Campos exportados:
- `kind: Kind` — enum `{ CALL, DIALOGUE, CAPTION }`.
- `speaker: String` — nome do falante (ex.: "CARLOS", "VOCÊ", "GUS"; vazio p/ CAPTION).
- `text: String` (`@export_multiline`).
- `portrait: Texture2D` — retrato do falante (null = placeholder).
- `portrait_side: PortraitSide` — enum `{ LEFT, RIGHT }` (nome próprio p/ não colidir com o `Side` embutido do Godot).
- `background: Texture2D` — troca opcional de fundo neste beat (null = mantém).
- `sfx: AudioStream` — som opcional do beat (null = silêncio).
- `auto_advance_after: float` — 0 = espera input; >0 = avança sozinho após N segundos.

### intro (`intro.tscn` / `intro.gd`)
Raiz `Node` "Intro" com um filho = instância de `cutscene_player.tscn`. `intro.gd`:
1. No `_ready()`: `player.finished.connect(_on_finished)`; `player.play(CutsceneIntro.build())`.
2. `_on_finished()`: `get_tree().change_scene_to_file("res://main.tscn")`.

### CutsceneIntro (`cutscene_intro.gd`)
`class_name CutsceneIntro`. `static func build() -> Array[CutsceneBeat]` retorna os beats
da CENA 1 (abaixo), construídos em código — sem `.tres` hand-authored (mais robusto no
smoke headless e sem binário pra dar merge conflict). Promovível a `.tres` depois se
alguém quiser editar pelo inspector.

## Dados — CENA 1 (roteiro do Notion mapeado em beats)

| # | kind | speaker | text | notas |
|---|------|---------|------|-------|
| 1 | CALL | CARLOS | "CARLOS chamando…" | SFX vibração, fundo preto, *atender* = Espaço |
| 2 | DIALOGUE | CARLOS | "E aí, beleza? Então… eu e o Gus vibecodamos um foguete no fim de semana." | retrato esq |
| 3 | DIALOGUE | VOCÊ | "Vocês fizeram o quê?" | *(off, incrédulo)*, retrato dir |
| 4 | DIALOGUE | CARLOS | "Funcionou! A gente chegou na Lua! De verdade!" | |
| 5 | DIALOGUE | CARLOS | "É… só que a gente esqueceu de codar a volta." | |
| 6 | DIALOGUE | GUS | "FALA PRA ELE TRAZER LANCHE!" | *(ao fundo, abafado)* |
| 7 | DIALOGUE | CARLOS | "Dá pra vir buscar a gente? Cê é a nossa única… uh… branch de recuperação." | |
| 8 | CAPTION | — | "Missão de resgate iniciada." | fundo troca p/ céu azul da base; fade; depois `finished` |

## UX de controle

- **Avançar**: `ui_accept` (Espaço/Enter) ou clique do mouse.
  - Se o typewriter ainda está digitando → revela a linha inteira imediatamente.
  - Se a linha já está completa → avança para o próximo beat.
- **Pular tudo**: `ui_cancel` (ESC) → emite `finished` na hora.
- Usa apenas `ui_accept`/`ui_cancel` (ações padrão do Godot) → **não** adiciona input
  actions em `project.godot`.

## Placeholders → arte depois

- **Retratos**: slot `portrait: Texture2D`. Null → `ColorRect` colorido + inicial do
  falante. Cor por falante (mapa simples em `cutscene_player.gd`). Ao chegar a arte,
  atribui a textura no beat; nenhum código de lógica muda.
- **Backgrounds**: `ColorRect` de fallback (preto na ligação, azul-céu na legenda final).
  Slot `background: Texture2D` para a arte real.
- **Áudio**: `AudioStreamPlayer` com `stream` vazio. SFX por beat via campo `sfx`;
  música via `stream` do player. Silencioso até os arquivos existirem.

## Impacto no time / contrato

- **`game_events.gd` (contrato): nenhuma mudança.** A abertura é pré-jogo, não usa signals.
- **Outras áreas (physics/obstacles/pickups): zero impacto.** Só arquivos novos.
- **integration**: registrar no devlog; a troca de `run/main_scene` no `project.godot` é
  o único ponto compartilhado — avisar o time (regra de ouro do CLAUDE.md).

## Testes / verificação

Smoke headless (rodar antes de commitar; ver CLAUDE.md):
1. `--headless --import --quit` sem erros de parse.
2. Carregar a nova cena de abertura sem `SCRIPT ERROR`:
   `Godot --headless res://intro.tscn --quit-after 200 2>&1 | grep -iE "SCRIPT ERROR|error|nil|invalid"`
3. Smoke existente do `main.tscn` continua passando.
4. Verificação manual no editor (F5): ligação → diálogo com typewriter → avançar → pular
   com ESC → legenda final → carrega o `main.tscn` e o gameplay começa normal.

## Fora de escopo (futuro)

- **CENA 2 (final)**: outro `cutscene_final.gd` (build de beats) + instanciar o
  `CutscenePlayer` como overlay ao receber `game_over(won == true)`. Toca a área
  integration e o contrato existente (`game_over`), não o design do player.
- Arte/áudio finais.
- Dublagem/voz.
