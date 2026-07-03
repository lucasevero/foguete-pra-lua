# Devlog — physics (Dev A)

Arquivos: `player.gd`, `player.tscn`. Só o agente desta área escreve aqui.
Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — Escudo com visual (círculo amarelo)
- Nó `Shield` (Sprite2D, z=1) no player; textura gerada em código (disco amarelo translúcido, placeholder). Mostra ao ativar escudo, esconde ao absorver hit.

## 2026-07-03 — Powerups no Player: escudo + arma
- ⚠️ CONTRATO (novos): `coin_collected`, `coins_changed`, `powerup_purchase_requested`, `powerup_activated`.
- Player escuta `powerup_activated`: escudo (`_shield` absorve 1 asteroid_hit em vez de morrer), gasolina (enche), arma (`_weapon_time`=15s, atira `bullet.tscn` pra cima a cada 0.15s). Bullet destrói asteroides (grupo "asteroid").
- bullet.gd/.tscn novos (Area2D). asteroid.tscn entrou no grupo "asteroid".

## 2026-07-03 — Emite thrust_changed / lifted_off / landed_safely (áudio)
- ⚠️ CONTRATO: Player emite `thrust_changed(active)` (virada do empuxo), `lifted_off` (sai do chão 1ª vez), `landed_safely` (pouso suave). AudioManager usa p/ SFX.

## 2026-07-03 — Cair no chão após decolar = game over (pouso suave OK)
- Flag `_has_taken_off` (vira true ao sair do chão). Ao tocar o chão de novo: se descida > `safe_land_speed` (250) → `player_died` (crash); senão pouso suave, reseta flag (pode decolar de novo).
- `descent` capturado antes do move_and_slide (que zera velocity no impacto).

## 2026-07-03 — Começa pousado + gasolina mais lenta
- `fuel_burn_rate` 25→10 (era ~4s de empuxo total, agora ~10s + pickups).
- Foguete começa pousado no chão (StaticBody em main.tscn, y=974). Zero `velocity.y` quando `is_on_floor()` — senão a gravidade acumulava e o empuxo não levantava.

## 2026-07-03 — Fase 2: controle mobile por toque + física
- Controle trocado de teclado p/ **toque/mouse** (polling de `Input.is_mouse_button_pressed` + `get_mouse_position`, robusto e funciona no mobile via emulação). Empurra o foguete pra LONGE do ponto tocado; lateral rotaciona.
- Física: `gravity` 500→200; modelo trocado de pêndulo invertido p/ **auto-endireitamento** (`-sin(rot)*uprighting`, suave); `touch_torque` gira devagar.
- **Morte ao sair da tela**: `VisibleOnScreenNotifier2D` → emite `player_died`.
- Camera2D limites p/ largura mobile 720.
- TODO: tuning fino de feel; sprite pixel art.

## 2026-07-03 — esqueleto inicial
- `player.gd`: gravidade + empuxo (ESPAÇO) na direção do foguete + rotação (A/D). Combustível decrementa ao empurrar.
- Escuta `fuel_collected`, `asteroid_hit`. Emite `fuel_changed`, `player_died`.
- TODO: game feel do equilíbrio (torque/inércia real), tuning dos valores exportados.
