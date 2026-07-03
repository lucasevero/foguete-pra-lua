# Devlog — integration (Dev D)

Arquivos: `ui.gd`, `ui.tscn`, `game_manager.gd`, `main.tscn`. Só o agente desta área escreve aqui.
Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — SFX de gameplay integrados
- ⚠️ CONTRATO: +2 signals `lifted_off`, `landed_safely` (Player → AudioManager). CONTRACT.md + game_events.gd atualizados.
- AudioManager conecta todos SFX de gameplay (8-bit, gerados via ffmpeg/python): liftoff, fuel_pickup, crash_asteroid (alto), crash_ground (explosão longa), land_soft, fuel_low (alarme).
- Truques: `_skip_ground_crash` evita som duplo quando morre por asteroide (asteroid_hit já toca crash_ast, então o player_died seguinte pula o crash_gnd). fuel_low dispara ao cruzar 25% (via fuel_changed), reseta ao reabastecer.
- Merge: música agora inicia via `_on_game_started` (MUSIC_START=10s), não no _ready (integra com a mudança de restart do Dev D).
- TODO: SFX de vitória/game over (win.wav, game_over.wav).

## 2026-07-03 — Música reinicia ao reiniciar o jogo
- `audio_manager.gd`: o tema agora reinicia (play a partir de `MUSIC_START`=10s) a cada `game_started`, em vez de tocar eternamente através do reload. O autoload persiste no `reload_current_scene()`, então a música só reinicia via signal; `GameManager` já reemite `game_started` no restart.
- Sem mudança de contrato (`game_started` já existia e já era emitido). Validado: emitir `game_started` 2× → posição da faixa volta de ~10.6s para ~10.0s.

## 2026-07-03 — UI art do HUD (Fase 5 · Arte)
- HUD de texto → **arte pixel**: painel (NinePatchRect), ícone de jerry can + `TextureProgressBar` de combustível, ícone de relógio + tempo, botão REINICIAR estilizado (StyleBoxTexture normal/pressed).
- Assets novos em `assets/ui/` (panel, fuel_icon, clock_icon, gauge_frame/fill, button_normal/pressed) gerados por `assets/ui/generate_ui_art.py` (pixel art procedural, reproduzível, paleta única espaço-retrô).
- `ui.gd`: barra usa `fuel_changed` (max/value) + label numérico; **tint vermelho** quando combustível ≤ 25%.
- Sem mudança de contrato (só escuta `fuel_changed`/`time_changed`/`game_over`). Validado renderizando o viewport (janela do jogo abre fora da tela no macOS; screenshot direto não pega).
- TODO: menu inicial (Fase 7) reutiliza o mesmo botão; indicador de inclinação no HUD; áudio/música (Fase 5 restante).

## 2026-07-03 — Áudio: AudioManager + tema + som do motor
- ⚠️ CONTRATO: novo signal `thrust_changed(active)` (Player → AudioManager). CONTRACT.md + game_events.gd atualizados. Avisar time (git pull).
- Autoload `AudioManager` (escuta signals, toca sons). Toca `theme_main.mp3` (Space Oddity 8-bit, loop) no start + `thrust_loop.wav` (motor 8-bit, v1 pesado) enquanto o empuxo tá ativo. process_mode=ALWAYS.
- Thrust wav importado com loop_mode=1 (forward).
- TODO: conectar SFX de pickup/crash/vitória/game over quando os arquivos chegarem (ver Notion "Sons a Produzir").

## 2026-07-03 — Chão sólido + fase maior
- Adicionado `Ground` (StaticBody2D + WorldBoundaryShape2D) em main.tscn, y=974 → foguete não passa do chão, começa pousado.
- Fase maior: `moon_altitude_offset` -5000→-10000; `time_limit` 120→180s.
- Coords que precisam casar entre áreas: player start y=950, chão 974, moon world ≈ -9050 (game_manager offset + start); bg usa `ground_y`/`moon_y` iguais.

## 2026-07-03 — Tela de game over + fix de crash + config projeto
- Game over agora **congela** o jogo (`get_tree().paused = true`) e mostra **botão REINICIAR** (mobile não tem tecla). UI com `process_mode = ALWAYS` p/ o botão funcionar na pausa. Tecla R removida.
- ⚠️ BUG CORRIGIDO: `ui.tscn` tinha `parent=""` no nó raiz → cena corrompida derrubava o EDITOR ao renderizar (headless não pega isso!). Regra nova: validar `.tscn` abrindo o editor, não só headless.
- Renderer trocado p/ **gl_compatibility** (mobile+web WebGL2, evita crash MoltenVK no editor).
- Pixel art: `default_texture_filter=0` (nearest, sem borrão).
- `assets/` estruturado por área; `serve_web.py` + preset Web commitados p/ testar no celular.

