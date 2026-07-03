extends Node
## Event bus / CONTRATO entre sistemas.
##
## Autoload global: acesse como `GameEvents` de qualquer script.
## Ninguém chama métodos de outro sistema direto — todos falam por estes signals.
## NÃO renomeie/mude assinatura sem avisar o time (isso quebra todo mundo).

# --- Player -> mundo ---
signal fuel_changed(current: float, maximum: float)   # HUD escuta
signal altitude_changed(ratio: float)                 # 0.0 = Terra, 1.0 = Lua. Background escuta
signal player_died                                    # GameManager escuta
signal player_reached_moon                            # GameManager escuta

# --- Player -> áudio ---
signal thrust_changed(active: bool)                   # AudioManager escuta (liga/desliga som do motor)
signal lifted_off                                     # AudioManager: som de decolagem (sai do chão 1ª vez)
signal landed_safely                                  # AudioManager: som de pouso suave

# --- Pickups / obstáculos -> Player ---
signal fuel_collected(amount: float)                  # Player escuta, adiciona combustível
signal asteroid_hit                                   # Player escuta, morre

# --- Fluxo de jogo (GameManager emite) ---
signal time_changed(seconds_left: float)              # HUD escuta
signal game_started
signal game_over(won: bool)                           # HUD escuta (true = venceu)
