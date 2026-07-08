# Foguete pra Lua 🚀 — contexto do projeto

Jogo Godot 4.7, 2D, pixel art, **mobile (portrait 720×1280, controle por toque)**. Fase única: o foguete sai da Terra e
sobe até a Lua para resgatar o Carlos e o Gus (que vibecodaram um foguete, chegaram
lá e não conseguem voltar). O jogador gerencia **combustível** e **tempo**, desvia de
**asteroides** e equilibra o foguete (gravidade puxa, empuxo compensa, ele tomba pros lados).
Final agridoce: ao chegar, o nosso foguete também não volta — todos ficam presos na Lua.

Estamos **4 devs**, cada um com um agente Claude Code, trabalhando em paralelo.

> ⚠️ **Este arquivo é contexto compartilhado e estável.** Não reescreva sem combinar
> com o time. Para registrar seu trabalho, use o devlog da sua área (ver abaixo) —
> rode a skill `/context-sync` ao terminar uma tarefa.

## Regras de ouro (evitam merge hell)

1. **Godot 4.7 exato.** Versão diferente reescreve `.tscn` → conflito garantido.
2. **Cada dev mexe SÓ nos arquivos da sua área** (tabela abaixo). Não edite arquivo de outra área.
3. **Sistemas se comunicam SÓ via `GameEvents`** (autoload signal bus). Nunca chame método de outro sistema direto.
4. `git pull --rebase` antes de começar E antes de push. Commits pequenos e frequentes.
5. Nunca commitar `.godot/` (já no `.gitignore`). Sempre commitar `.uid` e `.import`.
6. Antes de commitar: rodar o smoke test headless (ver "Verificar" abaixo). Zero erro.

## Arquitetura

`main.tscn` é um container magro que **instancia** cada cena. Nada de lógica solta lá.

```
main.tscn                                    [área: integration]
├── Background   parallax_bg.tscn/.gd        [área: pickups]   fundo Terra→espaço→Lua
├── Player       player.tscn/.gd             [área: physics]   gravidade+empuxo+torque
├── AsteroidSpawner  asteroid_spawner.gd      [área: obstacles]
│     └── asteroid.tscn/.gd                   [área: obstacles]
├── FuelSpawner  fuel_spawner.gd              [área: pickups]
│     └── fuel.tscn/.gd                       [área: pickups]
├── UI           ui.tscn/.gd                  [área: integration]  HUD
└── GameManager  game_manager.gd             [área: integration]  estados/tempo/win-lose
```

`game_events.gd` (autoload `GameEvents`) = **o contrato**. Todos os signals estão lá.

## Áreas e donos

| Área | Dono | Arquivos | Devlog |
|------|------|----------|--------|
| **physics** | Dev A | `player.gd`, `player.tscn` | `.claude/devlog/physics.md` |
| **obstacles** | Dev B | `asteroid.*`, `asteroid_spawner.gd` | `.claude/devlog/obstacles.md` |
| **pickups** | Dev C | `fuel.*`, `fuel_spawner.gd`, `parallax_bg.*` | `.claude/devlog/pickups.md` |
| **integration** | Dev D | `ui.*`, `game_manager.gd`, `main.tscn` | `.claude/devlog/integration.md` |

Compartilhado (mexer só combinando no time): `game_events.gd`, `project.godot`, `CLAUDE.md`, `CONTRACT.md`.

## Contrato de signals

Fonte da verdade: `game_events.gd`. Resumo em `CONTRACT.md`.
**Mudar assinatura de signal quebra outras áreas** → atualizar os dois + `/context-sync` + avisar o time.

## Controles (protótipo)

- **Toque/clique (segurar)** = empuxo: empurra o foguete pra longe do ponto tocado (embaixo → sobe; lateral → gira). Mouse simula toque no desktop.
- **R** = reiniciar (na tela de game over/vitória)

## Rodar / Verificar

Editor: `/Applications/Godot.app/Contents/MacOS/Godot --path . -e` (ou F5 no editor).

Smoke test headless (rodar ANTES de todo commit — deve sair sem nada):
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --import --quit 2>&1 | grep -iE "error|parse" | grep -vi "0 error"
/Applications/Godot.app/Contents/MacOS/Godot --headless res://main.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|error|nil|invalid"
```

## Deploy (jogar no navegador / celular)

Hospedado no **GitHub Pages**: https://lucasevero.github.io/foguete-pra-lua/ (link fixo).
Qualquer dev com push no repo publica uma nova versão rodando **`./deploy.sh`**
(exporta Web nothreads → branch `gh-pages`; Pages atualiza em ~1 min). Precisa de
Godot 4.7 + export templates. Godot fora do caminho padrão: `GODOT=/caminho ./deploy.sh`.
Export Web é **nothreads** (GitHub Pages não envia headers COOP/COEP).

## Como trabalhamos (agentes)

- Trabalhe **só na sua área**. Se precisar de algo de outra área, peça via **signal novo no contrato** — não invada o arquivo do outro.
- Antes de editar: `git pull --rebase`, leia o devlog das outras áreas (`.claude/devlog/*.md`) pra saber o que mudou.
- Ao terminar uma tarefa: rode **`/context-sync`** → registra no seu devlog e, se mexeu no contrato, atualiza `CONTRACT.md` + `game_events.gd` e marca ⚠️ pro time.
- Branch por área: `feat/physics`, `feat/obstacles`, etc. PR pra `master`. Evita quebrar a main dos outros.
- Nunca faça refactor cross-área sem alinhar — é o que mais gera conflito.
