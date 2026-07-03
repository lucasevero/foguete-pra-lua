# Design — Cutscene final (CENA 2 — a chegada)

**Data:** 2026-07-03
**Área:** integration (Dev D) — arquivos novos (minha área) + 1 hook em `game_manager.gd` (compartilhado ⚠️)
**Fonte narrativa:** roteiro CENA 2 (a chegada) fornecido pelo time.

## Objetivo

Adicionar a cutscene final, que toca **ao vencer** (chegar na Lua), reaproveitando o
`CutscenePlayer` cross-cut já existente. Final agridoce: resgatam o Carlos e o Gus, mas
o foguete do herói (Luca) também não tem a volta codada — os três ficam presos na Lua.

Decisões validadas:
- Gatilho: **eu faço o hook no `game_manager._end(true)`** (espelha o `_play_cutscene` de
  abertura), commito e **pusho rápido** + aviso no devlog. Sem mudança de contrato.
- Arte: **2 fundos novos** (`moon_surface`, `moon_sit`); reuso `lua_bg` (interior) e os
  retratos existentes.
- Planos finais (os três sentados) **sem retrato** — só a cena (os retratos atuais são
  poses "no telefone", que não encaixam na Lua).

## Fluxo (beats — `CutsceneFinal.build()`)

Reusa `CutsceneBeat` (kind DIALOGUE/CAPTION; sem CALL). Beats "(ação)" usam `speaker = ""`
(nome oculto) — funcionam como rubrica/cena.

| # | kind | speaker | text | bg | portrait / side |
|---|------|---------|------|----|-----------------|
| 1 | DIALOGUE | CARLOS | "CARA! Eu sabia que você vinha! Salvou a gente!" | MOON_SURFACE | carlos1 / LEFT |
| 2 | DIALOGUE | LUCA | "Bora voltar pra casa." | MOON_SURFACE | luca1 / RIGHT |
| 3 | DIALOGUE | "" | "(Todos entram. Ignição… o motor tosse. Tenta de novo. Silêncio.)" | LUA_BG | — |
| 4 | DIALOGUE | GUS | "Ãhn… Carlos." | LUA_BG | gus2 / RIGHT |
| 5 | DIALOGUE | CARLOS | "Que foi." | LUA_BG | carlos2 / LEFT |
| 6 | DIALOGUE | GUS | "Esse foguete também não tem a volta codada." | LUA_BG | gus2 / RIGHT |
| 7 | DIALOGUE | "" | "(Os três, sentados na Lua. Capacetes na mão. A Terra, brilhando.)" | MOON_SIT | — |
| 8 | DIALOGUE | CARLOS | "…Alguém trouxe o lanche?" | MOON_SIT | — |
| 9 | CAPTION | "" | "Missão de resgate: concluída.\nMissão de retorno: não implementada.\n// TODO: codar a volta" | MOON_SIT | — |

- Beats "(ação)"/wide-shots: `portrait = null` → o player não mostra avatar (o `_set_avatar`
  só é chamado quando há retrato; ver "Ajuste no player" abaixo). `SpeakerName` vazio some.
- Texto PT-BR verbatim do roteiro.
- Nenhum `auto_advance_after` — tudo por toque; a última CAPTION espera o toque, e ao
  avançar dela o `finished` dispara → game over.

## Ajuste no player (`cutscene_player.gd`)

Hoje `_show_dialogue` sempre mostra o avatar. Para os beats sem retrato (ação/wide-shot),
o avatar deve ficar escondido e o nome vazio não deve aparecer:
- Em `_show_dialogue`: se `beat.portrait == null`, `_avatar.visible = false`; senão
  `_avatar.visible = true` + `_set_avatar(beat)`.
- `_speaker.visible = not beat.speaker.is_empty()` (esconde o nome nos beats de ação).

Isso é retrocompatível com a CENA 1 (lá todos os beats de diálogo têm retrato e nome).
Nenhuma mudança na API pública nem no contrato.

## Assets novos (procedurais, `generate_final_bgs.py`)

Baixa resolução 90×160 (escala ×8 nearest), paleta coerente com os outros fundos.
- `moon_surface.png` — solo lunar (cinza, crateras) + o foguete gambiarra pousado (poeira),
  espaço preto + estrelas + **Terra grande** no céu.
- `moon_sit.png` — plano aberto: solo lunar no rodapé, espaço + Terra brilhando grande, e
  **três figurinhas sentadas** (silhuetas, capacetes ao lado). O remate emocional.
Reuso: `lua_bg.png` (interior), retratos `carlos1/carlos2/gus2/luca1`.

## Gatilho (`game_manager.gd` — ⚠️ compartilhado)

`_end(won)` passa a, quando `won`, tocar a CENA 2 inline antes do game over:
```
func _end(won: bool) -> void:
    if not running: return
    running = false
    get_tree().paused = true
    if won:
        _play_final_cutscene()
    else:
        GameEvents.game_over.emit(false)

func _play_final_cutscene() -> void:
    GameEvents.cutscene_started.emit()             # UI esconde HUD
    var cs: CutscenePlayer = CUTSCENE.instantiate()
    cs.layer = 100
    cs.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(cs)
    cs.finished.connect(func() -> void:
        cs.queue_free()
        GameEvents.game_over.emit(true)            # mostra REINICIAR/menu
    , CONNECT_ONE_SHOT)
    cs.play(CutsceneFinal.build())
```
Reusa `const CUTSCENE` (já preload no game_manager) e os signals `cutscene_started` +
`game_over` (já existentes). **Sem mudança de contrato.** Mexe só no `_end` + adiciona
`_play_final_cutscene`. Commit + push rápido + aviso no devlog (arquivo do outro Dev D).

## Arquivos

- Novos (minha área): `cutscene_final.gd`, `assets/cutscenes/moon_surface.png`(+`.import`),
  `assets/cutscenes/moon_sit.png`(+`.import`), `assets/cutscenes/generate_final_bgs.py`,
  `tests/test_cutscene_final.gd`.
- Modificados: `cutscene_player.gd` (avatar/nome opcionais por beat), `game_manager.gd` (hook `_end`).
- Intocados: `game_events.gd`/`CONTRACT.md` (sem novo signal), `cutscene_beat.gd`, `cutscene_intro.gd`.

## Testes / verificação

- **Headless:** import limpo; `test_cutscene_final` → `TEST_OK` (9 beats; beat 1 CARLOS;
  beat 9 CAPTION contém "TODO: codar a volta"; beat 8 CARLOS "…Alguém trouxe o lanche?");
  `test_cutscene_data`/`test_cutscene_player` seguem `TEST_OK`; `main.tscn` smoke sem erro.
- **Validação editor (F5):** vencer a partida (ou eu forço um atalho temporário de teste em
  debug) → CENA 2 toca → ao final, game over/REINICIAR. Conferir layout dos 2 fundos novos.
- Regra do time: `.tscn`/cena validada no editor, não só headless.

## Fora de escopo

- Retratos dedicados da CENA 2 (poses fora do telefone) — placeholder reusa os atuais.
- Áudio da CENA 2 (música de chegada) — pode entrar depois via `beat.sfx`.
