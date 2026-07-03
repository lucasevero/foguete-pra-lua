# Devlog — obstacles (Dev B)

Arquivos: `asteroid.gd`, `asteroid.tscn`, `asteroid_spawner.gd`. Só o agente desta área escreve aqui.
Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — Fase 2: spawn correto
- Spawn agora **acima do topo visível** sempre (converte tela→mundo via `canvas_transform.affine_inverse`), nunca dentro da tela.
- Spawn por **distância de subida** (não tempo) → densidade constante por trecho, imune à velocidade (corrige exploit de acelerar sem parar). `spawn_distance` ~220px + jitter.
- Despawn por posição na TELA (`get_global_transform_with_canvas`), não y fixo — funciona com a câmera subindo.
- TODO: padrões de movimento, tamanhos, curva de dificuldade por altitude.

## 2026-07-03 — esqueleto inicial
- `asteroid.gd`: Area2D que cai; ao encostar no player (grupo "player") emite `asteroid_hit` e se destrói.
- `asteroid_spawner.gd`: spawn por intervalo no topo da tela.
- TODO: padrões de movimento, tamanhos variados, dificuldade crescente por altitude.
