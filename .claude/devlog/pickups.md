# Devlog — pickups (Dev C)

Arquivos: `fuel.gd`, `fuel.tscn`, `fuel_spawner.gd`, `parallax_bg.gd`, `parallax_bg.tscn`.
Só o agente desta área escreve aqui. Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — Esqueleto de camadas de background
- `parallax_bg` virou Node2D (era CanvasLayer) com: SkyLayer (CanvasLayer -10, gradiente por código), Stars (Parallax2D tileável, alpha sobe com altitude), Earth (marco embaixo, `earth_y`), Moon (marco topo, `moon_y`).
- **Placeholders procedurais** em código (estrelas via Image aleatória, discos p/ Terra/Lua). Trocar por pixel art: arrastar PNG pra `texture` do nó → placeholder some (`if texture == null`).
- `earth_y`/`moon_y` @export devem casar com game_manager (moon offset -5000).
- Assets a gerar: ver Notion "Sprites a Gerar". Pixel filter (nearest) ligado no projeto.
- TODO: nuvens (camada baixa), trocar placeholders pela arte.

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
