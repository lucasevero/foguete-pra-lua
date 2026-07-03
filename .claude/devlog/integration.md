# Devlog — integration (Dev D)

Arquivos: `ui.gd`, `ui.tscn`, `game_manager.gd`, `main.tscn`. Só o agente desta área escreve aqui.
Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — Painéis do HUD/menu transparentes
- `ui.tscn`: HudPanel, TiltPanel, MenuPanel e CreditsPanel com `self_modulate` alpha 0 (some a caixa navy, mantém o conteúdo). Pedido: os "blocos com fundo azul" deviam ficar transparentes.
- Legibilidade: contorno escuro (`font_outline`) nos textos do HUD (FuelValue, CoinLabel, TimeLabel, TiltCaption, ResultLabel), já que ficam sobre o céu claro sem a caixa. Menu fica sobre o Dim, então dispensa.

## 2026-07-03 — Cutscene só no JOGAR (REINICIAR joga direto)
- `game_manager.gd`: no `_ready`, o ramo `_has_started_once` (caminho do REINICIAR/reload) voltou a chamar `_begin()` em vez de `_play_cutscene()`. Agora só o **JOGAR** (via `_on_start_requested`) toca a cutscene; **REINICIAR** entra direto no jogo.
- Validado: BOOT=menu, JOGAR→cutscene, recriar cena com flag=true (=REINICIAR)→jogo direto sem cutscene (RESULT_OK).
- (Revertida a tentativa de arte das moedas — não commitada.)

## 2026-07-03 — CENA 2 (final) dispara ao vencer
- `game_manager._end(true)` agora chama `_play_final_cutscene()` em vez de emitir `game_over(true)` direto: instancia o `CutscenePlayer` inline (mesma receita do `_play_cutscene` de abertura — `layer=100`, `process_mode=ALWAYS`, roda com a árvore pausada) e toca `CutsceneFinal.build()`; `_end(false)` (derrota) segue emitindo `game_over(false)` como antes. Ao terminar a cutscene → `game_over(true)`, aí sim a UI mostra REINICIAR/menu.
- Reaproveita `CutscenePlayer` + os 2 backgrounds novos da CENA 2 (`moon_surface`, `moon_sit`) e os retratos/`lua_bg` já existentes (Tasks 1–2); ajuste no player para beats sem retrato/nome (planos de ação/wide-shot, beats 6–8 "no telefone").
- **Sem mudança de contrato** — reusa `game_over` e `cutscene_started`, ambos já em `game_events.gd`/`CONTRACT.md`.
- ⚠️ Mexi no `game_manager.gd` (**compartilhado**, o outro Dev D também edita) — só a função `_end` + a nova `_play_final_cutscene`, nada mais no arquivo. Avisar o time (git pull) e dar push rápido pra minimizar janela de conflito.
- Verificação: suíte headless completa (import + `test_cutscene_final`/`test_cutscene_data`/`test_cutscene_player` + smoke `main.tscn`) tudo OK. **Pendente:** playtest F5 vencendo a partida (chegar na Lua) pra conferir a CENA 2 na prática (timing, os 2 fundos novos) — headless não exercita esse caminho porque só dispara ao vencer.

## 2026-07-03 — Fix: áudio continuava tocando em background
- `audio_manager.gd` `_notification`: muta o bus master em NOTIFICATION_APPLICATION_PAUSED / WM_WINDOW_FOCUS_OUT (app em background / tela off / perde foco), desmuta em RESUMED / FOCUS_IN. Resolve música tocando fora do app (web/mobile).

