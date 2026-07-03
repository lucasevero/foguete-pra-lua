# Design — Cutscene cross-cut (troca de ambiente por falante)

**Data:** 2026-07-03
**Área:** integration (Dev D)
**Itera sobre:** o redesign "tela de chamada" (`2026-07-03-cutscene-portrait-mobile-design.md`).
Após playtest, o time preferiu **mostrar os ambientes** de cada personagem em vez da UI
de celular pura. Formato segue portrait/mobile 720×1280.

## Objetivo

Transformar os beats de diálogo numa **montagem cross-cut**: uma cena por vez, em tela
cheia, mostrando **onde o falante está**. Corta pro ambiente de quem fala:
- **CARLOS / GUS → LUA** (superfície lunar + o foguete gambiarra deles).
- **VOCÊ → TERRA** (seu quarto/escritório em São Paulo — casa com o fundo de skyline de SP do time).

Beat 0 mantém a tela de **"recebendo chamada" + Atender** (o time gostou desse momento);
depois entra o cross-cut; no fim, a legenda "Missão de resgate iniciada." → gameplay.

## Decisões validadas
- Composição: **cross-cut** (um ambiente por vez, troca por falante). Não split-screen.
- Manter beat 0 como "recebendo chamada" (Atender).
- Input: **touch-first** (tocar avança; botões Atender/Pular; ESC/Espaço só desktop).
- **Data-driven**: o ambiente vem do beat (o player fica genérico, sem mapa fixo
  speaker→lugar) — serve pra CENA 2 depois.
- Placeholders trocáveis por arte (`assets/cutscenes/`); contrato `GameEvents` intocado.

## Mudança de dados

`cutscene_beat.gd` — adicionar um campo:
- `location: String = ""` — nome do ambiente exibido (rótulo placeholder agora; a cena/arte
  real entra depois via o campo já existente `background: Texture2D`).

`cutscene_intro.gd` — definir por beat `location` + `background_color` (placeholder do ambiente):
| Beat | speaker | kind | location | background_color (placeholder) |
|------|---------|------|----------|-------------------------------|
| 0 | CARLOS | CALL | "" (tela de chamada) | preto |
| 1 | CARLOS | DIALOGUE | "LUA" | cinza-espaço escuro |
| 2 | VOCÊ | DIALOGUE | "TERRA — seu quarto" | marrom-quente (indoor) |
| 3 | CARLOS | DIALOGUE | "LUA" | cinza-espaço escuro |
| 4 | CARLOS | DIALOGUE | "LUA" | cinza-espaço escuro |
| 5 | GUS | DIALOGUE | "LUA" | cinza-espaço escuro |
| 6 | CARLOS | DIALOGUE | "LUA" | cinza-espaço escuro |
| 7 | — | CAPTION | "" | azul-céu (como hoje) |

Cores placeholder sugeridas: LUA `Color(0.11, 0.12, 0.18)`, TERRA `Color(0.28, 0.20, 0.15)`,
azul-céu (mantém o `SKY` atual do `cutscene_intro.gd`). Texto PT-BR dos beats **inalterado**.

## Player (`cutscene_player.gd` + `.tscn`) — layout cross-cut

Raiz `CanvasLayer`. Nós (âncoras responsivas p/ 720×1280):
```
CutscenePlayer (CanvasLayer)                 [script]
├─ Background   (ColorRect)   full-rect      — o ambiente (cor placeholder / textura depois)
├─ Scene        (Control)     full-rect
│  ├─ LocationLabel (Label)   topo           — "LUA" / "TERRA — seu quarto" / "recebendo chamada"
│  ├─ Avatar        (Panel)   centro         — placeholder colorido do falante
│  │  ├─ Initial    (Label)                  — inicial do falante (placeholder)
│  │  └─ Art        (TextureRect) escondido  — retrato/arte quando houver
│  ├─ SubtitleBox   (Panel)   rodapé
│  │  ├─ SpeakerName (Label)                 — nome do falante
│  │  └─ SubtitleText (RichTextLabel)        — typewriter (visible_ratio)
│  ├─ AnswerButton  (Button "Atender")       — só no beat CALL
│  └─ SkipButton    (Button "Pular")         — canto sup. dir.
├─ Caption      (Label)       full-rect central — só no CAPTION
└─ Audio        (AudioStreamPlayer)
```

Render por `kind` (a máquina de beats/typewriter/skip/finished/auto-advance/API **fica igual**):
- **CALL** (beat 0): `Background` = `beat.background_color` (preto); `LocationLabel` =
  "recebendo chamada"; `SpeakerName` = `beat.speaker`; `Avatar` = falante; `SubtitleBox`
  escondido; `AnswerButton` visível; `SkipButton` visível.
- **DIALOGUE**: `Background` = `beat.background_color` (ambiente); `LocationLabel` =
  `beat.location`; `SpeakerName` = `beat.speaker`; `Avatar` = falante; `SubtitleBox`
  visível com typewriter de `beat.text`; `AnswerButton` escondido; `SkipButton` visível.
- **CAPTION**: `Scene` inteiro invisível (some com filhos, incl. SkipButton); `Background`
  = `beat.background_color` (azul); `Caption` visível com fade-in.

Remove o "timer de chamada" do redesign anterior (o cross-cut é sobre lugar, não sobre a
UI do telefone) — simplifica o `_process`/estado.

Avatar placeholder: `Avatar` sem textura → `Initial` (inicial do falante) sobre `Panel`
tingido por `SPEAKER_COLORS` (mantém o dicionário CARLOS/GUS/VOCÊ). Com `beat.portrait`
→ `Art` visível.

Input (inalterado do redesign): tocar/`ui_accept` = `advance()`; `AnswerButton`→advance;
`SkipButton`→skip; `ui_cancel` = skip. Sem novas input actions.

## API / contrato — inalterados
- Público: `class_name CutscenePlayer extends CanvasLayer`, `signal finished`,
  `@export var beats`, `play(p_beats)`, `advance()`, `skip()`. `intro.gd` não muda.
- `game_events.gd` / `CONTRACT.md`: **sem mudança** (cutscene continua isolada).

## Escopo / arquivos
- Muda: `cutscene_beat.gd` (campo `location`), `cutscene_intro.gd` (location+cor por beat),
  `cutscene_player.gd` + `cutscene_player.tscn` (render cross-cut), `tests/test_cutscene_data.gd`
  (cobrir `location`), `tests/test_cutscene_player.gd` (ajustar node-paths dos botões se mudarem).
- NÃO toca: `intro.gd`, `intro.tscn`, `project.godot`, `game_events.gd`, `CONTRACT.md`,
  arquivos de gameplay de outras áreas.

## Testes / verificação
- **Headless:** import limpo; `test_cutscene_data` → `TEST_OK` (inclui checagem de `location`
  nos beats certos); `test_cutscene_player` → `TEST_OK` (API + botões Atender/Pular);
  `intro.tscn` e `main.tscn` smoke sem `SCRIPT ERROR`.
- **Validação no editor (lição do time):** `.tscn` corrompida passa no headless mas derruba
  o editor. Antes do merge, abrir a cena no editor / rodar F5 (humano) — não confiar só no headless.
- **Manual (F5):** recebe chamada → Atender → cortes de ambiente (LUA quando Carlos/Gus,
  TERRA quando Você) com avatar + legenda typewriter → Pular funciona → legenda final →
  entra no gameplay. Layout cabe bem em 720×1280.

## Fora de escopo
- Arte/áudio finais (placeholders por ora).
- CENA 2 (final) — reaproveita o player + `location` depois.
- Split-screen (descartado a favor do cross-cut).
