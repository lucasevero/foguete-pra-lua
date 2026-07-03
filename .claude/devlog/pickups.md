# Devlog — pickups (Dev C)

Arquivos: `fuel.gd`, `fuel.tscn`, `fuel_spawner.gd`, `parallax_bg.gd`, `parallax_bg.tscn`.
Só o agente desta área escreve aqui. Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — Nuvens: várias pequenas espalhadas
- Clouds virou container Node2D; `_spawn_clouds` cria `cloud_count`=16 nuvens em x/y aleatórios na faixa baixa (ground_y-200 até -3200), escala 0.12-0.30, alpha variado. Fade do container por altitude (1-r*2.5). Antes era 1 nuvem centralizada.

## 2026-07-03 — Assets reais: background + galão
- `bg_city.png` (quintal 1800x700, escala 0.4) no nó City; `bg_moon.png` (300, escala 0.9) no Moon; `bg_clouds.png` novo nó Clouds (baixa altitude, some ao subir: alpha=1-r*3.5). Removidos placeholders procedurais de city/moon (estrelas seguem procedurais até chegar bg_stars).
- `fuel_can.png` (50x50) no fuel.tscn (era ColorRect); colisão 44x44.

## 2026-07-03 — Moedas coletáveis (+ moeda grande = 5)
- `coin.gd`/`coin.tscn` (Area2D dourado) + `coin_spawner.gd` (por distância, ~160px, mais frequente que combustível). Emite `coin_collected(amount)`.
- `big_coin.tscn` (reusa coin.gd, amount=5, maior, laranja). Spawner: `big_coin_chance`=0.12 (rara). CoinSpawner tem coin_scene + big_coin_scene em main.tscn.
- Som por valor: coin.wav (normal, v1), coin_big.wav (grande, v2) — AudioManager escolhe por amount>=5.

## 2026-07-03 — Background: chão vira CIDADE (São Paulo)
- Marco de baixo trocado de planeta (bola) p/ **cidade**: nó `City` (era `Earth`), skyline placeholder procedural (`_make_city`: prédios + janelas). Sprite real: `bg_city.png`. `earth_y` → `ground_y`. Lua segue bola (destino no espaço).
- Notion "Sprites a Gerar" atualizado (Terra → Cidade São Paulo).

## 2026-07-03 — Esqueleto de camadas de background
- `parallax_bg` virou Node2D (era CanvasLayer) com: SkyLayer (CanvasLayer -10, gradiente por código), Stars (Parallax2D tileável, alpha sobe com altitude), City (marco embaixo, `ground_y`), Moon (marco topo, `moon_y`).
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
