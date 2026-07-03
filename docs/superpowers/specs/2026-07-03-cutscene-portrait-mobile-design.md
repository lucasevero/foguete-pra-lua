# Design — Cutscene mobile/portrait "tela de chamada" (redesign da CENA 1)

**Data:** 2026-07-03
**Área:** integration (Dev D)
**Contexto:** o jogo virou mobile/portrait na Fase 2 (`project.godot` = 720×1280,
`handheld/orientation="portrait"`, `stretch=canvas_items`). A cutscene de abertura
foi construída para 1152×648 paisagem e precisa ser redesenhada para retrato.

## Objetivo

Redesenhar o `CutscenePlayer` para o formato retrato mobile, abraçando o conceito de
que a abertura é uma **ligação telefônica** — a tela em pé vira o próprio celular. O
arco visual: **recebendo chamada → em chamada → desliga e corta pro foguete**.

Decisões já validadas:
- Composição: **tela de chamada nativa** (não visual-novel genérico nem chat).
- Input: **touch-first** (tocar avança; botões Atender/Pular; ESC/Espaço mantidos p/ desktop).
- Placeholders trocáveis por arte, como antes.
- **Sem mudança de dados nem de contrato**: `cutscene_beat.gd`, `cutscene_intro.gd`,
  `game_events.gd`, `CONTRACT.md` ficam intactos. Mesmos 8 beats, mesmo texto PT-BR.

## Escopo

Muda apenas a camada de apresentação do player reutilizável:
- **Reescrita:** `cutscene_player.tscn` (layout retrato com âncoras responsivas).
- **Reescrita da apresentação:** `cutscene_player.gd` (render por `kind`, avatar único,
  timer de chamada, botões). A máquina de beats (índice, typewriter, `advance`/`skip`,
  `finished`, auto-advance) permanece igual, com **API pública intacta**.
- **Intocados:** `cutscene_beat.gd`, `cutscene_intro.gd`, `intro.gd`, `intro.tscn`,
  `project.godot`, `game_events.gd`, e todos os arquivos de gameplay de outras áreas.

## Fluxo de telas (mapeado nos beats existentes)

| Beat | kind | Tela |
|------|------|------|
| 0 | CALL | **Recebendo chamada**: nome grande "CARLOS", texto "CARLOS chamando…" (de `beat.text`), avatar placeholder, botão verde **Atender**. Sem timer/legenda. |
| 1–6 | DIALOGUE | **Em chamada**: TopBar (rótulo "chamada" + nome do falante + **timer** contando), **avatar grande do falante** (troca por `beat.speaker`), **legenda** no rodapé com typewriter. Botão **Pular**. |
| 7 | CAPTION | **Moldura de chamada some** (ligação "desligou"): legenda central "Missão de resgate iniciada." sobre fundo azul-céu, fade-in. Depois → `main.tscn`. |

Regras:
- O **timer da ligação** começa a contar quando o beat CALL é atendido (primeiro
  avanço a partir do CALL) e é exibido nos beats DIALOGUE como `M:SS` (cosmético).
- No beat CAPTION, `CallUI` inteiro fica invisível; só `Background` (cor do beat =
  azul-céu) + `Caption` aparecem.
- Quando **Gus** fala ("ao fundo"), o avatar troca para o Gus (cor placeholder dele) e
  o nome mostra "GUS" — regra do funny; single-avatar já faz isso via `beat.speaker`.

## Layout responsivo (`cutscene_player.tscn`)

Raiz `CanvasLayer`. Tudo com **âncoras relativas** (não offsets fixos) p/ escalar em
720×1280 e outras resoluções:

```
CutscenePlayer (CanvasLayer)                     [script: cutscene_player.gd]
├─ Background   (ColorRect)   anchors full-rect
├─ CallUI       (Control)     anchors full-rect  — a "moldura de chamada"
│  ├─ TopBar        (Panel)   ancorado no topo, full-width, altura fixa ~140px
│  │  ├─ CallLabel  (Label)   "chamada"           (topo, centralizado)
│  │  ├─ Speaker    (Label)   nome do falante     (grande, centralizado)
│  │  └─ CallTimer  (Label)   "0:07"              (abaixo do nome / canto)
│  ├─ Avatar        (Panel)   centro-topo, ~40% da largura, quadrado
│  │  ├─ Initial    (Label)   inicial do falante  (placeholder, centralizado)
│  │  └─ Art        (TextureRect) escondido; usado quando houver arte
│  ├─ SubtitleBox   (Panel)   ancorado no rodapé, full-width com margem
│  │  └─ SubtitleText (RichTextLabel) typewriter (visible_ratio)
│  ├─ AnswerButton  (Button)  "Atender", centralizado-baixo (só visível no CALL)
│  └─ SkipButton    (Button)  "Pular", canto superior direito
├─ Caption      (Label)       anchors full-rect, centralizado (só no CAPTION)
└─ Audio        (AudioStreamPlayer)
```

