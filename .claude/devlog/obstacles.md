# Devlog — obstacles (Dev B)

Arquivos: `asteroid.gd`, `asteroid.tscn`, `asteroid_spawner.gd`. Só o agente desta área escreve aqui.
Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — esqueleto inicial
- `asteroid.gd`: Area2D que cai; ao encostar no player (grupo "player") emite `asteroid_hit` e se destrói.
- `asteroid_spawner.gd`: spawn por intervalo no topo da tela.
- TODO: padrões de movimento, tamanhos variados, dificuldade crescente por altitude.