## 2026-07-03 — Fluxo menu→cutscene→jogo + moedas no HUD + loja fora do menu
- ⚠️ CONTRATO: +1 signal `cutscene_started` (GameManager → UI: esconde menu/HUD enquanto a cutscene toca). **Avisem o time (git pull).**
- ⚠️ `project.godot`: `run/main_scene` = `main.tscn` (era `intro.tscn`). Agora **o boot mostra o menu**; a cutscene deixou de ser a cena inicial. `intro.tscn`/`intro.gd` ficaram órfãos (mantidos, sem uso).
- **Cutscene no JOGAR/REINICIAR**: `game_manager.gd` instancia a `CutscenePlayer` inline (`layer=100`, `process_mode=ALWAYS`, toca com a árvore pausada) e no `finished` → `_begin()`. JOGAR = do menu (estado limpo); REINICIAR = reload reseta e o `_ready` (flag=true) toca a cutscene.
- **Moedas no HUD** (`ui.tscn`/`ui.gd`): contador (novo `coin_icon.png` + label) entre a barra de combustível e o tempo, escuta `coins_changed`. Removido o contador da loja (`shop.tscn`/`shop.gd`).
- **Botão LOJA** (`shop.gd`): escondido no menu (por padrão) e no game over (já era), aparece só em `game_started`.
- Validado (headless + captura): BOOT=menu (loja/HUD escondidos), JOGAR→cutscene (menu some), pular→jogo (HUD+loja+moedas), coin_collected→contador atualiza, game over→loja some + REINICIAR/MENU PRINCIPAL.

## 2026-07-03 — Som de moeda (normal/grande)
- AudioManager conecta `coin_collected(amount)`: coin.wav (normal) / coin_big.wav (amount>=5). Sons 8-bit gerados.

## 2026-07-03 — Moedas + Loja de powerups
- ⚠️ CONTRATO (novos): `coin_collected`, `coins_changed`, `powerup_purchase_requested`, `powerup_activated`. CONTRACT.md atualizado.
- `shop.gd`/`shop.tscn` (CanvasLayer process_mode=ALWAYS, cena NOVA p/ não conflitar com ui.tscn do Dev D): contador de moedas (canto sup. dir.) + botão LOJA (canto inf. dir.) que pausa e abre painel com 4 powerups. Botões desabilitam se não tem moeda.
- GameManager: rastreia `coins` (zeram no restart), `PRICES` {time:5,shield:10,fuel:15,weapon:25}, valida compra em `_on_purchase_requested` (debita + emite `powerup_activated`), aplica "time" (+15s).
- Fluxo: Loja emite `powerup_purchase_requested` → GameManager valida/debita/emite `powerup_activated` → Player aplica shield/fuel/weapon, GameManager aplica time.
- Adicionados CoinSpawner + Shop em main.tscn.

## 2026-07-03 — Game over: botão MENU PRINCIPAL
- ⚠️ CONTRATO: +1 signal `menu_requested` (UI game over "MENU" → GameManager + AudioManager). **Avisem o time (git pull).**
- `ui.tscn`/`ui.gd`: 2º botão **MENU PRINCIPAL** no game over (empilhado sob o REINICIAR). REINICIAR = replay instantâneo; MENU = volta pro menu inicial.
- `game_manager.gd`: `_on_menu_requested` zera `_has_started_once` e `reload_current_scene()` → cai no menu (não faz replay).
- `audio_manager.gd`: para a música no `menu_requested` (menu inicial é silencioso; volta no próximo JOGAR).
- Validado: game over mostra os 2 botões; após "MENU", cena recriada com `running=false` + menu visível (MENU_RETURN_OK).

## 2026-07-03 — Fase 7: menu inicial + estados + indicador de inclinação
- ⚠️ CONTRATO: +2 signals aditivos em `game_events.gd` (+ `CONTRACT.md`): `start_requested` (UI menu "JOGAR" → GameManager) e `tilt_changed(radians)` (GameManager → HUD). Não mudam nada existente, mas **avisem o time (git pull)**.
- **Menu inicial** (`ui.tscn`/`ui.gd`): overlay com título, história, dica de controle (onboarding), botões JOGAR/CRÉDITOS/SAIR (arte pixel) + painel de créditos. HUD e indicador só aparecem em `game_started`.
- **Máquina de estados** (`game_manager.gd`): começa pausado no MENU; `start_requested` inicia (`_begin`). `static var _has_started_once` sobrevive ao `reload_current_scene()` → REINICIAR faz **replay instantâneo** (pula o menu). Validado: BOOT=menu, JOGAR=jogando, recriar cena=jogando (REPLAY_OK).
- **Indicador de inclinação** no HUD (top-dir): seta `tilt_arrow.png` gira com `player.rotation` (GameManager lê e emite `tilt_changed`), verde no prumo → vermelho inclinado. Cobre o "HUD: indicador de inclinação?" da Fase 7.
- Fase 7 restante NÃO feita: **"aviso de quase batendo"** precisa de proximidade dos asteroides (área **obstacles**) — deixei pro dono da área emitir um signal.

