---
name: context-sync
description: Sync shared project context after making changes in the Godot rocket game. Use at the END of any coding task (or when the user says "sync context", "atualiza o contexto", "registra o que fiz", "/context-sync"). Records work in the area devlog, and if the GameEvents signal contract changed, updates CONTRACT.md + game_events.gd and flags the team. Keeps 4 parallel agents in sync without merge conflicts.
---

# context-sync

Mantém o contexto compartilhado atualizado entre os 4 agentes (um por dev), sem gerar
conflito de merge. Rode ao **terminar uma tarefa de código**.

## Princípio anti-conflito

Cada agente escreve **só no devlog da sua área** (`.claude/devlog/<area>.md`). Nunca edite
o devlog de outra área. `CLAUDE.md` é estável — não reescreva. `CONTRACT.md` e
`game_events.gd` só mudam quando o contrato de signals muda, e aí exige avisar o time.

## Áreas (deduza pelos arquivos que você editou)

| Área | Arquivos | Devlog |
|------|----------|--------|
| physics | `player.gd`, `player.tscn` | `.claude/devlog/physics.md` |
| obstacles | `asteroid.*`, `asteroid_spawner.gd` | `.claude/devlog/obstacles.md` |
| pickups | `fuel.*`, `fuel_spawner.gd`, `parallax_bg.*` | `.claude/devlog/pickups.md` |
| integration | `ui.*`, `game_manager.gd`, `main.tscn` | `.claude/devlog/integration.md` |

Editou arquivos de **mais de uma** área? Você provavelmente invadiu área alheia —
pare e alinhe com o time antes de continuar (viola a regra de ouro do `CLAUDE.md`).

## Passos

1. **Descubra sua área**: `git diff --name-only master...HEAD` (ou `git status`) → mapeie na tabela.

2. **Verifique (obrigatório)** — rode o smoke test; não registre se houver erro:
   ```bash
   /Applications/Godot.app/Contents/MacOS/Godot --headless --import --quit 2>&1 | grep -iE "error|parse" | grep -vi "0 error"
   /Applications/Godot.app/Contents/MacOS/Godot --headless res://main.tscn --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|error|nil|invalid"
   ```

3. **Registre no devlog da sua área** — prepend (entradas novas no topo), formato:
   ```markdown
   ## AAAA-MM-DD — <título curto>
   - <o que mudou, em 1-3 bullets>
   - TODO: <o que falta>
   ```
   Use a data real (peça ao usuário ou use a data do sistema). Não toque em devlog de outra área.

4. **Mudou o contrato de signals?** (adicionou/renomeou/alterou assinatura em `game_events.gd`,
   ou novo arquivo compartilhado, ou nova action de input). Se **sim**:
   - Atualize `game_events.gd` (a fonte da verdade) e a tabela em `CONTRACT.md` juntos.
   - Adicione no seu devlog uma linha começando com `⚠️ CONTRATO:` descrevendo a mudança.
   - Avise no resumo final ao usuário: "isto muda o contrato — avise os outros devs (git pull)".

5. **Commit** (só se o usuário pediu para commitar — senão, deixe staged e avise):
   - Mensagem curta, Conventional Commits. Rode `git pull --rebase` antes de push.

## O que NÃO fazer

- Não reescrever `CLAUDE.md` (estável; mudança estrutural precisa de acordo do time).
- Não editar devlog / arquivos de outra área.
- Não registrar trabalho que não passou no smoke test.
- Não commitar `.godot/`.
