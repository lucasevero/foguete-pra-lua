# Devlog — obstacles (Dev B)

Arquivos: `asteroid.gd`, `asteroid.tscn`, `asteroid_spawner.gd`. Só o agente desta área escreve aqui.
Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — Meteoros: bastante + todos os tamanhos ao escurecer
- (ajuste pela integração a pedido do humano: "poucos" → "bastante de todos os tamanhos".)
- `asteroid_spawner.gd`: `base_interval` 2.2→0.45s (~2.2/s já quando o céu escurece), `min_interval` 0.35→0.2s (~5/s no máximo), `ramp_time` 90→60s.
- `_pick_variant`: **todos os tamanhos presentes desde o início** (pesos pequeno=1.0, médio=0.9+diff·0.3, grande=0.7+diff·0.9) em vez de só pequenos cedo. Com o tempo pende pros maiores.
- Mantido o gate por altitude (nada no céu claro). Validado headless: diff=0 gera os 3 tamanhos; ~6 spawns em ~1s.

## 2026-07-03 — Sprites reais dos voadores (pombo animado, zepelim)
- Pombo: AnimatedSprite2D (passaro1/2/3, loop 8fps), scale 0.7, hitbox capsula 13x38. Zepelim: aviao.png (dirigível capim), scale 1.3, hitbox capsula 22x108. Ambos horizontais (CollisionShape rot 90°).
- flyer.gd: `flip_h` do $Sprite conforme velocity.x (vira pro lado do movimento).

## 2026-07-03 — Obstáculos de baixa altitude: pombos + zepelins
- `flyer.gd` (Area2D genérico, `velocity` setada no spawn; emite `asteroid_hit`; grupo "asteroid" p/ arma destruir). pigeon.tscn (capsula pequena horizontal) e zeppelin.tscn (capsula longa horizontal) — hitboxes no formato; placeholders ColorRect (aguardando sprites reais).
- `low_obstacle_spawner.gd`: só spawna com céu claro (`ratio < active_max_ratio`=0.30, casa com dark_start_ratio do asteroid_spawner). Pombos diagonal lentos (spawn no topo), zepelins horizontal mais rápidos (spawn nas laterais). Por tempo. Escuta altitude_changed/game_started. Sem mudança de contrato.
- main.tscn: LowObstacleSpawner com pigeon_scene/zeppelin_scene.

## 2026-07-03 — Meteoros só no céu escuro + dificuldade por tempo
- (implementado pela squad de integração a pedido do humano — era o `TODO(Dev B)` do spawner.)
- `asteroid_spawner.gd`: passa a escutar `altitude_changed` (0=chão claro, 1=Lua) e `game_started`. **NÃO spawna enquanto o céu está claro** (`ratio < dark_start_ratio`=0.30); começa quando o céu escurece.
- Spawn por **TEMPO** (não mais por distância): intervalo cai de `base_interval`=2.2s → `min_interval`=0.35s ao longo de `ramp_time`=90s → mais meteoros conforme o tempo passa.
- **Tamanho progressivo**: `_pick_variant(diff)` pondera pequeno (domina cedo) → médio → grande (quadrático, só bem mais tarde). Validado headless: céu claro=0 spawns; cedo=só pequenos; tarde=maioria grande.
- Sem mudança de contrato (só escuta signals existentes). Tudo `@export` → tunável.

## 2026-07-03 — 3 tamanhos de asteroide + pixel art
- asteroid.tscn: ColorRect → Sprite2D + CircleShape base radius 45. Grupo "asteroid" mantido.
- asteroid_spawner: `VARIANTS` sorteia textura+escala: asteroid_01 (0.5, pequeno), asteroid_02 (0.7, médio), asteroid_03 (1.0, grande). Escala o nó → colisão escala junto.

## 2026-07-03 — Fase 2: spawn correto
- Spawn agora **acima do topo visível** sempre (converte tela→mundo via `canvas_transform.affine_inverse`), nunca dentro da tela.
- Spawn por **distância de subida** (não tempo) → densidade constante por trecho, imune à velocidade (corrige exploit de acelerar sem parar). `spawn_distance` ~220px + jitter.
- Despawn por posição na TELA (`get_global_transform_with_canvas`), não y fixo — funciona com a câmera subindo.
- TODO: padrões de movimento, tamanhos, curva de dificuldade por altitude.

## 2026-07-03 — esqueleto inicial
- `asteroid.gd`: Area2D que cai; ao encostar no player (grupo "player") emite `asteroid_hit` e se destrói.
- `asteroid_spawner.gd`: spawn por intervalo no topo da tela.
- TODO: padrões de movimento, tamanhos variados, dificuldade crescente por altitude.
