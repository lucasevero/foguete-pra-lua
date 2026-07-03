#!/usr/bin/env python3
"""Gera o background pixel-art da cutscene na LUA: interior de um foguete
improvisado (gambiarra) com uma janela pro espaço, o solo lunar e a Terra ao
longe. Reproduzível e SEM dependências (encoder PNG em stdlib) — rode
`python3 generate_lua_bg.py`.

Arte desenhada em baixa resolução (90x160, proporção 9:16) e escalada pelo
Godot com filtro nearest (default_texture_filter=0). Placeholder decente — pode
ser trocado por uma versão do nano-banana depois, no mesmo arquivo lua_bg.png.

Paleta coerente com assets/ui/generate_ui_art.py (espaço retrô).
"""
import os, zlib, struct

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 90, 160

# --- paleta ---------------------------------------------------------------
STEEL_D = (30, 34, 50, 255)     # parede interna escura
STEEL   = (48, 54, 78, 255)     # parede
STEEL_L = (78, 90, 126, 255)    # highlight de chapa
EDGE    = (86, 122, 168, 255)   # borda azul-aço (paleta do time)
INK     = (18, 20, 32, 255)     # contorno
SPACE   = (7, 8, 18, 255)       # espaço quase preto
STAR    = (232, 240, 255, 255)  # estrela
STARD   = (150, 165, 200, 255)  # estrela fraca
MOON_D  = (104, 104, 122, 255)  # solo lunar sombra
MOON    = (150, 150, 166, 255)  # solo lunar
MOON_L  = (192, 192, 206, 255)  # solo lunar luz
EARTH_B = (58, 128, 200, 255)   # Terra oceano
EARTH_G = (92, 170, 120, 255)   # Terra continente
AMBER   = (251, 133, 0, 255)    # faixa de alerta / fio
CYAN    = (33, 158, 188, 255)   # fio
TAPE    = (206, 184, 128, 255)  # fita crepe (gambiarra)
RED     = (220, 72, 60, 255)    # luz de alerta
GREEN   = (90, 199, 120, 255)   # luz ok

grid = [[STEEL for _ in range(W)] for _ in range(H)]


def rect(x0, y0, x1, y1, c):
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(max(0, x0), min(W, x1 + 1)):
            grid[y][x] = c


def px(x, y, c):
    if 0 <= x < W and 0 <= y < H:
        grid[y][x] = c


def disc(cx, cy, r, c):
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                px(x, y, c)


# --- parede de fundo com chapas ------------------------------------------
rect(0, 0, W - 1, H - 1, STEEL)
for y in range(0, H, 16):                      # linhas horizontais de chapa
    rect(0, y, W - 1, y, STEEL_D)
for x in range(0, W, 22):                       # rebites verticais
    for y in range(4, H, 8):
        px(x + 4, y, STEEL_L)
        px(x + 4, y + 1, STEEL_D)

# faixa de alerta amarela/preta no topo (moldura da tela de texto)
for x in range(0, W):
    c = AMBER if (x // 4) % 2 == 0 else INK
    rect(x, 0, x, 2, c)

# --- janela pro espaço ----------------------------------------------------
WX0, WY0, WX1, WY1 = 12, 30, 78, 96
rect(WX0 - 2, WY0 - 2, WX1 + 2, WY1 + 2, INK)          # contorno externo
rect(WX0 - 1, WY0 - 1, WX1 + 1, WY1 + 1, EDGE)         # moldura aço
rect(WX0, WY0, WX1, WY1, SPACE)                        # vidro = espaço
# rebites na moldura
for x in range(WX0, WX1 + 1, 8):
    px(x, WY0 - 1, STEEL_L); px(x, WY1 + 1, STEEL_L)
for y in range(WY0, WY1 + 1, 8):
    px(WX0 - 1, y, STEEL_L); px(WX1 + 1, y, STEEL_L)

# estrelas (posições fixas p/ ser reproduzível)
stars = [(18, 36), (27, 41), (40, 34), (52, 38), (63, 35), (71, 44),
         (22, 52), (35, 49), (48, 55), (68, 52), (30, 62), (58, 46),
         (74, 60), (16, 46), (44, 43)]
for i, (sx, sy) in enumerate(stars):
    px(sx, sy, STAR if i % 3 else STARD)

# Terra ao longe (canto sup. dir. da janela)
disc(66, 42, 5, EARTH_B)
px(64, 40, EARTH_G); px(65, 41, EARTH_G); px(67, 43, EARTH_G)
px(68, 41, EARTH_G); px(66, 44, EARTH_G)

# solo lunar no terço inferior da janela
rect(WX0, 84, WX1, WY1, MOON_D)
for x in range(WX0, WX1 + 1):
    h = 84 - (1 if (x // 3) % 2 else 0) - (1 if (x % 7 == 0) else 0)
    rect(x, h, x, 83, MOON)
# crateras
disc(30, 90, 3, MOON_D); disc(31, 89, 1, MOON_L)
disc(55, 92, 4, MOON_D); disc(56, 91, 1, MOON_L)
disc(44, 88, 2, MOON_D)

# --- console / gambiarra abaixo da janela --------------------------------
rect(0, 104, W - 1, 104, INK)
rect(0, 105, W - 1, H - 1, STEEL_D)               # painel de console
# fios (gambiarra) atravessando
for x in range(6, 84):
    px(x, 112 + (x % 3), CYAN)
for x in range(10, 80):
    px(x, 120 - (x % 4), AMBER)
# fita crepe cobrindo um "conserto"
rect(34, 116, 52, 124, TAPE)
rect(34, 116, 52, 116, (170, 150, 96, 255))
px(40, 118, INK); px(46, 122, INK)
# luzes de status
disc(12, 132, 2, RED); disc(20, 132, 2, GREEN); disc(28, 132, 2, AMBER)
disc(78, 132, 2, GREEN)
# botões do painel
for i, bx in enumerate(range(48, 80, 8)):
    rect(bx, 130, bx + 4, 134, STEEL_L)
    px(bx + 2, 132, EDGE)


def write_png(path, w, h, g):
    raw = bytearray()
    for y in range(h):
        raw.append(0)  # filtro 0 por linha
        for x in range(w):
            raw += bytes(g[y][x])
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)  # RGBA 8-bit
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", ihdr)
                + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
                + chunk(b"IEND", b""))


write_png(os.path.join(HERE, "lua_bg.png"), W, H, grid)
print("wrote lua_bg.png (%dx%d)" % (W, H))
