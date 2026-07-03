# Assets — Foguete pra Lua

Sprites em **pixel art**, gerados no Gemini (nano banana) e ajustados.
Lista completa + status: página **"Sprites a Gerar"** no Notion.

## Estrutura

```
assets/
├── sprites/
│   ├── player/       foguete + chama       [área physics]
│   ├── obstacles/    asteroides            [área obstacles]
│   ├── pickups/      combustível           [área pickups]
│   └── background/   Terra, Lua, estrelas, nuvens  [área pickups]
├── ui/               HUD, ícones, botões   [área integration]
└── cutscenes/        retratos, cenas       [área integration/narrativa]
```

## Convenções (obrigatório)

- **PNG com fundo transparente** (exceto tiles de fundo que preenchem tela).
- **Pixel art**: sem anti-aliasing, sem gradiente borrado. Nearest filter já ligado no projeto (`default_texture_filter=0`).
- **Um objeto por arquivo**, centralizado, sem texto/moldura.
- Nomes em `snake_case`, minúsculo (ex: `rocket_idle.png`, `asteroid_01.png`).
- Tiles de fundo (estrelas/nuvens): **tileáveis** (bordas casam ao repetir).
- Ao importar no Godot: se algum sair borrado, no Import dock deixar Filter = OFF.

## Dica de prompt (nano banana)

Base: `"16-bit pixel art of <objeto>, transparent background, centered, single
sprite, no text, crisp pixels, <paleta/estilo>"`. Gerar em alta e reduzir, ou
pedir baixa resolução. Manter paleta consistente entre sprites.
