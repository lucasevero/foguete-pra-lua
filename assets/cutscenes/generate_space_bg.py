#!/usr/bin/env python3
"""Gera o fundo de espaço estrelado da CENA 2 (atrás das ilustrações cena_final),
SEM dependências (encoder PNG stdlib). Rode: python3 generate_space_bg.py

space_bg.png — 90x160 (9:16, preenche a tela em COVER): degradê escuro do espaço,
estrelas e uma Terra suave ao longe. Combina com as ilustrações transparentes.
"""
import os, zlib, struct, math

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 90, 160

TOP    = (6, 7, 16, 255)      # espaço no topo
BOT    = (12, 14, 30, 255)    # espaço mais quente embaixo
STAR   = (232, 240, 255, 255)
STARD  = (150, 165, 200, 255)
EARTH_B= (58, 128, 200, 255)
EARTH_G= (92, 170, 120, 255)
EARTH_L= (150, 200, 235, 255)

STARS = [(8, 12), (16, 26), (27, 8), (39, 20), (52, 10), (61, 28), (74, 14),
         (83, 30), (12, 44), (34, 40), (48, 52), (67, 46), (80, 54), (20, 66),
         (44, 72), (58, 64), (76, 78), (10, 88), (30, 96), (70, 100),
         (50, 110), (85, 120), (14, 128), (40, 140), (64, 150)]


def grid():
    g = []
    for y in range(H):
        t = y / (H - 1)
        c = (int(TOP[0] + (BOT[0] - TOP[0]) * t),
             int(TOP[1] + (BOT[1] - TOP[1]) * t),
             int(TOP[2] + (BOT[2] - TOP[2]) * t), 255)
        g.append([c for _ in range(W)])
    return g

def px(g, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = c

def disc(g, cx, cy, r, c):
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                px(g, x, y, c)

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

g = grid()
for i, (sx, sy) in enumerate(STARS):
    px(g, sx, sy, STAR if i % 3 else STARD)
# Terra suave ao longe (canto superior direito, longe do foguete que fica à esq)
disc(g, 72, 22, 9, EARTH_B)
for dx, dy, rr in [(-2, -1, 2), (2, 2, 2), (3, -3, 1), (-3, 3, 1)]:
    disc(g, 72 + dx, 22 + dy, rr, EARTH_G)
for a in range(200, 265, 7):
    rad = math.radians(a)
    px(g, 72 + int(9 * math.cos(rad)), 22 + int(9 * math.sin(rad)), EARTH_L)

write_png(os.path.join(HERE, "space_bg.png"), g)
print("wrote space_bg.png (%dx%d)" % (W, H))
