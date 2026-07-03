# Devlog — physics (Dev A)

Arquivos: `player.gd`, `player.tscn`. Só o agente desta área escreve aqui.
Entradas mais recentes no topo. Formato: `## AAAA-MM-DD — título`.

---

## 2026-07-03 — esqueleto inicial
- `player.gd`: gravidade + empuxo (ESPAÇO) na direção do foguete + rotação (A/D). Combustível decrementa ao empurrar.
- Escuta `fuel_collected`, `asteroid_hit`. Emite `fuel_changed`, `player_died`.
- TODO: game feel do equilíbrio (torque/inércia real), tuning dos valores exportados.
