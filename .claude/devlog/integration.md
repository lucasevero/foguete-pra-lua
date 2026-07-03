# Devlog — integration (Dev D)

Arquivos: `ui.gd`, `ui.tscn`, `game_manager.gd`, `main.tscn`. Só o agente desta área escreve aqui.
Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — esqueleto inicial
- `main.tscn`: container que instancia Background, Player, spawners, UI, GameManager.
- `game_manager.gd`: calcula altitude (Terra→Lua), cronômetro, decide win/lose. Emite `altitude_changed`, `time_changed`, `game_started`, `game_over`.
- `ui.gd`: HUD (combustível, tempo) + label de resultado.
- TODO: tela real de restart, pausar spawners no fim, tela de menu, cutscenes.