Placeholders: `Avatar` sem textura → `Initial` (inicial do falante) sobre `Panel`
tingido pela cor do falante; com textura → `Art` visível. Botões são `Button`s reais
com texto. Sem arquivos de imagem novos.

## Input (touch-first)

- **Tocar em qualquer lugar** (fora dos botões) = `advance()` — via `_unhandled_input`
  tratando `InputEventMouseButton` (o toque emula mouse, como no resto do jogo). Durante
  o typewriter completa a linha; senão vai pro próximo beat.
- **AnswerButton.pressed** → `advance()` (atende e segue). **SkipButton.pressed** →
  `skip()`. Como são `Button`s, consomem o próprio toque e **não** disparam o
  "tocar em qualquer lugar" (o clique de GUI não chega ao `_unhandled_input`).
- `ui_accept` (Espaço/Enter) e `ui_cancel` (ESC) mantidos para teste no desktop.
- **Sem novas input actions** no `project.godot`.

## `cutscene_player.gd` — mudanças

Mantém: `class_name CutscenePlayer extends CanvasLayer`, `signal finished`,
`@export var beats`, `play()`, `advance()`, `skip()`, `_next()`, typewriter
(`_start_typing`/`_finish_typing`), `_arm_auto_advance` (guarda contra double-fire),
`_cleanup()`, `_unhandled_input`.

Muda a apresentação:
- `_show_beat` roteia por `kind` para `_show_call` / `_show_dialogue` / `_show_caption`,
  cada um mostrando/escondendo os nós certos (CallUI vs Caption; AnswerButton só no CALL).
- `_show_call`: `CallUI` visível, TopBar/timer/legenda escondidos, `AnswerButton` visível,
  avatar = falante, texto grande = `beat.text` (fallback "%s chamando…").
- `_show_dialogue`: TopBar visível (Speaker = `beat.speaker`, CallTimer = tempo formatado),
  `AnswerButton` escondido, avatar troca p/ `beat.speaker`, `SubtitleText` faz typewriter.
- `_show_caption`: `CallUI` invisível, `Background.color = beat.background_color`,
  `Caption` visível com fade (tween em `modulate:a`).
- **Timer de chamada:** `var _call_seconds := 0.0`; começa a acumular em `_process`
  quando saímos do CALL (flag `_in_call`); `CallTimer.text` = `"%d:%02d"`. Cosmético,
  não afeta a lógica de avanço.
- `SkipButton` fica visível em CALL e DIALOGUE; escondido no CAPTION (já quase acabou).
- Conecta `AnswerButton.pressed`/`SkipButton.pressed` no `_ready`.

Cores placeholder por falante: mantém o dicionário `SPEAKER_COLORS` (CARLOS/GUS/VOCÊ)
+ default. Aplica no `Avatar`.

## Dados & contrato

- `cutscene_beat.gd` / `cutscene_intro.gd`: **sem mudança**. `portrait_side` fica sem
  uso (avatar único) — mantido por compatibilidade e para a CENA 2.
- `game_events.gd` / `CONTRACT.md`: **sem mudança**. A cutscene continua isolada.

## Testes / verificação

- **Headless (rodar antes de commitar):**
  1. `--headless --import --quit` → sem erro/parse.
  2. `--headless --script res://tests/test_cutscene_data.gd` → `TEST_OK` (inalterado).
  3. `--headless --script res://tests/test_cutscene_player.gd` → `TEST_OK`. A API é a
     mesma; o teste dirige `play/advance/skip` e checa `finished`. Ajustar só se um
     node-path referenciado no teste mudar. Reforçar cobertura CALL + CAPTION.
  4. `--headless res://intro.tscn --quit-after 120` → sem `SCRIPT ERROR|nil|invalid`
     (para no CALL esperando toque — esperado headless).
  5. `--headless res://main.tscn --quit-after 120` → sem erros.
- **Manual (F5, humano):** recebe chamada → Atender → diálogo com avatar trocando +
  timer contando → Pular funciona → ao final desliga, legenda azul, entra no gameplay.
  Conferir que o layout cabe bonito em 720×1280 (nada cortado).

## Fora de escopo

- Arte/áudio finais (continuam placeholders).
- CENA 2 (final) — reaproveita o mesmo player depois.
- Tela de decline/recusar a chamada (a cutscene precisa prosseguir; só "Atender").