## 2026-07-03 — redesign portrait/mobile da cutscene (tela de chamada)

Redesenhado o `CutscenePlayer` de "diálogo com retratos esq/dir em paisagem"
para uma **tela de chamada estilo celular**, pensada pro jogo já ser
portrait/mobile: **recebendo chamada** (nome de quem liga + "chamando…" +
botão Atender) → **em chamada** (avatar do falante que troca conforme a fala,
timer de duração contando, legenda com efeito typewriter) → desliga e corta
pro `main.tscn`.

**Input agora é touch-first:** tocar em qualquer lugar da tela atende a
chamada e depois avança/completa a linha atual; há botões explícitos
**Atender** e **Pular** na UI. `ui_accept`/`ui_cancel` (Espaço/ESC) continuam
funcionando como atalho desktop, mas não são mais o fluxo principal.

**Isso resolve** o item "adaptar layout p/ portrait" que tinha ficado
**PENDENTE** na entrada anterior (ver abaixo, "Pós-rebase na Fase 2") — o
`cutscene_player.tscn` foi refeito do zero para caber em 720×1280.

**Arquivos alterados (só estes três):**
- `cutscene_player.gd`
- `cutscene_player.tscn`
- `tests/test_cutscene_player.gd`

`cutscene_beat.gd`, `cutscene_intro.gd` (dados/sequência de beats) e o
contrato `GameEvents`/`CONTRACT.md` **não foram tocados** — a cutscene
continua sendo uma cena isolada, sem emitir/escutar signals do jogo.

**Verificação headless (suíte completa, todas passaram):**
1. `--headless --import --quit` → grep de erro/parse vazio.
2. `--headless --script res://tests/test_cutscene_data.gd` → `TEST_OK`.
3. `--headless --script res://tests/test_cutscene_player.gd` → `TEST_OK`.
4. `--headless res://intro.tscn --quit-after 120` → grep
   `SCRIPT ERROR|nil|invalid` vazio (a cena fica parada no beat de chamada
   esperando input, esperado headless).
5. `--headless res://main.tscn --quit-after 120` → grep vazio.

**Pendente:** playtest manual no editor (F5) — **interativo, precisa de um
humano** com toque/mouse/teclado e display; não dá pra rodar headless.
Checklist:
- Recebe chamada ("CARLOS" + "chamando…") com botão Atender; tocar em
  qualquer lugar também atende.
- Em chamada: avatar do falante troca (Carlos/Você/Gus), timer conta,
  legenda com typewriter; tocar avança/completa a linha.
- Botão Pular encerra a cutscene a qualquer momento.
- Legenda final "Missão de resgate iniciada." (fundo azul) → entra no
  `main.tscn`.
- Layout cabe bem em 720×1280 (nada cortado/fora da tela).

## 2026-07-03 — cutscene de abertura (CENA 1) + CutscenePlayer reutilizável

Adicionada a cutscene de abertura: a ligação do Carlos avisando que ele e o Gus
estão presos na Lua, que roda antes do gameplay começar.

**Arquivos novos:**
- `cutscene_beat.gd` — modelo de dados de um "beat" de cutscene (fala, retrato,
  lado, background, sfx etc).
- `cutscene_intro.gd` — `CutsceneIntro.build()`, a sequência de beats da CENA 1
  (tela de ligação preta → diálogo Carlos → Você → Carlos → Gus → Carlos →
  legenda "Missão de resgate iniciada." sobre fundo azul-céu).
- `cutscene_player.gd` / `cutscene_player.tscn` — player genérico e
  reutilizável: consome uma lista de beats, faz o typewriter do texto, mostra
  retratos placeholder coloridos esq/dir, avança com Espaço (Espaço também
  completa a linha na hora durante o typewriter) e permite pular tudo com ESC.
  Não depende de nenhum dado específico da CENA 1 — pode tocar qualquer
  sequência de beats.