## 2026-07-03 — SFX de estados/UI integrados
- win (`game_over(true)`), game_over (`game_over(false)`), ui_click (botão REINICIAR via `AudioManager.play_ui_click()` chamado em `ui.gd`). Todos 8-bit gerados.
- `phone_ring.wav` adicionado em assets/audio/sfx/ mas NÃO plugado — é da cutscene (área Dev D). Deixado pro dono da cutscene tocar (evita conflito na área ativa dele).
- Sem mudança de contrato (usa `game_over` existente; ui_click via chamada direta ao autoload).

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

## 2026-07-03 — cutscene cross-cut (corta pro ambiente de quem fala)

A cutscene de abertura virou **cross-cut**: em vez de uma única tela de
chamada, cada fala agora corta, em tela cheia, pro **ambiente de quem está
falando** — Carlos/Gus falam de **LUA**, Você fala da **TERRA — seu quarto**
(São Paulo). O beat 0 continua sendo "recebendo chamada" (nome de quem liga +
botão **Atender**, tocar em qualquer lugar também atende), e a cutscene
termina do mesmo jeito, com a legenda final centralizada sobre fundo azul
antes de entrar no `main.tscn`.

**O que mudou:**
- `CutsceneBeat` (`cutscene_beat.gd`) ganhou um campo **`location`**.
- `cutscene_intro.gd` define o `location` de cada beat da sequência (LUA para
  Carlos/Gus, TERRA/quarto para Você) — cores placeholder por ambiente (MOON,
  ROOM, SKY) substituem os retratos esq/dir do redesign anterior.
- `cutscene_player.gd`/`cutscene_player.tscn` foram adaptados para desenhar o
  ambiente em tela cheia por beat, com rótulo do local, em vez do layout de
  chamada com avatar único trocando de lado.
- O **timer de duração da chamada** (contagem visível introduzida no redesign
  portrait anterior) foi **removido** — não fazia sentido com o corte de
  ambiente cheio.
- Arquivos tocados: só `cutscene_beat.gd`, `cutscene_intro.gd`,
  `cutscene_player.gd`, `cutscene_player.tscn` + os dois testes
  (`tests/test_cutscene_data.gd`, `tests/test_cutscene_player.gd`).
  `intro.gd`/`intro.tscn` e o contrato `GameEvents`/`CONTRACT.md`
  **inalterados** — a cutscene continua isolada, sem emitir/escutar signals
  do jogo.

**Verificação headless (suíte completa, todas passaram):**
1. `--headless --import --quit` → grep de erro/parse vazio.
2. `--headless --script res://tests/test_cutscene_data.gd` → `TEST_OK`.
3. `--headless --script res://tests/test_cutscene_player.gd` → `TEST_OK`.
4. `--headless res://intro.tscn --quit-after 120` → grep
   `SCRIPT ERROR|nil|invalid` vazio.
5. `--headless res://main.tscn --quit-after 120` → grep vazio.

**Pendente: playtest/validação no editor (F5) — PENDENTE**, requer um humano
interativo (toque/mouse/teclado + display); headless não roda isso. Lição já
registrada neste devlog continua valendo: um `.tscn` corrompido passa no
headless mas derruba o editor — validação no editor é obrigatória antes do
merge. Checklist F5:
- Recebe chamada ("CARLOS") com botão Atender; tocar em qualquer lugar também
  atende.
- Cada fala corta pro ambiente do falante: LUA (Carlos/Gus) e TERRA/quarto
  (Você), com rótulo do local + avatar + legenda com efeito typewriter.
- Botão Pular encerra a cutscene a qualquer momento.
- Legenda final "Missão de resgate iniciada." (fundo azul) → entra no
  `main.tscn`.
- Layout cabe bem em 720×1280 (nada cortado).

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
