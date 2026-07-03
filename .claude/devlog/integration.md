# Devlog — integration (Dev D)

Arquivos: `ui.gd`, `ui.tscn`, `game_manager.gd`, `main.tscn`. Só o agente desta área escreve aqui.
Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — Tela de game over + fix de crash + config projeto
- Game over agora **congela** o jogo (`get_tree().paused = true`) e mostra **botão REINICIAR** (mobile não tem tecla). UI com `process_mode = ALWAYS` p/ o botão funcionar na pausa. Tecla R removida.
- ⚠️ BUG CORRIGIDO: `ui.tscn` tinha `parent=""` no nó raiz → cena corrompida derrubava o EDITOR ao renderizar (headless não pega isso!). Regra nova: validar `.tscn` abrindo o editor, não só headless.
- Renderer trocado p/ **gl_compatibility** (mobile+web WebGL2, evita crash MoltenVK no editor).
- Pixel art: `default_texture_filter=0` (nearest, sem borrão).
- `assets/` estruturado por área; `serve_web.py` + preset Web commitados p/ testar no celular.

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
