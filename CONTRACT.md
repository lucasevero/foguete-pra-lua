# Contrato de desenvolvimento — Foguete pra Lua 🚀

Jogo: fase única, foguete sai da Terra e chega na Lua resgatar o Carlos e o Gus.
Gerencie **combustível** e **tempo**, desvie de **asteroides**, equilibre o foguete.

## Regra de ouro (evita merge hell)

- **Godot 4.7 exato.** Versão diferente reescreve `.tscn` → conflito.
- **Cada dev mexe SÓ nos arquivos dele** (tabela abaixo). Não edite arquivo de outro.
- **Sistemas se comunicam só por `GameEvents`** (autoload). Ninguém chama método de outro sistema direto.
- `git pull` antes de começar E antes de push. Commits pequenos e frequentes.
- Nunca commitar `.godot/` (já no `.gitignore`).

## Divisão de trabalho

| Dev | Arquivos (só seus) | Tarefa |
|-----|--------------------|--------|
| **A** | `player.gd`, `player.tscn` | Física do foguete: gravidade + empuxo + inclinação. Ajustar até o equilíbrio ficar divertido. |
| **B** | `asteroid.gd`, `asteroid.tscn`, `asteroid_spawner.gd` | Asteroides: movimento, spawn, dificuldade crescente. |
| **C** | `fuel.gd`, `fuel.tscn`, `fuel_spawner.gd`, `parallax_bg.gd`, `parallax_bg.tscn` | Pickups de combustível + fundo Terra→espaço→Lua. |
| **D** | `ui.gd`, `ui.tscn`, `game_manager.gd`, `main.tscn` | HUD, estados, vitória/derrota, integração. Dono da `main.tscn`. |

Compartilhado (mexer só combinando com o time): `game_events.gd`, `project.godot`.

## Contrato de signals (`GameEvents`)

Ver `game_events.gd`. **Não mude assinatura sem avisar** — quebra todo mundo.

| Signal | Quem emite | Quem escuta |
|--------|-----------|-------------|
| `fuel_changed(current, maximum)` | Player | HUD |
| `fuel_collected(amount)` | Fuel pickup | Player |
| `asteroid_hit` | Asteroid | Player |
| `player_died` | Player | GameManager |
| `player_reached_moon` | GameManager | GameManager |
| `altitude_changed(ratio)` | GameManager | Background (0=Terra, 1=Lua) |
| `time_changed(seconds_left)` | GameManager | HUD |
| `game_started` | GameManager | (livre) |
| `game_over(won)` | GameManager | HUD |

## Controles (protótipo)

- **ESPAÇO**: empuxo (gasta combustível)
- **A / D** ou **setas**: girar o foguete

## Rodar

Abra no Godot 4.7, F5. Ou:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . -e
```