- `intro.gd` / `intro.tscn` — cena fina que instancia o `CutscenePlayer` com
  `CutsceneIntro.build()` e, ao terminar (fim natural ou ESC), chama
  `change_scene_to_file("res://main.tscn")`.
- `tests/test_cutscene_data.gd` — valida a estrutura dos beats gerados por
  `CutsceneIntro.build()`.
- `tests/test_cutscene_player.gd` — valida o comportamento do `CutscenePlayer`
  (avanço, typewriter, skip).

**Verificação headless (suíte completa, todas passaram):**
1. `--headless --import --quit` → grep de erro/parse vazio.
2. `--headless --script res://tests/test_cutscene_data.gd` → `TEST_OK`.
3. `--headless --script res://tests/test_cutscene_player.gd` → `TEST_OK`.
4. `--headless res://intro.tscn --quit-after 120` → grep `SCRIPT ERROR|nil|invalid`
   vazio (a cena fica parada no beat de ligação esperando input, o que é
   esperado headless).
5. `--headless res://main.tscn --quit-after 120` → grep vazio.

**⚠️ Aviso ao time — mudança em `project.godot`:**
`run/main_scene` agora aponta para `res://intro.tscn` (antes era `main.tscn`).
Isso significa que **F5 / rodar o projeto agora abre a cutscene de abertura
primeiro**, e só entra no `main.tscn` depois que a cutscene termina (fim
natural ou ESC). Para testar só o gameplay, usem **F6 (Run Current Scene)**
com `main.tscn` aberto, ou rodem `--headless res://main.tscn` direto — o
`main.tscn` continua funcionando normalmente sozinho, nada mudou nele.

**Contrato `GameEvents`:** inalterado. Nenhuma edição em `CONTRACT.md` ou
`game_events.gd` foi necessária — a cutscene não emite nem escuta nenhum
signal do jogo, é uma cena isolada que só troca de cena no final.

**⚠️ Pós-rebase na Fase 2 (mobile/portrait):** o layout do `cutscene_player.tscn`
foi feito para **1152×648 paisagem**; com o jogo agora em **720×1280 portrait**,
os offsets/âncoras dos retratos e da caixa de diálogo precisam ser adaptados
para retrato. A lógica (typewriter/avançar/pular/transição) segue válida — é só
reposicionamento de UI. **Pendente.** No mobile/touch, o "pular" via ESC também
não existe — avaliar um botão/skip por toque.

**Pendente:** checklist de verificação manual no editor (F5, playtest humano)
ainda não foi executado — precisa de um humano rodando o editor
interativamente (apertando Espaço/ESC, observando o typewriter e a transição).
Itens do checklist (ver `.superpowers/sdd/task-4-brief.md`, Step 2):
- Abre na tela de ligação ("CARLOS chamando…") em fundo preto.
- Espaço avança; durante o typewriter, Espaço completa a linha na hora.
- Diálogo passa por Carlos → Você → Carlos → Gus → Carlos com retratos
  placeholder coloridos (esq/dir).
- ESC pula a cutscene a qualquer momento.
- No fim aparece a legenda "Missão de resgate iniciada." sobre fundo
  azul-céu e, após ~2.5s, entra no `main.tscn` e o gameplay começa normal.

**Próximo passo natural:** CENA 2 (final), reaproveitando o mesmo
`CutscenePlayer` com uma nova lista de beats, disparada quando
`GameEvents.game_over(won == true)` — reforça o final agridoce (o nosso
foguete também não volta).

## 2026-07-03 — Fase 2: mobile + restart
- `project.godot`: viewport **720×1280 portrait** + orientação handheld + stretch canvas_items/keep (decisão: jogo é mobile).
- `game_manager.gd`: **R reinicia** (reload_current_scene) na tela de game over/vitória.
- `ui.gd`: label de resultado mostra "(R para reiniciar)".
- `main.tscn`: player start reposicionado p/ portrait (360, 950).
- TODO: menu inicial, cutscenes, pausar spawners no fim, tela real de resultado.

## 2026-07-03 — esqueleto inicial
- `main.tscn`: container que instancia Background, Player, spawners, UI, GameManager.
- `game_manager.gd`: calcula altitude (Terra→Lua), cronômetro, decide win/lose. Emite `altitude_changed`, `time_changed`, `game_started`, `game_over`.
- `ui.gd`: HUD (combustível, tempo) + label de resultado.
- TODO: tela real de restart, pausar spawners no fim, tela de menu, cutscenes.
