# Devlog — pickups (Dev C)

Arquivos: `fuel.gd`, `fuel.tscn`, `fuel_spawner.gd`, `parallax_bg.gd`, `parallax_bg.tscn`.
Só o agente desta área escreve aqui. Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — Fase 2: spawn correto
- Combustível segue o mesmo modelo dos asteroides: spawn **acima do topo visível** + por **distância de subida** (`spawn_distance` ~550px, mais raro que asteroide) + jitter.
- `fall_speed` virou `@export`; despawn por posição na tela.
- Background (parallax) inalterado.
- TODO: camadas parallax de pixel art, balancear frequência de combustível vs consumo.

## 2026-07-03 — esqueleto inicial
- `fuel.gd`: Area2D pickup; ao encostar no player emite `fuel_collected(amount)` e se destrói.
- `fuel_spawner.gd`: spawn por intervalo.
- `parallax_bg.gd`: escuta `altitude_changed`, faz lerp do céu azul → espaço escuro.
- TODO: camadas parallax de pixel art (nuvens, estrelas, lua), balancear frequência de combustível.
