#!/usr/bin/env python3
"""Gera os backgrounds da CENA 2 (final), SEM dependências (encoder PNG stdlib).
Rode: python3 generate_final_bgs.py
- moon_surface.png : exterior lunar + foguete gambiarra pousado + Terra no céu.
- moon_sit.png     : plano aberto, os três sentados na Lua, Terra brilhando.
Baixa resolução 90x160 (escala nearest no Godot). Placeholder reproduzível.
"""
import os, zlib, struct, math

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 90, 160

SPACE  = (7, 8, 18, 255)
STAR   = (232, 240, 255, 255)
STARD  = (150, 165, 200, 255)
MOON_D = (104, 104, 122, 255)
MOON   = (150, 150, 166, 255)
MOON_L = (192, 192, 206, 255)
EARTH_B= (58, 128, 200, 255)
EARTH_G= (92, 170, 120, 255)
EARTH_L= (150, 200, 235, 255)
STEEL  = (52, 58, 82, 255)
STEEL_L= (86, 96, 130, 255)
INK    = (18, 18, 30, 255)
TAPE   = (206, 184, 128, 255)
GREEN  = (190, 228, 30, 255)
SKIN   = (214, 150, 110, 255)
HELMET = (210, 214, 224, 255)
CARLOS_C = (200, 90, 70, 255)
LUCA_C   = (90, 120, 200, 255)
GUS_C    = (90, 180, 110, 255)

STARS = [(10, 20), (22, 14), (34, 24), (50, 12), (63, 22), (75, 16),
         (14, 40), (40, 46), (56, 40), (70, 50), (82, 34), (28, 58)]


def blank():
    return [[(0, 0, 0, 0) for _ in range(W)] for _ in range(H)]

def rect(g, x0, y0, x1, y1, c):
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(max(0, x0), min(W, x1 + 1)):
            g[y][x] = c

def px(g, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = c

def disc(g, cx, cy, r, c):
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                px(g, x, y, c)

def earth(g, cx, cy, r):
    disc(g, cx, cy, r, EARTH_B)
    for dx, dy, rr in [(-3, -2, 2), (2, 1, 3), (-1, 4, 2), (4, -3, 1), (-4, 2, 1)]:
        disc(g, cx + dx, cy + dy, rr, EARTH_G)
    for a in range(200, 265, 6):
        rad = math.radians(a)
        px(g, cx + int(r * math.cos(rad)), cy + int(r * math.sin(rad)), EARTH_L)

def ground(g, top):
    rect(g, 0, top, W - 1, H - 1, MOON_D)
    for x in range(W):
        h = top - (1 if (x // 4) % 2 else 0)
        rect(g, x, h, x, top - 1, MOON)

def rocket(g, x, y):
    rect(g, x, y, x + 12, y + 34, STEEL)
    rect(g, x, y, x + 3, y + 34, STEEL_L)
    rect(g, x + 2, y - 6, x + 10, y, STEEL)
    rect(g, x + 4, y - 9, x + 8, y - 6, STEEL_L)
    disc(g, x + 6, y + 10, 3, GREEN)
    px(g, x + 6, y + 9, INK)
    rect(g, x + 3, y + 20, x + 9, y + 24, TAPE)
    for i in range(5):
        px(g, x - 1 - i, y + 30 + i, STEEL)
        px(g, x + 13 + i, y + 30 + i, STEEL)
    rect(g, x, y + 34, x + 12, y + 35, INK)

def sit_figure(g, x, base, col):
    rect(g, x - 3, base - 5, x + 3, base - 1, col)   # tronco
    rect(g, x - 4, base - 1, x + 4, base, col)       # pernas dobradas
    disc(g, x, base - 7, 2, SKIN)                    # cabeça
    px(g, x, base - 9, INK)                          # cabelo
    disc(g, x + 6, base - 1, 2, HELMET)              # capacete ao lado
    px(g, x + 6, base - 2, STEEL)

def stars(g):
    for i, (sx, sy) in enumerate(STARS):
        px(g, sx, sy, STAR if i % 3 else STARD)

def write_png(path, g):
    raw = bytearray()
    for y in range(H):
        raw.append(0)
        for x in range(W):
            raw += bytes(g[y][x])
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))
    ihdr = struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
                + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))

def build_surface():
    g = blank()
    rect(g, 0, 0, W - 1, H - 1, SPACE)
    stars(g)
    earth(g, 22, 34, 12)
    ground(g, 112)
    disc(g, 18, 132, 5, MOON_D); disc(g, 62, 142, 6, MOON_D)
    rocket(g, 56, 74)
    for x in range(50, 78, 3):
        px(g, x, 117, MOON_L)
    return g

def build_sit():
    g = blank()
    rect(g, 0, 0, W - 1, H - 1, SPACE)
    stars(g)
    earth(g, 45, 40, 20)
    ground(g, 122)
    disc(g, 14, 142, 6, MOON_D); disc(g, 72, 146, 7, MOON_D)
    sit_figure(g, 32, 120, CARLOS_C)
    sit_figure(g, 46, 120, LUCA_C)
    sit_figure(g, 60, 120, GUS_C)
    return g

write_png(os.path.join(HERE, "moon_surface.png"), build_surface())
write_png(os.path.join(HERE, "moon_sit.png"), build_sit())
print("wrote moon_surface.png e moon_sit.png (%dx%d)" % (W, H))
